#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=192
#SBATCH --time=0:45:00
#SBATCH --output=plsc_post_%j.txt

# Pass ANALYSIS_NAME as first arg. To point at a specific older run, override PLSC_OUTPUT_DIR:
#   PLSC_OUTPUT_DIR=/path/to/plsc_outputs_boot1000_perm5000_20260401_120000 \
#     sbatch plsc_post_submission.sh combined_jan2026

source "${SLURM_SUBMIT_DIR}/plsc_config.sh" "$@"

# Allow overriding output dir from the environment (e.g. pointing at an older run)
: "${PLSC_OUTPUT_DIR:?PLSC_OUTPUT_DIR not set}"

export WORKING_DIR MASK_FILE TEMPLATE_FILE PLSC_OUTPUT_DIR PLSC_PLOTS_DIR

module load StdEnv/2023 cobralab
source "${VENV}"

SCRIPTS="${SLURM_SUBMIT_DIR}/.."
echo "Post-processing: ${PLSC_OUTPUT_DIR}"

echo "--- npz_to_csv.py ---"
python "${SCRIPTS}/npz_to_csv.py" "${PLSC_OUTPUT_DIR}"

echo "--- bsr_to_mnc.r ---"
Rscript "${SCRIPTS}/bsr_to_mnc.r"

echo "--- post_hoc.py ---"
python "${SCRIPTS}/post_hoc.py"

echo "--- post_hoc.r ---"
Rscript "${SCRIPTS}/post_hoc.r"

echo "--- plsc_plots.R ---"
Rscript "${SCRIPTS}/plsc_plots.R"

echo "--- plsc_brain_maps_load.R ---"
Rscript "${SCRIPTS}/plsc_brain_maps_load.R"

echo "--- plsc_brain_maps_plot.R ---"
Rscript "${SCRIPTS}/plsc_brain_maps_plot.R"

echo "Done. Outputs in: ${PLSC_OUTPUT_DIR}"
