###########################################################################
#Purpose: Check distribution of the follow up time between the exposed 
#          and not-exposed groups
########################################################################### 
library(tidyverse)
library(survival)
library(survminer)
library(data.table)
library(broom)
library(splines)
library(gridExtra)
library(ggplot2)

options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

########################################################################### 
## Load data  
########################################################################### 

incidence <- fread('output/incidence_t.csv')
prevalence <- fread('output/prevalence_t.csv')

##rename exposed categories to present on the graph (need to be character,not numeric)

incidence <- incidence %>% 
  mutate(exposed = ifelse(exposed == 1, "exposed", "not exposed"))

prevalence <- prevalence %>% 
  mutate(exposed = ifelse(exposed == 1, "exposed", "not exposed"))

## Histogram by exposed status and save
# incidence

g1 <- ggplot(incidence, aes(x = t, fill = exposed, colour = exposed)) + 
  geom_histogram(alpha = 0.4, position = 'identity', bins=30) + 
  guides(fill = guide_legend(title = "Legend"),
         colour = guide_legend(title = "Legend"))

den1 <- ggplot(incidence, aes(x = t, fill = exposed, colour = exposed)) + 
  geom_density(alpha = 0.2, position = "identity") + 
  guides(fill = guide_legend(title = "Legend"),
         colour = guide_legend(title = "Legend"))

ggsave("output/distribution_of_follow_up_time_incidence.jpg", g1)
ggsave("output/distribution_of_follow_up_time_incidence_density.jpg", den1)


# prevalence
g2 <- ggplot(prevalence, aes(x = t, fill = exposed, colour = exposed)) +
  geom_histogram(alpha = 0.4, position = 'identity', bins=30) + 
  guides(fill = guide_legend(title = "Legend"),
         colour = guide_legend(title = "Legend"))

den2 <- ggplot(prevalence, aes(x = t, fill = exposed, colour = exposed)) + 
  geom_density(alpha = 0.2, position = "identity") + 
  guides(fill = guide_legend(title = "Legend"),
         colour = guide_legend(title = "Legend"))

ggsave("output/distribution_of_follow_up_time_prevalence.jpg", g2)
ggsave("output/distribution_of_follow_up_time_prevalence_density.jpg", den2)
