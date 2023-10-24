## Date: 17/05/2023
## Overview: Discrete event simulation model for ambulance setting
## Author: Martina Fonseca, Jonathan Pearson, Digital Analytics and Research Team (DART)
## Stage: beta
## Current script: config (user inputs)
## Dependencies: 
## Called by: main.R
##
############################################################################# ##

# Batch run parameters --------------------------------------------------------
nreps = 10                              # number of replications

# Globals --------------------------------------------------------
n_days_week <- 7                       # days in a week. constant
g.tday = 24*60                         # minutes in a day. constant.

# Simulation parameters (some only used if demand flag not from file)--------------------------------------------------------
ambu_day <- 100                        # Parameter to poisson , only used if demand not from file.  120 is typical daily avg per most affected trusts, but varies considerably.
n_days_warm <- 1                       # days of warm-up , if demand not from file, only used to dictate time to remove for output KPI purposes.
n_days_study <- 14                      # days to observe , only used if demand not from file
ndays <- n_days_warm + n_days_study    # days of study (warm-up + observe), only used if demand not from file
g.tmax=24*60*ndays;                    # one day . Note: this may be different to implied by schedules.

# Fallback simulation parameters (only used if JCT error in loading from file, except g.T_prehandoverXed and g.T_allocatetomobilise)--------------------------------------------------------
g.T_allocatetomobilise<-0               # Time period from allocate to mobilise.
g.T_traveltoscene <- 22                # Time period to travel to scene. 22 to match travel to hospital. Under assumption that ambulances can't travel from their optimal spot. All pivot back and forth from site.
g.T_atscene <- 36                      # Time period at scene.
g.T_traveltohospital <- 22             # Time period to travel to hospital site.
g.T_prehandover_LN <- c(3.218467,1.414410*0.5,25) # Time period for pre-handover. Define the logmean, logsd, offset
g.T_clear=5
g.T_prehandoverXed <- 40 # Assumed period to pre-handover for X ED conveyances
g.T_prehandover_LN_median <- exp(g.T_prehandover_LN[1]) + g.T_prehandover_LN[3]# Time period for pre-handover. Median from distribution
g.T_prehandover_LN_mean <- exp(g.T_prehandover_LN[1]+g.T_prehandover_LN[2]^2/2)+ g.T_prehandover_LN[3] # Time period for pre-handover. Mean from distribution


# Fallback capacity simulation parameters (only used if capacity flag not from file)--------------------------------------------------------
n_ru0 <- 500                            # FAKE INPUT # number of staff (pool) - ideally twice of n_dsav0 (assuming all DSA vehicles and desired full use)
n_dsav0 <- 250                          # FAKE INPUT # number of double-staff vehicles (pool)
n_mobile0 <- min(floor(n_ru0/2),n_dsav0)

## Set A&E parameters
flag_supply_schedule_file_hED <- TRUE # whether to use (unscaled) seasonal ED variation from Dnc file. If so, n_AEbays will be used as average A&E bays over time horizon
flag_LoS_file <- TRUE                   # whether LoS should come from file. 
T_AE <- 6.5                           # period in AE (used if not loaded from file) , in hours
n_AEbays <- 73*1# 1500*1                   # FAKE INPUT # number of A&E bays / A&E capacity
t_AEsupplyshock <- 7*24*60             # when to apply supply shock, in minutes from t0
dn_AEsupplyshock <- -8                  # number of bays to change by, upon shock (for decrease, use negative number)

# What-if parameters -------------------------------------------------
tamper_dsa_flag <- FALSE              # whether to tamper with DSA supply
tamper_dsa_f <- 1               # factor by which to tamper by (1 is 'equal' / no tampering ; 1.10 and 0.9 are tampering upwards and downwards by 10%)
tamper_HO_flag <- FALSE ;   # whether to tamper with handover
tamper_HO_f <-1 # factor by which to tamper by (1 is 'equal' / no tampering ; 1.10 and 0.9 are tampering upwards and downwards by 10%)
tamper_HT_flag <- FALSE                # whether to 'tamper' with H&T (F2F portion)
tamper_HT_pp <- 5                     # the %p of F2F incidents to become H&T, from S&T - only cat3,4
tamper_ST_flag <- FALSE               # whether to 'tamper' with S&T (conveyance)
tamper_ST_pp <- 0                     # the %p to increase S&T by, from S&C - only cat3,4 
# https://www.researchgate.net/figure/Queuing-model-output-of-proposed-staffing-and-patient-arrival-rate-weekends_fig3_248279815
# https://www.england.nhs.uk/wp-content/uploads/2021/04/safe-staffing-uec-june-2018.pdf
DSV_holdout_flag = FALSE         # flag for use of holdout (if so, part of resource is put aside and can only be used by cat1 in given circumstances)
DSV_holdout_perc = 0.2          # percentage of on-duty fleet that is holdout
DSV_holdout_use_minqueue = 100  # minimum queue in for ain DSV in order to allow holdout to be used
flag_EDpriority_adjust = TRUE       # whether to do some deprioritising of direct vs ambulance at same acuity
if (flag_EDpriority_adjust){
  p_direct_deprio <- 0.2              # the probability of direct being deprioritised compared to ambulance with same acuity
} else{
  p_direct_deprio <- 0
}

# Escalation/trigger parameters -------------------------------------------------

flag_renege <- FALSE                    # whether to allow reneging (cat3,4)
T_renege <- 18*60                         # time after which an arrival will renege
p_renege_directED <- 0.25                 # probability that reneges will instead go straight to ED (rather than 'step down')
catmin_renege <- 3                      # minimum category where reneges happen

flag_stepcat <- TRUE                    # whether to allow calls to increase in priority after a time X
T_stepcat <- 7*60                       # time in hours after which to increase priority
catmin_stepcat <- 3                     # minimum category for which this should apply (towards lower acuities)

flag_balk_amb <- FALSE                   # whether to allow balking. If FALSE, nqueue_balk will be overwritten to 'Inf'
nqueue_balk <- 500                      # threshold of queue size. 

no_ambulancesqueueingbreach <- 10      # no ambulances queueing in site for it to count as breach from new ambulance arrival perspective
no_arrivalbreaches <- 10               # trigger point: nr of arrivals in time window that observe queue length breach.

flag_dynamics <- FALSE#FALSE                  # whether to allow for Cat3 conveyance to dynamically adjust based on pressure
T_window_escalation_hours<-8              # cycle for escalation checks and also window used for KPI computation that informs escalation

# Schedule parameters --------------------------------------------------------
flag_demand_schedule <- TRUE              # whether demand (poisson rate) should vary per hour (given in file) . nb not disaggregated by cat
flag_supply_schedule <- TRUE              # whether supply should follow a schedule
flag_supply_schedule_file <- TRUE         # whether this schedule comes from the file

T_window_hours<- 8 # hours per window
n_windows_week <- n_days_week*24/T_window_hours # number windows (warm-up + observe)

t_sch = seq(from = 0,to = (n_windows_week-1)*T_window_hours,by = T_window_hours)*60 # time intervals (6 - 2 days, 3 windows of 8 hours)
period_sch= n_days_week * 24 * 60      # weekly #Inf#24*60*2 # the periodicity of the schedule motif 
t_sch_ones = rep(1,n_windows_week)

# Scenario 'Run Mode' parameters --------------------------------------------------------
flag_scenarios <- FALSE   # whether to use scenario runs
names_levers <- c("T_AE","tamper_dsa_flag","tamper_dsa_f","tamper_HT_flag","tamper_HT_pp","tamper_ST_flag","tamper_ST_pp")
if (flag_scenarios){
  vec_T_AE = c(5.955)
  vec_tamper_dsa_flag=c(TRUE) # c(FALSE,TRUE)      # 
  vec_tamper_dsa_f = c(0.82)*1.01
  vec_tamper_HT_flag = c(FALSE)
  vec_tamper_HT_pp = c(0)
  vec_tamper_ST_flag = c(FALSE)
  vec_tamper_ST_pp = c(0)
} else{
  print("single scenario")
  vec_T_AE = c(T_AE)       # 
  vec_tamper_dsa_flag = c(tamper_dsa_flag)
  vec_tamper_dsa_f = c(tamper_dsa_f)
  vec_tamper_HT_flag = c(tamper_HT_flag)
  vec_tamper_HT_pp = c(tamper_HT_pp)
  vec_tamper_ST_flag = c(tamper_ST_flag)
  vec_tamper_ST_pp = c(tamper_ST_pp)
}

# Plotting parameters ------------------------------------------------------------
val_months = c("Month1","Month2","Month3") # not for editing
val_month = val_months[1]               # change between 1,2,3 for some reference lines from publications to appear in graphs

# Saving parameters ------------------------------------------------------------
flag_savedata_overallKPIs = T     # flag on whether to save overall KPI files
flag_savedata_stepwiseKPIs = T    # flag on whether to save stepwise KPI files
flag_savedata_fulllogs = T        # flag on whether to save full logs
flag_saveplots =  T               # flag on whether to save plots
flag_patientpathplot = F          # plot(trajectory)
g.debug=0                         # how many levels of depth of log detail to print. #0 for least.
