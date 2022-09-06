library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

incidence <- fread('output/adjusted_incidence_group.csv')
prevalence <- fread('output/adjusted_prevalence_group.csv')

eos_date <- as.IDate('2021-09-30')

# Derive t for outcomes
derive_t <- function(df){
  
  df <- df %>% 
    mutate(min_outcome_date_cmd = cmd_outcome_date,
           min_outcome_date_other = pmin(cmd_outcome_date_hospital,
                                         smi_outcome_date, smi_outcome_date_hospital,
                                         self_harm_outcome_date, self_harm_outcome_date_hospital)) %>% 
    mutate(min_outcome_date_cmd = fifelse(min_outcome_date_cmd == '2100-01-01', eos_date, min_outcome_date_cmd),
           min_outcome_date_other = fifelse(min_outcome_date_other == '2100-01-01', eos_date, min_outcome_date_other)) %>% 
    mutate(t_cmd = fifelse(min_outcome_date_cmd == '2021-09-30', 
                           end_date - visit_date, 
                           min_outcome_date_cmd - visit_date),
           t_other = fifelse(min_outcome_date_other == '2021-09-30', 
                             end_date - visit_date, 
                             min_outcome_date_other - visit_date)) %>% 
    select(-min_outcome_date_cmd, -min_outcome_date_other)
  
  return(df)
}


# Calculate cumulative incidence
cumulative_inc <- function(df, v){
  
  N <- nrow(df)
  
  cu_in <- df %>% 
    group_by(!!sym(v)) %>% 
    summarise(incidence = n()) %>% 
    arrange(v)
  
  cu_sum <- cumsum(cu_in$incidence)
  
  cu_in <- cu_in %>% 
    mutate(cumulative_incidence = cu_sum,
           surv = (N - cumulative_incidence)/N)
  
  return(cu_in)
}


incidence <- derive_t(incidence)
prevalence <- derive_t(prevalence)

inc_ci_cmd <- cumulative_inc(incidence, 't_cmd')
inc_ci_other <- cumulative_inc(incidence, 't_other')
prev_ci_cmd <- cumulative_inc(prevalence, 't_cmd')
prev_ci_other <- cumulative_inc(prevalence, 't_other')


plot_surv <- function(df, x, y, title){
  
  ggplot(df) +
    geom_line(aes_string(x = x, y = y)) +
    ggtitle(title) +
    theme(plot.title = element_text(hjust = 0.5))
  
}


jpeg('output/incidence_ci_cmd.jpg', res = 300, width = 12, height = 10, units = 'cm')
plot_surv(inc_ci_cmd, 't_cmd', 'surv', 'Incidence')
dev.off()

jpeg('output/incidence_ci_other.jpg', res = 300, width = 12, height = 10, units = 'cm')
plot_surv(inc_ci_other, 't_other', 'surv', 'Incidence')
dev.off()

jpeg('output/prevalence_ci_cmd.jpg', res = 300, width = 12, height = 10, units = 'cm')
plot_surv(prev_ci_cmd, 't_cmd', 'surv', 'Prevalence')
dev.off()

jpeg('output/prevalence_ci_other.jpg', res = 300, width = 12, height = 10, units = 'cm')
plot_surv(prev_ci_other, 't_other', 'surv', 'Prevalence')
dev.off()
