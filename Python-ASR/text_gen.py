# Python script for generating trans text file
import os
dir_name = 'spm8'
path = '/home/pallavi/Desktop/SummerProject/LibriSpeech/valid-clean-100/12/'+ dir_name # All subdirectory path should be given 

files = []
# r=root, d=directories, f = files
for r, d, f in os.walk(path):
    for file in f:
        if '.txt' in file:
            #files.append(os.path.join(r, file))
            files.append(file)

#for f in files:
#	print(f)
with open('12-' + dir_name+'.trans.txt', 'w') as main_file:
	for i in files:
		with open(path+'/'+i, 'r') as cur_file:
			data = cur_file.read()
			str1 = i[0:len(i)-4]
			temp = str(12) + '-' + dir_name +'-' +  str1 + ' ' + data
			#print('{} {}'.format(str1, data))
			#print(temp)
			main_file.write(temp)
	
