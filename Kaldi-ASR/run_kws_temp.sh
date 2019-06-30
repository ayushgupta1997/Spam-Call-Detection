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


#
data_only=false
fast_path=true
skip_kws=false
skip_stt=false
skip_scoring=false
max_states=150000
extra_kws=false
vocab_kws=false
tri5_only=false
wip=0.5
cer=0


#
feats_nj=30
train_nj=30
decode_nj=5


data_prep=0
data_kws_prep=0
feat_extract=0
mono_train=0
mono_decode=0
tri1_train=0
tri1_decode=0
tri2_train=0
tri2_decode=0
tri3_train=0
tri3_decode=0
sgmm_train=0
sgmm_decode=0
nmi_sgm_train=0
nmi_sgm_decode=0
DNN_train=0
DNN_decode=0
test_ali_fmllr=1
test_kws_fmllr=0


if [ $data_prep == 1  ]; then
echo ============================================================================
echo "                Data & Lexicon & Language Preparation                     "
echo ============================================================================

#timit=/export/corpora5/LDC/LDC93S1/timit/TIMIT # @JHU
#timit=/home/ishwarchy/kaldi_work/egs/timit/s6/TIMIT
timit=/home/laxmi/Documents/corpus1

local/data_prep.sh $timit || exit 1

#local/timit_prepare_dict.sh
#./Create_ngram_LM.sh #irstlm
#utils/prepare_lang.sh --share-silence-phones true data/local/dict '!sil' data/local/tmp.lang data/lang
#local/train_lms_srilm.sh --dev-text data/test/text --train-text data/train/text data data/srilm
#local/arpa2G.sh data/srilm/lm.gz data/lang data/lang  #strilm

#local/timit_format_data_kws.sh
fi

if [ $data_kws_prep == 1  ]; then
echo ============================================================================
echo "              KWS  Data  Preparation                     "
echo ============================================================================

local/prepare_ecf.sh data/test
local/prepare_kwlist.sh  data/KWS
#local/kws_setup.sh --case_insensitive "true" --rttm-file "data/kws/rttm"  data/kws/test.ecf.xml data/KWS/kwlist.xml data/lang data/test


fi



if [ $feat_extract == 1  ]; then
echo ============================================================================
echo "         MFCC Feature Extration & CMVN for Training and Test set          "
echo ============================================================================

# Now make MFCC features.
mfccdir=mfcc


for x in train test; do 
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



if [ $DNN_train == 1  ]; then
echo ============================================================================
echo "                    DNN Hybrid Training                       "
echo ============================================================================

# DNN hybrid system training parameters
dnn_mem_reqs="--mem 1G"
dnn_extra_opts="--num_epochs 20 --num-epochs-extra 10 --add-layers-period 1 --shrink-interval 3"

steps/nnet2/train_tanh.sh --mix-up 5000 --initial-learning-rate 0.015 \
  --final-learning-rate 0.002 --num-hidden-layers 8  \
  --num-jobs-nnet "$train_nj" --cmd "$train_cmd" "${dnn_train_extra_opts[@]}" \
  data/train data/lang exp/tri3_ali exp/tri4_nnet

fi






if [ $test_ali_fmllr == 1  ]; then
echo ============================================================================
echo "                    test alignment for rttm                       "
echo ============================================================================



steps/align_fmllr.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 data/test data/lang exp/tri3 exp/tri3/align_test

local/ali_to_rttm.sh data/test data/lang exp/tri3/align_test
cat exp/tri3/align_test/rttm |sed '/NON-LEX/d' >data/KWS/rttm
local/kws_setup.sh --case_insensitive "true" --rttm-file "data/KWS/rttm"  data/KWS/test.ecf.xml data/KWS/kwlist.xml data/lang data/test



fi

if [ $mono_decode == 1  ]; then
echo ============================================================================
echo "                     MonoPhone Decoding                        "
echo ============================================================================
utils/mkgraph.sh data/lang_test_bg exp/mono exp/mono/graph

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/mono/graph data/test exp/mono/decode_test
fi

if [ $tri1_decode == 1  ]; then
echo ============================================================================
echo "           tri1 : Deltas + Delta-Deltas  Decoding               "
echo ============================================================================
utils/mkgraph.sh data/lang_test_bg exp/tri1 exp/tri1/graph

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/tri1/graph data/test exp/tri1/decode_test
fi

if [ $tri2_decode == 1  ]; then
echo ============================================================================
echo "                 tri2 : LDA + MLLT Decoding                    "
echo ============================================================================
utils/mkgraph.sh data/lang_test_bg exp/tri2 exp/tri2/graph

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/tri2/graph data/test exp/tri2/decode_test
fi
if [ $tri3_decode == 1  ]; then
echo ============================================================================
echo "              tri3 : LDA + MLLT + SAT Decoding                 "
echo ============================================================================
#utils/mkgraph.sh data/lang_test_bg exp/tri3 exp/tri3/graph

 steps/decode_fmllr_extra.sh --skip-scoring $skip_scoring --beam 10 --lattice-beam 4\
   --nj $decode_nj --cmd "$decode_cmd" "${decode_extra_opts[@]}"\
   exp/tri3/graph data/test exp/tri3/decode_test_kws

local/run_kws_stt_task.sh --cer $cer --max-states $max_states \
    --skip-scoring $skip_scoring --extra-kws $extra_kws --wip $wip \
    --cmd "$decode_cmd" --skip-kws $skip_kws --skip-stt $skip_stt \
    "${lmwt_plp_extra_opts[@]}" \
    data/test data/lang exp/tri3/decode_test_kws
fi

if [ $sgmm_decode == 1  ]; then
echo ============================================================================
echo "                        SGMM2 Decoding                         "
echo ============================================================================
utils/mkgraph.sh data/lang_test_bg exp/sgmm2_4 exp/sgmm2_4/graph


  steps/decode_sgmm2.sh --skip-scoring true --use-fmllr true --nj $decode_nj \
      --cmd "$decode_cmd" --transform-dir exp/tri3/decode_test_kws "${decode_extra_opts[@]}"\
      exp/sgmm2_4/graph data/test exp/sgmm2_4/decode_test


 local/run_kws_stt_task.sh --cer $cer --max-states $max_states \
    --skip-scoring $skip_scoring --extra-kws $extra_kws --wip $wip \
    --cmd "$decode_cmd" --skip-kws $skip_kws --skip-stt $skip_stt \
    "${lmwt_plp_extra_opts[@]}" \
    data/test data/lang exp/sgmm2_4/decode_test

fi

if [ $DNN_decode == 1 ]; then
echo ============================================================================
echo "                    DNN Hybrid Decoding                        "
echo ============================================================================

mkdir -p exp/tri4_nnet/decode_test
steps/nnet2/decode.sh --cmd "$decode_cmd" --nj "$decode_nj" "${decode_extra_opts[@]}" \
  --transform-dir exp/tri3/decode_test_kws exp/tri3/graph data/test \
  exp/tri4_nnet/decode_test | tee exp/tri4_nnet/decode_test/decode.log

local/run_kws_stt_task.sh --cer $cer --max-states $max_states \
    --skip-scoring $skip_scoring --extra-kws $extra_kws --wip $wip \
    --cmd "$decode_cmd" --skip-kws $skip_kws --skip-stt $skip_stt \
    "${lmwt_plp_extra_opts[@]}" \
    data/test data/lang exp/tri4_nnet/decode_test

fi




