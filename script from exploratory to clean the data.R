# Set libPaths.
.libPaths("/Users/tylermuffly/.exploratory/R/3.6")

# Load required packages.
library(janitor)
library(lubridate)
library(hms)
library(tidyr)
library(stringr)
library(readr)
library(forcats)
library(RcppRoll)
library(dplyr)
library(tibble)
library(bit64)
library(exploratory)

# Custom R function as Data.
zipcodes.func <- function(){
  library(zipcode)
  data(zipcode)
  zipcode
}

# Steps to produce median_household_income_fro_mMichigan_Population_Studies_Center
`median_household_income_fro_mMichigan_Population_Studies_Center` <- exploratory::read_excel_file( "/Users/tylermuffly/Dropbox/workforce/Data/median household income fro mMichigan Population Studies Center.xlsx", sheet = "nation", na = c('','NA'), skip=0, col_names=TRUE, trim_ws=TRUE, col_types="text") %>%
  readr::type_convert() %>%
  exploratory::clean_data_frame() %>%
  mutate(Zip = as.character(Zip))

# Steps to produce geocorr2014_zip_code_urban_v_rural
`geocorr2014_zip_code_urban_v_rural` <- exploratory::read_delim_file("/Users/tylermuffly/Dropbox/workforce/Data/geocorr2014-zip code urban v rural.csv" , ",", quote = "\"", skip = 1 , col_names = TRUE , na = c('','NA') , locale=readr::locale(encoding = "UTF-8", decimal_mark = "."), trim_ws = TRUE , progress = FALSE) %>%
  readr::type_convert() %>%
  exploratory::clean_data_frame() %>%
  select(-`Total population (2010)`, -`zcta5 to cbsatype10 allocation factor`) %>%
  mutate(`State code` = statecode(`State code`, output_type = "name"), `State code_statecode` = statecode(`State code`, output_type = "alpha_code"), `ZIP census tabulation area` = as.character(`ZIP census tabulation area`))

# Steps to produce xtract_from_mcdc_missouri
`xtract_from_mcdc_missouri` <- exploratory::read_delim_file("/Users/tylermuffly/Dropbox/workforce/Data/xtract from mcdc missouri.csv" , ",", quote = "\"", skip = 0 , col_names = TRUE , na = c('','NA') , locale=readr::locale(encoding = "UTF-8", decimal_mark = "."), trim_ws = TRUE , progress = FALSE) %>%
  readr::type_convert() %>%
  exploratory::clean_data_frame()

# Steps to produce zipcodes
`zipcodes` <- zipcodes.func() %>%
  readr::type_convert() %>%
  exploratory::clean_data_frame()

# Steps to produce correct_lat_long
`correct_lat_long` <- exploratory::read_delim_file("/Users/tylermuffly/Dropbox/Mystery shopper/Data/correct_lat_long.csv" , ",", quote = "\"", skip = 0 , col_names = TRUE , na = c('','NA') , locale=readr::locale(encoding = "UTF-8", decimal_mark = ".", grouping_mark = "," ), trim_ws = TRUE , progress = FALSE) %>%
  readr::type_convert() %>%
  exploratory::clean_data_frame() %>%
  select(Clinic, `Zip code`, latitude, longitude) %>%
  mutate(Clinic = str_to_title(Clinic)) %>%
  select(-`Zip code`)

# Steps to produce the output
exploratory::read_excel_file( "/Users/tylermuffly/Dropbox/Mystery shopper/Data/mystery caller data uploaded 4.9.xlsx", sheet = "Sheet1", na = c('','NA'), skip=0, col_names=TRUE, trim_ws=TRUE, tzone='America/Denver') %>%
  readr::type_convert() %>%
  exploratory::clean_data_frame() %>%
  
  # This is the weird group that has duplicate on the notes/exclusion section.  
  filter(Docs %nin% c("Virginia G King, MD", "Milena M Weinstein, MD")) %>%
  
  # Only calling US offices.  
  filter(Clinic != "University of British Columbia OB/GYN, St Paul's Hospital") %>%
  select(-`Nunber on List`, -...4, -...5, -...6, -...7, -`Speaking to Male or Female`, -`Group or Single`, -`AMC or Not`, -`2nd language`, -`Number days wait time`, -Notes) %>%
  mutate(`If Not able to contact, reason` = recode(`If Not able to contact, reason`, `Went to office VM` = "Went to voicemail", `Went to VM` = "Went to voicemail", `Went to office's VM` = "Went to voicemail", `went to office's VM` = "Went to voicemail", `went to  office VM` = "Went to voicemail", `went to VM` = "Went to voicemail", `went to  office's VM` = "Went to voicemail", `went to vm` = "Went to voicemail", `Went to office vm` = "Went to voicemail", `Went to offices VM` = "Went to voicemail", `Went to vm` = "Went to voicemail", `Wrong number listed (cell)` = "Phone number to FPMRS physician's personal phone", `Went to VM (doc's cell)` = "Phone number to FPMRS physician's personal phone", `Went to VM, Not sure if personal or clinic` = "Phone number to FPMRS physician's personal phone", `Wrong number listed (doc's cel)` = "Phone number to FPMRS physician's personal phone", `Went to VM (home)` = "Phone number to FPMRS physician's personal phone", `went to VM (doc's cell)` = "Phone number to FPMRS physician's personal phone", `Wrong number listed (doc’s cell)` = "Phone number to FPMRS physician's personal phone", `Went to VM (cell)` = "Phone number to FPMRS physician's personal phone", `Went to vm (cell)` = "Phone number to FPMRS physician's personal phone", `Went to vm (doc’s cell)` = "Phone number to FPMRS physician's personal phone", `Went to vm (doc’s home)` = "Phone number to FPMRS physician's personal phone", `went to VM (cell)` = "Phone number to FPMRS physician's personal phone", `Wrong number listed` = "Wrong number listed", `Wrong number listed (home)` = "Phone number to FPMRS physician's personal phone", `Wrong number listed (State Farm)` = "Wrong number listed", `number Not in service` = "Wrong number listed", `Wrong number  listed (someone else)` = "Wrong number listed", `wrong number listed (cell)` = "Phone number to FPMRS physician's personal phone", `wrong number listed (someone else)` = "Wrong number listed", `Wrong number listed, academic office, went to VM` = "Wrong number listed", `Provided with academic office number on voicemail at academic office` = "Wrong number listed", `Busy signal` = "Phone not answer or busy signal on repeat calls", `rang without answer or machine for 2min, then call ended from other side` = "Phone not answer or busy signal on repeat calls", `busy signal` = "Phone not answer or busy signal on repeat calls", `No answer` = "Phone not answer or busy signal on repeat calls", `Office closed on 3 attempts` = "Phone not answer or busy signal on repeat calls", `On hold >5min` = "Greater than 5 minutes on hold", `>5min without a specific appointment date, need doc to review records first` = "Greater than 5 minutes on hold", `>5min on hold` = "Greater than 5 minutes on hold", `on hold >5min` = "Greater than 5 minutes on hold", `Closed for vacation` = "Not accepting New or Medicare Patients", `No phone number provided` = "No phone number provided", `No number listed` = "No phone number provided", `No phone number listed` = "No phone number provided", `Number Not in service` = "Wrong number listed", `Clinic Number Not in service` = "Wrong number listed", Yes = "Included for analysis", `office closed` = "Not accepting New or Medicare Patients", `Put on hold, call dropped` = "Greater than 5 minutes on hold", `Went to academic office vm` = "Wrong number listed", No = "Phone number to FPMRS physician's personal phone", s = "Went to voicemail")) %>%
  mutate(`If Not able to contact, reason` = na_if(`If Not able to contact, reason`, "Included for analysis"), `If Not able to contact, reason` = impute_na(`If Not able to contact, reason`, type = "value", val = "Included for Analysis")) %>%
  rename(Exclusions = `If Not able to contact, reason`) %>%
  mutate(`Hold Time` = recode(`Hold Time`, `0` = "0", `10sec` = "10", `15sec` = "15", O = "0", `1min` = "60", `1.5min` = "90", `5` = "5", `1min 10sec` = "70", `40sec` = "40", `3min 20sec` = "200", `5min` = "300", `2min 50sec` = "170", `7` = "7", `1.25min` = "75", `2` = "2", `50sec` = "50", `2.5min` = "150", `5 sec` = "5", `35sec` = "35", `4min` = "240", `5sec` = "5", `1 min` = "60", `1min 45 sec` = "105", `30sec, then 45 sec` = "75", `30sec` = "30", `1min 20sec` = "80", `20 sec` = "20", `45sec` = "45", `2min` = "120", `20sec` = "20", `3min` = "180", `2.25min` = "140", `1.75, 2min` = "120", `2 min` = "120", `1.5` = "90", `3 min` = "180", `50 sec` = "50", `4` = "240", `30 sec` = "30", `2.75min, 30sec` = "210", `3min 10 sec` = "190", `2min 15sec` = "135", `2.75min` = "175", `3.5min` = "190")) %>%
  mutate(`Hold Time` = parse_number(`Hold Time`)) %>%
  rename(`Hold Time (seconds)` = `Hold Time`) %>%
  mutate(`Length of call (min)` = parse_number(`Length of call (min)`), `Hold Time (seconds)` = `Hold Time (seconds)`/60) %>%
  rename(`Hold Time (min)` = `Hold Time (seconds)`) %>%
  mutate(`Insuance asked before appt date` = recode(`Insuance asked before appt date`, Yes = "Yes", No = "No", Medicare = "Yes")) %>%
  distinct(Clinic, .keep_all = TRUE) %>%
  distinct(Docs, .keep_all = TRUE) %>%
  mutate(`Accept Medicare` = recode(`Accept Medicare`, `Yes, case by case` = "Yes", Yes = "Yes", No = "No", `No, but have discounted self pay option` = "No")) %>%
  mutate(`Day of the week` = wday(`Date called`, label = TRUE, abbr = FALSE)) %>%
  mutate(`Date called day of the week` = wday(`Date called`, label = TRUE, abbr = FALSE), `Appt date` = excel_numeric_to_date(`Appt date`)) %>%
  mutate(`Business days until appointment` = bizdays(`Date called`, `Appt date`, "MyCalendar")) %>%
  left_join(correct_lat_long, by = c("Clinic" = "Clinic")) %>%
  mutate(`Date called` = as_date(`Date called`)) %>%
  mutate(`Able to contact` = recode(`Able to contact`, `Received call back from cell` = "Yes")) %>%
  mutate_at(vars(`Number of transfers`, `Length of call (min)`), funs(parse_number)) %>%
  
  # Fill in all "Able to contact".  
  mutate(`Able to contact` = impute_na(`Able to contact`, type = "value", val = "Yes")) %>%
  select(-`Recommend elsewhere that takes Medicare`, -Exclusion, -`Day of the week`) %>%
  reorder_cols(Exclusions, `Business days until appointment`, `Insuance asked before appt date`, `First available Male or Female (No midlevel, will see fellow)`, `Accept Medicare`, `Accepting new patients`, `Number of transfers`, `Hold Time (min)`, `Central number`, `Length of call (min)`, `Date called day of the week`, latitude, longitude, Clinic, Docs, `Date called`, `Appt date`, `Able to contact`) %>%
  arrange(Docs) %>%
  mutate(`Zip code` = str_pad(`Zip code`, pad="0", side="left", width=5)) %>%
  left_join(zipcodes, by = c("Zip code" = "zip")) %>%
  left_join(xtract_from_mcdc_missouri, by = c("Zip code" = "zcta5")) %>%
  select(-County2, -PlaceFP, -PlaceFP2, -CouSubFP, -CouSubFP2, -cd113, -cd113_2, -puma2k, -puma12, -necta, -nectaDiv, -Cnecta, -cbsa, -MetDiv, -csa, -CBSAType, -PctUrban, -pctcnty, -pctcnty2, -cnty2k, -pctcnty2k, -pctcousub, -pctplace, -pctplace2, -ua, -pctua, -pctcd113, -pctpuma2k, -pctpuma12, -pctnecta, -pctnectadiv, -pctcnecta, -pctcbsa, -pctcsa, -pctmetdiv, -pctcbsatype, -Fipco, -FipCo2, -PlaceName, -CBSAName, -MetDivName, -CSAName, -NectaName, -UAName, -Puma12Name, -UAtype, -Pop10ZCTAstate, -ZipTotPop, -Nstates, -psf, -pctState, -PctState2, -State2, -Stab2, -Pop10State2, -AltZIPs, -NaltZIPs, -SumLev, -Stab, -IntPtLat, -IntPtLon, -LandSQMI, -AreaSQMI, -TotPop10, -esriid, -TotPopACS, -MedianAge, -pctUnder18, -pctOver65, -pctWhite1, -pctBlack1, -pctAsian1, -pctHispanicPop, -TotHHs, -MedianHHInc, -FamHHs, -MedianFamInc, -PovUniverse, -pctPoor, -pctGrpQuarters, -pctInCollege, -pctBachelorsormore, -pctForeignBorn, -TotHUs, -OccHUs, -pctRenterOcc, -MedianHValue, -MedianGrossRent, -ACSYears, -Div, -Reg) %>%
  
  # Metropolitan vs. Micropolitan 
  left_join(geocorr2014_zip_code_urban_v_rural, by = c("Zip code" = "ZIP census tabulation area")) %>%
  left_join(median_household_income_fro_mMichigan_Population_Studies_Center, by = c("Zip code" = "Zip")) %>%
  select(-`State code`, -`State abbreviation`, -`ZCTA name`, -`State code_statecode`) %>%
  select(-Mean, -Pop) %>%
  mutate(clean_zip_codes = str_pad(`Zip code`, pad="0", side="left", width=5)) %>%
  mutate(Business_Days_Until_Appt_category = cut(`Business days until appointment`, breaks = c(-Inf, 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, Inf), labels = c("Same day", "1 to  10 business days", "11 to 20 business days", "21 to 30 business days", "31 to 40 business days", "41 to 50 business days", "51 to 60 business days", "61 to 70 business days", "71 to 80 business days", "81 to 90 business days", "Over 90 business days"), include.lowest = TRUE, dig.lab = 10)) %>%
  distinct(Clinic, .keep_all = TRUE) %>%
  distinct(Docs, .keep_all = TRUE) %>%
  mutate(Clinic = str_to_title(Clinic)) %>%
  separate(ZIPName, into = c("city", "state"), sep = "\\s*\\,\\s*", remove = TRUE, convert = TRUE) %>%
  mutate(state = statecode(state, output_type="alpha_code")) %>%
  mutate(ACOG_Region = state.x, ACOG_Region = recode_factor(ACOG_Region, CO = "District VIII", AL = "District VII", AR = "District VII", AZ = "District VIII", CA = "District IX", FL = "District XII", GA = "District IV", HI = "District VIII", IA = "District VI", ID = "District VIII", IL = "District VI", IN = "District V", KS = "District VII", LA = "District VII", MA = "District I", MD = "District IV", ME = "District I", MI = "District V", MN = "District VI", MO = "District VII", NC = "District IV", NH = "District I", NJ = "District III", NM = "District VIII", NY = "District II", OH = "District V", OR = "District VIII", PA = "District III", RI = "District I", SD = "District IV", TN = "District VII", TX = "District XI", VA = "District IV", WA = "District VIII", WI = "District VI", CT = "District I", DC = "District IV", KY = "District V", MS = "District VII", NE = "District VI", NV = "District VIII", SC = "District IV", WV = "District IV", UT = "District VIII", AK = "District VIII", DE = "District III", OK = "District VII")) %>%
  select(-city) %>%
  select(-latitude.x, -longitude.x) %>%
  mutate(ACOG_Region = fct_relevel(ACOG_Region, "District II", "District III", "District IV", "District V", "District VI", "District VII", "District VIII", "District IX", "District XI", "District XII"), state.x = factor(state.x)) %>%
  
  # Imputed data
  fill(`Business days until appointment`, `Insuance asked before appt date`, `First available Male or Female (No midlevel, will see fellow)`, `Accept Medicare`, `Accepting new patients`, `Number of transfers`, `Hold Time (min)`, `Length of call (min)`, cbsatype10, .direction = "down") %>%
  mutate(cbsatype10 = recode(cbsatype10, Metro = "Urban", Micro = "Rural")) %>%
  mutate(ACOG_Region = fct_relevel(ACOG_Region, "District I", "District II", "District III", "District IV", "District V", "District VI", "District VII", "District VIII", "District IX", "District XI", "District XII")) %>%
  filter(Exclusions == "Included for Analysis") %>%
  rename(`Insurance type asked before offering appointment` = `Insuance asked before appt date`, `Gender of first available female pelvic medicine and reconstructive surgeon` = `First available Male or Female (No midlevel, will see fellow)`, Rurality = cbsatype10, `Business Days Until Appointment` = Business_Days_Until_Appt_category, `American Congress of Obstetricians and Gynecologists Region` = ACOG_Region, `Day of the week the office was called` = `Date called day of the week`, `First Available FPMRS Physician:  ` = Docs) %>%
  mutate(`American Congress of Obstetricians and Gynecologists Region` = fct_other(`American Congress of Obstetricians and Gynecologists Region`, keep = c("District I", "District II", "District III", "District IV", "District V", "District VI", "District VII", "District VIII", "District IX", "District XI", "District XII"))) %>%
  rename(`American Congress of Obstetricians and Gynecologists District` = `American Congress of Obstetricians and Gynecologists Region`) %>%
  mutate(`American Congress of Obstetricians and Gynecologists District` = recode(`American Congress of Obstetricians and Gynecologists District`, `District I` = "District I (Atlantic Provinces, Connecticut, Maine, Massachusetts, Rhode Island, Vermont)", `District II` = "District II (New York)", `District III` = "District III (Delaware, New Jersey, Pennsylvania)", `District IV` = "District IV (District of Columbia, Georgia, Maryland, North Carolina, South Carolina, Virginia, West Virginia)", `District V` = "District V (Indiana, Kentucky, Ohio, Michigan)", `District VI` = "District VI (Illinois, Iowa, Minnesota, Nebraska, North Dakota, South Dakota, Wisconsin)", `District VII` = "District VII (Alabama, Arkansas, Kansas, Louisiana, Mississippi, Missouri, Oklahoma, Tennessee)", `District VIII` = "District VIII (Alaska, Arizona, Colorado, Hawaii, Idaho, Montana, Nevada, New Mexico, Oregon, Utah, Washington, Wyoming)", `District IX` = "District IX (California)", `District XI` = "District XI (Texas)", `District XII` = "District XII (Florida)"))