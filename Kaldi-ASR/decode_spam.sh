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
feats_nj=10
train_nj=10
decode_nj=5


data_prep=0
data_kws_prep=0
feat_extract=1
mono_train=0
mono_decode=0
tri1_train=0
tri1_decode=0
tri2_train=0
tri2_decode=0
tri3_train=0
tri3_decode=1
sgmm_train=0
sgmm_decode=0
nmi_sgm_train=0
nmi_sgm_decode=0
DNN_train=0
DNN_decode=1
test_ali_fmllr=0
test_kws_fmllr=0





if [ $feat_extract == 1  ]; then
echo ============================================================================
echo "         MFCC Feature Extration & CMVN for Training and Test set          "
echo ============================================================================

# Now make MFCC features.
mfccdir=mfcc


for x in data; do 
  steps/make_mfcc.sh --cmd "$train_cmd" --nj $feats_nj /home/karabi/Documents/project_spam/new_spam_auto/$x exp_new1/make_mfcc/$x $mfccdir
  steps/compute_cmvn_stats.sh /home/karabi/Documents/project_spam/new_spam_auto/$x exp_new1/make_mfcc/$x $mfccdir
done
fi


if [ $tri3_decode == 1  ]; then
echo ============================================================================
echo "              tri3 : LDA + MLLT + SAT Decoding                 "
echo ============================================================================
utils/mkgraph.sh data/lang_test_bg exp_new1/tri3 exp_new1/tri3/graph

 steps/decode_fmllr_extra.sh --skip-scoring $skip_scoring --beam 10 --lattice-beam 4\
    --nj $decode_nj --cmd "$decode_cmd" "${decode_extra_opts[@]}"\
    exp_new1/tri3/graph /home/karabi/Documents/project_spam/new_spam_auto/data exp_new1/tri3/decode_test
#/home/shivani/project_spam/new_system/new_system/atm_fraud3.sh
local/run_kws_stt_task.sh --cer $cer --max-states $max_states \
    --skip-scoring $skip_scoring --extra-kws $extra_kws --wip $wip \
    --cmd "$decode_cmd" --skip-kws $skip_kws --skip-stt $skip_stt \
    "${lmwt_plp_extra_opts[@]}" \
    /home/karabi/Documents/project_spam/new_spam_auto/data data/lang exp_new1/tri3/decode_test_20


fi



if [ $DNN_decode == 1 ]; then
echo ============================================================================
echo "                    DNN Hybrid Decoding                        "
echo ============================================================================

mkdir -p exp_new1/tri4_nnet/decode_test
steps/nnet2/decode.sh --cmd "$decode_cmd" --nj "$decode_nj" "${decode_extra_opts[@]}" \
 --transform-dir exp_new1/tri3/decode_test exp_new1/tri3/graph /home/karabi/Documents/project_spam/new_spam_auto/data \
  exp_new1/tri4_nnet/decode_test | tee exp_new1/tri4_nnet/decode_test/decode.log

local/run_kws_stt_task.sh --cer $cer --max-states $max_states \
    --skip-scoring $skip_scoring --extra-kws $extra_kws --wip $wip \
   --cmd "$decode_cmd" --skip-kws $skip_kws --skip-stt $skip_stt \
    "${lmwt_plp_extra_opts[@]}" \
    /home/karabi/Documents/project_spam/new_spam_auto/data data/lang_test_bg exp_new1/tri4_nnet/decode_test

fi




