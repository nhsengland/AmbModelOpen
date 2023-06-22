## Date: 17/05/2023
## Overview: Discrete event simulation model for ambulance setting
## Author: Martina Fonseca, Jonathan Pearson, Digital Analytics and Research Team (DART)
## Stage: beta
## Current script: Save.R - various saving options for dataframes and plots
## Dependencies: config.R, inputs.R, main.R, post-processing.R
## Called by: main.R
##
############################################################################# ##

### Overall KPIs ####

if(flag_savedata_overallKPIs){
  
  # Overall JCT
  write.xlsx(t_att_1,paste0(output_folder,"/","KPI_overall_JCT_conv.xlsx"))
  
  write.xlsx(t_att_2,paste0(output_folder,"/","KPI_overall_JCT.xlsx"))
  
  write.xlsx(t_att_2_DCA,paste0(output_folder,"/","KPI_overall_DCAtime.xlsx"))
  
  # Time to allocate ; Handover time; Response time - means
  write.xlsx(t_att_3,paste0(output_folder,"/","KPI_overall_val_conv.xlsx"))
  
  write.xlsx(t_att_4,paste0(output_folder,"/","KPI_overall_val_catconv.xlsx"))
  
  write.xlsx(t_att_5,paste0(output_folder,"/","KPI_overall_val_cat.xlsx"))
  
  write.xlsx(t_att_5_rep,paste0(output_folder,"/","KPIrep_overall_val_cat.xlsx"))
  
  write.xlsx(t_att_6_batch,paste0(output_folder,"/","KPIbatch_overall_val.xlsx"))
  
  # Handover
  write.xlsx(log_Handover_overall,paste0(output_folder,"/","KPIrep_overall_HO.xlsx"))
  write.xlsx(log_Handover_overall_batch,paste0(output_folder,"/","KPI_overall_HO.xlsx"))
  write.xlsx(KPI_HO_deciles,paste0(output_folder,"/","KPI_overall_HO_deciles.xlsx"))
  
  # Resource utilisation
  write.xlsx(resources_runsum,paste0(output_folder,"/","KPIbatch_overall_RU.xlsx"))
  write.xlsx(resources_rep,paste0(output_folder,"/","KPIrep_overall_RU.xlsx"))
  
  # Response times - 50, 75, 90th per rep
  write.xlsx(log_attributes_w_runsum,paste0(output_folder,"/","KPIrep_overall_RT.xlsx"))
  write.xlsx(log_RT_sim,paste0(output_folder,"/","KPIrep_overall_RTcat.xlsx"))
  
  # Response times - 50, 75, 90th batch
  write.xlsx(log_attributes_w_runsum_batch,paste0(output_folder,"/","KPIbatch_overall_RT.xlsx"))
  write.xlsx(log_RT_sim_batch,paste0(output_folder,"/","KPIbatch_overall_RTcat.xlsx"))
  
  # LoS
  write.xlsx(t_att_LoS_out,paste0(output_folder,"/","KPIflat_LoS.xlsx"))
  write.xlsx(t_att_LoS_out_rep,paste0(output_folder,"/","KPIrep_LoS.xlsx"))
}

### Stepwise KPIs ####

if(flag_savedata_stepwiseKPIs){
  
  # Response time KPIs "AQI-like"
  write.xlsx(log_RT,paste0(output_folder,"/","KPI_step_RT.xlsx"))
  
  # Handover KPIs - "Ambulance sitrep-like"
  write.xlsx(log_Handover,paste0(output_folder,"/","KPI_step_HO.xlsx"))
  
  # Handover KPIs - "Ambulance sitrep-like"
  write.xlsx(log_CallQueue,paste0(output_folder,"/","KPI_step_CallStack.xlsx"))
  
  # Handover KPIs - "Ambulance sitrep-like"
  write.xlsx(log_SiteQueue,paste0(output_folder,"/","KPI_step_SiteQueue.xlsx"))
  
}






### Full logs ####
if(flag_savedata_fulllogs){
  
  write.xlsx(log_arrivals,paste0(output_folder,"/","log_arrivals.xlsx"))
  write.xlsx(log_resources,paste0(output_folder,"/","log_resources.xlsx"))
  write.xlsx(log_attributes_w,paste0(output_folder,"/","log_attributes_w.xlsx"))
}

### Plots ####

# IMPLEMENT ME

if(flag_saveplots){
 
  ggsave(paste0(output_folder,"/","plot_RU_instant_.png"),
         p_ru2,
         units="cm",
         width=20,
         height=15)
   
  
  ggsave(paste0(output_folder,"/","plot_Kp_RT90_bp_d14_ylim.png"),
         p_Kp_RT90_bp + ylim(0,1000),
         units="cm",
         width=20,
         height=15)

  
  ggsave(paste0(output_folder,"/","plot_arri_cat_CM.png"),
         p_arri_cat_CMfreey,
         units="cm",
         width=20,
         height=15)
  
  ggsave(paste0(output_folder,"/","plot_arri_cat_DnC.png"),
         p_arri_cat_DnC,
         units="cm",
         width=20,
         height=15)
  
  
  
}

# ggsave(paste0(output_folder,"/","plot_RU_instant_.png"),
#        p_ru2,
#        units="cm",
#        width=20,
#        height=15)

### Inputs and parameters ####

# IMPLEMENT ME

