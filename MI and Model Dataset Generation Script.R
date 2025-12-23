####################################################################################
### Expungement Multiple Imputation and Model Specific Dataset Generation Script ###
####################################################################################


# This script generates the datasets from the multiple imputation process as well
# as the individual datasets used in each outcome model. The number of datasets 
# generated from this process can be set by editing the m variable. The random seed
# used in the MI process was chosen as 12345, but can be edited as well.

# Set Working Directory- assumes you are using RStudio, if not, set it yourself, I guess
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# Package Specification
library(mice)

# Parameter Specification
m = 10
seed = 12345

# Import Main Datasets
data <- read.csv("./ExpungementSurveyData.csv")
data.admin <- read.csv("./ExpungementAdminData.csv")

# Generate MI Datasets
data.mi <- mice(data, m=m, seed=seed)

mi.data <- complete(data.mi, action='all')

# Output model datasets

######################
### Admin Outcomes ###
######################

# Unemployment
unemployed.data <- data.admin[c('STID', 'Seq', 'Unemployed', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'total_income', 'logIncome', 'income_lag', 'unemploy_lag', 'pstudy_employed', 'local_unemploy', 'Married', 'dependent', 'Year')]
colnames(unemployed.data) <- c('stid', 'seq', 'unemployed', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'total_income', 'income', 'income_lag', 'unemploy_lag', 'ps_employed', 'local_unemploy','married', 'dependent', 'year')

write.csv(unemployed.data, './Stata Files/unemployedDataAdmin.csv', row.names=FALSE, na="")

# Recidivism- Panel data model not estimated; see cross-sectional model instead
rec.data <- data.admin[c('STID', 'Seq', 'Recid', 'add_rec', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'total_income', 'logIncome', 'pstudy_employed', 'Unemployed', 'unemploy_lag', 'local_unemploy', 'Married', 'dependent', 'Year')]
colnames(rec.data) <- c('stid', 'seq', 'recid', 'add_rec', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'total_income', 'income', 'ps_employed', 'unemployed', 'unemploy_lag', 'local_unemploy', 'married', 'dependent', 'year')

# Income Ratio
incomeR.data <- data.admin[c('Part', 'Seq', 'incomeRatio', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'unemploy_lag', 'local_unemploy', 'pstudy_employed', 'Married', 'dependent', 'Year', 'pe_incomeAvg')]
colnames(incomeR.data) <- c('stid', 'seq', 'income_ratio', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'unemploy_lag', 'local_unemploy', 'ps_employed', 'married', 'dependent', 'year', 'pe_income_avg')
incomeR.data <- filter(incomeR.data, !is.na(incomeR.data$income_ratio))

write.csv(incomeR.data, './Stata Files/incomeRDataAdmin.csv', row.names=FALSE, na="")

# Wage Ratio
wageR.data <- data.admin[c('Part', 'Seq', 'wageRatio', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'unemploy_lag', 'local_unemploy', 'pstudy_employed', 'Married', 'dependent', 'Year', 'pe_wageAvg')]
colnames(wageR.data) <- c('stid', 'seq', 'wage_ratio', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'unemploy_lag', 'local_unemploy', 'ps_employed', 'married', 'dependent', 'year', 'pe_wage_avg')
wageR.data <- filter(wageR.data, !is.na(wageR.data$wage_ratio))

write.csv(wageR.data, './Stata Files/wageRDataAdmin.csv', row.names=FALSE, na="")

# Recidivism Cross-Section
rec.dataCS <- rec.data[rec.data$seq >= 0,] %>% 
  group_by(stid) %>%
  summarise(
    recid = max(recid),
    add_rec = max(add_rec),
    treatment = max(treatment),
    expunge = max(expunge),
    white = max(white),
    female = max(female),
    age_enroll = max(age_enroll),
    total_income = mean(total_income),
    income = mean(income),
    ps_employed = mean(ps_employed),
    unemployed = max(unemployed),
    unemployed_q = sum(unemployed),
    local_unemploy = mean(local_unemploy),
    married = max(married),
    dependent = max(dependent)
  )

rec.dataCS <- rec.dataCS %>% ungroup()
rec.dataCS$recid[rec.dataCS$recid == 0 & rec.dataCS$add_rec==1] <- 1
rec.dataCS <- subset(rec.dataCS, select=-add_rec)

write.csv(rec.dataCS, './Stata Files/recDataCSAdmin.csv', row.names=FALSE, na="")

#############################
### Survey Based Outcomes ###
#############################

for(i in c(1:m)){
  # Missed Rent
  mRent.data <- mi.data[[i]][c('STID', 'Seq', 'MissedRent', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'total_income', 'logIncome', 'income_lag', 'pstudy_logIncome', 'pstudy_employed', 'ps_mRent', 'FullTime', 'fullTime_lag', 'unemploy_lag', 'local_unemploy', 'Married', 'dependent', 'Year')]
  colnames(mRent.data) <- c('stid', 'seq', 'm_rent', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'total_income', 'income', 'income_lag', 'ps_income', 'ps_employed', 'ps_m_rent', 'full_time', 'full_time_lag', 'unemploy_lag', 'local_unemploy', 'married', 'dependent', 'year')
  
  write.csv(mRent.data, paste0('./Stata Files/mRentData',i,'.csv'), row.names=FALSE, na="")
  
  # Full Time
  full_time.data <- mi.data[[i]][c('STID', 'Seq', 'FullTime', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'total_income', 'logIncome', 'income_lag', 'pstudy_logIncome', 'unemploy_lag', 'pstudy_employed', 'ps_fullTime', 'fullTime_lag', 'local_unemploy', 'Married', 'dependent', 'Year')]
  colnames(full_time.data) <- c('stid', 'seq', 'full_time', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'total_income', 'income', 'income_lag', 'ps_income', 'unemploy_lag', 'ps_employed', 'ps_full_time', 'full_time_lag', 'local_unemploy','married', 'dependent', 'year')
  
  write.csv(full_time.data, paste0('./Stata Files/full_timeData', i, '.csv'), row.names=FALSE, na="")
  
  # Job Satisfaction
  jobSat.data <- mi.data[[i]][c('STID', 'Seq', 'JobSat', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'logIncome', 'income_lag', 'fullTime_lag', 'unemploy_lag', 'local_unemploy', 'pstudy_employed', 'Year')]
  colnames(jobSat.data) <- c('stid', 'seq', 'job_sat', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'income', 'income_lag', 'full_time_lag', 'unemploy_lag', 'local_unemploy', 'ps_employed', 'year')
  
  write.csv(jobSat.data, paste0('./Stata Files/job_satData', i, '.csv'), row.names=FALSE, na="")
  
  # Applied for New Job
  jobApply.data <- mi.data[[i]][c('STID', 'Seq', 'JobApply', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'logIncome', 'income_lag', 'fullTime_lag', 'unemploy_lag', 'JobDeter', 'local_unemploy', 'pstudy_income', 'pstudy_employed', 'ps_jobApply', 'Married', 'dependent', 'Year')]
  colnames(jobApply.data) <- c('stid', 'seq', 'job_apply', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'income', 'income_lag', 'full_time_lag', 'unemploy_lag', 'job_deter', 'local_unemploy', 'ps_income', 'ps_employed', 'ps_job_apply', 'married', 'dependent', 'year')
  
  write.csv(jobApply.data, paste0('./Stata Files/jobApplyData', i, '.csv'), row.names=FALSE, na="")
  
  # Deterred from New Job
  jobDeter.data <- mi.data[[i]][c('STID', 'Seq', 'JobDeter', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'logIncome', 'income_lag', 'fullTime_lag', 'unemploy_lag', 'local_unemploy', 'pstudy_income', 'pstudy_employed', 'ps_jobDeter', 'Married', 'dependent', 'Year')]
  colnames(jobDeter.data) <- c('stid', 'seq', 'job_deter', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'income', 'income_lag', 'full_time_lag', 'unemploy_lag', 'local_unemploy', 'ps_income', 'ps_employed', 'ps_job_deter', 'married', 'dependent', 'year')
  
  write.csv(jobDeter.data, paste0('./Stata Files/jobDeterData',i, '.csv'), row.names=FALSE, na="")
  
  # Homelessness- not modeled as panel data; see cross-sectional model instead
  homeless.data <- mi.data[[i]][c('STID', 'Seq', 'Homeless', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'total_income', 'logIncome', 'income_lag', 'Unemployed', 'unemploy_lag', 'pstudy_income', 'pstudy_employed', 'local_unemploy', 'Married', 'dependent', 'Year')]
  colnames(homeless.data) <- c('stid', 'seq', 'homeless', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'total_income', 'income', 'income_lag', 'unemployed', 'unemploy_lag', 'ps_income', 'ps_employed', 'local_unemploy', 'married', 'dependent', 'year')
  
  # Homelessness Cross-Section
  homeless.dataCS <- homeless.data %>% 
    group_by(stid) %>%
    summarise(
      homeless = max(homeless),
      treatment = max(treatment),
      expunge = max(expunge),
      white = max(white),
      female = max(female),
      age_enroll = max(age_enroll),
      total_income = mean(total_income),
      income = mean(income),
      ps_income = mean(ps_income),
      ps_employed = mean(ps_employed),
      unemployed = max(unemployed),
      unemployed_q = sum(unemployed),
      local_unemploy = mean(local_unemploy),
      married = max(married),
      dependent = max(dependent)
    )
  
  homeless.dataCS <- homeless.dataCS %>% ungroup()
  
  write.csv(homeless.dataCS, paste0('./Stata Files/homelessDataCS', i, '.csv'), row.names=FALSE, na="")
  
  # Moved- with Utility data derived moves
  movedUty.data <- mi.data[[i]][c('STID', 'Seq', 'MovedUtility', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'logIncome', 'income_lag', 'HouseSat', 'MoveDeter', 'Unemployed', 'unemploy_lag', 'pstudy_employed', 'ps_moved', 'local_unemploy', 'Married', 'dependent', 'Year')]
  colnames(movedUty.data) <- c('stid', 'seq', 'moved_uty', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'income', 'income_lag', 'house_sat', 'move_deter', 'unemployed', 'unemploy_lag', 'ps_employed', 'ps_moved', 'local_unemploy', 'married', 'dependent', 'year')
  
  write.csv(movedUty.data, paste0('./Stata Files/movedUtyData', i, '.csv'), row.names=FALSE, na="")
  
  # Housing Satisfaction
  houseSat.data <- mi.data[[i]][c('STID', 'Seq', 'HouseSat', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'logIncome', 'income_lag', 'BQID2', 'BQID3', 'MoveAttempt', 'Unemployed', 'unemploy_lag', 'pstudy_employed', 'local_unemploy', 'Married', 'dependent', 'Year')]
  colnames(houseSat.data) <- c('stid', 'seq', 'house_sat', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'income', 'income_lag', 'house_num', 'house_size', 'move_attempt', 'unemployed', 'unemploy_lag', 'ps_employed', 'local_unemploy', 'married', 'dependent', 'year')
  
  write.csv(houseSat.data, paste0('./Stata Files/houseSatData', i, '.csv'), row.names=FALSE, na="")
  
  # Attempted New Move
  moveAttempt.data <- mi.data[[i]][c('STID', 'Seq', 'MoveAttempt', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'logIncome', 'income_lag', 'BQID2', 'BQID3', 'Unemployed', 'unemploy_lag', 'local_unemploy', 'pstudy_income', 'pstudy_employed', 'ps_moveAttempt', 'Married', 'dependent', 'Year')]
  colnames(moveAttempt.data) <- c('stid', 'seq', 'move_attempt', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'income', 'income_lag', 'house_num', 'house_size', 'unemployed', 'unemploy_lag', 'local_unemploy', 'ps_income', 'ps_employed', 'ps_move_attempt', 'married', 'dependent', 'year')
  
  write.csv(moveAttempt.data, paste0('./Stata Files/moveAttemptData',i, '.csv'), row.names=FALSE, na="")
  
  # Deterred From Move
  moveDeter.data <- mi.data[[i]][c('STID', 'Seq', 'MoveDeter', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'logIncome', 'income_lag', 'BQID2', 'BQID3', 'Unemployed', 'unemploy_lag', 'local_unemploy', 'pstudy_income', 'pstudy_employed', 'ps_moveDeter', 'Married', 'dependent', 'Year')]
  colnames(moveDeter.data) <- c('stid', 'seq', 'move_deter', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'income', 'income_lag', 'house_num', 'house_size', 'unemployed', 'unemploy_lag', 'local_unemploy', 'ps_income', 'ps_employed', 'ps_move_deter', 'married', 'dependent', 'year')
  
  write.csv(moveDeter.data, paste0('./Stata Files/moveDeterData',i, '.csv'), row.names=FALSE, na="")
  
  # Life Satisfaction
  lifeSat.data <- mi.data[[i]][c('STID', 'Seq', 'LifeSat', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'logIncome', 'income_lag', 'HouseSat', 'JobSat', 'Unemployed', 'unemploy_lag', 'pstudy_income', 'pstudy_employed', 'local_unemploy', 'Married', 'dependent', 'Year')]
  colnames(lifeSat.data) <- c('stid', 'seq', 'life_sat', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'income', 'income_lag', 'house_sat', 'job_sat', 'unemployed', 'unemploy_lag', 'ps_income', 'ps_employed', 'local_unemploy', 'married', 'dependent', 'year')
  
  write.csv(lifeSat.data, paste0('./Stata Files/lifeSatData', i, '.csv'), row.names=FALSE, na="")
  
  # Combined Happiness/Agency
  lifeComp.data <- mi.data[[i]][c('STID', 'Seq', 'LifeComp', 'Treatment', 'expunge', 'white', 'Female', 'AgeEnroll', 'logIncome', 'income_lag', 'HouseSat', 'JobSat', 'Unemployed', 'unemploy_lag', 'pstudy_income', 'pstudy_employed', 'local_unemploy', 'Married', 'dependent', 'Year')]
  colnames(lifeComp.data) <- c('stid', 'seq', 'life_comp', 'treatment', 'expunge', 'white', 'female', 'age_enroll', 'income', 'income_lag', 'house_sat', 'job_sat', 'unemployed', 'unemploy_lag', 'ps_income', 'ps_employed', 'local_unemploy', 'married', 'dependent', 'year')
  
  write.csv(lifeComp.data, paste0('./Stata Files/lifeCompData', i, '.csv'), row.names=FALSE, na="")
  
}