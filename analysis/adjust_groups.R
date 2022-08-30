library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

matched <- fread('output/matched_groups.csv')

# Get some summary stats for number of exposed and controls
print('Number of exposed')
matched %>% filter(exposed == 1) %>% nrow()

print('Number of controls')
matched %>% filter(exposed == 0) %>%  nrow()

# For date outcome variables, add binary flag for convenience
matched <- matched %>% 
  mutate(cmd_outcome = ifelse(cmd_outcome_date != '2100-01-01', 1, 0),
         cmd_outcome_hospital = ifelse(cmd_outcome_date_hospital != '2100-01-01', 1, 0),
         smi_outcome = ifelse(smi_outcome_date != '2100-01-01', 1, 0),
         smi_outcome_hospital = ifelse(smi_outcome_date_hospital != '2100-01-01', 1, 0),
         self_harm_outcome = ifelse(self_harm_outcome_date != '2100-01-01', 1, 0),
         self_harm_outcome_hospital = ifelse(self_harm_outcome_date_hospital != '2100-01-01', 1, 0))

print('Pre-splitting counts:')
print('cmd outcome')
matched %>% pull(cmd_outcome) %>% table()
print('cmd outcome hospital')
matched %>% pull(cmd_outcome_hospital) %>% table()
print('smi outcome')
matched %>% pull(smi_outcome) %>% table()
print('smi outcome hospital')
matched %>% pull(smi_outcome_hospital) %>% table()
print('self harm outcome')
matched %>% pull(self_harm_outcome) %>% table()
print('self harm outcome hospital')
matched %>% pull(self_harm_outcome_hospital) %>% table()


# Create weights for groups
# weights for controls (1/n) where n controls in matching group
# Convert weight back to 1 for exposed people
matched <- matched %>% 
  group_by(group_id) %>% 
  mutate(weight = 1/(n()-1)) %>% 
  ungroup() %>% 
  mutate(weight = ifelse(exposed == 1, 1, weight))


# 3 groups of outcome

### (1) Incidence group (new onset) ###
# No history of mental illness (in entire group)

incidence <- matched %>% 
  mutate(mh_history_any = ifelse(cmd_history == 1 | cmd_history_hospital == 1 |
                             smi_history == 1 | smi_history_hospital == 1 |
                             self_harm_history == 1 | self_harm_history_hospital == 1, 1, 0)) %>% 
  group_by(group_id) %>% 
  mutate(group_mh_history = max(mh_history_any)) %>% 
  ungroup() %>% 
  filter(group_mh_history == 0) %>% 
  select(-mh_history_any, -group_mh_history)

print('size of incidence group')
print(nrow(incidence))

write_csv(incidence, 'output/incidence_group.csv')


### (2) Prevalence group ###
# Everyone in the groups needs to have some form of MH history
prevalence <- matched %>% 
  mutate(mh_history_any = ifelse(cmd_history == 1 | cmd_history_hospital == 1 |
                                   smi_history == 1 | smi_history_hospital == 1 |
                                   self_harm_history == 1 | self_harm_history_hospital == 1, 1, 0)) %>%
  group_by(group_id) %>% 
  mutate(group_mh_history = max(mh_history_any)) %>% 
  ungroup() %>% 
  filter(group_mh_history == 1) %>% 
  select(-mh_history_any, -group_mh_history)

print('size of prevalence group')
print(nrow(prevalence))

write_csv(prevalence, 'output/prevalence_group.csv')


### (3) Exacerbation group ###
# Those with a cmd history (non-hospitalisation) only
# who have any hospitalisation as outcome or smi/self harm

# Keep groups where EVERYONE has cmd history only (non hospitalisation)
exac <- matched %>% 
  mutate(cmd_history_only = ifelse(cmd_history == 1 & cmd_history_hospital == 0 &
                                   smi_history == 0 & smi_history_hospital == 0 &
                                   self_harm_history == 0 & self_harm_history_hospital == 0, 1, 0)) %>%
  group_by(group_id) %>% 
  mutate(group_cmd_history = sum(cmd_history_only),
         group_size = n()) %>%
  ungroup() %>% 
  filter(group_cmd_history == group_size) %>% 
  select(-cmd_history_only, -group_cmd_history, -group_size)

print('size of exacerbated group')
print(nrow(exac))

write_csv(exac, 'output/exacerbated_group.csv')
