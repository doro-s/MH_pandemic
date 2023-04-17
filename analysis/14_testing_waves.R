library(tidyverse)
library(data.table)
library(survival)
library(survminer)
library(broom)
library(splines)
library(gridExtra)

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
           case_when(index_date <= "2021-12-19" ~ "before_omnicron",
                     index_date >="2021-12-20" ~ "omnicron_onwards"))


prevalence <- fread('output/prevalence_t.csv') %>% 
  mutate(waves = 
           case_when(index_date <= "2021-12-19" ~ "before_omnicron",
                     index_date >="2021-12-20" ~ "omnicron_onwards"))


###########################################################################
#     Test significance of time (spline) to explore the interaction
#             between time and the exposed variable
#         # incidence 
# convert index date as numeric #create new column with index date  
# if significant we'd like to visualize the interaction 
#x axis to the date 
# numbers relative to the start date 2020-01-24
###########################################################################

start_date <- as.Date("2020/01/24") 
print(start_date)

start_date_numeric <- as.numeric(start_date) #this is converted into days
print(start_date_numeric)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~###
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

######################################################################################################
######################################################################################################
# Testing the interaction between exposure and time (time as a spline)
#
######################################################################################################

#print('1. Incidence index numeric WITHOUT spline')
#incidence_without_spline <- coxph(Surv(t,mh_outcome)~ exposed*index_time_to_start_date ,data = incidence)
#print(incidence_without_spline)

#print('1a. Anova incidince WITHOUT spline')
#anova_incidence_without_spline <- anova(incidence_without_spline)
#(anova_incidence_without_spline)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


print('2. IMPORTANT - Incidence index numeric with spline')
incidence_with_spline <- coxph(Surv(t,mh_outcome)~ exposed*ns(index_time_to_start_date, df = 2, 
                                               Boundary.knots = c(quantile(index_time_to_start_date,0.1),
                                                                  quantile(index_time_to_start_date, 0.9))), 
                               data = incidence)
print(incidence_with_spline)
TIDY_WITH_SPLINE <-tidy(incidence_with_spline, conf.int=TRUE,exponentiate = TRUE) 
print(TIDY_WITH_SPLINE)
print('2a. IMPORTANT - Anova incidince WITH spline')
anova_incidence_with_spline <- anova(incidence_with_spline, row.names = TRUE)
anova_TIDY_WITH_SPLINE <-tidy(anova_incidence_with_spline, conf.int=TRUE,exponentiate = TRUE) 
print(anova_incidence_with_spline)


#write_csv(TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_INCIDENCE_SPLINE_TIME.csv')
write_csv(anova_TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_INCIDENCE_ANOVA.csv')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
print('222. IMPORTANT - Incidence index numeric with spline + AGE +SEX')
incidence_with_spline <- coxph(Surv(t,mh_outcome)~ exposed*ns(index_time_to_start_date, df = 2, 
                                                              Boundary.knots = c(quantile(index_time_to_start_date,0.1),
                                                                                 quantile(index_time_to_start_date, 0.9))) + sex + ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))), 
                               data = incidence)
print(incidence_with_spline)
TIDY_WITH_SPLINE <-tidy(incidence_with_spline, conf.int=TRUE,exponentiate = TRUE) 
print(TIDY_WITH_SPLINE)
print('2a. IMPORTANT - Anova incidince WITH spline')
anova_incidence_with_spline <- anova(incidence_with_spline, row.names = TRUE)
anova_TIDY_WITH_SPLINE <-tidy(anova_incidence_with_spline, conf.int=TRUE,exponentiate = TRUE) 
print(anova_incidence_with_spline)

#write_csv(TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_INCIDENCE_SPLINE_TIME_sex_age.csv')
write_csv(anova_TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_INCIDENCE_ANOVA_sex_age.csv')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print('22233. IMPORTANT - Incidence index numeric with spline + fully adjusted')
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
print('2a. IMPORTANT - Anova incidince WITH spline')
anova_incidence_with_spline <- anova(incidence_with_spline, row.names = TRUE)
anova_TIDY_WITH_SPLINE <-tidy(anova_incidence_with_spline, conf.int=TRUE,exponentiate = TRUE) 
print(anova_incidence_with_spline)


#write_csv(TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_INCIDENCE_SPLINE_TIME_fully_adjusted.csv')
write_csv(anova_TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_INCIDENCE_ANOVA_fully_adjusted.csv')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

int_1 <- coxph(Surv(t,mh_outcome)~ exposed*waves, data = incidence)
tidy_table <-tidy(int_1, conf.int=TRUE,exponentiate = TRUE) 
print('INTERACTION WITH WAVES VARIABLE ANOVA')
anova <- anova(int_1, row.names = TRUE)
anova_tidy <-tidy(anova, conf.int=TRUE, exponentiate = TRUE) 
print(anova_tidy)
write_csv(anova_tidy, 'output/99_anova_waves.csv')


print('INTERACTION WITH WAVES VARIABLE- age and sex')

int_1 <- coxph(Surv(t,mh_outcome)~ exposed*waves + 
                 sex + 
                 ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))), 
               data = incidence)
tidy_table <-tidy(int_1, conf.int=TRUE,exponentiate = TRUE) 
print('INTERACTION WITH WAVES VARIABLE ANOVA')
anova <- anova(int_1, row.names = TRUE)
anova_tidy <-tidy(anova, conf.int=TRUE, exponentiate = TRUE) 
print(anova_tidy)
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
anova <- anova(int_1, row.names = TRUE)
anova_tidy <-tidy(anova, conf.int=TRUE, exponentiate = TRUE) 
print(anova_tidy)
write_csv(anova_tidy, 'output/99_anova_waves_fully adjusted.csv')

######################################################################################################
######################################################################################################
# PREVALENCE 

prevalence$index_numeric <- as.numeric(prevalence$index_date) 
prevalence$index_time_to_start_date <- prevalence$index_numeric - start_date_numeric  

t2<- prevalence %>% filter(index_date <as.Date("2100-01-01"))

print('summary(prevalence$index_date)')
summary(prevalence$index_date) 

print('summary(t2$index_date) dates less than 2100-01-01')
summary(t2$index_date)

print('summary(prevalence$index_numeric)')
summary(prevalence$index_numeric)

print('summary(prevalence$index_time_to_start_date)')
summary(prevalence$index_time_to_start_date)


print('NAs number')
prevalence %>% filter(is.na(index_date)) %>% nrow()

######################################################################################################
# Testing the interaction between exposure and time (time as a spline)
#
######################################################################################################

print('1. prevalence index numeric WITHOUT spline')
prevalence_without_spline <- coxph(Surv(t,mh_outcome)~ exposed*index_time_to_start_date ,data = prevalence)
print(prevalence_without_spline)

print('1a. Anova prevalence WITHOUT spline')
anova_prevalence_without_spline <- anova(prevalence_without_spline)
print(anova_prevalence_without_spline)


print('2. IMPORTANT - prevalence index numeric with spline')
prevalence_with_spline <- coxph(Surv(t,mh_outcome)~ exposed*ns(index_time_to_start_date, df = 2, 
                                                              Boundary.knots = c(quantile(index_time_to_start_date,0.1),
                                                                                 quantile(index_time_to_start_date, 0.9))), data = prevalence)

print(prevalence_with_spline)



TIDY_WITH_SPLINE <-tidy(prevalence_with_spline, conf.int=TRUE,exponentiate = TRUE) 

print(TIDY_WITH_SPLINE)

print('2a. IMPORTANT - Anova prevalence WITH spline')
anova_prevalence_with_spline <- anova(prevalence_with_spline, row.names = TRUE)
anova_TIDY_WITH_SPLINE <-tidy(anova_prevalence_with_spline, conf.int=TRUE,exponentiate = TRUE) 

print(anova_TIDY_WITH_SPLINE)


write_csv(TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_PREV_SPLINE_TIME.csv')
write_csv(anova_TIDY_WITH_SPLINE, 'output/99_TEMPORARY_COX_PREV_ANOVA.csv')








