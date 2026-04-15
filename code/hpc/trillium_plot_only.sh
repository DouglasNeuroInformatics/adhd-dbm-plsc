#!/bin/bash

source "plsc_config.sh" "$@"
export ANALYSIS_DIR MASK_FILE TEMPLATE_FILE

module load StdEnv/2023 cobralab

Rscript "../trillium_plots.r"
