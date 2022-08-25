library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

source('analysis/cov_dist_cat.R')
source('analysis/cov_dist_cont.R')

incidence <- fread('output/incidence_group.csv')
prevalence <- fread('output/prevalence_group.csv')
exac <- fread('output/exacerbated_group.csv')

# Need to read in matched person level data
# Only need to consider participants characteristics at the index date
# 100% of cases and 0% controls should have result_mk == 1

# Create bmi category variable
create_bmi_categories <- function(df){
  df <- df %>% 
    mutate(bmi_category = case_when(
      bmi < 18.5 ~ 'underweight',
      bmi >= 18.5 & bmi < 25 ~ 'ideal',
      bmi >= 25 & bmi < 30 ~ 'overweight',
      bmi >= 30 ~ 'obese'))
  
  return(df)
}

incidence <- create_bmi_categories(incidence)
prevalence <- create_bmi_categories(prevalence)
exac <- create_bmi_categories(exac)

cat_vars <- c("alcohol", "obesity", "cancer", "digestive_disorder",
              "hiv_aids", "metabolic_disorder", "kidney_disorder",
              "respiratory_disorder", "CVD", "musculoskeletal", 
              "neurological", "bmi_category", "sex",
              "cmd_history", "cmd_history_hospital",
              "cmd_outcome", "cmd_outcome_hospital",
              "smi_history", "smi_history_hospital",
              "smi_outcome", "smi_outcome_hospital",
              "self_harm_history", "self_harm_history_hospital",
              "self_harm_outcome", "self_harm_outcome_hospital")

continuous_vars <- c('bmi', 'age')

if (nrow(incidence) > 0){
  incidence_cat_stats <- cov.dist.cat(vars = cat_vars, dataset = incidence, exposure = 'exposed')
  incidence_con_stats <- cov.dist.cont(vars = continuous_vars, dataset = incidence, exposure = 'exposed')
  write_csv(incidence_cat_stats, 'output/incidence_cat_stats.csv')
  write_csv(incidence_con_stats, 'output/incidence_con_stats.csv')
}

if (nrow(prevalence) > 0){
  prevalence_cat_stats <- cov.dist.cat(vars = cat_vars, dataset = prevalence, exposure = 'exposed')
  prevalence_con_stats <- cov.dist.cont(vars = continuous_vars, dataset = prevalence, exposure = 'exposed')
  write_csv(prevalence_cat_stats, 'output/prevalence_cat_stats.csv')
  write_csv(prevalence_con_stats, 'output/prevalence_con_stats.csv')
}

if (nrow(exac) > 0){
  exac_cat_stats <- cov.dist.cat(vars = cat_vars, dataset = exac, exposure = 'exposed')
  exac_con_stats <- cov.dist.cont(vars = continuous_vars, dataset = exac, exposure = 'exposed')
  write_csv(exac_cat_stats, 'output/exacerbated_cat_stats.csv')
  write_csv(exac_con_stats, 'output/exacerbated_con_stats.csv')
}

# TODO - calculates incidence of common mental disorders (outcomes).
# Rate per 1000 person-years

# Follow up time

# Poisson.test - to see rate with CIs
