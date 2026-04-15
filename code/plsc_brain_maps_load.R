library(RMINC)
library(tidyverse)

# ============================================================
# CONFIGURATION
# ============================================================
RESULTS_DIR  <- Sys.getenv("PLSC_OUTPUT_DIR",  unset = "")
OUTPUT_DIR   <- Sys.getenv("PLSC_PLOTS_DIR",   unset = "")
MASK_FILE    <- Sys.getenv("MASK_FILE",         unset = "")
ANAT_FILE    <- Sys.getenv("TEMPLATE_FILE",     unset = "")
BSR_THRESH   <- 1.95   # p < 0.05
ALPHA        <- 0.05
CROP_PADDING <- 15

CACHE_DIR <- file.path(OUTPUT_DIR, "cache")
dir.create(CACHE_DIR, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# PVALS + SIGNIFICANT LVs
# ============================================================
pvals   <- as.numeric(read.csv(file.path(RESULTS_DIR, "pvals.csv"), header = FALSE)[[1]])
sig_lvs <- which(pvals < ALPHA)
cat(sprintf("Significant LVs: %s\n", paste(sig_lvs, collapse = ", ")))

# ============================================================
# MASK + CROP BOUNDS
# ============================================================
mask_path <- if (MASK_FILE != "" && file.exists(MASK_FILE)) MASK_FILE else ANAT_FILE
if (!file.exists(mask_path)) stop(sprintf("Mask not found: %s", mask_path))

cat("Loading mask...\n")
mask_vol   <- mincGetVolume(mask_path)
mask_bool  <- mask_vol > 0.5
mask_array <- mincArray(mask_vol)

bounds <- which(mask_array > 0.5, arr.ind = TRUE) %>%
  as_tibble() %>%
  gather(dim, index) %>%
  group_by(dim) %>%
  summarize(
    min_slice = max(min(index) - CROP_PADDING, 1),
    max_slice = max(index) + CROP_PADDING,
    .groups = "drop"
  )

cat(sprintf("Crop bounds — dim1: %d-%d, dim2: %d-%d, dim3: %d-%d\n",
            bounds$min_slice[[1]], bounds$max_slice[[1]],
            bounds$min_slice[[2]], bounds$max_slice[[2]],
            bounds$min_slice[[3]], bounds$max_slice[[3]]))

# ============================================================
# ANATOMY
# ============================================================
if (!file.exists(ANAT_FILE)) stop(sprintf("Anatomy file not found: %s", ANAT_FILE))

cat("Loading anatomy...\n")
anat <- mincArray(mincGetVolume(ANAT_FILE))
anat_cropped <- anat[bounds$min_slice[[1]]:bounds$max_slice[[1]],
                     bounds$min_slice[[2]]:bounds$max_slice[[2]],
                     bounds$min_slice[[3]]:bounds$max_slice[[3]]]
cat(sprintf("Cropped anatomy: %s\n", paste(dim(anat_cropped), collapse = " x ")))

saveRDS(anat_cropped, file.path(CACHE_DIR, "anat_cropped.rds"))
cat("Saved: anat_cropped.rds\n")

# ============================================================
# BSR VOLUMES (one per significant LV)
# ============================================================
for (lv in sig_lvs) {
  bsr_path <- file.path(RESULTS_DIR, "bsr_minc", sprintf("bsr_LV%d.mnc", lv))
  if (!file.exists(bsr_path)) {
    cat(sprintf("  SKIPPING LV%d — file not found: %s\n", lv, bsr_path))
    next
  }
  bsr_flat    <- mincGetVolume(bsr_path)
  max_bsr     <- max(abs(bsr_flat[mask_bool]))
  bsr_cropped <- mincArray(bsr_flat)[bounds$min_slice[[1]]:bounds$max_slice[[1]],
                                     bounds$min_slice[[2]]:bounds$max_slice[[2]],
                                     bounds$min_slice[[3]]:bounds$max_slice[[3]]]
  cat(sprintf("LV%d — max BSR: %.3f\n", lv, max_bsr))
  saveRDS(list(bsr_cropped = bsr_cropped, max_bsr = max_bsr),
          file.path(CACHE_DIR, sprintf("bsr_LV%d.rds", lv)))
  cat(sprintf("  Saved: bsr_LV%d.rds\n", lv))
}

# ============================================================
# METADATA (everything the plot script needs to know)
# ============================================================
saveRDS(list(
  sig_lvs    = sig_lvs,
  BSR_THRESH = BSR_THRESH,
  dim1_begin = 25, dim1_end = 275,
  dim2_begin = 25, dim2_end = 340,
  dim3_begin = 50, dim3_end = 290
), file.path(CACHE_DIR, "meta.rds"))
cat("Saved: meta.rds\n")

cat("\nLoad complete. Run plsc_brain_maps_plot.R to generate PDFs.\n")
