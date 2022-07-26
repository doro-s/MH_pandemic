library(tidyverse)

# (dirname(rstudioapi::getActiveDocumentContext()$path))

# Read in exposed population
exposed <- read_csv('output/cis_exposed.csv')

# Bring cis dates into memory #################### this data is wrong - 10x too many visits
control <- read_csv('output/cis_control.csv')

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


# Create data structure to store matching results
n <- nrow(exposed)
groups <- data.frame(matching_group = 1:n,
                     exposed = character(n),
                     index_date_exposed = rep(as.Date('2100-01-01'), n),
                     end_date_exposed = rep(as.Date('2100-01-01'), n),
                     stringsAsFactors = FALSE)

for (i in 1:N){
  var <- paste0('control_', i)
  groups[var] <- character(n)
  var <- paste0('index_date_control_', i)
  groups[var] <- as.Date('2100-01-01')
  var <- paste0('end_date_control_', i)
  groups[var] <- as.Date('2100-01-01')
}


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
  date_pos_exposed <- row$min_pos_covid[1]
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
    print('No controls found')
    next
  }
  
  # SELECT 5 PEOPLE FIRST FROM VISIT LEVEL DATA, THEN GET CLOSEST VISIT 
  # DATE PER PERSON
  control_ids <- unique(temp$patient_id)
  
  if (length(control_ids) < N){
    print(paste0('Fewer than ', N, ' controls found - taking maximum'))
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
  
  # Add to groups table
  groups$exposed[i] <- id_pos_exposed
  groups$index_date_exposed[i] <- date_pos_exposed
  groups$end_date_exposed[i] <- end_date_exposed
  for (j in 1:nrow(temp)){
    var <- paste0('control_', j)
    groups[[var]][i] <- temp$patient_id[j]
    var <- paste0('index_date_control_', j)
    groups[[var]][i] <- temp$visit_date[j]
    var <- paste0('end_date_control_', j)
    groups[[var]][i] <- temp$end_date[j]
  }
  
  # Remove the selected control(s) from the population
  # (cannot be a control for someone else)  
  exposed <- exposed %>%
    mutate(group_id = ifelse(patient_id %in% id_pos_exposed, i, group_id))
  
  control_reduced <- control_reduced %>% 
    mutate(already_used = ifelse(patient_id %in% control_ids, 1, already_used))
  
  control <- control %>%
    mutate(group_id = ifelse(patient_id %in% control_ids, i, group_id))
  
  for (i in nrow(temp)){
    id <- temp$patient_id[i]
    v_date <- temp$visit_date[i]
    control <- control %>% 
      mutate(visit_date_flag = ifelse(patient_id == id & visit_date == v_date, 1, 0))
  }
  
  # Remove from visit level population
  control_reduced <- control_reduced %>%
    filter(already_used == 0)
  
}



## Reformat table into 1 row per person (CIS ID/NHS number) ##

flags <- control %>%
  select(patient_id) %>%
  distinct(patient_id, .keep_all = TRUE) %>%
  mutate(group_exposed = -1,
         group_control = -1,
         index_date_exposed = as.Date('2100-01-01'),
         index_date_control = as.Date('2100-01-01'),
         end_date_exposed = as.Date('2100-01-01'),
         end_date_control = as.Date('2100-01-01'))

# For every group, populate placeholder
for (i in 1:nrow(groups)){

  row <- groups[i, ]

  # Get exposed person info
  exposed_id <- row$exposed[1]
  index_date_exp <- row$index_date_exposed[1]
  end_date_exp <- row$end_date_exposed[1]

  # Populate exposed person
  flags <- flags %>%
    mutate(group_exposed = ifelse(patient_id == exposed_id, i, group_exposed),
           index_date_exposed = if_else(patient_id == exposed_id, index_date_exp, index_date_exposed),
           end_date_exposed = if_else(patient_id == exposed_id, end_date_exp, end_date_exposed))

  # Loop through all available controls
  # and populate control rows
  for (j in 1:N){
    # Get exposed person info
    var <- paste0('control_', j)
    control_id <- row[[var]][1]
    # Stop looping through controls if none left
    if (is.na(control_id)){
      print('yes')
      break
    }
    var <- paste0('index_date_control_', j)
    index_date_con <- row[[var]][1]
    var <- paste0('end_date_control_', j)
    end_date_con <- row[[var]][1]

    # Populate control person
    flags <- flags %>%
      mutate(group_control = ifelse(patient_id == control_id, i, group_control),
             index_date_control = if_else(patient_id == control_id, index_date_con, index_date_control),
             end_date_control = if_else(patient_id == control_id, end_date_con, end_date_control))

  }

}

# Save flags
write_csv(flags, 'output/group_flags.csv')
