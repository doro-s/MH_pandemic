library(tidyverse)

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
         covid_vaccine = if_else(is.na(covid_vaccine), as.Date('2100-01-01'), covid_vaccine))

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
  mutate(visit_date_one_year = max(visit_date) + 365) %>%
  ungroup()

# Derive the index date - earliest date of +ve test
exposed <- cis %>%
  filter(result_mk == 1) %>%
  group_by(patient_id) %>%
  mutate(min_pos_date_cis = min(visit_date)) %>%
  filter(min_pos_date_cis == visit_date) %>%
  ungroup()

min_pos_tt <- cis %>%
  filter(covid_tt != '2100-01-01') %>%
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
  mutate(min_pos_date_tt = if_else(is.na(min_pos_date_tt), as.Date('2100-01-01'), min_pos_date_tt)) %>%
  mutate(min_pos_date_tt = if_else(min_pos_date_tt > visit_date_one_year, as.Date('2100-01-01'), min_pos_date_tt)) %>% 
  # Get minimum of T&T and CIS
  mutate(date_positive = pmin(min_pos_date_cis, min_pos_date_tt)) %>% 
  select(-min_pos_date_cis, -min_pos_date_tt)

# Derive end of study date for exposed
exposed <- exposed %>%
  mutate(eos_date = as.Date('2021-09-30'))

# Get deaths and join to eos_dates
dod <- cis %>% 
  filter(date_of_death != '2100-01-01') %>%
  group_by(patient_id) %>%
  mutate(dod = min(date_of_death)) %>%
  filter(dod == date_of_death) %>% 
  ungroup() %>%
  select(patient_id, dod) %>% 
  distinct(.keep_all = TRUE)

dod <- dod %>% 
  filter(dod >= '2020-01-01' & dod <= '2021-09-30')

exposed <- exposed %>%
  left_join(dod, by = 'patient_id') %>%
  mutate(dod = if_else(is.na(dod), as.Date('2100-01-01'), dod))

# Undo any link to dod where after visit date one year #########################

# Get minimum date of eos, max(visit) + 365, dod
exposed <- exposed %>%
  mutate(end_date = if_else(eos_date <= visit_date_one_year, eos_date, visit_date_one_year)) %>%
  mutate(end_date = if_else(end_date <= dod, end_date, dod)) %>%
  select(-eos_date, -visit_date_one_year, -dod,
         -first_pos_swab, -first_pos_blood, -result_combined,
         -covid_hes, -covid_tt, -covid_vaccine,
         -date_of_death)


# Save index dates for exposed population
write_csv(exposed, 'output/cis_exposed.csv')
