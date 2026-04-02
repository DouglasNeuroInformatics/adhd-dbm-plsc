#!/bin/bash
# plsc_config.sh — edit this file to configure the PLSC pipeline
# Sourced by plsc_submission.sh and plsc_post_submission.sh

# ── Paths ─────────────────────────────────────────────────────────────────────
WORKING_DIR="/home/moncia/scratch/projects/hailab_ADHD/r_analysis"
DEMOGRAPHICS_FILE="${WORKING_DIR}/data/Demographic_Data_ADHD_combined_Jan102026_cleaned.tsv"
MASK_FILE="${WORKING_DIR}/data/mask_shapeupdate.mnc"
TEMPLATE_FILE="${WORKING_DIR}/data/template_sharpen_shapeupdate.mnc"
VENV="${WORKING_DIR}/../../.venv/bin/activate"

# ── PLSC parameters ───────────────────────────────────────────────────────────
N_BOOT=1000
N_PERM=5000
N_SPLIT=0      # split-half reliability; 0 = skip (saves hours)
SEED=42
N_PROC=16

# ── Output dirs (auto-named from parameters above — no need to edit) ──────────
_TS="$(date +%Y%m%d_%H%M%S)"
PLSC_OUTPUT_DIR="${WORKING_DIR}/plsc_outputs_boot${N_BOOT}_perm${N_PERM}_${_TS}"
PLSC_PLOTS_DIR="${PLSC_OUTPUT_DIR}/plots"
