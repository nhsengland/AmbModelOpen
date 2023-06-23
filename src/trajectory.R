## Date: 17/05/2023
## Overview: Discrete event simulation model for ambulance setting
## Author: Martina Fonseca, Jonathan Pearson, Digital Analytics and Research Team (DART)
## Stage: beta
## Current script: trajectory definitions
## Dependencies: 
## Called by: main.R
##
############################################################################# ##

#https://stackoverflow.com/questions/55364348/simmer-in-r-modelling-changes-in-server-capacity-based-on-queue-length-and-dura
#https://stackoverflow.com/questions/67089345/r-simmer-reallocate-resource-between-pots-based-on-queue-size

traj <- function(ii){
  
  sim <- simmer("sim",log_level=g.debug)
  
 
  m_demand_cat2conv <<- m_demand_cat2conv_enf # reset original demand relations
  
  
  if(flag_supply_schedule){
    sim <- sim %>%
      add_resource("ambulance",mobile_schedule,queue_size=nqueue_balk_imposed) %>%
      add_resource("AEbay",AEbay_schedule) 
    
    if(DSV_holdout_flag){
      sim <- sim %>%
        add_resource(res_DSV[2],holdout_schedule,nqueue_balk_imposed)
    }
    
  }
  else
  {
   sim <- sim %>%
    add_resource("ambulance",n_mobile,queue_size=nqueue_balk_imposed) %>%
    add_resource("AEbay",n_AEbays)
   
   if(DSV_holdout_flag){
     sim <- sim %>%
       add_resource(res_DSV[2],n_holdout,nqueue_balk_imposed)
   }
   
  }
  
  
  
  f_hrate_to_profile <- function(dtime,sample_cat_dtime=FALSE,cat_time=NA){
    v_arriv<-vector()
    cat_arriv <- vector()
    for(i in 1:length(dtime)){
      rate_now <- dtime[i]
      rv_now <- rexp(rate_now+10,rate_now/60) # generate arrivals at relevant rate
      c_rv_now <- cumsum(rv_now) # absolute
      c_rv_now <- c_rv_now[c_rv_now<=60]# drop those beyond an hour
      c_rv_now <- c_rv_now + (i-1)*60
      v_arriv <- c(v_arriv,c_rv_now)
      if (sample_cat_dtime){
        prob_now <- cat_time[i,]
        c_cat_now <- sample(1:n_cats,length(c_rv_now),prob=prob_now,replace=TRUE)
        cat_arriv <- c(cat_arriv,c_cat_now)
      }
      
    }
    
    v_arriv <- as.data.frame(v_arriv)
    
    if (sample_cat_dtime){
      #v_arriv$Cat <- cat_arriv
      v_arriv$priority <- (n_cats+1) - cat_arriv
    }
    
    return(v_arriv)
  }
  
  
  if(flag_demand_schedule){
    v_arriv <- f_hrate_to_profile(df_demand_sch$Incident_Demand,sample_cat_dtime=flag_demand_schedule_variantcat,cat_time=df_demand_sch %>% dplyr::select(c("C1","C2","C3","C4")))
    df_varriv <<- as.data.frame(v_arriv)
    
    if(flag_demand_schedule_variantcat==FALSE){
      v_catsampled <- sample(1:n_cats,nrow(v_arriv),prob=v_demand_cat$Rel,replace=TRUE)
      df_varriv$priority <<- (n_cats+1) - v_catsampled
    }
    
    
    v_Darriv <- f_hrate_to_profile(df_demand_sch$Direct_Demand,sample_cat_dtime=FALSE)
    df_Dvarriv <<- as.data.frame(v_Darriv)
    
  } else {
    
    #patient_gen = function(prop){c(0,rexp(ambu_day*ndays,prop*ambu_day/(24*60)),-1)}  # https://r-simmer.org/articles/simmer-04-bank-1.html
    #patient_gen = function(prop){rexp(ambu_day*ndays,prop*ambu_day/(24*60))}
    patient_gen_C1 = function(){rexp(ambu_day_now*ndays,v_demand_cat$Rel[1]*ambu_day/(24*60))}
    patient_gen_C2 = function(){rexp(ambu_day_now*ndays,v_demand_cat$Rel[2]*ambu_day/(24*60))}
    patient_gen_C3 = function(){rexp(ambu_day_now*ndays,v_demand_cat$Rel[3]*ambu_day/(24*60))}
    patient_gen_C4 = function(){rexp(ambu_day_now*ndays,v_demand_cat$Rel[4]*ambu_day/(24*60))}
    patient_gen_D = function(){rexp(direct_day_proxy*ndays,direct_day_proxy/(24*60))}
    
  }
  
  
  
  
  # Branch where patient presents directly at ED
  patientD_directED <- trajectory() %>%
    log_("Direct AE",level=1) %>%
    set_attribute("t_hospitalarrival", function(){now(sim)}) %>%
    set_attribute(c("Acuity"),function() {
      Acuity <- sample(m_acuity$Acuity,1,prob=m_acuity$Direct)
    }) %>%
    set_prioritization(function(){
      acu <- get_attribute(sim, "Acuity")
      c((n_acuity-acu)*2-sample(c(1,0),1,prob=c(p_direct_deprio,1-p_direct_deprio)),99,FALSE)
    }
    ) %>%
    #set_prioritization(c(1,99,FALSE)) %>%
    seize("AEbay",1) %>%
    set_attribute("LoS", function(){v_LoS$LoS[5]}) %>%
    set_attribute("t_EDhandover", function(){now(sim)}) %>%
    timeout(function() {v_LoS$LoS[5]*60}) %>% # usually clearance less than time in a&e, but setting floor just in case
    release("AEbay",1) %>%
    set_attribute("t_EDclockstop", function(){now(sim)}) %>%
    set_attribute("Done",0) # signal job done, and done as direct ED (0)
  
  
  
  # Branch where patient reneges from incident stack after a given time
  path_renege <- trajectory() %>%
    log_("Reneged",level=1) %>%
    branch(
      function() (ifelse(runif(1) <= p_renege_directED ,1,2)),  # ED -> path 1 ; Pure renege -> path 2
      continue=c(T,T),
      patientD_directED, # acuity drawn as per any other direct ED... if this should depend on Cat3/4 probabilities, code needs changing.
      trajectory() %>%
        set_attribute("Done",99) # incomplete ambulance path with no ED appearance
      )
    
  
  # Branch where ambulance patient goes to ED
  patient_directED <- trajectory() %>%
    log_("Direct AE",level=1) %>%
    set_attribute(c("Acuity"),function() {
      cat <- as.integer(get_attribute(sim,"Cat"))
      Acuity <- sample(m_acuity$Acuity,1,prob=m_acuity[,paste0("C",cat)])
    }) %>%
    set_prioritization(function(){
      acu <- get_attribute(sim, "Acuity")
      c((n_acuity-acu)*2,99,FALSE)
      #cat <- as.integer(get_attribute(sim,"Cat"))
      #c(n_cats+1+0-cat,99,FALSE)
    }
    ) %>%
    seize("AEbay",1) %>%
    set_attribute("t_EDhandover", function(){now(sim)}) %>%
    #set_attribute("t_ambhandover", function(){now(sim)}) %>%
    timeout(function() {get_attribute(sim,"T_timetoclear")}) %>%
    #log_("release AE amb") %>%
    #release("ambulance",1) %>%  # despite patient not being with ambulance, it is to reflect time to clear post-handover. Only then release resource.
    release_selected(1) %>%
    #log_(function(){paste("SCend:Seize-select: ",get_seized_selected(sim),"Seized ambu: ",get_seized(sim,"ambulance"),"Seized ambuhold: ",get_seized(sim,"ambulance_holdout"))}) %>%
    set_global("site_queue",-1,mod="+") %>% # track queue size outside ED, decrement by 1
    set_attribute("t_ambclear", function(){now(sim)}) %>%
    set_attribute("t_JCTend", function(){now(sim)}) %>%
    timeout(function() {max(0,get_attribute(sim,"LoS")*60-get_attribute(sim,"T_timetoclear"))}) %>% # usually clearance less than time in a&e, but setting floor just in case
    release("AEbay",1) %>%
    set_attribute("t_EDclockstop", function(){now(sim)}) %>%
    set_attribute("Done",1) # signal job done, and done as S&C (1)
   
  
  # Branch where ambulance patient conveys to non-ED
  patient_conveyXED <- trajectory() %>%
    log_("Convey non-ED",level=1) %>%
    timeout(function() {g.T_prehandoverXed}) %>%
    timeout(function() {get_attribute(sim,"T_timetoclear")}) %>%
    release_selected(1) %>%
    #release("ambulance",1) %>%
    set_attribute("t_ambclear", function(){now(sim)}) %>%
    set_attribute("t_JCTend", function(){now(sim)}) %>%
    #log_(function(){paste("xEDend. Seize-select: ",get_seized_selected(sim),"Seized ambu: ",get_seized(sim,"ambulance"),"Seized ambuhold: ",get_seized(sim,"ambulance_holdout"))}) %>%
    set_attribute("Done",1.5) # signal job done, and done as S&C - nonED (1)
    
  
  # Branch where ambulance patient is conveyed
  patient_convey <- trajectory() %>%
    log_("Convey",level=1) %>%
    set_attribute(c("ConveyDestED","LoS"),function() {
      cat <- as.integer(get_attribute(sim,"Cat"))
      ConveyDestED <- sample(c(1,0),1,prob=c(v_conveyED$perc_toED[cat],1-v_conveyED$perc_toED[cat]))
      LoS <- v_LoS$LoS[cat]
      return(c(ConveyDestED,LoS))
    }) %>%
    timeout(function() {get_attribute(sim,"T_timetosite")}) %>%
    set_attribute("t_hospitalarrival", function(){now(sim)}) %>%
    log_("Hospital arrival",level=1) %>%
    branch(
      function() (ifelse(get_attribute(sim,"ConveyDestED")==1,1,2)), # ED => path1 ; nonED -> path2
      continue=c(T,T),
      trajectory() %>%
        set_global("site_queue",1,mod="+") %>% # track queue size outside ED, increment by 1
        set_global("events10pinshift",
                   function(){
                     ifelse(get_global(sim,"site_queue")>=no_ambulancesqueueingbreach,1,0)
                   },
                   mod="+"
        ) %>%
        timeout(function() get_attribute(sim,"T_unavprehand")) %>%
        join(patient_directED),
      patient_conveyXED
    )
  
  
  # Branch for hear and treat
  patient_hear_and_treat <- trajectory() %>%
    renege_abort() %>%
    #set_attribute("CAS",function(){TRUE})
    set_attribute("Done",3) %>% # signal job done, and done as H&T(3)
    set_attribute("t_JCTend", function(){now(sim)})
  
  # Branch for see and treat or see and convey (from seize point)
  patient_not_hear_and_treat_fromseize <- trajectory() %>%
    seize_selected(function() get_attribute(sim,"n_resources_allocate")) %>%
    #seize_selected(1) %>%
    #log_("grab") %>%
    #rollback(2,times=1) %>%
    #log_(function(){paste("Seize-select: ",get_seized_selected(sim),"Seized ambu: ",get_seized(sim,"ambulance"),"Seized ambuhold: ",get_seized(sim,"ambulance_holdout"))}) %>%
    #log_(function(){paste("allocate:",get_attribute(sim,"n_resources_allocate"),
    #                      "scene:",get_attribute(sim,"n_resources_arrive"),
    #                      "selected:",get_selected(sim),
    #                      "cm:",get_attribute(sim,"Convey"),
    #                      "cat:",get_attribute(sim,"Cat"))},level=2)%>%
    #seize("ambulance",function() get_attribute(sim,"n_resources_allocate")) %>% # this approach only grabs resource when the amount needed is available. Do sequential instead?
    #seize("ambulance",1) %>%
  renege_abort() %>%
    set_attribute("t_ambulanceseized", function(){now(sim)}) %>%
    log_(function(){paste("Allocated after: ",round(now(sim) - get_attribute(sim,"t_Rclockstart"),1))},level=2) %>% 
    timeout(g.T_allocatetomobilise) %>%
    timeout(function() get_attribute(sim,"T_timetoscene")) %>%
    set_attribute("t_Rclockstop", function(){now(sim)}) %>%
    log_(function(){paste("Clock-stop: ",round(now(sim) - get_attribute(sim,"t_clockstart"),))},level=2) %>%
    branch(function() ifelse(get_attribute(sim,"n_resources_allocate")==1|get_attribute(sim,"n_resources_arrive")==2,1,2), # 1 resource -> path 1 , more resources -> path2
           c(T,T),
           trajectory(), # do nothing. just continue
           trajectory() %>%
             #log_("release_alloc",level=0) %>%
             release_selected(function(){get_attribute(sim,"n_resources_allocate")-1})
           #log_(function(){paste("relalloc.Seize-select: ",get_seized_selected(sim),"Seized ambu: ",get_seized(sim,"ambulance"),"Seized ambuhold: ",get_seized(sim,"ambulance_holdout"))})
           #release("ambulance",function(){get_attribute(sim,"n_resources_allocate")-1}) # release all except one. Assumption of no time on scene for now despite getting there
    ) %>%
    timeout(function() {get_attribute(sim,"T_timeatscene")}) %>%
    branch(function() ifelse(get_attribute(sim,"n_resources_arrive")==2,2,1), # 1 resource arriving -> path 1 , more resources -> path2
           c(T,T),
           trajectory(), # do nothing. just continue
           trajectory() %>%
             #log_("release_arrive",level=0) %>%
             #log_(function(){paste("relarrive.Seize-select: ",get_seized_selected(sim),"Seized ambu: ",get_seized(sim,"ambulance"),"Seized ambuhold: ",get_seized(sim,"ambulance_holdout"))}) %>%
             #release("ambulance",function(){get_attribute(sim,"n_resources_arrive")-1}) # release all except one. Assumption of no time on scene for now despite getting there
             release_selected(function(){get_attribute(sim,"n_resources_arrive")-1})
    ) %>%
    branch(function() ifelse(get_attribute(sim,"Convey")==1,1,2), # S&C -> path 1 ; S&T -> path 2
           c(T,T),
           patient_convey,
           trajectory() %>%
             #release("ambulance",1) %>%
             #log_("release_main_st") %>%
             release_selected(1) %>%
             set_attribute("Done",2) %>% # signal job done, and done as S&T(2)
             #log_(function(){paste("STend. Seize-select: ",get_seized_selected(sim),"Seized ambu: ",get_seized(sim,"ambulance"),"Seized ambuhold: ",get_seized(sim,"ambulance_holdout"))}) %>%
             set_attribute("t_JCTend", function(){now(sim)})
    )
  
  # Branch for see and treat or see and convey
  patient_not_hear_and_treat <- trajectory() %>%
    #seize("ambulance",1) %>% # Q...
    set_attribute(c("n_resources_allocate","n_resources_arrive"),function(){
      cat <- as.integer(get_attribute(sim,"Cat"))
      n_resources_allocate <- sample(c(2,1),1,prob=c(v_resarriveperinc$odds2resalloc[cat],1-v_resarriveperinc$odds2resalloc[cat]))
      n_resources_arrive <- ifelse(n_resources_allocate>1,
                               sample(c(2,1),1,prob=c(v_resarriveperinc$odds2resarrive_given2resalloc[cat],1-v_resarriveperinc$odds2resarrive_given2resalloc[cat])),
                               1)
      return(c(n_resources_allocate,n_resources_arrive))
    }) %>%
    #log_(function(){paste("holdout:",ifelse(get_attribute(sim,"Cat")==1 & get_queue_count(sim, "ambulance")>100,1,2))},level=2)%>%
    branch(function() ifelse(DSV_holdout_flag,ifelse(get_attribute(sim,"Cat")==1 & get_queue_count(sim, "ambulance")>DSV_holdout_use_minqueue &  get_queue_count(sim, "ambulance_holdout")==0,1,2),2),
           # 
           c(T,T),
           trajectory() %>%
             select(
              res_DSV,"round-robin"
               #function(){
               #occ <- get_server_count(sim, res_DSV) + get_queue_count(sim, res_DSV)# AMEND ME. not right stand-up. amend
               #res_DSV[which.min(occ)[1]]
               #res_DSV[2]
             #}
             ),
           trajectory() %>%
             select("ambulance")
           ) %>%
    branch(
      function() (ifelse(get_attribute(sim,"Cat")>=catmin_stepcat && flag_stepcat,1,2)), # Cat3,4 => path1 ; H&T -> path2
      continue=c(T,T),
      trajectory() %>%
        renege_in(T_stepcat,
          out = trajectory() %>%
            set_prioritization(function(){ # if reneging, increase priority
              prio <- get_prioritization(sim)[1]
              c(prio+1,99,FALSE)}
            ) %>% 
            join(patient_not_hear_and_treat_fromseize) # if reneging, seize again now with new priority
            ),
      trajectory()) %>%
    join(patient_not_hear_and_treat_fromseize)
    
    
  
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
          rlnormprm <- tep_tts_cat_m1a[cat,,conv] #
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
            rlnormprm <- tep_tas_cat_m1a[cat,,conv] # 
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
            rlnormprm <- tep_ttsi_cat_m1a[cat,,conv] #
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
          rlnormprm <- tep_uph_cat_m1a[cat,,conv] # 
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
          rlnormprm <- tep_ttc_cat_m1a[cat,,conv] # 
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
      function() (ifelse(get_attribute(sim,"Cat")>=catmin_renege && flag_renege,1,2)), # Cat3,4 => path1 ; H&T -> path2
      continue=c(T,T),
      trajectory() %>%
        renege_in(
          T_renege,
          out = path_renege),
      trajectory()
    ) %>%
    branch(
      function() (ifelse(get_attribute(sim,"Convey")>=3,2,1)),  # Not H&T -> path 1 ; H&T -> path 2
      #function() (1),
      continue=c(T,T),
      patient_not_hear_and_treat,
      patient_hear_and_treat
    )
    
  
  # KPIs for performance over shift that then dictate triggers (up/down) use or escalation.
  # decide how to implement
  control_q_KPIS <- trajectory() %>%
    set_attribute(c("K_calls","K_HO30p","K_RT_c2mean"), function() {
      
      mon_attr <- get_mon_attributes(sim)
      
      log_attributes_w <- mon_attr %>% # remove control vars
        filter(name!="") %>% # to remove globals
        filter(substr(name,1,5)!="Contr") %>% # remove control vars
        dplyr::select(-time) %>%
        pivot_wider(names_from = key,values_from=value)
      
      K_calls <- log_attributes_w %>% filter(!is.na(Cat),
                                             between(t_Rclockstart,now(sim)-T_window_escalation_hours*60,now(sim))) %>% nrow() # KPI for overall incoming call demand in previous window

      K_RT_C2mean <- log_attributes_w %>%
        filter(Convey %in% c(1,2), Cat==2, between(t_Rclockstop,now(sim)-T_window_escalation_hours*60,now(sim))) %>% # CM involves site; Cat 2; events w clock stop in last time window
        mutate(Kp_Tresponsetime=t_Rclockstop - t_Rclockstart) %>%
        summarise(K_RT_C2_mean = mean(Kp_Tresponsetime,na.rm=T)) %>% .$K_RT_C2_mean

      K_HO30p <- log_attributes_w %>%
        filter(Convey %in% c(1),
               between(t_EDhandover,now(sim)-T_window_escalation_hours*60,now(sim))) %>% # CM involves conveyance; events w handover in previous time window
        mutate(T_prehandover = t_EDhandover-t_hospitalarrival) %>%
        summarise(perc_delay30p = sum(T_prehandover>=30,na.rm=T)/sum(T_prehandover>=0,na.rm=T)) %>% .$perc_delay30p
      
      return(c(K_calls,K_HO30p*100,K_RT_C2mean))
    }
    )
  
  # Control - dynamic changes to conveyance
  control_q <- trajectory() %>%
    log_("Control") %>%
    join(control_q_KPIS) %>%
    set_global("pconvey_C3_scene",
               function(){
      
      K_calls<-get_attribute(sim,"K_calls")
      K_HO30p<-get_attribute(sim,"K_HO30p")
      K_RT_C2mean<-get_attribute(sim,"K_RT_c2mean")
      
      Kz_calls <- (K_calls-dynamic_C3conv_standard["Kz_calls","mean"])/dynamic_C3conv_standard["Kz_calls","sd"]
      Kz_RT_C2mean <- (K_RT_C2mean-dynamic_C3conv_standard["Kz_RT_C2mean","mean"])/dynamic_C3conv_standard["Kz_RT_C2mean","sd"]
      Kz_HO30p <- (K_HO30p-dynamic_C3conv_standard["Kz_HO30p","mean"])/dynamic_C3conv_standard["Kz_HO30p","sd"]
      
      pconvey_C3_scene <- func_dynamic_C3conv(Kz_calls,Kz_RT_C2mean,Kz_HO30p)
      
      perc_conv <- m_demand_cat2conv[3,"SeeConvey"]+m_demand_cat2conv[3,"SeeTreat"] # conveyance rate cat 3
      
      m_demand_cat2conv[3,"SeeConvey"]<<- pconvey_C3_scene * perc_conv # to affect src global
      m_demand_cat2conv[3,"SeeTreat"]<<- (1-pconvey_C3_scene) * perc_conv # to affect src global
      return(pconvey_C3_scene)
    }
    )
  
  # Path plotted ------------------------------------------------------------
  # decide whether relevant to implement
  # Path plotted ------------------------------------------------------------
  if (flag_patientpathplot){
    p<- patient %>% plot()
    saveWidget(p, here::here("Output",mydate,paste0("pathway_patient.html")))
    #webshot::webshot(here::here("Output",mydate,paste0("v05_patient_pathway_generic.html")),here::here("Output",mydate,paste0("v05_patient_pathway_generic.png")))
    
    p<- patient_hear_and_treat %>% plot()
    saveWidget(p, here::here("Output",mydate,paste0("pathway_patient_hear_and_treat.html")))
    
    p<- patient_not_hear_and_treat %>% plot()
    saveWidget(p, here::here("Output",mydate,paste0("pathway_patient_not_hear_and_treat.html")))
    
    p<- patientD_directED %>% plot()
    saveWidget(p, here::here("Output",mydate,paste0("pathway_patientD_direct_ED.html")))
    
    p<- patientD_directED %>% plot()
    saveWidget(p, here::here("Output",mydate,paste0("pathway_patient_direct_ED.html")))
    
    flag_patientpathplot = FALSE # only do this once.
  }
  
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
                    col_time="v_arriv")
    
    
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
  
  if (flag_dynamics){
    
    sim <- sim %>% add_generator("Control_Q",
                                 control_q,
                                 at(seq(T_window_escalation_hours*60,g.tmaxused,T_window_escalation_hours*60)),
                                 mon=2
    )
  }
  
  
  
  
  
  
  
  ### Run ###
  sim %>% run(until=g.tmaxused)
}