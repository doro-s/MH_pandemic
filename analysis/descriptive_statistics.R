library(tidyverse)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

source('../analysis/cov_dist_cat.R')
source('../analysis/cov_dist_cont.R')

matched <- read_csv('../output/group_flags.csv')

# Need to read in matched person level data
# Only need to consider participants characteristics at the index date
# 100% of cases and 0% controls should have result_mk == 1

# Read in exposed population
exposed <- read_csv('../output/cis_exposed.csv')

# Bring cis dates into memory
control <- read_csv('../output/cis_control.csv')

# Add flag for exposed
control <- control %>% 
  group_by(patient_id) %>% 
  mutate(ever_tested_pos = ifelse(sum(result_mk) > 0, 1, 0)) %>% 
  ungroup()

cov.dist.cat(vars = c('result_mk'), dataset = control, exposure = 'ever_tested_pos')

