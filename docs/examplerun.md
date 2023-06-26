
To get an example run going, follow the following steps:

- Use the `config.R`, `main.R` and `inputs.R` as given in the main branch as default (as there have already been set up to align with a given scenario).
- Open `main.R` . Use `mydate` to change the name of the subfolder to which the results should be saved (within "Output"). e.g. to name it "myexamplerun" set `mydate <- "myexamplerun"`.
- The run has been set to use scenario folder `Fake_Scenario` for reading inputs (in `/parameter` subfolder).
- "Select all" in `main.R` and then press `run` or `Ctrl+R`. The run may take some minutes given it is set to run 10 replications, each covering a 15 day simulation time period for a whole trust footprint.
- After the run, some results will be printed to the Console or the Plots viewer. A range of relevant outputs will be saved to the folder selected above, e.g. `./Outputs/myexamplerun/` .
- This should have successfully concluded a run!

Exploring further:

- See [User guide - Parameter input files](userguide.md) to understand the Scenario input files and when / how / if they get used via `Input.R` and in the DES model runs.
- See [Optimised Model - Inputs](inputs.md) for an overview of Input use in the model (from Scenario input files).
- See [Optimised Model - User Settings (Config)](config.md) to understand further user settings in the `config.R` file.

