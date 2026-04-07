
source "$(dirname "$0")/plsc_config.sh" "$@"
export ANALYSIS_DIR DEMOGRAPHICS_FILE MASK_FILE TEMPLATE_FILE


echo "$(dirname "$0")/../trillium_models.r"
