#!/usr/bin/env Rscript
library(RMINC)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  cat("Usage: Rscript write_mask.r /path/to/template.mnc\n")
  quit(status = 1)
}

mask_path <- args[1]
out_path  <- sub("\\.mnc$", "_mask.mnc", mask_path)

cat(sprintf("Loading: %s\n", mask_path))
mask_vol  <- mincGetVolume(mask_path)
mask_bool <- mask_vol > 0.5
cat(sprintf("Voxels in mask: %d\n", sum(mask_bool)))

out      <- mask_vol
out[]    <- as.numeric(mask_bool)
mincWriteVolume(out, out_path)
cat(sprintf("Saved: %s\n", out_path))
