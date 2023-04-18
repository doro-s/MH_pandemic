library(tidyverse)
library(data.table)
library(survival)
library(survminer)
library(broom)
library(splines)
library(gridExtra)
library(car)

#rm(list=ls())

options(datatable.fread.datatable=FALSE)

#setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
#setwd('../')

###########################################################################
# Load data 
# create new variable for waves 

#wave dates

# alphanad_before <- "2020-11-16" to "2021-05-16"
# delta <- "2021-05-17" to "2021-12-19"
# omnicrom <- "2021-12-20" to "2022-10-19" 
###########################################################################

incidence <- fread('output/incidence_t.csv') %>% 
  mutate(waves = 
           case_when(index_date <= "2020-11-15" ~ "before_alpha",
                     index_date >= "2020-11-16" & index_date <="2021-05-16" ~ "alpha",
                     index_date >="2021-05-17" & index_date <="2021-12-19" ~ "delta",
                     index_date >="2021-12-20" ~ "omnicron"))


prevalence <- fread('output/prevalence_t.csv') %>% 
  mutate(waves = 
           case_when(index_date <= "2020-11-15" ~ "before_alpha",
                     index_date >= "2020-11-16" & index_date <="2021-05-16" ~ "alpha",
                     index_date >="2021-05-17" & index_date <="2021-12-19" ~ "delta",
                     index_date >="2021-12-20" ~ "omnicron"))


###########################################################################
#     Test significance of time (spline) to explore the interaction
#             between time and the exposed variable
#         # incidence 
# convert index date as numeric 
#     Change index date to numeric so that we can use it as spline
# numbers relative to the start date 2020-01-24
###########################################################################

start_date <- as.Date("2020/01/24") 
print(start_date)

start_date_numeric <- as.numeric(start_date) #this is converted into days
print(start_date_numeric)

# summary check of index dates

# INCIDENCE 

incidence$index_numeric <- as.numeric(incidence$date_positive) 
incidence$index_time_to_start_date <- incidence$index_numeric - start_date_numeric  

print('summary(incidence$index_date)')
summary(incidence$index_date) 

print('summary(incidence$index_numeric)')
summary(incidence$index_numeric)

print('summary(incidence$index_time_to_start_date - time from start date to index date)')
summary(incidence$index_time_to_start_date)

print('NAs number')
incidence %>% filter(is.na(index_date)) %>% nrow()

prevalence$index_numeric <- as.numeric(prevalence$index_date) 
prevalence$index_time_to_start_date <- prevalence$index_numeric - start_date_numeric  


print('summary(prevalence$index_date)')
summary(prevalence$index_date) 


print('summary(prevalence$index_numeric)')
summary(prevalence$index_numeric)

print('summary(prevalence$index_time_to_start_date)')
summary(prevalence$index_time_to_start_date)


print('NAs number')
prevalence %>% filter(is.na(index_date)) %>% nrow()

######################################################################################################
######################################################################################################
#
#         Testing the interaction between exposure and time (time as a spline)
#
######################################################################################################
######################################################################################################

# INCIDENCE 

print('1. Incidence index numeric model - spline')
incidence_with_spline <- coxph(Surv(t,mh_outcome)~ exposed*ns(index_time_to_start_date, df = 2, 
                                               Boundary.knots = c(quantile(index_time_to_start_date,0.1),
                                                                  quantile(index_time_to_start_date, 0.9))), 
                               data = incidence)
print(incidence_with_spline)
TIDY_WITH_SPLINE <-tidy(incidence_with_spline, conf.int=TRUE,exponentiate = TRUE) 
print(TIDY_WITH_SPLINE)

print('1a. Anova incidince - spline')
anova_incidence_with_spline <- Anova(incidence_with_spline, row.names = TRUE)
anova_TIDY_WITH_SPLINE <-tidy(anova_incidence_with_spline, conf.int=TRUE,exponentiate = TRUE) 
print(anova_incidence_with_spline)

#a1 <- Anova(incidence_with_spline, row.names = TRUE)
#a2 <-tidy(a1, conf.int=TRUE,exponentiate = TRUE) 
#print(a2)

#write_csv(TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_INCIDENCE_SPLINE_TIME.csv')
write_csv(anova_TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_INCIDENCE_ANOVA.csv')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
print('2. Incidence index numeric model - spline + AGE +SEX')
incidence_with_spline <- coxph(Surv(t,mh_outcome)~ exposed*ns(index_time_to_start_date, df = 2, 
                                                              Boundary.knots = c(quantile(index_time_to_start_date,0.1),
                                                                                 quantile(index_time_to_start_date, 0.9))) + sex + ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))), 
                               data = incidence)
print(incidence_with_spline)
TIDY_WITH_SPLINE <-tidy(incidence_with_spline, conf.int=TRUE,exponentiate = TRUE) 
print(TIDY_WITH_SPLINE)

print('2a. Anova incidince - spline')
anova_incidence_with_spline <- Anova(incidence_with_spline, row.names = TRUE)
anova_TIDY_WITH_SPLINE <-tidy(anova_incidence_with_spline, conf.int=TRUE,exponentiate = TRUE) 
print(anova_incidence_with_spline)

#write_csv(TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_INCIDENCE_SPLINE_TIME_sex_age.csv')
write_csv(anova_TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_INCIDENCE_ANOVA_sex_age.csv')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print('3. Incidence index numeric - spline + fully adjusted')
incidence_with_spline <- coxph(Surv(t,mh_outcome) ~ exposed*ns(index_time_to_start_date, df = 2, 
                                                              Boundary.knots = c(quantile(index_time_to_start_date,0.1),
                                                                                 quantile(index_time_to_start_date, 0.9))) + 
                                 ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))) + 
                                 alcohol + 
                                 obese_binary_flag + 
                                 cancer + 
                                 digestive_disorder + 
                                 hiv_aids + 
                                 kidney_disorder + 
                                 respiratory_disorder + 
                                 metabolic_disorder + 
                                 sex + 
                                 ethnicity + 
                                 region + 
                                 hhsize + 
                                 work_status_new + CVD + 
                                 musculoskeletal + 
                                 neurological + 
                                 mental_behavioural_disorder, 
                               data = incidence)



print(incidence_with_spline)
TIDY_WITH_SPLINE <-tidy(incidence_with_spline, conf.int=TRUE,exponentiate = TRUE) 
print(TIDY_WITH_SPLINE)

print('3a. IMPORTANT - Anova incidince WITH spline')
anova_incidence_with_spline <- Anova(incidence_with_spline, row.names = TRUE)
anova_TIDY_WITH_SPLINE <-tidy(anova_incidence_with_spline, conf.int=TRUE,exponentiate = TRUE) 
print(anova_incidence_with_spline)


#write_csv(TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_INCIDENCE_SPLINE_TIME_fully_adjusted.csv')
write_csv(anova_TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_INCIDENCE_ANOVA_fully_adjusted.csv')


######################################################################################################
# PREVALENCE 

# Testing the interaction between exposure and time (time as a spline)
#
######################################################################################################

print('1. prevalence index numeric WITHOUT spline')
prevalence_without_spline <- coxph(Surv(t,mh_outcome)~ exposed*index_time_to_start_date ,data = prevalence)
print(prevalence_without_spline)

print('1a. Anova prevalence WITHOUT spline')
anova_prevalence_without_spline <- Anova(prevalence_without_spline)
print(anova_prevalence_without_spline)

print('2. IMPORTANT - prevalence index numeric with spline')
prevalence_with_spline <- coxph(Surv(t,mh_outcome)~ exposed*ns(index_time_to_start_date, df = 2, 
                                                               Boundary.knots = c(quantile(index_time_to_start_date,0.1),
                                                                                  quantile(index_time_to_start_date, 0.9))), data = prevalence)

print(prevalence_with_spline)

TIDY_WITH_SPLINE <-tidy(prevalence_with_spline, conf.int=TRUE,exponentiate = TRUE) 

print(TIDY_WITH_SPLINE)
print('2a. IMPORTANT - Anova prevalence WITH spline')
anova_prevalence_with_spline <- Anova(prevalence_with_spline, row.names = TRUE)
anova_TIDY_WITH_SPLINE <-tidy(anova_prevalence_with_spline, conf.int=TRUE,exponentiate = TRUE) 

print(anova_TIDY_WITH_SPLINE)
#write_csv(TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_PREV_SPLINE_TIME.csv')
write_csv(anova_TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_PREV_ANOVA.csv')







######################################################################################################
######################################################################################################
#
#         Testing the interaction between exposure and WAVES
#
######################################################################################################
######################################################################################################

int_1 <- coxph(Surv(t,mh_outcome)~ exposed*waves, data = incidence)
tidy_table <-tidy(int_1, conf.int=TRUE,exponentiate = TRUE) 
print('INTERACTION WITH WAVES VARIABLE ANOVA')
anova <- Anova(int_1, row.names = TRUE)
anova_tidy <-tidy(anova, conf.int=TRUE, exponentiate = TRUE) 
print(anova_tidy)

#save
write_csv(anova_tidy, 'output/99_anova_waves.csv')



print('INTERACTION WITH WAVES VARIABLE- age and sex')

int_1 <- coxph(Surv(t,mh_outcome)~ exposed*waves + 
                 sex + 
                 ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))), 
               data = incidence)
tidy_table <-tidy(int_1, conf.int=TRUE,exponentiate = TRUE) 
print('INTERACTION WITH WAVES VARIABLE ANOVA')
anova <- Anova(int_1, row.names = TRUE)
anova_tidy <-tidy(anova, conf.int=TRUE, exponentiate = TRUE) 
print(anova_tidy)

#save
write_csv(anova_tidy, 'output/99_anova_waves_sex_age.csv')





print('INTERACTION WITH WAVES VARIABLE - fully adjusted')
int_1 <- coxph(Surv(t,mh_outcome)~ exposed*waves + 
                 ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))) + 
                 alcohol + 
                 obese_binary_flag + 
                 cancer + 
                 digestive_disorder + 
                 hiv_aids + 
                 kidney_disorder + 
                 respiratory_disorder + 
                 metabolic_disorder + 
                 sex + 
                 ethnicity + 
                 region + 
                 hhsize + 
                 work_status_new + 
                 CVD + 
                 musculoskeletal + 
                 neurological + 
                 mental_behavioural_disorder, 
               data = incidence)
tidy_table <-tidy(int_1, conf.int=TRUE,exponentiate = TRUE) 
print('INTERACTION WITH WAVES VARIABLE ANOVA')
anova <- Anova(int_1, row.names = TRUE)
anova_tidy <-tidy(anova, conf.int=TRUE, exponentiate = TRUE) 
print(anova_tidy)

#save
write_csv(anova_tidy, 'output/99_anova_waves_fully adjusted.csv')
write_csv(tidy_table, 'output/99_coefficients_for_waves_incidence.csv')


######################################################################################################









