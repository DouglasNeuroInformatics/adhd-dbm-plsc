library(RMINC)
library(MRIcrotome)
library(tidyverse)

# ============================================================
# CONFIGURATION
# ============================================================
RESULTS_DIR  <- Sys.getenv("PLSC_OUTPUT_DIR",  unset = "../plsc_outputs_bootstrap_1000")
OUTPUT_DIR   <- Sys.getenv("PLSC_PLOTS_DIR",   unset = "../plsc_plots_no_composites")
MASK_FILE    <- Sys.getenv("MASK_FILE",         unset = "../data/mask_shapeupdate.mnc")
ANAT_FILE    <- Sys.getenv("TEMPLATE_FILE",     unset = "../data/template_sharpen_shapeupdate.mnc")
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
CROP_PADDING <-  15 # voxels of padding around the mask

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
  cat(sprintf("Anatomy dimensions: %s\n", paste(dim(anat), collapse = " x ")))


  # Crop to mask bounds
  anat_cropped <- anat[bounds$min_slice[[1]]:bounds$max_slice[[1]],
                       bounds$min_slice[[2]]:bounds$max_slice[[2]],
                       bounds$min_slice[[3]]:bounds$max_slice[[3]]]

  cat(sprintf("Cropped dimensions: %s\n", paste(dim(anat_cropped), collapse = " x ")))


  dim1_begin <- 25
  dim1_end   <- 275
  dim2_begin <- 25
  dim2_end   <- 340
  dim3_begin <- 50
  dim3_end   <- 290

  cat(sprintf("Cropped dim1: %d-%d, dim2: %d-%d, dim3: %d-%d\n",
              dim1_begin, dim1_end,
              dim2_begin, dim2_end,
              dim3_begin, dim3_end))


  for (lv in sig_lvs) {
    bsr_path <- file.path(RESULTS_DIR, "bsr_minc", sprintf("bsr_LV%d.mnc", lv))

    if (!file.exists(bsr_path)) {
      cat(sprintf("  SKIPPING LV%d — file not found: %s\n", lv, bsr_path))
      next
    }

    bsr_flat <- mincGetVolume(bsr_path)
    max_bsr  <- max(abs(bsr_flat[mask_bool]))
    bsr_vol  <- mincArray(bsr_flat)
    cat(sprintf("\nLV%d — max BSR: %.3f\n", lv, max_bsr))

    # Crop BSR volume to same bounds
    bsr_cropped <- bsr_vol[bounds$min_slice[[1]]:bounds$max_slice[[1]],
                           bounds$min_slice[[2]]:bounds$max_slice[[2]],
                           bounds$min_slice[[3]]:bounds$max_slice[[3]]]

    fname <- file.path(OUTPUT_DIR, sprintf("plot_D_brainmap_LV%d.pdf", lv))
    pdf(fname, width = 12, height = 8)

    tryCatch({
      sliceSeries(nrow = 5, ncol = 2, dimension = 1, begin=dim1_begin, end=dim1_end) %>%
        anatomy(anat_cropped,
          low = 0.5, high = 5.2,
          col = colorRampPalette(c("black", "grey50", "white"))(255)) %>%
        addtitle(sprintf("LV%d BSR (thresh: +/-%.2f) Saggital", lv, BSR_THRESH)) %>%
        overlay(bsr_cropped,
                low       = BSR_THRESH,
                high      = max_bsr,
                symmetric = TRUE,
                col       = colorRampPalette(c("red", "yellow", "white"))(255)) %>%
      sliceSeries(nrow = 5, ncol = 2, dimension = 2, begin=dim2_begin, end=dim2_end) %>%
        anatomy(anat_cropped,
          low = 0.5, high = 5.2,
          col = colorRampPalette(c("black", "grey50", "white"))(255)) %>%
        addtitle("Coronal") %>%
        overlay(bsr_cropped,
                low       = BSR_THRESH,
                high      = max_bsr,
                symmetric = TRUE,
                col       = colorRampPalette(c("red", "yellow", "white"))(255)) %>%
      sliceSeries(nrow = 5, ncol = 2, dimension = 3, begin=dim3_begin, end=dim3_end) %>%
        anatomy(anat_cropped,
          low = 0.5, high = 5.2,
          col = colorRampPalette(c("black", "grey50", "white"))(255)) %>%
        addtitle("Axial") %>%
        overlay(bsr_cropped,
                low       = BSR_THRESH,
                high      = max_bsr,
                symmetric = TRUE,
                col       = colorRampPalette(c("red", "yellow", "white"))(255)) %>%
        legend("BSR") %>%
        draw()
    }, error = function(e) { cat("ERROR:", conditionMessage(e), "\n") })

    dev.off()
    cat(sprintf("  Saved %s\n", fname))
  }
}

cat("\nDone.\n")
