## Date: 27/02/2023
## Overview: Discrete event simulation model for ambulance setting
## Author: Martina Fonseca, Digital Analytics and Research Team (DART)
## Stage: alpha / rapid prototype
## Current script: main script from which libraries are loaded, parameters set, 
## runs made and results processed
## Dependencies: packages.R
## Called by:
##
############################################################################# ##


############################################################################# ##
######### PREPARATORY AND PRESETS                                     ####### ##
############################################################################# ##
# Clear vars in environment ----------------------------------------------------
rm(list = ls())
set.seed(999)

# Source libraries -------------------------------------------------------------
#invisible(lapply(paste0("package:", names(sessionInfo()$otherPkgs)),   # Unload add-on packages
#                 detach,
#                 character.only = TRUE, unload = TRUE))# to not have e.g. bupaR mask select from simmer
source("packages.R")
source("trajectory.R")

scenario_folder <- "Fake_Data"
scenario_folder <- paste0(scenario_folder,"/")
mydate="Fake_May2023_base_ppt" # name of Output subfolder

# Set batch run presets ----------------------------------------------------------------
nreps = 3 # number of replications

flag_resourcesaveplots=T # whether to save per batch res_mon plots (slows down considerably when writing to file)
flag_utilsaveplots = T # whether to save per batch util plots
flag_sitequeuesaveplots = T # whether to save site queueing plots
flag_patientpathplot = T # plot(trajectory)
g.debug=0 # how many levels of depth of log detail to print. #0 for least.

n_days_week <- 7 # days in a week. constant

ambu_day <- 100 # Parameter to poisson .  120 is typical daily avg per most affected trusts, but varies considerably.
#ambu_hour_peak <- ambu_day/24 # if enabled, peak value to multiply by a peak-normalised schedule.
n_days_warm <- 2 # days of warm-up
n_days_study <- 7 # days to observe
flag_RRS <- TRUE # whether to allow for static
RRS_protocol <- "schedule"
#RRS_protocol <- "trigger"

# Whether demand is constant Poisson rate or rate follows a user-inputted profile
flag_demand_schedule <- TRUE # whether demand (poisson rate) should vary per hour (given in file) . nb not disaggregated by cat

# DSA Resource info -----------------------------------------------------------
flag_supply_schedule <- TRUE # whether supply should follow a schedule
flag_supply_schedule_file <- TRUE # whether this schedule comes from the file

# Presets - derived
ndays <- n_days_warm + n_days_study # days of study (warm-up + observe)
g.tmin=0
g.tmax=24*60*ndays; # one day . Note: this may be different to implied by schedules.
g.tday = 24*60 # minutes in a day

# Create directory for results if necessary
if (!dir.exists(here::here("Output"))){
  dir.create(here::here("Output"))
}

if (!dir.exists(here::here("Output", mydate))){
  dir.create(here::here("Output", mydate))
}


############### ##
# Demand ----------------------------------------------------------------
############### ##

df_demand_sch <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_v_DnC_schedule.xlsx"),sheet="Demand-Enforced") # if so, peak normalised demand schedule 

# Define relative distribution of demand by category
v_demand_cat <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_m_demand_cat2conv.xlsx"),sheet="v_demand_cat")

# Define relative distribution of conveyance by category
m_demand_cat2conv <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_m_demand_cat2conv.xlsx"),sheet="m_demand_cat2conv")
v_conv=colnames(m_demand_cat2conv[,2:4])
vi_conv = c(1:length(v_conv))
names(vi_conv) <- v_conv
rownames(m_demand_cat2conv)<- m_demand_cat2conv[,1]
m_demand_cat2conv<- m_demand_cat2conv[,-1]

# Derive relative distribution of demand by conveyance (derived, matrix multiplication)
v_demand_conv <- t(m_demand_cat2conv) %*% v_demand_cat$Rel

# Globals
n_cats = v_demand_cat %>% nrow()
n_conv = length(vi_conv)

# Define direct - their acuity and how much these are as un uplift of conveyance
v_direct_acuity <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_m_demand_cat2conv.xlsx"),sheet="v_direct_acuity")
n_acuity <- nrow(v_direct_acuity)

if(!flag_demand_schedule){
  v_direct_ratio <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_m_demand_cat2conv.xlsx"),sheet="v_direct_ratio")
  direct_day_proxy <- v_direct_ratio$EDattendance_Rel_to_AmbConveyance[1] * ambu_day * v_demand_conv["SeeConvey",1]
}

####################### ##
# Job Cycle Time #####
###################### ##

## Define the distributions for job cycle time ####

## Type of sampling (Quantile-based or Stylistic parametrisation-based.) ##

JCT_type <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_JCT_v_type.xlsx")) %>% as.vector()

## JCT as quantile - upload ##

# Function for dataframe to matrix conversion
JCT_qfile_2_matrix <- function(teq_jct_cat,n_cats,n_conv){
  
  n_q <- teq_jct_cat$q %>% n_distinct
  teq_jct_cat_m <- teq_jct_cat %>% pivot_longer(cols=c("C1","C2","C3","C4"),names_to="cat",values_to="value")
  teq_jct_cat_m1a <- array(data=teq_jct_cat_m$value,dim=c(n_cats,n_q,n_conv))
  
  return(teq_jct_cat_m1a)
}

# Travel to scene - quant
teq_tts_cat <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_JCT_m_q.xlsx"),sheet="traveltoscene")
teq_tts_cat_m1a <- JCT_qfile_2_matrix(teq_tts_cat,n_cats,n_conv)


# Matrices for each of the JCT components (quantile)
teq_tts_cat <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_JCT_m_q.xlsx"),sheet="traveltoscene")
teq_tts_cat_m1a <- JCT_qfile_2_matrix(teq_tts_cat,n_cats,n_conv)

teq_tas_cat <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_JCT_m_q.xlsx"),sheet="timeatscene")
teq_tas_cat_m1a <- JCT_qfile_2_matrix(teq_tas_cat,n_cats,n_conv)

teq_ttsi_cat <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_JCT_m_q.xlsx"),sheet="traveltosite")
teq_ttsi_cat_m1a <- JCT_qfile_2_matrix(teq_ttsi_cat,n_cats,n_conv)

teq_uph_cat <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_JCT_m_q.xlsx"),sheet="unavoidableprehandover")
teq_uph_cat_m1a <- JCT_qfile_2_matrix(teq_uph_cat,n_cats,n_conv)

teq_ttc_cat <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_JCT_m_q.xlsx"),sheet="timetoclear")
teq_ttc_cat_m1a <- JCT_qfile_2_matrix(teq_ttc_cat,n_cats,n_conv)


## JCT as stylistic parametrisation - upload ##

# Function for dataframe to matrix conversion
JCT_file_2_matrix <- function(teparam_jct_cat,n_cats,n_conv){
  
  n_param <- teparam_jct_cat$param %>% n_distinct
  teparam_jct_cat_m <- teparam_jct_cat %>% pivot_longer(cols=c("C1","C2","C3","C4"),names_to="cat",values_to="value")
  teparam_jct_cat_m1a <- array(data=teparam_jct_cat_m$value,dim=c(n_cats,n_param,n_conv))
  
  return(teparam_jct_cat_m1a)
}

# Matrices for each of the JCT components
teparam_tts_cat <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_JCT_m_style.xlsx"),sheet="traveltoscene")
tep_tts_cat_m1a <- JCT_file_2_matrix(teparam_tts_cat,n_cats,n_conv)

teparam_tas_cat <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_JCT_m_style.xlsx"),sheet="timeatscene")
tep_tas_cat_m1a <- JCT_file_2_matrix(teparam_tas_cat,n_cats,n_conv)

teparam_ttsi_cat <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_JCT_m_style.xlsx"),sheet="traveltosite")
tep_ttsi_cat_m1a <- JCT_file_2_matrix(teparam_ttsi_cat,n_cats,n_conv)

teparam_uph_cat <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_JCT_m_style.xlsx"),sheet="unavoidableprehandover")
tep_uph_cat_m1a <- JCT_file_2_matrix(teparam_uph_cat,n_cats,n_conv)

teparam_ttc_cat <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_JCT_m_style.xlsx"),sheet="timetoclear")
tep_ttc_cat_m1a <- JCT_file_2_matrix(teparam_ttc_cat,n_cats,n_conv)

# Globals on job cycle time (fallbacks) ----------------------------------------------------------
#unit minute
g.T_allocatetomobilise=0 # Time period from allocate to mobilise. Assume most of 1/5*25 above is from call to allocate, not allocate to mobilise. Allow for 2 minutes.
g.T_traveltoscene <- 22# Time period to travel to scene. 22 to match travel to hospital. Under assumption that ambulances can't travel from their optimal spot. All pivot back and forth from site.
g.T_atscene <- 36 # Time period at scene.
g.T_traveltohospital <- 22 # Time period to travel to hospital site.
g.T_prehandover_LN <- c(3.218467,1.414410*0.5,25) # Time period for pre-handover. Define the logmean, logsd, offset
g.T_clear=5
# Auxiliary calcs on job cycle time ----------------------------------------------------------
(g.T_prehandover_LN_median <- exp(g.T_prehandover_LN[1]) + g.T_prehandover_LN[3])  #Time period for pre-handover. Median from distribution
(g.T_prehandover_LN_mean <- exp(g.T_prehandover_LN[1]+g.T_prehandover_LN[2]^2/2)+ g.T_prehandover_LN[3]) #Time period for pre-handover. Mean of distribution
# old approach. Not time averaged, instead sets threshold Y ambulances arriving in shift that would see a queue of X or more on arrival
no_ambulancesqueueingbreach <- 10  # no ambulances queueing in site for it to count as breach from new ambulance arrival perspective
no_arrivalbreaches <- 10 # trigger point: nr of arrivals in time window that observe queue length breach.


##################### ##
#### Supply - DSA #####
##################### ##

## DSA Resource Schedule Profile From file

df_DSA_sch <- read.xlsx(paste0(here() %>% dirname(),"/parameters/",scenario_folder,"Fake_v_DnC_schedule.xlsx"),sheet="Supply-Enforced") # peak normalised supply schedule

## DSA Resource Schedule Profile Manual
n_ru0 <- 46  # 30 # number of staff (pool) - ideally twice of n_ru (assuming all DSA vehicles and desired full use)
n_dsav0 <- 23 # 15  #number of double-staff vehicles (pool)
n_staticru <- 2 # number of staff for static (only used if flag_RRS is true)
c_bays_per_staticstaff <- 3 # bays per staff (indication of 4), twice that per double vehicle
n_mobile0 <- min(floor(n_ru0/2),n_dsav0)

# Schedule outline ----------------------------------------------------------------

#t_sch = c(0, 8, 16, 24, 32, 40)*60 # time intervals
T_window_hours<- 8 # hours per window
n_windows_week <- n_days_week*24/T_window_hours # number windows (warm-up + observe)
#n_warmup_windows <- n_days_warm*24/T_window_hours  # nr warm-up windows
t_sch = seq(from = 0,to = (n_windows_week-1)*T_window_hours,by = T_window_hours)*60 # time intervals (6 - 2 days, 3 windows of 8 hours)
period_sch= n_days_week * 24 * 60 # weekly #Inf#24*60*2 # the periodicity of the schedule motif 
t_sch_ones = rep(1,n_windows_week)

# An 8-window profile for a week. Then repeat.
t_DSA_sch <- t_sch
n_DSA_sch <- t_sch_ones*n_mobile0
per_DSA_sch <- period_sch

if (flag_supply_schedule_file){
  #mobile_schedule <- schedule(df_DSA_sch$Time,round(df_DSA_sch$DSV * n_mobile0,0),period = period_sch) # assumes same week on week  
  mobile_schedule <- schedule(df_DSA_sch$Time,round(df_DSA_sch$DSV_Enforced,0),period = Inf)
} else{
  mobile_schedule <- schedule(t_DSA_sch ,n_DSA_sch, period = per_DSA_sch )
  
}


##################################### ##
# Supply and Performance - A&E #####
#################################### ##

## A&E Capacity and performance info (interim) --------------------------------------------------------

## some apportioning... heuristic --------------------------------------------------------
T_AE <- 4/24 # period in AE . 4 hours -> days
r_AE <- 1/T_AE # patients seen per day per 'server'
n_conv_day <- ambu_day * v_demand_conv["SeeConvey",]
# servers needed to deal with queue
if(flag_demand_schedule){
  (c_needed <- (sum(df_demand_sch$Incident_Demand)*v_demand_conv["SeeConvey",]+sum(df_demand_sch$Direct_Demand))/max(df_demand_sch$Day))/r_AE
} else{
  (c_needed <- (n_conv_day+direct_day_proxy)/r_AE)
  
}

## Set the A&E time (simplistic constant) and nr A&E bays . COnsider admission v discharge and acuity. COnsider profile need
T_AE_min <- T_AE*24*60
n_AEbays <- 90

t_AEsupplyshock <- 4*24*60  # after 4 days, in minutes
dn_AEsupplyshock <- 0 #-n_AEbays * 0.66 # number of bays to decrease by, upon shock

t_ae_sch <- c(0 , t_AEsupplyshock)
n_AE_sch <- c(n_AEbays , n_AEbays - dn_AEsupplyshock)
per_AE_sch <- Inf # doesnt repeat
AEbay_schedule <- schedule(t_ae_sch,n_AE_sch,per_AE_sch)


############################ ##
# Scenario library #############
############################ ##
## (currently not in use; needs updating)

## Parameters for scenario building ----------------------------------------------------------
flag_scenarios <- FALSE
if (flag_scenarios){
  vec_prehandoverNAperc = c(0.1) # percentage of pre-handover that is not-avoidable by using RRS. To understand how RRS effect changes with decreasing portion of vehicle handover time avoided
  vec_JCToffsiteincrement = c(0) # additional JCT time. Added stylistically to 'at scene' time . To understand trade-off of %JCT off-site on effectiviness of standing down DSA vehicle for RRS.
  vec_demand = c(170,180,190)
  vec_RRS = c(FALSE,TRUE)
} else{
  vec_prehandoverNAperc = c(0.1) # percentage of pre-handover that is not-avoidable by using RRS. To understand how RRS effect changes with decreasing portion of vehicle handover time avoided
  vec_JCToffsiteincrement = c(0)
  vec_demand = c(ambu_day)
  vec_RRS = (flag_RRS)
}

n_prehandoverNAperc = length(vec_prehandoverNAperc)
n_JCToffsiteincrement = length(vec_JCToffsiteincrement)
n_demand <- length(vec_demand)
n_RRS <- length(vec_RRS)
n_scenarios <- n_prehandoverNAperc * n_JCToffsiteincrement * n_demand * n_RRS
names_levers <- c("demand","prehandoverNAperc","JCToffsiteincrement","RRS")
df_scenarios <-expand.grid(vec_demand,vec_prehandoverNAperc,vec_JCToffsiteincrement,vec_RRS)
colnames(df_scenarios) <- names_levers
df_scenarios <- df_scenarios %>% mutate(id=row_number())
rownames(df_scenarios) <- 1:nrow(df_scenarios)
#scenarioids_toplot <- c(1,2,3)
scenarioids_toplot <- df_scenarios$id
dff_rc=data.frame() # attributes log initialised (all patients, all iterations, all parameter variation batch runs)
dfr_rc=data.frame() # resources log initialised (all event timepoints, all iterations, all parameter variation batch runs)


############################################################################# ##
######### RUN                                                         ####### ##
############################################################################# ##

source("trajectory.R");start_time <- Sys.time()
for (myr in 1:nrow(df_scenarios)) { 
  
  row <- df_scenarios[myr,]
  id<-row$id
  now_prehandoverNAperc <- row$prehandoverNAperc
  now_JCToffsiteincrement <- row$JCToffsiteincrement
  now_demand <- row$demand
  flag_RRS <- row$RRS
  g.T_prehandoverNAperc = now_prehandoverNAperc # NA - portion of pre-handover that is non-avoidable (as %)
  g.T_atscene <- 36 + now_JCToffsiteincrement # idem - #make this lognormal/triangular?
  ambu_day_now <- now_demand #120 # typical daily avg per RRS trust is 120
  g.tmaxused <- ifelse(flag_demand_schedule,
                       df_demand_sch$Time %>% max() + df_demand_sch$Time[2],
                       g.tmax)
  
  # Run simulation (multiple runs) - not parallelised ----------------------------------------------------------
  
  sims <- lapply(1:nreps, traj) # CAD_rep defined in 03-replication_v08.R
  #sims <- traj(1)
};

end_time <- Sys.time();print(end_time - start_time)


