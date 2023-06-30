
This section explains the meaning of the output files.

## Output - patient pathway (Simmer)



## Output - logs

Full simulation logs are saved if `flag_savedata_fulllogs <- TRUE` in `config.R`.
Beware of use for very large simulations.

| File           |   | Description                          |
|:----------------:|:---:|:------------------------------:|
| log_arrivals |   | A log of arrivals (demand). Both ambulance and direct. Each row is an arrival.  |
| log_resources  |   | An event log of resource use. Both double staffed vehicles and ED. A new row signals a timestamp in which either the queue, occupancy or capacity of a resource changed.  |
| log_attributes_w  |   | A log of arrivals and their various characteristics and notable timestamps. Attributes saved are defined in the trajectory.R specification.  |


### Output - log of arrivals

Variables in `log_arrivals.xlsx`.

| File           |   | Description                          |
|:----------------:|:---:|:------------------------------:|
| name |   | Unique patient identifier.  |
| start_time |   | Start of activity.  |
| end_time |   | End of activity (model exit)  |
| activity_time |   | Difference between start and end time  |
| finished |   | Flag on whether activity had finished by the end of the simulation  |
| replication |   | The model run replication number  |


### Output - log of resources

Variables in `log_resources.xlsx`.

| Variable          |   | Description                          |
|:----------------:|:---:|:------------------------------:|
| resource |   | Resource (server) type.  |
| time |   | Timestamp marking change in utilisation profile from previous row's characteristics  |
| server |   | Number patients in server  |
| queue |   | Number patients in queue for that server  |
| capacity |   | Capacity of that server  |
| queue_size |   | Maximum allowed queue size of that server (#NUM means infinite)  |
| system |   | Number patients in server system (in queue or in server itself)  |
| limit |   |  Maximum allowed system (queue+server) size (#NUM means infinite)  |
| replication|   | The model run replication number  |
| id |   | n/a  |

### Output - log of resources

Variables in `log_attributes_w.xlsx`.

{{ read_excel('ambsim_logattributesw_outputs.xlsx', engine='openpyxl') }}


## Output - KPI files

Overall (simulation time) KPIs are saved if `flag_savedata_overallKPIs <- TRUE` in `config.R`.

Step-wise (by steps of simulation time) KPIs are saved if `flag_savedata_stepwiseKPIs <- TRUE` in `config.R`.

Contrary to the full logs, these files save more post-processed KPIs (though all resulting from those two logs).

**KPIs** include:

- Response times (Cat1, 2, 3, 4) - mean and 90th percentile
- Handover delays 30+ (%)
- Handover delays 60+ (%)
- Total time lost to handover delays (TLAHD)
- Total job cycle time (JCT)
- Double crewed ambulance (DCA) time  - mean, sd
- Time to allocate - mean, sd
- Call queue (queueing for an ambulance)
- Site queue (queueing for ED)
- Resource utilisation (%) - mean, sd

**Replication or batch:** Some files give results "by replication" while others summarise these further "across replications" ("batch"). This is indicated in the table below.

**If batch - replication aggregate or flat:** In some cases, this "batch" KPI is derived by considering all arrivals regardless of replication ("flat"). In others, the batch KPI is found by first calculating the KPI per replication and then finding the mean and standard deviation of this KPI among replications ("aggregate").

**Stepwise:** Some KPIs are calculated for different steps (e.g. days, time windows) of the simulation window while other times they are calculated for the overall simulation time.

**Disaggregations:** Where certain disaggregations were used, this is indicated (e.g. category for response times ; care model for time to allocate; resource type for utilisation; etc)




An overview of the meaning of KPI output files is given below (navigate rightwards in the table to see all columns).

{{ read_excel('ambsim_outputs.xlsx', engine='openpyxl') }}


## Output-  plots


