
task="localizer"
data_dir="/scratch/csng/CSNG/data/output/fmriprep/sub-${subject}/func"
for run in 1 2
    do

    func_file=/scratch/csng/CSNG/data/output/tedana/sub-${subject}/sub-${subject}_task-${task}_run-${run}_desc-optcomDenoised_bold.nii.gz
    func_out=/scratch/csng/CSNG/data/output/fmriprep/sub-${subject}/func/sub-${subject}_task-${task}_run-${run}_space-T1w_desc-optcomDenoised_bold.nii.gz
    #func_file=/scratch/csng/CSNG/data/output/fmriprep/sub-${subject}/func/sub-${subject}_task-${task}_run-${run}_echo-2_desc-preproc_bold.nii.gz
    #func_out=/scratch/csng/CSNG/data/output/fmriprep/sub-${subject}/func/sub-${subject}_task-${task}_run-${run}_echo-2_space-T1w_desc-preproc_bold.nii.gz

    itk_xforms=/scratch/csng/CSNG/data/output/fmriprep/sub-${subject}/func/sub-${subject}_task-${task}_run-${run}_from-scanner_to-T1w_mode-image_xfm.txt
    sT1w=/scratch/csng/CSNG/data/output/fmriprep/sub-${subject}/func/sub-${subject}_task-${task}_run-${run}_space-T1w_boldref.nii.gz
    ants_xforms=/scratch/csng/CSNG/data/output/fmriprep/sub-${subject}/anat/sub-${subject}_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5



    antsApplyTransforms --dimensionality 3 \
    --input-image-type 3 \
    --input ${func_file} \
    --reference-image ${sT1w} \
    --output ${func_out} \
    --interpolation LanczosWindowedSinc \
    --transform ${itk_xforms} \
    --default-value 0 \
    --float 1 \
    --verbose 1

    done

#/work/temp_data_BRAINT/fmriprep_22_1_wf/single_subject_pilote1_wf/anat_preproc_wf/anat_norm_wf/_template_MNI152NLin2009cAsym/registration/ants_t1_to_mniComposite.h5
#--transform /work/temp_data_BRAINT/fmriprep_22_1_wf/single_subject_pilote1_wf/func_preproc_ses_01_task_rest_wf/bold_reg_wf/bbreg_wf/concat_xfm/out_fwd.tfm
#--transform /work/temp_data_BRAINT/fmriprep_22_1_wf/single_subject_pilote1_wf/func_preproc_ses_01_task_rest_wf/unwarp_wf/resample/vol0000_xfm.nii.gz
