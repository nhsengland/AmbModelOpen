####
# This script takes the post-processed log_attributes_w.xlsx file from a simulation, takes relevant events and metrics, and turns it into an event log format for BupaR.
# that can be used for process mining.
# In practice, the original raw output of monitor_attributes() in Simmer will already be in event log (long) format . However,
# Since we a) kept a more post-processed version that is in wide format (per patient) ; b) not all events were explicitly stored during simulation as standalone timestamps
# the below reformats into the relevant core event log


### Load libraries ####
#######################
library(here)
library(bupaR)
library(processmapR)
library(tidyverse)
library(processanimateR)
library(webshot)
library(htmlwidgets)
library(openxlsx)
webshot::install_phantomjs()
`%!in%` = Negate(`%in%`)

#### Define AmbModelOpen attribute log interest (log_attributes_w.xlsx) to format into event log ####
#######################
myfolder <- "example_outputs" # path with outputs
mydate <- "Fake_Scenario1A_1" # file with outputs
attrib_log <- read.xlsx(here::here(myfolder,mydate,"log_attributes_w.xlsx"))
log_attributes_l <- attrib_log

#### Format to standard event log with relevant attributes ####
#######################

myid = 1  # choose a scenario id
myrep = 1 # choose a replication

# Add relevant timestamps
# Note: in our simulation model we did not make attributes_log hold all individual timestamps for efficiency and redundancy. Since time intervals and t0 are kept,  timestamps can be derived as seen below
forevent_w <- attrib_log %>%
  filter(id==myid,replication==myrep) %>%  # filter to desired id and replication
  filter(!is.na(Done)) %>% # filter unfinished events
  mutate(t_hospitalarrival = ifelse(Done==0,NA_integer_,t_hospitalarrival)) %>% # define timestamp of hospital arrival
  mutate(t_arriveatscene = ifelse(Done %in% c(1,2),t_ambulanceseized+T_timetoscene,NA_integer_)) %>% # define timestamp of arrive at scene
  mutate(t_leavescene = ifelse(Done %in% c(1,2),t_ambulanceseized+T_timetoscene+T_timeatscene,NA_integer_)) %>% # define timestamp of leave scene
  mutate(T_handoverbreach30 = ifelse(t_EDhandover-t_hospitalarrival>30,t_hospitalarrival+30,NA_integer_)) %>%  # make handover breach explicit
  mutate(`T_Cat2RT>18`= ifelse(t_arriveatscene-t_Rclockstart>18,t_Rclockstart+18,NA_integer_)) %>% # make response time over 18 minutes explicit (mean Cat2 standard)
  mutate(`T_Cat2RT>40`= ifelse(t_arriveatscene-t_Rclockstart>40,t_Rclockstart+40,NA_integer_)) %>% # make response time over 40 minutes explicit (90th ile Cat2 standard)
  mutate(`Hear&Treat` = ifelse(Done==3,t_JCTend+0.0001,NA_integer_), # Place Care Model as event (interpretability)
         `See&Treat` = ifelse(Done==2,t_JCTend+0.0001,NA_integer_), # Place Care Model as event (interpretability)
         `See&Convey` = ifelse(Done==1,t_leavescene+0.0001,NA_integer_), # Place Care Model as event (interpretability)
         `Direct` = ifelse(Done==0,t_EDhandover-0.0001,NA_integer_)) %>% #  # Place Direct ED as event (interpretability)
  mutate(Convey_n = ifelse(Convey==1,"See&Convey",ifelse(Convey==2,"See&Treat",ifelse(Convey==3,"Hear&Treat",Convey)))) %>% mutate(Convey_n=ifelse(is.na(Convey),"Direct",Convey_n)) %>%
  dplyr::select(name,Cat,Convey,Convey_n,Acuity,Done,t_Rclockstart,t_ambulanceseized,t_arriveatscene,t_leavescene,t_hospitalarrival,T_handoverbreach30,t_EDhandover,t_ambclear,t_EDclockstop,
                `Hear&Treat`,`See&Treat`,`See&Convey`,`Direct`,`T_Cat2RT>40`)# choose variables to keep

flag_week <- "week2" # whether to focus on "week1", "week2" or "weeks" (all time) --> relevant because of the week2 disruption in the model
if (flag_week=="week1"){
  forevent_w <- forevent_w %>% filter(t_Rclockstart < 7*24*60 | Direct < 7*24*60) # filter log horizon 
  tenor=""
} else if (flag_week=="week2"){
  forevent_w <- forevent_w %>% filter(t_Rclockstart >= 7*24*60 | Direct >= 7*24*60) # filter log horizon 
  tenor<-flag_week
} else{
  tenor<-flag_week
}


# Pivot to long format to conform with event log format
forevent <- forevent_w %>% pivot_longer(cols = c(starts_with("t_"),`Hear&Treat`,`See&Treat`,`See&Convey`,`Direct`),names_to="key",values_to="value") %>%
  arrange(value) %>%
  mutate(activity_instance=1:nrow(.),
         resource_id = "ambulance",
         status="complete")
forevent <- forevent %>% filter(!is.na(value)) # remove those NAs (non-used route)
my_origin = "2023-05-01" # fictional start date
forevent$time <- as.POSIXct(forevent$value*60,origin=my_origin) # create absolute timestamps from relative timestamps


### Turn dataframe into eventlog object (three versions) ####
#######################

# Version - overall
event_DES <- eventlog(forevent %>% filter(key %!in% c("T_Cat2RT>18","T_Cat2RT>40")),
                      case_id="name",
                      activity_id="key",
                      activity_instance_id = "activity_instance",
                      timestamp="time",
                      lifecycle_id="status",
                      resource_id="resource_id"
)

# Version - by category

forevent_cat <- forevent %>% # '_Cat' as differentiator of event activites
  mutate(key_cat = ifelse(key %in% c("t_Rclockstart","t_ambulanceseized","t_arriveatscene","t_leavescene",
                                     "Hear&Treat","See&Treat","See&Convey"),
                          paste0(key,"_Cat",Cat),
                          key)) 

event_DES_cat <- eventlog(forevent_cat %>% filter(key %!in% c("T_Cat2RT>18","T_Cat2RT>40")),
                      case_id="name",
                      activity_id="key_cat",
                      activity_instance_id = "activity_instance",
                      timestamp="time",
                      lifecycle_id="status",
                      resource_id="resource_id"
)

# Version - Category 2
event_DES_cat2 <- eventlog(forevent_cat %>% filter(Cat==2) %>% mutate(activity_instance=1:nrow(.)),
                           case_id="name",
                           activity_id="key_cat",
                           activity_instance_id = "activity_instance",
                           timestamp="time",
                           lifecycle_id="status",
                           resource_id="resource_id"
)

# function to support with saving graphics
#######################
saveviewer <- function(aux,mymetric){
  saveWidget(aux,"temp.html",selfcontained=FALSE)
  webshot("temp.html",file=here::here(myfolder, mydate,paste0("map-",tenor,mymetric,"rep",myrep,"id",myid,".png")))
}

saveviewerhtml <- function(aux,mymetric="absolute"){
  saveWidget(aux,file=here::here(myfolder, mydate,paste0("map-",tenor,mymetric,"rep",myrep,"id",myid,"_",Sys.Date(),".html")),selfcontained=FALSE)
}

saveviewerhtml_self <- function(aux,mymetric="absolute"){
  saveWidget(aux,file=here::here(myfolder, mydate,paste0("map-",tenor,mymetric,"rep",myrep,"id",myid,"_",Sys.Date(),"_self.html")),selfcontained=TRUE)
}


### Analyse event log (three versions) #####
#######################

# Version - overall
event_DES_now <- event_DES
event_DES_now %>% summary() # event log summary statistics
event_DES_now %>% process_map() # event log process map
mapping(event_DES_now)
n_activities(event_DES_now) # nr of activities
activity_labels(event_DES_now)
activities(event_DES_now)# absolute and relative frequency per activity

# Version - by Category
event_DES_now <- event_DES_cat
event_DES_now %>% summary() # event log summary statistics
event_DES_now %>% process_map() # event log process map
mapping(event_DES_now)
n_activities(event_DES_now) # nr of activities
activity_labels(event_DES_now)
activities(event_DES_now)# absolute and relative frequency per activity

# Version - Category 2
event_DES_now <- event_DES_cat2
event_DES_now %>% summary() # event log summary statistics
event_DES_now %>% process_map() # event log process map
mapping(event_DES_now)
n_activities(event_DES_now) # nr of activities
activity_labels(event_DES_now)
activities(event_DES_now)# absolute and relative frequency per activity

#### Process maps ####
#######################
# Process maps illustrating either mean, median, relative or relative_case metrics . plus Animated pathway object.

#### Process maps - Version - overall ####

det=5
aa <- event_DES # event log object
prefix = "all_"  # prefix for files saved

mymetric = "median"
aux <- aa %>% process_map(performance(median, "mins")) ; aux
aa_median <- aux
#saveviewer(aux,mymetric)
saveviewerhtml(aux,paste0(prefix,mymetric))

mymetric = "mean"
aux <- aa %>% process_map(performance(mean, "mins")) ; aux
aa_median <- aux
#saveviewer(aux,mymetric)
saveviewerhtml(aux,paste0(prefix,mymetric))

mymetric="absolute"
aux <- aa %>% process_map();aux
saveviewerhtml(aux,paste0(prefix,mymetric))

mymetric="relative"
aux<- aa %>% process_map(type = frequency(mymetric));aux
saveviewerhtml(aux,paste0(prefix,mymetric))

mymetric="relative_case"
aux <- aa %>% process_map(type = frequency(mymetric));aux
saveviewerhtml(aux,paste0(prefix,mymetric))


### Process maps - Animated
ap_aa <- animate_process(aa, mode = "absolute",epsilon_time=0.1)
ap_aa
ap_aa_2c <- animate_process(aa,
                            mode = "absolute",
                            legend="color",
                            #duration=15,
                            epsilon_time=0.1,
                            #jitter=10,
                            mapping = token_aes(color = token_scale("Convey_n", 
                                                                    scale = "ordinal", 
                                                                    range = RColorBrewer::brewer.pal(4, "Set1"))))
ap_aa_2c
saveviewerhtml(ap_aa_2c,paste0("anim_",prefix,"absolute_c"))
saveviewerhtml_self(ap_aa_2c,paste0("anim_",prefix,"absolute_c"))


### Process maps - Version - by category ####

aa <- event_DES_cat #%>%
prefix = "cat_" # prefix for files saved

mymetric = "median"
aux <- aa %>% process_map(performance(median, "mins")) ; aux
aa_median <- aux
#saveviewer(aux,mymetric)
saveviewerhtml(aux,paste0(prefix,mymetric))

mymetric = "mean"
aux <- aa %>% process_map(performance(mean, "mins")) ; aux
aa_median <- aux
#saveviewer(aux,mymetric)
saveviewerhtml(aux,paste0(prefix,mymetric))
saveviewerhtml_self(aux,paste0(prefix,mymetric))

mymetric="absolute"
aux <- aa %>% process_map();aux
saveviewerhtml(aux,paste0(prefix,mymetric))

mymetric="relative"
aux<- aa %>% process_map(type = frequency(mymetric));aux
saveviewerhtml(aux,paste0(prefix,mymetric))

mymetric="relative_case"
aux <- aa %>% process_map(type = frequency(mymetric));aux
saveviewerhtml(aux,paste0(prefix,mymetric))


### Process maps - Animated
ap_aa <- animate_process(aa, mode = "absolute",epsilon_time=0.1)
ap_aa
ap_aa_2c <- animate_process(aa,
                            mode = "absolute",
                            legend="color",
                            #duration=15,
                            epsilon_time=0.1,
                            #jitter=10,
                            mapping = token_aes(color = token_scale("Convey_n", 
                                                                    scale = "ordinal", 
                                                                    range = RColorBrewer::brewer.pal(4, "Set1"))))
ap_aa_2c
saveviewerhtml(ap_aa_2c,paste0("anim_",prefix,"absolute_c"))
saveviewerhtml_self(ap_aa_2c,paste0("anim_",prefix,"absolute_c"))


### Process maps - Version - category 2 only ####

aa <- event_DES_cat2 # event log object
prefix = "cat2_" # prefifx for files saved
mymetric = "median"

aux <- aa %>% process_map(performance(median, "mins")) ; aux
aa_median <- aux
#saveviewer(aux,mymetric)
saveviewerhtml(aux,paste0(prefix,mymetric))

mymetric = "mean"
aux <- aa %>% process_map(performance(mean, "mins")) ; aux
aa_median <- aux
#saveviewer(aux,mymetric)
saveviewerhtml(aux,paste0(prefix,mymetric))

mymetric="absolute"
aux <- aa %>% process_map();aux
saveviewerhtml(aux,paste0(prefix,mymetric))

mymetric="relative"
aux<- aa %>% process_map(type = frequency(mymetric));aux
saveviewerhtml(aux,paste0(prefix,mymetric))

mymetric="relative_case"
aux <- aa %>% process_map(type = frequency(mymetric));aux
saveviewerhtml(aux,paste0(prefix,mymetric))


### Process maps - Animated
ap_aa <- animate_process(aa, mode = "absolute",epsilon_time=0.1)
ap_aa
ap_aa_2c <- animate_process(aa,
                            mode = "absolute",
                            legend="color",
                            #duration=15,
                            epsilon_time=0.1,
                            #jitter=10,
                            mapping = token_aes(color = token_scale("Convey_n", 
                                                                    scale = "ordinal", 
                                                                    range = RColorBrewer::brewer.pal(4, "Set1"))))
ap_aa_2c
saveviewerhtml(ap_aa_2c,paste0("anim_",prefix,"absolute_c"))
saveviewerhtml_self(ap_aa_2c,paste0("anim_",prefix,"absolute_c"))

