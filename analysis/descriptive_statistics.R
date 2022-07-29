library(tidyverse)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

source('analysis/cov_dist_cat.R')
source('analysis/cov_dist_cont.R')

matched <- read_csv('output/group_flags.csv')

# Need to read in matched person level data
# Only need to consider participants characteristics at the index date
# 100% of cases and 0% controls should have result_mk == 1

health_vars = c("alcohol", "obesity", "cancer", "digestive_disorder",
                "hiv_aids", "mental_disorder",  "metabolic_disorder",
                "kidney_disorder", "respiratory_disorder", "CVD",
                "musculoskeletal", "neurological")

cat_stats <- cov.dist.cat(vars = health_vars, dataset = matched, exposure = 'exposed')

write_csv(cat_stats, 'output/cat_stats.csv')

