#!/bin/bash

#
# Copyright 2013 Bagher BabaAli,
#           2014 Brno University of Technology (Author: Karel Vesely)
#
# TIMIT, description of the database:
# http://perso.limsi.fr/lamel/TIMIT_NISTIR4930.pdf
#
# Hon and Lee paper on TIMIT, 1988, introduces mapping to 48 training phonemes, 
# then re-mapping to 39 phonemes for scoring:
# http://repository.cmu.edu/cgi/viewcontent.cgi?article=2768&context=compsci
#

. ./cmd.sh 
[ -f path.sh ] && . ./path.sh
set -e

# Acoustic model parameters
numLeavesTri1=2500
numGaussTri1=15000
numLeavesMLLT=2500
numGaussMLLT=15000
numLeavesSAT=2500
numGaussSAT=15000
numGaussUBM=400
numLeavesSGMM=7000
numGaussSGMM=9000

feats_nj=30
train_nj=30
decode_nj=5


data_prep=0
feat_extract=1
mono_train=1
mono_decode=1
tri1_train=1
tri1_decode=1
tri2_train=1
tri2_decode=1
tri3_train=1
tri3_decode=1
sgmm_train=1
sgmm_decode=1
nmi_sgm_train=1
nmi_sgm_decode=1
DNN_train=1
DNN_decode=1

if [ $data_prep == 1  ]; then
echo ============================================================================
echo "                Data & Lexicon & Language Preparation                     "
echo ============================================================================

#timit=/export/corpora5/LDC/LDC93S1/timit/TIMIT # @JHU
timit=/home/ishwarchy/kaldi_work/egs/timit/s6/TIMIT 

local/timit_data_prep.sh $timit || exit 1

local/timit_prepare_dict.sh

# Caution below: we remove optional silence by setting "--sil-prob 0.0",
# in TIMIT the silence appears also as a word in the dictionary and is scored.
utils/prepare_lang.sh --sil-prob 0.0 --position-dependent-phones false --num-sil-states 3 data/local/dict '!SIL' data/local/lang_tmp data/lang
local/train_lms_srilm.sh --dev-text data/dev/text \
    --train-text data/train/text data data/srilm words-file data/local/dict/lexicon.txt
local/arpa2G.sh data/srilm/lm.gz data/lang data/lang
local/timit_format_data.sh
fi




if [ $feat_extract == 1  ]; then
echo ============================================================================
echo "         MFCC Feature Extration & CMVN for Training and Test set          "
echo ============================================================================

# Now make MFCC features.
mfccdir=mfcc


for x in train dev test; do 
  steps/make_mfcc.sh --cmd "$train_cmd" --nj $feats_nj data/$x exp/make_mfcc/$x $mfccdir
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
done
fi

if [ $mono_train == 1  ]; then
echo ============================================================================
echo "                     MonoPhone Training                        "
echo ============================================================================

steps/train_mono.sh  --nj "$train_nj" --cmd "$train_cmd" data/train data/lang exp/mono
fi

if [ $mono_decode == 1  ]; then
echo ============================================================================
echo "                     MonoPhone Decoding                        "
echo ============================================================================
utils/mkgraph.sh data/lang_test_bg exp/mono exp/mono/graph

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" exp/mono/graph data/dev exp/mono/decode_dev

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/mono/graph data/test exp/mono/decode_test
fi


if [ $tri1_train == 1  ]; then
echo ============================================================================
echo "           tri1 : Deltas + Delta-Deltas Training              "
echo ============================================================================

steps/align_si.sh --boost-silence 1.25 --nj "$train_nj" --cmd "$train_cmd" \
 data/train data/lang exp/mono exp/mono_ali

# Train tri1, which is deltas + delta-deltas, on train data.
steps/train_deltas.sh --cmd "$train_cmd" \
 $numLeavesTri1 $numGaussTri1 data/train data/lang exp/mono_ali exp/tri1

fi
if [ $tri1_decode == 1  ]; then
echo ============================================================================
echo "           tri1 : Deltas + Delta-Deltas  Decoding               "
echo ============================================================================
utils/mkgraph.sh data/lang_test_bg exp/tri1 exp/tri1/graph

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/tri1/graph data/dev exp/tri1/decode_dev

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/tri1/graph data/test exp/tri1/decode_test
fi


if [ $tri2_train == 1  ]; then
echo ============================================================================
echo "                 tri2 : LDA + MLLT Decoding                    "
echo ============================================================================
steps/align_si.sh --nj "$train_nj" --cmd "$train_cmd" \
  data/train data/lang exp/tri1 exp/tri1_ali

steps/train_lda_mllt.sh --cmd "$train_cmd" \
 --splice-opts "--left-context=3 --right-context=3" \
 $numLeavesMLLT $numGaussMLLT data/train data/lang exp/tri1_ali exp/tri2
fi
if [ $tri1_decode == 1  ]; then
echo ============================================================================
echo "                 tri2 : LDA + MLLT Decoding                    "
echo ============================================================================
utils/mkgraph.sh data/lang_test_bg exp/tri2 exp/tri2/graph

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/tri2/graph data/dev exp/tri2/decode_dev

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/tri2/graph data/test exp/tri2/decode_test
fi
if [ $tri3_train == 1  ]; then
echo ============================================================================
echo "              tri3 : LDA + MLLT + SAT Training                "
echo ============================================================================

# Align tri2 system with train data.
steps/align_si.sh --nj "$train_nj" --cmd "$train_cmd" \
 --use-graphs true data/train data/lang exp/tri2 exp/tri2_ali

# From tri2 system, train tri3 which is LDA + MLLT + SAT.
steps/train_sat.sh --cmd "$train_cmd" \
 $numLeavesSAT $numGaussSAT data/train data/lang exp/tri2_ali exp/tri3
fi
if [ $tri3_decode == 1  ]; then

echo ============================================================================
echo "              tri3 : LDA + MLLT + SAT Decoding                 "
echo ============================================================================
utils/mkgraph.sh data/lang_test_bg exp/tri3 exp/tri3/graph

steps/decode_fmllr.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/tri3/graph data/dev exp/tri3/decode_dev

steps/decode_fmllr.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/tri3/graph data/test exp/tri3/decode_test
fi

if [ $sgmm_train == 1  ]; then
echo ============================================================================
echo "                        SGMM2 Training                       "
echo ============================================================================

steps/align_fmllr.sh --nj "$train_nj" --cmd "$train_cmd" \
 data/train data/lang exp/tri3 exp/tri3_ali

#exit 0 # From this point you can run Karel's DNN : local/nnet/run_dnn.sh 

steps/train_ubm.sh --cmd "$train_cmd" \
 $numGaussUBM data/train data/lang exp/tri3_ali exp/ubm4

steps/train_sgmm2.sh --cmd "$train_cmd" $numLeavesSGMM $numGaussSGMM \
 data/train data/lang exp/tri3_ali exp/ubm4/final.ubm exp/sgmm2_4
fi


if [ $sgmm_decode == 1  ]; then
echo ============================================================================
echo "                        SGMM2 Decoding                         "
echo ============================================================================
utils/mkgraph.sh data/lang_test_bg exp/sgmm2_4 exp/sgmm2_4/graph

steps/decode_sgmm2.sh --nj "$decode_nj" --cmd "$decode_cmd"\
 --transform-dir exp/tri3/decode_dev exp/sgmm2_4/graph data/dev \
 exp/sgmm2_4/decode_dev

steps/decode_sgmm2.sh --nj "$decode_nj" --cmd "$decode_cmd"\
 --transform-dir exp/tri3/decode_test exp/sgmm2_4/graph data/test \
 exp/sgmm2_4/decode_test
fi
if [ $DNN_train == 1  ]; then
echo ============================================================================
echo "                    DNN Hybrid Training & Decoding                        "
echo ============================================================================

# DNN hybrid system training parameters
dnn_mem_reqs="--mem 1G"
dnn_extra_opts="--num_epochs 20 --num-epochs-extra 10 --add-layers-period 1 --shrink-interval 3"

steps/nnet2/train_tanh.sh --mix-up 5000 --initial-learning-rate 0.015 \
  --final-learning-rate 0.002 --num-hidden-layers 2  \
  --num-jobs-nnet "$train_nj" --cmd "$train_cmd" "${dnn_train_extra_opts[@]}" \
  data/train data/lang exp/tri3_ali exp/tri4_nnet

fi
if [ $DNN_decode=1 ]; then
mkdir -p exp/tri4_nnet/decode_dev

decode_extra_opts=(--num-threads 6)
steps/nnet2/decode.sh --cmd "$decode_cmd" --nj "$decode_nj" "${decode_extra_opts[@]}" \
  --transform-dir exp/tri3/decode_dev exp/tri3/graph data/dev \
  exp/tri4_nnet/decode_dev | tee exp/tri4_nnet/decode_dev/decode.log

mkdir -p exp/tri4_nnet/decode_test
steps/nnet2/decode.sh --cmd "$decode_cmd" --nj "$decode_nj" "${decode_extra_opts[@]}" \
  --transform-dir exp/tri3/decode_test exp/tri3/graph data/test \
  exp/tri4_nnet/decode_test | tee exp/tri4_nnet/decode_test/decode.log
fi
