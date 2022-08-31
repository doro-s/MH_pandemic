library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

incidence <- fread('output/incidence_group.csv') %>% 
  mutate(group = 'incidence')
prevalence <- fread('output/prevalence_group.csv') %>% 
  mutate(group = 'prevalence')
exac <- fread('output/exacerbated_group.csv') %>% 
  mutate(group = 'exacerbated')

# Get some summary stats for number of exposed and controls
count_exposed_and_control <- function(df){
  print('Number of exposed')
  df %>% filter(exposed == 1) %>% nrow() %>% print()
  print('Number of controls')
  df %>% filter(exposed == 0) %>%  nrow() %>% print()
}

print('counts for incidence group')
count_exposed_and_control(incidence)

print('counts for prevalence group')
count_exposed_and_control(prevalence)

print('counts for exacerbated group')
count_exposed_and_control(exac)

# Temporary rbind() together for convenience
matched <- rbind(incidence, rbind(prevalence, exac))

# For date outcome variables, add binary flag for convenience
matched <- matched %>% 
  mutate(cmd_outcome = ifelse(cmd_outcome_date != '2100-01-01', 1, 0),
         cmd_outcome_hospital = ifelse(cmd_outcome_date_hospital != '2100-01-01', 1, 0),
         smi_outcome = ifelse(smi_outcome_date != '2100-01-01', 1, 0),
         smi_outcome_hospital = ifelse(smi_outcome_date_hospital != '2100-01-01', 1, 0),
         self_harm_outcome = ifelse(self_harm_outcome_date != '2100-01-01', 1, 0),
         self_harm_outcome_hospital = ifelse(self_harm_outcome_date_hospital != '2100-01-01', 1, 0))

# Create weights for groups
# weights for controls (1/n) where n controls in matching group
# Convert weight back to 1 for exposed people
matched <- matched %>% 
  group_by(group, group_id) %>% 
  mutate(weight = 1/(n()-1)) %>% 
  ungroup() %>% 
  mutate(weight = ifelse(exposed == 1, 1, weight))

# Split back out into the three groups
incidence <- matched %>% filter(group == 'incidence')
prevalence <- matched %>% filter(group == 'prevalence')
exac <- matched %>% filter(group == 'exacerbated')

rm(matched)

count_outcomes <- function(df){
  
  print('Pre-splitting history counts:')
  print('cmd outcome')
  df %>% pull(cmd_history) %>% table() %>% print()
  print('cmd history hospital')
  df %>% pull(cmd_history_hospital) %>% table() %>% print()
  print('smi history')
  df %>% pull(smi_history) %>% table() %>% print()
  print('smi history hospital')
  df %>% pull(smi_history_hospital) %>% table() %>% print()
  print('self harm history')
  df %>% pull(self_harm_history) %>% table() %>% print()
  print('self harm history hospital')
  df %>% pull(self_harm_history_hospital) %>% table() %>% print()
  
  
  print('Pre-splitting outcome counts:')
  print('cmd outcome')
  df %>% pull(cmd_outcome) %>% table() %>% print()
  print('cmd outcome hospital')
  df %>% pull(cmd_outcome_hospital) %>% table() %>% print()
  print('smi outcome')
  df %>% pull(smi_outcome) %>% table() %>% print()
  print('smi outcome hospital')
  df %>% pull(smi_outcome_hospital) %>% table() %>% print()
  print('self harm outcome')
  df %>% pull(self_harm_outcome) %>% table() %>% print()
  print('self harm outcome hospital')
  df %>% pull(self_harm_outcome_hospital) %>% table() %>% print()
  
}


print('counting history & outcomes for incidence')
count_outcomes(incidence)
print('counting history & outcomes for prevalence')
count_outcomes(prevalence)
print('counting history & outcomes for exacerbated')
count_outcomes(exac)


write_csv(incidence, 'output/adjusted_incidence_group.csv')
write_csv(prevalence, 'outputadjusted_/prevalence_group.csv')
write_csv(exac, 'output/adjusted_exacerbated_group.csv')
