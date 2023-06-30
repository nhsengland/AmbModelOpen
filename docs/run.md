> **Warning**
> IN CONSTRUCTION.

The model is run as a discrete event simulation using the [RSimmer package](https://r-simmer.org/).  This type of modelling requires a "trajectory" to be fed with a realistic demand which then moves through the trajectory based on evidence based assumptions and resource supply usage.  The time it takes for the demand to make its way through the system and the utilisation of resources required for this can be monitored.  Each of these components will be explain in more detail below. 

## Trajectory

For this problem we can state that there is a fairly consistent patient pathway or "trajectory" as patients enter the system through a 999 triage process, are allocated ambulance resources which have fairly consistent job cycle times and then are either treated at scene, conveyed to and ED or conveyed to a non-ED setting.  At the ED setting there may be the formation of a queue whilst handing over the patients.  This creates a relatively simple trajectory but one where the time delays and resource prioritisation are heavily impacted by other parts of the system.

<p align = "center">
    <img src="../assets/AmbSimTraj.png" alt="Patient Pathway covering ambulance and ED resource usage" width="600"/>
</p>

## Demand

The demand in this model comes from two main generators:

- Walk-ins (i.e. direct ED attendances)
- Ambulance incidents

In this model, walk-in demand can vary over time (hourly). It can be attributed different levels of ED acuity, which will impact the way requests for ED resource (among themselves and in relation to ambulance demand) are prioritised.

Ambulance incident demand can vary over time (hourly). The distribution of this demand by category can also vary hourly. Each ambulance incident will be attributed a certain care model. If this involves conveyance, the incident will be attributed a certain probability that conveyance is to ED. If conveyance is to ED, it will be attributed a given ED acuity. 

## Assumptions


## Resource Usage

