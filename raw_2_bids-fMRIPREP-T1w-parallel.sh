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
    

    # Location of DICOMs - anatomicals
    t1wdcmdir01=${dcmdir}/T1_MPRAGE_SAG_P2_ISO_00*
    t1wdcmdir02=${dcmdir}/T1_MPRAGE_AXIAL_BRAINSIGHT*
    #t2wdcmdir=${dcmdir}/T2_SPACE*

    # Location of DICOMs - fieldmaps
    #fm_mag_dcmdir=${dcmdir}/GRE_FIELD*_0005*
    #fm_pha_dcmdir=${dcmdir}/GRE_FIELD*_0006*

    # Fieldmap files
    #fmap_mag=_0005
    #fmap_pha=_0006

    # Opposite Phase Encode fieldmap and sbref
    #peepidcmdir01=${dcmdir}/RFMRI_BEN_BOLD-PA_2_0028*
    #peepisbrefdcmdir01=${dcmdir}/RFMRI_BEN_BOLD-PA_2_SBREF_0027*

    # Location of DICOMS - BOLD
    #bolddcmdir01=${dcmdir}/RFMRI_BEN_BOLD-AP_2_0*
#     bolddcmdir02=${dcmdir}/RFMRI_BEN_BOLD-AP_2_0*
#     bolddcmdir03=${dcmdir}/RFMRI_BEN_BOLD-AP_3_0*
#     bolddcmdir04=${dcmdir}/RFMRI_BEN_BOLD-AP_4_0*
#     bolddcmdir05=${dcmdir}/RFMRI_BEN_BOLD-AP_5_0*
#     bolddcmdir06=${dcmdir}/RFMRI_BEN_BOLD-AP_6_0*
#     bolddcmdir07=${dcmdir}/RFMRI_BEN_BOLD-AP_7_0*
#     bolddcmdir08=${dcmdir}/RFMRI_BEN_BOLD-AP_8_0*
#     bolddcmdir09=${dcmdir}/RFMRI_BEN_BOLD-AP_9_0*
#     bolddcmdir10=${dcmdir}/RFMRI_BEN_BOLD-AP_10_0*

    # Location of DICOMS - BOLD-SBREF
    #boldsbrefdcmdir01=${dcmdir}/RFMRI_BEN_BOLD-AP_2_SBREF_00*
#     boldsbrefdcmdir02=${dcmdir}/RFMRI_BEN_BOLD-AP_2_SBREF_00*
#     boldsbrefdcmdir03=${dcmdir}/RFMRI_BEN_BOLD-AP_3_SBREF_00*
#     boldsbrefdcmdir04=${dcmdir}/RFMRI_BEN_BOLD-AP_4_SBREF_00*
#     boldsbrefdcmdir05=${dcmdir}/RFMRI_BEN_BOLD-AP_5_SBREF_00*
#     boldsbrefdcmdir06=${dcmdir}/RFMRI_BEN_BOLD-AP_6_SBREF_00*
#     boldsbrefdcmdir07=${dcmdir}/RFMRI_BEN_BOLD-AP_7_SBREF_00*
#     boldsbrefdcmdir08=${dcmdir}/RFMRI_BEN_BOLD-AP_8_SBREF_00*
#     boldsbrefdcmdir09=${dcmdir}/RFMRI_BEN_BOLD-AP_9_SBREF_00*
#     boldsbrefdcmdir10=${dcmdir}/RFMRI_BEN_BOLD-AP_10_SBREF_00*


    # BOLD tasknames - correspond to BOLD data above
    #boldname01=motor01
    #boldname02=motor02

    #dcm2niidir=/usr/bin
    #Create nifti directory
    #mkdir ${toplev}/nifti




    ####Anatomical Organization####

	echo "Processing subject $subj"

	###Create structure
	mkdir -p ${niidir}/sub-${subj}/anat

	###Convert dcm to nii
	#Only convert the Dicom folder anat
	for direcs in ${t1wdcmdir01} ${t1wdcmdir02}; do
	    dcm2niix -o ${niidir}/sub-${subj} -f ${subj}_%f_%p ${direcs}
	done

	#Changing directory into the subject folder
	cd ${niidir}/sub-${subj}

	###Change filenames
	##Rename anat files
	#Example filename: 01_anat_MPRAGE
	#BIDS filename: sub-01_ses-1_T1w
	#Capture the number of anat files to change
	anatfiles=$(ls -1 *MPRAGE_SAG* | wc -l)
	for ((i=1;i<=${anatfiles};i++)); do
	    Anat=$(ls *MPRAGE_SAG*) #This is to refresh the Anat variable, if this is not in the loop, each iteration a new "No such file or directory error", this is because the filename was changed. 
	    tempanat=$(ls -1 $Anat | sed '1q;d') #Capture new file to change
	    tempanatext="${tempanat##*.}"
	    tempanatfile="${tempanat%.*}"
	    mv ${tempanatfile}.${tempanatext} sub-${subj}_acq-sag_T1w.${tempanatext}
	    echo "${tempanat} changed to sub-${subj}_acq-sag_T1w.${tempanatext}"
	done
	
	anatfiles=$(ls -1 *MPRAGE_AXIAL* | wc -l)
	for ((i=1;i<=${anatfiles};i++)); do
	    Anat=$(ls *MPRAGE_AXIAL*) #This is to refresh the Anat variable, if this is not in the loop, each iteration a new "No such file or directory error", this is because the filename was changed. 
	    tempanat=$(ls -1 $Anat | sed '1q;d') #Capture new file to change
	    tempanatext="${tempanat##*.}"
	    tempanatfile="${tempanat%.*}"
	    mv ${tempanatfile}.${tempanatext} sub-${subj}_acq-axial_T1w.${tempanatext}
	    echo "${tempanat} changed to sub-${subj}_acq-axial_T1w.${tempanatext}"
	done 

	anatfiles=$(ls -1 *SPACE* | wc -l)
	for ((i=1;i<=${anatfiles};i++)); do
	Anat=$(ls *SPACE*) #This is to refresh the Anat variable, if this is not in the loop, each iteration a new "No such file or directory error", this is because the filename was changed.
	tempanat=$(ls -1 $Anat | sed '1q;d') #Capture new file to change
	tempanatext="${tempanat##*.}"
	tempanatfile="${tempanat%.*}"
	mv ${tempanatfile}.${tempanatext} sub-${subj}_T2w.${tempanatext}
	echo "${tempanat} changed to sub-${subj}_T2w.${tempanatext}"
	done

	###Organize files into folders
	for files in $(ls sub*); do 
	    Orgfile="${files%.*}"
	    Orgext="${files##*.}"
	    Modality=$(echo $Orgfile | rev | cut -d '_' -f1 | rev)
	    if [ $Modality == "T1w" ]; then
		mv ${Orgfile}.${Orgext} anat
	    elif [ $Modality == "T2w" ]; then
		mv ${Orgfile}.${Orgext} anat
	    else
		:
	    fi 
	done

gzip ${niidir}/sub-$subj/anat/*.nii
