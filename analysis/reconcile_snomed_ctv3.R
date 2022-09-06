library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

cis_long <- fread('output/input_cis_long.csv')
                    
cis_long %>% pull(result_mk) %>% table()
cis_long %>% pull(result_combined) %>% table()

cis_long <- cis_long %>% 
  mutate(CVD = ifelse(CVD_snomed == 1 | CVD_ctv3 == 1, 1, 0),
         musculoskeletal = if_else(musculoskeletal_snomed == 1 | musculoskeletal_ctv3 == 1, 1, 0),
         neurological = if_else(neurological_snomed == 1 | neurological_ctv3 == 1, 1, 0)) %>%
  select(-CVD_snomed, -CVD_ctv3,
         -musculoskeletal_snomed, -musculoskeletal_ctv3,
         -neurological_snomed, -neurological_ctv3)

# Create overweight flag
cis_long <- cis_long %>% 
  mutate(overweight = ifelse(bmi >= 25, 1, 0))

# Add a check for date columns where all NAs - convert from logical to date
check_all_na_date <- function(df, col){
  if (sum(is.na(df[col])) == nrow(df)){
    df[col] <- as.IDate('2100-01-01')
  }
  return(df)
}


cis_long <- check_all_na_date(cis_long, 'date_of_death')
cis_long <- check_all_na_date(cis_long, 'covid_hes')
cis_long <- check_all_na_date(cis_long, 'covid_tt')
cis_long <- check_all_na_date(cis_long, 'covid_vaccine')
cis_long <- check_all_na_date(cis_long, 'first_pos_swab')
cis_long <- check_all_na_date(cis_long, 'first_pos_blood')
cis_long <- check_all_na_date(cis_long, 'cmd_outcome_date_hospital')
cis_long <- check_all_na_date(cis_long, 'cmd_outcome_date')
cis_long <- check_all_na_date(cis_long, 'smi_outcome_date_hospital')
cis_long <- check_all_na_date(cis_long, 'smi_outcome_date')
cis_long <- check_all_na_date(cis_long, 'self_harm_outcome_date_hospital')
cis_long <- check_all_na_date(cis_long, 'self_harm_outcome_date')


# For rows where date is NA (no observation), make arbitrarily large date
cis_long <- cis_long %>% 
  mutate(date_of_death = if_else(is.na(date_of_death), as.IDate('2100-01-01'), date_of_death),
         covid_hes = if_else(is.na(covid_hes), as.IDate('2100-01-01'), covid_hes),
         covid_tt = if_else(is.na(covid_tt), as.IDate('2100-01-01'), covid_tt),
         covid_vaccine = if_else(is.na(covid_vaccine), as.IDate('2100-01-01'), covid_vaccine),
         first_pos_swab = if_else(is.na(first_pos_swab), as.IDate('2100-01-01'), first_pos_swab),
         first_pos_blood = if_else(is.na(first_pos_blood), as.IDate('2100-01-01'), first_pos_blood),
         cmd_outcome_date_hospital = if_else(is.na(cmd_outcome_date_hospital), as.IDate('2100-01-01'), cmd_outcome_date_hospital),
         cmd_outcome_date = if_else(is.na(cmd_outcome_date), as.IDate('2100-01-01'), cmd_outcome_date),
         smi_outcome_date_hospital = if_else(is.na(smi_outcome_date_hospital), as.IDate('2100-01-01'), smi_outcome_date_hospital),
         smi_outcome_date = if_else(is.na(smi_outcome_date), as.IDate('2100-01-01'), smi_outcome_date),
         self_harm_outcome_date_hospital = if_else(is.na(self_harm_outcome_date_hospital), as.IDate('2100-01-01'), self_harm_outcome_date_hospital),
         self_harm_outcome_date = if_else(is.na(self_harm_outcome_date), as.IDate('2100-01-01'), self_harm_outcome_date))

print('Number of positive rows (string)')
cis_long %>% filter(result_mk == 'Positive') %>% nrow()


# Drop non-cis participants (no visit dates)
# Drop anything after 30th September 2021 - end of study date
# Fix missing result_mk and result_combined
cis_long <- cis_long %>%
  filter(!is.na(visit_date)) %>% 
  filter(visit_date <= '2021-09-30') %>% 
  mutate(result_mk = ifelse(result_mk == 'Positive', 1, 0),
         result_combined = ifelse(result_combined == 'Positive', 1, 0))

print('Number of positive rows (numeric)')
cis_long %>% filter(result_mk == 1) %>% nrow()

# Rearrange rows so that visit dates are monotonically increasing
# Shouldn't be a problem in the real data but will affect pipeline development
cis_long <- cis_long %>% 
  arrange(patient_id, visit_date)

# Remove rows where date of death < visit date
# Won't be necessary in actual data
cis_long <- cis_long %>% 
  filter(date_of_death > visit_date)

# Add 365 days to most recent visit date per person,
# do not link to anything after this date
cis_long <- cis_long %>%
  group_by(patient_id) %>%
  mutate(visit_date_one_year = max(visit_date) + 365) %>%
  ungroup()

cis_long %>% pull(result_mk) %>% table()

print('number of rows on reconciled data (visit level), visit_date <= 2021-09-30')
nrow(cis_long)


# Perform naive counts on outcome variables
print('cmd outcome')
cis_long %>% mutate(flag = ifelse(cmd_outcome_date == '2100-01-01', 0, 1)) %>% pull(flag) %>% table()
print('cmd outcome hospital')
cis_long %>% mutate(flag = ifelse(cmd_outcome_date_hospital == '2100-01-01', 0, 1)) %>% pull(flag) %>% table()
print('smi outcome')
cis_long %>% mutate(flag = ifelse(smi_outcome_date == '2100-01-01', 0, 1)) %>% pull(flag) %>% table()
print('smi outcome hospital')
cis_long %>% mutate(flag = ifelse(smi_outcome_date_hospital == '2100-01-01', 0, 1)) %>% pull(flag) %>% table()
print('self harm outcome')
cis_long %>% mutate(flag = ifelse(self_harm_outcome_date == '2100-01-01', 0, 1)) %>% pull(flag) %>% table()
print('self harm outcome hospital')
cis_long %>% mutate(flag = ifelse(self_harm_outcome_date_hospital == '2100-01-01', 0, 1)) %>% pull(flag) %>% table()


# TODO - check bmi mean, min, max

# Save data
write_csv(cis_long, 'output/input_reconciled.csv')
