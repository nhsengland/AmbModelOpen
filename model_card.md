# Model Card: {Amb-Model-Open}


## Model Details

The implementation of the Amb-Model-Open within this repository is the public facing version realting to a piece of work conducted in NHS England from Feb-May 2023. This model card describes the updated version of the model, released 20-June-2023.  The model itself is a discrete event simulation using a trajectory to define possible routes.

## Model Use

### Intended Use

This model is intended to be used to generate evidence for understanding the dynamics in the ambulance job cycle.   The intended use requires the model inputs and parameters to be calibrated for a specific ambulance trust and the results to be validated alongside expert opinion.

### Out-of-Scope Use Cases

This model is a simple representation of the ambulance / ED interaction.   Currently no escalation or human behaviour characteristics are included in the model.  Without these formal and informal mitigation dynamics, the model is overly sensitive and shows an explosive nature when resources become depleted.   Therefore, the results from this model should be used as an indication to inform the narrative and not used for performance monitoring or to be used in isolation for planning purposes.
