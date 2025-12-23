Access to Justice Lab Expungement Replication Readme

This file contains instructions for replicating, in full or in part, the results for the Final Stage Reentry Project Report. Internally, this was referred to as the Expungement project, so that terminology is used throughout the technical documents. These instructions walk through the general project work flow and explain what each relevant file is doing, as well as provides a few specific instructions for altering some of the parameters or obtaining additional output.

In general, the project is structured around three stages:
	1) Analysis Datasets/Model Datasets
	2) Model Output
	3) Graphics Output
	
The workflow starts with the base analysis datasets provided in the top-level folder:
	- ExpungementSurveyData.csv
		* This file contains the panel data structured survey responses obtained during the post-enrollment period alongside necessary study variables like internal IDs and treatment status
		* It is used primarily to estimate the effect of expungement on survey based outcomes
	- ExpungementAdminData.csv
		* This file contains the panel data structured administrative data obtained during both pre and post enrollment from the different administrative data sources alongside necessary study variables like internal IDs and treatment status
		* It is used primarily to estimate the effect of expungement on administrative based outcomes
	- ExpungementIntakeData.csv
		* This file contains cross-sectional administrative data collected during the intake interview with participants alongside necessary study variables
		* It is used primarily to determine covariate balance at the time of enrollment across treatment groups
	- ExpungementInstrumentData.csv
		* This file contains cross-sectional administrative data related to the expungement success and length of time between enrollment and expungement
		* It is used primarily to determine the strength of legal representation vs. self-help as an instrument for expungement
		
From these base analysis datasets, 10 multiple imputation datasets and additional outcome specific datasets, were generated using the MI and Model Dataset Generation Script. The specific models expect datasets restrained to the variables tested directly in the model, so each outcome has its own unquie subset of the main analysis datasets that a fed into the relevant statistical model. For multiply imputed survey outcomes, these include 10 different versions of each subset of variables; one for each of the default multiple imputations.

*** Note: The number of multiple imputated datasets can be changed by changing the m parameter declared at the beginning of the MI and Model Dataset Generation Script. However, this number much match the first line of each model estimate script for multiply imputed outcomes (see next workflow step) as well as the m parameter at the beginning of the ExpugementGraphiicsOutput markdown file. ***

The default seed for the multiple imputation was 12345, and can be edited within the MI script. The script outputs the generated data subsets directly into the Stata Files folder. The original subdatasets used in the analysis are already provided in this folder.

The primary estimation portion of the workflow relies on Stata do-files. So access to Stata is required. You are welcome to build the same models in R, but there have been observed minor differences in estimation values when moving between these programs (although not enough to change substantive conclusions). Prior to running any do-files in Stata, you must manually change the working directory in Stata to the Stata Files location, as this cannot be done within the do-file (which seems super inefficient of Stata, I know). 

Each outcome-model has a specific do-file associated with it that imports the relevant data subset generated in the previous process, estimates the specified model in the do file, and produces overall LATE/ATE values, period specific LATE/ATE values, and predicted probabilities across periods and expungement status. These output values are saved in specific CSV files within the Stata Files folder. Outcomes that are multiply imputed generate as many versions of thee output files as the initial multiple imputation count specifies at the top of the relevant do-file (default: 10). The original output files generated from this process that were used in the report are already present in the Stata Files folder.

After Stata estimates and outputs the relevant data, the ExpungementGraphicsOutput.Rmd file can be used to produce a single R markdown file of graphics relating to: covariate balance, instrument strength, administrative data based outcomes, and survey data based outcomes. Overall LATE/ATE estimates are included in the graphic output for administrative outcome; however, to obtain the overall LATE/ATE estimates and confidence intervals for survey based outcomes, the relevant code chunks for the outcome must be run up to the line prior to filtering the overall LATE/ATE estimate out from the period-specific LATE/ATE estimates. These prior lines run the relevant code for combining the various multiply imputed estimations using Rubin's Rules (directly programmed in the script). The original output file used for the report is included in the top-level folder.

These scripts went through a number of different iterations, and any notion of elegance or abstraction was more or less abandoned at the end, but the overall workflow does produce working output.