The `config.R` file contains all the user parameters and controls for the model.  These can be categorised into several groups of parameters.

The below shows these parameters with a default assignment but this can be changed.

#### batch run parameters

| Parameter           |   | Use                          |
|:----------:|:---------:|:-------------------------:|
| nreps = 10 |   | # number of replications  |


#### simulation parameters

| Parameter           |   | Use                          |
|:----------------:|:---:|:------------------------------:|
| n_days_week <- 7 |   | # days in a week. constant     |
| g.tday = 24*60   |   | # minutes in a day. constant.  |

#### simulation parameters (only used if demand flag not from file)

| Parameter           |   | Use                          |
|:-----------------------------------:|:---:|:-----------------------------------------------------------------------------------------------------------------------------------------:|
| ambu_day <- 100                     |   | # Parameter to poisson , only used if demand not from file.  120 is typical daily avg per most affected trusts, but varies considerably.  |
| n_days_warm <- 1                    |   | # days of warm-up , if demand not from file, only used to dictate time to remove for output KPI purposes.                                 |
| n_days_study <- 14                  |   | # days to observe , only used if demand not from file                                                                                     |
| ndays <- n_days_warm + n_days_study |   | # days of study (warm-up + observe), only used if demand not from file                                                                    |
| g.tmax=24*60*ndays;                 |   | # one day . Note: this may be different to implied by schedules.                                                                          |

#### Fallback simulation parameters (only used if JCT error in loading from file, except g.T_prehandoverXed and g.T_allocatetomobilise)

| Parameter           |   | Use                          |
|:---:|:---:|:--------:|
| g.T_allocatetomobilise=0 |  | # Time period from allocate to mobilise.  |
| g.T_traveltoscene <- 22 |  | # Time period to travel to scene. 22 to match travel to hospital. Under assumption that ambulances can't travel from their optimal spot. All pivot back and forth from site.  |
| g.T_atscene <- 36 |  | # Time period at scene.  |
| g.T_traveltohospital <- 22 |  | # Time period to travel to hospital site.  |
| g.T_prehandover_LN|  | # Time period for pre-handover. Define the logmean, logsd, offset  |
| g.T_clear=5 |  | # Time period for clearance  |
| g.T_prehandoverXed <- 40 |  | # Assumed period to pre-handover for X ED conveyances  |
| g.T_prehandover_LN_median |  | # Derived field. Time period for pre-handover. Median from distribution  |
| g.T_prehandover_LN_mean  |  | # Derived field. Time period for pre-handover. Mean from distribution  |

#### Fallback capacity simulation parameters (only used if capacity flag not from file)

| Parameter           |   | Use                          |
|:---:|:---:|:---:|
| n_ru0 <- 500 |  | # number of staff (pool) - ideally twice of n_dsav0 (assuming all DSA vehicles and desired full use)  |
| n_dsav0 <- 250 |  | # number of double-staff vehicles (pool)  |
| n_mobile0 <- min(floor(n_ru0/2),n_dsav0) |  | # Derived field  |

#### Set the A&E parameters

| Parameter           |   | Use                          |
|:---:|:---:|:---:|
| flag_supply_schedule_file_hED <- TRUE |  |  # whether to use (unscaled) seasonal ED variation from Dnc file. If so, n_AEbays will be used as average A&E bays over time horizon  |
| flag_LoS_file <- FALSE |  | # whether LoS should come from file.   |
| T_AE <- 5.96 |  | # period in AE (used if not loaded from file) , in hours  |
| n_AEbays <- 1500*1 |  | # number of A&E bays / A&E capacity  |
| t_AEsupplyshock <- 7*24*60 |  | # when to apply supply shock, in minutes from t0  |
| dn_AEsupplyshock <- 0 |  | # number of bays to change by, upon shock (for decrease, use negative number) 

#### What-if parameters

| Parameter           |   | Use                          |
|:---:|:---:|:---:|
| tamper_dsa_flag <- TRUE |  | # whether to tamper with DSA supply  |
| tamper_dsa_f <- 0.861 |  | # factor by which to tamper by (1 is 'equal' / no tampering ; 1.10 and 0.9 are tampering upwards and downwards by 10%)  |
| tamper_HO_flag <- FALSE |  | # whether to tamper with handover  |
| tamper_HO_f <-1 |  | # factor by which to tamper by (1 is 'equal' / no tampering ; 1.10 and 0.9 are tampering upwards and downwards by 10%)  |
| tamper_HT_flag <- FALSE |  | # whether to 'tamper' with H&T (F2F portion)  |
| tamper_HT_pp <- 5 |  | # the %p of F2F incidents to become H&T, from S&T - only cat3,4  |
| tamper_ST_flag <- FALSE |  | # whether to 'tamper' with S&T (conveyance)  |
| tamper_ST_pp <- 0 |  |  # the %p to increase S&T by, from S&C - only cat3,4   |
| DSV_holdout_flag = FALSE |  | # flag for use of holdout (if so, part of resource is put aside and can only be used by cat1 in given circumstances)  |
| DSV_holdout_perc = 0.2 |  | # percentage of on-duty fleet that is holdout  |
| DSV_holdout_use_minqueue = 100  |  | # minimum queue in for ain DSV in order to allow holdout to be used  |
| flag_EDpriority_adjust = TRUE  |  | # whether to do some deprioritising of direct vs ambulance at same acuity  |
| p_direct_deprio <- 0.2               |  | # the probability of direct being deprioritised compared to ambulance with same acuity  |

#### escalation/trigger parameters

| Parameter           |   | Use                          |
|:---:|:---:|:---:|
| flag_renege <- FALSE |  | # whether to allow reneging (cat3,4)  |
| T_renege <- 18*60 |  | # time in minutes after which an arrival will renege  |
| p_renege_directED <- 0.25 |  | # probability that reneges will instead go straight to ED (rather than 'step down')  |
| catmin_renege <- 3 |  | # minimum category where reneges happen  |
|  |  |   |
| flag_stepcat <- TRUE |  | # whether to allow calls to increase in priority after a time X  |
| T_stepcat <- 7*60 |  | # time in minutes after which to increase priority  |
| catmin_stepcat <- 3 |  | # minimum category for which this should apply (towards lower acuities)  |
|  |  |   |
| flag_balk_amb <- FALSE |  | # whether to allow balking. If FALSE, nqueue_balk will be overwritten to 'Inf'  |
| nqueue_balk <- 500 |  | # threshold of queue size. (#500 as WMAS saw a peak of circa 470 on unallocated calls across the day by month, in Dec22)  |
|  |  |   |
| no_ambulancesqueueingbreach <- 10 |  | # no ambulances queueing in site for it to count as breach from new ambulance arrival perspective  |
| no_arrivalbreaches <- 10 |  | # trigger point: nr of arrivals in time window that observe queue length breach.  |
|  |  |   |
| flag_dynamics <- FALSE |  | # whether to allow for Cat3 conveyance to dynamically adjust based on pressure  |
| T_window_escalation_hours<-8 |  | # cycle for escalation checks and also window used for KPI computation that informs escalation, in hours  |

#### Schedule parameters

| Parameter           |   | Use                          |
|:---:|:---:|:---:|
| flag_demand_schedule <- TRUE |  | # whether demand (poisson rate) should vary per hour (given in file) . nb not disaggregated by cat  |
| flag_supply_schedule <- TRUE |  | # whether supply should follow a schedule  |
| flag_supply_schedule_file <- TRUE |  | # whether this schedule comes from the file  |
| T_window_hours<- 8 |  |  # hours per window  |


#### Scenario 'Run Mode' parameters

| Parameter           |   | Use                          |
|:---:|:---:|:---:|
| flag_scenarios <- TRUE |  | # whether to use scenario runs . Do not edit the below if under the 'else' statement (single scenario)  |
| vec_T_AE = c(5.96) |  | # vector for time in A&E (hours)  |
|   vec_tamper_dsa_flag=c(TRUE) |  | # vector for DSA flag  |
|   vec_tamper_dsa_f = c(0.82) |  | # vector for DSA factor  |
|   vec_tamper_HT_flag = c(FALSE) |  | # vector for H&T flag  |
|   vec_tamper_HT_pp = c(0) |  | # vector for H&T p.p. change  |
|   vec_tamper_ST_flag = c(FALSE) |  | # vector for S&T flag  |
|   vec_tamper_ST_pp = c(0) |  | # vector for S&T p.p. change  |


#### Plotting parameters

| Parameter           |   | Use                          |
|:---:|:---:|:---:|
| val_months = c("Month1","Month2","Month3") |  | # not for editing  |
| val_month = val_months[1] |  | # change between 1,2,3 for some reference lines from publications to appear in graphs  |

#### Saving parameters

| Parameter           |   | Use                          |
|:---:|:---:|:---:|
| flag_savedata_overallKPIs = T |  | # flag on whether to save overall KPI files  |
| flag_savedata_stepwiseKPIs = T |  | # flag on whether to save stepwise KPI files  |
| flag_savedata_fulllogs = F |  | # flag on whether to save full logs  |
| flag_saveplots = T |  | # flag on whether to save plots  |
| flag_patientpathplot = F |  | # plot(trajectory)  |
| g.debug=0 |  | # how many levels of depth of log detail to print. #0 for least.  |

