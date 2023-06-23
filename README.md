# Amb-Model-Open
## NHS England Digital Analytics and Research Team (DART)

### About the Project

[![status: experimental](https://github.com/GIScience/badges/raw/master/status/experimental.svg)](https://github.com/GIScience/badges#experimental)

This repository holds code for AmbModelOpen: A discrete event simulation of ambulance resources.  The methodological approach and project specifics can be seen in the MkDocs documentation.  

### Project Stucture

- The main code is found in the src folder
- More information about the code usage can be found in the [model card](./model_card.md)
- Documentation is created by MkDocs 

### Built With

[![R v3.6.1](https://img.shields.io/badge/r-v3.6.1-blue.svg)](https://cran.r-project.org/bin/windows/base/old/3.6.1/)
- [RSimmer](https://github.com/r-simmer/simmer)

### Getting Started

#### Installation

To get a local copy up and running follow these simple steps.

To clone the repo:

`git clone https://github.com/nhsengland/ambmodelopen`

Launch the `stmnhsx.Rproj` file in a suitable IDE (e.g. RStudio).  

The required packages are stored in `src/packages.R`.

### Usage
RSimmer generates entities to follow set trajectories.  The entities in this case are patients requiring emergency transport to an emergency department whilst the trajectory covers the ambulance allocation, transportation and handover to the emergency department.  Both generator and trajectory are defined in `src/trajectories`.  The trajectory can be viewed using the library simmer.plot and the command `plot(patient)` if the trajectory is run outside of it's funtion. 

The main run of the model is controlled by `main.R` which defines the simulation configuration and any static or scenario input parameters.  The model can be run over a grid of scenarios for `nreps` number of replications. Post processing visualisations and saving of outputs then finishes the run with outputs saved to the `Output` folder (gitignored).  Example outputs can be found in the `example_output` folder.

#### Datasets
The main data sources used in this work are the Computer Aided Dispatch (CAD) System to inform job cycle times of ambulances and a linkage with the Emergency Care Data Set (ECDS) to address handover.  

### Roadmap
See the [Issues](https://github.com/nhsengland/ambmodelopen/issues) for a list of proposed features (and known issues).

### Contributing
Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

_See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidance._

### License
Unless stated otherwise, the codebase is released under [the MIT Licence][mit].
This covers both the codebase and any sample code in the documentation.

_See [LICENSE](./LICENSE) for more information._

The documentation is [© Crown copyright][copyright] and available under the terms
of the [Open Government 3.0][ogl] licence.

[mit]: LICENCE
[copyright]: http://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/
[ogl]: http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/

### Contact
To find out more about the [DART](https://www.nhsx.nhs.uk/key-tools-and-info/nhsx-analytics-unit/) visit our [project website](https://nhsx.github.io/AnalyticsUnit/projects.html) or get in touch at [TDAUgroup@england.nhs.uk](mailto:TDAUgroup@england.nhs.uk).

<!-- ### Acknowledgements -->
