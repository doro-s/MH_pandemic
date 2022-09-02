library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

incidence <- fread('../output/adjusted_incidence_group.csv')
prevalence <- fread('../output/adjusted_prevalence_group.csv')

eos_date <- as.IDate('2021-09-30')

# Derive t for outcomes
derive_t <- function(df){
  
  df <- df %>% 
    mutate(min_outcome_date_cmd = cmd_outcome_date,
           min_outcome_date_other = pmin(cmd_outcome_date_hospital,
                                         smi_outcome_date, smi_outcome_date_hospital,
                                         self_harm_outcome_date, self_harm_outcome_date_hospital)) %>% 
    mutate(min_outcome_date = fifelse(min_outcome_date == '2100-01-01', eos_date, min_outcome_date)) %>% 
    mutate(t = fifelse(min_outcome_date == '2021-09-30', 
                       end_date - visit_date, 
                       min_outcome_date - visit_date))
  
  return(df)
}


# Calculate cumulative incidence
cumulative_inc <- function(df, v){
  print(v)
  
  cu_in <- df %>% 
    group_by(!!sym(v)) %>% 
    summarise(incidence = n()) %>% 
    arrange(v)
  
  cu_sum <- cumsum(cu_in$incidence)
  
  cu_in <- cu_in %>% 
    mutate(cumulative_incidence = cu_sum)
  
  return(cu_in)
}


incidence <- derive_t(incidence)
prevalence <- derive_t(prevalence)

cumulative_inc(incidence, 'cmd_outcome_t')
cumulative_inc(incidence, 'cmd_outcome_hospital_t')

cumulative_inc(prevalence, 'cmd_outcome_t')
cumulative_inc(prevalence, 'cmd_outcome_hospital_t')
cumulative_inc(prevalence, 'smi_outcome_t')
cumulative_inc(prevalence, 'smi_outcome_hospital_t')
cumulative_inc(prevalence, 'self_harm_outcome_t')
cumulative_inc(prevalence, 'self_harm_outcome_hospital_t')

write_csv(data.frame(1), 'output/placeholder.csv')
