## Date: 17/05/2023
## Overview: Discrete event simulation model for ambulance setting
## Author: Martina Fonseca, Jonathan Pearson, Digital Analytics and Research Team (DART)
## Stage: beta
## Current script: main script from which libraries are loaded, parameters set, 
## runs made and results processed
## Dependencies: packages.R, config.R, input.R
## Called by:
##
############################################################################# ##


############################################################################# ##
######### PREPARATORY AND PRESETS                                     ####### ##
############################################################################# ##
# Clear vars in environment ----------------------------------------------------
rm(list = ls())
gc() # garbage collection to take place
set.seed(995)

# Source libraries -------------------------------------------------------------
#invisible(lapply(paste0("package:", names(sessionInfo()$otherPkgs)),   # Unload add-on packages
#                 detach,
#                 character.only = TRUE, unload = TRUE))# to not have e.g. bupaR mask select from simmer
source(here::here("src","packages.R"))

# Create scenario folder and output directory ----------------------------------
scenario_folder <- "Fake_Data_2"
scenario_folder <- paste0(scenario_folder,"/")

mydate = "Fake_Scenario2"

mydate_ori <- mydate;

if (!dir.exists(here::here("Output"))){
  dir.create(here::here("Output"))
}


############################################################################# ##
######### Inputs                                                      ####### ##
############################################################################# ##
# Source user inputs -----------------------------------------------------------
source(here::here("src","config.R"))

# Source data inputs -----------------------------------------------------------
source(here::here("src","inputs.R"))


#### Preset for scenarios #####
df_scenarios <-expand.grid(vec_T_AE,vec_tamper_dsa_flag,vec_tamper_dsa_f,vec_tamper_HT_flag,vec_tamper_HT_pp,vec_tamper_ST_flag,vec_tamper_ST_pp) %>% mutate(id=row_number())
colnames(df_scenarios) <- c(names_levers,"id")
rownames(df_scenarios) <- 1:nrow(df_scenarios)

for (myr in 1:nrow(df_scenarios)) { 
  
  row <- df_scenarios[myr,]
  id<-row$id
  mydate <- paste0(mydate_ori,"_",id)
  if (!dir.exists(here::here("Output", mydate))){
    dir.create(here::here("Output", mydate))
  }
  output_folder <- here::here("Output", mydate)
  
  #now_demand <- row$demand
  ambu_day_now <- ambu_day
  T_AE = row$T_AE
  tamper_dsa_flag=row$tamper_dsa_flag      # 
  (tamper_dsa_f = row$tamper_dsa_f)
  tamper_HT_flag = row$tamper_HT_flag
  tamper_HT_pp = row$tamper_HT_pp
  tamper_ST_flag = row$tamper_ST_flag
  tamper_ST_pp = row$tamper_ST_pp
  
  ############################################################################# ##
  ######### Pre-processing                                              ####### ##
  ############################################################################# ##
  v_LoS <- v_LoS_ori
  if (flag_LoS_file==FALSE){
    v_LoS$LoS <- T_AE
  } else{
    if(flag_scenarios){
      v_LoS[v_LoS$Cat %in% c("C3","C4"),"LoS"]=v_LoS[v_LoS$Cat %in% c("C3","C4"),"LoS"]+T_AE
    }
  }
  
  r_AE <- 24/T_AE                         # patients seen per day per 'server'
  
  # Source user inputs -----------------------------------------------------------
  # An 8-window profile for a week. Then repeat.
  t_DSA_sch <- t_sch
  n_DSA_sch <- t_sch_ones*n_mobile0
  per_DSA_sch <- period_sch
  
  if (flag_supply_schedule_file){
    #mobile_schedule <- schedule(df_DSA_sch$Time,round(df_DSA_sch$DSV * n_mobile0,0),period = period_sch) # assumes same week on week  
    mobile_schedule <- schedule(df_DSA_sch$Time,round(df_DSA_sch$DSV_Enforced,0),period = Inf)
    if(tamper_dsa_flag){
      mobile_schedule <- schedule(df_DSA_sch$Time,round(df_DSA_sch$DSV_Enforced*tamper_dsa_f,0),period = Inf)
    }
    
  } else{
    mobile_schedule <- schedule(t_DSA_sch ,n_DSA_sch, period = per_DSA_sch )
    
  }
  
  res_DSV <- c("ambulance")
  if(DSV_holdout_flag){
    
    avg_hourly <- mobile_schedule$values %>% mean()
    hourly_holdout <- ceiling(DSV_holdout_perc * avg_hourly)
    
    holdout_schedule <- schedule(mobile_schedule$timetable,mobile_schedule$values*0 +hourly_holdout,period=Inf)
    #holdout_schedule <- mobile_schedule
    #holdout_schedule$values <- holdout_schedule$values*0 +hourly_holdout
    
    mobile_schedule <- schedule(mobile_schedule$timetable,mobile_schedule$values - hourly_holdout,period=Inf)
    
    res_DSV <- c(res_DSV,"ambulance_holdout")
    
    n_holdout <- ceiling(avg_hourly*DSV_holdout_perc)
    n_mobile <- n_mobile0 - n_holdout
    
  }
    
  if(flag_supply_schedule_file_hED && flag_supply_schedule_file && tamper_HO_flag==FALSE){ # ED seasonality with avg n_AEbays scaling
    
    t_ae_sch <- df_DSA_sch$Time
    n_AE_sch <- round(df_DSA_sch$ED_Enforced_torescale*n_AEbays/mean(df_DSA_sch$ED_Enforced_torescale),0) # assumes equal dt windows
    n_AE_sch[t_ae_sch>t_AEsupplyshock]=n_AE_sch[t_ae_sch>t_AEsupplyshock]+dn_AEsupplyshock # surge (equal offset)
    per_AE_sch <- Inf                      # doesnt repeat
    AEbay_schedule <- schedule(t_ae_sch,n_AE_sch,per_AE_sch)
    
  } else{
    
    t_ae_sch <- c(0 , t_AEsupplyshock)
    n_AE_sch <- c(n_AEbays , n_AEbays - dn_AEsupplyshock)
    per_AE_sch <- Inf                      # doesnt repeat
    AEbay_schedule <- schedule(t_ae_sch,n_AE_sch,per_AE_sch)
  }
  
  if(flag_balk_amb){
    nqueue_balk_imposed <- nqueue_balk
  } else{
    nqueue_balk_imposed <-Inf
    
  }
    
  # servers needed to deal with queue
  if(flag_demand_schedule){
    (c_needed <- (sum(df_demand_sch$Incident_Demand)*v_demand_conv["SeeConvey",]+sum(df_demand_sch$Direct_Demand))/max(df_demand_sch$Day))/r_AE
  } else{
    n_conv_day <- ambu_day * v_demand_conv["SeeConvey",]
    (c_needed <- (n_conv_day+direct_day_proxy)/r_AE)
  }
  print(n_AEbays)

  g.tmaxused <- ifelse(flag_demand_schedule,
                       df_demand_sch$Time %>% max() + df_demand_sch$Time[2],
                       g.tmax)
  
  # Adjust Cat2Conv if needed
  m_demand_cat2conv_enf <- m_demand_cat2conv_ori
  if(tamper_HT_flag){
    print("tamper HT")
    m_demand_cat2conv_enf$SeeTreat[3:4] <- m_demand_cat2conv_enf$SeeTreat[3:4] - tamper_HT_pp * 0.01
    m_demand_cat2conv_enf$HearTreat[3:4] <- m_demand_cat2conv_enf$HearTreat[3:4] + tamper_HT_pp * 0.01
  }
  
  if(tamper_ST_flag){
    print("tamper ST")
    m_demand_cat2conv_enf$SeeConvey[3:4] <- m_demand_cat2conv_enf$SeeConvey[3:4] - tamper_ST_pp * 0.01
    m_demand_cat2conv_enf$SeeTreat[3:4] <- m_demand_cat2conv_enf$SeeTreat[3:4] + tamper_ST_pp * 0.01
  }
  
  ############################################################################# ##
  ######### RUN                                                         ####### ##
  ############################################################################# ##
  set.seed(995)
  source(here::here("src","trajectory.R"));
  # Run simulation (multiple runs) - not parallelised ----------------------------------------------------------
  start_time <- Sys.time()
  #sims <- traj(1)
  sims <- lapply(1:nreps, traj)
  end_time <- Sys.time();print(end_time - start_time)
  
  ############################################################################# ##
  ######### POST-PROCESSING AND SAVE                                    ####### ##
  ############################################################################# ##
  
  source(here::here("src","post-processing.R"))
  source(here::here("src","save.R"))
  
};

############################################################################# ##
######### PLOTS                                                       ####### ##
############################################################################# ##
# plot_list %>% summary()
# plot_list  # uncomment to render all (may take 1-2 minutes)
plot_list$p_arri_cat_CM # uncomment to render specific. e.g. here demand by catxconv
plot_list$p_arri_cat_DnC # uncomment to render specific. e.g. here ambu demand by cat, with supply demand curve overlay
p_arri_cat_CMfreey
#plot_list$p_Kp_RT90_bp #+ ylim(0,1000) # uncomment to render specific. e.g. here Cat response time 90th KPI boxplot
#p_Kp_RT90_bp_freey
#plot_list$RU_instant # uncomment to render specific. e.g. here resource use cumulative
#p_ru
p_ru4
p2_KPI_cq_1_hour # validate hourly stack
#plot_list$p_Kp_handover_bp # uncomment to render specific. e.g. here handover KPI boxplot
p_Kp_handover_bp_y0
plot_list$p_Kp_RTmean_bp # uncomment to render specific. e.g. here Cat response time mean KPI boxplot
p_Kp_RTmean_bp_freey0

############################################################################# ##
######### WARNINGS                                                       ####### ##
############################################################################# ##
if(tamper_dsa_flag){warning("Tamper DSA enabled")}
if(tamper_HO_flag){warning("Tamper HO enabled")}
if(flag_dynamics){warning("Escalation - Conveyance changing dynamically")}
if(flag_renege){warning("Escalation - Reneging in place")}
if(flag_balk_amb){warning("Escalation - balking in place")}

