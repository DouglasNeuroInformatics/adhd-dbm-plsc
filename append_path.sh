#!/bin/bash

# Usage: ./append_path.sh <data_file.txt>
# Appends Jacobian path to last column (in-place)

JACOBIAN_DIR="/data/hailab/ADHD/dbm/optimized_antsMultivariateTemplateConstruction/output/dbm/jacobian/relative/smooth"

INPUT="$1"
TMP=$(mktemp)

while IFS=$'\t' read -ra cols; do
    subj="${cols[0]}"
    path=$(ls "$JACOBIAN_DIR"/sub-"${subj}"_*.nii.gz 2>/dev/null || echo "NOT_FOUND")
    echo -e "$(IFS=$'\t'; echo "${cols[*]}")\t$path"
done < "$INPUT" > "$TMP"

mv "$TMP" "$INPUT"
echo "Done: $INPUT"

