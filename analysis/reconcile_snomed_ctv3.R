library(tidyverse)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

df <- read_csv('output/input.csv')

df <- df %>% 
  mutate(CVD = ifelse(CVD_snomed == 1 | CVD_ctv3 == 1, 1, 0),
         musculoskeletal = ifelse(musculoskeletal_snomed == 1 | musculoskeletal_ctv3 == 1, 1, 0)) %>%
  select(-CVD_snomed, -CVD_ctv3,
         -musculoskeletal_snomed, -musculoskeletal_ctv3)

write_csv(df, 'output/input_reconciled.csv')
