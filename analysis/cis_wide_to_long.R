library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

cis_wide <- fread('output/input_cis_wide.csv')

print('original wide data')
nrow(cis_wide)

# Remove anyone not in the CIS
cis_wide <- cis_wide %>% 
  filter(!is.na(visit_date_0))

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

cis_cols <- cis_wide %>% 
  select(patient_id, date_of_death, sex, 
         first_pos_swab, first_pos_blood, 
         covid_hes, covid_tt, covid_vaccine)

# last_linkage_dt, nhs_data_share)

N <- 25
for (i in 0:N){
  print(i)
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


add_new_wide_col <- function(df_wide, df_long, col, col_regex, join_keys){
  temp <- wide_to_long(df_wide, col, col_regex)
  df_long <- df_long %>% 
    left_join(temp, by = join_keys)
  rm(temp)
  gc()
  
  return(df_long)
}

cis_long <- add_new_wide_col(cis_wide, cis_long, 'result_combined', 'result\\_combined\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'result_combined')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'age', 'age\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'age')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'alcohol', 'alcohol\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'alcohol')


cis_long <- add_new_wide_col(cis_wide, cis_long,  'obesity', 'obesity\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'obesity')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'bmi', 'bmi\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'bmi')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'cancer', 'cancer\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'cancer')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'CVD_ctv3', 'CVD\\_ctv3\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'CDV_ctv3')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'CVD_snomed', 'CVD\\_snomed\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'CVD_snomed')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'digestive_disorder', 'digestive\\_disorder\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'digestive_disorder')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'hiv_aids', 'hiv\\_aids\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'hiv_aids')

temp <- cis_wide %>% select(contains('mental_behavioural_disorder'))
print(colnames(temp))

cis_long <- add_new_wide_col(cis_wide, cis_long, 'mental_behavioural_disorder', 'mental\\_behavioural\\_disorder\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'mental_behavioural_disorder')

temp <- cis_wide %>% select(contains('other_mood_disorder_hospital_history'))
print(colnames(temp))

cis_long <- add_new_wide_col(cis_wide, cis_long, 'other_mood_disorder_hospital_history', 'other\\_mood\\_disorder\\_hospital\\_history\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'other_mood_disorder_hospital_history')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'other_mood_disorder_diagnosis_history', 'other\\_mood\\_disorder\\_diagnosis\\_history\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'other_mood_disorder_diagnosis_history')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'cmd_history_hospital', 'cmd\\_\\history\\_hospital\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'cmd_history_hospital')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'cmd_history', 'cmd\\_\\history\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'cmd_history')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'cmd_outcome_date_hospital', 'cmd\\_\\outcome\\_date\\_hospital\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'cmd_outcome_date_hospital')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'cmd_outcome_date', 'cmd\\_\\outcome\\_date\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'cmd_outcome_date')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'smi_history_hospital', 'smi\\_\\history\\_hospital\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'smi_history_hospital')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'smi_history', 'smi\\_\\history\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'smi_history')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'smi_outcome_date_hospital', 'smi\\_\\outcome\\_date\\_hospital\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'smi_outcome_date_hospital')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'smi_outcome_date', 'smi\\_\\outcome\\_date\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'smi_outcome_date')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'self_harm_history_hospital', 'self_harm\\_\\history\\_hospital\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'self_harm_history_hospital')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'self_harm_history', 'self_harm\\_\\history\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'self_harm_history')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'self_harm_outcome_date_hospital', 'self_harm\\_\\outcome\\_date\\_hospital\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'self_harm_outcome_date_hospital')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'self_harm_outcome_date', 'self_harm\\_\\outcome\\_date\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'self_harm_outcome_date')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'musculoskeletal_ctv3', 'musculoskeletal\\_ctv3\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'musculoskeletal_ctv3')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'musculoskeletal_snomed', 'musculoskeletal\\_snomed\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'musculoskeletal_snomed')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'neurological_ctv3', 'neurological\\_ctv3\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'neurological_ctv3')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'neurological_snomed', 'neurological\\_snomed\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'neurological_snomed')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'kidney_disorder', 'kidney\\_disorder\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'kidney_disorder')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'respiratory_disorder', 'respiratory\\_disorder\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'respiratory_disorder')

cis_long <- add_new_wide_col(cis_wide, cis_long, 'metabolic_disorder', 'metabolic\\_disorder\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'metabolic_disorder')


cis_long <- cis_long %>% 
  left_join(cis_cols, by = 'patient_id') %>% 
  filter(age >= 16) %>% 
  select(-visit_number)

rm(cis_cols, cis_wide)
gc()


# Save out
write_csv(cis_long, 'output/input_cis_long.csv')
