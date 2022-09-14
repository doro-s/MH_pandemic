library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

# Read in exposed population
exposed <- fread('output/cis_exposed.csv') %>% 
  mutate(exposed = 1)

# Read in control population
control <- fread('output/cis_control.csv') %>% 
  mutate(exposed = 0)

# Temporary rbind() while type of outcome is determined
population <- rbind(exposed, control)


# 3 types of outcome

### (1) Incidence group (new onset) ###
# No history of mental illness

incidence <- population %>% 
  mutate(mh_history = ifelse(cmd_history == 1 | cmd_history_hospital == 1 |
                               smi_history == 1 | smi_history_hospital == 1 |
                               self_harm_history == 1 | self_harm_history_hospital == 1, 1, 0)) %>% 
  filter(mh_history == 0) %>% 
  select(-mh_history)

incidence_exposed <- incidence %>% 
  filter(exposed == 1)

incidence_control <- incidence %>% 
  filter(exposed == 0)


### (2) Prevalence group ###
# Needs to have some form of MH history
prevalence <- population %>% 
  mutate(mh_history = ifelse(cmd_history == 1 | cmd_history_hospital == 1 |
                                   smi_history == 1 | smi_history_hospital == 1 |
                                   self_harm_history == 1 | self_harm_history_hospital == 1, 1, 0)) %>%
  filter(mh_history == 1) %>% 
  select(-mh_history)

prevalence_exposed <- prevalence %>% 
  filter(exposed == 1)

prevalence_control <- prevalence %>% 
  filter(exposed == 0)


### (3) Exacerbation group ###
# Those with a cmd history (non-hospitalisation) only
exac <- population %>% 
  mutate(cmd_history_only = ifelse(cmd_history == 1 & cmd_history_hospital == 0 &
                                     smi_history == 0 & smi_history_hospital == 0 &
                                     self_harm_history == 0 & self_harm_history_hospital == 0, 1, 0)) %>%
  filter(cmd_history_only == 1) %>% 
  select(-cmd_history_only)

exac_exposed <- exac %>% 
  filter(exposed == 1)

exac_control <- exac %>% 
  filter(exposed == 0)


# Clean up memory
rm(exposed, control, population, incidence, prevalence, exac)
gc()


# Print information to log
print('size of pre matched incidence controls')
nrow(incidence_control)
print('size of pre matched incidence exposed')
nrow(incidence_exposed)

print('size of pre matched prevalence controls')
nrow(prevalence_control)
print('size of pre matched prevalence exposed')
nrow(prevalence_exposed)

print('size of pre matched exacerbated controls')
nrow(exac_control)
print('size of pre matched exacerbated exposed')
nrow(exac_exposed)


# Function to perform matching
match_exposed_to_controls <- function(exposed, control, N){
  
  # Randomly order exposed population and initialise group id
  exposed <- slice_sample(exposed, n=nrow(exposed), replace=FALSE) %>%
    mutate(group_id = -1)
  
  # Initialise group_id in full control population
  control <- control %>%
    mutate(group_id = -1,
           visit_date_flag = 0)
  
  # Make copy of controls that can be reduced iteratively
  # Initialise flag for already used as controls
  control_reduced <- control %>% 
    mutate(already_used = 0)
  
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
    visit_date_min <- as.IDate(as.Date(date_pos_exposed) - 14)
    visit_date_max <- as.IDate(as.Date(date_pos_exposed) + 14)
    
    # Filter CIS based on min and max dates,
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
    
    # SELECT N PEOPLE FIRST FROM VISIT LEVEL DATA, THEN GET CLOSEST VISIT 
    # DATE PER PERSON
    control_ids <- unique(temp$patient_id)
    
    if (length(control_ids) < N){
      # pass
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
             t_to_origin = abs(as.numeric(as.Date(date_pos_exposed) - as.Date(visit_date)))) %>%
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
  
  # Assemble final matched dataset
  control <- control %>% 
    filter(visit_date_flag == 1) %>% 
    select(-visit_date_flag)
  
  groups <- rbind(control, exposed) %>% 
    filter(group_id != -1)
  
  return(groups)
}


# Run matching
incidence_group <- match_exposed_to_controls(incidence_exposed, incidence_control, 5)
prevalence_group <- match_exposed_to_controls(prevalence_exposed, prevalence_control, 5)
exac_group <- match_exposed_to_controls(exac_exposed, exac_control, 5)

print('total size of post matched incidence population')
nrow(incidence_group)
print('total size of post matched prevalence population')
nrow(prevalence_group)
print('total size of post matched exacerbated population')
nrow(exac_group)


# Save groups
write_csv(incidence_group, 'output/incidence_group.csv')
write_csv(prevalence_group, 'output/prevalence_group.csv')
write_csv(exac_group, 'output/exacerbated_group.csv')
