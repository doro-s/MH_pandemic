library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

non_health <- fread('output/input_non_health.csv')

print(nrow(non_health))

write_csv(data.frame(1), 'output/placeholder.csv')
