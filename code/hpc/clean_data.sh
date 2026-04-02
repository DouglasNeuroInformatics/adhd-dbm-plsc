#!/bin/bash
# Usage: ./clean_data.sh <ANALYSIS_NAME>
# Appends jacobian paths from JACOBIAN_DIR to RAW_DEMOGRAPHICS_FILE
# and writes the result to DEMOGRAPHICS_FILE (analysis/<ANALYSIS_NAME>/data/cleaned_<ANALYSIS_NAME>.tsv)

ANALYSIS_NAME="${1:?Usage: ./clean_data.sh <ANALYSIS_NAME>}"
source "$(dirname "$0")/plsc_config.sh" "$ANALYSIS_NAME"
mkdir -p "${ANALYSIS_DIR}/data"

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
done < "$RAW_DEMOGRAPHICS_FILE" > "$TMP"

mv "$TMP" "$DEMOGRAPHICS_FILE"
echo "Done: $DEMOGRAPHICS_FILE"
if $path_errors; then
    echo "Some files were not found, check output file"
fi
