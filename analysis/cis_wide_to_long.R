library(tidyverse)
library(purrr)

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
result_combined <- wide_to_long(cis_wide, 'result_combined', 'result\\_combined\\_\\d+')

cis_dates <- cis_wide %>% 
  select(patient_id, date_of_death, 
         first_pos_swab, first_pos_blood, 
         covid_hes, covid_tt, covid_vaccine)

alcohol <- wide_to_long(cis_wide, 'alcohol', 'alcohol\\_\\d+')

obesity <- wide_to_long(cis_wide, 'obesity', 'obesity\\_\\d+')

bmi <- wide_to_long(cis_wide, 'bmi', 'bmi\\_\\d+')

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

rm(cis_wide)
gc()

join_keys <- c('patient_id', 'visit_number')

# Join everything together
cis_long <- visit_date %>% 
  left_join(result_mk, by = join_keys)
rm(result_mk)

cis_long <- cis_long %>% 
  left_join(result_combined, by = join_keys)
rm(result_combined)

cis_long <- cis_long %>% 
  left_join(alcohol, by = join_keys)
rm(alcohol)

cis_long <- cis_long %>% 
  left_join(obesity, by = join_keys)
rm(obesity)

cis_long <- cis_long %>% 
  left_join(bmi, by = join_keys)
rm(bmi)

cis_long <- cis_long %>% 
  left_join(cancer, by = join_keys) 
rm(cancer)

cis_long <- cis_long %>% 
  left_join(CVD_ctv3, by = join_keys)
rm(CVD_ctv3)

cis_long <- cis_long %>% 
  left_join(CVD_snomed, by = join_keys)
rm(CVD_snomed)
   
cis_long <- cis_long %>% 
  left_join(digestive_disorder, by = join_keys)
rm(digestive_disorder)
   
cis_long <- cis_long %>% 
  left_join(hiv_aids, by = join_keys) 
rm(hiv_aids)

cis_long <- cis_long %>% 
  left_join(mental_disorder, by = join_keys)
rm(mental_disorder)

cis_long <- cis_long %>% 
  left_join(metabolic_disorder, by = join_keys)
rm(metabolic_disorder)

cis_long <- cis_long %>% 
  left_join(musculoskeletal_ctv3, by = join_keys)
rm(musculoskeletal_ctv3)

cis_long <- cis_long %>% 
  left_join(musculoskeletal_snomed, by = join_keys)
rm(musculoskeletal_snomed)

cis_long <- cis_long %>% 
  left_join(neurological_ctv3, by = join_keys)
rm(neurological_ctv3)

cis_long <- cis_long %>% 
  left_join(neurological_snomed, by = join_keys)
rm(neurological_snomed)

cis_long <- cis_long %>% 
  left_join(kidney_disorder, by = join_keys)
rm(kidney_disorder)

cis_long <- cis_long %>% 
  left_join(respiratory_disorder, by = join_keys) %>% 
  select(-visit_number)
rm(respiratory_disorder)

cis_long <- cis_long %>% 
  left_join(cis_dates, by = 'patient_id')
rm(cis_dates)
gc()

# Save out
write_csv(cis_long, 'output/input_cis_long.csv')
