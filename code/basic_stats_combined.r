library(tidyverse)                                                                                             
              
  excluded_ids <- scan("excluded_ids.txt", quiet = TRUE)                                  
                                                                                                                 
  df_full <- read.csv(sep="\t",                                                                                  
  "~/scratch/projects/hailab_ADHD/r_analysis/Demographic_Data_ADHD_combined_Jan102026_cleaned.tsv")
  df <- df_full[!df_full$Participant_ID %in% excluded_ids, ]                                                     
                                                                                                                 
  run_stats <- function(dat, label) {
    chisq_result <- chisq.test(table(dat$Group, dat$Sex))                                                        
    sex_counts   <- table(dat$Group, dat$Sex)
    sex_props    <- prop.table(table(dat$Group, dat$Sex), margin = 1)                                            
    t_result     <- t.test(Age_years ~ Group, data = dat)
                                                                                                                 
    descriptives <- dat %>%                                                                                      
      group_by(Group) %>%
      summarise(                                                                                                 
        n        = n(),
        age_mean = mean(Age_years, na.rm = TRUE),
        age_sd   = sd(Age_years, na.rm = TRUE),
        n_male   = sum(Sex == "Male", na.rm = TRUE),                                                             
        pct_male = mean(Sex == "Male", na.rm = TRUE) * 100
      ) %>%                                                                                                      
      mutate(sample = label)                                                                                     
   
    list(descriptives = descriptives, chisq = chisq_result,                                                      
         sex_counts = sex_counts, sex_props = sex_props, t_result = t_result)
  }                                                                                                              
              
  before <- run_stats(df_full, "before_removal")                                                                 
  after  <- run_stats(df,      "after_removal")
                                                                                                                 
  # Combined descriptives CSV                                                                                    
  bind_rows(before$descriptives, after$descriptives) %>%
    write_csv("descriptives_combined.csv")                                                                       
              
  # Combined stats text file
  sink("group_comparison_tests_combined.txt")
  for (res in list(list(label="BEFORE REMOVAL", r=before), list(label="AFTER REMOVAL", r=after))) {              
    cat("========================================\n")                                                            
    cat(paste0("=== ", res$label, " ===\n"))                                                                     
    cat("========================================\n\n")                                                          
    cat("--- Chi-squared: Group x Sex ---\n")
    print(res$r$chisq)                                                                                           
    cat("\nCounts:\n")
    print(res$r$sex_counts)                                                                                      
    cat("\nProportions (row %):\n")
    print(round(res$r$sex_props * 100, 1))                                                                       
    cat("\n--- T-test: Age by Group ---\n")
    print(res$r$t_result)                                                                                        
    cat("\n")                                                                                                    
  }
  sink()        
