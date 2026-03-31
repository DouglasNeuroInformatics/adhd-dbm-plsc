library(RMINC)

# Check FDR structure
fdr <- readRDS("univariate_trillium/fdr_BASC_Hyperactivity.rds")
cat("=== FDR thresholds ===\n")
th <- attr(fdr, "thresholds")
print(th)
cat("\nRow names:", rownames(th), "\n")
cat("Col names:", colnames(th), "\n")

# Check template dimensions and intensity range
template_path <- "/home/moncia/scratch/projects/hailab_ADHD/dbm/optimized_antsMultivariateTemplateConstruction/output/final/average/template_sharpen_shapeupdate.mnc"
vol <- mincGetVolume(template_path)
cat("\n=== Template info ===\n")
cat("Dimensions:", dim(mincArray(vol)), "\n")
cat("Intensity range:", range(vol, na.rm=TRUE), "\n")
cat("Quantiles:\n")
print(quantile(vol, probs=c(0, 0.01, 0.05, 0.5, 0.95, 0.99, 1), na.rm=TRUE))
