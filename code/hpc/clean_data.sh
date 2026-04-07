#!/bin/bash
# Usage: ./clean_data.sh <ANALYSIS_NAME>
# Appends jacobian paths from JACOBIAN_DIR to RAW_DEMOGRAPHICS_FILE,
# recodes Group/Sex, renames Age column, drops QC-flagged rows,
# and writes the result to DEMOGRAPHICS_FILE.

ANALYSIS_NAME="${1:?Usage: ./clean_data.sh <ANALYSIS_NAME>}"
source "$(dirname "$0")/plsc_config.sh" "$ANALYSIS_NAME"
mkdir -p "${ANALYSIS_DIR}/data"

LOG="${ANALYSIS_DIR}/data/clean_data_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee "$LOG") 2>&1
echo "clean_data.sh started: $(date)"
echo "Input:  $RAW_DEMOGRAPHICS_FILE"
echo "Output: $DEMOGRAPHICS_FILE"
echo "Log:    $LOG"
echo ""

[[ -f "$RAW_DEMOGRAPHICS_FILE" ]] || { echo "ERROR: input file not found: $RAW_DEMOGRAPHICS_FILE"; exit 1; }

TMP=$(mktemp)

awk -v jdir="$JACOBIAN_DIR" '
BEGIN { FS = OFS = "\t" }

# ── Header ────────────────────────────────────────────────────────────────────
NR == 1 {
    gsub(/\r/, "")
    ncols = NF
    for (i = 1; i <= NF; i++) {
        if ($i == "Group")       gcol = i
        if ($i == "Sex")         scol = i
        if ($i == "QC_notes")    qcol = i
        if ($i == "Age (years)") $i   = "Age_years"
    }
    $(NF + 1) = "relative_jacobian"
    print; next
}

# ── Data rows ─────────────────────────────────────────────────────────────────
{
    gsub(/\r/, "")

    if (NF != ncols) next

    # Drop rows with any QC note
    if (qcol && $qcol != "") {
        print "  QC drop: subject " $1 " (" $qcol ")" > "/dev/stderr"
        dropped++
        next
    }

    # Recode Group and Sex
    if (gcol) { sub(/^1$/, "ADHD",     $gcol); sub(/^2$/, "Control", $gcol) }
    if (scol) { sub(/^1$/, "female",   $scol); sub(/^2$/, "male",     $scol) }

    # Look up jacobian path for this subject
    cmd  = "find " jdir " -maxdepth 1 -name \"sub-" $1 "_*.mnc\" 2>/dev/null | head -1"
    path = ""
    if ((cmd | getline path) <= 0 || path == "") {
        print "  Jacobian drop: subject " $1 " (no file found)" > "/dev/stderr"
        errors++
        close(cmd)
        next
    }
    close(cmd)

    $(NF + 1) = path
    print
}

END {
    if (dropped) print dropped " row(s) dropped due to QC notes" > "/dev/stderr"
    if (errors)  print errors  " subject(s) dropped (no jacobian file found)" > "/dev/stderr"
}
' "$RAW_DEMOGRAPHICS_FILE" > "$TMP" && mv "$TMP" "$DEMOGRAPHICS_FILE"

echo "Done: $(date)"
