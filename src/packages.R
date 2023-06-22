## Date: 17/05/2023
## Overview: Discrete event simulation model for ambulance setting
## Author: Martina Fonseca, Jonathan Pearson, Digital Analytics and Research Team (DART)
## Stage: beta
## Current script: Packages needed for run and results
## Dependencies: 
## Called by: main.R
##
############################################################################# ##
'%!in%' <- function(x,y)!('%in%'(x,y))
library(tidyverse)
#library(parallel)
library(simmer)
library(simmer.plot)
library(EnvStats)
library(viridis)
library(psych)
library(hrbrthemes)
library(htmlwidgets)
library(here)
library(webshot)
library(openxlsx)
#library(reticulate) # for arrays
#install.packages("psych")

# https://search.r-project.org/CRAN/refmans/EnvStats/html/LognormalTrunc.html
# https://stats.stackexchange.com/questions/103356/truncate-lognormal-distribution-with-excel