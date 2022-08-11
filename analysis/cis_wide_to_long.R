library(tidyverse)
library(purrr)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

cis_wide <- read_csv('output/input_cis_wide.csv', guess_max = 1000000)

N <- 25

print('original wide data')
nrow(cis_wide)

# Remove anyone not in the CIS
cis_wide <- cis_wide %>% 
  filter(!is.na(visit_date_1))

print('cis only wide data')
nrow(cis_wide)


wide_to_long <- function(df_wide, col, regex){
  
  df_long <- cis_wide %>%
    select(patient_id, matches(regex)) %>% 
    pivot_longer(cols = -patient_id,
                 names_to = c(NA, 'visit_number'),
                 names_pattern = '^(.*)_(\\d+)',
                 values_to = col,
                 values_drop_na = FALSE) %>%
    mutate(visit_number = as.numeric(visit_number)) %>% 
    arrange(patient_id, visit_number)
  
  return(df_long)
}

remove_cols_string <- function(df, string){
  df <- df %>% 
    select(-contains(string))
  return(df)
}

cis_dates <- cis_wide %>% 
  select(patient_id, date_of_death, 
         first_pos_swab, first_pos_blood, 
         covid_hes, covid_tt, covid_vaccine)

# last_linkage_dt, nhs_data_share)

for (i in 0:N){
  v_date <- paste0('visit_date_', i)
  r_mk <- paste0('result_mk_', i)
  print(cis_wide %>% pull(r_mk) %>% table())
  print(paste0('min visit date ', i))
  print(cis_wide %>% pull(v_date) %>% min(na.rm = TRUE))
  print(paste0('max visit date ', i))
  print(cis_wide %>% pull(v_date) %>% max(na.rm = TRUE))
  cat('\n')
}

# after filters (age > 16)


# Join keys
join_keys <- c('patient_id', 'visit_number')

visit_date <- wide_to_long(cis_wide, 'visit_date', 'visit\\_date\\_\\d+')
result_mk <- wide_to_long(cis_wide, 'result_mk', 'result\\_mk\\_\\d+')
cis_long <- visit_date %>% 
  left_join(result_mk, by = join_keys)
rm(visit_date, result_mk)
cis_wide <- remove_cols_string(cis_wide, 'visit_date')
cis_wide <- remove_cols_string(cis_wide, 'result_mk')


result_combined <- wide_to_long(cis_wide, 'result_combined', 'result\\_combined\\_\\d+')
cis_long <- cis_long %>% 
  left_join(result_combined, by = join_keys)
rm(result_combined)
cis_wide <- remove_cols_string(cis_wide, 'result_combined')


age <- wide_to_long(cis_wide, 'age', 'age\\_\\d+')
cis_long <- cis_long %>% 
  left_join(age, by = join_keys)
rm(age)
cis_wide <- remove_cols_string(cis_wide, 'age')


alcohol <- wide_to_long(cis_wide, 'alcohol', 'alcohol\\_\\d+')
cis_long <- cis_long %>% 
  left_join(alcohol, by = join_keys)
rm(alcohol)
cis_wide <- remove_cols_string(cis_wide, 'alcohol')


obesity <- wide_to_long(cis_wide, 'obesity', 'obesity\\_\\d+')
cis_long <- cis_long %>% 
  left_join(obesity, by = join_keys)
rm(obesity)
cis_wide <- remove_cols_string(cis_wide, 'obesity')


bmi <- wide_to_long(cis_wide, 'bmi', 'bmi\\_\\d+')
cis_long <- cis_long %>% 
  left_join(bmi, by = join_keys)
rm(bmi)
cis_wide <- remove_cols_string(cis_wide, 'bmi')


cancer <- wide_to_long(cis_wide, 'cancer', 'cancer\\_\\d+')
cis_long <- cis_long %>% 
  left_join(cancer, by = join_keys) 
rm(cancer)
cis_wide <- remove_cols_string(cis_wide, 'cancer')


CVD_ctv3 <- wide_to_long(cis_wide, 'CVD_ctv3', 'CVD\\_ctv3\\_\\d+')
cis_long <- cis_long %>% 
  left_join(CVD_ctv3, by = join_keys)
rm(CVD_ctv3)
cis_wide <- remove_cols_string(cis_wide, 'CDV_ctv3')


CVD_snomed <- wide_to_long(cis_wide, 'CVD_snomed', 'CVD\\_snomed\\_\\d+')
cis_long <- cis_long %>% 
  left_join(CVD_snomed, by = join_keys)
rm(CVD_snomed)
cis_wide <- remove_cols_string(cis_wide, 'CVD_snomed')


digestive_disorder <- wide_to_long(cis_wide, 'digestive_disorder', 'digestive\\_disorder\\_\\d+')
cis_long <- cis_long %>% 
  left_join(digestive_disorder, by = join_keys)
rm(digestive_disorder)
cis_wide <- remove_cols_string(cis_wide, 'digestive_disorder')


hiv_aids <- wide_to_long(cis_wide, 'hiv_aids', 'hiv\\_aids\\_\\d+')
cis_long <- cis_long %>% 
  left_join(hiv_aids, by = join_keys) 
rm(hiv_aids)
cis_wide <- remove_cols_string(cis_wide, 'hiv_aids')


cmd_history_hospital <- wide_to_long(cis_wide, 'cmd_history_hospital', 'cmd\\_\\history\\_hospital\\_\\d+')
cis_long <- cis_long %>% 
  left_join(cmd_history_hospital, by = join_keys)
rm(cmd_history_hospital)
cis_wide <- remove_cols_string(cis_wide, 'cmd_history_hospital')


cmd_history <- wide_to_long(cis_wide, 'cmd_history', 'cmd\\_\\history\\_\\d+')
cis_long <- cis_long %>% 
  left_join(cmd_history, by = join_keys)
rm(cmd_history)
cis_wide <- remove_cols_string(cis_wide, 'cmd_history')


cmd_outcome_hospital <- wide_to_long(cis_wide, 'cmd_outcome_date_hospital', 'cmd\\_\\outcome\\_date\\_hospital\\_\\d+')
cis_long <- cis_long %>% 
  left_join(cmd_outcome_hospital, by = join_keys)
rm(cmd_outcome_hospital)
cis_wide <- remove_cols_string(cis_wide, 'cmd_outcome_date_hospital')


cmd_outcome <- wide_to_long(cis_wide, 'cmd_outcome_date', 'cmd\\_\\outcome\\_date\\_\\d+')
cis_long <- cis_long %>% 
  left_join(cmd_outcome, by = join_keys)
rm(cmd_outcome)
cis_wide <- remove_cols_string(cis_wide, 'cmd_outcome_date')


smi_history_hospital <- wide_to_long(cis_wide, 'smi_history_hospital', 'smi\\_\\history\\_hospital\\_\\d+')
cis_long <- cis_long %>% 
  left_join(smi_history_hospital, by = join_keys)
rm(smi_history_hospital)
cis_wide <- remove_cols_string(cis_wide, 'smi_history_hospital')


smi_history <- wide_to_long(cis_wide, 'smi_history', 'smi\\_\\history\\_\\d+')
cis_long <- cis_long %>% 
  left_join(smi_history, by = join_keys)
rm(smi_history)
cis_wide <- remove_cols_string(cis_wide, 'smi_history')


smi_outcome_hospital <- wide_to_long(cis_wide, 'smi_outcome_date_hospital', 'smi\\_\\outcome\\_date\\_hospital\\_\\d+')
cis_long <- cis_long %>% 
  left_join(smi_outcome_hospital, by = join_keys)
rm(smi_outcome_hospital)
cis_wide <- remove_cols_string(cis_wide, 'smi_outcome_date_hospital')


smi_outcome <- wide_to_long(cis_wide, 'smi_outcome_date', 'smi\\_\\outcome\\_date\\_\\d+')
cis_long <- cis_long %>% 
  left_join(smi_outcome, by = join_keys)
rm(smi_outcome)
cis_wide <- remove_cols_string(cis_wide, 'smi_outcome_date')


self_harm_history_hospital <- wide_to_long(cis_wide, 'self_harm_history_hospital', 'self_harm\\_\\history\\_hospital\\_\\d+')
cis_long <- cis_long %>% 
  left_join(self_harm_history_hospital, by = join_keys)
rm(self_harm_history_hospital)
cis_wide <- remove_cols_string(cis_wide, 'self_harm_history_hospital')


self_harm_history <- wide_to_long(cis_wide, 'self_harm_history', 'self_harm\\_\\history\\_\\d+')
cis_long <- cis_long %>% 
  left_join(self_harm_history, by = join_keys)
rm(self_harm_history)
cis_wide <- remove_cols_string(cis_wide, 'self_harm_history')


self_harm_outcome_hospital <- wide_to_long(cis_wide, 'self_harm_outcome_date_hospital', 'self_harm\\_\\outcome\\_date\\_hospital\\_\\d+')
cis_long <- cis_long %>% 
  left_join(self_harm_outcome_hospital, by = join_keys)
rm(self_harm_outcome_hospital)
cis_wide <- remove_cols_string(cis_wide, 'self_harm_outcome_date_hospital')


self_harm_outcome <- wide_to_long(cis_wide, 'self_harm_outcome_date', 'self_harm\\_\\outcome\\_date\\_\\d+')
cis_long <- cis_long %>% 
  left_join(self_harm_outcome, by = join_keys)
rm(self_harm_outcome)
cis_wide <- remove_cols_string(cis_wide, 'self_harm_outcome_date')


musculoskeletal_ctv3 <- wide_to_long(cis_wide, 'musculoskeletal_ctv3', 'musculoskeletal\\_ctv3\\_\\d+')
cis_long <- cis_long %>% 
  left_join(musculoskeletal_ctv3, by = join_keys)
rm(musculoskeletal_ctv3)
cis_wide <- remove_cols_string(cis_wide, 'musculoskeletal_ctv3')


musculoskeletal_snomed <- wide_to_long(cis_wide, 'musculoskeletal_snomed', 'musculoskeletal\\_snomed\\_\\d+')
cis_long <- cis_long %>% 
  left_join(musculoskeletal_snomed, by = join_keys)
rm(musculoskeletal_snomed)
cis_wide <- remove_cols_string(cis_wide, 'musculoskeletal_snomed')


neurological_ctv3 <- wide_to_long(cis_wide, 'neurological_ctv3', 'neurological\\_ctv3\\_\\d+')
cis_long <- cis_long %>% 
  left_join(neurological_ctv3, by = join_keys)
rm(neurological_ctv3)
cis_wide <- remove_cols_string(cis_wide, 'neurological_ctv3')


neurological_snomed <- wide_to_long(cis_wide, 'neurological_snomed', 'neurological\\_snomed\\_\\d+')
cis_long <- cis_long %>% 
  left_join(neurological_snomed, by = join_keys)
rm(neurological_snomed)
cis_wide <- remove_cols_string(cis_wide, 'neurological_snomed')


kidney_disorder <- wide_to_long(cis_wide, 'kidney_disorder', 'kidney\\_disorder\\_\\d+')
cis_long <- cis_long %>% 
  left_join(kidney_disorder, by = join_keys)
rm(kidney_disorder)
cis_wide <- remove_cols_string(cis_wide, 'kidney_disorder')


respiratory_disorder <- wide_to_long(cis_wide, 'respiratory_disorder', 'respiratory\\_disorder\\_\\d+')
cis_long <- cis_long %>% 
  left_join(respiratory_disorder, by = join_keys)
rm(respiratory_disorder)
cis_wide <- remove_cols_string(cis_wide, 'respiratory_disorder')


cis_long <- cis_long %>% 
  left_join(cis_dates, by = 'patient_id') %>% 
  select(-visit_number)
rm(cis_dates, cis_wide)
gc()


# Save out
write_csv(cis_long, 'output/input_cis_long.csv')
