#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=192
#SBATCH --time=1:00:00
#SBATCH --output=plsc_%j.txt

source "${SLURM_SUBMIT_DIR}/plsc_config.sh" "$@"
export WORKING_DIR DEMOGRAPHICS_FILE MASK_FILE TEMPLATE_FILE N_BOOT N_PERM N_SPLIT SEED N_PROC PLSC_OUTPUT_DIR JACOBIAN_DIR

module load StdEnv/2023 cobralab
source "${VENV}"

echo "Output dir: ${PLSC_OUTPUT_DIR}"
python "${SLURM_SUBMIT_DIR}/../plsc_analysis.py"
