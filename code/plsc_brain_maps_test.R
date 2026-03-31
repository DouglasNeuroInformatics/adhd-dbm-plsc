library(RMINC)
library(MRIcrotome)
library(magrittr)

# ============================================================
# CONFIGURATION
# ============================================================
OUTPUT_DIR <- "plsc_plots"
MASK_FILE  <- "mask_shapeupdate.mnc"
ANAT_FILE  <- "/home/moncia/scratch/projects/hailab_ADHD/dbm/optimized_antsMultivariateTemplateConstruction/output/final/average/template_sharpen_shapeupdate.mnc"
BSR_THRESH <- 1.95

# ============================================================
# LOAD — use mincArray() so MRIcrotome gets spatial attributes
# ============================================================
cat("Loading anatomy...\n")
anat <- mincArray(mincGetVolume(ANAT_FILE))
cat(sprintf("  Anatomy dim: %s\n", paste(dim(anat), collapse = " x ")))

cat("Loading mask...\n")
mask_vol  <- mincGetVolume(MASK_FILE)
mask_bool <- mask_vol > 0.5

cat("Anatomy intensity range...\n")
cat(sprintf("  min=%.2f  max=%.2f\n", min(anat, na.rm=TRUE), max(anat, na.rm=TRUE)))
cat(sprintf("  p1=%.2f  p5=%.2f  p50=%.2f  p95=%.2f  p99=%.2f\n",
  quantile(anat, 0.01, na.rm=TRUE),
  quantile(anat, 0.05, na.rm=TRUE),
  quantile(anat, 0.50, na.rm=TRUE),
  quantile(anat, 0.95, na.rm=TRUE),
  quantile(anat, 0.99, na.rm=TRUE)))

cat("Loading LV1 BSR...\n")
bsr_vol  <- mincArray(mincGetVolume(file.path(OUTPUT_DIR, "bsr_minc", "bsr_LV1.mnc")))
# Use flat mask for max calculation
bsr_flat <- mincGetVolume(file.path(OUTPUT_DIR, "bsr_minc", "bsr_LV1.mnc"))
max_bsr  <- max(abs(bsr_flat[mask_bool]))
cat(sprintf("  Max BSR: %.3f\n", max_bsr))

# Volume is 420(z) x 498(y) x 420(x) — dimension index in mincArray = 1=z, 2=y, 3=x
cat(sprintf("  anat dim: %s\n", paste(dim(anat), collapse=" x ")))

# ============================================================
# TEST 0: single central slice — confirm anatomy loads at right location
# ============================================================
cat("\nTest 0: single slice at centre of each dimension...\n")
for (d in 1:3) {
  n_slices <- dim(anat)[d]
  mid <- round(n_slices / 2)
  tryCatch({
    pdf(file.path(OUTPUT_DIR, sprintf("test0_dim%d_slice%d.pdf", d, mid)), width=6, height=6)
    sliceSeries(nrow=1, slices=mid, dimension=d) %>%
      anatomy(anat, low=0.5, high=4.5) %>%
      draw()
    dev.off()
    cat(sprintf("  dim=%d slice=%d PASSED\n", d, mid))
  }, error=function(e) {
    dev.off()
    cat(sprintf("  dim=%d FAILED: %s\n", d, e$message))
  })
}

# ============================================================
# TEST 1: axial (dimension=1, z-axis, 420 voxels)
# ============================================================
cat("\nTest 1: axial, dimension=1, begin=100, end=360...\n")
tryCatch({
  pdf(file.path(OUTPUT_DIR, "test1_axial.pdf"), width = 10, height = 6)
  ss <- sliceSeries(nrow = 3, ncol = 4, begin = 100, end = 360, dimension = 1) %>%
    anatomy(anat, low = 0.5, high = 4.5)
  draw(ss)
  dev.off()
  cat("  Test 1 PASSED\n")
}, error = function(e) {
  dev.off()
  cat(sprintf("  Test 1 FAILED: %s\n", e$message))
})

# ============================================================
# TEST 2: coronal (dimension=2, y-axis, 498 voxels)
# ============================================================
cat("\nTest 2: coronal, dimension=2, begin=100, end=400...\n")
tryCatch({
  pdf(file.path(OUTPUT_DIR, "test2_coronal.pdf"), width = 10, height = 6)
  ss <- sliceSeries(nrow = 3, ncol = 4, begin = 100, end = 400, dimension = 2) %>%
    anatomy(anat, low = 0.5, high = 4.5)
  draw(ss)
  dev.off()
  cat("  Test 2 PASSED\n")
}, error = function(e) {
  dev.off()
  cat(sprintf("  Test 2 FAILED: %s\n", e$message))
})

# ============================================================
# TEST 3: sagittal (dimension=3, x-axis, 420 voxels)
# ============================================================
cat("\nTest 3: sagittal, dimension=3, begin=100, end=360...\n")
tryCatch({
  pdf(file.path(OUTPUT_DIR, "test3_sagittal.pdf"), width = 10, height = 6)
  ss <- sliceSeries(nrow = 3, ncol = 4, begin = 100, end = 360, dimension = 3) %>%
    anatomy(anat, low = 0.5, high = 4.5)
  draw(ss)
  dev.off()
  cat("  Test 3 PASSED\n")
}, error = function(e) {
  dev.off()
  cat(sprintf("  Test 3 FAILED: %s\n", e$message))
})

# ============================================================
# TEST 4: axial with BSR overlay
# ============================================================
cat("\nTest 4: axial with BSR overlay...\n")
tryCatch({
  pdf(file.path(OUTPUT_DIR, "test4_overlay.pdf"), width = 10, height = 6)
  ss <- sliceSeries(nrow = 3, ncol = 4, begin = 100, end = 360, dimension = 1) %>%
    anatomy(anat, low = 0.5, high = 4.5) %>%
    overlay(bsr_vol,
            low       = BSR_THRESH,
            high      = max_bsr,
            symmetric = TRUE,
            col       = colorRampPalette(c("red", "yellow", "white"))(255))
  draw(ss)
  dev.off()
  cat("  Test 4 PASSED\n")
}, error = function(e) {
  dev.off()
  cat(sprintf("  Test 4 FAILED: %s\n", e$message))
})

cat("\nDone. Check plsc_plots/ for any PDFs that were created.\n")
