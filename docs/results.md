> **Warning**
> Internal documentation for the results of Phase 1 of the work (March-April 2023) and Phase 2 of the work (April-May 2023) not made public.
> Outputs from the Toy / Fake scenarios shown below to exemplify outputs.

Graphical visualisations and summary metrics (those below and beyond) can be obtained by pre-processing either the Log of Arrivals (log_arrivals.xlsx) or the Log of Attributes (log_attributes_w.xlsx). These will be saved if `flag_savedata_fulllogs <- TRUE`. 

## Example outcomes from Fake_Data_2

Example outcomes from `parameters/Fake_Data_2/` scenario , with `n_AEbays <- 1500`, `T_AE <- 6.5`, `flag_LoS_file <- FALSE`, `dn_AEsupplyshock <- 0`

### Demand

**Figure** Demand per category and conveyance (colour-coded ; 1 - see and convey; 2 - see and treat; 3 - hear and treat; 99 - direct ED)
![Hourly demand for Fake_Data_2.](../assets/Fake_Scenario_2/plot_arri_cat_CM.png)

### Demand and supply

**Figure** Incident demand per category (colour-coded ; categories 1-4). 3 replications shown. Direct ED demand excluded. Black trace - input demand. Red-trace - input DSV supply
![Hourly demand and DSV supply for Fake_Data_2.](../assets/Fake_Scenario_2/plot_arri_cat_DnC.png)

### Resource utilisation KPIs

#### Instantaneous utilisation, capacity and queue traces

**Figure** Instantaneous resource usage for respectively ambulance and A&E bay. Dashed blue - server capacity ; Solid blue traces - server use ; Solid red traces - queues . Multiple traces due to n=10 rpelications.
![Instananeous utilisation for Fake_Data_2.](../assets/Fake_Scenario_2/plot_RU_instant_.PNG)

#### Utilisation KPIs - batch, overall simulation time

**Figure** Utilisation and queue for A&E bay and ambulance. Average and standard deviation.
![Overall utilisation for Fake_Data_2.](../assets/Fake_Scenario_2/plot_RU_KPI.png)

### Response time KPIs

**Figure** Mean response time KPIs per category and per simulation time-steps. Boxplots showing inter-replication variation. Dashed line is dummy, can be used to benchmark.
![Response time KPIs for Fake_Data_2.](../assets/Fake_Scenario_2/plot_Kp_RTmean_bp_ref_freey0_d14.png)

**Table** Response time KPIs (mean, median, 90th) averaged across simulation time and replications (mean, standard deviation)

{{ read_excel('./assets/Fake_Scenario_2/KPIbatch_overall_RTcat.xlsx', engine='openpyxl') }}

### Handover KPIs

**Figure** Handover KPIs per simulation time-steps. Boxplots showing inter-replication variation. Dashed line is dummy, can be used to benchmark.
![Handover KPIs for Fake_Data_2.](../assets/Fake_Scenario_2/plot_Kp_HO_bp_y0.PNG)

**Table** Handover KPIs averaged across simulation time and replications (mean, standard deviation)

{{ read_excel('./assets/Fake_Scenario_2/KPI_overall_HO.xlsx', engine='openpyxl') }}

### Select Job Cycle Time KPIs

**Table** KPIs 'Time to allocate' , 'Time for pre-handover', 'Total job cycle time', 'Response time', per conveyance. Mean and median.
{{ read_excel('./assets/Fake_Scenario_2/KPI_overall_val_conv.xlsx', engine='openpyxl') }}

### Call queue KPIs

**Figure** Average call queue KPI per simulation time-steps (6 hour window). Boxplots showing inter-replication variation.
![Call queue KPIs for Fake_Data_2.](../assets/Fake_Scenario_2/p_KPI_cq_1.png)

### (Hospital) site queue KPIs

**Figure** Averege site queue KPI per simulation time-steps (24 hour window). Boxplots showing inter-replication variation.
![Call queue KPIs for Fake_Data_2.](../assets/Fake_Scenario_2/p_KPI_sq_1_day.png)






