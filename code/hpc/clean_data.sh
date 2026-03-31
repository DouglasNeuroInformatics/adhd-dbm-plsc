#!/bin/bash
# Usage: ./append_path.sh <data_file.txt>

JACOBIAN_DIR="/home/moncia/scratch/projects/hailab_ADHD/dbm/optimized_antsMultivariateTemplateConstruction/output/dbm/jacobian/relative/smooth"
INPUT="$1"
TMP=$(mktemp)

first_line=true
path_errors=false
while IFS= read -r line; do
    # Strip Windows carriage returns from the whole line
    line="${line//$'\r'/}"

    if $first_line; then
        printf '%s\trelative_jacobian\n' "$line"
        first_line=false
        continue
    fi

    subj=$(printf '%s' "$line" | cut -f1)

    path=$(find "$JACOBIAN_DIR" -maxdepth 1 -name "sub-${subj}_*.mnc" 2>/dev/null | head -1)
    [[ -z "$path" ]] && path="NOT_FOUND" && path_errors=true

    printf '%s\t%s\n' "$line" "$path"
done < "$INPUT" > "$TMP"

mv "$TMP" "$INPUT"
echo "Done: $INPUT"
if $path_errors; then
        echo "Some files were not found, check output file"
fi
