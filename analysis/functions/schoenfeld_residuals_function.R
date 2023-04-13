schoenfeld_residuals_function <- function(df, model_name){
  
  #calculate and save graph of schoenfeld residuals
  df_zph <- cox.zph(df)
  plot_zph = ggcoxzph(df_zph, var = c("exposed"), font.main = 12)
  ggsave(paste0("output/",model_name,"_schoenfeld_res.jpg"), arrangeGrob(grobs = plot_zph))
  
  #save schoenfeld residuals as csv
  df_zph_table <-  cox.zph(df)$table 
  
  write.csv(df_zph_table, paste0("output/",model_name,"_schoenfeld_res.csv"),row.names = TRUE)
}




