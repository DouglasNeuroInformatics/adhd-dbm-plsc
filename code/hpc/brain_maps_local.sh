#!/bin/bash
# Run brain map scripts locally (no SLURM).
# Usage:
#   bash hpc/brain_maps_local.sh combined_jan2026                  # load + plot
#   bash hpc/brain_maps_local.sh combined_jan2026 --plot-only      # skip load, re-run plot only
#   bash hpc/brain_maps_local.sh combined_jan2026 --maps-only      # run plsc_brain_maps.R only

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="${SCRIPT_DIR}/.."

source "${SCRIPT_DIR}/plsc_config.sh" "$1"
: "${PLSC_OUTPUT_DIR:?PLSC_OUTPUT_DIR not set}"
export WORKING_DIR MASK_FILE TEMPLATE_FILE PLSC_OUTPUT_DIR PLSC_PLOTS_DIR

case "${2}" in
  --plot-only)
    echo "--- plsc_brain_maps_plot.R ---"
    Rscript "${SCRIPTS}/plsc_brain_maps_plot.R"
    ;;
  --maps-only)
    echo "--- plsc_brain_maps.R ---"
    Rscript "${SCRIPTS}/plsc_brain_maps.R"
    ;;
  *)
    echo "--- plsc_brain_maps_load.R ---"
    Rscript "${SCRIPTS}/plsc_brain_maps_load.R"
    echo "--- plsc_brain_maps_plot.R ---"
    Rscript "${SCRIPTS}/plsc_brain_maps_plot.R"
    ;;
esac

echo "Done. Outputs in: ${PLSC_PLOTS_DIR}"
