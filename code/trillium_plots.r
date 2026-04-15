library(RMINC)
library(MRIcrotome)
library(magrittr)

analysis_dir  <- Sys.getenv("ANALYSIS_DIR", unset = ".")
template_file <- Sys.getenv("TEMPLATE_FILE", unset = "")
mask_file     <- Sys.getenv("MASK_FILE",     unset = "")

input_dir  <- file.path(analysis_dir, "univariate_trillium")
output_dir <- file.path(analysis_dir, "univariate_trillium", "outputs")
dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)

CROP_PADDING <- 15

if (template_file == "" || !file.exists(template_file)) stop("TEMPLATE_FILE not found — cannot generate overlays")

# Derive crop bounds from mask; fall back to the template (assumed skull-stripped)
mask_path  <- if (mask_file != "" && file.exists(mask_file)) mask_file else template_file
mask_array <- mincArray(mincGetVolume(mask_path))
mask_idx   <- which(mask_array > 0.5, arr.ind = TRUE)
crop_lo    <- pmax(apply(mask_idx, 2, min) - CROP_PADDING, 1)
crop_hi    <- pmin(apply(mask_idx, 2, max) + CROP_PADDING, dim(mask_array))
cat(sprintf("Crop bounds — dim1: %d-%d, dim2: %d-%d, dim3: %d-%d\n",
            crop_lo[1], crop_hi[1], crop_lo[2], crop_hi[2], crop_lo[3], crop_hi[3]))

anatVol <- mincArray(mincGetVolume(template_file))[
  crop_lo[1]:crop_hi[1], crop_lo[2]:crop_hi[2], crop_lo[3]:crop_hi[3]]

# Slice ranges = actual mask extent in cropped space (skips the padding)
mask_lo_cropped <- apply(mask_idx, 2, min) - crop_lo + 1
mask_hi_cropped <- apply(mask_idx, 2, max) - crop_lo + 1
dim1_begin <- 25; dim1_end <- 275
dim2_begin <- 25; dim2_end <- 340
dim3_begin <- 50; dim3_end <- 290

model_names <- c(
  "BASC_Hyperactivity",
  "BASC_Inattention",
  "Symptom_Severity",
  "BRIEFP_BRI_B",
  "BRIEFP_Emotional_Control",
  "DKEFS_Inhibition_SS+BRIEFP_Inh_B",
  "CPT_Omission_Tscore+CPT_Commission_Tscore"
)

generate_slices <- function(model, predictor, title, lowerthreshold, upperthreshold, outfile) {
  tvals <- mincArray(model, predictor)[
    crop_lo[1]:crop_hi[1], crop_lo[2]:crop_hi[2], crop_lo[3]:crop_hi[3]]
  png(outfile, width=2400, height=1800, res=200)
  sliceSeries(nrow = 5, ncol = 2, dimension = 2, begin = dim2_begin, end = dim2_end) %>%
    anatomy(anatVol, low=1, high=9.7,
      col = colorRampPalette(c("black", "grey50", "white"))(255)) %>%
    addtitle("Coronal") %>%
    overlay(tvals, low = lowerthreshold, high = upperthreshold, symmetric = TRUE) %>%
  sliceSeries(nrow = 6, ncol = 2, dimension = 1, begin = dim1_begin, end = dim1_end) %>%
    anatomy(anatVol, low=1, high=9.7,
      col = colorRampPalette(c("black", "grey50", "white"))(255)) %>%
    addtitle("Sagittal") %>%
    overlay(tvals, low = lowerthreshold, high = upperthreshold, symmetric = TRUE) %>%
  sliceSeries(nrow = 5, ncol = 2, dimension = 3, begin = dim3_begin, end = dim3_end) %>%
    anatomy(anatVol, low=1, high=9.7,
      col = colorRampPalette(c("black", "grey50", "white"))(255)) %>%
    addtitle("Axial") %>%
    overlay(tvals, low = lowerthreshold, high = upperthreshold, symmetric = TRUE) %>%
    legend(predictor) %>%
    draw()
  dev.off()
  cat("Saved:", outfile, "\n")
}

for (name in model_names) {
  model <- readRDS(file.path(input_dir, paste0("model_", name, ".rds")))
  fdr   <- readRDS(file.path(input_dir, paste0("fdr_",   name, ".rds")))
  thresholds <- attr(fdr, "thresholds")

  model_cols  <- colnames(model)
  tvalue_cols <- model_cols[grep("^tvalue-", model_cols)]

  for (predictor in tvalue_cols) {
    lowerthreshold <- 2
    upperthreshold <- NULL
    if (!is.null(thresholds) && predictor %in% colnames(thresholds)) {
      fdr_05 <- thresholds["0.05", predictor]
      fdr_01 <- thresholds["0.01", predictor]
      if (!is.na(fdr_05) && is.finite(fdr_05) && fdr_05 > 0) lowerthreshold <- fdr_05
      if (!is.na(fdr_01) && is.finite(fdr_01) && fdr_01 > 0) upperthreshold <- fdr_01
    }
    if (is.null(upperthreshold)) {
      tvals <- as.numeric(model[, predictor])
      upperthreshold <- round(max(abs(tvals[is.finite(tvals)]), na.rm = TRUE), 2)
    }

    safe_name <- gsub("[^A-Za-z0-9_.-]", "_", paste0(name, "_", predictor))
    outfile <- file.path(output_dir, paste0("slices_", safe_name, ".png"))
    generate_slices(model, predictor, paste(name, predictor), lowerthreshold, upperthreshold, outfile)
  }
}

cat("\nPlots complete.\n")
