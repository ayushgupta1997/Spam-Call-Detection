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

rm -rf /home/shivani/project_spam/new_spam_auto/spam_data/r_count
rm -rf /home/shivani/project_spam/new_spam_auto/spam_data/r_keyword
rm -rf /home/shivani/project_spam/new_spam_auto/spam_data/counts.txt
rm -rf /home/shivani/project_spam/new_spam_auto/spam_data/per_utt1
#
feats_nj=10
train_nj=10
decode_nj=5


data_prep=1
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

#if [ $data_prep == 1  ]; then
echo =======================================================================
echo "                 preprocessing                          "
echo =======================================================================
#duration=$(soxi -D /home/shivani/project_spam/new_spam_auto/Test/a023_akanksha_01.wav)
#echo "--------------------duration--------------------"$duration
find /home/shivani/project_spam/new_spam_auto/Test/* -name '*.wav' > /home/shivani/project_spam/new_spam_auto/data/wav_list.scp
exec 4< /home/shivani/project_spam/new_spam_auto/data/wav_list.scp
read <&4

wav_list=$REPLY
part=10
gst-launch-1.0 playbin uri=file://$wav_list &
duration=$(soxi -D $wav_list)
echo "duration=" $duration
l_count1=`echo 'scale=4; '$duration'/'$part'' | bc -l`

echo "l_count: "$l_count1
ceiling $l_count1

l_count=$(($ceil_val))
echo "l_count: " $l_count


echo 0 >>'/home/shivani/project_spam/new_spam_auto/spam_data/r_count'
echo "" >>'/home/shivani/project_spam/new_spam_auto/spam_data/r_keyword'
echo 0 >>'/home/shivani/project_spam/new_spam_auto/spam_data/r_alarm'
for ((j=0;j<$l_count;j++))
do
echo "----------------j="$j
start_time=$(( $j * 10 )) 

echo "start_time: " $start_time
floor `echo ''$start_time'/60' | bc -l`
s_min=$(($floor_val))
s_sec=$(( $start_time -( 60* $s_min ) )) 

echo "s_min="$s_min
echo "s_sec="$s_sec
end_time=$(( ($j + 1)*10 ))
floor `echo ''$end_time'/60' | bc -l`
e_min=$(($floor_val))
e_sec=$(( $end_time -( 60* $e_min ) )) 

echo "end_time" $end_time

echo "e_min="$e_min
echo "e_sec="$e_sec
sleep 11s
rm -rf '/home/shivani/project_spam/new_spam_auto/testing/output1.wav'
avconv -i $wav_list -vcodec copy -acodec copy -ss 00:$s_min:$s_sec -t 00:00:11 /home/shivani/project_spam/new_spam_auto/testing/output1.wav

#avconv -i $wav_list -vcodec copy -acodec copy -ss 00:00:00 -t 00:00:10 /home/shivani/project_spam/new_spam_auto/testing/output1.wav

#fi


#if [ $feat_extract == 1  ]; then
echo ============================================================================
echo "         MFCC Feature Extration & CMVN for Training and Test set          "
echo ============================================================================

# Now make MFCC features.
mfccdir=mfcc


 
	#find /home/shivani/project_spam/new_spam_auto/testing/* -name *.wav > /home/shivani/project_spam/new_spam_auto/data/wav.scp
	#echo 
	#/home/shivani/project_spam/KWS_SPAM/utils/utt2spk_to_spk2utt.pl data_new/utt2spk data_new/spk2utt	
  steps/make_mfcc.sh --cmd "$train_cmd" --nj 1 /home/shivani/project_spam/new_spam_auto/data exp_new1/make_mfcc $mfccdir
  steps/compute_cmvn_stats.sh /home/shivani/project_spam/new_spam_auto/data exp_new1/make_mfcc $mfccdir

#fi





#if [ $tri3_decode == 1  ]; then
echo ============================================================================
echo "              tri3 : LDA + MLLT + SAT Decoding                 "
echo ============================================================================
#utils/mkgraph.sh data/lang_test_bg exp_new1/tri3 exp_new1/tri3/graph

 steps/decode_fmllr_extra.sh --skip-scoring $skip_scoring --beam 1 --lattice-beam 1\
   --nj 1 --cmd "$decode_cmd" "${decode_extra_opts[@]}"\
    exp_new1/tri3/graph /home/shivani/project_spam/new_spam_auto/data exp_new1/tri3/decode_test

#fi

/home/shivani/project_spam/new_spam_auto/spam_data/spam_call_detection.sh
done

