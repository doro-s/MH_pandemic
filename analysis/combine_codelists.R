library(tidyverse)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

cmd_historic <- read_csv('codelists/ons-historic-anxiety-and-depression-diagnosis-codes.csv')
cmd_current <- read_csv('codelists/ons-depression-and-anxiety-diagnoses-and-symptoms-excluding-specific-anxieties.csv')
cmd <- rbind(cmd_historic, cmd_current)
write_csv(cmd, 'codelists/ons-cmd-codes.csv')

smi_historic <- read_csv('codelists/ons-historic-serious-mental-illness-diagnosis-codes.csv')
smi_current <- read_csv('codelists/ons-serious-mental-illness-schizophrenia-bipolar-disorder-psychosis.csv')
smi <- rbind(smi_historic, smi_current)
write_csv(smi, 'codelists/ons-smi-codes.csv')

self_harm_historic <- read_csv('codelists/ons-historic-self-harm-codes.csv')
self_harm_current <- read_csv('codelists/ons-self-harm-intentional-and-undetermined-intent.csv')
self_harm <- rbind(self_harm_historic, self_harm_current)
write_csv(self_harm, 'codelists/ons-self-harm-codes.csv')
