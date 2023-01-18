# Cumulative incidence curves graph function 

cumulative_incidence_plot <- function(data, name){
  
  graph <- autoplot(survfit(Surv(t, mh_outcome) ~ exposed + cluster(patient_id), 
                                         weights = sipw, 
                                         data = data),
                                 fun = function(x) 1-x, 
                                 censor = FALSE,
                                 conf.int = TRUE,
                                 xlab = "Time", 
                                 ylab = "Cumulative incidence")
  
  ggsave(paste0("output/", name,".jpg"), graph)
}
