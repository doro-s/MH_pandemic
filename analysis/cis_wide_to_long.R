library(tidyverse)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

cis_wide <- read_csv('output/input_cis_wide.csv')

wide_to_long <- function(df_wide, col, regex){
  
  df_long <- cis_wide %>%
    select(patient_id, matches(regex)) %>% 
    pivot_longer(cols = -patient_id,
                 names_to = c(NA, 'visit_number'),
                 names_pattern = '^(.*)_(\\d+)',
                 values_to = col,
                 values_drop_na = TRUE) %>%
    mutate(visit_number = as.numeric(visit_number)) %>% 
    arrange(patient_id, visit_number)
  
  return(df_long)
}

visit_date <- wide_to_long(cis_wide, 'visit_date', 'visit\\_date\\_\\d+')
result_mk <- wide_to_long(cis_wide, 'result_mk', 'result\\_mk\\_\\d+')
covid_hes <- wide_to_long(cis_wide, 'covid_hes', 'covid\\_hes\\_\\d+')
covid_tt <- wide_to_long(cis_wide, 'covid_tt', 'covid\\_tt\\_\\d+')
covid_vaccine <- wide_to_long(cis_wide, 'covid_vaccine', 'covid\\_vaccine\\_\\d+')

alcohol <- wide_to_long(cis_wide, 'alcohol', 'alcohol\\_\\d+')

cancer <- wide_to_long(cis_wide, 'cancer', 'cancer\\_\\d+')

CVD_ctv3 <- wide_to_long(cis_wide, 'CVD_ctv3', 'CVD\\_ctv3\\_\\d+')

CVD_snomed <- wide_to_long(cis_wide, 'CVD_snomed', 'CVD\\_snomed\\_\\d+')

digestive_disorder <- wide_to_long(cis_wide, 'digestive_disorder', 'digestive\\_disorder\\_\\d+')

hiv_aids <- wide_to_long(cis_wide, 'hiv_aids', 'hiv\\_aids\\_\\d+')

mental_disorder <- wide_to_long(cis_wide, 'mental_disorder', 'mental\\_disorder\\_\\d+')

metabolic_disorder <- wide_to_long(cis_wide, 'metabolic_disorder', 'metabolic\\_disorder\\_\\d+')

musculoskeletal_ctv3 <- wide_to_long(cis_wide, 'musculoskeletal_ctv3', 'musculoskeletal\\_ctv3\\_\\d+')
musculoskeletal_snomed <- wide_to_long(cis_wide, 'musculoskeletal_snomed', 'musculoskeletal\\_snomed\\_\\d+')

neurological_ctv3 <- wide_to_long(cis_wide, 'neurological_ctv3', 'neurological\\_ctv3\\_\\d+')
neurological_snomed <- wide_to_long(cis_wide, 'neurological_snomed', 'neurological\\_snomed\\_\\d+')

kidney_disorder <- wide_to_long(cis_wide, 'kidney_disorder', 'kidney\\_disorder\\_\\d+')

respiratory_disorder <- wide_to_long(cis_wide, 'respiratory_disorder', 'respiratory\\_disorder\\_\\d+')

# Join everything together
cis_long <- visit_date %>% 
  left_join(result_mk, by = c('patient_id', 'visit_number')) %>% 
  left_join(covid_hes, by = c('patient_id', 'visit_number')) %>% 
  left_join(covid_tt, by = c('patient_id', 'visit_number')) %>% 
  left_join(covid_vaccine, by = c('patient_id', 'visit_number')) %>% 
  left_join(alcohol, by = c('patient_id', 'visit_number')) %>% 
  left_join(cancer, by = c('patient_id', 'visit_number')) %>% 
  left_join(CVD_ctv3, by = c('patient_id', 'visit_number')) %>% 
  left_join(CVD_snomed, by = c('patient_id', 'visit_number')) %>% 
  left_join(digestive_disorder, by = c('patient_id', 'visit_number')) %>% 
  left_join(hiv_aids, by = c('patient_id', 'visit_number')) %>% 
  left_join(mental_disorder, by = c('patient_id', 'visit_number')) %>% 
  left_join(metabolic_disorder, by = c('patient_id', 'visit_number')) %>% 
  left_join(musculoskeletal_ctv3, by = c('patient_id', 'visit_number')) %>% 
  left_join(musculoskeletal_snomed, by = c('patient_id', 'visit_number')) %>% 
  left_join(neurological_ctv3, by = c('patient_id', 'visit_number')) %>% 
  left_join(neurological_snomed, by = c('patient_id', 'visit_number')) %>% 
  left_join(kidney_disorder, by = c('patient_id', 'visit_number')) %>% 
  left_join(respiratory_disorder, by = c('patient_id', 'visit_number'))

# TODO
# Put in sense check to remove rows where visit dates are not monotonically
# increasing
# Shouldn't be a problem in the real data but will affect pipeline devlopment

write_csv(cis_long, 'output/input_cis_long.csv')
