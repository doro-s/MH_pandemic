library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

mh <- fread('output/input_health_mh.csv') %>% 
  select(-contains('visit_date_'))

non_mh <- fread('output/input_health_non_mh.csv') %>% 
  select(-contains('visit_date_'))

non_health <- fread('output/input_non_health.csv')

combined <- non_health %>% 
  left_join(mh, by = 'patient_id') %>% 
  left_join(non_mh, by = 'patient_id')

write_csv(combined, 'output/input_cis_wide.csv')
