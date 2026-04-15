library(tidyverse)
 
plsc_dir <- Sys.getenv("PLSC_OUTPUT_DIR", unset = "")
df <- read_csv(file.path(plsc_dir, "lv_scores.csv"))

# Correlations per group per LV
for (lv in 1:4) {
  cat(sprintf("\n--- LV%d ---\n", lv))
  for (grp in c("ADHD", "Control")) {
    sub <- df %>% filter(Group == grp)
    r <- cor.test(sub[[paste0("x_lv", lv)]], sub[[paste0("y_lv", lv)]])
    cat(sprintf("  %s: r=%.3f, p=%.4f\n", grp, r$estimate, r$p.value))
  }
}

# Plot all 4 LVs
plots <- map(1:4, function(lv) {
  ggplot(df, aes_string(x = paste0("x_lv", lv), y = paste0("y_lv", lv), colour = "Group")) +
    geom_point(alpha = 0.7) +
    geom_smooth(method = "lm", se = TRUE) +
    labs(title = sprintf("LV%d: Brain vs Behaviour by Group", lv),
         x = "Brain score", y = "Behaviour score") +
    theme_minimal()
})

# Save as multi-page PDF
pdf(file.path(plsc_dir, "posthoc_lv_by_group.pdf"), width = 6, height = 5)
walk(plots, print)
dev.off()
cat("\nSaved posthoc_lv_by_group.pdf\n")
