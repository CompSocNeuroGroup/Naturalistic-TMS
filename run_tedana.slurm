#!/bin/bash
#
#SBATCH --job-name=tedana
#SBATCH -J tedana
#SBATCH --time=12:00:00
#SBATCH --array=1
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=16G
#SBATCH --constraint=intel
#SBATCH -p contrib # Queue names you can submit to
# Outputs ----------------------------------
#SBATCH --output=/scratch/csng/CSNG/%x-%N-%A-%a.out  # Output file
#SBATCH --error=/scratch/csng/CSNG/%x-%N-%A-%a.err   # Error file
# ------------------------------------------

module purge
module load hosts/hopper  gnu9/9.3.0
module load python/3.8.6-ye
module load ants/2.3.5
#module load fsl


#subject=$( sed "${SLURM_ARRAY_TASK_ID}q;d" /home/jthompsz/analysis/csng/cifti-participants.tsv )
subject=JT101
export subject
echo $subject

bash run_tedana.sh
bash tendana_to_T1w.sh
#bash tendana_to_MNI.sh
#python PPI-to-hcp.py $subject
