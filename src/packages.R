## Date: 17/05/2023
## Overview: Discrete event simulation model for ambulance setting
## Author: Martina Fonseca, Jonathan Pearson, Digital Analytics and Research Team (DART)
## Stage: beta
## Current script: Packages needed for run and results
## Dependencies: 
## Called by: main.R
##
############################################################################# ##

## Packages to install

flag_install_packages <- FALSE
#c_packagestoinstall <- c("tidyverse","simmer","simmer.plot","EnvStats","psych","hrbrthemes","htmlwidgets","here","webshot","openxlsx")
c_packagestoinstall <- c()  # Include packages yet to be installed (among list above)

if (flag_install_packages){
  install.packages(c_packagestoinstall)
}

## Packages to load
'%!in%' <- function(x,y)!('%in%'(x,y))
library(tidyverse)
library(simmer)
library(simmer.plot)
library(EnvStats)
library(psych)
library(hrbrthemes)
library(htmlwidgets)
library(here)
library(webshot)
library(openxlsx)

