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
#rm -rf/home/karabi/Documents/project_spam/new_spam_auto/log
#mkdir -p /home/karabi/Documents/project_spam/new_spam_auto/log
rm -rf /home/karabi/Documents/project_spam/new_spam_auto/log_wav/*
rm -rf /home/karabi/Documents/project_spam/new_spam_auto/log/cmvn
rm -rf /home/karabi/Documents/project_spam/new_spam_auto/log/Dnn
rm -rf /home/karabi/Documents/project_spam/new_spam_auto/log/mfcc
rm -rf /home/karabi/Documents/project_spam/new_spam_auto/log/tri3
rm -rf /home/karabi/Documents/project_spam/new_spam_auto/spam_data/r_count
rm -rf /home/karabi/Documents/project_spam/new_spam_auto/spam_data/r_keyword
rm -rf /home/karabi/Documents/project_spam/new_spam_auto/spam_data/counts.txt
rm -rf /home/karabi/Documents/project_spam/new_spam_auto/spam_data/per_utt1
rm -rf /home/karabi/Documents/project_spam/new_spam_auto/spam_data/r_alarm
rm -rf /home/karabi/Documents/project_spam/new_spam_auto/spam_data/utterance
#
feats_nj=10
train_nj=10
decode_nj=5


data_prep=0
feat_extract=0

tri3_decode=0

function ceiling() {
    float_in=$1
    ceil_val=${float_in/.*}
    ceil_val=$((ceil_val+1))
}
function floor() {
    float_in=$1
    floor_val=${float_in/.*}
}
clear
clear
python /home/karabi/Documents/project_spam/new_spam_auto/record.py &
sleep 13s

echo "start"

count=1
echo 0 >>'/home/karabi/Documents/project_spam/new_spam_auto/spam_data/r_count'
echo "" >>'/home/karabi/Documents/project_spam/new_spam_auto/spam_data/r_keyword'
echo 0 >>'/home/karabi/Documents/project_spam/new_spam_auto/spam_data/r_alarm'

while [ true ]
do


while [ true ]
do
flag233=0
if [ "$(ls -A /home/karabi/Documents/project_spam/new_spam_auto/TEST2)" ];then
		break
	
fi
done

	if [ "$(ls -A /home/karabi/Documents/project_spam/new_spam_auto/TEST2)" ];then
	find /home/karabi/Documents/project_spam/new_spam_auto/TEST2/* -name '*.wav'|sort > /home/karabi/Documents/project_spam/new_spam_auto/data/wav_list.scp #|| continue
	else
		
		echo "completed..."
		exit 0
	fi
	#}
#fi
	exec 4< /home/karabi/Documents/project_spam/new_spam_auto/data/wav_list.scp
	read <&4
	wav_list=$REPLY	
	
	printf "\033[1;33m--------------------executing part "$count" of the audio--------------------\033[0m\n"
	count=$(( $count +1 ))
	
	echo "wav:"$wav_list
	
	mv $wav_list /home/karabi/Documents/project_spam/new_spam_auto/testing/output1.wav

#echo "mfcc"

#if [ $feat_extract == 1  ]; then
#echo ============================================================================
#echo "         MFCC Feature Extration & CMVN for Training and Test set          "
#echo ============================================================================

# Now make MFCC features.
mfccdir=mfcc
#echo "mfcc start"
  steps/make_mfcc.sh --cmd "$train_cmd" --nj 1 /home/karabi/Documents/project_spam/new_spam_auto/data exp_kws/make_mfcc $mfccdir>/home/karabi/Documents/project_spam/new_spam_auto/log/mfcc
  steps/compute_cmvn_stats.sh /home/karabi/Documents/project_spam/new_spam_auto/data exp_kws/make_mfcc $mfccdir>/home/karabi/Documents/project_spam/new_spam_auto/log/cmvn
#echo "mfcc & cmvn"

#fi





#if [ $tri3_decode == 1  ]; then
#echo ============================================================================
#echo "              tri3 : LDA + MLLT + SAT Decoding                 "
#echo ============================================================================
#utils/mkgraph.sh data/lang_test_bg exp_kws/tri3 exp_kws/tri3/graph

 steps/decode_fmllr_extra.sh --skip-scoring $skip_scoring --beam 1 --lattice-beam 1\
   --nj 1 --cmd "$decode_cmd" "${decode_extra_opts[@]}"\
    exp_kws/tri3/graph /home/karabi/Documents/project_spam/new_spam_auto/data exp_kws/tri3/decode_test >>/home/karabi/Documents/project_spam/new_spam_auto/log/tri3
#echo "tri3"
#echo ============================================================================
#echo "                    DNN Hybrid Decoding                        "
#echo ============================================================================
rm -rf /home/karabi/Documents/project_spam/KWS_SPAM/exp_kws/tri4_nnet/decode_test
steps/nnet2/decode.sh --cmd "$decode_cmd" --nj 1 "${decode_extra_opts[@]}" \
 --transform-dir exp_kws/tri3/decode_test exp_kws/tri3/graph /home/karabi/Documents/project_spam/new_spam_auto/data \
  exp_kws/tri4_nnet/decode_test>>/home/karabi/Documents/project_spam/new_spam_auto/log/Dnn


/home/karabi/Documents/project_spam/new_spam_auto/spam_data/spam_call_detection.sh

#while [ true ]
#do
##l=$( cat /home/karabi/Documents/project_spam/new_spam_auto/data/wav_list.scp |wc -l )
#echo "-------l="$l
#if [ $l -gt 1 ]; then
#	echo "------------------break"
#		break
#	fi
#done

done
flag=$(cat /home/karabi/Documents/project_spam/new_spam_auto/spam_data/r_alarm)
if [ $flag -eq 0 ]; then
	printf "\033[1;32m -------------------- NOT SPAM-------------------\033[0m\n"
fi
