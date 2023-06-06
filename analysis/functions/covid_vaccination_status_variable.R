# This function creates a vaccination_status variable
# 1. Create temporary index date which will be moved back by 14 days
# to allow at least 14 days for the vaccine to become effective. If vaccine 
# happened after index date or within the 14 days prior to index date then
# replace the date with NA (unvaccinated before infection).
# 2. Change index date & all of the covid_vaccine variables to numeric
# 3. Calculate sum of all valid vaccines in period per person
# 4. Calculate the difference between index date and latest covid vaccine in days
# 5. Return the data 
 

#Function

covid_vaccine_function <- function(data){
  #data1 <- fread('output/adjusted_incidence_group.csv')
  
  data1 <- data %>%
    mutate(index_date = ifelse(exposed == 1, date_positive, visit_date)) %>%
    mutate(index_date = as.IDate(index_date))
  
  # Change index_dates to numeric and covid vaccine dates
  data1$index_numeric <- as.numeric(data1$index_date) 
  data1$temp_index_date_14 <- data1$index_numeric - 14  

  data1$first_vaccine <- as.numeric(data1$covid_vacc_date) 
  data1$second_vaccine <- as.numeric(data1$covid_vacc_second_dose_date) 
  data1$booster3_vaccine <- as.numeric(data1$covid_vacc_third_dose_date) 
  data1$booster4_vaccine <- as.numeric(data1$covid_vacc_fourth_dose_date) 



  ## first step would be to make sure we only keep the vaccine dates that happened 
  ###  at least 14 days prior to the infection
  # 1. Put NA when vaccine date is after infection 

  data1 <- data1 %>% 
    mutate(first_vaccine = ifelse(!is.na(first_vaccine) & first_vaccine <= temp_index_date_14,
                                  first_vaccine, 0),
         
                    second_vaccine = ifelse(!is.na(second_vaccine) & second_vaccine <= temp_index_date_14,
                                  second_vaccine, 0),
           
         booster3_vaccine = ifelse(!is.na(booster3_vaccine) & booster3_vaccine <= temp_index_date_14,
                                   booster3_vaccine, 0),
         
         booster4_vaccine = ifelse(!is.na(booster4_vaccine) & booster4_vaccine <= temp_index_date_14,
                                    booster4_vaccine, 0))

    data1 <- data1 %>% 
      mutate(first_vaccine_v1 = ifelse(first_vaccine == 0, 0, 1),
             second_vaccine_v1 =  ifelse(second_vaccine == 0, 0, 1),
             booster3_vaccine_v1 =  ifelse(booster3_vaccine == 0, 0, 1),
             booster4_vaccine_v1 =  ifelse(booster4_vaccine == 0, 0, 1))

    # column with number of vaccines they had 
    data1$sum_of_vaccines <- rowSums(data1[, c("first_vaccine_v1",
                                             "second_vaccine_v1",
                                             "booster3_vaccine_v1", 
                                             "booster4_vaccine_v1")]) 

    # calculate number of days since the latest vaccine status

    data1 <- data1 %>% 
      #select the latest date
      mutate(latest_covid_vacc_date = pmax(first_vaccine, second_vaccine)) %>%
      mutate(latest_covid_vacc_date = pmax(latest_covid_vacc_date, booster3_vaccine)) %>%
      mutate(latest_covid_vacc_date = pmax(latest_covid_vacc_date, booster4_vaccine)) %>%
      
      #difference between latest_covid_vacc_date and index_date
      mutate(days_since_latest_vaccine = 
               ifelse(latest_covid_vacc_date == 0,0, index_numeric - latest_covid_vacc_date))

    # based on the new variable calculate categorical data on vaccine 
    data1 <- data1 %>% mutate(vaccination_status = 
                                case_when(sum_of_vaccines == 0 ~ "Unvaccinated when infected",
                                          sum_of_vaccines == 1 ~ "One dose at least 14 days before infection",
                                          sum_of_vaccines >= 2 & 
                                            days_since_latest_vaccine <= 89 ~ "At least two doses 14 to 89 days before infection",
                                          sum_of_vaccines >= 2 & 
                                            days_since_latest_vaccine >= 90 & 
                                            days_since_latest_vaccine <= 179 ~ "At least two doses 90 to 179 days before infection",
                                          sum_of_vaccines >= 2 & 
                                            days_since_latest_vaccine >= 180 & 
                                            days_since_latest_vaccine <= 269 ~ "At least two doses 180 to 269 days before infection",
                                          sum_of_vaccines >= 2 & 
                                            days_since_latest_vaccine >= 270 ~ "At least two doses 270 days or more before infection",
                                          TRUE ~ 'Mistake'))


    # delete all the temporary columns that we do not need any more
    data1 <- data1 %>% select(-first_vaccine_v1, 
                              -second_vaccine_v1, 
                              #-temp_index_date_14,
                              -booster3_vaccine_v1,
                              -booster4_vaccine_v1)

    
    return(data1)
    }


