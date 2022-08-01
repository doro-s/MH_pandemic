library(tidyverse)
library(purrr)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

cis_wide <- read_csv('output/input_cis_wide.csv')

table_dims <- as.data.frame(dim(cis_wide))
write_csv(table_dims, 'output/cis_wide_dimensions.csv')

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

cis_dates <- cis_wide %>% 
  select(patient_id, date_of_death, 
         first_pos_swab, first_pos_blood, 
         covid_hes, covid_tt, covid_vaccine)

# Join keys
join_keys <- c('patient_id', 'visit_number')

visit_date <- wide_to_long(cis_wide, 'visit_date', 'visit\\_date\\_\\d+') %>% 
  filter(!is.na(visit_date))
result_mk <- wide_to_long(cis_wide, 'result_mk', 'result\\_mk\\_\\d+')
cis_long <- visit_date %>% 
  left_join(result_mk, by = join_keys)
rm(visit_date, result_mk)


result_combined <- wide_to_long(cis_wide, 'result_combined', 'result\\_combined\\_\\d+')
cis_long <- cis_long %>% 
  left_join(result_combined, by = join_keys)
rm(result_combined)


alcohol <- wide_to_long(cis_wide, 'alcohol', 'alcohol\\_\\d+')
cis_long <- cis_long %>% 
  left_join(alcohol, by = join_keys)
rm(alcohol)


obesity <- wide_to_long(cis_wide, 'obesity', 'obesity\\_\\d+')
cis_long <- cis_long %>% 
  left_join(obesity, by = join_keys)
rm(obesity)


bmi <- wide_to_long(cis_wide, 'bmi', 'bmi\\_\\d+')
cis_long <- cis_long %>% 
  left_join(bmi, by = join_keys)
rm(bmi)


cancer <- wide_to_long(cis_wide, 'cancer', 'cancer\\_\\d+')
cis_long <- cis_long %>% 
  left_join(cancer, by = join_keys) 
rm(cancer)


CVD_ctv3 <- wide_to_long(cis_wide, 'CVD_ctv3', 'CVD\\_ctv3\\_\\d+')
cis_long <- cis_long %>% 
  left_join(CVD_ctv3, by = join_keys)
rm(CVD_ctv3)


CVD_snomed <- wide_to_long(cis_wide, 'CVD_snomed', 'CVD\\_snomed\\_\\d+')
cis_long <- cis_long %>% 
  left_join(CVD_snomed, by = join_keys)
rm(CVD_snomed)


digestive_disorder <- wide_to_long(cis_wide, 'digestive_disorder', 'digestive\\_disorder\\_\\d+')
cis_long <- cis_long %>% 
  left_join(digestive_disorder, by = join_keys)
rm(digestive_disorder)


hiv_aids <- wide_to_long(cis_wide, 'hiv_aids', 'hiv\\_aids\\_\\d+')
cis_long <- cis_long %>% 
  left_join(hiv_aids, by = join_keys) 
rm(hiv_aids)


mental_disorder <- wide_to_long(cis_wide, 'mental_disorder', 'mental\\_disorder\\_\\d+')
cis_long <- cis_long %>% 
  left_join(mental_disorder, by = join_keys)
rm(mental_disorder)


metabolic_disorder <- wide_to_long(cis_wide, 'metabolic_disorder', 'metabolic\\_disorder\\_\\d+')
cis_long <- cis_long %>% 
  left_join(metabolic_disorder, by = join_keys)
rm(metabolic_disorder)


musculoskeletal_ctv3 <- wide_to_long(cis_wide, 'musculoskeletal_ctv3', 'musculoskeletal\\_ctv3\\_\\d+')
cis_long <- cis_long %>% 
  left_join(musculoskeletal_ctv3, by = join_keys)
rm(musculoskeletal_ctv3)


musculoskeletal_snomed <- wide_to_long(cis_wide, 'musculoskeletal_snomed', 'musculoskeletal\\_snomed\\_\\d+')
cis_long <- cis_long %>% 
  left_join(musculoskeletal_snomed, by = join_keys)
rm(musculoskeletal_snomed)


neurological_ctv3 <- wide_to_long(cis_wide, 'neurological_ctv3', 'neurological\\_ctv3\\_\\d+')
cis_long <- cis_long %>% 
  left_join(neurological_ctv3, by = join_keys)
rm(neurological_ctv3)


neurological_snomed <- wide_to_long(cis_wide, 'neurological_snomed', 'neurological\\_snomed\\_\\d+')
cis_long <- cis_long %>% 
  left_join(neurological_snomed, by = join_keys)
rm(neurological_snomed)


kidney_disorder <- wide_to_long(cis_wide, 'kidney_disorder', 'kidney\\_disorder\\_\\d+')
cis_long <- cis_long %>% 
  left_join(kidney_disorder, by = join_keys)
rm(kidney_disorder)


respiratory_disorder <- wide_to_long(cis_wide, 'respiratory_disorder', 'respiratory\\_disorder\\_\\d+')
cis_long <- cis_long %>% 
  left_join(respiratory_disorder, by = join_keys) %>% 
  select(-visit_number)
rm(respiratory_disorder)


cis_long <- cis_long %>% 
  left_join(cis_dates, by = 'patient_id')
rm(cis_dates, cis_wide)
gc()


# Save out
write_csv(cis_long, 'output/input_cis_long.csv')
