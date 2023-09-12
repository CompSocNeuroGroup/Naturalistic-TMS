#!/bin/bash
#
#SBATCH --job-name=fsl-task
#SBATCH -J fsl-task
#SBATCH --time=2-00:00:00
#SBATCH --array=1
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G
#SBATCH --constraint=intel
#SBATCH -p contrib  # Queue names you can submit to
# Outputs ----------------------------------
#SBATCH --output=/scratch/csng/CSNG/%x-%N-%A-%a.out  # Output file
#SBATCH --error=/scratch/csng/CSNG/%x-%N-%A-%a.err   # Error file
#SBATCH --mail-type=all                         # send email on job start, end and fault
#SBATCH --mail-user=jthompsz@gmu.edu
# ------------------------------------------

module load workbench/1.5.0
module load fsl/6.0.5.2

#subject=$( sed "${SLURM_ARRAY_TASK_ID}q;d" /home/jthompsz/analysis/csng/cognafld-participants.tsv )
subject="C001"
export subject
echo $subject

# add lag between jobs
sleep $[ 10 * ${SLURM_ARRAY_TASK_ID} ]

cd /home/jthompsz/analysis/csng
#bash cifti_dense_feat1.sh
#bash cifti_localizer_feat1.sh
#bash cifti_localizer_feat2.sh
#bash cifti_localizer_gfeat.sh

#bash cifti_dense_feat3.sh
#bash cifti_dense_feat4.sh
#bash cifti_dense_feat5.sh
#bash cifti_dense_feat6.sh
#bash cifti_dense_feat7.sh
#bash cifti_dense-smooth-out-only_gfeat.sh

#bash vol_T1w-PPI01_feat3.sh
#bash vol_T1w-PPI01_feat4.sh
#bash vol_T1w-PPI01_feat5.sh
#bash vol_T1w-PPI01_feat6.sh
#bash vol_T1w-PPI01_feat7.sh

#bash vol_localizer_feat1.sh
#bash vol_localizer_feat2.sh
bash vol_localizer_gfeat.sh
