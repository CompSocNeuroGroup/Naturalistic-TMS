#!/bin/bash
set -e


########################################## READ COMMAND-LINE ARGUMENTS ##################################

Subject=${subject}
ResultsFolder="/scratch/csng/CSNG/data/output/stats"
LevelOnefMRINames=("VolumeStats-T1_s6-run-1" "VolumeStats-T1_s6-run-2")
LevelOnefsfNames=("design-run1")
LevelTwofMRIName="Localizer"
LevelTwofsfName="localizer"
LevelTwoDirName="VolumeStats-T1"
LowResMesh="32"
FinalSmoothingFWHM="0"
TemporalFilter="128"
Parcellation="NONE"
VolumeBasedProcessing="YES"
FinalSmoothingFWHM="0"



########################################## MAIN ##################################

##### DETERMINE ANALYSES TO RUN (DENSE, PARCELLATED, VOLUME) #####

# initialize run variables
runParcellated=false; runVolume=false; runDense=false;
Analyses=""; ExtensionList=""; ScalarExtensionList="";

# Determine whether to run Parcellated, and set strings used for filenaming
if [ "${Parcellation}" != "NONE" ] ; then
	# Run Parcellated Analyses
	runParcellated=true;
	ParcellationString="_${Parcellation}"
	ExtensionList="${ExtensionList}ptseries.nii "
	ScalarExtensionList="${ScalarExtensionList}pscalar.nii "
	Analyses="${Analyses}ParcellatedStats"; # space character at end to separate multiple analyses
	echo "MAIN: DETERMINE_ANALYSES: Parcellated Analysis requested"
fi

# Determine whether to run Dense, and set strings used for filenaming
if [ "${Parcellation}" = "NONE" ]; then
	# Run Dense Analyses
	runDense=true;
	ParcellationString=""
	ExtensionList="${ExtensionList}dtseries.nii "
	ScalarExtensionList="${ScalarExtensionList}dscalar.nii "
	#Analyses="${Analyses}GrayordinatesStats"; # space character at end to separate multiple analyses
	echo "MAIN: DETERMINE_ANALYSES: Dense Analysis requested"
fi

# Determine whether to run Volume, and set strings used for filenaming
if [ $VolumeBasedProcessing = "YES" ] ; then
	runParcellated=false;
	runDense=false;
	runVolume=true;
	ParcellationString=""
	ExtensionList="${ExtensionList}nii.gz "
	ScalarExtensionList="${ScalarExtensionList}volume.dscalar.nii "
	Analyses="${Analyses}${LevelTwoDirName}"; # space character at end to separate multiple analyses
	echo "MAIN: DETERMINE_ANALYSES: Volume Analysis requested"
fi

echo "MAIN: DETERMINE_ANALYSES: Analyses: ${Analyses}"
echo "MAIN: DETERMINE_ANALYSES: ParcellationString: ${ParcellationString}"
echo "MAIN: DETERMINE_ANALYSES: ExtensionList: ${ExtensionList}"
echo "MAIN: DETERMINE_ANALYSES: ScalarExtensionList: ${ScalarExtensionList}"


##### SET VARIABLES REQUIRED FOR FILE NAMING #####

### Set smoothing and filtering string variables used for file naming

# Set variables used for different registration procedures
SmoothingString="_s${FinalSmoothingFWHM}"
TemporalFilterString="_hp""$TemporalFilter"
echo "MAIN: SET_NAME_STRINGS: SmoothingString: ${SmoothingString}"
echo "MAIN: SET_NAME_STRINGS: TemporalFilterString: ${TemporalFilterString}"

### Figure out where the Level1 .feat directories are located
# Change '@' delimited arguments to space-delimited lists for use in for loops
LevelOnefMRINames=`echo $LevelOnefMRINames | sed 's/@/ /g'`
LevelOnefsfNames=`echo $LevelOnefsfNames | sed 's/@/ /g'`
# Loop over list to make string with paths to the Level1 .feat directories
LevelOneFEATDirSTRING=""
NumFirstLevelFolders=0; # counter
for LevelOnefMRIName in ${LevelOnefMRINames[@]} ; do 
  echo ${LevelOnefMRIName}
  NumFirstLevelFolders=$(($NumFirstLevelFolders+1));
  # get fsf name that corresponds to fMRI name
  #LevelOnefMRIName=`echo $LevelOnefMRINames | cut -d " " -f $NumFirstLevelFolders`;
  LevelOneFEATDirSTRING="${LevelOneFEATDirSTRING}${ResultsFolder}/sub-${Subject}/${LevelOnefMRIName} "; # space character at end is needed to separate multiple FEATDir strings
done

echo "MAIN: SET_DIR_STRINGS: Level1 FEATDir: ${LevelOneFEATDirSTRING}"
echo "MAIN: SET_DIR_STRINGS: Number of Level1 FEATDir: ${NumFirstLevelFolders}"

### Determine list of contrasts for this analysis
FirstFolder=`echo $LevelOneFEATDirSTRING | cut -d " " -f 1`
ContrastNames=`cat ${ResultsFolder}/sub-${Subject}/design-run-1.con | grep "ContrastName" | cut -f 2`
NumContrasts=`echo ${ContrastNames} | wc -w`
echo "MAIN: SET_NUMBER_CONTRASTS: Number of Contrasts: ${NumContrasts}"
#echo ${ContrastNames}

##### MAKE DESIGN FILES AND LEVEL2 DIRECTORY #####

# Make LevelTwoFEATDir
LevelTwoFEATDir="${ResultsFolder}/sub-${Subject}/${Analyses}_level2${ParcellationString}.gfeat"
if [ -e ${LevelTwoFEATDir} ] ; then
  rm -r ${LevelTwoFEATDir}
  mkdir ${LevelTwoFEATDir}
else
  mkdir -p ${LevelTwoFEATDir}
fi

# Edit template.fsf and place it in LevelTwoFEATDir
echo "MAIN: MAKE_DESIGNS: Copying fsf file to .feat directory"
cp ${ResultsFolder}/${LevelTwofsfName}_level2.fsf ${LevelTwoFEATDir}/design.fsf

# Make additional design files required by flameo
echo "Make design files"
cd ${LevelTwoFEATDir}; # Run feat_model inside LevelTwoFEATDir so relative paths work
feat_model ${LevelTwoFEATDir}/design
cd $OLDPWD; # Go back to previous directory using bash built-in $OLDPWD


##### RUN flameo (FIXED-EFFECTS GLM ANALYSIS ON LEVEL2) #####

### Loop over Level 2 Analyses requested
echo "Loop over Level 2 Analyses requested: ${Analyses}"
analysisCounter=1;
for Analysis in ${Analyses} ; do
	echo "Run Analysis: ${Analysis}"
	Extension=`echo $ExtensionList | cut -d' ' -f $analysisCounter`;
	ScalarExtension=`echo $ScalarExtensionList | cut -d' ' -f $analysisCounter`;

	### Exit if cope files are not present in Level 1 folders
	#fileCount=$( ls ${FirstFolder}/cope1.${Extension} 2>/dev/null | wc -l );
	#if [ "$fileCount" -eq 0 ]; then
	#	echo "ERROR: Missing expected cope files in ${FirstFolder}"
	#	echo "ERROR: Exiting $g_script_name"
	#	exit 1
	#fi
# 
	### Copy Level 1 stats folders into Level 2 analysis directory
	echo "Copy over Level 1 stats folders and convert CIFTI to NIFTI if required"
	mkdir -p ${LevelTwoFEATDir}/${Analysis}
	i=1
	for LevelOneFEATDir in ${LevelOneFEATDirSTRING} ; do
		mkdir -p ${LevelTwoFEATDir}/${Analysis}/${i}
		cp ${LevelOneFEATDir}/* ${LevelTwoFEATDir}/${Analysis}/${i}
		i=$(($i+1))
	done

	### convert CIFTI files to fakeNIFTI if required
	if [ "${Analysis}" != ${LevelTwoDirName} ] ; then
		echo "Convert CIFTI files to fakeNIFTI"
		fakeNIFTIused="YES"
		for CIFTI in ${LevelTwoFEATDir}/${Analysis}/*/*.${Extension} ; do
			fakeNIFTI=$( echo $CIFTI | sed -e "s|.${Extension}|.nii.gz|" );
			wb_command -cifti-convert -to-nifti $CIFTI $fakeNIFTI
			rm $CIFTI
		done
	else
		fakeNIFTIused="NO"
	fi

	### Create dof and Mask files for input to flameo (Level 2 analysis)
	echo "Create dof and Mask files for input to flameo (Level 2 analysis)"
	MERGESTRING=""
	i=1
	while [ "$i" -le "${NumFirstLevelFolders}" ] ; do
		dof=`cat ${LevelTwoFEATDir}/${Analysis}/${i}/dof`
		fslmaths ${LevelTwoFEATDir}/${Analysis}/${i}/res4d.nii.gz -Tstd -bin -mul $dof ${LevelTwoFEATDir}/${Analysis}/${i}/dofmask.nii.gz
		MERGESTRING=`echo "${MERGESTRING}${LevelTwoFEATDir}/${Analysis}/${i}/dofmask.nii.gz "`
		i=$(($i+1))
	done
	fslmerge -t ${LevelTwoFEATDir}/${Analysis}/dof.nii.gz $MERGESTRING
	fslmaths ${LevelTwoFEATDir}/${Analysis}/dof.nii.gz -Tmin -bin ${LevelTwoFEATDir}/${Analysis}/mask.nii.gz

	### Create merged cope and varcope files for input to flameo (Level 2 analysis)
	echo "Merge COPES and VARCOPES for ${NumContrasts} Contrasts"
	copeCounter=1
	while [ "$copeCounter" -le "${NumContrasts}" ] ; do
		echo "Contrast Number: ${copeCounter}"
		COPEMERGE=""
		VARCOPEMERGE=""
		i=1
		while [ "$i" -le "${NumFirstLevelFolders}" ] ; do
		  COPEMERGE="${COPEMERGE}${LevelTwoFEATDir}/${Analysis}/${i}/cope${copeCounter}.nii.gz "
		  VARCOPEMERGE="${VARCOPEMERGE}${LevelTwoFEATDir}/${Analysis}/${i}/varcope${copeCounter}.nii.gz "
		  i=$(($i+1))
		done
		fslmerge -t ${LevelTwoFEATDir}/${Analysis}/cope${copeCounter}.nii.gz $COPEMERGE
		fslmerge -t ${LevelTwoFEATDir}/${Analysis}/varcope${copeCounter}.nii.gz $VARCOPEMERGE
		copeCounter=$(($copeCounter+1))
	done

	### Run 2nd level analysis using flameo
	echo "Run flameo (Level 2 analysis) for ${NumContrasts} Contrasts"
	copeCounter=1
	while [ "$copeCounter" -le "${NumContrasts}" ] ; do
		echo "Contrast Number: ${copeCounter}"
		echo "$( which flameo )"
		echo "Command: flameo --cope=${Analysis}/cope${copeCounter}.nii.gz \\"
		echo "  --vc=${Analysis}/varcope${copeCounter}.nii.gz \\"
		echo "  --dvc=${Analysis}/dof.nii.gz \\"
		echo "  --mask=${Analysis}/mask.nii.gz \\"
		echo "  --ld=${Analysis}/cope${copeCounter}.feat \\"
		echo "  --dm=design.mat \\"
		echo "  --cs=design.grp \\"
		echo "  --tc=design.con \\"
		echo "  --runmode=fe"

		cd ${LevelTwoFEATDir}; # run flameo within LevelTwoFEATDir so relative paths work
		flameo --cope=${Analysis}/cope${copeCounter}.nii.gz \
			   --vc=${Analysis}/varcope${copeCounter}.nii.gz \
			   --dvc=${Analysis}/dof.nii.gz \
			   --mask=${Analysis}/mask.nii.gz \
			   --ld=${Analysis}/cope${copeCounter}.feat \
			   --dm=design.mat \
			   --cs=design.grp \
			   --tc=design.con \
			   --runmode=fe

		echo "Successfully completed flameo for Contrast Number: ${copeCounter}"
		cd $OLDPWD; # Go back to previous directory using bash built-in $OLDPWD
		copeCounter=$(($copeCounter+1))
	done

	### Cleanup Temporary Files (which were copied from Level1 stats directories)
	echo "Cleanup Temporary Files"
	i=1
	while [ "$i" -le "${NumFirstLevelFolders}" ] ; do
		rm -r ${LevelTwoFEATDir}/${Analysis}/${i}
		i=$(($i+1))
	done

# 	### Convert fakeNIFTI Files back to CIFTI (if necessary)
# 	if [ "$fakeNIFTIused" = "YES" ] ; then
# 		echo "Convert fakeNIFTI files back to CIFTI"
# 		CIFTItemplate="${LevelOneFEATDir}/pe1.${Extension}"
#
# 		# convert flameo input files for review: ${LevelTwoFEATDir}/${Analysis}/*.nii.gz
# 		# convert flameo output files for each cope: ${LevelTwoFEATDir}/${Analysis}/cope*.feat/*.nii.gz
# 		for fakeNIFTI in ${LevelTwoFEATDir}/${Analysis}/*.nii.gz ${LevelTwoFEATDir}/${Analysis}/cope*.feat/*.nii.gz; do
# 			CIFTI=$( echo $fakeNIFTI | sed -e "s|.nii.gz|.${Extension}|" );
# 			wb_command -cifti-convert -from-nifti $fakeNIFTI $CIFTItemplate $CIFTI -reset-timepoints 1 1
# 			rm $fakeNIFTI
# 		done
# 	fi
#
# 	### Generate Files for Viewing
# 	echo "Generate Files for Viewing"
# 	# Initialize strings used for fslmerge command
# 	zMergeSTRING=""
# 	bMergeSTRING=""
# 	touch ${LevelTwoFEATDir}/Contrasttemp.txt
# 	[ "${Analysis}" = "VolumeStats" ] && touch ${LevelTwoFEATDir}/wbtemp.txt
# 	[ -e "${LevelTwoFEATDir}/Contrasts.txt" ] && rm ${LevelTwoFEATDir}/Contrasts.txt
#
# 	# Loop over contrasts to identify cope and zstat files to merge into wb_view scalars
# 	copeCounter=1;
# 	while [ "$copeCounter" -le "${NumContrasts}" ] ; do
# 		Contrast=`echo $ContrastNames | cut -d " " -f $copeCounter`
# 		# Contrasts.txt is used to store the contrast names for this analysis
# 		echo ${Contrast} >> ${LevelTwoFEATDir}/Contrasts.txt
# 		# Contrasttemp.txt is a temporary file used to name the maps in the CIFTI scalar file
# 		echo "${Subject}_${LevelTwofsfName}_level2_${Contrast}${TemporalFilterString}${SmoothingString}${ParcellationString}" >> ${LevelTwoFEATDir}/Contrasttemp.txt
#
# 		if [ "${Analysis}" = "VolumeStats" ] ; then
#
# 			### Make temporary dtseries files to convert into scalar files
# 			# Converting volume to dense timeseries requires a volume label file
# 			echo "OTHER" >> ${LevelTwoFEATDir}/wbtemp.txt
# 			echo "1 255 255 255 255" >> ${LevelTwoFEATDir}/wbtemp.txt
# 			wb_command -volume-label-import ${LevelTwoFEATDir}/VolumeStats/mask.nii.gz ${LevelTwoFEATDir}/wbtemp.txt ${LevelTwoFEATDir}/VolumeStats/mask.nii.gz -discard-others -unlabeled-value 0
# 			rm ${LevelTwoFEATDir}/wbtemp.txt
#
# 			# Convert temporary volume CIFTI timeseries files
# 			wb_command -cifti-create-dense-timeseries ${LevelTwoFEATDir}/${Subject}_${LevelTwofsfName}_level2_zstat_${Contrast}${TemporalFilterString}${SmoothingString}${ParcellationString}.volume.dtseries.nii -volume ${LevelTwoFEATDir}/VolumeStats/cope${copeCounter}.feat/zstat1.nii.gz ${LevelTwoFEATDir}/VolumeStats/mask.nii.gz -timestep 1 -timestart 1
# 			wb_command -cifti-create-dense-timeseries ${LevelTwoFEATDir}/${Subject}_${LevelTwofsfName}_level2_cope_${Contrast}${TemporalFilterString}${SmoothingString}${ParcellationString}.volume.dtseries.nii -volume ${LevelTwoFEATDir}/VolumeStats/cope${copeCounter}.feat/cope1.nii.gz ${LevelTwoFEATDir}/VolumeStats/mask.nii.gz -timestep 1 -timestart 1
#
# 			# Convert volume CIFTI timeseries files to scalar files
# 			wb_command -cifti-convert-to-scalar ${LevelTwoFEATDir}/${Subject}_${LevelTwofsfName}_level2_zstat_${Contrast}${TemporalFilterString}${SmoothingString}${ParcellationString}.volume.dtseries.nii ROW ${LevelTwoFEATDir}/${Subject}_${LevelTwofsfName}_level2_zstat_${Contrast}${TemporalFilterString}${SmoothingString}${ParcellationString}.${ScalarExtension} -name-file ${LevelTwoFEATDir}/Contrasttemp.txt
# 			wb_command -cifti-convert-to-scalar ${LevelTwoFEATDir}/${Subject}_${LevelTwofsfName}_level2_cope_${Contrast}${TemporalFilterString}${SmoothingString}${ParcellationString}.volume.dtseries.nii ROW ${LevelTwoFEATDir}/${Subject}_${LevelTwofsfName}_level2_cope_${Contrast}${TemporalFilterString}${SmoothingString}${ParcellationString}.${ScalarExtension} -name-file ${LevelTwoFEATDir}/Contrasttemp.txt
#
# 			# Delete the temporary volume CIFTI timeseries files
# 			rm ${LevelTwoFEATDir}/${Subject}_${LevelTwofsfName}_level2_{cope,zstat}_${Contrast}${TemporalFilterString}${SmoothingString}${ParcellationString}.volume.dtseries.nii
# 		else
# 			### Convert CIFTI dense or parcellated timeseries to scalar files
# 			wb_command -cifti-convert-to-scalar ${LevelTwoFEATDir}/${Analysis}/cope${copeCounter}.feat/zstat1.${Extension} ROW ${LevelTwoFEATDir}/${Subject}_${LevelTwofsfName}_zstat_${Contrast}${TemporalFilterString}${SmoothingString}${ParcellationString}.${ScalarExtension} -name-file ${LevelTwoFEATDir}/Contrasttemp.txt
# 			wb_command -cifti-convert-to-scalar ${LevelTwoFEATDir}/${Analysis}/cope${copeCounter}.feat/cope1.${Extension} ROW ${LevelTwoFEATDir}/${Subject}_${LevelTwofsfName}_cope_${Contrast}${TemporalFilterString}${SmoothingString}${ParcellationString}.${ScalarExtension} -name-file ${LevelTwoFEATDir}/Contrasttemp.txt
# 		fi
#
# 		# These merge strings are used below to combine the multiple scalar files into a single file for visualization
# 		zMergeSTRING="${zMergeSTRING}-cifti ${LevelTwoFEATDir}/${Subject}_${LevelTwofsfName}_zstat_${Contrast}${TemporalFilterString}${SmoothingString}${ParcellationString}.${ScalarExtension} "
# 		bMergeSTRING="${bMergeSTRING}-cifti ${LevelTwoFEATDir}/${Subject}_${LevelTwofsfName}_cope_${Contrast}${TemporalFilterString}${SmoothingString}${ParcellationString}.${ScalarExtension} "
#
# 		# Remove Contrasttemp.txt file
# 		rm ${LevelTwoFEATDir}/Contrasttemp.txt
# 		copeCounter=$(($copeCounter+1))
# 	done
#
# 	# Perform the merge into viewable scalar files
# 	wb_command -cifti-merge ${LevelTwoFEATDir}/${Subject}_${LevelTwofsfName}_zstat${TemporalFilterString}${SmoothingString}${ParcellationString}.${ScalarExtension} ${zMergeSTRING}
# 	wb_command -cifti-merge ${LevelTwoFEATDir}/${Subject}_${LevelTwofsfName}_cope${TemporalFilterString}${SmoothingString}${ParcellationString}.${ScalarExtension} ${bMergeSTRING}
#
# 	analysisCounter=$(($analysisCounter+1))
 done  # end loop: for Analysis in ${Analyses}


echo "Complete"
