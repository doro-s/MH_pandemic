library(tidyverse)
library(data.table)
library(ggfortify)
library(here)
library(survival)
library(survminer)
library(broom)
library(splines)
library(gridExtra)


rm(list=ls())

options(datatable.fread.datatable=FALSE)
#setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
#setwd('../')

###########################################################################
# Load data 
###########################################################################

incidence <- fread('output/incidence_t.csv')
prevalence <- fread('output/prevalence_t.csv')

###########################################################################
# Load functions 
###########################################################################

#source("analysis/functions/inverse_prob_weights_incidence_full.R")
#source("analysis/functions/inverse_prob_weights_min.R")
#source("analysis/functions/inverse_prob_weights_prevalence_full.R")
#source("analysis/functions/schoenfeld_residuals_function.R")
#source("analysis/functions/fit_cox_model_fully_adjusted.R")
#source("analysis/functions/cumulative_incidence_graph_function.R")



# List variables for incidence and prevalence models
vars <- c("exposed",
          "cluster(patient_id)",
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
          "ethnicity",
          "region",
          "hhsize",
          "CVD",
          "musculoskeletal",
          "neurological",
          "mental_behavioural_disorder")

###########################################################################
#     Test significance of time (spline) to explore the interaction
#             between time and the exposed variable
#         # incidence 
###########################################################################

# index date is labeled as date_positive
# convert index date as numeric #create new column with index date  

#as.Date(18382, origin='1970-01-01')
# if significant we'd like to vis the interaction 
#x axis to the date 
# numbers relative to the start date 2020-01-24

start_date = as.Date("2020/01/24")

start_date_numeric = as.numeric(start_date) #this is converted into days


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~###
# INCIDENCE 

incidence$index_numeric <- as.numeric(incidence$date_positive) - start_date_numeric  

inc1 <- coxph(Surv(t,
                       mh_outcome) ~ exposed*ns(index_numeric, 
                                                df = 2, 
                                                Boundary.knots = c(quantile(index_numeric,0.1), 
                                                                   quantile(index_numeric, 0.9))), 
                  data = incidence)

inc1a <-tidy(inc1, conf.int=TRUE,exponentiate = TRUE) 

#inc2 <- coxph(Surv(t, mh_outcome) ~ exposed*ns(index_numeric, 
#                                                          df = 2, 
#                                                          Boundary.knots = c(quantile(index_numeric,0.1), 
#                                                                             quantile(index_numeric, 0.9))) + cluster(patient_id), 
#                         data = incidence)
#
#inc3 <- coxph(Surv(t, mh_outcome) ~ exposed*ns(index_numeric, 
#                                                      df = 2, 
#                                                      Boundary.knots = c(quantile(index_numeric,0.1), 
#                                                                         quantile(index_numeric, 0.9))) + sex + ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))) + cluster(patient_id), 
#                     data = incidence)

inc1b <- anova(inc1)
#inc2 <- anova(inc2)
#inc3 <- anova(inc3)

# PREVALENCE 

prevalence$index_numeric <- as.numeric(prevalence$date_positive) - start_date_numeric  

prev1 <- coxph(Surv(t,
                   mh_outcome) ~ exposed*ns(index_numeric, 
                                            df = 2, 
                                            Boundary.knots = c(quantile(index_numeric,0.1), 
                                                               quantile(index_numeric, 0.9))), 
              data = prevalence)


  
prev1a <-tidy(prev1, conf.int=TRUE,exponentiate = TRUE) 

  

#prev2 <- coxph(Surv(t, mh_outcome) ~ exposed*ns(index_numeric, 
#                                               df = 2, 
#                                               Boundary.knots = c(quantile(index_numeric,0.1), 
#                                                                  quantile(index_numeric, 0.9))) + cluster(patient_id), 
#              data = prevalence)
#
#prev3 <- coxph(Surv(t, mh_outcome) ~ exposed*ns(index_numeric, 
#                                               df = 2, 
#                                               Boundary.knots = c(quantile(index_numeric,0.1), 
#                                                                  quantile(index_numeric, 0.9))) + sex + ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))) + cluster(patient_id), 
#              data = prevalence)

prev1b <- anova(prev1)
#prev2 <- anova(prev2)
#prev3 <- anova(prev3)


##############################################################################
# SAVE THE ANOVA OUTPUTS TO LOOK AT SIGNIFICANCE 

write_csv(inc1a, 'output/99_TEMPORARY_COX_INCIDENCE_SPLINE_TIME.csv')
write_csv(inc1b, 'output/99_TEMPORARY_COX_INCIDENCE_ANOVA.csv')

write_csv(prev1a, 'output/99_TEMPORARY_COX_PREV_SPLINE_TIME.csv')
write_csv(prev1b, 'output/99_TEMPORARY_COX_PREV_ANOVA.csv')








