#!/bin/bash

# save the to your desktop to easily run from terminal
# cd into folder to run
# programmed by Lauren Breithaupt 
# modified by JT 03.04.19

set -e 
####Defining pathways
## ajn ## toplvl=/mnt/EE9A47C59A478953/data/fmri/SR08
toplev=$1
## ajn ## dcmdir=/mnt/EE9A47C59A478953/data/fmri/SR08/THOMPSON*/THOMPSON*

###Create dataset_description.json
niidir=${toplev}/CSNG/data/nifti
if [[ ! -f ${niidir}/dataset_description.json ]]
    then
    jo -p "Name"="encode" "BIDSVersion"="1.0.2" >> ${niidir}/dataset_description.json
fi

#for subj in 05 17; do
    subj=$( echo $subject | cut -d'-' -f 2)
    dcmdir=$toplev/CSNG/data/raw/sub-$subj

    # Location of DICOMs - fieldmaps
    fm_mag_dcmdir=${dcmdir}/GRE_FIELD*_0009*
    fm_pha_dcmdir=${dcmdir}/GRE_FIELD*_0010*

    # Fieldmap files
    fmap_mag=_0009
    fmap_pha=_0010





    ####Anatomical Organization####

	echo "Processing subject $subj"



	###Field Maps####
	#Create subject folder
	mkdir -p ${niidir}/sub-${subj}/fmap
	
	###Convert dcm to nii
	for direcs in ${fm_mag_dcmdir} ${fm_pha_dcmdir}; do 
        dcm2niix -o ${niidir}/sub-${subj} -f %f ${direcs}
	done
	
	#Changing directory into the subject folder
	cd ${niidir}/sub-${subj}
	
	
	grefiles=$(ls -1 *${fmap_mag}*e1* | wc -l)
	for ((i=1;i<=${grefiles};i++)); do
	GRE=$(ls *${fmap_mag}*e1*) #This is to refresh the Anat variable, if this is not in the loop, each iteration a new "No such file or directory error", this is because the filename was changed. 
	tempgre=$(ls -1 $GRE | sed '1q;d') #Capture new file to change
	tempgreext="${tempgre##*.}"
	tempgrefile="${tempgre%.*}"
	mv ${tempgrefile}.${tempgreext} sub-${subj}_magnitude1.${tempgreext}
	echo "${tempgre} changed to sub-${subj}_magnitude1.${tempgreext}"
	done 
	
	grefiles=$(ls -1 *${fmap_mag}*e2* | wc -l)
	for ((i=1;i<=${grefiles};i++)); do
	GRE=$(ls *${fmap_mag}*e2*) #This is to refresh the Anat variable, if this is not in the loop, each iteration a new "No such file or directory error", this is because the filename was changed. 
	tempgre=$(ls -1 $GRE | sed '1q;d') #Capture new file to change
	tempgreext="${tempgre##*.}"
	tempgrefile="${tempgre%.*}"
	mv ${tempgrefile}.${tempgreext} sub-${subj}_magnitude2.${tempgreext}
	echo "${tempgre} changed to sub-${subj}_magnitude2.${tempgreext}"
	done
	
	grefiles=$(ls -1 *${fmap_pha}*e2* | wc -l)
	for ((i=1;i<=${grefiles};i++)); do
	GRE=$(ls *${fmap_pha}*e2*) #This is to refresh the Anat variable, if this is not in the loop, each iteration a new "No such file or directory error", this is because the filename was changed. 
	tempgre=$(ls -1 $GRE | sed '1q;d') #Capture new file to change
	tempgreext="${tempgre##*.}"
	tempgrefile="${tempgre%.*}"
	mv ${tempgrefile}.${tempgreext} sub-${subj}_phasediff.${tempgreext}
	echo "${tempgre} changed to sub-${subj}_phasediff.${tempgreext}"
	done 
	
	###Organize files into folders
	for files in $(ls sub*); do 
	Orgfile="${files%.*}"
	Orgext="${files##*.}"
	Modality=$(echo $Orgfile | rev | cut -d '_' -f1 | rev)
	if [ $Modality == "magnitude1" ]; then
		mv ${Orgfile}.${Orgext} fmap
	elif [ $Modality == "magnitude2" ]; then
		mv ${Orgfile}.${Orgext} fmap
	elif [ $Modality == "phasediff" ]; then
		mv ${Orgfile}.${Orgext} fmap
	else
		rm -f *_e2*
	fi 
	done


gzip ${niidir}/sub-$subj/fmap/*_magnitude*.nii
gzip ${niidir}/sub-$subj/fmap/*_phasediff*.nii

	# ###Add IntendedFor to FMAP files to run w fMRIPREP
	wDir=$(pwd)
	cd ${niidir}/sub-$subj/
    line=$(grep -n '"EchoTime":' fmap/sub-${subj}_magnitude1.json | cut -d : -f 1)
    next=1
    lineout=$(($line + $next))
    
    echo1=$(grep -n '"EchoTime":' fmap/sub-${subj}_magnitude1.json | cut -d : -f3)

    array=()
    array=(`find func/*echo-*_bold.nii.gz -type f`)
    var=$( IFS=$'\n'; printf "\"${array[*]}"\" )
    filenames=$(echo $var | sed 's/ /", "/g')
    textin=$(echo -e '"IntendedFor": ['$filenames'],')
    sed -i "${lineout}i $textin " fmap/sub-${subj}_magnitude1.json
    
    	# ###Add IntendedFor to FMAP files to run w fMRIPREP
	wDir=$(pwd)
	cd ${niidir}/sub-$subj/
    line=$(grep -n '"EchoTime":' fmap/sub-${subj}_magnitude2.json | cut -d : -f 1)
    next=1
    lineout=$(($line + $next))
    
    echo2=$(grep -n '"EchoTime":' fmap/sub-${subj}_magnitude2.json | cut -d : -f3)

    array=()
    array=(`find func/*echo-*_bold.nii.gz -type f`)
    var=$( IFS=$'\n'; printf "\"${array[*]}"\" )
    filenames=$(echo $var | sed 's/ /", "/g')
    textin=$(echo -e '"IntendedFor": ['$filenames'],')
    sed -i "${lineout}i $textin " fmap/sub-${subj}_magnitude2.json
    
    	# ###Add IntendedFor to FMAP files to run w fMRIPREP
	wDir=$(pwd)
	cd ${niidir}/sub-$subj/
    line=$(grep -n '"EchoTime":' fmap/sub-${subj}_phasediff.json | cut -d : -f 1)
    next=1
    lineout=$(($line + $next))

    array=()
    array=(`find func/*echo-*_bold.nii.gz -type f`)
    var=$( IFS=$'\n'; printf "\"${array[*]}"\" )
    filenames=$(echo $var | sed 's/ /", "/g')
    textin=$(echo -e '"IntendedFor": ['$filenames'],')
    sed -i "${lineout}i $textin " fmap/sub-${subj}_phasediff.json
    
    line=$(grep -n '"EchoTime":' fmap/sub-${subj}_phasediff.json | cut -d : -f 1)
    next=1
    lineout=$(($line + $next))
    
    textin=$(echo -e '"EchoTime1": '$echo1'')
    sed -i "${line}i $textin " fmap/sub-${subj}_phasediff.json
    
    textin=$(echo -e '"EchoTime2": '$echo2'')
    sed -i "${lineout}i $textin " fmap/sub-${subj}_phasediff.json
    
    grep -v '"EchoTime":' fmap/sub-${subj}_phasediff.json > fmap/tmpfile && mv fmap/tmpfile fmap/sub-${subj}_phasediff.json
    
    
