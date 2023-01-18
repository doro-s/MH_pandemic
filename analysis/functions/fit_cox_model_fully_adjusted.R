###  Function for the fully adjusted model 
fit_cox_model <- function(df, vars){
  
  vars <- paste(vars, collapse = ' + ')
  
  model_formula <- formula(paste0('Surv(t, mh_outcome) ~ ', vars))
  
  model <- coxph(model_formula, data = df)
  
  return(model)
  
}