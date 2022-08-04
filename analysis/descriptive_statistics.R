library(tidyverse)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

source('analysis/cov_dist_cat.R')
source('analysis/cov_dist_cont.R')

matched <- read_csv('output/adjusted_groups.csv', guess_max = 100000)

# Need to read in matched person level data
# Only need to consider participants characteristics at the index date
# 100% of cases and 0% controls should have result_mk == 1

# Create bmi category variable
matched <- matched %>% 
  mutate(bmi_category = case_when(
    bmi < 18.5 ~ 'underweight',
    bmi >= 18.5 & bmi < 25 ~ 'ideal',
    bmi >= 25 & bmi < 30 ~ 'overweight',
    bmi >= 30 ~ 'obese'))

cat_vars <- c("alcohol", "obesity", "cancer", "digestive_disorder",
              "hiv_aids", "mental_disorder_history", "mental_disorder_outcome",
              "metabolic_disorder", "kidney_disorder", "respiratory_disorder",
              "CVD", "musculoskeletal", "neurological", "bmi_category")
cat_stats <- cov.dist.cat(vars = cat_vars, dataset = matched, exposure = 'exposed')

cont_vars <- c('bmi', 'age')
cont_stats <- cov.dist.cont(vars = cont_vars, dataset = matched, exposure = 'exposed')

write_csv(cat_stats, 'output/cat_stats.csv')
write_csv(cont_stats, 'output/cont_stats.csv')

# TODO - calculates incidence of common mental disorders (outcomes).
# Rate per 1000 person-years

# Follow up time - will need date of when mental disorder was diagnosed 
# - back to study definition

# Poisson.test - to see rate with CIs

# Prevalence & incidence
