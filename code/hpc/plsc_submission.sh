#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=192
#SBATCH --time=5:00:00
#SBATCH --output=plsc_output_%j.txt

# NOTE: Split-half resampling (n_split=200) significantly increases runtime.
# CoBrALab wiki warns it can take 15+ hours for ~250 subjects.

module load StdEnv/2023 cobralab

source ../../.venv/bin/activate
python ../plsc_analysis.py
