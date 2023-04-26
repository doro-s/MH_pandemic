# This code tests the interaction between time(time from strat date to index date)#
# We use spline(time) to do that                                                  #
#                     COX PROPORTIONAL HAZARD RATIO                               #
#                                                                                 #
# This is necessary as results from the Sch.Residuals showed that the             #
#  assumption has not been met. first we calculate estimates using                #
#  coxph( Surv()....then we test significance using Anova()                       #

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
# Set study start date and chnage it to numeric 
###########################################################################

start_date <- as.Date("2020/01/24") 
start_date_numeric <- as.numeric(start_date) #this is converted into days

###########################################################################
# Load data & create new variable for waves 
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
# Summary check on dates - needed to check all dates are within range
###########################################################################

# Chnage index_dates to numeric
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

###########################################################################
# Test significance of interaction between time(spline) & exposed variable
###########################################################################

# INCIDENCE 

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
                     rural_urban, 
                   data = incidence)



tidy_spline_m1 <-tidy(spline_m1, conf.int=TRUE,exponentiate = TRUE) 
tidy_spline_m2 <-tidy(spline_m2, conf.int=TRUE,exponentiate = TRUE) 
tidy_spline_m3 <-tidy(spline_m3, conf.int=TRUE,exponentiate = TRUE) 

#write_csv(tidy_spline_m1, 'output/99_anova_exposed_spline_time_unadj_incidence.csv')
#write_csv(tidy_spline_m2, 'output/99_anova_exposed_spline_time_sexage_incidence.csv')
write_csv(tidy_spline_m3, 'output/99_coeff_exposed_spline_time_fulladj_incidence.csv')


# run anova & save 
a_m1 <-tidy(Anova(spline_m1, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)
a_m2 <-tidy(Anova(spline_m2, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)
a_m3 <-tidy(Anova(spline_m3, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)

a_m1$model <- "unadj"
a_m2$model <- "sex & age"
a_m3$model <- "fully adjusted"

avova_table <- rbind(a_m1, a_m2, a_m3)

# save anova table for all models
write_csv(avova_table, 'output/99_anova_exposed_spline_time_interactions.csv')

# schoenfeld residuals
df_zph <- cox.zph(spline_m3)
plot_zph = ggcoxzph(df_zph, var = c("exposed"), font.main = 12)
ggsave("output/spline_interaction_inc_full_schoenfeld_res.jpg", arrangeGrob(grobs = plot_zph))
  
#save csv
df_zph_table <-  cox.zph(spline_m3)$table 
write.csv(df_zph_table,"output/spline_interaction_inc_full/_schoenfeld_res.csv",row.names = TRUE)


#############################    PREVALENCE    #################################

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
                     rural_urban, data = prevalence)


tidy_spline_p1 <-tidy(spline_p1, conf.int=TRUE,exponentiate = TRUE) 
write_csv(tidy_spline_p1, 'output/99_coeff_exposed_spline_time_fulladj_prev.csv')

# anova
a_spline_p1 <-tidy(Anova(spline_p1, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE) 

write_csv(a_spline_p1, 'output/99_anova_exposed_spline_time_fulladj_prev.csv')

# schoenfeld residuals
df_zph <- cox.zph(spline_p1)
plot_zph = ggcoxzph(df_zph, var = c("exposed"), font.main = 12)
ggsave("output/spline_interaction_prev_full_schoenfeld_res.jpg", arrangeGrob(grobs = plot_zph))

#save csv
df_zph_table <-  cox.zph(spline_p1)$table 
write.csv(df_zph_table,"output/spline_interaction_prev_full/_schoenfeld_res.csv",row.names = TRUE)
###########################################################################
# Test significance of interaction between WAVES & exposed variable
###########################################################################
# The above analysis showed only the incidence group to have a statistically
#  significant relationship between time and exposed category. Therefore we 
#  further test the effects of waves. This is done in a same way, first we 
#  calculate estimates using coxph( Surv().... then we test significance using
#  Anova()

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
              #imd + 
              rural_urban, 
            data = incidence)

# save cox models of interaction - only save fully adjusted for coeff.
m3_tidy <-tidy(m3, conf.int=TRUE,exponentiate = TRUE) 

write_csv(m3_tidy, 'output/99_coefficients_for_waves_incidence.csv')

# run anova & save 
a_m1 <-tidy(Anova(m1, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)
a_m2 <-tidy(Anova(m2, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)
a_m3 <-tidy(Anova(m3, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)

a_m1$model <- "unadj"
a_m2$model <- "sex & age"
a_m3$model <- "fully adjusted"

avova_table <- rbind(a_m1, a_m2, a_m3)

# save anova table for all models
write_csv(avova_table, 'output/99_anova_waves_time_interaction.csv')


# schoenfeld residuals
df_zph <- cox.zph(m3)
plot_zph = ggcoxzph(df_zph, var = c("exposed"), font.main = 12)
ggsave("output/wave_interaction_inc_full_schoenfeld_res.jpg", arrangeGrob(grobs = plot_zph))

#save csv
df_zph_table <-  cox.zph(m3)$table 
write.csv(df_zph_table,"output/wave_interaction_inc_full/_schoenfeld_res.csv",row.names = TRUE)