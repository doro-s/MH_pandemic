library(tidyverse)
library(survival)
library(data.table)
options(datatable.fread.datatable=FALSE)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('../')

incidence <- fread('output/incidence_t.csv')
prevalence <- fread('output/prevalence_t.csv')

fit_cox_model <- function(df, vars){
  
  vars <- paste(vars, collapse = ' + ')
  
  model_formula <- formula(paste0('Surv(t, mh_outcome) ~ ', vars))
  
  model <- coxph(model_formula, data = df)
  
  return(model)
  
}


inc_vars <- c('age', 'alcohol', 'obesity',
              'bmi', 'cancer', 'hiv_aids',
              'mental_behavioural_disorder',
              'other_mood_disorder_diagnosis_history',
              'kidney_disorder', 'respiratory_disorder',
              'metabolic_disorder', 'sex', 'CVD',
              'musculoskeletal', 'neurological')

inc_model <- fit_cox_model(incidence, inc_vars)
summary(inc_model)

prev_vars <- c('age', 'alcohol', 'obesity',
              'bmi', 'cancer', 'hiv_aids',
              'mental_behavioural_disorder',
              'other_mood_disorder_diagnosis_history',
              'kidney_disorder', 'respiratory_disorder',
              'metabolic_disorder', 'sex', 'CVD',
              'musculoskeletal', 'neurological')

prev_model <- fit_cox_model(incidence, inc_vars)
summary(prev_model)
