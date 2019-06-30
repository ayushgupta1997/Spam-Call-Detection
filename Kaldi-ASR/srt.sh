#!/bin/bash
exec 3< /home/laxmi/Desktop/KWS_CM/data/train/wav2.scp
no_of_files= $(cat /home/laxmi/Desktop/KWS_CM/data/train/wav2.scp|wc -l)
echo "number of files = $no_of_files"
for ((i=1;i<$no_of_files;i++))
do
read <&3
filename=$REPLY
cp /home/laxmi/Documents/CH_MOD/TRAIN /home/laxmi/Documents/CH_MOD/TRAIN_NEW
done
