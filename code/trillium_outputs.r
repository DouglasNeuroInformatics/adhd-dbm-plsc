library(RMINC)
library(MRIcrotome)
library(magrittr)

input_dir  <- "univariate_trillium"
output_dir <- "univariate_trillium/outputs"
dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)

mask <- "/home/moncia/scratch/projects/hailab_ADHD/r_analysis/mask_shapeupdate.mnc"
template_path <- "/home/moncia/scratch/projects/hailab_ADHD/dbm/optimized_antsMultivariateTemplateConstruction/output/final/average/template_sharpen_shapeupdate.mnc"
anatVol <- mincArray(mincGetVolume(template_path))

# Slice range parameters (template is 420 x 498 x 420)
dim1_begin <- 50;  dim1_end <- 370   # sagittal
dim2_begin <- 50;  dim2_end <- 450   # coronal
dim3_begin <- 50;  dim3_end <- 370   # axial

# Model names matching saved files
model_names <- c(
  "BASC_Hyperactivity",
  "BASC_Inattention",
  "Symptom_Severity",
  "BRIEFP_BRI_B",
  "BRIEFP_Emotional_Control",
  "DKEFS_Inhibition_SS+BRIEFP_Inh_B",
  "CPT_Omission_Tscore+CPT_Commission_Tscore"
)

# --- 1. FDR threshold summary table ---
fdr_summary <- data.frame()
for (name in model_names) {
  fdr <- readRDS(file.path(input_dir, paste0("fdr_", name, ".rds")))
  thresholds <- attr(fdr, "thresholds")
  if (!is.null(thresholds)) {
    for (j in seq_len(ncol(thresholds))) {
      fdr_summary <- rbind(fdr_summary, data.frame(
        model        = name,
        term         = colnames(thresholds)[j],
        threshold_1  = thresholds["0.01", j],
        threshold_5  = thresholds["0.05", j],
        threshold_10 = thresholds["0.1",  j],
        threshold_15 = thresholds["0.15", j],
        threshold_20 = thresholds["0.2",  j],
        stringsAsFactors = FALSE
      ))
    }
  }
  cat("FDR thresholds extracted:", name, "\n")
}
write.csv(fdr_summary, file.path(output_dir, "fdr_threshold_summary.csv"), row.names=FALSE)
cat("Saved: fdr_threshold_summary.csv\n")

# --- 2. Brain overlay images for each model/predictor ---
generate_slices <- function(model, predictor, title, lowerthreshold, upperthreshold, outfile) {
  png(outfile, width=2400, height=1800, res=200)
  sliceSeries(nrow = 5, ncol = 2, dimension = 2, begin = dim2_begin, end = dim2_end) %>%
    anatomy(anatVol, low=1, high=5.9) %>%
    addtitle("Coronal") %>%
    overlay(mincArray(model, predictor),
            low = lowerthreshold, high = upperthreshold, symmetric = TRUE) %>%
    contours(abs(mincArray(model, predictor)), levels=lowerthreshold, lwd=2, col="black") %>%
  sliceSeries(nrow = 6, ncol = 2, dimension = 1, begin = dim1_begin, end = dim1_end) %>%
    anatomy(anatVol, low=1, high=5.9) %>%
    addtitle("Sagittal") %>%
    overlay(mincArray(model, predictor),
            low = lowerthreshold, high = upperthreshold, symmetric = TRUE) %>%
    contours(abs(mincArray(model, predictor)), levels=lowerthreshold, lwd=2, col="black") %>%
  sliceSeries(nrow = 5, ncol = 2, dimension = 3, begin = dim3_begin, end = dim3_end) %>%
    anatomy(anatVol, low=1, high=5.9) %>%
    addtitle("Axial") %>%
    overlay(mincArray(model, predictor),
            low = lowerthreshold, high = upperthreshold, symmetric = TRUE) %>%
    contours(abs(mincArray(model, predictor)), levels=lowerthreshold, lwd=2, col="black") %>%
    legend(predictor) %>%
    draw()
  dev.off()
  cat("Saved:", outfile, "\n")
}

for (name in model_names) {
  model <- readRDS(file.path(input_dir, paste0("model_", name, ".rds")))
  fdr   <- readRDS(file.path(input_dir, paste0("fdr_",   name, ".rds")))
  thresholds <- attr(fdr, "thresholds")

  # Get tvalue columns from the model
  model_cols <- colnames(model)
  tvalue_cols <- model_cols[grep("^tvalue-", model_cols)]

  for (predictor in tvalue_cols) {
    # Use 20% FDR threshold as lower bound if available, otherwise default to 2
    lowerthreshold <- 2
    if (!is.null(thresholds) && predictor %in% colnames(thresholds)) {
      fdr_val <- thresholds["0.2", predictor]
      if (!is.na(fdr_val) && is.finite(fdr_val) && fdr_val > 0) {
        lowerthreshold <- fdr_val
      }
    }
    upperthreshold <- lowerthreshold * 2

    safe_name <- gsub("[^A-Za-z0-9_.-]", "_", paste0(name, "_", predictor))
    outfile <- file.path(output_dir, paste0("slices_", safe_name, ".png"))
    generate_slices(model, predictor, paste(name, predictor), lowerthreshold, upperthreshold, outfile)
  }
}

# --- 3. Peak voxel tables ---
peak_summary <- data.frame()
for (name in model_names) {
  model <- readRDS(file.path(input_dir, paste0("model_", name, ".rds")))
  model_cols <- colnames(model)
  tvalue_cols <- model_cols[grep("^tvalue-", model_cols)]

  for (predictor in tvalue_cols) {
    vol <- mincArray(model, predictor)
    tvals <- as.numeric(model[, predictor])
    tvals[is.na(tvals)] <- 0

    # Top 10 positive and negative peaks
    pos_idx <- order(tvals, decreasing=TRUE)[1:10]
    neg_idx <- order(tvals, decreasing=FALSE)[1:10]

    for (idx in c(pos_idx, neg_idx)) {
      coords <- arrayInd(idx, dim(vol))
      peak_summary <- rbind(peak_summary, data.frame(
        model     = name,
        predictor = predictor,
        voxel_idx = idx,
        dim1 = coords[1], dim2 = coords[2], dim3 = coords[3],
        tvalue    = tvals[idx],
        stringsAsFactors = FALSE
      ))
    }
  }
  cat("Peaks extracted:", name, "\n")
}
write.csv(peak_summary, file.path(output_dir, "peak_voxels.csv"), row.names=FALSE)
cat("Saved: peak_voxels.csv\n")

# --- 4. Effect size / stats CSV per model ---
for (name in model_names) {
  model <- readRDS(file.path(input_dir, paste0("model_", name, ".rds")))
  fdr   <- readRDS(file.path(input_dir, paste0("fdr_",   name, ".rds")))

  # Write volume-wise stats summary
  model_cols <- colnames(model)
  stats_df <- data.frame(
    term = model_cols,
    mean = apply(model, 2, mean, na.rm=TRUE),
    sd   = apply(model, 2, sd,   na.rm=TRUE),
    min  = apply(model, 2, min,  na.rm=TRUE),
    max  = apply(model, 2, max,  na.rm=TRUE)
  )
  write.csv(stats_df, file.path(output_dir, paste0("stats_", name, ".csv")), row.names=FALSE)
  cat("Saved: stats_", name, ".csv\n")
}

cat("\nAll outputs complete.\n")
