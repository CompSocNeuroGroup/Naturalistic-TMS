#!/bin/bash
#
#SBATCH --job-name=unconfound
#SBATCH --time=2-00:00:00
#SBATCH --array=1-10
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G
#SBATCH --constraint=intel
#SBATCH -p contrib # 
# Outputs ----------------------------------
#SBATCH --output=/scratch/csng/CSNG/%x-%N-%A-%a.out  # Output file
#SBATCH --error=/scratch/csng/CSNG/%x-%N-%A-%a.err   # Error file
# ------------------------------------------

module purge
module load hosts/hopper  gnu9/9.3.0
module load python/3.8.6-ye

#subject=$( sed "${SLURM_ARRAY_TASK_ID}q;d" /home/jthompsz/analysis/csng/cognafld-participants.tsv )
subject="JT101"
export subject
echo $subject

#sleep $[ 20 * ${SLURM_ARRAY_TASK_ID} ]

python unconfound_localizer_fd.py $subject
