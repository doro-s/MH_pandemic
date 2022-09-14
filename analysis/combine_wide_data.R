library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

health <- fread('output/input_health.csv')
non_health <- fread('output/input_non_health.csv')

combined <- health %>% 
  select(-contains('visit_date_')) %>% 
  left_join(non_health, by = 'patient_id')

write_csv(combined, 'output/input_cis_wide.csv')
