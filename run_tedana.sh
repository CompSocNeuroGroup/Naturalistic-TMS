
task="localizer"
data_dir="/scratch/csng/CSNG/data/output/fmriprep/sub-${subject}/func"
for run in 1 2
    do
    in_data="${data_dir}/sub-${subject}_task-${task}_run-${run}_echo-1_desc-preproc_bold.nii.gz ${data_dir}/sub-C001_task-${task}_run-${run}_echo-2_desc-preproc_bold.nii.gz ${data_dir}/sub-${subject}_task-${task}_run-${run}_echo-3_desc-preproc_bold.nii.gz"
    out_dir="/scratch/csng/CSNG/data/output/tedana/sub-${subject}"
    out_pre="sub-${subject}_task-${task}_run-${run}"

    tedana -d ${in_data} -e 14.4 33.2 52.06 --out-dir ${out_dir} --prefix ${out_pre}
    done


