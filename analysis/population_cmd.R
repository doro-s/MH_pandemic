library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

cmd <- fread('output/input_cmd.csv')

print('total population')
nrow(cmd)

print('cmd counts by sex')
cmd %>% group_by(sex) %>% count(cmd)

write_csv(data.frame(1), 'output/population_cmd.csv')
