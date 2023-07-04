### Fully adjusted (Incidence) Stabilized Inverse Probability Weights (SIPWs)
inverse_prob_weights_incidence <- function(data){
  
  sipw_log_reg_model <- glm(
    exposed ~ cluster(patient_id) + 
      ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))) +
      alcohol +
      obese_binary_flag +
      cancer +
      digestive_disorder +
      hiv_aids +
      mental_behavioural_disorder +
      kidney_disorder +
      respiratory_disorder +
      metabolic_disorder +
      sex +
      ethnicity +
      region +
      hhsize +
      work_status_new +
      CVD +
      musculoskeletal +
      neurological +
      #imd +
      #rural_urban +
      self_isolating +
      vaccination_status,
    family = binomial,
    data = data)
  
  df <- data
  
  #calculate marginal probabilities
  p1 <- sum(df$exposed)/nrow(df)
  p0 <- 1-p1
  
  #extract predicted probabilities from model
  df$pred1 <- predict(sipw_log_reg_model, type="response")
  df$pred0 <- 1 - df$pred1
  
  # derive SIPWs
  df$sipw1 <- p1/df$pred1
  df$sipw0 <- p0/df$pred0
  df$sipw <- ifelse(df$exposed==1,df$sipw1,df$sipw0)
  
  # truncate SIPWs at 99th percentile and re-scale
  df$sipw[df$sipw > quantile(df$sipw, 0.99)] <- quantile(df$sipw, 0.99)
  df$sipw <- df$sipw*(nrow(df)/sum(df$sipw))
  
  return(df)
}
