## Date: 20/01/2023
## Overview: Discrete event simulation model for ambulance setting
## Author: Martina Fonseca, Digital Analytics and Research Team (DART)
## Stage: alpha / rapid prototype
## Current script: trajectory definitions
## Dependencies: 
## Called by: main.R
##
############################################################################# ##

#https://stackoverflow.com/questions/55364348/simmer-in-r-modelling-changes-in-server-capacity-based-on-queue-length-and-dura
#https://stackoverflow.com/questions/67089345/r-simmer-reallocate-resource-between-pots-based-on-queue-size

traj <- function(ii){
  
  sim <- simmer("sim",log_level=g.debug)
  
 
  
  
  
  if(flag_supply_schedule){
    sim <- sim %>%
      add_resource("ambulance",mobile_schedule) %>%
      #add_resource("cohortbay",0,queue_size=0) %>%
      add_resource("AEbay",AEbay_schedule)     
  }
  else
  {
   sim <- sim %>%
    add_resource("ambulance",n_mobile0) %>%
    #add_resource("cohortbay",0,queue_size=0) %>%
    add_resource("AEbay",n_AEbays)  
  }
  
  
  v <- c(4,2,2,2,2,6,7,8,9,10,10,10,10,10,10,10,10,10,10,10,10,8,6,6)
  
  f_hrate_to_profile <- function(dtime){
    v_arriv<-vector()
    for(i in 1:length(dtime)){
      rate_now <- dtime[i]
      rv_now <- rexp(rate_now+10,rate_now/60) # generate arrivals at relevant rate
      c_rv_now <- cumsum(rv_now) # absolute
      c_rv_now <- c_rv_now[c_rv_now<=60]# drop those beyond an hour
      c_rv_now <- c_rv_now + (i-1)*60
      v_arriv <- c(v_arriv,c_rv_now)
    }
    return(v_arriv)
  }
  
  
  if(flag_demand_schedule){
    v_arriv <- f_hrate_to_profile(df_demand_sch$Incident_Demand)
    df_varriv <<- as.data.frame(v_arriv)
    v_catsampled <- sample(1:n_cats,length(v_arriv),prob=v_demand_cat$Rel,replace=TRUE)
    df_varriv$priority <<- (n_cats+1) - v_catsampled
    
    v_Darriv <- f_hrate_to_profile(df_demand_sch$Direct_Demand)
    df_Dvarriv <<- as.data.frame(v_Darriv)
    
  } else {
    
    #patient_gen = function(prop){c(0,rexp(ambu_day*ndays,prop*ambu_day/(24*60)),-1)}  # https://r-simmer.org/articles/simmer-04-bank-1.html
    #patient_gen = function(prop){rexp(ambu_day*ndays,prop*ambu_day/(24*60))}
    patient_gen_C1 = function(){rexp(ambu_day_now*ndays,v_demand_cat$Rel[1]*ambu_day/(24*60))}
    patient_gen_C2 = function(){rexp(ambu_day_now*ndays,v_demand_cat$Rel[2]*ambu_day/(24*60))}
    patient_gen_C3 = function(){rexp(ambu_day_now*ndays,v_demand_cat$Rel[3]*ambu_day/(24*60))}
    patient_gen_C4 = function(){rexp(ambu_day_now*ndays,v_demand_cat$Rel[4]*ambu_day/(24*60))}
    patient_gen_D = function(){rexp(direct_day_proxy*ndays,direct_day_proxy/(24*60))}
    
    # patient_gen_C1 = function(){rexp(ambu_day*ndays,1*ambu_day/(24*60))}
    # patient_gen_C2 = function(){rexp(ambu_day*ndays,0*ambu_day/(24*60))} 
    # patient_gen_C3 = function(){rexp(ambu_day*ndays,0*ambu_day/(24*60))} 
    # patient_gen_C4 = function(){rexp(ambu_day*ndays,0*ambu_day/(24*60))}
    
  }
  
  
  
  
  # Branch where patient presents directly at ED
  patientD_directED <- trajectory() %>%
    log_("Direct AE",level=1) %>%
    set_attribute("t_hospitalarrival", function(){now(sim)}) %>%
    set_attribute(c("Acuity"),function() {
      Acuity <- sample(v_direct_acuity$Acuity,1,prob=v_direct_acuity$Direct)
    }) %>%
    set_prioritization(function(){
      acu <- get_attribute(sim, "Acuity")
      c(n_acuity-acu,99,FALSE)
    }
    ) %>%
    #set_prioritization(c(1,99,FALSE)) %>%
    seize("AEbay",1) %>%
    timeout(function() {max(0,T_AE_min)}) %>% # usually clearance less than time in a&e, but setting floor just in case
    release("AEbay",1) %>%
    set_attribute("t_EDclockstop", function(){now(sim)}) %>%
    set_attribute("Done",1) # signal job done, and done as S&C (1)
  
  
  
  
  
  
  # Branch where ambulance patient goes to ED
  patient_directED <- trajectory() %>%
    log_("Direct AE",level=1) %>%
    set_attribute("RRS_use",function(){FALSE}) %>%
    seize("AEbay",1) %>%
    set_attribute("t_EDhandover", function(){now(sim)}) %>%
    #set_attribute("t_ambhandover", function(){now(sim)}) %>%
    timeout(function() {get_attribute(sim,"T_timetoclear")}) %>%
    release("ambulance",1) %>%  # despite patient not being with ambulance, it is to reflect time to clear post-handover. Only then release resource.
    set_global("site_queue",-1,mod="+") %>% # track queue size outside ED, decrement by 1
    set_attribute("t_ambclear", function(){now(sim)}) %>%
    set_attribute("t_JCTend", function(){now(sim)}) %>%
    timeout(function() {max(0,T_AE_min-get_attribute(sim,"T_timetoclear"))}) %>% # usually clearance less than time in a&e, but setting floor just in case
    release("AEbay",1) %>%
    set_attribute("t_EDclockstop", function(){now(sim)}) %>%
    set_attribute("Done",1) # signal job done, and done as S&C (1)
    
  
  
  # Branch for hear and treat
  patient_hear_and_treat <- trajectory() %>%
    #set_attribute("CAS",function(){TRUE})
    set_attribute("Done",3) %>% # signal job done, and done as H&T(3)
    set_attribute("t_JCTend", function(){now(sim)})
  
  
  # Branch for see and treat or see and convey
  patient_not_hear_and_treat <- trajectory() %>%
    seize("ambulance",1) %>% # Q...
    set_attribute("t_ambulanceseized", function(){now(sim)}) %>%
    log_(function(){paste("Allocated after: ",round(now(sim) - get_attribute(sim,"t_Rclockstart"),1))},level=2) %>% 
    timeout(g.T_allocatetomobilise) %>%
    timeout(function() get_attribute(sim,"T_timetoscene")) %>%
    set_attribute("t_Rclockstop", function(){now(sim)}) %>%
    log_(function(){paste("Clock-stop: ",round(now(sim) - get_attribute(sim,"t_clockstart"),))},level=2) %>%
    timeout(function() {get_attribute(sim,"T_timeatscene")}) %>%
    branch(function() ifelse(get_attribute(sim,"Convey")==1,1,2), # S&C -> path 1 ; S&T -> path 2
           c(T,T),
           trajectory() %>%
             timeout(function() {get_attribute(sim,"T_timetosite")}) %>%
             set_attribute("t_hospitalarrival", function(){now(sim)}) %>%
             log_("Hospital arrival",level=1) %>%
             set_attribute("T_prehandover", function() rlnorm(1,g.T_prehandover_LN[1],g.T_prehandover_LN[2])+g.T_prehandover_LN[3]) %>%
             set_attribute("T_NAprehandover", function() {get_attribute(sim,"T_prehandover")*g.T_prehandoverNAperc}) %>% 
             set_attribute("T_BNprehandover", function() {get_attribute(sim,"T_prehandover")*(1-g.T_prehandoverNAperc)}) %>% 
             log_(function(){paste0("T_prehandover: ",get_capacity(sim, "bay"))},level=2) %>%
             log_(function(){paste0("Period - prehandover: ",get_attribute(sim,"T_prehandover"))},level=2) %>%
             log_(function(){paste0("Period - non avoidable prehandover: ",get_attribute(sim,"T_NAprehandover"))},level=2) %>%
             log_(function(){paste0("Period - bottle neck prehandover: ",get_attribute(sim,"T_BNprehandover"))},level=2) %>%
             set_global("site_queue",1,mod="+") %>% # track queue size outside ED, increment by 1
             set_global("events10pinshift",
                        function(){
                          ifelse(get_global(sim,"site_queue")>=no_ambulancesqueueingbreach,1,0)
                        },
                        mod="+"
             ) %>%
             timeout(function() get_attribute(sim,"T_unavprehand")) %>%
             join(patient_directED),
           trajectory() %>%
             release("ambulance",1) %>%
             set_attribute("Done",2) %>% # signal job done, and done as S&T(2)
             set_attribute("t_JCTend", function(){now(sim)})
           )
    
  
  patient_debug <-
    trajectory("Patient path") %>%
    #set_attribute(c("Cat"),2) %>%
    set_attribute(c("Cat","Convey"),function() {

      cat <- get_prioritization(sim)[1]
      conv <- sample(vi_conv,1,prob=m_demand_cat2conv[as.integer(cat) ,])

      return(c(cat,conv))
    }
    ) %>%
    timeout(0)
  
  
  
  
  ### start of trajectory ###
  patient <-
    trajectory("Patient path") %>%
    set_attribute(c("Cat","Convey","T_timetoscene","T_timeatscene","T_timetosite","T_unavprehand","T_timetoclear"),function() {
      
      cat <- (n_cats+1)-get_prioritization(sim)[1]
      conv <- sample(vi_conv,1,prob=m_demand_cat2conv[as.integer(cat) ,])

      # initialise
      x=NA_real_
      x_tas=NA_real_
      x_ttsi=NA_real_
      x_uph=NA_real_
      x_ttc=NA_real_
      
      if(conv<3){ # if not hear and treat
        # timetoscene
        if(JCT_type["tts"]=="Quantiles"){
          v_quants <- teq_tts_cat_m1a[cat,,conv]
          my_q <- sample(1:(length(v_quants)-1),size=1) # sample a quantile
          x=runif(1,min=v_quants[my_q],max=v_quants[my_q+1]) # sample uniformly from within the quantile ("piecewise constant")
          #x=1
        }
        else if(JCT_type["tts"]=="Style"){
          rlnormprm <- tep_tts_cat_m1a[cat,,conv] # 2 secs rather than 1 but nothing like the 30 secs gotten with the df filter!
          rlnormprm_type <- tail(rlnormprm,1)
          rlnormprm <- as.double(rlnormprm)
          x = switch(
            rlnormprm_type,
            "rlnorm"=rlnorm(1,rlnormprm[1],rlnormprm[2]),
            "cons"=rlnormprm[1]
          )
        }
        else{
          x=g.T_traveltoscene
        }
        
        # timeatscene
        if(JCT_type["tas"]=="Quantiles"){
          v_quants <- teq_tas_cat_m1a[cat,,conv]
          my_q <- sample(1:(length(v_quants)-1),size=1) # sample a quantile
          x_tas=runif(1,min=v_quants[my_q],max=v_quants[my_q+1]) # sample uniformly from within the quantile ("piecewise constant")
          #x=1
          }
          else if(JCT_type["tas"]=="Style"){
            rlnormprm <- tep_tas_cat_m1a[cat,,conv] # 2 secs rather than 1 but nothing like the 30 secs gotten with the df filter!
            rlnormprm_type <- tail(rlnormprm,1)
            rlnormprm <- as.double(rlnormprm)
            x_tas = switch(
              rlnormprm_type,
              "rlnorm"=rlnorm(1,rlnormprm[1],rlnormprm[2]),
              "cons"=rlnormprm[1]
            )
          }
          else{
            x_tas=g.T_atscene
          }

        if(conv<2){ # if see-and-treat
          # timetosite
          if(JCT_type["ttsi"]=="Quantiles"){
            v_quants <- teq_ttsi_cat_m1a[cat,,conv]
            my_q <- sample(1:(length(v_quants)-1),size=1) # sample a quantile
            x_ttsi=runif(1,min=v_quants[my_q],max=v_quants[my_q+1]) # sample uniformly from within the quantile ("piecewise constant")
            #x=1
          }
          else if(JCT_type["ttsi"]=="Style"){
            rlnormprm <- tep_ttsi_cat_m1a[cat,,conv] # 2 secs rather than 1 but nothing like the 30 secs gotten with the df filter!
            rlnormprm_type <- tail(rlnormprm,1)
            rlnormprm <- as.double(rlnormprm)
            x_ttsi = switch(
              rlnormprm_type,
              "rlnorm"=rlnorm(1,rlnormprm[1],rlnormprm[2]),
              "cons"=rlnormprm[1]
            )
          }
          else{
            x_ttsi=g.T_traveltohospital
          }

        # time unavoidable prehandover
        if(JCT_type["uph"]=="Quantiles"){
          v_quants <- teq_uph_cat_m1a[cat,,conv]
          my_q <- sample(1:(length(v_quants)-1),size=1) # sample a quantile
          x_uph=runif(1,min=v_quants[my_q],max=v_quants[my_q+1]) # sample uniformly from within the quantile ("piecewise constant")
          #x=1
        }
        else if(JCT_type["uph"]=="Style"){
          rlnormprm <- tep_uph_cat_m1a[cat,,conv] # 2 secs rather than 1 but nothing like the 30 secs gotten with the df filter!
          rlnormprm_type <- tail(rlnormprm,1)
          rlnormprm <- as.double(rlnormprm)
          x_uph = switch(
            rlnormprm_type,
            "rlnorm"=rlnorm(1,rlnormprm[1],rlnormprm[2]),
            "cons"=rlnormprm[1]
          )
        }
        else{
          x_uph=vec_prehandoverNAperc * g.T_prehandover_LN_mean
        }


        if(JCT_type["ttc"]=="Quantiles"){
          v_quants <- teq_ttc_cat_m1a[cat,,conv]
          my_q <- sample(1:(length(v_quants)-1),size=1) # sample a quantile
          x_ttc=runif(1,min=v_quants[my_q],max=v_quants[my_q+1]) # sample uniformly from within the quantile ("piecewise constant")
          #x=1
        }
        else if(JCT_type["ttc"]=="Style"){
          rlnormprm <- tep_ttc_cat_m1a[cat,,conv] # 2 secs rather than 1 but nothing like the 30 secs gotten with the df filter!
          rlnormprm_type <- tail(rlnormprm,1)
          rlnormprm <- as.double(rlnormprm)
          x_ttc = switch(
            rlnormprm_type,
            "rlnorm"=rlnorm(1,rlnormprm[1],rlnormprm[2]),
            "cons"=rlnormprm[1]
          )
        }
        else{
          x_ttc=g.T_clear
        }
          }
      }
      
      return(c(cat,conv,x,x_tas,x_ttsi,x_uph,x_ttc))
    }  ) %>%
    
    log_("Patient waiting to be assigned",level=1) %>%
    set_attribute("t_Rclockstart", function(){now(sim)}) %>%
    branch(
      function() (ifelse(get_attribute(sim,"Convey")>=3,2,1)),  # Not H&T -> path 1 ; H&T -> path 2
      #function() (1),
      continue=c(T,T),
      patient_not_hear_and_treat,
      patient_hear_and_treat
    )
    
  
  # KPIs for performance over shift that then dictate triggers (up/down) use or escalation.
  # decide how to implement
  
  
  # Control whether to trigger RRSBays resource up or down
  # decide whether relevant to implement
  
  
  
  # Path plotted ------------------------------------------------------------
  # decide whether relevant to implement

  
  ### Add generator ###
  
  if(flag_demand_schedule){
    sim <- sim %>% add_dataframe(name_prefix="Patient",
                                 trajectory=patient,
                                 data=df_varriv,
                                 mon=2,
                                 time="absolute",
                                 col_time="v_arriv",
                                 col_priority="priority") %>%
      add_dataframe(name_prefix="PatientD_",
                    trajectory=patientD_directED,
                    data=df_Dvarriv,
                    mon=2,
                    time="absolute",
                    col_time="v_Darriv")
    
    
  } else{
    
    sim <- sim %>% add_generator("PatientC1_",
                                 patient,
                                 patient_gen_C1,
                                 mon=2,
                                 priority=4) %>% # https://stackoverflow.com/questions/50367760/r-simmer-using-set-attribute-and-get-attribute-and-replication-using-lapply
      add_generator("PatientC2_",
                    patient,
                    patient_gen_C2,
                    mon=2,
                    priority=3) %>%
      add_generator("PatientC3_",
                    patient,
                    patient_gen_C3,
                    mon=2,
                    priority=2) %>%
      add_generator("PatientC4_",
                    patient,
                    patient_gen_C4,
                    mon=2,
                    priority=1) %>%
      add_generator("PatientD_",
                    patientD_directED,
                    patient_gen_D,
                    mon=2,
                    priority=0)
    #
  }
    # 
  
  
  ### Add trigger generator
  # decide whether relevant to implement
  
  
  
  
  
  
  
  
  
  
  ### Run ###
  sim %>% run(until=g.tmaxused)
}