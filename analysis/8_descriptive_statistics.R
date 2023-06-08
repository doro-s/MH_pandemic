library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

#Load functions and data
# Need to read in matched person level data
# Only need to consider participants characteristics at the index date
# 100% of cases and 0% controls should have result_mk == 1

source('analysis/cov_dist_cat.R')
source('analysis/cov_dist_cont.R')
source('analysis/functions/covid_vaccination_status_variable.R')


incidence <- fread('output/adjusted_incidence_group.csv')
prevalence <- fread('output/adjusted_prevalence_group.csv')

###############################################################################
#                 Create index_date
# index date for the exposed should be the date_positive (earliest date of 
#   positive covid tests from CIS, HES or T&T)
#
# index date for the control should be visit_date (of the matched exposed as
#  we choose people who haven't been infected 14+ or - of visit date)
###############################################################################

incidence <- incidence %>%
  mutate(index_date = ifelse(exposed == 1, date_positive, visit_date)) %>%
  mutate(index_date = as.IDate(index_date))

prevalence <- prevalence %>%
  mutate(index_date = ifelse(exposed == 1, date_positive, visit_date))%>%
  mutate(index_date = as.IDate(index_date))


# Apply the covid_vaccination status function ################################

incidence <- covid_vaccine_function(data = incidence)

prevalence <- covid_vaccine_function(data = prevalence)


# Create bmi category variable
create_bmi_categories <- function(df){
  df <- df %>% 
    mutate(bmi_category = case_when(
      bmi == 0 ~ 'unknown or outlier', 
      bmi < 18.5 ~ 'underweight',
      bmi >= 18.5 & bmi < 25 ~ 'ideal',
      bmi >= 25 & bmi < 30 ~ 'overweight',
      bmi >= 30 ~ 'obese'))
  
  return(df)
}
# Rename English regions function 
rename_regions_function<- function(df){
  df <- df %>% 
    mutate(region = case_when(
      gor9d == 'E12000001' ~ 'North East', 
      gor9d == 'E12000002' ~ 'North West',
      gor9d =='E12000003' ~ 'Yorkshire and The Humber',
      gor9d == 'E12000004' ~ 'East Midlands',
      gor9d == 'E12000005' ~ 'West Midlands',
      gor9d == 'E12000006' ~ 'East of England',
      gor9d == 'E12000007' ~ 'London',
      gor9d == 'E12000008' ~ 'South East',
      gor9d == 'E12000009' ~ 'South West',
      TRUE ~ "Missing")) 
  
  return(df)
}
# Create age bands 
age_bands_function <- function(df){
  df <- df %>% mutate(
    #create categories
    age_groups = case_when(
      age >= 16 & age <= 24 ~ "16 to 24",
      age >= 25 & age <= 34 ~ "25 to 34",
      age >= 35 & age <= 49 ~ "35 to 49",
      age >= 50 & age <= 69 ~ "50 to 69",
      age >= 70 ~ "70 and over"))
  return(df)
}


# apply the bmi categories function
incidence <- create_bmi_categories(incidence)
prevalence <- create_bmi_categories(prevalence)

# apply the region renaming function

incidence <- rename_regions_function(incidence)
prevalence <- rename_regions_function(prevalence)

# apply age band function &
# remove the old region column (gor9d)
incidence <- age_bands_function(incidence) %>% select(-gor9d)
prevalence <- age_bands_function(prevalence) %>% select(-gor9d)

cat_vars <- c("alcohol", 
              "obese_binary_flag", 
              "cancer", 
              "digestive_disorder",
              "hiv_aids", 
              "metabolic_disorder", 
              "kidney_disorder",
              "respiratory_disorder",
              "mental_behavioural_disorder",
              "CVD", 
              "musculoskeletal", 
              "neurological", 
              "bmi_category",
              "sex",
              "mh_history",
              "mh_outcome", 
              "ethnicity",
              "region",
              "age_groups",
              "hhsize",
              "work_status_new",
              "imd",
              "rural_urban",
              "self_isolating",
              "vaccination_status")

continuous_vars <- c('age')

if (nrow(incidence) > 0){
  incidence_cat_stats <- cov.dist.cat(vars = cat_vars, dataset = incidence, exposure = 'exposed')
  incidence_con_stats <- cov.dist.cont(vars = continuous_vars, dataset = incidence, exposure = 'exposed')
  write_csv(incidence_cat_stats, 'output/1_descriptives_incidence_cat.csv')
  write_csv(incidence_con_stats, 'output/2_descriptives_incidence_con.csv')
} else{
  write_csv(data.frame(1), 'output/1_descriptives_incidence_cat.csv')
  write_csv(data.frame(1), 'output/2_descriptives_incidence_con.csv')
}

if (nrow(prevalence) > 0){
  prevalence_cat_stats <- cov.dist.cat(vars = cat_vars, dataset = prevalence, exposure = 'exposed')
  prevalence_con_stats <- cov.dist.cont(vars = continuous_vars, dataset = prevalence, exposure = 'exposed')
  write_csv(prevalence_cat_stats, 'output/3_descriptives_prevalence_cat.csv')
  write_csv(prevalence_con_stats, 'output/4_descriptives_prevalence_con.csv')
} else{
  write_csv(data.frame(1), 'output/3_descriptives_prevalence_cat.csv')
  write_csv(data.frame(1), 'output/4_descriptives_prevalence_con.csv')
}
# bmi seperately as i had to filter out 0s

function_get_bmi_descriptives <- function(dataset){
 
  ds3 <- dataset %>% filter(exposed == 0)
  ds4 <- dataset %>% filter(exposed == 1)
  
  
  all <- dataset %>%  summarise(
    mean_bmi = mean(bmi[bmi > 0]),
    sd_bmi = sd(bmi[bmi>0]),
    variance_bmi = var(bmi[bmi>0]))
  
  all$type <- "all" 
  
  not_ex <- ds3 %>%  summarise(
    mean_bmi = mean(bmi[bmi > 0]),
    sd_bmi = sd(bmi[bmi>0]),
    variance_bmi = var(bmi[bmi>0]))
  
  not_ex$type <- "not exposed" 
  
  exposed <- ds4 %>%  summarise(
    mean_bmi = mean(bmi[bmi > 0]),
    sd_bmi = sd(bmi[bmi>0]),
    variance_bmi = var(bmi[bmi>0]))
  
  exposed$type <- "exposed" 
  
  bmi_desc <- rbind(all,not_ex,exposed) 

  return(bmi_desc)
}

incidence_bmi <- function_get_bmi_descriptives(incidence)
prevalence_bmi <- function_get_bmi_descriptives(prevalence)

#write_csv(incidence_bmi, 'output/incidence_cont_bmi_stats.csv')
#write_csv(prevalence_bmi, 'output/prevalence_cont_bmi_stats.csv')
