library(tidyverse)
library(survival)
library(survminer)
library(data.table)
library(broom)
library(splines)

options(datatable.fread.datatable=FALSE)

#rm(list=ls())
# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

incidence <- fread('output/incidence_t.csv')
prevalence <- fread('output/prevalence_t.csv')

#summary(incidence)

###  Function for the fully adjusted model 
fit_cox_model <- function(df, vars){
  
  vars <- paste(vars, collapse = ' + ')
  
  model_formula <- formula(paste0('Surv(t, mh_outcome) ~ ', vars))
  
  model <- coxph(model_formula, data = df)
  
  return(model)
  
}

####    unadjusted model
unadj_incidence <- coxph(Surv(t, mh_outcome) ~ exposed + cluster(patient_id), 
                         data = incidence)

unadj_prevalence <- coxph(Surv(t, mh_outcome) ~ exposed + cluster(patient_id),
                          data = prevalence)

#summary(unadj_incidence)


###   min adjusted model (sex and age)
min_adj_inc <- coxph(Surv(t, mh_outcome) ~ exposed + sex + age + cluster(patient_id), 
                     data = incidence)


min_adj_prev <- coxph(Surv(t, mh_outcome) ~ exposed + sex + age + cluster(patient_id),
                      data = prevalence)

# Check model specification - correct covariates? Missing any variables?

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
              

inc_model <- fit_cox_model(incidence, inc_vars)
#summary(inc_model)

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

prev_model <- fit_cox_model(prevalence, prev_vars)
#summary(prev_model)

# Get outputs into opensafely friendly format e.g. csv file

###   Function to tidy tables 

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

###   All scripts need an output for opensafely to work, so save out placeholder

write_csv(incidence_cox_hz, 'output/inc_hr_placeholder.csv')
write_csv(prevalence_cox_hz, 'output/prev_hr_placeholder.csv')

###   Check Schoenfled residuals to test the proportional-hazards assumption
# incidence
ph_no_inc <-  cox.zph(unadj_incidence)$table
ph_min_inc <-  cox.zph(min_adj_inc)$table
ph_full_inc <-  cox.zph(inc_model)$table

# prevalence
ph_no_prev <-  cox.zph(unadj_prevalence)$table
ph_min_prev <-  cox.zph(min_adj_prev)$table
ph_full_prev <-  cox.zph(prev_model)$table

###   save Schoenfled residuals

write.csv(ph_no_inc, "output/schoenfled_inc_no.csv")
write.csv(ph_min_inc, "output/schoenfled_inc_min.csv")
write.csv(ph_full_inc, "output/schoenfled_inc_full.csv")
write.csv(ph_no_prev, "output/schoenfled_prev_no.csv")
write.csv(ph_min_prev, "output/schoenfled_prev_min.csv")
write.csv(ph_full_prev, "output/schoenfled_prev_full.csv")

#Plot and save the residuals 

jpeg('output/res_no_inc.jpg')
plot(ph_no_inc, var = "exposed")
dev.off()

jpeg('output/res_min_inc.jpg')
plot(ph_no_inc, var = "exposed")
dev.off()

jpeg('output/res_full_inc.jpg')
plot(ph_no_inc, var = "exposed")
dev.off()

jpeg('output/res_no_prev.jpg')
plot(ph_no_inc, var = "exposed")
dev.off()

jpeg('output/res_min_prev.jpg')
plot(ph_no_inc, var = "exposed")
dev.off()

jpeg('output/res_full_prev.jpg')
plot(ph_no_inc, var = "exposed")
dev.off()


#add Cox HR visual graphs
#inc no 
f1 <- survfit(unadj_incidence)
jpeg('output/cox_graph_inc_no_adj.jpg')
ggsurvplot(f1, data =incidence,  palette= '#2E9FDF', ggtheme = theme_minimal())
dev.off()

#inc min 
f2 <- survfit(min_adj_inc)
jpeg('output/cox_graph_inc_min_adj.jpg')
ggsurvplot(f2, data =incidence,  palette= '#2E9FDF', ggtheme = theme_minimal())
dev.off()

#inc full 
f3 <- survfit(inc_model)
jpeg('output/cox_graph_inc_full_adj.jpg')
ggsurvplot(f3, data =incidence,  palette= '#2E9FDF', ggtheme = theme_minimal())
dev.off()

#prev no
f4 <- survfit(unadj_prevalence)
jpeg('output/cox_graph_prev_no_adj.jpg')
ggsurvplot(f4, data =prevalence,  palette= '#2E9FDF', ggtheme = theme_minimal())
dev.off()

#prev min
f5 <- survfit(min_adj_prev)
jpeg('output/cox_graph_prev_min_adj.jpg')
ggsurvplot(f5, data =prevalence,  palette= '#2E9FDF', ggtheme = theme_minimal())
dev.off()

#prev full
f6 <- survfit(prev_model)
jpeg('output/cox_graph_prev_full_adj.jpg')
ggsurvplot(f6, data =prevalence,  palette= '#2E9FDF', ggtheme = theme_minimal())
dev.off()

remove(f1,f2,f3,f4,f5,f6)

