#!/bin/bash
set -e



########################################## READ_ARGS ##################################
Subject=${subject}
Run="run-1"
OtherRun="run1"
ResultsFolder="/scratch/csng/CSNG/data/output/fmriprep/sub-${Subject}/func"
LevelOnefMRIName="task-localizer_${Run}"
FEATDir="/scratch/csng/CSNG/data/output/stats"
fMRIPREPDir="/scratch/csng/CSNG/data/output/fmriprep/sub-${Subject}/func"
VolStatsDir="VolumeStats-T1"
TemplateFSF="localizer-run1.fsf"
#DesignMatrix="localizer-run1.mat"
#DesignContrasts="localizer-run1.con"
#ParcellationDir="/mnt/EE9A47C59A478953/data/NS-SocRew/data/parcellations"
#ParcellationFile="HCP-Sub"
TemporalFilter="128"
#Confound="sub-${Subject}_task-paced_${Run}_desc-confounds_compcor24.tsv"
VolumeBasedProcessing="YES"
FinalSmoothingFWHM="6"
OriginalSmoothingFWHM="0"



########################################## MAIN ##################################

##### DETERMINE ANALYSES TO RUN (DENSE, PARCELLATED, VOLUME) #####
# initialize run variables
runParcellated=false; runDense=false;

# Determine whether to run Parcellated, and set strings used for filenaming
if [ "${Parcellation}" != "NONE" ] ; then
	# Run Parcellated Analyses
	runParcellated=true;
	ParcellationString="_${Parcellation}"
	Extension="ptseries.nii"
	echo "MAIN: DETERMINE_ANALYSES: Parcellated Analysis requested"
fi

# Determine whether to run Dense, and set strings used for filenaming
if [ "${Parcellation}" = "NONE" ]; then
	# Run Dense Analyses
	runDense=true;
	ParcellationString=""
	Extension="dtseries.nii"
	echo "MAIN: DETERMINE_ANALYSES: Dense Analysis requested"
fi

# Determine whether to run Volume, and set strings used for filenaming
if [ "$VolumeBasedProcessing" = "YES" ] ; then
	runParcellated=false;
	runDense=false;
	runVolume=true;
	echo "MAIN: DETERMINE_ANALYSES: Volume Analysis requested"
fi

##### SET_NAME_STRINGS: smoothing and filtering string variables used for file naming #####
SmoothingString="_s${FinalSmoothingFWHM}"
TemporalFilterString="_hp""$TemporalFilter"
# Set variables used for different registration procedures
if [ "${RegName}" != "NONE" ] ; then
	RegString="_${RegName}"
else
	RegString=""
fi

##### IMAGE_INFO: DETERMINE TR AND SCAN LENGTH #####
# Caution: Reading information for Parcellated and Volume analyses from original CIFTI file
# Extract TR information from input time series files
TR_vol=`wb_command -file-information ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_space-T1w_desc-optcomDenoised_bold.nii.gz -no-map-info -only-step-interval`
echo "MAIN: IMAGE_INFO: TR_vol: ${TR_vol}"

# Extract number of time points in CIFTI time series file
npts=`wb_command -file-information ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_space-T1w_desc-optcomDenoised_bold.nii.gz -no-map-info -only-number-of-maps`
echo "MAIN: IMAGE_INFO: npts: ${npts}"


##### MAKE_DESIGNS: MAKE DESIGN FILES #####

# Create output .feat directory ($FEATDir) for this analysis
#FEATDir="${ResultsFolder}/${LevelOnefMRIName}/${LevelOnefsfName}${TemporalFilterString}_level1${RegString}${ParcellationString}.feat"
echo "MAIN: MAKE_DESIGNS: FEATDir: ${FEATDir}/sub-${Subject}"
if [ -e ${FEATDir}/sub-${Subject} ] ; then
	#rm -r ${FEATDir}/sub-${Subject}
	#mkdir ${FEATDir}/sub-${Subject}
	echo "MAIN: MAKE_DESIGNS: FEATDir already exists"
else
	mkdir -p ${FEATDir}/sub-${Subject}
fi

### Edit fsf file to record the parameters used in this analysis
# Copy template fsf file into $FEATDir
echo "MAIN: MAKE_DESIGNS: Copying fsf file to .feat directory"
cp ${FEATDir}/${TemplateFSF} ${FEATDir}/sub-${Subject}/design-${Run}.fsf

# Change the subject id to ${Subject}
echo "MAIN: MAKE_DESIGNS: Change design.fsf: Set Subject to ${Subject}"
sed -i -e "s|NS06|${Subject}|g" ${FEATDir}/sub-${Subject}/design-${Run}.fsf

# Change the run id to ${Subject}
echo "MAIN: MAKE_DESIGNS: Change design.fsf: Set run to ${Run} #1"
sed -i -e "s|run-3|${Run}|g" ${FEATDir}/sub-${Subject}/design-${Run}.fsf

echo "MAIN: MAKE_DESIGNS: Change design.fsf: Set run to ${Run} #2"
sed -i -e "s|run3|${OtherRun}|g" ${FEATDir}/sub-${Subject}/design-${Run}.fsf

# Change the highpass filter string to the desired highpass filter
echo "MAIN: MAKE_DESIGNS: Change design.fsf: Set highpass filter string to the desired highpass filter to ${TemporalFilter}"
sed -i -e "s|set fmri(paradigm_hp) \"128\"|set fmri(paradigm_hp) \"${TemporalFilter}\"|g" ${FEATDir}/sub-${Subject}/design-${Run}.fsf

# Change output directory name to match total smoothing and highpass
#echo "MAIN: MAKE_DESIGNS: Change design.fsf: Change string in output directory name to ${TemporalFilterString}_level1${RegString}${ParcellationString}"
#sed -i -e "s|_hp200_s4|${TemporalFilterString}_level1${RegString}${ParcellationString}|g" ${FEATDir}/design.fsf

# find current value for npts in template.fsf
fsfnpts=`grep "set fmri(npts)" ${FEATDir}/sub-${Subject}/design-${Run}.fsf | cut -d " " -f 3 | sed 's|"||g'`;

# Ensure number of time points in fsf matches time series image
if [ "$fsfnpts" -eq "$npts" ] ; then
	echo "MAIN: MAKE_DESIGNS: Change design.fsf: Scan length matches number of timepoints in template.fsf: ${fsfnpts}"
else
	echo "MAIN: MAKE_DESIGNS: Change design.fsf: Warning! Scan length does not match template.fsf!"
	echo "MAIN: MAKE_DESIGNS: Change design.fsf: Warning! Changing Number of Timepoints in fsf (""${fsfnpts}"") to match time series image (""${npts}"")"
	sed -i -e  "s|set fmri(npts) \"\?${fsfnpts}\"\?|set fmri(npts) ${npts}|g" ${FEATDir}/sub-${Subject}/design-${Run}.fsf
fi


### Use fsf to create additional design files used by film_gls
echo "MAIN: MAKE_DESIGNS: Create design files, model confounds if desired"
# Determine if there is a confound matrix text file (e.g., output of fsl_motion_outliers)
confound_matrix="";
if [ "${Confound}" != "NONE" ] ; then
echo "MAIN: MAKE_DESIGNS: Copy confound file from ${fMRIPREPDir} to ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}"
	#cp ${fMRIPREPDir}/${Confound} ${ResultsFolder}/${Confound}
    echo "MAIN: MAKE_DESIGNS: Confound file is ${ResultsFolder}/${Confound}"
	confound_matrix=$( ls -d ${ResultsFolder}/${Confound} 2>/dev/null )
fi

# Run feat_model inside $FEATDir
echo "MAIN: MAKE_DESIGNS: Run feat_model"
cd $FEATDir/sub-${Subject} # so feat_model can interpret relative paths in fsf file
#feat_model ${FEATDir}/sub-${Subject}/design ${confound_matrix}; # $confound_matrix string is blank if file is missing
feat_model design-${Run} $confound_matrix string is blank if file is missing
cd $OLDPWD	# OLDPWD is shell variable previous working directory

# Set variables for additional design files
DesignMatrix=${FEATDir}/sub-${Subject}/design-${Run}.mat
DesignContrasts=${FEATDir}/sub-${Subject}/design-${Run}.con
DesignfContrasts=${FEATDir}/sub-${Subject}/design-${Run}.fts

echo "MAIN: MAKE_DESIGNS: feat_model is run"

# An F-test may not always be requested as part of the design.fsf
ExtraArgs=""
if [ -e "${DesignfContrasts}" ] ; then
	ExtraArgs="$ExtraArgs --fcon=${DesignfContrasts}"
fi


##### SMOOTH_OR_PARCELLATE: APPLY SPATIAL SMOOTHING (or parcellation) #####

### Parcellate data if a Parcellation was provided
# Parcellation may be better than adding spatial smoothing to dense time series.
# Parcellation increases sensitivity and statistical power, but avoids blurring signal
# across region boundaries into adjacent, non-activated regions.
echo "MAIN: SMOOTH_OR_PARCELLATE: PARCELLATE: Parcellate data if a Parcellation was provided"
if $runParcellated; then
	echo "MAIN: SMOOTH_OR_PARCELLATE: PARCELLATE: Parcellating data"
	echo "MAIN: SMOOTH_OR_PARCELLATE: PARCELLATE: Notice: currently parcellated time series has $SmoothingString in file name, but no additional smoothing was applied!"
	# SmoothingString in parcellated filename allows subsequent commands to work for either dtseries or ptseries
	wb_command -cifti-parcellate ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_space-MNI152NLin2009cAsym_res-2_desc-preproc_bold.nii.gz ${ParcellationDir}/${ParcellationFile}.dlabel.nii COLUMN ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${ParcellationString}.ptseries.nii
fi

### Apply spatial smoothing to volume analysis
if $runVolume ; then
	if [ "${FinalSmoothingFWHM}" != "0" ]; then
		echo "MAIN: SMOOTH_OR_PARCELLATE: SMOOTH_NIFTI: Standard NIFTI Volume-based Processsing"

		#Add edge-constrained volume smoothing
		echo "MAIN: SMOOTH_OR_PARCELLATE: SMOOTH_NIFTI: Add edge-constrained volume smoothing"
		FinalSmoothingSigma=`echo "$FinalSmoothingFWHM / ( 2 * ( sqrt ( 2 * l ( 2 ) ) ) )" | bc -l`
		fslmaths ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_space-T1w_desc-optcomDenoised_bold.nii.gz -bin ${FEATDir}/sub-${Subject}/mask_orig
		fslmaths ${FEATDir}/sub-${Subject}/mask_orig -kernel gauss ${FinalSmoothingSigma} -fmean ${FEATDir}/sub-${Subject}/mask_orig_weight -odt float
		fslmaths ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_space-T1w_desc-optcomDenoised_bold.nii.gz -kernel gauss ${FinalSmoothingSigma} -fmean \
		-div ${FEATDir}/sub-${Subject}/mask_orig_weight -mas ${FEATDir}/sub-${Subject}/mask_orig \
		${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}_space-T1w_desc-optcomDenoised_bold${SmoothingString}.nii.gz -odt float

		#Add volume dilation
		#
		# For some subjects, FreeSurfer-derived brain masks (applied to the time
		# series data in IntensityNormalization.sh as part of
		# GenericfMRIVolumeProcessingPipeline.sh) do not extend to the edge of brain
		# in the MNI152 space template. This is due to the limitations of volume-based
		# registration. So, to avoid a lack of coverage in a group analysis around the
		# penumbra of cortex, we will add a single dilation step to the input prior to
		# creating the Level1 maps.
		#
		# Ideally, we would condition this dilation on the resolution of the fMRI
		# data.  Empirically, a single round of dilation gives very good group
		# coverage of MNI brain for the 2 mm resolution of HCP fMRI data. So a single
		# dilation is what we use below.
		#
		# Note that for many subjects, this dilation will result in signal extending
		# BEYOND the limits of brain in the MNI152 template.  However, that is easily
		# fixed by masking with the MNI space brain template mask if so desired.
		#
		# The specific implementation involves:
		# a) Edge-constrained spatial smoothing on the input fMRI time series (and masking
		#    that back to the original mask).  This step was completed above.
		# b) Spatial dilation of the input fMRI time series, followed by edge constrained smoothing
		# c) Adding the voxels from (b) that are NOT part of (a) into (a).
		#
		# The motivation for this implementation is that:
		# 1) Identical voxel-wise results are obtained within the original mask.  So, users
		#    that desire the original ("tight") FreeSurfer-defined brain mask (which is
		#    implicitly represented as the non-zero voxels in the InputSBRef volume) can
		#    mask back to that if they chose, with NO impact on the voxel-wise results.
		# 2) A simpler possible approach of just dilating the result of step (a) results in
		#    an unnatural pattern of dark/light/dark intensities at the edge of brain,
		#    whereas the combination of steps (b) and (c) yields a more natural looking
		#    transition of intensities in the added voxels.
		echo "MAIN: SMOOTH_OR_PARCELLATE: SMOOTH_NIFTI: Add volume dilation"

		# Dilate the original BOLD time series, then do (edge-constrained) smoothing
		fslmaths ${FEATDir}/sub-${Subject}/mask_orig -dilM -bin ${FEATDir}/sub-${Subject}/mask_dilM
		fslmaths ${FEATDir}/sub-${Subject}/mask_dilM \
		-kernel gauss ${FinalSmoothingSigma} -fmean ${FEATDir}/sub-${Subject}/mask_dilM_weight -odt float
		fslmaths ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_space-T1w_desc-optcomDenoised_bold.nii.gz -dilM -kernel gauss ${FinalSmoothingSigma} -fmean \
		-div ${FEATDir}/sub-${Subject}/mask_dilM_weight -mas ${FEATDir}/sub-${Subject}/mask_dilM \
		${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}_dilM${SmoothingString} -odt float

		# Take just the additional "rim" voxels from the dilated then smoothed time series, and add them
		# into the smoothed time series (that didn't have any dilation)
		SmoothedDilatedResultFile=${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}${SmoothingString}_dilMrim
		fslmaths ${FEATDir}/sub-${Subject}/mask_orig -binv ${FEATDir}/sub-${Subject}/mask_orig_inv
		fslmaths ${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}_dilM${SmoothingString} \
		-mas ${FEATDir}/sub-${Subject}/mask_orig_inv \
		-add ${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}_space-T1w_desc-optcomDenoised_bold${SmoothingString}.nii.gz \
		${SmoothedDilatedResultFile}

	else
		echo "MAIN: SMOOTH_OR_PARCELLATE: SMOOTH_NIFTI: No volume smoothing"
		SmoothedDilatedResultFile=${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_space-T1w_desc-optcomDenoised_bold.nii.gz
	fi

fi # end Volume spatial smoothing

##### APPLY TEMPORAL FILTERING #####

# Issue 1: Temporal filtering is conducted by fslmaths, but fslmaths is not CIFTI-compliant.
# Convert CIFTI to "fake" NIFTI file, use FSL tools (fslmaths), then convert "fake" NIFTI back to CIFTI.
# Issue 2: fslmaths -bptf removes timeseries mean (for FSL 5.0.7 onward). film_gls expects mean in image.
# So, save the mean to file, then add it back after -bptf.
if [[ $runParcellated == true || $runDense == true ]]; then
	echo "MAIN: TEMPORAL_FILTER: Add temporal filtering to CIFTI file"
	# Convert CIFTI to "fake" NIFTI
	wb_command -cifti-convert -to-nifti ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${ParcellationString}.${Extension} ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${ParcellationString}_FAKENIFTI.nii.gz
	# Save mean image
	fslmaths ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${ParcellationString}_FAKENIFTI.nii.gz -Tmean ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${ParcellationString}_FAKENIFTI_mean.nii.gz
	# Compute smoothing kernel sigma
	hp_sigma=`echo "0.5 * $TemporalFilter / $TR_vol" | bc -l`;
	# Use fslmaths to apply high pass filter and then add mean back to image
	fslmaths ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${ParcellationString}_FAKENIFTI.nii.gz -bptf ${hp_sigma} -1 \
	   -add ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${ParcellationString}_FAKENIFTI_mean.nii.gz \
	   ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${ParcellationString}_FAKENIFTI.nii.gz
	# Convert "fake" NIFTI back to CIFTI
	wb_command -cifti-convert -from-nifti ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${ParcellationString}_FAKENIFTI.nii.gz ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${ParcellationString}.${Extension} ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${TemporalFilterString}${ParcellationString}.${Extension}
	# Cleanup the "fake" NIFTI files
	rm ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${ParcellationString}_FAKENIFTI.nii.gz ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${ParcellationString}_FAKENIFTI_mean.nii.gz
fi

if $runVolume; then
	#Add temporal filtering to the output from above
	echo "MAIN: TEMPORAL_FILTER: Add temporal filtering to NIFTI file"
	# Temporal filtering is conducted by fslmaths.
	# fslmaths -bptf removes timeseries mean (for FSL 5.0.7 onward), which is expected by film_gls.
	# So, save the mean to file, then add it back after -bptf.
	# We drop the "dilMrim" string from the output file name, so as to avoid breaking
	# any downstream scripts.
	fslmaths ${SmoothedDilatedResultFile} -Tmean ${SmoothedDilatedResultFile}_mean
	hp_sigma=`echo "0.5 * $TemporalFilter / $TR_vol" | bc -l`
	fslmaths ${SmoothedDilatedResultFile} -bptf ${hp_sigma} -1 \
	  -add ${SmoothedDilatedResultFile}_mean \
	  ${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}_space-T1w_desc-optcomDenoised_bold_${TemporalFilterString}${SmoothingString}.nii.gz
fi

##### RUN film_gls (GLM ANALYSIS ON LEVEL 1) #####

#Run CIFTI Dense Grayordinates Analysis (if requested)
if $runDense ; then
	# Dense Grayordinates Processing
	echo "MAIN: RUN_GLM: Dense Grayordinates Analysis"
	#Split into surface and volume
	echo "MAIN: RUN_GLM: Split into surface and volume"
	wb_command -cifti-separate-all ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${TemporalFilterString}.dtseries.nii -volume ${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}_AtlasSubcortical${TemporalFilterString}.nii.gz -left ${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}${TemporalFilterString}.atlasroi.L.${LowResMesh}k_fs_LR.func.gii -right ${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}${TemporalFilterString}.atlasroi.R.${LowResMesh}k_fs_LR.func.gii


	#Run film_gls on subcortical volume data
	echo "MAIN: RUN_GLM: Run film_gls on subcortical volume data"
	film_gls --rn=${FEATDir}/sub-${Subject}/SubcorticalVolumeStats --sa --ms=5 --in=${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}_AtlasSubcortical${TemporalFilterString}.nii.gz --pd=${DesignMatrix} --con=${DesignContrasts} ${ExtraArgs} --thr=1 --mode=volumetric
	rm ${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}_AtlasSubcortical${TemporalFilterString}.nii.gz

	#Run film_gls on cortical surface data
	echo "MAIN: RUN_GLM: Run film_gls on cortical surface data"
	#mkdir -p ${FEATDir}/sub-${Subject}/${DownSampleFolder}/
	for Hemisphere in L R ; do
		#Prepare for film_gls
		echo "MAIN: RUN_GLM: Prepare for film_gls"
		wb_command -metric-dilate ${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}${TemporalFilterString}.atlasroi.${Hemisphere}.${LowResMesh}k_fs_LR.func.gii ${DownSampleFolder}/sub-${Subject}.${Hemisphere}.midthickness.${LowResMesh}k_fs_LR.surf.gii 50 ${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}${TemporalFilterString}.atlasroi_dil.${Hemisphere}.${LowResMesh}k_fs_LR.func.gii -nearest

		#Run film_gls on surface data
		echo "MAIN: RUN_GLM: Run film_gls on surface data"
		film_gls --rn=${FEATDir}/sub-${Subject}/${Hemisphere}_SurfaceStats --sa --ms=15 --epith=5 --in2=${DownSampleFolder}/sub-${Subject}.${Hemisphere}.midthickness.${LowResMesh}k_fs_LR.surf.gii --in=${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}${TemporalFilterString}.atlasroi_dil.${Hemisphere}.${LowResMesh}k_fs_LR.func.gii --pd=${DesignMatrix} --con=${DesignContrasts} ${ExtraArgs} --mode=surface
		rm ${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}${TemporalFilterString}.atlasroi_dil.${Hemisphere}.${LowResMesh}k_fs_LR.func.gii ${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}${TemporalFilterString}.atlasroi.${Hemisphere}.${LowResMesh}k_fs_LR.func.gii
	done

	# Merge Cortical Surface and Subcortical Volume into Grayordinates
	echo "MAIN: RUN_GLM: Merge Cortical Surface and Subcortical Volume into Grayordinates"
	mkdir -p ${FEATDir}/sub-${Subject}/GrayordinatesStats-func-${Run}
	cat ${FEATDir}/sub-${Subject}/SubcorticalVolumeStats/dof > ${FEATDir}/sub-${Subject}/GrayordinatesStats-func-${Run}/dof
	cat ${FEATDir}/sub-${Subject}/SubcorticalVolumeStats/logfile > ${FEATDir}/sub-${Subject}/GrayordinatesStats-func-${Run}/logfile
	cat ${FEATDir}/sub-${Subject}/L_SurfaceStats/logfile >> ${FEATDir}/sub-${Subject}/GrayordinatesStats-func-${Run}/logfile
	cat ${FEATDir}/sub-${Subject}/R_SurfaceStats/logfile >> ${FEATDir}/sub-${Subject}/GrayordinatesStats-func-${Run}/logfile

	for Subcortical in ${FEATDir}/sub-${Subject}/SubcorticalVolumeStats/*nii.gz ; do
		File=$( basename $Subcortical .nii.gz );
		wb_command -cifti-create-dense-timeseries ${FEATDir}/sub-${Subject}/GrayordinatesStats-func-${Run}/${File}.dtseries.nii -volume $Subcortical ${ROIFolder}/Atlas_ROIs.${GrayordinatesResolution}.nii.gz -left-metric ${FEATDir}/sub-${Subject}/L_SurfaceStats/${File}.func.gii -roi-left ${DownSampleFolder}/sub-${Subject}.L.atlasroi.${LowResMesh}k_fs_LR.shape.gii -right-metric ${FEATDir}/sub-${Subject}/R_SurfaceStats/${File}.func.gii -roi-right ${DownSampleFolder}/sub-${Subject}.R.atlasroi.${LowResMesh}k_fs_LR.shape.gii
	done
	rm -r ${FEATDir}/sub-${Subject}/SubcorticalVolumeStats ${FEATDir}/sub-${Subject}/L_SurfaceStats ${FEATDir}/sub-${Subject}/R_SurfaceStats
fi

# Run CIFTI Parcellated Analysis (if requested)
if $runParcellated ; then
	# Parcellated Processing
	echo "MAIN: RUN_GLM: Parcellated Analysis"
	# Convert CIFTI to "fake" NIFTI
	wb_command -cifti-convert -to-nifti ${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${TemporalFilterString}${ParcellationString}.${Extension} ${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${TemporalFilterString}${ParcellationString}_FAKENIFTI.nii.gz
	# Now run film_gls on the fakeNIFTI file
	film_gls --rn=${FEATDir}/sub-${Subject}/ParcellatedStats-${Run} --in=${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${TemporalFilterString}${ParcellationString}_FAKENIFTI.nii.gz --pd=${DesignMatrix} --con=${DesignContrasts} ${ExtraArgs} --thr=1 --mode=volumetric
	# Remove "fake" NIFTI time series file
	rm ${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${TemporalFilterString}${ParcellationString}_FAKENIFTI.nii.gz
	# Convert "fake" NIFTI output files (copes, varcopes, zstats) back to CIFTI
	templateCIFTI=${ResultsFolder}/sub-${Subject}_${LevelOnefMRIName}_Atlas_s0${TemporalFilterString}${ParcellationString}.ptseries.nii
	for fakeNIFTI in `ls ${FEATDir}/sub-${Subject}/ParcellatedStats-${Run}/*.nii.gz` ; do
		CIFTI=$( echo $fakeNIFTI | sed -e "s|.nii.gz|.${Extension}|" );
		wb_command -cifti-convert -from-nifti $fakeNIFTI $templateCIFTI $CIFTI -reset-timepoints 1 1
		rm $fakeNIFTI;
	done
fi

# Standard NIFTI Volume-based Processsing###
if $runVolume ; then
	echo "MAIN: RUN_GLM: Standard NIFTI Volume Analysis"
	echo "MAIN: RUN_GLM: Run film_gls on volume data"
	film_gls --rn=${FEATDir}/sub-${Subject}/${VolStatsDir}${SmoothingString}-${Run} --sa --ms=5 --in=${FEATDir}/sub-${Subject}/sub-${Subject}_${LevelOnefMRIName}_space-T1w_desc-optcomDenoised_bold_${TemporalFilterString}${SmoothingString}.nii.gz --pd=${DesignMatrix} --con=${DesignContrasts} ${ExtraArgs} --thr=1000

fi


echo "MAIN: Complete"
