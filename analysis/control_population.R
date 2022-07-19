library(tidyverse)
library(lubridate)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

cis <- read_csv('output/input_reconciled.csv')

# Drop non-cis participants (no visit dates)
# Drop anything after 30th September 2021 - end of study date
cis <- cis %>%
  filter(!is.na(visit_date)) %>% 
  filter(visit_date <= '2021-09-30')

# For rows where date is NA (no observation), make arbitrarily large date
cis <- cis %>% 
  mutate(date_of_death = if_else(is.na(date_of_death), as.Date('2100-01-01'), date_of_death),
         covid_hes = if_else(is.na(covid_hes), as.Date('2100-01-01'), covid_hes),
         covid_tt = if_else(is.na(covid_tt), as.Date('2100-01-01'), covid_tt),
         covid_vaccine = if_else(is.na(covid_vaccine), as.Date('2100-01-01'), covid_vaccine),
         first_pos_swab = if_else(is.na(first_pos_swab), as.Date('2100-01-01'), first_pos_swab),
         first_pos_blood = if_else(is.na(first_pos_blood), as.Date('2100-01-01'), first_pos_blood))

# Rearrange rows so that visit dates are monotonically increasing
# Shouldn't be a problem in the real data but will affect pipeline development
cis <- cis %>% 
  arrange(patient_id, visit_date)

# Remove rows where date of death < visit date
# Won't be necessary in actual data
cis <- cis %>% 
  filter(date_of_death > visit_date)

# Add 365 days to most recent visit date per person,
# do not link to anything after this date
cis <- cis %>%
  group_by(patient_id) %>%
  mutate(visit_date_one_year = max(visit_date) + 365,
         eos_date = as.Date('2021-09-30')) %>%
  ungroup()

# Derive all source dates for entire cis data

# Earliest date of +ve test in cis
cis_never_pos <- cis %>%
  group_by(patient_id) %>%
  mutate(ever_tested_pos = ifelse(sum(result_mk) > 0, 1, 0)) %>%
  filter(ever_tested_pos == 0) %>%
  mutate(min_pos_date_cis = as.Date('2100-01-01')) %>%
  ungroup() %>%
  select(patient_id, min_pos_date_cis, eos_date, visit_date_one_year) %>% 
  distinct(.keep_all = TRUE)

cis_pos <- cis %>%
  filter(result_mk == 1) %>%
  group_by(patient_id) %>%
  mutate(min_pos_date_cis = min(visit_date)) %>%
  filter(min_pos_date_cis == visit_date) %>%
  ungroup() %>%
  select(patient_id, min_pos_date_cis, eos_date, visit_date_one_year) %>% 
  distinct(.keep_all = TRUE)

cis_dates <- rbind(cis_never_pos, cis_pos)

# Derive earliest +ve dates per source (T&T, HES)
min_pos_tt <- cis %>%
  group_by(patient_id) %>%
  mutate(min_pos_date_tt = min(covid_tt)) %>%
  filter(min_pos_date_tt == covid_tt) %>%
  ungroup() %>%
  select(patient_id, min_pos_date_tt) %>% 
  distinct(.keep_all = TRUE)

min_pos_hes <- cis %>%
  group_by(patient_id) %>%
  mutate(min_pos_date_hes = min(covid_hes)) %>%
  filter(min_pos_date_hes == covid_hes) %>%
  ungroup() %>%
  select(patient_id, min_pos_date_hes) %>% 
  distinct(.keep_all = TRUE)

# Link T&T to CIS +ve cases
cis_dates <- cis_dates %>%
  left_join(min_pos_tt, by = 'patient_id') %>% 
  left_join(min_pos_hes, by = 'patient_id')

# UNDO ANY JOINS WHERE T&T OR HES HAPPENS AFTER visit_date_one_year
cis_dates <- cis_dates %>%
  mutate(min_pos_date_tt = if_else(min_pos_date_tt > visit_date_one_year, as.Date('2100-01-01'), min_pos_date_tt),
         min_pos_date_hes = if_else(min_pos_date_hes > visit_date_one_year, as.Date('2100-01-01'), min_pos_date_hes))


# Minimum blood test date in CIS as 3rd date column

# First dose date
vacc_cis <- cis %>%
  group_by(patient_id) %>%
  mutate(vacc_date = min(covid_vaccine)) %>%
  filter(vacc_date == covid_vaccine) %>%
  ungroup() %>%
  select(patient_id, vacc_date) %>% 
  distinct(.keep_all = TRUE)

# Earliest positive blood result from result_combined
earliest_pos_blood <- cis %>%
  filter(result_combined == 1) %>% 
  group_by(patient_id) %>%
  mutate(min_pos_result_comb = min(visit_date)) %>%
  filter(min_pos_result_comb == visit_date) %>%
  ungroup() %>%
  select(patient_id, min_pos_result_comb) %>% 
  distinct(.keep_all = TRUE)

# Earliest +ve from self reported swab or blood test
min_pos_blood <- cis %>% 
  group_by(patient_id) %>% 
  mutate(min_self_blood = min(first_pos_blood)) %>% 
  filter(min_self_blood == first_pos_blood) %>% 
  ungroup() %>% 
  select(patient_id, min_self_blood) %>% 
  distinct(.keep_all = TRUE)

min_pos_swab <- cis %>% 
  group_by(patient_id) %>% 
  mutate(min_self_swab = min(first_pos_swab)) %>% 
  filter(min_self_swab == first_pos_swab) %>% 
  ungroup() %>% 
  select(patient_id, min_self_swab) %>% 
  distinct(.keep_all = TRUE)


# Join vaccine dates to earliest +ve blood (and self reported dates)
earliest_pos_blood <- earliest_pos_blood %>%
  left_join(vacc_cis, by = 'patient_id') %>% 
  left_join(min_pos_blood, by = 'patient_id') %>% 
  left_join(min_pos_swab, by = 'patient_id')

# If vacc date <= min_pos_result_comb, set min_pos_result_comb to NA (2100-01-01)
# Same for:
# min_self_blood
# min_self_swab
earliest_pos_blood <- earliest_pos_blood  %>%
  mutate(min_pos_result_comb = if_else(vacc_date < min_pos_result_comb, as.Date('2100-01-01'), min_pos_result_comb)) %>%
  mutate(min_pos_result_comb = if_else(min_self_blood < min_pos_result_comb, as.Date('2100-01-01'), min_pos_result_comb)) %>%
  mutate(min_pos_result_comb = if_else(min_self_swab < min_pos_result_comb, as.Date('2100-01-01'), min_pos_result_comb)) %>%
  select(-vacc_date, -min_self_swab, -min_self_blood)

# Link blood date to +ve cases
cis_dates <- cis_dates %>%
  left_join(earliest_pos_blood, by = 'patient_id')

# UNDO ANY JOINS WHERE BLOOD DATES HAPPENS AFTER visit_date_one_year
cis_dates <- cis_dates %>%
  mutate(min_pos_result_comb = if_else(is.na(min_pos_result_comb), as.Date('2100-01-01'), min_pos_result_comb)) %>%
  mutate(min_pos_result_comb = if_else(min_pos_result_comb > visit_date_one_year, as.Date('2100-01-01'), min_pos_result_comb))


# Derive end of study date

# Minimum of:
# end of study date
# 365 days after last visit date
# date of death
# date permission to link CIS to clinical records was withdraw

eos_dates <- cis %>%
  mutate(row_id = 1:nrow(cis)) %>% 
  group_by(patient_id) %>%
  filter(visit_date_one_year == max(visit_date_one_year)) %>%
  filter(row_id == max(row_id)) %>% 
  ungroup() %>% 
  select(patient_id, eos_date, visit_date_one_year)

# Read in latest deaths file and join to eos_dates
dod <- cis %>%
  mutate(row_id = 1:nrow(cis)) %>% 
  group_by(patient_id) %>%
  filter(date_of_death == min(date_of_death)) %>%
  filter(row_id == max(row_id)) %>% 
  ungroup() %>% 
  select(patient_id, date_of_death)
  
dod <- dod %>%
  filter(date_of_death >= '2020-01-01' & date_of_death <= '2021-09-30')

eos_dates <- eos_dates %>%
  left_join(dod, by = 'patient_id') %>%
  mutate(date_of_death = if_else(is.na(date_of_death), as.Date('2100-01-01'), date_of_death))

# Get minimum date of eos, max(visit) + 365, dod
eos_dates <- eos_dates %>%
  mutate(end_date = if_else(eos_date <= visit_date_one_year, eos_date, visit_date_one_year)) %>%
  mutate(end_date = if_else(end_date <= date_of_death, end_date, date_of_death)) %>%
  select(-eos_date, -visit_date_one_year, -date_of_death)

# Join eos_dates back onto cis_dates
cis_dates <- cis_dates %>%
  left_join(eos_dates, by = 'patient_id')


# Get minimum +ve date for cis_dates
cis_dates <- cis_dates %>%
  mutate(date_positive = if_else(min_pos_date_cis < min_pos_date_tt, min_pos_date_cis, min_pos_date_tt)) %>%
  mutate(date_positive = if_else(date_positive < min_pos_result_comb, date_positive, min_pos_result_comb)) %>%
  mutate(date_positive = if_else(date_positive < min_pos_date_hes, date_positive, min_pos_date_hes)) %>%
  select(patient_id, date_positive, end_date)


# Join back to CIS visit level data
cis <- cis %>% 
  left_join(cis_dates, by = 'patient_id') %>% 
  select(-date_of_death, -first_pos_swab, -first_pos_blood,
         -result_combined, -covid_hes, -covid_tt,
         -covid_vaccine, -eos_date)

# Save data
write_csv(cis, 'output/cis_control.csv')
