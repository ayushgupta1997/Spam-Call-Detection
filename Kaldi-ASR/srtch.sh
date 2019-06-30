exec 3<  /home/karabi/Documents/Children_Model/data/train/uttid
no_of_files=$(cat /home/karabi/Documents/Children_Model/data/train/uttid| wc -l)
echo "number of files =$no_of_files"
for ((i=1;i<= $no_of_files;i++))
do
read <&3

file_name=$REPLY

cp /home/karabi/Documents/Children_Model/corpus/train_pfstar/$file_name.wav /home/karabi/Documents/Children_Model/CH_MOD/test/$file_name.wav
done 

