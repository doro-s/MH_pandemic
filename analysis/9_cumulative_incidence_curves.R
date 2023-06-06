library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')


# end of study period
eos_date <- as.IDate('2022-10-19')


# Load data 
incidence <- fread('output/adjusted_incidence_group.csv')
prevalence <- fread('output/adjusted_prevalence_group.csv')

source('analysis/functions/covid_vaccination_status_variable.R')

###############################################################################
#                 Create new variable with index_date
# index date for the exposed should be the date_positive (earliest date of 
#   positive covid tests from CIS, HES or T&T)
#
# index date for the control should be visit_date (of the matched exposed as
#  we choose people who haven't been infected 14+ or - of visit date)
###############################################################################

incidence <- incidence %>%
  mutate(index_date = ifelse(exposed == 1, date_positive, visit_date)) %>%
  mutate(index_date = as.IDate(index_date))

prevalence <- prevalence %>%
  mutate(index_date = ifelse(exposed == 1, date_positive, visit_date))%>%
  mutate(index_date = as.IDate(index_date))

# Apply the covid_vaccination status function ################################

incidence <- covid_vaccine_function(data = incidence)
prevalence <- covid_vaccine_function(data = prevalence)


# Derive t for outcomes
derive_t <- function(df, drop_negative = TRUE){
  
  df <- df %>% 
    mutate(min_outcome_date_mh = pmin(cmd_outcome_date, cmd_outcome_date_hospital,
                                      smi_outcome_date, smi_outcome_date_hospital,
                                      self_harm_outcome_date, self_harm_outcome_date_hospital,
                                      other_mood_disorder_diagnosis_outcome_date, 
                                      other_mood_disorder_hospital_outcome_date)) %>% 
    mutate(min_outcome_date_mh = fifelse(min_outcome_date_mh == '2100-01-01', eos_date, min_outcome_date_mh)) %>% 
    mutate(t = fifelse(min_outcome_date_mh == eos_date, 
                           end_date - index_date, 
                           min_outcome_date_mh - index_date)) %>% 
    select(-min_outcome_date_mh)

    if (drop_negative) {
    df  <- filter(df, t > 0)  
    }
  
  return(df)
}


# Calculate cumulative incidence
cumulative_inc <- function(df, v){
  
  N <- nrow(df)
  
  cu_in <- df %>% 
    group_by(!!sym(v)) %>% 
    summarise(incidence = n()) %>% 
    arrange(v)
  
  cu_sum <- cumsum(cu_in$incidence)
  
  cu_in <- cu_in %>% 
    mutate(cumulative_incidence = cu_sum,
           surv = (N - cumulative_incidence)/N)
  
  return(cu_in)
}


incidence <- derive_t(incidence)
prevalence <- derive_t(prevalence)

# Rename English regions function 
rename_regions_function<- function(df){
  df <- df %>% 
    mutate(region = case_when(
      gor9d == 'E12000001' ~ 'North East', 
      gor9d == 'E12000002' ~ 'North West',
      gor9d == 'E12000003' ~ 'Yorkshire and The Humber',
      gor9d == 'E12000004' ~ 'East Midlands',
      gor9d == 'E12000005' ~ 'West Midlands',
      gor9d == 'E12000006' ~ 'East of England',
      gor9d == 'E12000007' ~ 'London',
      gor9d == 'E12000008' ~ 'South East',
      gor9d == 'E12000009' ~ 'South West',
      TRUE ~ "Missing")) 
  
  return(df)
}

# Create age bands 
age_bands_function <- function(df){
  df <- df %>% mutate(
    #create categories
    age_groups = case_when(
      age >= 16 & age <= 24 ~ "16 to 24",
      age >= 25 & age <= 34 ~ "25 to 34",
      age >= 35 & age <= 49 ~ "35 to 49",
      age >= 50 & age <= 69 ~ "50 to 69",
      age >= 70 ~ "70 and over"))
  return(df)
}


# apply the region renaming function
incidence <- rename_regions_function(incidence)
prevalence <- rename_regions_function(prevalence)

# apply age band function &
# remove the old region column (gor9d)
incidence <- age_bands_function(incidence) %>% select(-gor9d)
prevalence <- age_bands_function(prevalence) %>% select(-gor9d)

# Save out data with t derived
write_csv(incidence, 'output/incidence_t.csv')
write_csv(prevalence, 'output/prevalence_t.csv')

inc_ci_cmd <- cumulative_inc(incidence, 't')
prev_ci_other <- cumulative_inc(prevalence, 't')


plot_surv <- function(df, x, y, title){
  
  ggplot(df) +
    geom_line(aes_string(x = x, y = y)) +
    ggtitle(title) +
    theme(plot.title = element_text(hjust = 0.5))
  
}


jpeg('output/incidence_surv.jpg', res = 300, width = 12, height = 10, units = 'cm')
plot_surv(inc_ci_cmd, 't', 'surv', 'Incidence')
dev.off()

jpeg('output/prevalence_surv.jpg', res = 300, width = 12, height = 10, units = 'cm')
plot_surv(prev_ci_other, 't', 'surv', 'Prevalence')
dev.off()
