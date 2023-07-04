## ===========================================================
# The aim of this code is to combine all study populations derived 
#  through cohort extractor (into a wide format)
## ===========================================================
library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# set working directory - only needed when running remotely
# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

mh <- fread('output/input_health_mh.csv') %>%
  select(-contains('visit_date_'))

non_mh <- fread('output/input_health_non_mh.csv') %>%
  select(-contains('visit_date_'))

cis_new <- fread('output/dataset_ons_cis_new.csv') %>%
  select(-contains('visit_date_'))

non_health <- fread('output/input_non_health.csv')

combined <- non_health %>% 
  left_join(mh, by = 'patient_id') %>%
  left_join(non_mh, by = 'patient_id') #%>%
  #left_join(cis_new, by = 'patient_id')

write_csv(combined, 'output/input_cis_wide.csv')
