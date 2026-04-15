library(MRIcrotome)
library(magrittr)

# ============================================================
# CONFIGURATION
# ============================================================
OUTPUT_DIR <- Sys.getenv("PLSC_PLOTS_DIR", unset = "")
CACHE_DIR  <- file.path(OUTPUT_DIR, "cache")

dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# LOAD CACHE
# ============================================================
meta         <- readRDS(file.path(CACHE_DIR, "meta.rds"))
anat_cropped <- readRDS(file.path(CACHE_DIR, "anat_cropped.rds"))

BSR_THRESH <- meta$BSR_THRESH
sig_lvs    <- meta$sig_lvs
dim1_begin <- meta$dim1_begin; dim1_end <- meta$dim1_end
dim2_begin <- meta$dim2_begin; dim2_end <- meta$dim2_end
dim3_begin <- meta$dim3_begin; dim3_end <- meta$dim3_end

cat(sprintf("Significant LVs: %s\n", paste(sig_lvs, collapse = ", ")))

# ============================================================
# PLOTTING — edit below to try different things
# ============================================================
for (lv in sig_lvs) {
  cache_file <- file.path(CACHE_DIR, sprintf("bsr_LV%d.rds", lv))
  if (!file.exists(cache_file)) {
    cat(sprintf("  SKIPPING LV%d — cache not found (run plsc_brain_maps_load.R first)\n", lv))
    next
  }

  bsr         <- readRDS(cache_file)
  bsr_cropped <- bsr$bsr_cropped
  max_bsr     <- bsr$max_bsr
  cat(sprintf("\nLV%d — max BSR: %.3f\n", lv, max_bsr))

  tryCatch({
    lowerthreshold <- round(BSR_THRESH, digits = 2)
    upperthreshold <- round(max_bsr,    digits = 2)

    # Base palettes
    pospal <- colorRampPalette(c("red",  "yellow"),     alpha = TRUE)(255)
    negpal <- colorRampPalette(c("blue", "turquoise1"), alpha = TRUE)(255)

    # Crossover index where colormap switches from transparent to opaque
    breakpoint_idx <- round(lowerthreshold / upperthreshold * 255) - 1

    breakpointpos <- pospal[breakpoint_idx]
    breakpointneg <- negpal[breakpoint_idx]

    # Transparent ramp up to threshold
    pospalalpha <- colorRampPalette(c("#FF000000", breakpointpos), alpha = TRUE)(breakpoint_idx - 1)
    negpalalpha <- colorRampPalette(c("#0000FF00", breakpointneg), alpha = TRUE)(breakpoint_idx - 1)

    # Full combined palettes
    combinedpospal <- c(pospalalpha, pospal[breakpoint_idx:255])
    combinednegpal <- c(negpalalpha, negpal[breakpoint_idx:255])

    fname <- file.path(OUTPUT_DIR, sprintf("plot_D_brainmap_LV%d.pdf", lv))
    pdf(fname, width = 12, height = 8)

    sliceSeries(nrow = 5, ncol = 2, dimension = 2, begin = dim2_begin, end = dim2_end) %>%
      anatomy(anat_cropped, low = 0.5, high = 9.7,
        col = colorRampPalette(c("black", "grey50", "white"))(255)) %>%
      addtitle("Coronal") %>%
      overlay(bsr_cropped,
              low = 0, high = upperthreshold, symmetric = TRUE,
              col = combinedpospal, rCol = combinednegpal) %>%
      contours(abs(bsr_cropped), levels = lowerthreshold, lwd = 2, col = "black") %>%
    sliceSeries(nrow = 5, ncol = 2, dimension = 1, begin = dim1_begin, end = dim1_end) %>%
      anatomy(anat_cropped, low = 0.5, high = 9.7,
        col = colorRampPalette(c("black", "grey50", "white"))(255)) %>%
      addtitle("Sagittal") %>%
      overlay(bsr_cropped,
              low = 0, high = upperthreshold, symmetric = TRUE,
              col = combinedpospal, rCol = combinednegpal) %>%
      contours(abs(bsr_cropped), levels = lowerthreshold, lwd = 2, col = "black") %>%
    sliceSeries(nrow = 5, ncol = 2, dimension = 3, begin = dim3_begin, end = dim3_end) %>%
      anatomy(anat_cropped, low = 0.5, high = 9.7,
        col = colorRampPalette(c("black", "grey50", "white"))(255)) %>%
      addtitle("Axial") %>%
      overlay(bsr_cropped,
              low = 0, high = upperthreshold, symmetric = TRUE,
              col = combinedpospal, rCol = combinednegpal) %>%
      legend(sprintf("LV%d BSR (thresh: +/-%.2f)\n ", lv, BSR_THRESH)) %>%
      contours(abs(bsr_cropped), levels = lowerthreshold, lwd = 2, col = "black") %>%
      draw()

    dev.off()
    cat(sprintf("  Saved %s\n", fname))
  }, error = function(e) { cat("ERROR:", conditionMessage(e), "\n") })
}

cat("\nDone.\n")
