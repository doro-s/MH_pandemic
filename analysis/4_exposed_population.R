library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

eos_date <- as.IDate('2022-10-19')

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

cis <- fread('output/input_reconciled.csv')

cat(dim(cis))
cat('\n')

cat(str(cis))
cat('\n')

# Derive the index date - earliest date of +ve test
exposed <- cis %>%
  filter(result_mk == 1) %>%
  group_by(patient_id) %>%
  mutate(min_pos_date_cis = min(visit_date)) %>%
  filter(min_pos_date_cis == visit_date) %>%
  ungroup()

# Get earliest positive date from test and trace
min_pos_tt <- exposed %>%
  group_by(patient_id) %>%
  mutate(min_pos_date_tt = min(covid_tt)) %>%
  filter(min_pos_date_tt == covid_tt) %>%
  ungroup() %>%
  select(patient_id, min_pos_date_tt) %>% 
  distinct(.keep_all = TRUE)

# Link T&T to CIS +ve cases and derive earliest +ve date
exposed <- exposed %>%
  left_join(min_pos_tt, by = 'patient_id') %>%
  # Undo any joins where min T&T is more than 1 year after most recent visit date
  # or non-matches
  mutate(min_pos_date_tt = ifelse(is.na(min_pos_date_tt), as.IDate('2100-01-01'), min_pos_date_tt)) %>%
  mutate(min_pos_date_tt = ifelse(min_pos_date_tt > visit_date_one_year, as.IDate('2100-01-01'), min_pos_date_tt)) %>% 
  # Get minimum of T&T and CIS
  mutate(date_positive = pmin(min_pos_date_cis, min_pos_date_tt)) %>% 
  select(-min_pos_date_cis, -min_pos_date_tt)

# Derive end of study date for exposed
exposed <- exposed %>%
  mutate(eos_date = eos_date)

# Get deaths and join to eos_dates
dod <- cis %>% 
  group_by(patient_id) %>%
  mutate(dod = min(date_of_death)) %>%
  filter(dod == date_of_death) %>% 
  ungroup() %>%
  select(patient_id, dod) %>% 
  distinct(.keep_all = TRUE)

dod <- dod %>% 
  filter(dod >= '2020-01-01' & dod <= eos_date)

exposed <- exposed %>%
  left_join(dod, by = 'patient_id') %>%
  mutate(dod = ifelse(is.na(dod), as.IDate('2100-01-01'), dod))

# Undo any link to dod where after visit date one year #########################

# Get minimum date of eos, max(visit) + 365, dod
# & keep last_linkage_date if it's less that visit_date_one_year or eos
exposed <- exposed %>%
  mutate(end_date = pmin(eos_date, visit_date_one_year)) %>%
  #mutate(end_date = pmin(end_date, last_linkage_dt)) %>%
  mutate(end_date = pmin(end_date, dod)) %>%
  select(-eos_date, -visit_date_one_year, -dod,
         -first_pos_swab, -first_pos_blood, -result_combined,
         -covid_hes, -covid_tt, -covid_vaccine,
         -date_of_death)

print('Size of exposed population')
nrow(exposed)

# Save index dates for exposed population
write_csv(exposed, 'output/cis_exposed.csv')
