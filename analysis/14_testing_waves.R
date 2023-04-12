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
###########################################################################

incidence <- fread('output/incidence_t.csv')
prevalence <- fread('output/prevalence_t.csv')

###########################################################################
#     Test significance of time (spline) to explore the interaction
#             between time and the exposed variable
#         # incidence 
###########################################################################


# convert index date as numeric #create new column with index date  


# if significant we'd like to visualize the interaction 
#x axis to the date 
# numbers relative to the start date 2020-01-24

start_date <- as.Date("2020/01/24")

print(start_date)

start_date_numeric <- as.numeric(start_date) #this is converted into days

print(start_date_numeric)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~###
# INCIDENCE 

incidence$index_numeric <- as.numeric(incidence$date_positive) 

incidence$index_numeric2 <- incidence$index_numeric - start_date_numeric  

t2<- incidence %>% filter(index_date < as.Date("2100-01-01"))

print('summary(incidence$index_date)')
summary(incidence$index_date) 

print('summary(t2$index_date) dates less than 2100-01-01')
summary(t2$index_date)

print('summary(incidence$index_numeric)')
summary(incidence$index_numeric)

print('summary(incidence$index_numeric2 - time from start date to index date)')
summary(incidence$index_numeric2)


print('NAs number')
incidence %>% filter(is.na(index_date)) %>% nrow()

######################################################################################################

print('1. incidence index numeric without spline')
inc1a <- coxph(Surv(t,mh_outcome)~ exposed*index_numeric2 ,data = incidence)
print(inc1a)


print('2. incidence index numeric with spline')
inc1b <- coxph(Surv(t,mh_outcome)~ exposed*ns(index_numeric2, df = 2, 
                                               Boundary.knots = c(quantile(index_numeric2,0.1),
                                                                  quantile(index_numeric2, 0.9))),
                data = incidence)
print(inc1b)



inc1aaaaaa <-tidy(inc1b, conf.int=TRUE,exponentiate = TRUE) 

print(inc1aaaaaa)

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

print('Anova incidince withOUT spline')
inc1aa <- anova(inc1a)
print(inc1aa)

print('Anova incidince with spline')
inc1bb <- anova(inc1b)
print(inc1bb)
#inc2 <- anova(inc2)
#inc3 <- anova(inc3)

######################################################################################################
######################################################################################################
# PREVALENCE 

prevalence$index_numeric <- as.numeric(prevalence$index_date) 
prevalence$index_numeric2 <- prevalence$index_numeric - start_date_numeric  

t2<- prevalence %>% filter(index_date <as.Date("2100-01-01"))

print('summary(prevalence$index_date)')
summary(prevalence$index_date) 

print('summary(t2$index_date) dates less than 2100-01-01')
summary(t2$index_date)

print('summary(prevalence$index_numeric)')
summary(prevalence$index_numeric)

print('summary(prevalence$index_numeric2)')
summary(prevalence$index_numeric2)


print('NAs number')
prevalence %>% filter(is.na(index_date)) %>% nrow()




print('PREV - index numeric without spline')
prev111 <- coxph(Surv(t,mh_outcome)~ exposed*index_numeric2 ,data = prevalence)
print(prev111)


print('PREV - index numeric with spline')

prev1 <- coxph(Surv(t,
                   mh_outcome) ~ exposed*ns(index_numeric2, 
                                            df = 2, 
                                            Boundary.knots = c(quantile(index_numeric2,0.1), 
                                                               quantile(index_numeric2, 0.9))), 
              data = prevalence)


print(prev1)

prev1a <-tidy(prev1, conf.int=TRUE,exponentiate = TRUE) 

print(prev1a)
  

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

print('Anova prev withOUT spline')
prev111bb <- anova(prev111)
print(prev111bb)


print('Anova prev with spline')
prev1b <- anova(prev1)
print(prev1b)
#prev2 <- anova(prev2)
#prev3 <- anova(prev3)


##############################################################################
# SAVE THE ANOVA OUTPUTS TO LOOK AT SIGNIFICANCE 

write_csv(inc1aaaaaa, 'output/99_TEMPORARY_COX_INCIDENCE_SPLINE_TIME.csv')
write_csv(inc1bb, 'output/99_TEMPORARY_COX_INCIDENCE_ANOVA.csv')

write_csv(prev1a, 'output/99_TEMPORARY_COX_PREV_SPLINE_TIME.csv')
write_csv(prev1b, 'output/99_TEMPORARY_COX_PREV_ANOVA.csv')








