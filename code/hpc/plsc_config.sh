#!/bin/bash
# plsc_config.sh — edit this file to configure the PLSC pipeline
# Sourced by plsc_submission.sh and plsc_post_submission.sh
#

#This is what the jacbobian output dir name and will build everything from there
ANALYSIS_NAME="${1:?Error: ANALYSIS_NAME required as first argument (e.g. source plsc_config.sh combined_jan2026)}"

# ── Paths ─────────────────────────────────────────────────────────────────────
WORKING_DIR="/home/moncia/scratch/projects/hailab_ADHD/r_analysis"
VENV="${WORKING_DIR}/../../.venv/bin/activate"

# ── DBM jacobian path ─────────────────────────────────────────────────────────
DBM_PATH="/home/moncia/scratch/projects/hailab_ADHD/dbm/optimized_antsMultivariateTemplateConstruction/${ANALYSIS_NAME}"
FINAL_PATH="${DBM_PATH}/final"
JACOBIAN_DIR="${DBM_PATH}/dbm/jacobian/relative/smooth"


# ── Analayis Dir Paths ─────────────────────────────────────────────────────────────────────
ANALYSIS_DIR="/home/moncia/scratch/projects/hailab_ADHD/r_analysis/analysis/${ANALYSIS_NAME}"
# Raw file (hardcoded input — edit if source data changes)
RAW_DEMOGRAPHICS_FILE="/home/moncia/scratch/projects/hailab_ADHD/r_analysis/data/Demographic_Data_ADHD_combined_Jan102026.tsv"
# Cleaned file (output of clean_data.sh, input to PLSC — name derived from ANALYSIS_NAME)
DEMOGRAPHICS_FILE="${ANALYSIS_DIR}/data/cleaned_${ANALYSIS_NAME}.tsv"
# Optional — steps that need these files will skip gracefully if not present
MASK_FILE="${FINAL_PATH}/mask_shapeupdate.mnc"
TEMPLATE_FILE="${FINAL_PATH}/template_sharpen_shapeupdate.mnc"

# ── PLSC parameters ───────────────────────────────────────────────────────────
N_BOOT=1000
N_PERM=5000
N_SPLIT=0      # split-half reliability; 0 = skip (saves hours)
SEED=42
N_PROC=16

# ── Output dirs (auto-named from parameters above - no need to edit) ─────────
_TS="$(date +%Y%m%d_%H%M)"
PLSC_OUTPUT_DIR="${ANALYSIS_DIR}/plsc_outputs_boot${N_BOOT}_perm${N_PERM}_${_TS}"
PLSC_PLOTS_DIR="${PLSC_OUTPUT_DIR}/plots"
