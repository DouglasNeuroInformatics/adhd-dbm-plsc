#!/bin/bash
# Usage: ./append_path.sh <data_file.txt>

JACOBIAN_DIR="/data/hailab/ADHD/dbm/optimized_antsMultivariateTemplateConstruction/output/dbm/jacobian/relative/smooth"
INPUT="$1"
TMP=$(mktemp)

first_line=true
while IFS= read -r line; do
    # Strip Windows carriage returns from the whole line
    line="${line//$'\r'/}"

    if $first_line; then
        printf '%s\tjacobian_relative\n' "$line"
        first_line=false
        continue
    fi

    # Extract subject ID from first column only
    subj=$(printf '%s' "$line" | cut -f1)

    path=$(find "$JACOBIAN_DIR" -maxdepth 1 -name "sub-${subj}_*.nii.gz" 2>/dev/null | head -1)
    [[ -z "$path" ]] && path="NOT_FOUND"

    printf '%s\t%s\n' "$line" "$path"
done < "$INPUT" > "$TMP"

mv "$TMP" "$INPUT"
echo "Done: $INPUT"
