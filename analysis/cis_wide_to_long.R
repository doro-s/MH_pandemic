library(tidyverse)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

cis_wide <- read_csv('../output/input_cis_wide.csv')

visit_date <- cis_wide %>%
  select(patient_id, matches('visit\\_date\\_\\d+')) %>% 
  pivot_longer(cols = -patient_id,
               names_to = c(NA, 'visit_number'),
               names_pattern = '^(.*)_(\\d+)',
               values_to = 'visit_date',
               values_drop_na = TRUE) %>%
  mutate(visit_number = as.numeric(visit_number)) %>% 
  arrange(patient_id, visit_number)

result_mk <- cis_wide %>%
  select(patient_id, matches('result\\_mk\\_\\d+')) %>% 
  pivot_longer(cols = -patient_id,
               names_to = c(NA, 'visit_number'),
               names_pattern = '^(.*)_(\\d+)',
               values_to = 'result_mk',
               values_drop_na = TRUE) %>%
  mutate(visit_number = as.numeric(visit_number)) %>% 
  arrange(patient_id, visit_number)

cis_long <- visit_date %>% 
  left_join(result_mk, by = c('patient_id', 'visit_number'))

# TODO
# Put in sense check to remove rows where visit dates are not monotonically
# increasing

write_csv(cis_long, 'output/input_cis_long.csv')
