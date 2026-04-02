#!/bin/bash
# pipeline_config.sh — shared defaults for all pipeline scripts
# Source this file; output dirs are derived AFTER arg parsing in each wrapper.

# ── Core paths ────────────────────────────────────────────────────────────────
WORKING_DIR="${WORKING_DIR:-/home/moncia/scratch/projects/hailab_ADHD/r_analysis}"
VENV_PATH="${VENV_PATH:-${WORKING_DIR}/../../.venv/bin/activate}"

# ── PLSC parameters ───────────────────────────────────────────────────────────
N_PERM="${N_PERM:-5000}"
N_BOOT="${N_BOOT:-1000}"
N_SPLIT="${N_SPLIT:-0}"
SEED="${SEED:-42}"
N_PROC="${N_PROC:-16}"
