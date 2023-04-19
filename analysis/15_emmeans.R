library(tidyverse)
library(data.table)
library(survival)
library(survminer)
library(broom)
library(splines)
library(gridExtra)
library(car)
library(emmeans)


#rm(list=ls())

options(datatable.fread.datatable=FALSE)

#setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
#setwd('../')

###########################################################################
# Load data 

start_date <- as.Date("2020/01/24") 
start_date_numeric <- as.numeric(start_date) #this is converted into days
#18285 + 800
#as.Date(19085, origin="1970/01/01")


incidence <- fread('output/incidence_t.csv') %>% 
  mutate(waves = 
           case_when(index_date <= "2020-11-15" ~ "before_alpha",
                     index_date >= "2020-11-16" & index_date <="2021-05-16" ~ "alpha",
                     index_date >="2021-05-17" & index_date <="2021-12-19" ~ "delta",
                     index_date >="2021-12-20" ~ "omnicron"))

incidence$index_numeric <- as.numeric(incidence$date_positive) 
incidence$index_time_to_start_date <- incidence$index_numeric - start_date_numeric


# EMMEANS
in1 <- coxph(Surv(t,mh_outcome) ~ exposed*ns(index_time_to_start_date, df = 2, 
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


#PROBLEMS  BUILDS GRID A COMBINATION OF EVERYTHINNG 
# ARGUMNET TO TELLS IT THAT ALL OF THE NUISANCE = NON NUISENCE = exposed, index 
#ref_grid()

# estimated marginal means 
in1_emmeans <- as.data.frame(emmeans(in1, 
                                     specs = ~index_time_to_start_date|exposed,
                                     non.nuisance=c("exposed","index_time_to_start_date"),
                                     at= list(index_time_to_start_date=
                                                min(incidence$index_time_to_start_date):max(incidence$index_time_to_start_date))))

write_csv(in1_emmeans, 'output/99_emmeans_incidence.csv')

plot <- ggplot(in1_emmeans, mapping = aes(x= index_time_to_start_date, y= emmean,color=exposed)) +
  geom_point() 
#plot
ggsave("output/99_emmeans_incidence.jpg",plot)

#Bayesian Information Criterion
#bic<- BIC(in1)

#check the BIC
# MODEL WITH MORE DEGREES OF FREEDOM -> 3

in2 <- coxph(Surv(t,mh_outcome) ~ exposed*ns(index_time_to_start_date, df = 3, 
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

in2_emmeans <- as.data.frame(emmeans(in2, 
                                     specs = ~index_time_to_start_date|exposed,
                                     non.nuisance=c("exposed","index_time_to_start_date"),
                                     at= list(index_time_to_start_date=
                                                min(incidence$index_time_to_start_date):max(incidence$index_time_to_start_date))))

write_csv(in2_emmeans, 'output/99_emmeans_3df_incidence.csv')

plot <- ggplot(in2_emmeans, mapping = aes(x= index_time_to_start_date, y= emmean,color=exposed)) +
  geom_point() 
#plot
ggsave("output/99_emmeans_3df_incidence.jpg",plot)

# MODEL WITH MORE DEGREES OF FREEDOM -> 4

in3 <- coxph(Surv(t,mh_outcome) ~ exposed*ns(index_time_to_start_date, df = 4, 
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

in3_emmeans <- as.data.frame(emmeans(in3, 
                                     specs = ~index_time_to_start_date|exposed,
                                     non.nuisance=c("exposed","index_time_to_start_date"),
                                     at= list(index_time_to_start_date=
                                                min(incidence$index_time_to_start_date):max(incidence$index_time_to_start_date))))

write_csv(in3_emmeans, 'output/99_emmeans_4df_incidence.csv')

plot <- ggplot(in3_emmeans, mapping = aes(x= index_time_to_start_date, y= emmean,color=exposed)) +
  geom_point() 
#plot
ggsave("output/99_emmeans_4df_incidence.jpg",plot)


#Bayesian Information Criterion for all models

t<- as.data.frame(sapply(list(in1, in2, in3), BIC))

write_csv(t, 'output/BIC_all_3models.cvs')

#####
# anova on the models


a1 <-tidy(Anova(in1, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)
a2 <-tidy(Anova(in2, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)
a3 <-tidy(Anova(in3, row.names = TRUE), conf.int=TRUE,exponentiate = TRUE)

a1$df <- "2 DF"
a2$df <- "3 DF"
a3$df <- "4 DF"

avova_table <- prevalence_cox_hz <- rbind(a1,a2,a3)
write_csv(avova_table, 'output/different_degrees_of_freedom_avova_fully_adj.cvs')

rm(a1,a2,a3)

