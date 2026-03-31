#!/bin/bash

module load cobralab

JACOBIAN_DIR="/data/hailab/ADHD/dbm/optimized_antsMultivariateTemplateConstruction/output/dbm/jacobian/relative/smooth"
JACOBIAN_DIR_TRILLIUM="/home/moncia/scratch/projects/hailab_ADHD/dbm/optimized_antsMultivariateTemplateConstruction/output/dbm/jacobian/relative/smooth"
for f in "$JACOBIAN_DIR_TRILLIUM"/*.nii.gz; do
    out="${f%.nii.gz}.mnc"
    nii2mnc "$f" "$out"
done
