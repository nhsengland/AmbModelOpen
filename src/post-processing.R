## Date: 17/05/2023
## Overview: Discrete event simulation model for ambulance setting
## Author: Martina Fonseca, Jonathan Pearson, Digital Analytics and Research Team (DART)
## Stage: beta
## Current script: post-processing . post-processing of logs (data wrangling, rules) to arrive at relevant metric dataframes and graphs
## Dependencies: 
## Called by: main.R
##
############################################################################# ## 


### Save the raw post-processing logs  --------------------------------------------------------------

#saveRDS(dff_rc,here::here("Output", mydate,"attribs_rc.RDS"))
#saveRDS(dfr_rc,here::here("Output", mydate,"resources_rc.RDS"))
#save(df_scenarios,file=here::here("Output",mydate,"df_scenarios.RData"))
#save(df_params,file=here::here("Output",mydate,"df_params.RData"))

### Resource: utilisation ##

breakmax <- g.tmaxused/(24*60)-1
### Post-processing - log of resources ####
log_resources <- sims %>% get_mon_resources() %>% mutate(id=1)
#log_resources %>% View()

v_breaks <- seq(0,g.tmaxused,g.tday)

p_ru<-plot(get_mon_resources(sims), #%>% filter(time>24*60),
        metric = "usage",
        c(res_DSV,"AEbay"),
        items = c("queue","server"),
        steps=FALSE)+
  scale_x_continuous(breaks = v_breaks,
                     labels = seq(0,length(v_breaks)-1,1))+
  labs(x="Time (days)");

p_ru2<-plot(get_mon_resources(sims), #%>% filter(time>24*60),
         metric = "usage",
         c(res_DSV,"AEbay"),
         items = c("queue","server"),
         steps=TRUE)+
  scale_x_continuous(breaks = v_breaks,
                     labels = seq(0,length(v_breaks)-1,1))+
  labs(x="Time (days)");

p_ru3<-plot(get_mon_resources(sims), #%>% filter(time>24*60),
         metric = "usage",
         c(res_DSV),
         items = c("queue","server"),
         steps=TRUE)+
  scale_x_continuous(breaks = v_breaks,
                     labels = seq(0,length(v_breaks)-1,1))+
  labs(x="Time (days)");

p_ru32<-plot(get_mon_resources(sims), #%>% filter(time>24*60),
            metric = "usage",
            c("AEbay"),
            items = c("queue","server"),
            steps=TRUE)+
  scale_x_continuous(breaks = v_breaks,
                     labels = seq(0,length(v_breaks)-1,1))+
  labs(x="Time (days)");


#+
#labs(subtitle = paste0("% pre-handover unavoidable: ",now_prehandoverNAperc*100,"%\n Increment to off-site JCT (min): ",now_JCToffsiteincrement));

p_ru4<- plot(log_resources,
     metric="utilization",
     c(res_DSV, "AEbay"))

resources_rep <- log_resources %>%
  group_by(resource,replication) %>%
  filter(time > n_days_warm*g.tday) %>% 
  mutate(dtime = lead(time)-time) %>%
  summarise(utilization = sum(dtime*server,na.rm=T)/sum(dtime*capacity,na.rm=T)*100,
            queue = sum(dtime*queue,na.rm=T)/sum(dtime,na.rm=T))

resources_runsum <- resources_rep %>%
  summarise(mean_util=mean(utilization),sd_util=sd(utilization),mean_queue=mean(queue),sd_queue=sd(queue))


### Resource profiles - valid - hourly #

# IMPLEMENT ME #


###
### Post-processing - log of attributes ####
###

log_attributes <- sims %>% get_mon_attributes() %>% mutate(id=1)
#log_attributes %>% View()

log_attributes %>%
  filter(key %in% c("T_timetoscene","T_timeatscene","T_timetosite","T_unavprehand","T_timetoclear")) %>%
  group_by(key) %>%
  summarise(median=median(value,na.rm=T),
            mean=mean(value,na.rm=T),
            sd=sd(value,na.rm=T),
            n=n()) %>% print()

log_attributes_w <- log_attributes %>% # remove control vars
  filter(name!="") %>% # to remove globals
  filter(substr(name,1,5)!="Contr") %>% # remove control vars
  dplyr::select(-time) %>%
  pivot_wider(names_from = key,values_from=value)

log_attributes_w <- log_attributes_w %>% mutate(T_allocate = t_ambulanceseized-t_Rclockstart,
                                                T_prehandover = t_EDhandover-t_hospitalarrival,
                                                T_JCT=t_JCTend-t_Rclockstart,
                                                Kp_Tresponsetime=t_Rclockstop - t_Rclockstart,
                                                T_ED = t_EDclockstop-t_EDhandover)

t_att_LoS <- mean(log_attributes_w$LoS,na.rm=T) %>% print()

t_att_LoS_out <- log_attributes_w %>% filter(t_EDhandover> n_days_warm*g.tday) %>% group_by(Cat) %>% summarise(meanLoS=mean(LoS,na.rm=T),n=n()) %>% print()
t_att_LoS_out_rep <- log_attributes_w %>% filter(t_EDhandover> n_days_warm*g.tday) %>% group_by(Cat,replication) %>% summarise(meanLoS=mean(LoS,na.rm=T),n=n()) %>% print()


# Empirical JCT by Care Model
t_att_1<- log_attributes_w %>% filter(!is.na(Done),Done!=99) %>% mutate(T_JCT=t_JCTend-t_Rclockstart) %>%
  group_by(Convey) %>%
  summarise(median=median(T_JCT,na.rm=T),
            mean=mean(T_JCT,na.rm=T),
            sd=sd(T_JCT,na.rm=T),
            n=n()) %>% print()

# Empirical JCT overall
t_att_2<-log_attributes_w %>% filter(!is.na(Done)) %>% mutate(T_JCT=t_JCTend-t_Rclockstart) %>%
  summarise(median=median(T_JCT,na.rm=T),
            mean=mean(T_JCT,na.rm=T),
            sd=sd(T_JCT,na.rm=T),
            n=n())

# Empirical DCA time overall
t_att_2_DCA<-log_attributes_w %>% filter(!is.na(Done)) %>% mutate(T_DCA=t_JCTend-t_ambulanceseized) %>%
  summarise(median=median(T_DCA,na.rm=T),
            mean=mean(T_DCA,na.rm=T),
            sd=sd(T_DCA,na.rm=T),
            n=n())

# Validation elements
t_att_3<-log_attributes_w %>% group_by(Convey) %>%
  filter(t_Rclockstart>(n_days_warm*g.tday)) %>%
  mutate(n=n()) %>%
  summarise_at(c("T_allocate","T_prehandover","T_JCT","Kp_Tresponsetime","n"),list(mean=mean,median=median),na.rm=TRUE) %>% print()

t_att_5<-log_attributes_w %>% group_by(Cat) %>%
  filter(t_Rclockstart>(n_days_warm*g.tday)) %>%
  mutate(n=n()) %>%
  summarise_at(c("T_allocate","T_prehandover","T_JCT","Kp_Tresponsetime","n"),list(mean=mean,median=median),na.rm=TRUE) %>% print()

t_att_5_rep<-log_attributes_w %>% group_by(replication,Cat) %>%
  filter(t_Rclockstart>(n_days_warm*g.tday)) %>%
  mutate(n=n()) %>%
  summarise_at(c("T_allocate","T_prehandover","T_JCT","Kp_Tresponsetime","n"),list(mean=mean,median=median),na.rm=TRUE)


t_att_4<-log_attributes_w %>% group_by(Convey,Cat) %>%
  filter(t_Rclockstart>(n_days_warm*g.tday)) %>%
  mutate(n=n()) %>%
  summarise_at(c("T_allocate","T_prehandover","T_JCT","Kp_Tresponsetime","n"),list(mean=mean,median=median),na.rm=TRUE) %>% print()

t_att_6_rep<-log_attributes_w %>% group_by(replication) %>%
  filter(t_Rclockstart>(n_days_warm*g.tday)) %>%
  mutate(n=n()) %>%
  summarise_at(c("T_allocate","T_prehandover","T_JCT","Kp_Tresponsetime","n"),list(mean=mean,median=median,sd=sd),na.rm=TRUE) %>% print()

t_att_6_batch<-t_att_6_rep %>%
  summarise_all(list(mean=mean,sd=sd),na.rm=TRUE)


###
### KPI Post-processing - log of attributes - KPIs ####
###


###
#### KPI Post-processing - response time KPIs (analogy to AQI AmbSYS) ####
###

# Reference (dAC) - response time mean monthly
log_RT_val_month <- data.frame(Cat=c(1,2,3,4),RT_AmbSYS=c(8.5,50,200,250),month="Month1") %>%
  bind_rows(data.frame(Cat=c(1,2,3,4),RT_AmbSYS=c(9,90,300,250),month="Month2")) %>%
  bind_rows(data.frame(Cat=c(1,2,3,4),RT_AmbSYS=c(8,30,100,105),month="Month3"))

log_RT_val <- log_RT_val_month %>% filter(month==val_month)

# Reference (dAC) - response time mean time window
ref_RT_val_scenewin <- data.frame(Cat=c(1,2,3,4),RT_AmbSYS=c(NA,40,NA,NA),month="Month1") %>%
  bind_rows(data.frame(Cat=c(1,2,3,4),RT_AmbSYS=c(NA,100,NA,NA),month="Month2")) %>%
  bind_rows(data.frame(Cat=c(1,2,3,4),RT_AmbSYS=c(NA,20,NA,NA),month="Month3"))

ref_RT_val_win <- ref_RT_val_scenewin %>% filter(month==val_month)

## Log attributes - Calculate run-level summary for metrics . Filter to exclude warm-up
v_quantile <- function(vector,probs=c(0.5,0.75)){ # function to obtain quantiles as dataframe
  data.frame(as.list(quantile(vector,probs,na.rm=T)))
}  


log_RT_sim <- log_attributes_w %>%
  filter(Convey %in% c(1,2),t_Rclockstart>2*g.tday) %>% # see and convey or see and treat
  dplyr::select(id,replication,Cat,Convey,Kp_Tresponsetime) %>%
  group_by(id,replication,Cat) %>%
  summarise(
    quant_n = c(names(quantile(Kp_Tresponsetime,c(0.5,0.9),na.rm=T)),"mean","n"),
    quant=c(quantile(Kp_Tresponsetime,c(0.5,0.9),na.rm=T),mean(Kp_Tresponsetime,na.rm=T),n()))

log_RT_sim_batch <- log_RT_sim %>% group_by(id,Cat,quant_n) %>% summarise(Kn=c("Kmu","Ksd"),
                                                                         Kval=c(mean(quant),sd(quant)))

my_step <- g.tday

log_RT <- log_attributes_w %>%
  filter(Convey %in% c(1,2)) %>% # see and convey or see and treat
  mutate(step=(t_Rclockstart %/% my_step)*my_step) %>%
  dplyr::select(id,replication,step,Cat,Convey,Kp_Tresponsetime) %>%
  group_by(id,replication,step,Cat) %>%
  summarise(
    quant_n = c(names(quantile(Kp_Tresponsetime,c(0.5,0.9),na.rm=T)),"mean","n"),
    quant=c(quantile(Kp_Tresponsetime,c(0.5,0.9),na.rm=T),mean(Kp_Tresponsetime,na.rm=T),n()))
  
#View(log_RT)

v_breaks <- round(seq(min(log_RT$step), max(log_RT$step), by = g.tday),1)

# Plot = KPI response time mean, per category, per replication, per day
p_Kp_RTmean <- ggplot(data = log_RT %>% filter(quant_n=='mean',step<15*g.tday,replication<=3), aes(x=step,y=quant,colour=factor(Cat))) +
  geom_point() +
  geom_line(linetype="dashed")+
  geom_hline(data=ref_RT_val_win,aes(yintercept=RT_AmbSYS,colour=factor(Cat)),linetype="dotted",linewidth=0.6)+
  facet_grid(Cat~replication,scales="free_y") +
  labs(title="Response time mean (replication x category)",subtitle="Up to 3 first reps",x="Time (days)",y="Response times in minutes")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_continuous(breaks = v_breaks,
                   labels = seq(0,length(v_breaks)-1,1)); p_Kp_RTmean#+
  #ylim(0,g.tday)

# Plot = KPI response time 90th, per category, per replication, per day
p_Kp_RTmean_bp_freey <- ggplot(data = log_RT %>% filter(quant_n=='mean',step<15*g.tday), aes(x=factor(step),y=quant,colour=factor(Cat))) +
  geom_boxplot() +
  geom_hline(data=log_RT_val,aes(yintercept=RT_AmbSYS,colour=factor(Cat)),linetype="dashed",linewidth=0.5)+
  geom_hline(data=ref_RT_val_win,aes(yintercept=RT_AmbSYS,colour=factor(Cat)),linetype="dotted",linewidth=0.6)+
  geom_line(linetype="dashed")+
  facet_grid(Cat~.,scales="free_y") +
  labs(title="Response time mean (category)",subtitle="Boxplot for replication variation",x="Time (days)",y="Response times in minutes")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_discrete(breaks = v_breaks,
                   labels = seq(0,length(v_breaks)-1,1)); p_Kp_RTmean_bp_freey


p_Kp_RTmean_bp_freey0 <- p_Kp_RTmean_bp_freey + scale_y_continuous(limits=c(0,NA))

if(flag_saveplots){
  ggsave(paste0(output_folder,"/","plot_Kp_RTmean_bp_ref_freey_d14.png"),
         p_Kp_RTmean_bp_freey,
         units="cm",
         width=20,
         height=15)
  
  ggsave(paste0(output_folder,"/","plot_Kp_RTmean_bp_ref_freey0_d14.png"),
         p_Kp_RTmean_bp_freey0,
         units="cm",
         width=20,
         height=15)
  
}

p_Kp_RTmean_bp <- ggplot(data = log_RT %>% filter(quant_n=='mean',step<15*g.tday), aes(x=factor(step),y=quant,colour=factor(Cat))) +
  geom_boxplot() +
  geom_hline(data=log_RT_val,aes(yintercept=RT_AmbSYS,colour=factor(Cat)),linetype="dashed",linewidth=0.5)+
  geom_hline(data=ref_RT_val_win,aes(yintercept=RT_AmbSYS,colour=factor(Cat)),linetype="dotted",linewidth=0.6)+
  facet_wrap(.~Cat,nrow=1) +
  labs(title="Response time mean (category)",subtitle="Boxplot for replication variation",x="Time (days)",y="Response times in minutes")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_discrete(breaks = v_breaks,
                   labels = seq(0,length(v_breaks)-1,1)); p_Kp_RTmean_bp
#+ylim(0,550);

p_Kp_RTmean_bp_ylim <- p_Kp_RTmean_bp + ylim(0,1000)
if(flag_saveplots){
  ggsave(paste0(output_folder,"/","plot_Kp_RTmean_bp_d14.png"),
         p_Kp_RTmean_bp,
         units="cm",
         width=20,
         height=15)
  
  ggsave(paste0(output_folder,"/","plot_Kp_RTmean_bp_d14_ylim.png"),
         p_Kp_RTmean_bp_ylim,
         units="cm",
         width=20,
         height=15)
}

# Plot = KPI response time 90th, per category, per replication, per day

log_RT90_val_month <- data.frame(Cat=c(1,2,3,4),RT_AmbSYS=c(15,100,600,700),month="Month1") %>%
  bind_rows(data.frame(Cat=c(1,2,3,4),RT_AmbSYS=c(15,220,800,720),month="Month2")) %>%
  bind_rows(data.frame(Cat=c(1,2,3,4),RT_AmbSYS=c(15,55,240,260),month="Month3"))

log_RT90_val <- log_RT90_val_month %>% filter(month==val_month)


p_Kp_RT90 <- ggplot(data = log_RT %>% filter(quant_n=='90%',step<15*g.tday,replication<=3), aes(x=step,y=quant,colour=factor(Cat))) +
  geom_point() +
  geom_line(linetype="dashed")+
  facet_grid(Cat~replication,scales="free_y") +
  labs(title="Response time 90th (replication x category)",subtitle="Up to 3 first reps",x="Time (days)",y="Response times in minutes")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_continuous(breaks = v_breaks,
                     labels = seq(0,length(v_breaks)-1,1)); p_Kp_RT90

# Plot = KPI response time 90th, per category, per replication, per day
p_Kp_RT90_bp_freey <- ggplot(data = log_RT %>% filter(quant_n=='90%',step<15*g.tday), aes(x=factor(step),y=quant,colour=factor(Cat))) +
  geom_boxplot() +
  geom_hline(data=log_RT90_val,aes(yintercept=RT_AmbSYS,colour=factor(Cat)),linetype="dashed",linewidth=0.5)+
  facet_grid(Cat~.,scales="free_y") +
  labs(title="Response time 90th (category)",subtitle="Boxplot for replication variation",x="Time (days)",y="Response times in minutes")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_discrete(breaks = v_breaks,
                     labels = seq(0,length(v_breaks)-1,1)); p_Kp_RT90_bp_freey

if(flag_saveplots){
  ggsave(paste0(output_folder,"/","plot_Kp_RT90_bp_freey_d14.png"),
         p_Kp_RT90_bp_freey,
         units="cm",
         width=20,
         height=15)
}

p_Kp_RT90_bp <- ggplot(data = log_RT %>% filter(quant_n=='90%',step<15*g.tday), aes(x=factor(step),y=quant,colour=factor(Cat))) +
  geom_boxplot() +
  geom_hline(data=log_RT90_val,aes(yintercept=RT_AmbSYS,colour=factor(Cat)),linetype="dashed",linewidth=0.5)+
  facet_wrap(Cat~.,nrow=1) +
  labs(title="Response time 90th (category)",subtitle="Boxplot for replication variation",x="Time (days)",y="Response times in minutes")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_discrete(breaks = v_breaks,
                   labels = seq(0,length(v_breaks)-1,1)); p_Kp_RT90_bp

if(flag_saveplots){
  ggsave(paste0(output_folder,"/","plot_Kp_RT90_bp_d14.png"),
         p_Kp_RT90_bp,
         units="cm",
         width=20,
         height=15)
}

# Summary KPI per replication (across batch x scenarios), Long
log_attributes_w_runsum_l <- log_attributes_w %>%
  filter(t_Rclockstart > n_days_warm*g.tday) %>% 
  group_by(id,replication) %>%
  summarise(
    quant_n = c(names(quantile(t_Rclockstart,c(0.5,0.9),na.rm=T)),"mean"),
    quant=c(quantile(t_Rclockstart,c(0.5,0.9),na.rm=T),mean(T_allocate,na.rm=T)))

# Summary KPI per batch (across scenarios)
log_attributes_w_runsum_l_batch <- log_attributes_w_runsum_l %>%
  group_by(id,quant_n) %>% 
  #mutate(prehandoverNAperc = factor(prehandoverNAperc),
  #       JCToffsiteincrement = factor(JCToffsiteincrement)) %>% 
  summarise(Kp_Tresponsetime_Rq_Bmu=mean(quant,na.rm=T)) %>% 
  ungroup()


# Summary KPI per replication (across batch x scenarios), Wide
# https://stackoverflow.com/questions/22240816/dplyr-summarise-with-multiple-return-values-from-a-single-function
log_attributes_w_runsum <- log_attributes_w %>%
  filter(t_Rclockstart > n_days_warm*g.tday) %>% 
  group_by(id,replication) %>%
  summarise(quant=v_quantile(T_allocate,c(0.25,0.5,0.75,0.9)),
            desc=psych::describe(T_allocate,na.rm=T)) %>% 
  unpack(cols = c(quant,desc))

# Summary KPI per batch (across scenarios)
log_attributes_w_runsum_batch <- log_attributes_w_runsum %>%
  group_by(id) %>% 
  summarise(Kp_Tresponsetime_Rq50_Bmu = mean(X50.),
            Kp_Tresponsetime_Rq75_Bmu = mean(X75.),
            Kp_Tresponsetime_Rq90_Bmu = mean(X90.)) %>% 
  ungroup()




###
#### KPI Post-processing - handover time KPIs (analogy to amb sitrep) ####
###

ref_HO_val_month <- data.frame(quant_n=c("perc_delay30p","perc_delay60p","n_ambu","TLAHD"),quant=c(0.35,0.15,40000/30,15000/30),month="Month1") %>%
  bind_rows(data.frame(quant_n=c("perc_delay30p","perc_delay60p","n_ambu","TLAHD"),quant=c(0.45,0.25,40000/30,25000/30),month="Month2")) %>%
  bind_rows(data.frame(quant_n=c("perc_delay30p","perc_delay60p","n_ambu","TLAHD"),quant=c(0.30,0.13,40000/30,11000/30),month="Month3"))


ref_HO_val <- ref_HO_val_month %>% filter(month==val_month)

ref_HO_val_scenwin <- data.frame(quant_n=c("perc_delay30p","perc_delay60p","n_ambu","TLAHD"),quant=c(0.35,0.15,18000/14,7000/14),month="Month1") %>%
  bind_rows(data.frame(quant_n=c("perc_delay30p","perc_delay60p","n_ambu","TLAHD"),quant=c(0.45,0.3,18000/14,10000/14),month="Month2")) %>%
  bind_rows(data.frame(quant_n=c("perc_delay30p","perc_delay60p","n_ambu","TLAHD"),quant=c(0.20,0.1,18000/14,2000/14),month="Month3"))

ref_HO_val_win <- ref_HO_val_scenwin %>% filter(month==val_month)

log_Handover_pre <- log_attributes_w %>%
  filter(Convey %in% c(1),ConveyDestED==1)

ggplot(data=log_Handover_pre %>% filter(t_hospitalarrival>n_days_warm*g.tday),aes(x=T_prehandover))+
  geom_histogram(binwidth=15) + xlim(0,60*12)

KPI_HO_deciles <- quantile(log_Handover_pre %>% filter(t_hospitalarrival>n_days_warm*g.tday) %>% .$T_prehandover,
                           c(0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95),na.rm=T)
print(KPI_HO_deciles)
KPI_HO_deciles <- as.data.frame(KPI_HO_deciles)

log_Handover <- log_attributes_w %>%
  filter(Convey %in% c(1),ConveyDestED==1) %>% # see and convey; destination ED
  mutate(step=(t_EDhandover %/% my_step)*my_step) %>%
  dplyr::select(id,replication,step,T_prehandover) %>%
  group_by(id,replication,step) %>%
  summarise(
    #quant_n = c("TLAHD","n_delay3060","n_delay60p","n"),
    quant_n = c("n_delay3060",
                "n_delay60p",
                "n_ambu",
                "TLAHD",
                "perc_delay30p",
                "perc_delay60p",
                "n"),
    quant=c(sum(between(T_prehandover,30,60),na.rm=T),
            sum(T_prehandover>=60,na.rm=T),
            sum(T_prehandover>=0,na.rm=T),
            sum(ifelse(T_prehandover>=30,T_prehandover-30,0),na.rm=T)/60, # hours
            sum(T_prehandover>=30,na.rm=T)/sum(T_prehandover>=0,na.rm=T),
            sum(T_prehandover>=60,na.rm=T)/sum(T_prehandover>=0,na.rm=T),
            n()))

# overall. Replication-wise
log_Handover_overall <- log_attributes_w %>%
  filter(Convey %in% c(1),ConveyDestED==1,t_EDhandover> n_days_warm*g.tday) %>% # see and convey; destination ED
  dplyr::select(id,replication,T_prehandover,t_EDhandover) %>%
  group_by(id,replication) %>%
  summarise(
    #quant_n = c("TLAHD","n_delay3060","n_delay60p","n"),
    quant_n = c("n_delay3060",
                "n_delay60p",
                "n_ambu",
                "TLAHD",
                "n_days",
                "perc_delay30p",
                "perc_delay60p",
                "n"),
    quant=c(sum(between(T_prehandover,30,60),na.rm=T),
            sum(T_prehandover>=60,na.rm=T),
            sum(T_prehandover>=0,na.rm=T),
            sum(ifelse(T_prehandover>=30,T_prehandover-30,0),na.rm=T)/60, # hours
            (max(t_EDhandover)-min(t_EDhandover))/g.tday,
            sum(T_prehandover>=30,na.rm=T)/sum(T_prehandover>=0,na.rm=T),
            sum(T_prehandover>=60,na.rm=T)/sum(T_prehandover>=0,na.rm=T),
            n()))

# overall. Batch-wise
(log_Handover_overall_batch <- log_Handover_overall %>% group_by(id,quant_n) %>% summarise(Bmu_quant=mean(quant),Bsd_quant=sd(quant)))

# Plot = KPI response time mean, per category, per replication, per day
p_Kp_handover <- ggplot(data = log_Handover %>% filter(step<15*g.tday,quant_n %!in% c("n","n_delay3060","n_delay60p"),replication<=3), aes(x=step,y=quant,colour=factor(quant_n))) +
  geom_point() +
  geom_line(linetype="dashed")+
  geom_hline(data=ref_HO_val,aes(yintercept=quant,colour=quant_n),linetype="dashed",linewidth=0.5)+
  geom_hline(data=ref_HO_val_win,aes(yintercept=quant,colour=quant_n),linetype="dotted",linewidth=0.5)+
  facet_grid(quant_n~replication,scales="free_y") +
  labs(title="Handover KPIs",subtitle="Up to 3 first reps",x="Time (days)")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_continuous(breaks = v_breaks,
                     labels = seq(0,length(v_breaks)-1,1)); p_Kp_handover#+


if(flag_saveplots){
  ggsave(paste0(output_folder,"/","plot_Kp_HO_rep.png"),
         p_Kp_handover,
         units="cm",
         width=20,
         height=20)
}


p_Kp_handover_bp <- ggplot(data = log_Handover %>% filter(step<15*g.tday,quant_n %!in% c("n","n_delay3060","n_delay60p")), aes(x=factor(step),y=quant,colour=factor(quant_n))) +
  geom_boxplot() +
  geom_hline(data=ref_HO_val,aes(yintercept=quant,colour=quant_n),linetype="dashed",linewidth=0.5)+
  geom_hline(data=ref_HO_val_win,aes(yintercept=quant,colour=quant_n),linetype="dotted",linewidth=0.5)+
  facet_grid(quant_n~.,scales="free_y") +
  labs(title="Handover KPIs",subtitle="Boxplot for replication variation",x="Time (days)")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_discrete(breaks = v_breaks,
                     labels = seq(0,length(v_breaks)-1,1)); p_Kp_handover_bp#+

p_Kp_handover_bp_y0 <- p_Kp_handover_bp + scale_y_continuous(limits=c(0,NA))

p_Kp_handover_bp_y0_dac <- p_Kp_handover_bp_y0 + 
  #geom_point(data=df_validate,linetype='dotted',colour="red")+
  geom_path(data=df_validate,group=1,colour="gray",linetype="dashed")

if(flag_saveplots){
  ggsave(paste0(output_folder,"/","plot_Kp_HO_bp.png"),
         p_Kp_handover_bp ,
         units="cm",
         width=15,
         height=20)
  
  
  ggsave(paste0(output_folder,"/","plot_Kp_HO_bp_y0.png"),
         p_Kp_handover_bp_y0 ,
         units="cm",
         width=15,
         height=20)
}



ggplot(data=log_attributes_w %>%
         filter(Convey %in% c(1),ConveyDestED==1,t_EDhandover> n_days_warm*g.tday),aes(x=T_prehandover))+
  geom_histogram()+
  facet_wrap(.~Cat,scales="free_x")


###
#### KPI Post-processing - call queue, single scenario. Operations to give equal steps to average over ####
###

postproc_callqueue <- function(log_resources,my_step){

  log_callqueue <- log_resources %>% filter(resource=="ambulance") %>% dplyr::select(time,queue,replication)
  log_callqueue <- log_callqueue %>% mutate(step = (time %/% my_step)*my_step) %>% rename(value=queue)
  
  aux <- log_callqueue %>% group_by(replication,step) %>% summarise(value = sum(value*(time==max(time)))) %>%
    ungroup() %>% mutate(step=step+my_step,
                         time=step)
  log_callqueue_step <- log_callqueue %>% bind_rows(aux) %>% arrange(replication,step,time)
  
  log_callqueue_avstep <- log_callqueue_step %>% group_by(replication) %>%
    mutate(dtime = lead(time)-time) %>%
    group_by(replication,step) %>%
    summarise(queue = sum(dtime*value,na.rm=T)/sum(dtime,na.rm=T)) %>%
    ungroup()
  
  v_breaks <- round(seq(min(log_callqueue_avstep$step), max(log_callqueue_avstep$step), by = g.tday),1)
  p_KPI_cq_1 <- ggplot(data = log_callqueue_avstep, aes(x=factor(step),y=queue)) +
    geom_boxplot() +
    labs(title="Calls queued - non allocated (across replications)",x="Time (days)",y="Nr (time window avg)")+
    theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
    scale_x_discrete(breaks = v_breaks,
                     labels = seq(0,length(v_breaks)-1,1))+
    scale_y_continuous(limits=c(0,NA));p_KPI_cq_1
  
  p_KPI_cq_2 <- ggplot(data = log_callqueue_avstep, aes(x=factor(step),y=queue)) +
    geom_boxplot() +
    facet_wrap(.~replication) +
    labs(title="Calls queued - non allocated (across replications)",x="Time (days)",y="Nr (time window avg)")+
    theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
    scale_x_discrete(breaks = v_breaks,
                     labels = seq(0,length(v_breaks)-1,1))+scale_y_continuous(limits=c(0,NA));p_KPI_cq_2
  
  return(list(p_KPI_cq_1,p_KPI_cq_2,log_callqueue_avstep))
}

aa <- postproc_callqueue(log_resources,0.25*g.tday)
p_KPI_cq_1 <-aa[[1]]; p_KPI_cq_1
p_KPI_cq_2 <- aa[[2]]; p_KPI_cq_2

aa <- postproc_callqueue(log_resources,1*g.tday)
p_KPI_cq_1_day <-aa[[1]]; p_KPI_cq_1_day
p_KPI_cq_2_day <- aa[[2]] ; p_KPI_cq_2_day
log_CallQueue <- aa[[3]]

aa <- postproc_callqueue(log_resources,(1/24)*g.tday)
p_KPI_cq_1_hour <-aa[[1]]; p_KPI_cq_1_hour
#p_KPI_cq_2_day <- aa[2] ; p_KPI_cq_2_day
log_KPI_cq_1_hour<- aa[[3]]
log_KPI_cq_1_hour <- log_KPI_cq_1_hour %>% mutate(hour=step%/%60,hour_=hour%%24)

p_KPI_cq_1_hour <- ggplot(data = log_KPI_cq_1_hour, aes(x=factor(hour_),y=queue)) +
  geom_boxplot() +
  facet_wrap(.~replication) +
  labs(title="Calls queued - 24 hour",x="Hour of day",y="Nr (time window avg)")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10));p_KPI_cq_1_hour 


p2_KPI_cq_1_hour <- ggplot(data = log_KPI_cq_1_hour, aes(x=factor(hour_),y=queue)) +
  geom_boxplot() +
  labs(title="Calls queued - 24 hour",x="Hour of day",y="Nr (time window avg)")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10));p2_KPI_cq_1_hour
###
#### KPI Post-processing - site queue, single scenario. Operations to give equal steps to average over ####
###

postproc_sitequeue <- function(log_attributes,my_step){
  
  log_sitequeue <- log_attributes %>% filter(key=="site_queue") %>% dplyr::select(id,time,value,replication)
  log_sitequeue <- log_sitequeue %>% mutate(step = (time %/% my_step)*my_step)
  
  aux <- log_sitequeue %>% group_by(id,replication,step) %>% summarise(value = sum(value*(time==max(time)))) %>%
    ungroup() %>% mutate(step=step+my_step,
                         time=step)
  aux2 <- log_sitequeue %>% group_by(id,replication) %>% summarise(step=0,
                                                                   value=0,
                                                                   time=0) %>% ungroup()
  log_sitequeue_step <- log_sitequeue %>% bind_rows(aux) %>% bind_rows(aux2) %>% arrange(id,replication,step,time)
  
  log_sitequeue_avstep <- log_sitequeue_step %>% group_by(replication) %>%
    mutate(dtime = lead(time)-time) %>%
    group_by(id,replication,step) %>%
    summarise(sitequeue = sum(dtime*value,na.rm=T)/sum(dtime,na.rm=T)) %>%
    ungroup()
  
  v_breaks <- round(seq(min(log_sitequeue_avstep$step), max(log_sitequeue_avstep$step), by = g.tday),1)
  p_KPI_sq_1 <- ggplot(data = log_sitequeue_avstep, aes(x=factor(step),y=sitequeue)) +
    geom_boxplot() +
    facet_wrap(.~id) +
    labs(title="Average ambulances queueing at site over time (across replications)",x="Time (days)",y="Nr (time window avg)")+
    theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
    scale_x_discrete(breaks = v_breaks,
                     labels = seq(0,length(v_breaks)-1,1))+
    scale_y_continuous(limits=c(0,NA));p_KPI_sq_1
  
  p_KPI_sq_2 <- ggplot(data = log_sitequeue_avstep, aes(x=factor(step),y=sitequeue)) +
    geom_col() +
    facet_wrap(.~replication) +
    labs(title="Average ambulances queueing at site over time (per replication)",x="Time (days)",y="Nr (time window avg)")+
    theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
    scale_x_discrete(breaks = v_breaks,
                     labels = seq(0,length(v_breaks)-1,1))+
    scale_y_continuous(limits=c(0,NA));p_KPI_sq_2

  return(list(p_KPI_sq_1,p_KPI_sq_2,log_sitequeue_avstep))

}

aa <- postproc_sitequeue(log_attributes,0.25*g.tday)
p_KPI_sq_1 <-aa[[1]]; p_KPI_sq_1
p_KPI_sq_2 <- aa[[2]]; p_KPI_sq_2

aa <- postproc_sitequeue(log_attributes,1*g.tday)
p_KPI_sq_1_day <-aa[[1]]; p_KPI_sq_1_day
p_KPI_sq_2_day <- aa[[2]] ; p_KPI_sq_2_day
log_SiteQueue <- aa[[3]]

###
### Plotting arrivals (ambulance) ####
###

log_plot_arrivals <- log_attributes_w %>% dplyr::select(c("replication","Cat","Convey","t_Rclockstart","t_hospitalarrival")) %>%
  #filter(!is.na(Cat)) %>%
  mutate(Cat=ifelse(is.na(Cat),99,Cat),
         Convey=ifelse(is.na(Convey),99,Convey)) %>%
  mutate(time=ifelse(is.na(t_Rclockstart),t_hospitalarrival,t_Rclockstart))

my_step <- 60 # in minutes
log_plot_arrivals <- log_plot_arrivals %>% mutate(step = (time %/% my_step)*my_step )


aux <- log_plot_arrivals %>% group_by(replication,step) %>%
  summarise(n=n())


ggplot(data=aux,aes(x=step,y=n,colour=as.factor(replication)))+
  geom_step()

p_arri1 <- ggplot()+
  geom_col(data=aux,aes(x=step,y=n / (my_step/60),fill=as.factor(replication))) +
  geom_line(data=df_demand_sch,aes(x=Time,y=Incident_Demand+Direct_Demand))+
  facet_wrap(~replication,ncol=1)+
  labs(title="Demand (direct and calls)",x="Time (days)",y="Nr/hour (step time window)")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_continuous(breaks = round(seq(min(aux$step), max(aux$step), by = 1440),1),
                   labels = seq(0,breakmax,1)); p_arri1

aux_a <- log_plot_arrivals %>% filter(Convey!=99) %>% group_by(replication,step) %>%
  summarise(n=n())

p_arri2 <- ggplot()+
  geom_col(data=aux_a ,aes(x=step,y=n / (my_step/60),fill=as.factor(replication))) +
  geom_line(data=df_demand_sch,aes(x=Time,y=Incident_Demand))+
  facet_wrap(~replication,ncol=1)+
  labs(title="Demand (direct and calls)",x="Time (days)",y="Nr/hour (step time window)")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_discrete(breaks = round(seq(min(aux$step), max(aux$step), by = 1440),1),
                   labels = seq(0,breakmax,1)); p_arri2

# by category
aux2 <- log_plot_arrivals %>% group_by(replication,step,Cat) %>%
  summarise(n=n())


p_arri_cat <- ggplot()+
  geom_col(data=aux2,aes(x=step,y=n / (my_step/60),fill=as.factor(Cat))) +
  geom_line(data=df_demand_sch,aes(x=Time,y=Incident_Demand+Direct_Demand))+
  facet_wrap(~replication,ncol=1)+
  labs(title="Calls being made by Category",x="Time (days)",y="Nr/hour (step time window)")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_discrete(breaks = round(seq(min(aux$step), max(aux$step), by = 1440),1),
                   labels = seq(0,breakmax,1)); p_arri_cat


p_arri_cat_DnC <- ggplot()+
  geom_col(data=aux2 %>% filter(Cat!=99,replication<=3),aes(x=step,y=n / (my_step/60),fill=as.factor(Cat))) +
  geom_line(data=df_demand_sch,aes(x=Time,y=Incident_Demand))+
  geom_line(data=df_DSA_sch,aes(x=Time,y=DSV_Enforced*tamper_dsa_f),colour="red")+
  #geom_line(aes(x=mobile_schedule$timetable,y=mobile_schedule$values),colour="red")+
  facet_wrap(~replication,ncol=1)+
  labs(title="Calls being made by Category",subtitle="Supply schedule in red, Demand input in black",x="Time (days)",y="Nr/hour (step time window)",fill="Category",caption="Up to 3 reps")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_continuous(breaks = round(seq(min(aux$step), max(aux$step), by = 1440),1),
                   labels = seq(0,breakmax,1))

# by care model
aux2 <- log_plot_arrivals %>% group_by(replication,step,Convey) %>%
  summarise(n=n())


p_arri_CM <-ggplot()+
  geom_col(data=aux2,aes(x=step,y=n / (my_step/60),fill=as.factor(Convey))) +
  geom_line(data=df_demand_sch,aes(x=Time,y=Incident_Demand+Direct_Demand))+
  facet_wrap(~replication,ncol=1)+
  labs(title="Calls being made by Conveyance",x="Time (days)",y="Nr/hour (step time window)")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_continuous(breaks = round(seq(min(aux$step), max(aux$step), by = 1440),1),
                   labels = seq(0,breakmax,1)); p_arri_CM


aux2$Convey <- factor(aux2$Convey,rev(unique(aux2$Convey)))

ggplot()+
  geom_col(data=aux2 %>% filter(Convey!=99),aes(x=step,y=n / (my_step/60),fill=as.factor(Convey))) +
  facet_wrap(~replication,ncol=1)+
  #geom_line(data=df_demand_sch,aes(x=Time,y=Incident_Demand))+
  geom_line(data=df_DSA_sch,aes(x=Time,y=DSV_Enforced*tamper_dsa_f))+
  #geom_line(aes(x=mobile_schedule$timetable,y=mobile_schedule$values),colour="red")+
  labs(title="Calls being made by Conveyance, overlay supply schedule",x="Time (days)",y="Nr/hour (step time window)")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_continuous(breaks = round(seq(min(aux$step), max(aux$step), by = 1440),1),
                   labels = seq(0,breakmax,1))

# by category and care model (across replications)
aux3 <- log_plot_arrivals %>% group_by(step,Cat,Convey) %>%
  summarise(n=n())


p_arri_cat_CM <- ggplot()+
  geom_col(data=aux3,aes(x=step,y=n / (my_step*nreps/60),fill=as.factor(Convey))) +
  #geom_line(data=df_demand_sch,aes(x=Time,y=Demand))+
  facet_wrap(~Cat,ncol=1)+
  labs(title="Calls being made by Category, Conveyance",x="Time (days)",y="Nr/hour (step time window)")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_continuous(breaks = round(seq(min(aux$step), max(aux$step), by = 1440),1),
                   labels = seq(0,breakmax,1))

p_arri_cat_CMfreey <- ggplot()+
  geom_col(data=aux3,aes(x=step,y=n / (my_step*nreps/60),fill=as.factor(Convey))) +
  #geom_line(data=df_demand_sch,aes(x=Time,y=Demand))+
  facet_wrap(~Cat,ncol=1,scales="free_y")+
  labs(title="Calls being made by Category, Conveyance",x="Time (days)",y="Nr/(hour*replication) (step time window)")+
  theme(axis.text.x = element_text(angle = 0),text = element_text(size=10))+
  scale_x_continuous(breaks = round(seq(min(aux$step), max(aux$step), by = 1440),1),
                   labels = seq(0,breakmax,1))

###
### Post-processing - log of arrivals ####
###

log_arrivals <- sims %>% get_mon_arrivals()

plot(log_arrivals,
     metric="waiting_time",
     resources=c(c("ambulance", "AEbay")))

plot(log_arrivals,
     metric="flow_time",
     resources=c(c("ambulance", "AEbay")))

#log_arrivals %>% View()
log_arrivals %>% filter(activity_time!=0) %>% summarise(median=median(activity_time,na.rm=T),
                                                        mean=mean(activity_time,na.rm=T),
                                                        sd=sd(activity_time,na.rm=T),
                                                        n=n())

log_arrivals %>% filter(activity_time!=0,start_time<(7*24*60)) %>% summarise(median=median(activity_time,na.rm=T),
                                                                             mean=mean(activity_time,na.rm=T),
                                                                             sd=sd(activity_time,na.rm=T),
                                                                             n=n())



###
### Structure for plots ###
###

#plot_struc <- structure(list(plot=c(p,p2),
#                             name=c("Resource use cumul","Resource use instantaneous")),
#                        .Names=c("Plot object","Plot name"))

plot_list <- list("RU_cumul"=p_ru,
                  "RU_instant"=p_ru2,
                  "RU_instant_ambu"=p_ru3,
                  "RU_KPI"=p_ru4,
                  "p_arri1"=p_arri1,
                  "p_arri_cat"=p_arri_cat,
                  "p_arri_cat_DnC"=p_arri_cat_DnC,
                  "p_arri_CM"=p_arri_CM,
                  "p_arri_cat_CM" =p_arri_cat_CM,
                  "p_Kp_RTmean"=p_Kp_RTmean,
                  "p_Kp_RTmean_bp"=p_Kp_RTmean_bp,
                  "p_Kp_RT90"=p_Kp_RT90,
                  "p_Kp_RT90_bp"=p_Kp_RT90_bp,
                  "p_Kp_handover"=p_Kp_handover,
                  "p_Kp_handover_bp"=p_Kp_handover_bp)

#rm("p_ru","p_ru2","p_ru3","p_ru4","p_arri1","p_arri_cat","p_arri_CM","p_arri_cat_CM")


###
### Log of parameters - audit ###
###
parameter_list <- list(
  "scenario_folder"=scenario_folder,
  "mydate"=mydate,
  "nreps"=nreps,
  "row"=row,
  "id"=id,
  "df_scenarios"=df_scenarios,
  "flag_demand_schedule"=flag_demand_schedule,
  "flag_supply_schedule"=flag_supply_schedule,
  "flag_supply_schedule_file"=flag_supply_schedule_file,
  "flag_supply_schedule_file_hED"=flag_supply_schedule_file_hED,
  "v_resarriveperinc"=v_resarriveperinc,
  "T_window_hours"=T_window_hours,
  "n_windows_week"=n_windows_week,
  "flag_scenarios"=flag_scenarios,
  "T_AE"=T_AE,
  "r_AE"=r_AE,
  "n_AEbays"=n_AEbays,
  "t_AEsupplyshock"=t_AEsupplyshock,
  "dn_AEsupplyshock"=dn_AEsupplyshock,
  "tamper_dsa_flag"=tamper_dsa_flag,
  "tamper_dsa_f"=tamper_dsa_f,
  "tamper_HO_flag"=tamper_HO_flag,
  "tamper_HO_f"=tamper_HO_f,
  "tamper_HT_flag"=tamper_HT_flag,
  "tamper_HT_pp"=tamper_HT_pp,
  "tamper_ST_flag"=tamper_ST_flag,
  "tamper_ST_pp"=tamper_ST_pp,
  "DSV_holdout_flag"=DSV_holdout_flag,
  "DSV_holdout_perc"=DSV_holdout_perc,
  "DSV_holdout_use_minqueue"=DSV_holdout_use_minqueue,
  "flag_EDpriority_adjust"=flag_EDpriority_adjust,
  "p_direct_deprio"=p_direct_deprio,
  "flag_dynamics"=flag_dynamics,
  "T_window_escalation_hours"=T_window_escalation_hours,
  "flag_renege"=flag_renege,
  "T_renege"=T_renege,
  "p_renege_directED"=p_renege_directED,
  "flag_stepcat"= flag_stepcat,
  "T_stepcat"=T_stepcat,
  "catmin_stepcat"= catmin_stepcat,
  "catmin_renege"=catmin_renege,
  "flag_balk_amb"=flag_balk_amb,
  "nqueue_balk"=nqueue_balk,
  "dynamic_C3conv_standard"=dynamic_C3conv_standard,
  "dynamic_C3conv_coef"=dynamic_C3conv_coef,
  "val_month"=val_month,
  "flag_savedata_overallKPIs"=flag_savedata_overallKPIs,
  "flag_savedata_stepwiseKPIs"=flag_savedata_stepwiseKPIs,
  "flag_savedata_fulllogs"=flag_savedata_fulllogs,
  "flag_saveplots"=flag_saveplots,
  "flag_patientpathplot"=flag_patientpathplot,
  "df_demand_sch"=df_demand_sch,
  "flag_demand_schedule_variantcat"=flag_demand_schedule_variantcat,
  "v_demand_cat"=v_demand_cat,
  "m_demand_cat2conv"=m_demand_cat2conv,
  "m_acuity"=m_acuity,
  "v_demand_conv"=v_demand_conv,
  "v_conveyED"=v_conveyED,
  "JCT_type"=JCT_type,
  "df_DSA_sch"=df_DSA_sch,
  "g.debug"=g.debug,
  "n_days_week"=n_days_week,
  "g.tday"=g.tday,
  "ambu_day"=ambu_day,
  "n_days_warm"=n_days_warm,
  "n_days_study"=n_days_study,
  "g.T_allocatetomobilise"=g.T_allocatetomobilise,
  "g.T_traveltoscene",g.T_traveltoscene,
  "g.T_atscene"=g.T_atscene,
  "g.T_traveltohospital"=g.T_traveltohospital,
  "g.T_prehandover_LN"=g.T_prehandover_LN,
  "g.T_clear"=g.T_clear,
  "g.T_prehandoverXed"=g.T_prehandoverXed,
  "n_ru0"=n_ru0,
  "n_dsav0"=n_dsav0,
  "n_mobile0"=n_mobile0
)

saveRDS(parameter_list,file=paste0(output_folder,"/","parameterlistaudit.RData"))

write.xlsx(row,file=paste0(output_folder,"/","row.xlsx"))

write.xlsx(df_scenarios,file=paste0(output_folder,"/","df_scenarios.xlsx"))

#alist <- readRDS(paste0(output_folder,"/","parameterlistaudit.RData"))

