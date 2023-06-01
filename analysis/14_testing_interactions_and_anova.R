#Purpose:                                                                      #
# 1.Testing interaction between spline('index time to start date')*exposed     #
# 2.Create waves variables (categorical data) & test interaction between       #
#   waves*exposed                                                              #
# 3. Save ANOVA outputs for 1 & 2 for the Incidence & Prevalence (3 adj models)#
#                     COX PROPORTIONAL HAZARD RATIO                            #
#                                                                              #
# This code is an additional check of our assumptions as results from the      #
# Sch.Residuals showed that the assumption has not been met.                   #
# - first we calculate estimates using coxph( Surv() then we test significance #
#   using Anova()                                                              #

library(tidyverse)
library(data.table)
library(survival)
library(survminer)
library(broom)
library(splines)
library(gridExtra)
library(car)

options(datatable.fread.datatable=FALSE)

#setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
#setwd('../')

###########################################################################
# Load data & create new variable waves and its categories 
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
# Set start date, change it to numeric, create index_time_to_start_date
###########################################################################

start_date <- as.Date("2020/01/24") 
start_date_numeric <- as.numeric(start_date) #this is converted into days

# Change index_dates to numeric
#incidence
incidence$index_numeric <- as.numeric(incidence$date_positive) 
incidence$index_time_to_start_date <- incidence$index_numeric - start_date_numeric  

#prevalence
prevalence$index_numeric <- as.numeric(prevalence$index_date) 
prevalence$index_time_to_start_date <- prevalence$index_numeric - start_date_numeric 


###########################################################################
# Test significance of interaction between time(spline) & exposed variable
###########################################################################

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# INCIDENCE 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

spline_m1 <- coxph(Surv(t,mh_outcome)~ exposed*ns(index_time_to_start_date, df = 2, 
                                                  Boundary.knots = c(quantile(index_time_to_start_date,0.1),
                                                                     quantile(index_time_to_start_date, 0.9))), 
                   data = incidence)

spline_m2 <- coxph(Surv(t,mh_outcome)~ exposed*ns(index_time_to_start_date, df = 2, 
                                                  Boundary.knots = c(quantile(index_time_to_start_date,0.1),
                                                                     quantile(index_time_to_start_date, 0.9))) + 
                     sex + ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))) + 
                     cluster(patient_id), 
                   data = incidence)

spline_m3 <- coxph(Surv(t,mh_outcome) ~ exposed*ns(index_time_to_start_date, df = 2, 
                                                   Boundary.knots = c(quantile(index_time_to_start_date,0.1),
                                                                      quantile(index_time_to_start_date, 0.9))) + 
                     ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))) + 
                     cluster(patient_id) +
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
                     mental_behavioural_disorder +
                     imd + 
                     rural_urban + 
                     self_isolating_v1, 
                   data = incidence)



tidy_spline_m1 <-tidy(spline_m1, conf.int=TRUE,exponentiate = TRUE) 
tidy_spline_m2 <-tidy(spline_m2, conf.int=TRUE,exponentiate = TRUE) 
tidy_spline_m3 <-tidy(spline_m3, conf.int=TRUE,exponentiate = TRUE) 


# run ANOVA & save 
a_m1 <-tidy(Anova(spline_m1, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)
a_m2 <-tidy(Anova(spline_m2, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)
a_m3 <-tidy(Anova(spline_m3, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)

a_m1$model <- "unadj"
a_m2$model <- "sex & age"
a_m3$model <- "fully adjusted"

avova_table <- rbind(a_m1, a_m2, a_m3)

# schoenfeld residuals
df_zph <- cox.zph(spline_m3)
plot_zph = ggcoxzph(df_zph, var = c("exposed"), font.main = 12)
ggsave("output/99_SCH_RESIDUALS_indextime_spline_interaction_INCIDENCE.jpg", arrangeGrob(grobs = plot_zph))
df_zph_table <-  cox.zph(spline_m3)$table 

#save CSVs
write_csv(tidy_spline_m3, 'output/99_COEFF_indextime_spline_interaction_INCIDENCE_full.csv')
#write_csv(incidence_spline_table, 'output/99_COEFF_indextime_spline_interaction_INCIDENCE_no_min.csv')
write_csv(avova_table, 'output/99_ANOVA_indextime_spline_interaction_INCIDENCE.csv')
write.csv(df_zph_table,"output/99_SCH_RESIDUALS_indextime_spline_interaction_INCIDENCE.csv",row.names = TRUE)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# PREVALENCE  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
spline_p1 <- coxph(Surv(t,mh_outcome)~ exposed*ns(index_time_to_start_date, df = 2, 
                                                  Boundary.knots = c(quantile(index_time_to_start_date,0.1),
                                                                     quantile(index_time_to_start_date, 0.9))) + 
                     ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))) + 
                     alcohol + 
                     cluster(patient_id) +
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
                     mental_behavioural_disorder +
                     imd + 
                     rural_urban + 
                     self_isolating_v1, data = prevalence)


tidy_spline_p1 <-tidy(spline_p1, conf.int=TRUE,exponentiate = TRUE) 

# anova
a_spline_p1 <-tidy(Anova(spline_p1, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE) 

# schoenfeld residuals
df_zph <- cox.zph(spline_p1)
plot_zph = ggcoxzph(df_zph, var = c("exposed"), font.main = 12)
ggsave("output/99_SCH_RESIDUALS_indextime_spline_interaction_PREVALENCE.jpg", arrangeGrob(grobs = plot_zph))
df_zph_table <-  cox.zph(spline_p1)$table 


#save csv
write.csv(df_zph_table,"output/99_SCH_RESIDUALS_indextime_spline_interaction_PREVALENCE.csv",row.names = TRUE)
write_csv(tidy_spline_p1, 'output/99_COEFF_indextime_spline_interaction_PREVALENCE.csv')
write_csv(a_spline_p1, 'output/99_ANOVA_indextime_spline_interaction_PREVALENCE.csv')


###########################################################################
# This is just an extra Test significance of interaction between WAVES & exposed variable
###########################################################################
m1 <- coxph(Surv(t,mh_outcome)~ exposed*waves, data = incidence)

m2 <- coxph(Surv(t,mh_outcome)~ exposed*waves + 
              sex + 
              ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))), 
            data = incidence)

m3 <- coxph(Surv(t,mh_outcome)~ exposed*waves + 
              ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))) + 
              alcohol + 
              cluster(patient_id) +
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
              mental_behavioural_disorder +
              imd + 
              rural_urban + 
              self_isolating_v1, 
            data = incidence)

# save cox models of interaction - only save fully adjusted for coeff.
m3_tidy <-tidy(m3, conf.int=TRUE,exponentiate = TRUE) 

# run anova & save 
a_m1 <-tidy(Anova(m1, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)
a_m2 <-tidy(Anova(m2, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)
a_m3 <-tidy(Anova(m3, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)

a_m1$model <- "unadj"
a_m2$model <- "sex & age"
a_m3$model <- "fully adjusted"

avova_table <- rbind(a_m1, a_m2, a_m3)

# schoenfeld residuals
df_zph <- cox.zph(m3)
plot_zph = ggcoxzph(df_zph, var = c("exposed"), font.main = 12)
ggsave("output/99_SCH_RESIDUALS_waves_interaction_INCIDENCE.jpg", arrangeGrob(grobs = plot_zph))

#save csv
df_zph_table <-  cox.zph(m3)$table 

write_csv(avova_table, 'output/99_ANOVA_waves_interaction_INCIDENCE.csv')
write_csv(m3_tidy, 'output/99_COEFF_waves_interaction_INCIDENCE.csv')
write.csv(df_zph_table,"output/99_SCH_RESIDUALS_waves_interaction_INCIDENCE.csv",row.names = TRUE)
