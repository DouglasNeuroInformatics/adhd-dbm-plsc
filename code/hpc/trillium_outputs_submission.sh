#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=192
#SBATCH --time 02:00:00
#SBATCH --output=r_output_outputs_%j.txt

source "$(dirname "$0")/plsc_config.sh" "$@"
export ANALYSIS_DIR MASK_FILE TEMPLATE_FILE

module load StdEnv/2023 cobralab

Rscript "$(dirname "$0")/../trillium_outputs.r"
