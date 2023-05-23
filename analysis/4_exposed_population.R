###########################################################################
#Purpose: Derive the exposed population for the incidence and prevalence 
#         groups
###########################################################################
library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# End of study period date 
eos_date <- as.IDate('2022-10-19')

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

# Load data 
cis <- fread('output/input_reconciled.csv')

cat(dim(cis))
cat('\n')

cat(str(cis))
cat('\n')

# Derive the index date from Covid Infection Survey - earliest date of +ve test
# filter only Positive results (1) through variable results_mk
# create new variable = minimum date of positive CIS  
exposed <- cis %>%
  filter(result_mk == 1) %>%
  group_by(patient_id) %>%
  mutate(min_pos_date_cis = min(visit_date)) %>%
  filter(min_pos_date_cis == visit_date) %>%
  ungroup()

# Same but for Test & Trace: Get earliest positive date from test and trace
min_pos_tt <- exposed %>%
  group_by(patient_id) %>%
  mutate(min_pos_date_tt = min(covid_tt)) %>%
  filter(min_pos_date_tt == covid_tt) %>%
  ungroup() %>%
  select(patient_id, min_pos_date_tt) %>% 
  distinct(.keep_all = TRUE)

# Same but for Hospital Episodes: Get earliest positive date from HES data
min_pos_hes <- exposed %>%
  group_by(patient_id) %>%
  mutate(min_pos_date_hes = min(covid_hes)) %>%
  filter(min_pos_date_hes == covid_hes) %>%
  ungroup() %>%
  select(patient_id, min_pos_date_hes) %>% 
  distinct(.keep_all = TRUE)

################################################################################
#               DERIVE INDEX DATE FOR THE EXPOSED (date_positive)
# (index date is the earliest positive covid result from either CIS, T&T or HES)
# 
# Link Test&Trace and HES to Covid Infection Survey exposed population and 
# derive earliest date from across all sources
################################################################################
exposed <- exposed %>%
  left_join(min_pos_tt, by = 'patient_id') %>%
  left_join(min_pos_hes, by = 'patient_id') %>%
  
  # In case there are missing dates in HES and T&T after joining, add fake date if not keep same date
  mutate(min_pos_date_tt = ifelse(is.na(min_pos_date_tt), as.IDate('2100-01-01'), min_pos_date_tt)) %>%
  mutate(min_pos_date_hes = ifelse(is.na(min_pos_date_hes), as.IDate('2100-01-01'), min_pos_date_hes)) %>%
  
  # if last_linkage_date is NA then place a really high date, if it's not NA keep that date
  mutate(last_linkage_dt = ifelse(is.na(last_linkage_dt), as.IDate('2100-01-01'), last_linkage_dt)) %>% 
  
  # Undo joins where T&T date is more than 1 year after the most recent visit date
  mutate(min_pos_date_tt = ifelse(min_pos_date_tt > visit_date_one_year, as.IDate('2100-01-01'),min_pos_date_tt),
         min_pos_date_hes = ifelse(min_pos_date_hes > visit_date_one_year, as.IDate('2100-01-01'), min_pos_date_hes)) %>% 
  
  # create new column with the index_date 
  
  # select date of the earliest positive test across all sources
  mutate(temp_index =    pmin(min_pos_date_hes, min_pos_date_tt)) %>% 
  mutate(date_positive = pmin(temp_index, min_pos_date_cis)) %>%   
  mutate(date_positive = as.IDate(date_positive)) %>%
  #remove the temporary variables
  select(-temp_index,
         -min_pos_date_cis, 
         -min_pos_date_tt, 
         -min_pos_date_hes)

################################################################################
#               DERIVE END DATE FOR EACH PATIENT IN THE EXPOSED
#
# this will either be End of Study, date-of-death, Visit-1 year 
#  or last-linkage-date
################################################################################

# Derive end of study date for exposed table
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

#filter for deaths in the study period
dod <- dod %>% 
  filter(dod >= '2020-01-24' & dod <= eos_date)

exposed <- exposed %>%
  left_join(dod, by = 'patient_id') %>%
  mutate(dod = ifelse(is.na(dod), as.IDate('2100-01-01'), dod))


# Get minimum date of eos, max(visit) + 365, dod or last_linkage_dt

exposed <- exposed %>%
  mutate(end_date = pmin(eos_date, visit_date_one_year)) %>%
  mutate(end_date = pmin(end_date, last_linkage_dt)) %>%
  mutate(end_date = pmin(end_date, dod)) %>%
  select(-eos_date, 
         -visit_date_one_year, 
         -dod,
         -first_pos_swab, 
         -first_pos_blood, 
         -result_combined,
         -covid_hes, 
         -covid_tt, 
         -covid_vaccine,
         -date_of_death)

print('Size of exposed population')
nrow(exposed)

print('Summary of index dates (date_positive')
summary(exposed$date_positive)

print('Summary of end_dates')
summary(exposed$end_date)

# Save index dates for exposed population
write_csv(exposed, 'output/cis_exposed.csv')

