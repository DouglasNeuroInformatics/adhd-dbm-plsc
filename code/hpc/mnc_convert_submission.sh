#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=192
#SBATCH --time=1:00:00
#SBATCH --output=mnc_convert%j.txt

module load StdEnv/2023 cobralab

./mnc_convert.sh output_2nd_run_no_masks
