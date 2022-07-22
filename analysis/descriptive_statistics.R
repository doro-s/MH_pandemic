library(tidyverse)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

source('../analysis/cov_dist_cat.R')
source('../analysis/cov_dist_cont.R')

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

