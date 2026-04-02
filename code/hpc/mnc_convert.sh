#!/bin/bash
# Usage: ./mnc_convert.sh <ANALYSIS_NAME>
# Converts all .nii.gz files in JACOBIAN_DIR to .mnc in-place.

ANALYSIS_NAME="${1:?Usage: ./mnc_convert.sh <ANALYSIS_NAME>}"
source "$(dirname "$0")/plsc_config.sh" "$ANALYSIS_NAME"

module load cobralab

for f in "$JACOBIAN_DIR"/*.nii.gz; do
    out="${f%.nii.gz}.mnc"
    nii2mnc "$f" "$out"
done
