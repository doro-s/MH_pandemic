library(tidyverse)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

matched <- read_csv('output/matched_groups.csv')

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

# Remove groups based on historical evidence


# Write out adjusted groups
write_csv(matched, 'output/adjusted_groups.csv')

