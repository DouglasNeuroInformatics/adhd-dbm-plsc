library(tidyverse)
library(patchwork)

# ============================================================
# CONFIGURATION
# ============================================================
RESULTS_DIR <- "../plsc_outputs_bootstrap_1000"
OUTPUT_DIR  <- "../plsc_plots_no_composites"
ALPHA       <- 0.05

BEHAVIORAL_NAMES <- c(
  "DKEFS Inhibition",
  "DKEFS Letter Fluency",
  "DKEFS Category Fluency",
  "CPT Omission",
  "CPT Commission",
  "BASC Inattention",
  "BASC Hyperactivity",
  "BASC Anxiety",
  "BASC Depression",
  "BASC Aggression",
  "BASC Withdrawal",
  "BASC Adaptive",
  "BRIEFP Inhibit",
  "BRIEFP Shift",
  "BRIEFP Emotional Control",
  "BRIEFP Initiate",
  "BRIEFP Working Memory",
  "BRIEFP Plan/Org",
  "BRIEFP Org of Materials"
)

# ============================================================
# LOAD DATA
# ============================================================
pvals      <- as.numeric(read.csv(file.path(RESULTS_DIR, "pvals.csv"),    header = FALSE)[[1]])
varexp     <- as.numeric(read.csv(file.path(RESULTS_DIR, "varexp.csv"),   header = FALSE)[[1]])
singvals   <- as.numeric(read.csv(file.path(RESULTS_DIR, "singvals.csv"), header = FALSE)[[1]])
y_loadings <- as.matrix(read.csv(file.path(RESULTS_DIR, "y_loadings.csv"), header = FALSE))
x_scores   <- as.matrix(read.csv(file.path(RESULTS_DIR, "x_scores.csv"),  header = FALSE))
y_scores   <- as.matrix(read.csv(file.path(RESULTS_DIR, "y_scores.csv"),  header = FALSE))
subjects   <- read.csv(file.path(RESULTS_DIR, "subject_list.csv"))

n_lvs      <- length(pvals)
sig_lvs    <- which(pvals < ALPHA)  # 1-indexed

dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)

cat(sprintf("Significant LVs: %s\n", paste(sig_lvs, collapse = ", ")))

# ============================================================
# LOAD CIs
# Read y_loadings_ci files — one per behaviour (0-indexed filenames)
# Each file: rows = LVs, cols = [lower_CI, upper_CI]
# ============================================================
n_behaviors <- length(BEHAVIORAL_NAMES)
ci_lower <- matrix(NA, nrow = n_behaviors, ncol = n_lvs)
ci_upper <- matrix(NA, nrow = n_behaviors, ncol = n_lvs)

for (b in 0:(n_behaviors - 1)) {
  ci_file <- read.csv(
    file.path(RESULTS_DIR, "y_loadings_ci", paste0("y_loadings_ci_", b, ".csv")),
    header = FALSE
  )
  ci_lower[b + 1, ] <- ci_file[, 1]
  ci_upper[b + 1, ] <- ci_file[, 2]
}

# ============================================================
# PLOT B: Variance explained + p-value
# ============================================================
lv_df <- data.frame(
  LV     = 1:n_lvs,
  varexp = varexp * 100,
  pval   = pvals,
  sig    = pvals < ALPHA
)

scale_factor <- max(lv_df$varexp) / 1.0  # p-values already 0-1

p_b <- ggplot(lv_df, aes(x = LV)) +
  geom_point(aes(y = varexp), colour = "#d62728", size = 3) +
  geom_point(aes(y = pval * scale_factor), colour = "#1f77b4", size = 3) +
  geom_hline(yintercept = ALPHA * scale_factor, linetype = "dashed",
             colour = "#1f77b4", linewidth = 0.5) +
  scale_y_continuous(
    name     = "% Covariance Explained",
    sec.axis = sec_axis(~ . / scale_factor, name = "Permutation p-value")
  ) +
  scale_x_continuous(breaks = 1:n_lvs) +
  labs(title = "Variance Explained and P-value by LV", x = "Latent Variable") +
  theme_minimal() +
  theme(
    axis.title.y.left  = element_text(colour = "#d62728"),
    axis.title.y.right = element_text(colour = "#1f77b4")
  )

ggsave(file.path(OUTPUT_DIR, "plot_B_varexp_pval.pdf"), p_b, width = 8, height = 5)
cat("Saved plot_B_varexp_pval.pdf\n")

# ============================================================
# PLOT A: Behavioural loadings for each significant LV
# ============================================================
for (lv in sig_lvs) {
  load_df <- data.frame(
    behavior = factor(BEHAVIORAL_NAMES, levels = rev(BEHAVIORAL_NAMES)),
    loading  = y_loadings[, lv],
    ci_low   = ci_lower[, lv],
    ci_high  = ci_upper[, lv]
  ) %>%
    mutate(sig = !(ci_low <= 0 & ci_high >= 0))

  p_a <- ggplot(load_df, aes(x = loading, y = behavior, colour = sig)) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "grey50") +
    geom_errorbarh(aes(xmin = ci_low, xmax = ci_high), height = 0.3) +
    geom_point(size = 2.5) +
    scale_colour_manual(values = c("FALSE" = "grey60", "TRUE" = "#d62728"),
                        labels = c("n.s.", "significant"),
                        name   = "") +
    labs(
      title = sprintf("LV%d Behavioural Loadings (p = %.4f, varexp = %.1f%%)",
                      lv, pvals[lv], varexp[lv] * 100),
      x = "Loading", y = NULL
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")

  fname <- file.path(OUTPUT_DIR, sprintf("plot_A_loadings_LV%d.pdf", lv))
  ggsave(fname, p_a, width = 7, height = 8)
  cat(sprintf("Saved plot_A_loadings_LV%d.pdf\n", lv))
}

# ============================================================
# PLOT C: Brain vs behaviour scores by group
# ============================================================
scores_df <- subjects %>%
  mutate(
    across(everything(), as.character)
  ) %>%
  bind_cols(
    as.data.frame(x_scores) %>% setNames(paste0("x_lv", 1:n_lvs)),
    as.data.frame(y_scores) %>% setNames(paste0("y_lv", 1:n_lvs))
  ) %>%
  mutate(across(starts_with("x_lv") | starts_with("y_lv"), as.numeric))

for (lv in sig_lvs) {
  p_c <- ggplot(scores_df,
                aes_string(x = paste0("x_lv", lv),
                           y = paste0("y_lv", lv),
                           colour = "Group")) +
    geom_point(alpha = 0.7, size = 2) +
    geom_smooth(method = "lm", se = TRUE, linewidth = 0.8) +
    scale_colour_manual(values = c("ADHD" = "#d62728", "Control" = "#1f77b4")) +
    labs(
      title = sprintf("LV%d: Brain vs Behaviour Scores by Group (p = %.4f)",
                      lv, pvals[lv]),
      x = "Brain Score", y = "Behaviour Score"
    ) +
    theme_minimal()

  fname <- file.path(OUTPUT_DIR, sprintf("plot_C_scores_LV%d.pdf", lv))
  ggsave(fname, p_c, width = 6, height = 5)
  cat(sprintf("Saved plot_C_scores_LV%d.pdf\n", lv))
}

cat("\nAll plots saved to", OUTPUT_DIR, "\n")
