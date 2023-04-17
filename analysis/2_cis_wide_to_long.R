library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

cis_wide <- fread('output/input_cis_wide.csv')

print('original wide data')
nrow(cis_wide)

# Remove anyone not in the CIS
cis_wide <- cis_wide %>% 
  filter(!is.na(visit_date_0)) %>%
  filter(sex == 'M' | sex == 'F') %>%
  filter(!gor9d %in% c('N99999999', 'S99999999', 'W99999999'))

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
         covid_hes, covid_tt, covid_vaccine,
         ethnicity, gor9d, hhsize, work_status, work_status_v1)


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


# Join keys
join_keys <- c('patient_id', 'visit_number')

visit_date <- wide_to_long(cis_wide, 'visit_date', 'visit\\_date\\_\\d+')
result_mk <- wide_to_long(cis_wide, 'result_mk', 'result\\_mk\\_\\d+')

# new ons cis 
visit_num  <- wide_to_long(cis_wide, 'visit_num', 'visit\\_num\\_\\d+')
last_linkage_dt <- wide_to_long(cis_wide, 'last_linkage_dt', 'last\\_linkage\\_dt\\_\\d+')
is_opted_out_of_nhs_data_share <- wide_to_long(cis_wide, 'is_opted_out_of_nhs_data_share', 'is\\_opted\\_out\\_of\\_nhs\\_data\\_share\\_\\d+')
imd_decile_e <- wide_to_long(cis_wide, 'imd_decile_e', 'imd\\_decile\\_e\\_\\d+')
imd_quartile_e <- wide_to_long(cis_wide, 'imd_quartile_e', 'imd\\_quartile\\_e\\_\\d+')
rural_urban <- wide_to_long(cis_wide, 'rural_urban', 'rural\\_urban\\_\\d+')

cis_long <- visit_date %>% 
  left_join(result_mk, by = join_keys) %>% 
  left_join(visit_num, by = join_keys) %>% 
  left_join(last_linkage_dt, by = join_keys) %>% 
  left_join(is_opted_out_of_nhs_data_share, by = join_keys) %>% 
  left_join(imd_decile_e, by = join_keys) %>% 
  left_join(imd_quartile_e, by = join_keys) %>% 
  left_join(rural_urban, by = join_keys)

rm(visit_date, result_mk, visit_num, last_linkage_dt, is_opted_out_of_nhs_data_share, imd_decile_e, imd_quartile_e, rural_urban)
cis_wide <- remove_cols_string(cis_wide, 'visit_date')
cis_wide <- remove_cols_string(cis_wide, 'result_mk')
cis_wide <- remove_cols_string(cis_wide, 'visit_num')
cis_wide <- remove_cols_string(cis_wide, 'last_linkage_dt')
cis_wide <- remove_cols_string(cis_wide, 'is_opted_out_of_nhs_data_share')
cis_wide <- remove_cols_string(cis_wide, 'imd_decile_e')
cis_wide <- remove_cols_string(cis_wide, 'imd_quartile_e')
cis_wide <- remove_cols_string(cis_wide, 'rural_urban')


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


cis_long <- add_new_wide_col(cis_wide, cis_long, 'mental_behavioural_disorder', 'mental\\_behavioural\\_disorder\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'mental_behavioural_disorder')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'other_mood_disorder_hospital_history', 'other\\_mood\\_disorder\\_hospital\\_history\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'other_mood_disorder_hospital_history')


cis_long <- add_new_wide_col(cis_wide, cis_long, 'other_mood_disorder_diagnosis_history', 'other\\_mood\\_disorder\\_diagnosis\\_history\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'other_mood_disorder_diagnosis_history')

cis_long <- add_new_wide_col(cis_wide, cis_long, 'other_mood_disorder_hospital_outcome_date', 'other\\_mood\\_disorder\\_hospital\\_outcome\\_date\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'other_mood_disorder_hospital_outcome_date')

cis_long <- add_new_wide_col(cis_wide, cis_long, 'other_mood_disorder_diagnosis_outcome_date', 'other\\_mood\\_disorder\\_diagnosis\\_outcome\\_date\\_\\d+', join_keys)
cis_wide <- remove_cols_string(cis_wide, 'other_mood_disorder_diagnosis_outcome_date')

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


# Keep only participants who are aged 16 and over
cis_long <- cis_long %>% 
  left_join(cis_cols, by = 'patient_id') %>% 
  filter(age >= 16) %>% 
  select(-visit_number)


# combine work_status & work_status_v1 into 1 column and remove those 2 after 
# code ethnicity breakdowns into 2 categories

cis_long <- cis_long %>% 
  mutate(ethnicity = 
           ifelse(ethnicity == "White-British", "White-British","Any other ethnic group")) %>%
  
  mutate(work_status_new =
  case_when(work_status_v1 == "Employed and currently working" | 
              work_status_v1 == "Self-employed and currently working" ~ "Working",
            
            work_status == "Furloughed (temporarily not working)" & 
              work_status_v1 == "Employed and currently not working" ~"Furloughed",
            
            work_status == "Furloughed (temporarily not working)" & 
              work_status_v1 =="Self-employed and currently not working" ~ "Furloughed",
            
            work_status_v1 == "Looking for paid work and able to start" ~ "Unemployed",
            work_status_v1 == "Not working and not looking for work" ~ "Inactive",
            work_status_v1 == "Retired"	~ "Retired",
           
            work_status_v1 == "Child under 5y not attending child care" | 
              work_status_v1 == "Child under 5y attending child care" | 
              work_status_v1 =="5y and older in full-time education"	~ "Student",
            
            work_status != "Furloughed (temporarily not working)" & 
              work_status_v1 == "Employed and currently not working" ~ "Not working (for other reasons e.g. sick leave)",
            
            work_status != "Furloughed (temporarily not working)" & 
              work_status_v1 =="Self-employed and currently not working" ~ "Not working (for other reasons e.g. sick leave)",
            TRUE ~ 'Unknown')) %>%
  select(-work_status,
         -work_status_v1)

# Change IMD deciles to IMD quitiles 
#currently commented out until we load them through a study definition

#cis_long <- cis_long %>% 
#  mutate(imd = 
#           case_when(imd_decile_E == 1 | imd_decile_E == 2 ~ 1, 
#                     imd_decile_E == 3 | imd_decile_E == 4 ~ 2,
#                     imd_decile_E == 5 | imd_decile_E == 6 ~ 3,
#                     imd_decile_E == 7 | imd_decile_E == 8 ~ 4,
#                     imd_decile_E == 9 | imd_decile_E == 10 ~ 5,
#                     TRUE ~ 'Unknown')) %>% select(-imd_decile_E, -imd_quartile_E)
  
                   
rm(cis_cols, cis_wide)
gc()

# temporary step - check if there are any non English patients
#cis_long %>% count(gor9d)  # will remove this line
# Save out
write_csv(cis_long, 'output/input_cis_long.csv')
