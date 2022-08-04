library(tidyverse)

# (dirname(rstudioapi::getActiveDocumentContext()$path))

# Read in exposed population
exposed <- read_csv('output/cis_exposed.csv', guess_max = 100000)

# Bring cis dates into memory #################### this data is wrong - 10x too many visits
control <- read_csv('output/cis_control.csv', guess_max = 100000) %>% 
  mutate(visit_date_flag = 0)

# Make copy of cis dates that can be reduced
control_reduced <- control %>% 
  mutate(already_used = 0)

# 'already_used' flag, initialise to 0
# group_id, initialise to -1
control <- control %>%
  mutate(group_id = -1)

# Randomly order exposed population
exposed <- slice_sample(exposed, n=nrow(exposed), replace=FALSE) %>%
  mutate(group_id = -1)


# Define max number of controls
N <- 5


# Run the matching
for (i in 1:nrow(exposed)){
  
  if (i %% 10 == 0){
    print(i)
  }
  
  row <- exposed[i, ]
  
  # Get participant id of exposed person
  id_pos_exposed <- row$patient_id[1]
  
  # Get end date of exposed person
  end_date_exposed <- row$end_date[1]
  
  # Get min and max dates based on date_positive
  date_pos_exposed <- row$date_positive[1]
  visit_date_min <- date_pos_exposed - 14
  visit_date_max <- date_pos_exposed + 14
  
  # Filter cis based on min and max dates,
  # negative visit, and whether they are already a 
  # control for someone else
  temp <- control_reduced %>%
    filter(result_mk == 0,
           visit_date >= visit_date_min,
           visit_date <= visit_date_max) %>%
    select(-result_mk)
  
  # Add in logic to ensure that no one can be their 
  # own control case
  temp <- temp %>%
    filter(patient_id != id_pos_exposed)
  
  # Remove anyone with evidence of infection
  # across all sources prior to exposed infection date
  temp <- temp %>%
    filter(date_positive > date_pos_exposed)
  
  # If no controls, move on to next exposed person
  if (nrow(temp) == 0){
    # print('No controls found')
    next
  }
  
  # SELECT 5 PEOPLE FIRST FROM VISIT LEVEL DATA, THEN GET CLOSEST VISIT 
  # DATE PER PERSON
  control_ids <- unique(temp$patient_id)
  
  if (length(control_ids) < N){
    # print(paste0('Fewer than ', N, ' controls found - taking maximum'))
    print(length(control_ids))
  }
  else{
    control_ids <- sample(control_ids, N, replace = FALSE)
  }
  
  temp <- temp %>%
    filter(patient_id %in% control_ids)
  
  # Convert control to person level
  # Take visit closest to +ve case in exposed group
  # Also handle multiple visits on same day per person
  temp <- temp %>%
    mutate(row_id = 1:nrow(temp),
           t_to_origin = abs(as.numeric(date_pos_exposed - visit_date))) %>%
    group_by(patient_id) %>%
    filter(t_to_origin == min(t_to_origin)) %>%
    filter(row_id == min(row_id)) %>%
    select(-t_to_origin, -row_id) %>%
    ungroup()
  
  # Assign group id to exposed person
  exposed <- exposed %>%
    mutate(group_id = ifelse(patient_id %in% id_pos_exposed, i, group_id))
  
  # Remove the selected control(s) from the population 
  # (cannot be a control for someone else) 
  control_reduced <- control_reduced %>% 
    mutate(already_used = ifelse(patient_id %in% control_ids, 1, already_used))
  
  # Assign group id to controls
  control <- control %>%
    mutate(group_id = ifelse(patient_id %in% control_ids, i, group_id))
  
  # Adjust visit date flag so we know which row to take from visit level controls
  for (i in 1:nrow(temp)){
    id <- temp$patient_id[i]
    v_date <- temp$visit_date[i]
    control <- control %>% 
      mutate(visit_date_flag = ifelse(patient_id == id & visit_date == v_date, 1, visit_date_flag))
  }
  
  # Remove from visit level population
  control_reduced <- control_reduced %>%
    filter(already_used == 0)
  
}


rm(temp, control_reduced, row)

control <- control %>% 
  filter(visit_date_flag == 1) %>% 
  mutate(exposed = 0) %>% 
  select(-visit_date_flag)

exposed <- exposed %>% 
  mutate(exposed = 1)

groups <- rbind(control, exposed) %>% 
  filter(group_id != -1)

# Create overweight flag
groups <- groups %>% 
  mutate(overweight = ifelse(bmi >= 25, 1, 0))


# Save flags
write_csv(groups, 'output/matched_groups.csv')
