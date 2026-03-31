library(RMINC)
library(MRIcrotome)
library(tidyverse)

# ============================================================
# CONFIGURATION
# ============================================================
RESULTS_DIR  <- "plsc_results_1000_bootstrap_no_groups"
OUTPUT_DIR   <- "../plsc_plots"
MASK_FILE    <- "../data/mask_shapeupdate.mnc"
ANAT_FILE    <- "../data/template_sharpen_shapeupdate.mnc"
BSR_THRESH   <- 1.95   # p < 0.05
ALPHA        <- 0.05

# ============================================================
# LOAD PVALS ONLY — MNC files already exist, skip rewriting
# ============================================================
pvals   <- as.numeric(read.csv(file.path(RESULTS_DIR, "pvals.csv"), header = FALSE)[[1]])
n_lvs   <- length(pvals)
sig_lvs <- which(pvals < ALPHA)

dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)

cat(sprintf("Significant LVs: %s\n", paste(sig_lvs, collapse = ", ")))

# ============================================================
# LOAD MASK
# ============================================================
cat("Loading mask...\n")
mask_vol  <- mincGetVolume(MASK_FILE)
mask_bool <- mask_vol > 0.5
mask_array <- mincArray(mask_vol)

# ============================================================
# COMPUTE CROP BOUNDS FROM MASK
# ============================================================
CROP_PADDING <- 5  # voxels of padding around the mask

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
# VISUALISE WITH MRIcrotome
# ============================================================
if (!file.exists(ANAT_FILE)) {
  cat(sprintf("\nWARNING: Anatomy file not found: %s\n", ANAT_FILE))
} else {
  anat <- mincArray(mincGetVolume(ANAT_FILE))

  # Check volume sizes
  cat(sprintf("Anatomy dimensions: %s\n", paste(dim(anat), collapse = " x ")))

  for (lv in sig_lvs) {
    bsr_path <- file.path(OUTPUT_DIR, "bsr_minc", sprintf("bsr_LV%d.mnc", lv))

    if (!file.exists(bsr_path)) {
      cat(sprintf("  SKIPPING LV%d — file not found: %s\n", lv, bsr_path))
      next
    }

    bsr_flat <- mincGetVolume(bsr_path)
    max_bsr  <- max(abs(bsr_flat[mask_bool]))
    bsr_vol  <- mincArray(bsr_flat)
    cat(sprintf("\nLV%d — max BSR: %.3f\n", lv, max_bsr))

    fname <- file.path(OUTPUT_DIR, sprintf("plot_D_brainmap_LV%d.pdf", lv))
    pdf(fname, width = 12, height = 8)

    # Axial (dimension=1, z-axis, 420 voxels), voxel indices
    ss <- sliceSeries(nrow = 4, ncol = 6, begin = 100, end = 360, dimension = 1) %>%
      anatomy(anat, low = 0.5, high = 4.5) %>%
      addtitle(sprintf("LV%d BSR map  (threshold: +/-%.2f, p < 0.05)", lv, BSR_THRESH)) %>%
      overlay(bsr_vol,
              low       = BSR_THRESH,
              high      = max_bsr,
              symmetric = TRUE,
              col       = colorRampPalette(c("red", "yellow", "white"))(255)) %>%
      legend("BSR")
    draw(ss)

    dev.off()
    cat(sprintf("  Saved %s\n", fname))
  }
}

cat("\nDone.\n")
