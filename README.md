# Naturalistic-TMS

# some changes as of 9/18/23, including to the .fsf files

1. In your /scratch/${your username}/ folder make a folder called:

CSNG/

then within this make:

data/behavior

data/raw

data/nifti

data/output/fmriprep

data/output/tendana

data/output/freesurfer

data/output/stats

data/backup

work

In your /home/${your username}/ folder make a folder called:

analysis/csng

2. Put all the *.sh and *.slurm files in your /home/${your username}/analysis/csng folder

3. Modify directory names in:

raw_2_bids-TN-parallel.slurm

ME-fMRIPREP-parallel-nofs.slurm

run_tedana.slurm

run_tedana.sh

tendana_to_T1w.sh

unconfound_localizer_fd.py

unconfound-hopper.slurm

vol_localizer_feat1.sh

vol_localizer_feat1.sh

vol_localizer_gfeat.sh

fsl-localizer-task.slurm


4. Put the localizer-run-1.fsf and localizer_level2.fsf files in the /data/output/stats folder. Modify directory names for location of textfiles.

5. On a local computer, download the NS-fmri-textfiles.R file and modify paths, make output folder (line 7). Download the psychopy .csv files from dropbox folder. Sometimes you get duplicates of each run xxxx_1.csv. Delete these before you run the *.R file. Check timings of the text files to ensure they are different across runs. Copy the textfiles to /data/behavior/${subject}/textfiles.

6. Pull data from MRICORE using globus. Raw data should go in data/raw/sub-TNXXX

6. Run in following order:

raw_2_bids-TN-parallel.slurm
- check nifti folders. Move axial T1w from anat folder to a folder in data/backup

ME-fMRIPREP-parallel-nofs.slurm
- copy the fmriprep/sub-XXX.html file and the fmriprep/sub-XXX/figures folder locally and check html file

run_tedana.slurm
- check that Optimally Denoised T1w file is created in fmriprep/func folder

unconfound-hopper.slurm

fsl-localizer-task.slurm
- check cope5.feat/zstat1.nii.gz
