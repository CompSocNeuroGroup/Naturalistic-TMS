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
    

    #### Multi Echo Data
    # Opposite Phase Encode fieldmap and sbref
    #peepmedcmdir01=${dcmdir}/RFMRI_JIM_BOLD-PA_3_0*
    #peepmesbrefdcmdir01=${dcmdir}/RFMRI_JIM_BOLD-PA_3_SBREF_0*

    # Location of DICOMS - BOLD
    boldmedcmdir01=${dcmdir}/RFMRI_JIM_ME-2-1_0*
    boldmedcmdir02=${dcmdir}/RFMRI_JIM_ME-2-2_0*


    # Location of DICOMS - BOLD-SBREF
    boldmesbrefdcmdir01=${dcmdir}/RFMRI_JIM_ME-2-1_SBREF_00*
    boldmesbrefdcmdir02=${dcmdir}/RFMRI_JIM_ME-2-2_SBREF_00*


    mkdir -p ${niidir}/sub-${subj}/func
	###Convert dcm to nii
	for direcs in ${boldmedcmdir01} ${boldmedcmdir02}; do 
	    dcm2niix -o ${niidir}/sub-${subj} -f %f ${direcs}
	done

	#Changing directory into the subject folder
	cd ${niidir}/sub-${subj}

	##Rename func Single Echo files
	#Break the func down into each task
	#Capture the number of dissonance files to change
	BOLDfiles=$(ls -1 *JIM_ME-2-1*.nii | wc -l)
	for ((i=1;i<=BOLDfiles;i++)); do
	    BOLD=$(ls *JIM_ME-2-1*.nii) #This is to refresh the Checker variable, same as the Anat case
	    tempBOLD=$(ls -1 $BOLD | sed '1q;d') #Capture new file to change
	    tempBOLDext="${tempBOLD##*.}"
	    tempBOLDfile="${tempBOLD%.nii}"
	    #tr=$(echo $tempcheck | cut -d '_' -f3) #f3 is the third field delineated by _ to capture the acquisition TR from the filename
	    mv ${tempBOLDfile}.${tempBOLDext} sub-${subj}_task-localizer_run-1_echo-${i}_bold.${tempBOLDext}
	    echo "${tempBOLDfile}.${tempBOLDext} changed to sub-${subj}_task-localizer_run-1_echo-${i}_bold.${tempBOLDext}"
	done


	BOLDfiles=$(ls -1 *JIM_ME-2-1*.json | wc -l)
	for ((i=1;i<=BOLDfiles;i++)); do
	    BOLD=$(ls *JIM_ME-2-1*.json) #This is to refresh the Checker variable, same as the Anat case
	    tempBOLD=$(ls -1 $BOLD | sed '1q;d') #Capture new file to change
	    tempBOLDext="${tempBOLD##*.}"
	    tempBOLDfile="${tempBOLD%.json}"
	    #tr=$(echo $tempcheck | cut -d '_' -f3) #f3 is the third field delineated by _ to capture the acquisition TR from the filename
	    mv ${tempBOLDfile}.${tempBOLDext} sub-${subj}_task-localizer_run-1_echo-${i}_bold.${tempBOLDext}
	    echo "${tempBOLDfile}.${tempBOLDext} changed to sub-${subj}_task-localizer_run-1_echo-${i}_bold.${tempBOLDext}"
	done
	
    BOLDfiles=$(ls -1 *JIM_ME-2-2*.nii | wc -l)
	for ((i=1;i<=BOLDfiles;i++)); do
	    BOLD=$(ls *JIM_ME-2-2*.nii) #This is to refresh the Checker variable, same as the Anat case
	    tempBOLD=$(ls -1 $BOLD | sed '1q;d') #Capture new file to change
	    tempBOLDext="${tempBOLD##*.}"
	    tempBOLDfile="${tempBOLD%.nii}"
	    #tr=$(echo $tempcheck | cut -d '_' -f3) #f3 is the third field delineated by _ to capture the acquisition TR from the filename
	    mv ${tempBOLDfile}.${tempBOLDext} sub-${subj}_task-localizer_run-2_echo-${i}_bold.${tempBOLDext}
	    echo "${tempBOLDfile}.${tempBOLDext} changed to sub-${subj}_task-localizer_run-2_echo-${i}_bold.${tempBOLDext}"
	done


	BOLDfiles=$(ls -1 *JIM_ME-2-2*.json | wc -l)
	for ((i=1;i<=BOLDfiles;i++)); do
	    BOLD=$(ls *JIM_ME-2-2*.json) #This is to refresh the Checker variable, same as the Anat case
	    tempBOLD=$(ls -1 $BOLD | sed '1q;d') #Capture new file to change
	    tempBOLDext="${tempBOLD##*.}"
	    tempBOLDfile="${tempBOLD%.json}"
	    #tr=$(echo $tempcheck | cut -d '_' -f3) #f3 is the third field delineated by _ to capture the acquisition TR from the filename
	    mv ${tempBOLDfile}.${tempBOLDext} sub-${subj}_task-localizer_run-2_echo-${i}_bold.${tempBOLDext}
	    echo "${tempBOLDfile}.${tempBOLDext} changed to sub-${subj}_task-localizer_run-2_echo-${i}_bold.${tempBOLDext}"
	done


	###Organize files into folders
	for files in $(ls sub*); do 
	    Orgfile="${files%.*}"
	    Orgext="${files##*.}"
	    Modality=$(echo $Orgfile | rev | cut -d '_' -f1 | rev)
	    if [ $Modality == "bold" ]; then
		mv ${Orgfile}.${Orgext} func
	    else
		:
	    fi 
	done

	###Functional SBREF Organization####
	#Create subject folder
	#mkdir -p ${niidir}/sub-${subj}/func

	###Convert dcm to nii
	for direcs in ${boldmesbrefdcmdir01} ${boldmesbrefdcmdir02}; do 
	    dcm2niix -o ${niidir}/sub-${subj} -f %f ${direcs}
	done

	#Changing directory into the subject folder
	cd ${niidir}/sub-${subj}

	##Rename func files
	#Break the func down into each task
	#Capture the number of dissonance files to change
	BOLDfiles=$(ls -1 *JIM_ME-2-1*.nii | wc -l)
	for ((i=1;i<=BOLDfiles;i++)); do
	    BOLD=$(ls *JIM_ME-2-1*.nii) #This is to refresh the Checker variable, same as the Anat case
	    tempBOLD=$(ls -1 $BOLD | sed '1q;d') #Capture new file to change
	    tempBOLDext="${tempBOLD##*.}"
	    tempBOLDfile="${tempBOLD%.nii}"
	    #tr=$(echo $tempcheck | cut -d '_' -f3) #f3 is the third field delineated by _ to capture the acquisition TR from the filename
	    mv ${tempBOLDfile}.${tempBOLDext} sub-${subj}_task-localizer_run-1_echo-${i}_sbref.${tempBOLDext}
	    echo "${tempBOLDfile}.${tempBOLDext} changed to sub-${subj}_task-localizer_run-1_echo-${i}_sbref.${tempBOLDext}"
	done


	BOLDfiles=$(ls -1 *JIM_ME-2-1*.json | wc -l)
	for ((i=1;i<=BOLDfiles;i++)); do
	    BOLD=$(ls *JIM_ME-2-1*.json) #This is to refresh the Checker variable, same as the Anat case
	    tempBOLD=$(ls -1 $BOLD | sed '1q;d') #Capture new file to change
	    tempBOLDext="${tempBOLD##*.}"
	    tempBOLDfile="${tempBOLD%.json}"
	    #tr=$(echo $tempcheck | cut -d '_' -f3) #f3 is the third field delineated by _ to capture the acquisition TR from the filename
	    mv ${tempBOLDfile}.${tempBOLDext} sub-${subj}_task-localizer_run-1_echo-${i}_sbref.${tempBOLDext}
	    echo "${tempBOLDfile}.${tempBOLDext} changed to sub-${subj}_task-localizer_run-1_echo-${i}_sbref.${tempBOLDext}"
	done
	
	BOLDfiles=$(ls -1 *JIM_ME-2-2*.nii | wc -l)
	for ((i=1;i<=BOLDfiles;i++)); do
	    BOLD=$(ls *JIM_ME-2-2*.nii) #This is to refresh the Checker variable, same as the Anat case
	    tempBOLD=$(ls -1 $BOLD | sed '1q;d') #Capture new file to change
	    tempBOLDext="${tempBOLD##*.}"
	    tempBOLDfile="${tempBOLD%.nii}"
	    #tr=$(echo $tempcheck | cut -d '_' -f3) #f3 is the third field delineated by _ to capture the acquisition TR from the filename
	    mv ${tempBOLDfile}.${tempBOLDext} sub-${subj}_task-localizer_run-2_echo-${i}_sbref.${tempBOLDext}
	    echo "${tempBOLDfile}.${tempBOLDext} changed to sub-${subj}_task-localizer_run-2_echo-${i}_sbref.${tempBOLDext}"
	done


	BOLDfiles=$(ls -1 *JIM_ME-2-2*.json | wc -l)
	for ((i=1;i<=BOLDfiles;i++)); do
	    BOLD=$(ls *JIM_ME-2-2*.json) #This is to refresh the Checker variable, same as the Anat case
	    tempBOLD=$(ls -1 $BOLD | sed '1q;d') #Capture new file to change
	    tempBOLDext="${tempBOLD##*.}"
	    tempBOLDfile="${tempBOLD%.json}"
	    #tr=$(echo $tempcheck | cut -d '_' -f3) #f3 is the third field delineated by _ to capture the acquisition TR from the filename
	    mv ${tempBOLDfile}.${tempBOLDext} sub-${subj}_task-localizer_run-2_echo-${i}_sbref.${tempBOLDext}
	    echo "${tempBOLDfile}.${tempBOLDext} changed to sub-${subj}_task-localizer_run-2_echo-${i}_sbref.${tempBOLDext}"
	done
	

	###Organize files into folders
	for files in $(ls sub*); do 
	    Orgfile="${files%.*}"
	    Orgext="${files##*.}"
	    Modality=$(echo $Orgfile | rev | cut -d '_' -f1 | rev)
	    if [ $Modality == "sbref" ]; then
		mv ${Orgfile}.${Orgext} func
	    else
		:
	    fi 
	done

# 	###PEPOLAR fieldmaps####
# 	#Create subject folder
# 	mkdir -p ${niidir}/sub-${subj}/fmap
#
# 	###Convert dcm to nii
# 	for direcs in ${peepmedcmdir01}; do
# 	    dcm2niix -o ${niidir}/sub-${subj} -f %f ${direcs}
# 	done
#
# 	#Changing directory into the subject folder
# 	cd ${niidir}/sub-${subj}
#
# 	##Rename func files
# 	#Break the func down into each task
# 	#Capture the number of dissonance files to change
# 	PEEPIfiles=$(ls -1 *_JIM_*-PA_*.nii | wc -l)
# 	for ((i=1;i<=PEEPIfiles;i++)); do
# 	    PEEPI=$(ls *_JIM_*-PA_*.nii) #This is to refresh the Checker variable, same as the Anat case
# 	    tempPEEPI=$(ls -1 $PEEPI | sed '1q;d') #Capture new file to change
# 	    tempPEEPIext="${tempPEEPI##*.}"
# 	    tempPEEPIfile="${tempPEEPI%.nii}"
# 	    #tr=$(echo $tempcheck | cut -d '_' -f3) #f3 is the third field delineated by _ to capture the acquisition TR from the filename
# 	    mv ${tempPEEPIfile}.${tempPEEPIext} sub-${subj}_dir-PA_run-1_epi.${tempPEEPIext}
# 	    echo "${tempPEEPIfile}.${tempPEEPIext} changed to sub-${subj}_dir-PA_run-1_epi.${tempPEEPIext}"
# 	done
#
# 	PEEPIfiles=$(ls -1 *_JIM_*-PA_*.json | wc -l)
# 	for ((i=1;i<=PEEPIfiles;i++)); do
# 	    PEEPI=$(ls *_JIM_*-PA_*.json) #This is to refresh the Checker variable, same as the Anat case
# 	    tempPEEPI=$(ls -1 $PEEPI | sed '1q;d') #Capture new file to change
# 	    tempPEEPIext="${tempPEEPI##*.}"
# 	    tempPEEPIfile="${tempPEEPI%.json}"
# 	    #tr=$(echo $tempcheck | cut -d '_' -f3) #f3 is the third field delineated by _ to capture the acquisition TR from the filename
# 	    mv ${tempPEEPIfile}.${tempPEEPIext} sub-${subj}_dir-PA_run-1_epi.${tempPEEPIext}
# 	    echo "${tempPEEPIfile}.${tempPEEPIext} changed to sub-${subj}_dir-PA_run-1_epi.${tempPEEPIext}"
#
# 	done
#
# 	###Organize files into folders
# 	for files in $(ls sub*); do
# 	    Orgfile="${files%.*}"
# 	    Orgext="${files##*.}"
# 	    Modality=$(echo $Orgfile | rev | cut -d '_' -f1 | rev)
# 	    if [ $Modality == "epi" ]; then
# 		mv ${Orgfile}.${Orgext} fmap
# 	    else
# 		:
# 	    fi
# 	done

	
	#gzip *.nii files
	#gzip ${niidir}/sub-$subj/anat/*.nii
	#gzip ${niidir}/sub-$subj/fmap/*.nii
	gzip ${niidir}/sub-$subj/func/*.nii
	
# 	# ###Add IntendedFor to FMAP files to run w fMRIPREP
# 	wDir=$(pwd)
# 	cd ${niidir}/sub-$subj/
#     line=$(grep -n '"EchoTime":' fmap/sub-${subj}_dir-PA_run-1_epi.json | cut -d : -f 1)
#     next=1
#     lineout=$(($line + $next))
#
#     array=()
#     array=(`find func/*echo-*_bold.nii.gz -type f`)
#     var=$( IFS=$'\n'; printf "\"${array[*]}"\" )
#     filenames=$(echo $var | sed 's/ /", "/g')
#     textin=$(echo -e '"IntendedFor": ['$filenames'],')
#     sed -i "${lineout}i $textin " fmap/sub-${subj}_dir-PA_run-1_epi.json
#
#     rm -rf fmap/sub-${subj}_dir-PA_run-1_echo-2_epi.
#     *
# 	cd $wDir
	


	
