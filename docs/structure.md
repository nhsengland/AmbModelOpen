### Folder structure

- `./src` - folder for source code.
- `./parameters` - folder to house sub-folders. A sub-folder will include a set of Input parameter files for a given scenario that should be parametrised.
- `./docs` - folder with MkDocs documentation
- `./Outputs` - folder for run outputs subfolders
- `./example_outputs` - folder with example outputs


### Source Code structure

Core:

- `main.R` - main script from which libraries are loaded, parameters set, runs made and results processed.
- ----- `trajectory.R` - trajectory definitions. Core element of `simmer` DES model.
- ----- `config.R` - config (user inputs). File where various user inputs are set (apart from those loaded from file, though including flags on whether those should be used or not).
- ----- `inputs.R` - script where inputs (data) are loaded from Input parameter files and pre-processing is done.
- ----- `packages.R` - packages needed for run and results
- ----- `post-processing.R` - post-processing . post-processing of logs (data wrangling, rules) to arrive at relevant metric dataframes and graphs (including demand; supply; utilisation metrics; handover metrics; response time metrics; queue metrics)
- ----- `save.R` - various saving options for model output dataframes and plots

An end-user would only be expected to interact with `config.R` and two lines in `main.R` on `scenario_folder` and `mydate`.

A developer could interact with different code files depending on the use case.
