#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=192
#SBATCH --time=13:00:00
#SBATCH --output=plsc_output_%j.txt

# NOTE: Split-half resampling (n_split=200) significantly increases runtime.
# CoBrALab wiki warns it can take 15+ hours for ~250 subjects.
# With 85 subjects it should be faster, but 6 hours is a safe starting point.
# Increase --time if the job times out, or set N_SPLIT=0 in plsc_analysis.py
# to skip split-half and reduce runtime to ~15-30 min.

module load StdEnv/2023 cobralab

source ./.venv/bin/activate
python ./plsc_analysis.py
