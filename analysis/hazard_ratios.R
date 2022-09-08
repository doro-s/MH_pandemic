library(tidyverse)
library(survival)
library(data.table)
options(datatable.fread.datatable=FALSE)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

incidence <- fread('output/incidence_t.csv')
prevalence <- fread('output/prevalence_t.csv')
