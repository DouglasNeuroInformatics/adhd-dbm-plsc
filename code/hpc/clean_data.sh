#!/bin/bash
# Usage: ./clean_data.sh <ANALYSIS_NAME> <data_file.txt>
# Appends relative_jacobian paths from JACOBIAN_DIR to the demographics file
# and writes the result to analysis/<ANALYSIS_NAME>/data/

ANALYSIS_NAME="${1:?Usage: ./clean_data.sh <ANALYSIS_NAME> <data_file.txt>}"
INPUT="${2:?Usage: ./clean_data.sh <ANALYSIS_NAME> <data_file.txt>}"

source "$(dirname "$0")/plsc_config.sh" "$ANALYSIS_NAME"
mkdir -p "${ANALYSIS_DIR}/data"

TMP=$(mktemp)
_TS="$(date +%Y%m%d_%H%M)"

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

OUT="${ANALYSIS_DIR}/data/cleaned_${_TS}_$(basename "$INPUT")"
mv "$TMP" "$OUT"
echo "Done: $OUT"
if $path_errors; then
        echo "Some files were not found, check output file"
fi
