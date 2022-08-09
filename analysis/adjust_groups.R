library(tidyverse)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

matched <- read_csv('output/matched_groups.csv', guess_max = 100000)

# Get some summary stats for number of exposed and controls
print('Number of exposed')
matched %>% filter(exposed == 1) %>% nrow()

print('Number of controls')
matched %>% filter(exposed == 0) %>%  nrow()

if (sum(is.na(matched$mental_disorder_outcome_date)) == nrow(matched)){
  matched <- matched %>% 
    mutate(mental_disorder_outcome_date = as.Date(2100-01-01))
}

matched <- matched %>% 
  mutate(mental_disorder_outcome_date = if_else(is.na(mental_disorder_outcome_date), as.Date('2100-01-01'), mental_disorder_outcome_date))

# Create weights for groups
# weights for controls (1/n) where n controls in matching group
# Convert weight back to 1 for exposed people
matched <- matched %>% 
  group_by(group_id) %>% 
  mutate(weight = 1/(n()-1)) %>% 
  ungroup() %>% 
  mutate(weight = ifelse(exposed == 1, 1, weight))

# For new onset of mental health, if ANYONE in matching group has 
# mental health history, remove entire group
# include hospitalisation due to mental health - looking for any historical
# evidence in history

# Create new onset flag for mental disorder
matched <- matched %>% 
  mutate(mental_disorder_outcome = ifelse(mental_disorder_outcome_date != '2100-01-01', 1, 0),
         md_new_onset = ifelse(mental_disorder_history == 0 & mental_disorder_outcome == 1, 1, 0))

# For new onset, remove groups based on historical evidence of 
# mental disorder, including hospitalisation

# DO I NEED TO APPLY THIS TO ALL CASES WHERE MD OUTCOME == 1, NOT JUST NEW ONSET?
matched <- matched %>% 
  group_by(group_id) %>% 
  mutate(md_history_group = sum(mental_disorder_history) + sum(mental_disorder_hospital),
         md_new_onset_group = sum(md_new_onset),
         remove_group = ifelse(md_new_onset_group > 0 & md_history_group > 0, 1, 0)) %>% 
  ungroup() %>% 
  filter(remove_group == 0) %>% 
  select(-md_history_group, -md_new_onset_group, -remove_group, -md_new_onset)


# Derive time to outcome
matched <- matched %>% 
  mutate(t = ifelse(mental_disorder_outcome_date == '2100-01-01', 
                    end_date - visit_date,
                    mental_disorder_outcome_date - visit_date))

# Get some summary stats for number of exposed and controls (how many have been lost?)
print('Number of exposed')
matched %>% filter(exposed == 1) %>% nrow()

print('Number of controls')
matched %>% filter(exposed == 0) %>%  nrow()


# Write out adjusted groups
write_csv(matched, 'output/adjusted_groups.csv')

