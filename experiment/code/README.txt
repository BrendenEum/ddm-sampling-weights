# Gorilla and Stimuli Creation Scripts README


This repository contains four scripts and a csv file: a JavaScript script for running the experiment, three R scripts for creating the stimuli for the practice and regular trials, and a final csv file to be used in Gorilla.


## Gorilla Script (JavaScript)


The `GorillaScript.js` file contains a JavaScript script that is designed to work within the Gorilla Experiment Builder environment. It enables you to display a count-up effect on a specified zone of the screen for a defined period. The script also handles bonus calculations and response recording for the experimental trials.


### Setup and Configuration


Before using the `GorillaScript.js`, ensure you configure the following variables according to your experiment requirements:


- `_countUpDisplays`: An array of display names where the count-up functionality is required.
- `_countUpScreenIndex`: The screen index where the count-up functionality is desired.
- `_countUpZoneName`: The name of the zone where you want the count to be displayed.
- `_countMax`: The maximum length of the count-up in milliseconds.
- `_countInterval`: The interval in milliseconds between executions of the callback function.
- Other variables: Adjust these variables based on your specific experimental settings.


### Usage


1. Add the `GorillaScript.js` to your Gorilla Experiment Builder project.
2. Configure the required variables as mentioned above.
3. Attach the script to the relevant screens and displays where you want the count-up functionality.


## Stimuli Scripts (R)


The `dfPractice.R` file contains an R script for generating the stimuli to be used in the practice trials.


The `df.R` file contains an R script for generating the stimuli to be used in the experimental tasks. 


The `dfFULL.R` file contains an R script for compiling the stimuli and trials created in `df.R` and `dfPractice.R` into a format usable in Gorilla spreasheets. 


### Setup and Configuration


`dfFULL.R` requires the tibble package to be installed.


### Usage


The `dfPractice.R` and `df.R` files should be run first, as `dfFULL.R` requires `dfPractice` and `df` to be in the workspace.


## dfFULL.csv


### File Structure


The `dfFULL.csv` file has the following columns:


- **randomise_blocks**: Number assigned to the block for randomization.
- **randomise_trials**: Number assigned to the trial for randomization within blocks.
- **display**: Indicates the display participants were viewing at that time.
- **t**: Trial number (with "p" added for practice trials) assigned before randomization.
- **s**: Identifies the selected slot machine for the trial. Slot machines were randomly selected ahead of time when creating trials.
        “s” column values corresponding slot machine mean:
* 1 → -2
* 2 → -1
* 3 → 0
* 4 → 1
* 5 → 2
        All slot machines have a standard deviation of 2
- **e**: A vector of raw values sampled from the slot machine. Based on the slot machine chosen for the trial, 100 values were randomly sampled from the normal distribution of that slot machine.
- **size**: Corresponding dot size for each value in the "e" column vector. The sizes range from 70 to 400 in increments of 30 to assign a font size for the dot participants saw.
- **color**: Corresponding hex code color for each value in the "e" column vector. The hex code value is “00FF00” (green) if the “e” column value is positive and “FF0000” (red) if it is negative.