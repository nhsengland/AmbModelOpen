## Date: 20/01/2023
## Overview: Discrete event simulation model for ambulance setting
## Author: Martina Fonseca, Digital Analytics and Research Team (DART)
## Stage: alpha / rapid prototype
## Current script: Packages needed for run and results
## Dependencies: 
## Called by: main.R
##
############################################################################# ##

library(tidyverse)
#library(parallel)
library(simmer)
library(simmer.plot)
library(EnvStats)
library(viridis)
library(hrbrthemes)
library(htmlwidgets)
library(here)
library(webshot)
library(openxlsx)
#library(reticulate) # for arrays

# https://search.r-project.org/CRAN/refmans/EnvStats/html/LognormalTrunc.html
# https://stats.stackexchange.com/questions/103356/truncate-lognormal-distribution-with-excel