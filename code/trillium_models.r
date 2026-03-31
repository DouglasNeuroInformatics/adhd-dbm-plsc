library(RMINC)

data       <- read.csv(sep="\t", "~/scratch/projects/hailab_ADHD/r_analysis/Demographic_Data_ADHD_combined_Jan102026_cleaned.tsv")
output_dir <- "univariate_trillium"
dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)
mask <- "/home/moncia/scratch/projects/hailab_ADHD/r_analysis/mask_shapeupdate.mnc"

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
