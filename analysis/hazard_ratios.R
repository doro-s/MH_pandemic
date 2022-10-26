library(tidyverse)
library(survival)
library(survminer)
library(data.table)
library(broom)
options(datatable.fread.datatable=FALSE)
#rm(list=ls())
# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

incidence <- fread('output/incidence_t.csv')
prevalence <- fread('output/prevalence_t.csv')

#summary(incidence)

fit_cox_model <- function(df, vars){
  
  vars <- paste(vars, collapse = ' + ')
  
  model_formula <- formula(paste0('Surv(t, mh_outcome) ~ ', vars))
  
  model <- coxph(model_formula, data = df)
  
  return(model)
  
}

#unadjusted model
unadj_incidence <- coxph(Surv(t, mh_outcome) ~ exposed + cluster(patient_id), 
                         data = incidence)

unadj_prevalence <- coxph(Surv(t, mh_outcome) ~ exposed + cluster(patient_id),
                          data = prevalence)

summary(unadj_incidence)
summary(unadj_prevalence)

#min adjusted model (sex and age)
min_adj_inc <- coxph(Surv(t, mh_outcome) ~ exposed + sex + age + cluster(patient_id), 
                     data = incidence)


min_adj_prev <- coxph(Surv(t, mh_outcome) ~ exposed + sex + age + cluster(patient_id),
                      data = prevalence)
summary(min_adj_inc)
summary(min_adj_prev)


# Check model specification - correct covariates? Missing any variables?

inc_vars <- c('exposed',
              'cluster(patient_id)',
              "age",
              "alcohol",
              "obese_binary_flag", 
              "cancer",
              "digestive_disorder",
              "hiv_aids",
              "kidney_disorder",
              "respiratory_disorder",
              "metabolic_disorder",
              "sex",
              "CVD",
              "musculoskeletal",
              "neurological")
              

inc_model <- fit_cox_model(incidence, inc_vars)
summary(inc_model)

#check if those covariates are correct 
prev_vars <- c('exposed',
               'cluster(patient_id)',
               'age', 
               'alcohol', 
               "obese_binary_flag",
               'cancer',
              'hiv_aids',
              'mental_behavioural_disorder',
              'other_mood_disorder_diagnosis_history',
              "other_mood_disorder_hospital_history",
              "cmd_history_hospital",
              "cmd_history",
              "smi_history_hospital",
              "smi_history",
              "self_harm_history_hospital",
              "self_harm_history",
              'kidney_disorder',
              'respiratory_disorder',
              'metabolic_disorder',
              'sex',
              'CVD',
              'musculoskeletal',
              'neurological')

prev_model <- fit_cox_model(prevalence, prev_vars)
summary(prev_model)

# Get outputs into opensafely friendly format e.g. csv file
#function to tidy tables 

function_test <- function(df,col){
  
  df_out <-tidy(df,conf.int=TRUE,exponentiate = TRUE) 
  
  df_out$adjustment <- col
  
  return(df_out)
}

no_inc <- function_test(unadj_incidence, "unadjusted")
min_inc <- function_test(min_adj_inc, "min adjusted")
full_inc <- function_test(inc_model, "fully adjusted")
incidence_cox_hz <- rbind(no_inc, min_inc, full_inc)

no_prev <- function_test(unadj_prevalence, "unadjusted")
min_prev<- function_test(min_adj_prev, "min adjusted")
full_prev <- function_test(prev_model, "fully adjusted")
prevalence_cox_hz <- rbind(no_prev,min_prev,full_prev)


# All scripts need an output for opensafely to work, so save out placeholder

write_csv(incidence_cox_hz, 'output/inc_hr_placeholder.csv')
write_csv(prevalence_cox_hz, 'output/prev_hr_placeholder.csv')

# check Schoenfled residuals to test the proportional-hazards assumption
# check with Dan if we would like to do this with all models (not-adj, min-adj $ full-adj?)
# below is the PH test for fully adjusted model 

#to go through with Dan

#pp<- solve(inc_model, tol = 1e-17)
#test_ph_no_inc <-  cox.zph(unadj_incidence)
#test_ph_min_inc <-  cox.zph(min_adj_inc)
#test_ph_full_inc <-  cox.zph(inc_model)

#test_ph_no_prev <-  cox.zph(unadj_prevalence)
#test_ph_min_prev <-  cox.zph(min_adj_prev)
#test_ph_full_prev <-  cox.zph(prev_model)




#add visual graphs

#ggsurvplot(survfit(inc_model), color = "#2E9FDF",
#ggtheme = theme_minimal())


