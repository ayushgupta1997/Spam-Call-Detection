for i in TIMIT-0001 TIMIT-0002 TIMIT-0003 TIMIT-0004 TIMIT-0005 TIMIT-0006 TIMIT-0007 TIMIT-0008 TIMIT-0009 TIMIT-0010 TIMIT-0011 TIMIT-0012 TIMIT-0013 TIMIT-0014 TIMIT-0015 TIMIT-0016 TIMIT-0017 TIMIT-0018 TIMIT-0019 TIMIT-0020 															
do
echo $i
echo "YES"
cat kwslist_20 | awk /"$i"/ >txt
tr -s ' ' '\n' <txt |grep -c 'decision="YES"'
echo "NO"
tr -s ' ' '\n' <txt |grep -c 'decision="NO"'
done >keywords_20

