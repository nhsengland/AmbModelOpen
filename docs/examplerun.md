

### Code Setup

The following steps will likely be necessary ahead of the first run:

- Clone the repository to a folder location of choice;
- Open R Studio;
- Open the R project of AmbModelOpen in the parent folder (double click `ambsim.Rproj`)
    - Check: when running`getwd()` from the R console, the working directory should now be set to the cloned folder location `AmbModelOpen`.
- Open `packages.R` and run this file. This will likely throw errors as some (or all) packages are not installed.
- In `packages.R` set `flag_install_packages <- TRUE` and add the relevant packages to be installed in `c_packagestoinstall` . For example, if `tidyverse` and `simmer` need installing, write `c_packagestoinstall <- c("tidyverse","simmer")`. Run the code.
- Once all relevant packages have been installed explicitly set `flag_install_packages <- FALSE` to make sure the programme does not reinstall each time it is run.

### Starting a run (first run)

To get an example run going, follow the following steps:

- For a first run, use the code files (`./src`) as given in the main branch as default (as there have already been set up to align with a given scenario).
- Open `main.R` . Use `mydate` to change the name of the subfolder to which the results should be saved (within `AmbModel/Output`). e.g. to name it "myexamplerun" set `mydate <- "myexamplerun"`.
- The run has been set to use scenario folder `Fake_Data_2` for reading inputs (in `/parameter` subfolder).
- "Select all" in `main.R` and then press `run` or `Ctrl+R`. The run may take some minutes given it is set to run 10 replications, each covering a 15 day simulation time period for a whole ambulance trust footprint.
- After the run, some results will be printed to the Console or the Plots viewer. A range of relevant outputs will be saved to the folder selected above, e.g. `./Outputs/myexamplerun/` .
- This should have successfully concluded a run!

### Creating my own custom scenario and run

The code was made with the expectation that an end-user would only potentially update:

- `main.R` (lines 22-23)
    - `scenario_folder` to specify the name of the parameter scenario folder to use (an existing subfolder of AmbModelOpen/parameters that the user worked on)
    - `mydate` to specify the name of the folder where results should be saved (will appear in AmbModelOpen/Outputs).
- `config.R` - a range of configurable settings
- a `/parameter` subfolder similar to `/parameter/Fake_Data_2` to change inputs on demand, supply, job cycle time components and pathway probabilities.
    - The user can create a copy of the `Fake_Data_2` folder (e.g. `Fake_Data_3`), update parameters as desired and run the model with `scenario_folder <- "Fake_Data_3`.

#### Understanding the config.R file (reference)

See [Optimised Model - User Settings (Config)](config.md) to understand further user settings in the `config.R` file.

#### Understanding how to update parameter input files (user guide)

See [User guide - Parameter input files](userguide.md) to understand the Scenario input files and when / how / if they get used via `Input.R` and in the DES model runs.

#### An overview of parameter inputs (reference)
See [Optimised Model - Inputs](inputs.md) for an overview of Input use in the model (from Scenario input files).



### Understanding the output files

An overview of output files is given in [Overview of output files](interpretoutput.md).
