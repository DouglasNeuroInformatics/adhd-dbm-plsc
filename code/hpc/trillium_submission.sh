#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=192
#SBATCH --time 02:00:00
#SBATCH --output=r_output_%j.txt

source "${SLURM_SUBMIT_DIR}/plsc_config.sh" "$@"
export ANALYSIS_DIR DEMOGRAPHICS_FILE MASK_FILE TEMPLATE_FILE

module load StdEnv/2023 cobralab

Rscript "${SLURM_SUBMIT_DIR}/../trillium_models.r"
