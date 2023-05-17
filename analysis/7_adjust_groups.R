library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

incidence <- fread('output/incidence_group.csv') %>% 
  mutate(group = 'incidence')
prevalence <- fread('output/prevalence_group.csv') %>% 
  mutate(group = 'prevalence')

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

# Temporary rbind() together for convenience
matched <- rbind(incidence, prevalence)

# For date outcome variables, add binary flag for convenience
matched <- matched %>% 
  mutate(cmd_outcome = ifelse(cmd_outcome_date != '2100-01-01', 1, 0),
         cmd_outcome_hospital = ifelse(cmd_outcome_date_hospital != '2100-01-01', 1, 0),
         smi_outcome = ifelse(smi_outcome_date != '2100-01-01', 1, 0),
         smi_outcome_hospital = ifelse(smi_outcome_date_hospital != '2100-01-01', 1, 0),
         self_harm_outcome = ifelse(self_harm_outcome_date != '2100-01-01', 1, 0),
         self_harm_outcome_hospital = ifelse(self_harm_outcome_date_hospital != '2100-01-01', 1, 0),
         other_mood_disorder_hospital_outcome = ifelse(other_mood_disorder_hospital_outcome_date != '2100-01-01', 1, 0),
         other_mood_disorder_diagnosis_outcome = ifelse(other_mood_disorder_diagnosis_outcome_date != '2100-01-01', 1, 0))

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
  print('other mood disorder hospital history')
  df %>% pull(other_mood_disorder_hospital_history) %>% table() %>% print()
  print('other mood disorder diagnosis history')
  df %>% pull(other_mood_disorder_diagnosis_history) %>% table() %>% print()
  
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
  print('other mood disorder hospital history')
  df %>% pull(other_mood_disorder_hospital_outcome) %>% table() %>% print()
  print('other mood disorder diagnosis history')
  df %>% pull(other_mood_disorder_diagnosis_outcome) %>% table() %>% print()
  
}


print('counting history & outcomes for incidence')
count_outcomes(incidence)
print('counting history & outcomes for prevalence')
count_outcomes(prevalence)

# At this point exacerbation group has so few outcome counts of cmd hosp, 
# smi or self harm that analysis cannot be performed on this group

# For incidence and prevalence groups - group outcome into mh_outcome
# same for mental health history -> mh_history

group_outcomes_history <- function(df){
  
  df <- df %>% 
    mutate(mh_outcome = pmax(cmd_outcome,
                             cmd_outcome_hospital,
                             smi_outcome, 
                             smi_outcome_hospital,
                             self_harm_outcome, 
                             self_harm_outcome_hospital,
                             other_mood_disorder_hospital_outcome,
                             other_mood_disorder_diagnosis_outcome)) %>% 
    
    mutate(mh_history = pmax(cmd_history,
                             cmd_history_hospital,
                             smi_history,
                             smi_history_hospital,
                             self_harm_history,
                             self_harm_history_hospital,
                             other_mood_disorder_hospital_history,
                             other_mood_disorder_diagnosis_history)) %>%
    select(-cmd_outcome, 
           -cmd_outcome_hospital,
           -smi_outcome, 
           -smi_outcome_hospital,
           -self_harm_outcome, 
           -self_harm_outcome_hospital,
           -other_mood_disorder_hospital_outcome,
           -other_mood_disorder_diagnosis_outcome,
           -cmd_history,
           -cmd_history_hospital,
           -smi_history,
           -smi_history_hospital,
           -self_harm_history,
           -self_harm_history_hospital,
           -other_mood_disorder_hospital_history,
           -other_mood_disorder_diagnosis_history)
  
  return(df)
}

incidence <- group_outcomes_history(incidence)
prevalence <- group_outcomes_history(prevalence)

write_csv(incidence, 'output/adjusted_incidence_group.csv')
write_csv(prevalence, 'output/adjusted_prevalence_group.csv')

#it should be 6 per group as 1 exposed & 5 controls 

incidence2 <- incidence %>% 
  #create new cols for year and month
  mutate(year = year(date_positive)) %>%
  mutate(month = month(date_positive))%>%
  group_by(group_id) %>% mutate(count = n()) %>% 
  ungroup()%>% select(year,month,group_id,count) %>% print(n=1000)



#mean_matches_by_month_and_year
means <- incidence2 %>% 
  group_by(year,month) %>%   
  mutate(mean = mean(count)) %>% select(year,month,mean) 

print('AVERAGE NUMBER OF MATCHED CONTROLS PER MONTH PER YEAR') 
means %>% distinct(year, month, .keep_all = TRUE) %>% arrange(year, month) %>%
  print(n=100)