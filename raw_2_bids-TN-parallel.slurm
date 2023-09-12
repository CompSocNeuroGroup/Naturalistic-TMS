#!/bin/bash
#
#SBATCH --job-name=raw_2_bids
#SBATCH -J raw_2_bids
#SBATCH --time=02:00:00
#SBATCH --array=1
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4G
#SBATCH --constraint=intel
#SBATCH -p contrib  # Queue names you can submit to
# Outputs ----------------------------------
#SBATCH --output=/scratch/csng/CSNG/%x-%N-%A-%a.out  # Output file
#SBATCH --error=/scratch/csng/CSNG/%x-%N-%A-%a.err   # Error file
# ------------------------------------------#


## Load the relevant modules needed for the job
module load jo
module load dcm2niix/v1.0.20190902

#subject=$( sed "${SLURM_ARRAY_TASK_ID}q;d" /home/jthompsz/analysis/csng/cifti-participants.tsv )
subject=C001
export subject
echo $subject

# add lag between jobs
sleep $[ 10 * ${SLURM_ARRAY_TASK_ID} ]

## Run your program or script
/bin/date
cd /scratch/csng/CSNG/
/home/jthompsz/analysis/csng/raw_2_bids-fMRIPREP-T1w-parallel.sh /scratch/csng
#/home/jthompsz/analysis/csng/raw_2_bids-fMRIPREP-DTI-parallel.sh /scratch/csng
/home/jthompsz/analysis/csng/raw_2_bids-fMRIPREP-ME-loc-parallel.sh /scratch/csng
/home/jthompsz/analysis/csng/raw_2_bids-fMRIPREP-FMAP-parallel.sh /scratch/csng
/bin/date
