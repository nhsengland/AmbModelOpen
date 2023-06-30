## Date: 17/05/2023
## Overview: Discrete event simulation model for ambulance setting
## Author: Martina Fonseca, Jonathan Pearson, Digital Analytics and Research Team (DART)
## Stage: beta
## Current script: Inputs (Data)
## Dependencies: config.R
## Called by: main.R
##
############################################################################# ##

############################################################################# ##
######### Demand                                                      ####### ##
############################################################################# ##

#df_demand_sch <- read.xlsx(paste0(here(),"/parameters/v_demand_schedule.xlsx"),sheet="Sheet1") # if so, peak normalised demand schedule 
#df_demand_sch <- df_demand_sch %>% mutate(Demand = Demand_norm * ambu_hour_peak) # round to unity not needed since we're using it as a hourly poisson rate
df_demand_sch <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"v_DnC_schedule.xlsx"),sheet="Demand-Enforced")
meta_dnc <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"v_DnC_schedule.xlsx"),sheet="Controls")
flag_demand_schedule_variantcat <- meta_dnc[ifelse(is.na(meta_dnc$CONTROLS),"",meta_dnc$CONTROLS)=="Should category distribution vary over time?","X2"]   # whether demand by category is time-variant. If so, taken from schedule file. If not, taken from cat2conv file
flag_demand_schedule_variantcat <- ifelse(flag_demand_schedule_variantcat=="Yes",TRUE,FALSE)

# Define relative distribution of demand by category . Will be superseded if schedule file has 'time variant' as on.
#v_demand_cat <- read.xlsx(paste0(here(),"/parameters/v_demand_cat.xlsx"))
v_demand_cat <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"m_demand_cat2conv.xlsx"),sheet="v_demand_cat")

# Define relative distribution of conveyance by category
m_demand_cat2conv <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"m_demand_cat2conv.xlsx"),sheet="m_demand_cat2conv")

# Define relation between category (or direct) and ED acuity
m_acuity <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"m_demand_cat2conv.xlsx"),sheet="v_direct_acuity")
n_acuity <- nrow(m_acuity)

# Define direct - how much these are as an uplift of conveyance
if(!flag_demand_schedule){
  v_direct_ratio <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"m_demand_cat2conv.xlsx"),sheet="v_direct_ratio")
  direct_day_proxy <- v_direct_ratio$EDattendance_Rel_to_AmbConveyance[1] * ambu_day * v_demand_conv["SeeConvey",1]
}

v_conv=colnames(m_demand_cat2conv[,2:4])
vi_conv = c(1:length(v_conv))
names(vi_conv) <- v_conv
rownames(m_demand_cat2conv)<- m_demand_cat2conv[,1]
m_demand_cat2conv<- m_demand_cat2conv[,-1]
m_demand_cat2conv_ori <- m_demand_cat2conv # keep original as other will be altered during sim

# Derive relative distribution of demand by conveyance (derived, matrix multiplication)
v_demand_conv <- t(m_demand_cat2conv) %*% v_demand_cat$Rel

# Define portion of conveyance going to ED (of all conveyances)
v_conveyED <- tryCatch(
  expr={read.xlsx(paste0(here(),"/parameters/",scenario_folder,"m_demand_cat2conv.xlsx"),sheet="v_conveydestination")},
  error=function(e){data.frame(Cat=c(1,2,3,4),`perc_toED`=0.9124)}
)


# Define length of stay by category
v_LoS_ori <- tryCatch(
  expr={read.xlsx(paste0(here(),"/parameters/",scenario_folder,"m_demand_cat2conv.xlsx"),sheet="v_LoS")},
  error=function(e){data.frame(Cat=c(1,2,3,4,"D"),`LoS`=5.96)}
)
 

# Define resources arriving per F2F incident
v_resarriveperinc <- data.frame(Cat=c(1,2,3,4),`resallocperinc`=c(2,1.43,2,2),`resarriveperinc`=c(1.41,1.05,1.06,1.09))
#v_resarriveperinc <- data.frame(Cat=c(1,2,3,4),`resallocperinc`=c(2,2,2,2),`resarriveperinc`=c(1.41,1.05,1.06,1.09)) # cat2 w/ 2 res alloc too
#v_resarriveperinc <- data.frame(Cat=c(1,2,3,4),`resallocperinc`=c(1,1,1,1),`resarriveperinc`=c(1,1,1,1))
v_resarriveperinc <- v_resarriveperinc %>% mutate(odds2resalloc=pmax(resallocperinc-1,0),
                                                  odds2resarrive = pmax(resarriveperinc-1,0),
                                                  odds2resarrive_given2resalloc=ifelse(odds2resalloc==0,0,odds2resarrive/odds2resalloc))


# Globals
n_cats = v_demand_cat %>% nrow()
n_conv = length(vi_conv)

############################################################################# ##
######### Job Cycle Time                                              ####### ##
############################################################################# ##

## Define the distributions for job cycle time ---------------------------------
## Type of sampling (Quantile-based or Stylistic parametrisation-based.)
JCT_type <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"JCT_v_type.xlsx")) %>% as.vector()

## JCT as quantile - upload ----------------------------------------------------
# Function for dataframe to matrix conversion
JCT_qfile_2_matrix <- function(teq_jct_cat,n_cats,n_conv){
  
  n_q <- teq_jct_cat$q %>% n_distinct
  teq_jct_cat_m <- teq_jct_cat %>% pivot_longer(cols=c("C1","C2","C3","C4"),names_to="cat",values_to="value")
  teq_jct_cat_m1a <- array(data=teq_jct_cat_m$value,dim=c(n_cats,n_q,n_conv))
  return(teq_jct_cat_m1a)
}

# Travel to scene - quant
teq_tts_cat <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"JCT_m_q.xlsx"),sheet="traveltoscene")
teq_tts_cat_m1a <- JCT_qfile_2_matrix(teq_tts_cat,n_cats,n_conv)

# Matrices for each of the JCT components (quantile)
teq_tts_cat <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"JCT_m_q.xlsx"),sheet="traveltoscene")
teq_tts_cat_m1a <- JCT_qfile_2_matrix(teq_tts_cat,n_cats,n_conv)

teq_tas_cat <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"JCT_m_q.xlsx"),sheet="timeatscene")
teq_tas_cat_m1a <- JCT_qfile_2_matrix(teq_tas_cat,n_cats,n_conv)

teq_ttsi_cat <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"JCT_m_q.xlsx"),sheet="traveltosite")
teq_ttsi_cat_m1a <- JCT_qfile_2_matrix(teq_ttsi_cat,n_cats,n_conv)

teq_uph_cat <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"JCT_m_q.xlsx"),sheet="unavoidableprehandover")
teq_uph_cat_m1a <- JCT_qfile_2_matrix(teq_uph_cat,n_cats,n_conv)
if(tamper_HO_flag){
  teq_uph_cat_m1a <- teq_uph_cat_m1a * tamper_HO_f
}

teq_ttc_cat <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"JCT_m_q.xlsx"),sheet="timetoclear")
teq_ttc_cat_m1a <- JCT_qfile_2_matrix(teq_ttc_cat,n_cats,n_conv)

## JCT as stylistic parametrisation - upload -----------------------------------
# Function for dataframe to matrix conversion
JCT_file_2_matrix <- function(teparam_jct_cat,n_cats,n_conv){
  
  n_param <- teparam_jct_cat$param %>% n_distinct
  teparam_jct_cat_m <- teparam_jct_cat %>% pivot_longer(cols=c("C1","C2","C3","C4"),names_to="cat",values_to="value")
  teparam_jct_cat_m1a <- array(data=teparam_jct_cat_m$value,dim=c(n_cats,n_param,n_conv))
  
  return(teparam_jct_cat_m1a)
}

# Matrices for each of the JCT components
teparam_tts_cat <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"JCT_m_style.xlsx"),sheet="traveltoscene")
tep_tts_cat_m1a <- JCT_file_2_matrix(teparam_tts_cat,n_cats,n_conv)

teparam_tas_cat <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"JCT_m_style.xlsx"),sheet="timeatscene")
tep_tas_cat_m1a <- JCT_file_2_matrix(teparam_tas_cat,n_cats,n_conv)

teparam_ttsi_cat <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"JCT_m_style.xlsx"),sheet="traveltosite")
tep_ttsi_cat_m1a <- JCT_file_2_matrix(teparam_ttsi_cat,n_cats,n_conv)

teparam_uph_cat <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"JCT_m_style.xlsx"),sheet="unavoidableprehandover")
tep_uph_cat_m1a <- JCT_file_2_matrix(teparam_uph_cat,n_cats,n_conv)

teparam_ttc_cat <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"JCT_m_style.xlsx"),sheet="timetoclear")
tep_ttc_cat_m1a <- JCT_file_2_matrix(teparam_ttc_cat,n_cats,n_conv)

############################################################################# ##
######### Supply                                                      ####### ##
############################################################################# ##

## DSA Resource Schedule Profile From file
df_DSA_sch <- read.xlsx(paste0(here(),"/parameters/",scenario_folder,"v_DnC_schedule.xlsx"),sheet="Supply-Enforced")

df_validate <- read.xlsx(paste0(here(),"/parameters/df_validation_HO.xlsx"),detectDates=TRUE)
df_validate <- df_validate %>% filter(Date >= 1, Date <=15)
df_validate$step <- (1:nrow(df_validate)-1)*g.tday
df_validate <- df_validate %>% rename(perc_delay30p=`HO.30+.%`,perc_delay60p=`HO.60+%`)
df_validate <- df_validate %>% dplyr::select(-c(Cat2.RT,Date))
df_validate <- df_validate %>% pivot_longer(cols=-c(step),names_to="quant_n",values_to="quant")

############################################################################# ##
######### Escalation                                                  ####### ##
############################################################################# ##

# Use a function (empirical, judgemental or other) that dictates relation between C2 mean, 30+ handover delays and the conveyance of Cat3
x <- matrix(c(1000,40,30,
              200,20,10), nrow = 3, dimnames = list(c("Kz_calls","Kz_RT_C2mean","Kz_HO30p"), c("mean","sd"))) # provide standardisation values of independent variables (mean, sd)
dynamic_C3conv_standard = x
dynamic_C3conv_coef <- c("c0"=0.444845348,
                         "c1"=0,
                         "c2"=-0.045895590,
                         "c3"=-0.005338881,
                         "c12"=0,
                         "c13"=0,
                         "c23"=0.012727331,
                         "c123"=0)    # c(c0,c1,c2,c3,c12,c13,c23,c123) . 0 - intercept ; 1 - Kz_calls ; 2 - Kz_RT_C2_mean , 3 - Kz_HO30p
func_dynamic_C3conv <- function(Kz_calls,Kz_RT_C2mean,Kz_HO30p,coef=dynamic_C3conv_coef,Kmin=0.306,Kmax=0.576){
  
  pconvey_C3_scene <- coef["c0"]+ coef["c1"]*Kz_calls + coef["c2"]*Kz_RT_C2mean + coef["c3"] * Kz_HO30p +
    coef["c12"] * Kz_calls*Kz_RT_C2mean + coef["c13"] * Kz_calls*Kz_RT_C2mean + coef["c23"] * Kz_RT_C2mean * Kz_HO30p +
    coef["c123"] * Kz_calls* Kz_RT_C2mean * Kz_HO30p
  
  pconvey_C3_scene <- max(min(Kmax,pconvey_C3_scene),Kmin)
  
  pconvey_C3_scene <- ifelse(is.na(pconvey_C3_scene),Kmin,pconvey_C3_scene) #
  return(pconvey_C3_scene)
}

