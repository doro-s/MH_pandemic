library(tidyverse)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

cis_long <- read_csv('../output/input_cis_long.csv',
                     col_types = cols(
                       patient_id = col_double(),
                       visit_date = col_date(format = ""),
                       result_mk = col_character(),
                       result_combined = col_double(),
                       age = col_double(),
                       alcohol = col_double(),
                       obesity = col_double(),
                       bmi = col_double(),
                       cancer = col_double(),
                       CVD_ctv3 = col_double(),
                       CVD_snomed = col_double(),
                       digestive_disorder = col_double(),
                       hiv_aids = col_double(),
                       mental_disorder_history = col_double(),
                       mental_disorder_outcome_date = col_date(format = ""),
                       mental_disorder_hospital = col_double(),
                       metabolic_disorder = col_double(),
                       musculoskeletal_ctv3 = col_double(),
                       musculoskeletal_snomed = col_double(),
                       neurological_ctv3 = col_double(),
                       neurological_snomed = col_double(),
                       kidney_disorder = col_double(),
                       respiratory_disorder = col_double(),
                       date_of_death = col_date(format = ""),
                       first_pos_swab = col_date(format = ""),
                       first_pos_blood = col_date(format = ""),
                       covid_hes = col_date(format = ""),
                       covid_tt = col_date(format = ""),
                       covid_vaccine = col_date(format = "")))

cis_long <- cis_long %>% 
  mutate(CVD = ifelse(CVD_snomed == 1 | CVD_ctv3 == 1, 1, 0),
         musculoskeletal = ifelse(musculoskeletal_snomed == 1 | musculoskeletal_ctv3 == 1, 1, 0),
         neurological = if_else(neurological_snomed == 1 | neurological_ctv3 == 1, 1, 0)) %>%
  select(-CVD_snomed, -CVD_ctv3,
         -musculoskeletal_snomed, -musculoskeletal_ctv3,
         -neurological_snomed, -neurological_ctv3)

# Add a check for date columns where all NAs - convert from logical to date
if (sum(is.na(cis_long$date_of_death)) == nrow(cis_long)){
  cis_long <- cis_long %>% 
    mutate(date_of_death = as.Date('2100-01-01'))
}

if (sum(is.na(cis_long$covid_hes)) == nrow(cis_long)){
  cis_long <- cis_long %>% 
    mutate(covid_hes = as.Date('2100-01-01'))
}

if (sum(is.na(cis_long$covid_tt)) == nrow(cis_long)){
  cis_long <- cis_long %>% 
    mutate(covid_tt = as.Date('2100-01-01'))
}

if (sum(is.na(cis_long$covid_vaccine)) == nrow(cis_long)){
  cis_long <- cis_long %>% 
    mutate(covid_vaccine = as.Date('2100-01-01'))
}

if (sum(is.na(cis_long$first_pos_swab)) == nrow(cis_long)){
  cis_long <- cis_long %>% 
    mutate(first_pos_swab = as.Date('2100-01-01'))
}

if (sum(is.na(cis_long$first_pos_blood)) == nrow(cis_long)){
  cis_long <- cis_long %>% 
    mutate(first_pos_blood = as.Date('2100-01-01'))
}

if (sum(is.na(cis_long$mental_disorder_outcome_date)) == nrow(cis_long)){
  cis_long <- cis_long %>% 
    mutate(mental_disorder_outcome_date = as.Date('2100-01-01'))
}

# For rows where date is NA (no observation), make arbitrarily large date
cis_long <- cis_long %>% 
  mutate(date_of_death = if_else(is.na(date_of_death), as.Date('2100-01-01'), date_of_death),
         covid_hes = if_else(is.na(covid_hes), as.Date('2100-01-01'), covid_hes),
         covid_tt = if_else(is.na(covid_tt), as.Date('2100-01-01'), covid_tt),
         covid_vaccine = if_else(is.na(covid_vaccine), as.Date('2100-01-01'), covid_vaccine),
         first_pos_swab = if_else(is.na(first_pos_swab), as.Date('2100-01-01'), first_pos_swab),
         first_pos_blood = if_else(is.na(first_pos_blood), as.Date('2100-01-01'), first_pos_blood),
         mental_disorder_outcome_date = if_else(is.na(mental_disorder_outcome_date), as.Date('2100-01-01'), mental_disorder_outcome_date))

# Drop non-cis participants (no visit dates)
# Drop anything after 30th September 2021 - end of study date
# Fix missing result_mk and result_combined
cis_long <- cis_long %>%
  filter(!is.na(visit_date)) %>% 
  filter(visit_date <= '2021-09-30') %>% 
  mutate(result_mk = as.numeric(result_mk)) %>% 
  mutate(result_mk = ifelse(is.na(result_mk) | result_mk > 1, 0, result_mk),
         result_combined = ifelse(is.na(result_combined) | result_combined > 1, 0, result_combined))

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

# Save data
write_csv(cis_long, 'output/input_reconciled.csv')
