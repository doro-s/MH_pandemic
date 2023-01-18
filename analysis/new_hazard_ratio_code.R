###########################################################################
#Purpose: 1. Calculate Cox proportional hazard ratios for all models
#             incidence: no adjustemnt, min adjustment and full
#             prevalence: no adjustemnt, min adjustment and full
# 2. Test the assumption of.C.P.HR - Schoenfeld residuals
# 3. Plot the cumulative incidence survival curves (with Stabilized Inverse
#     Probability Weights (SIPWs) for the min and full adj models)
# 4. Save all outputs into OpenSAFELY friendly format 
###########################################################################
library(tidyverse)
library(survival)
library(survminer)
library(data.table)
library(broom)
library(splines)
library(gridExtra)
library(here)
library(ggfortify)

options(datatable.fread.datatable=FALSE)

# rm(list=ls())
# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

###########################################################################
# Load data 
###########################################################################

incidence <- fread('output/incidence_t.csv')
prevalence <- fread('output/prevalence_t.csv')

###########################################################################
# Load functions 
###########################################################################

source(here("analysis","functions","inverse_prob_weights_incidence_full.R"))
source(here("analysis","functions","inverse_prob_weights_min.R"))
source(here("analysis","functions","inverse_prob_weights_prevalence_full.R"))
source(here("analysis","functions","schoenfeld_residuals_function.R"))
source(here("analysis","functions","fit_cox_model_fully_adjusted.R"))
source(here("analysis","functions","cumulative_incidence_graph_function.R"))

#source('D:/MH_pandemic/analysis/functions/inverse_prob_weights_incidence_full.R')


# List variables for incidence and prevalence models
inc_vars <- c('exposed',
              'cluster(patient_id)',
              "ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9)))",
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

#check if those covariates are correct 
prev_vars <- c("exposed",
               "cluster(patient_id)",
               "ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9)))", 
               "alcohol", 
               "obese_binary_flag",
               "cancer",
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
               "kidney_disorder",
               "respiratory_disorder",
               "metabolic_disorder",
               "sex",
               "CVD",
               "musculoskeletal",
               "neurological")

###########################################################################
# Run Cox Proportional Hazard Ratio
#   This section of the code runs Cox Prop. HR for each model (unadjusted, 
#    min-adjusted and fully adjusted) and saves outputs as csv
###########################################################################

## Incidence models

unadj_incidence <- coxph(Surv(t, mh_outcome) ~ exposed + cluster(patient_id), 
                         data = incidence)

min_adj_inc <- coxph(Surv(t, mh_outcome) ~ exposed + sex + age + cluster(patient_id), 
                     data = incidence)

inc_model <- fit_cox_model(incidence, inc_vars)


## Prevalence models

unadj_prevalence <- coxph(Surv(t, mh_outcome) ~ exposed + cluster(patient_id),
                          data = prevalence)
min_adj_prev <- coxph(Surv(t, mh_outcome) ~ exposed + sex + age + cluster(patient_id),
                      data = prevalence)

prev_model <- fit_cox_model(prevalence, prev_vars)


## Function to tidy tables and save outputs into opensafely friendly format e.g. csv file

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

## SAVE
write_csv(incidence_cox_hz, 'output/1_cox_hazard_ratio_incidence_table.csv')
write_csv(prevalence_cox_hz, 'output/2_cox_hazard_ratio_prevalence.csv')

###########################################################################
#               Survival Curves - logistic regression for weights
# 
###########################################################################

### Logistic regression to calculate Stabilized Inverse Probability Weights

# incidence - min adj
incidence_min_with_weights <- inverse_prob_weights_min(incidence)

# incidence - full adj
incidence_full_with_weights <-inverse_prob_weights_incidence(incidence)

# prevalence - min adj
prevalence_min_with_weights <- inverse_prob_weights_min(prevalence)

# prevalence - full adj
prevalence_full_with_weights <-inverse_prob_weights_prevalence(prevalence)


###########################################################################
#    Plot survival fit models-unadjusted models don't need Cox.P.HR
#  
###########################################################################
##UNADJUSTED
# Incidence
cumulative_unadj_inc <- autoplot(survfit(Surv(t, mh_outcome) ~ exposed + cluster(patient_id), 
                                         data = incidence), 
                                 fun = function(x) 1-x, 
                                 censor = FALSE,
                                 conf.int = TRUE,
                                 xlab = "Time", 
                                 ylab = "Cumulative incidence")

ggsave("output/1_survfit_plot_incidence_noadj.jpg",cumulative_unadj_inc)

# Prevalence
cumulative_unadj_prev <- autoplot(survfit(Surv(t, mh_outcome) ~ exposed + cluster(patient_id), 
                                         data = prevalence), 
                                 fun = function(x) 1-x, 
                                 censor = FALSE,
                                 conf.int = TRUE,
                                 xlab = "Time", 
                                 ylab = "Cumulative incidence")

ggsave("output/2_survfit_plot_prevalence_noadj.jpg",cumulative_unadj_prev)

# SAVE min and fully adjusted models
cumulative_incidence_plot(data = incidence_min_with_weights, 
                          name = "3_survfit_plot_incidence_min")

cumulative_incidence_plot(data = prevalence_min_with_weights, 
                          name = "4_survfit_plot_prevalence_min")

cumulative_incidence_plot(data = incidence_full_with_weights, 
                          name = "5_survfit_plot_incidence_full")

cumulative_incidence_plot(data = prevalence_full_with_weights, 
                          name = "6_survfit_plot_prevalence_full")

###############################################################################
#   Check Schoenfeld residuals to test the proportional-hazards assumption
#
###############################################################################


schoenfeld_residuals_function(df = unadj_incidence, 
                              model_name = "inc_no_adj")

schoenfeld_residuals_function(df = min_adj_inc, 
                              model_name = "inc_min_adj")

schoenfeld_residuals_function(df = inc_model, 
                              model_name = "inc_full_adj")

schoenfeld_residuals_function(df = unadj_prevalence, 
                              model_name = "prev_no_adj")

schoenfeld_residuals_function(df = min_adj_prev, 
                              model_name = "prev_min_adj")

schoenfeld_residuals_function(df = prev_model, 
                              model_name = "prev_full_adj")

