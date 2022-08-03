library(tidyverse)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

cis_long <- read_csv('output/input_cis_long.csv')

cis_long <- cis_long %>% 
  mutate(CVD = ifelse(CVD_snomed == 1 | CVD_ctv3 == 1, 1, 0),
         musculoskeletal = ifelse(musculoskeletal_snomed == 1 | musculoskeletal_ctv3 == 1, 1, 0),
         neurological = if_else(neurological_snomed == 1 | neurological_ctv3 == 1, 1, 0)) %>%
  select(-CVD_snomed, -CVD_ctv3,
         -musculoskeletal_snomed, -musculoskeletal_ctv3,
         -neurological_snomed, -neurological_ctv3)

# Add a check for where date of death is all NAs - convert from logical to date
if (sum(is.na(cis_long$date_of_death)) == nrow(cis_long)){
  cis_long <- cis_long %>% 
    mutate(date_of_death = as.Date('2100-01-01'))
}


write_csv(cis_long, 'output/input_reconciled.csv')
