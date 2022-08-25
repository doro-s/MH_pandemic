library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

incidence <- fread('output/incidence_group.csv')
prevalence <- fread('output/prevalence_group.csv')
exac <- fread('output/exacerbated_group.csv')


count_outcomes <- function(df, variables){
  
  for (v in variables){
    print(v)
    print(table(df[[v]]))
    cat('\n')
  }
}


# Count outcomes for feasibility of analysis - do outcomes need to be grouped?
count_outcomes(incidence, c('cmd_outcome', 'cmd_outcome_hospital',
                            'smi_outcome', 'smi_outcome_hospital',
                            'self_harm_outcome', 'self_harm_outcome_hospital'))

count_outcomes(prevalence, c('cmd_outcome', 'cmd_outcome_hospital',
                             'smi_outcome', 'smi_outcome_hospital',
                             'self_harm_outcome', 'self_harm_outcome_hospital'))

count_outcomes(exac, c('cmd_outcome', 'cmd_outcome_hospital',
                       'smi_outcome', 'smi_outcome_hospital',
                       'self_harm_outcome', 'self_harm_outcome_hospital'))


# Derive t for incidence of every individual outcome
derive_t <- function(df){
  
  df <- df %>% 
    mutate(cmd_outcome_t = ifelse(cmd_outcome_date == '2100-01-01',
                                  end_date - visit_date, 
                                  cmd_outcome_date - visit_date),
           cmd_outcome_hospital_t = ifelse(cmd_outcome_date_hospital == '2100-01-01',
                                           end_date - visit_date, 
                                           cmd_outcome_date_hospital - visit_date),
           smi_outcome_t = ifelse(smi_outcome_date == '2100-01-01',
                                  end_date - visit_date, 
                                  smi_outcome_date - visit_date),
           smi_outcome_hospital_t = ifelse(smi_outcome_date_hospital == '2100-01-01',
                                           end_date - visit_date, 
                                           smi_outcome_date_hospital - visit_date),
           self_harm_outcome_t = ifelse(self_harm_outcome_date == '2100-01-01',
                                        end_date - visit_date, 
                                        self_harm_outcome_date - visit_date),
           self_harm_outcome_hospital_t = ifelse(self_harm_outcome_date_hospital == '2100-01-01',
                                                 end_date - visit_date, 
                                                 self_harm_outcome_date_hospital - visit_date))
  
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
exac <- derive_t(exac)

cumulative_inc(incidence, 'cmd_outcome_t')
cumulative_inc(incidence, 'cmd_outcome_hospital_t')
cumulative_inc(incidence, 'smi_outcome_t')
cumulative_inc(incidence, 'smi_outcome_hospital_t')
cumulative_inc(incidence, 'self_harm_outcome_t')
cumulative_inc(incidence, 'self_harm_outcome_hospital_t')

cumulative_inc(prevalence, 'cmd_outcome_t')
cumulative_inc(prevalence, 'cmd_outcome_hospital_t')
cumulative_inc(prevalence, 'smi_outcome_t')
cumulative_inc(prevalence, 'smi_outcome_hospital_t')
cumulative_inc(prevalence, 'self_harm_outcome_t')
cumulative_inc(prevalence, 'self_harm_outcome_hospital_t')

cumulative_inc(exac, 'cmd_outcome_t')
cumulative_inc(exac, 'cmd_outcome_hospital_t')
cumulative_inc(exac, 'smi_outcome_t')
cumulative_inc(exac, 'smi_outcome_hospital_t')
cumulative_inc(exac, 'self_harm_outcome_t')
cumulative_inc(exac, 'self_harm_outcome_hospital_t')

write_csv(data.frame(1), 'output/placeholder.csv')
