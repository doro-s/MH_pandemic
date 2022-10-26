library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

source('analysis/cov_dist_cat.R')
source('analysis/cov_dist_cont.R')

incidence <- fread('output/adjusted_incidence_group.csv')
prevalence <- fread('output/adjusted_prevalence_group.csv')

# Need to read in matched person level data
# Only need to consider participants characteristics at the index date
# 100% of cases and 0% controls should have result_mk == 1

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

incidence <- create_bmi_categories(incidence)
prevalence <- create_bmi_categories(prevalence)

cat_vars <- c("alcohol", "obese_binary_flag", "cancer", "digestive_disorder",
              "hiv_aids", "metabolic_disorder", "kidney_disorder",
              "respiratory_disorder", "CVD", "musculoskeletal", 
              "neurological", "bmi_category", "sex",
              "cmd_history", "cmd_history_hospital",
              "smi_history", "smi_history_hospital",
              "self_harm_history", "self_harm_history_hospital",
              "mh_outcome")

continuous_vars <- c('age') #Luke originally put BMI here, but we created a categorical bmi variable instead

if (nrow(incidence) > 0){
  incidence_cat_stats <- cov.dist.cat(vars = cat_vars, dataset = incidence, exposure = 'exposed')
  incidence_con_stats <- cov.dist.cont(vars = continuous_vars, dataset = incidence, exposure = 'exposed')
  write_csv(incidence_cat_stats, 'output/incidence_cat_stats.csv')
  write_csv(incidence_con_stats, 'output/incidence_con_stats.csv')
} else{
  write_csv(data.frame(1), 'output/incidence_cat_stats.csv')
  write_csv(data.frame(1), 'output/incidence_con_stats.csv')
}

if (nrow(prevalence) > 0){
  prevalence_cat_stats <- cov.dist.cat(vars = cat_vars, dataset = prevalence, exposure = 'exposed')
  prevalence_con_stats <- cov.dist.cont(vars = continuous_vars, dataset = prevalence, exposure = 'exposed')
  write_csv(prevalence_cat_stats, 'output/prevalence_cat_stats.csv')
  write_csv(prevalence_con_stats, 'output/prevalence_con_stats.csv')
} else{
  write_csv(data.frame(1), 'output/prevalence_cat_stats.csv')
  write_csv(data.frame(1), 'output/prevalence_con_stats.csv')
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

write_csv(incidence_bmi, 'output/incidence_cont_bmi_stats.csv')
write_csv(prevalence_bmi, 'output/prevalence_cont_bmi_stats.csv')

#abs_std_diff <- abs((mu1 - mu0) / sqrt((var1 + var0) / 2))


# TODO - calculates incidence of common mental disorders (outcomes).
# Rate per 1000 person-years

# Poisson.test - to see rate with CIs
