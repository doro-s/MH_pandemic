library(data.table)
library(purrr)
library(tidyverse)
options(datatable.fread.datatable=FALSE)


# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

dat <- fread('output/incidence_t.csv') 


### add a constant to obtain results not broken down (i.e. all participants)
dat$all <- "all"

### list domains to loop over
domains <- c("all",
             "age_groups",
             "alcohol",
             "obese_binary_flag",
             "cancer",
             "digestive_disorder",
             "hiv_aids",
             "mental_behavioural_disorder",
             "kidney_disorder",
             "respiratory_disorder",
             "metabolic_disorder",
             "sex",
             "ethnicity",
             "region",
             "hhsize",
             "work_status_new",
             "CVD",
             "musculoskeletal",
             "neurological",
             "imd",
             "rural_urban",
             "self_isolating_v1",
             "vaccination_status")

                         
### list exposures to loop over 
exposures <- c("all", "exposed") #our exposure of interest is all and our infected vs control

### list outcomes to loop over
outcomes <- c("mh_outcome") #check if we have anyother outcomes that i should list 

### set up empty lists for outputs 
out1 <- as.list(NULL)
out2 <- as.list(NULL)
out3 <- as.list(NULL)

for(k in 1:length(outcomes)){
  
  outcome <- outcomes[k]
  
  for(j in 1:length(exposures)){
   
     exposure <- exposures[j]
    
    for(i in 1:length(domains)){
      
      domain <- domains[i]
      
      ### calculate exposure time on 'per 1,000 person-years' basis
      dat$ptime <- dat$t/(365.25*1000)
      
      ### sum number of events by domain and exposure
      events <- aggregate(x=list(events=dat[[outcome]]==1),
                          by=list(level=dat[[domain]], exposure=dat[[exposure]]),
                          FUN=sum)
      
      ### sum person-time by domain and exposure 
      ptime <- aggregate(x=list(person_time=dat[["ptime"]]),
                         by=list(level=dat[[domain]], exposure=dat[[exposure]]),
                         FUN=sum)
      
      ### combine events and person-time
      comb <- merge(x=events, y=ptime, all=TRUE)
      comb$outcome <- outcome
      comb$domain <- domain
      comb <- comb[c(5:6,1:4)]
      
      out1[[i]] <- comb
 
      #print(i)     
    }
     
     df1 <- out1[[1]]
     if(length(domains)>1){
       for(i in 2:length(domains)) {df1 <- rbind(df1, out1[[i]])}
     }
     
     out2[[j]] <- df1
     
  }
  
  df2 <- out2[[1]]
  if(length(exposures)>1){
    for(j in 2:length(exposures)) {df2 <- rbind(df2, out2[[j]])}
  }
  
  out3[[k]] <- df2
  
}

df3 <- out3[[1]]
if(length(outcomes)>1){
  for(k in 2:length(outcomes)) {df3 <- rbind(df3, out3[[k]])}
}

### calculate event rates
df3$rate <- unlist(map2(df3$events,
                        df3$person_time,
                        ~poisson.test(.x,.y)$estimate))

### calculate Poisson CI - lower limit
df3$lcl <- unlist(map2(df3$events,
                       df3$person_time,
                       ~poisson.test(.x,.y)$conf.int[1]))

### calculate Poisson CI - upper limit
df3$ucl <- unlist(map2(df3$events,
                       df3$person_time,
                       ~poisson.test(.x,.y)$conf.int[2]))

### save result to working directory
write_csv(df3, 'output/event_counts_and_rates_incidence.csv')

