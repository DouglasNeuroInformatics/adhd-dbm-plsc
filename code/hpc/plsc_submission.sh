#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=192
#SBATCH --time=5:00:00
#SBATCH --output=plsc_%j.txt

source "$(dirname "$0")/plsc_config.sh"
export WORKING_DIR DEMOGRAPHICS_FILE MASK_FILE N_BOOT N_PERM N_SPLIT SEED N_PROC PLSC_OUTPUT_DIR

module load StdEnv/2023 cobralab
source "${VENV}"

echo "Output dir: ${PLSC_OUTPUT_DIR}"
python "$(dirname "$0")/../plsc_analysis.py"
