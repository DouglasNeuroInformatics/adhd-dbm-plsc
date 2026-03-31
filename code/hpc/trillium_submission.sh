#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=192
#SBATCH --time 02:00:00
#SBATCH --output=r_output_%j.txt

# Load required modules
module load StdEnv/2023 cobralab

# Run the R script
Rscript ./trillium_models.r
