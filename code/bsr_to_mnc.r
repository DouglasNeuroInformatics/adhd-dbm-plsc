library(RMINC)

results_dir <- Sys.getenv("PLSC_OUTPUT_DIR", unset = "../plsc_outputs_bootstrap_1000")
output_dir  <- file.path(results_dir, "bsr_minc")
dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)


bsr   <- read.csv(paste0(results_dir, "/x_weights_normed.csv"), header=FALSE)
pvals <- as.numeric(read.csv(paste0(results_dir, "/pvals.csv"), header=FALSE)[[1]])
mask  <- mincGetVolume(Sys.getenv("MASK_FILE", unset = "../data/mask_shapeupdate.mnc"))

cat("BSR:", nrow(bsr), "voxels x", ncol(bsr), "LVs\n")
cat("Sig LVs (p<0.05):", which(pvals < 0.05), "\n")

for (lv in seq_len(ncol(bsr))) {
  vol <- mask
  vol[mask >= 0.5] <- bsr[, lv]

  out <- sprintf("%s/bsr_LV%d.mnc", output_dir, lv)
  mincWriteVolume(vol, out)
  cat(sprintf("  LV%d: max |BSR| = %.3f -> %s\n", lv, max(abs(bsr[, lv])), out))
}
