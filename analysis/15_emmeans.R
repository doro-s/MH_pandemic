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
                                 sex, 
                               data = incidence)



# estimated marginal means 
in1_emmeans <- as.data.frame(emmeans(in1, 
                                     specs = ~index_time_to_start_date|exposed,
                                     at= list(index_time_to_start_date=
                                                min(incidence$index_time_to_start_date):max(incidence$index_time_to_start_date))))

write_csv(in1_emmeans, 'output/99_emmeans_incidence.csv')

plot <- ggplot(in1_emmeans, mapping = aes(x= index_time_to_start_date, y= emmean,color=exposed)) +
  geom_point() 
#plot
ggsave("output/99_emmeans_incidence.jpg",plot)


