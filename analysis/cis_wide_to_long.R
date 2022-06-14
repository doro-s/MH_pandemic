library(tidyverse)

cis_wide <- read_csv('output/input_cis_wide.csv')

cis_long <- cis_wide %>%
  select(patient_id, matches('cis\\_visit\\_date\\_\\d+')) %>% 
  pivot_longer(cols = -patient_id,
               names_to = c(NA, 'visit_number'),
               names_pattern = '^(.*)_(\\d+)',
               values_to = 'visit_date',
               values_drop_na = TRUE) %>%
  arrange(patient_id, visit_number)

write_csv(cis_long, 'output/input_cis_long.csv')
