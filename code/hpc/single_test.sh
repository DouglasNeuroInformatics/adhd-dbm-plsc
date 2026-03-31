#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=192
#SBATCH --time 01:00:00
#SBATCH --output=r_output_%j.txt

# Load required modules
module load StdEnv/2023 cobralab

# Run the R script
/usr/bin/time -v Rscript ./trillium_single_test.r 2>&1 | tee trillium_time_test.log
