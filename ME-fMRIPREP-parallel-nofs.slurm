#!/bin/bash
#
#SBATCH --job-name=fmriprep
#SBATCH -J fmriprep
#SBATCH --time=2-00:00:00
#SBATCH --array=1
#SBATCH -n 1
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=4G
#SBATCH --constraint=intel
#SBATCH -p contrib  # Queue names you can submit to
# Outputs ----------------------------------
#SBATCH --output=/scratch/csng/CSNG/%x-%N-%A-%a.out  # Output file
#SBATCH --error=/scratch/csng/CSNG/%x-%N-%A-%a.err   # Error file
#SBATCH --mail-type=all                         # send email on job start, end and fault
#SBATCH --mail-user=jthompsz@gmu.edu
# ------------------------------------------

STUDY=/scratch/csng/CSNG
BIDS_DIR="${STUDY}/data"
DERIVS_DIR="output"
LOCAL_FREESURFER_DIR="${BIDS_DIR}/${DERIVS_DIR}/freesurfer"

# Prepare some writeable bind-mount points.
TEMPLATEFLOW_HOST_HOME=/scratch/csng/.cache/templateflow
FMRIPREP_HOST_CACHE=/scratch/csng/.cache/fmriprep
if [[ ! -d ${TEMPLATEFLOW_HOST_HOME} ]]
    then
    mkdir -p ${TEMPLATEFLOW_HOST_HOME}
    mkdir -p ${FMRIPREP_HOST_CACHE}
fi


# Prepare derivatives folder
mkdir -p ${BIDS_DIR}/${DERIVS_DIR}

# Make sure FS_LICENSE is defined in the container.
export SINGULARITYENV_FS_LICENSE=/home/jthompsz/analysis/license.txt

# Designate a templateflow bind-mount point
export SINGULARITYENV_TEMPLATEFLOW_HOME="/templateflow"
module load singularity

#SINGULARITY_CMD="singularity run --cleanenv -B $BIDS_DIR:/data -B ${TEMPLATEFLOW_HOST_HOME}:${SINGULARITYENV_TEMPLATEFLOW_HOME} -B /scratch/csng/CSNG/work:/work -B ${LOCAL_FREESURFER_DIR}:/fsdir /cm/shared/singularity/images/fmriprep_20.2.1"

SINGULARITY_CMD="singularity run --cleanenv -B $BIDS_DIR:/data -B ${TEMPLATEFLOW_HOST_HOME}:${SINGULARITYENV_TEMPLATEFLOW_HOME} -B /scratch/csng/CSNG/work:/work -B ${LOCAL_FREESURFER_DIR}:/fsdir /containers/hopper/Containers/fmriprep/fmriprep_23.0.2.sif"


# Parse the participants.tsv file and extract one subject ID from the line corresponding to this SLURM task.
#subject=$( sed -n -E "$((${SLURM_ARRAY_TASK_ID}))s/sub-(\S*)\>.*/\1/gp" $HOME/participants.tsv )
#subject=$( sed "${SLURM_ARRAY_TASK_ID}q;d" /home/jthompsz/analysis/csng/cifti-participants-3.tsv )
subject="JT101"

# Remove IsRunning files from FreeSurfer
find ${LOCAL_FREESURFER_DIR}/sub-$subject/ -name "*IsRunning*" -type f -delete

# Compose the command line
cmd="${SINGULARITY_CMD} /data/nifti /data/${DERIVS_DIR} participant --participant-label ${subject} -w /work/ -vv --omp-nthreads 8 --nthreads 12 --mem_mb 30000 --output-spaces MNI152NLin2009cAsym:res-2 T1w --me-output-echos --skip_bids_validation --fs-no-reconall --output-layout legacy"

# Setup done, run the command
#echo Running task ${SLURM_ARRAY_TASK_ID}
echo Commandline: ${cmd}
eval $cmd
exitcode=$?

sleep $[ 60 * ${SLURM_ARRAY_TASK_ID} ]

# Output results to a table
echo "$subject   ${SLURM_ARRAY_TASK_ID}    $exitcode" \
      >> /scratch/csng/CSNG/${SLURM_JOB_NAME}.tsv
echo Finished tasks ${SLURM_JOB_NAME} with exit code $exitcode
exit $exitcode
