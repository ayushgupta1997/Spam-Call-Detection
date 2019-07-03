# Python script for generating trans text file
import os
dir_name = 'spm8'
path = '/home/pallavi/Desktop/SummerProject/LibriSpeech/valid-clean-100/12/'+ dir_name # All subdirectory path should be given 

files = []
# r=root, d=directories, f = files
for r, d, f in os.walk(path):
    for file in f:
        if '.wav' in file:
            #files.append(os.path.join(r, file))
            files.append(file)
os.chdir(path)
for f in files:
	temp = '12' + '-' + dir_name +'-' + f
	#print(temp)
	os.rename(f, temp) 
