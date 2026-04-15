library(RMINC)

analysis_dir <- Sys.getenv("ANALYSIS_DIR", unset = ".")
demo_file    <- Sys.getenv("DEMOGRAPHICS_FILE")
mask_file    <- Sys.getenv("MASK_FILE",      unset = "")
template_file <- Sys.getenv("TEMPLATE_FILE", unset = "")

data       <- read.csv(sep="\t", demo_file)
output_dir <- file.path(analysis_dir, "univariate_trillium")
dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)

# Mask is optional — fall back to template > 0.5 if not present
if (mask_file != "" && file.exists(mask_file)) {
  mask <- mask_file
} else if (template_file != "" && file.exists(template_file)) {
  cat(sprintf("MASK_FILE not found — using template as mask (> 0.5): %s\n", template_file))
  mask <- template_file
} else {
  stop("Neither MASK_FILE nor TEMPLATE_FILE found — cannot run without a mask")
}

score_cols <- c("BASC_Hyperactivity", "BASC_Inattention",
                "BRIEFP_BRI_B", "BRIEFP_Emotional_Control",
                "BRIEFP_Inh_B", "DKEFS_Inhibition_SS",
                "CPT_Omission_Tscore", "CPT_Commission_Tscore")
data[score_cols] <- lapply(data[score_cols], as.numeric)
data <- data[!is.na(data$relative_jacobian) & data$relative_jacobian != "", ]

data$Symptom_Severity <- data$BASC_Hyperactivity + data$BASC_Inattention

models <- list(
  "BASC_Hyperactivity"                       = "BASC_Hyperactivity",
  "BASC_Inattention"                         = "BASC_Inattention",
  "Symptom_Severity"                         = "Symptom_Severity",
  "BRIEFP_BRI_B"                             = "BRIEFP_BRI_B",
  "BRIEFP_Emotional_Control"                 = "BRIEFP_Emotional_Control",
  "DKEFS_Inhibition_SS+BRIEFP_Inh_B"        = "DKEFS_Inhibition_SS + BRIEFP_Inh_B",
  "CPT_Omission_Tscore+CPT_Commission_Tscore" = "CPT_Omission_Tscore + CPT_Commission_Tscore"
)

for (name in names(models)) {
  formula_str <- paste0("relative_jacobian ~ Group + Sex + Age_years + ", models[[name]])
  formula     <- as.formula(formula_str)

  predictors <- all.vars(formula)
  predictors <- predictors[predictors != "relative_jacobian"]
  data_sub   <- data[complete.cases(data[, predictors, drop=FALSE]), ]

  cat("Running:", name, "| formula:", formula_str, "| n =", nrow(data_sub), "\n")
  model <- mincLm(formula, data=data_sub, mask=mask, parallel=c("local", 20))

  saveRDS(model,          file.path(output_dir, paste0("model_", name, ".rds")))
  saveRDS(mincFDR(model), file.path(output_dir, paste0("fdr_",   name, ".rds")))
  cat("Done:", name, "\n")
}
