# Appointment Wait Times: A Mystery Caller Study
# Corbisiero

Code to evaluate enthealth.org list of physicians

<details>
<summary>Click to expand code</summary>

```R
# Your R code here
require(rvest)
require(magrittr)
require(httr)
require(jsonlite)
require(stringi)
require(dplyr)
require(xlsx)

# 1. Install packages 
# 2. Set settings
# 3. Run a script


# User settings -----------------------------------------------------------


use_cached_data = FALSE  # don't remove temporary data

country = "United States"

output_file_name = "results.xlsx"  # path to final file



# Definition of variables and functions -----------------------------------



temp_search_results = "temp_1.xlsx"
temp_search_individuals = "temp_2.xlsx"

# Session ID
ent <- 'https://www.enthealth.org/find-ent/' %>%
  session() %>%
  html_node('input[name="_ent_nonce"]') %>%
  html_attr("value")

# HTTP parameters
base_url = 'https://www.enthealth.org/wp-admin/admin-ajax.php'

headers = c(
  'authority' = 'www.enthealth.org',
  'accept' = 'application/json, text/javascript, */*; q=0.01',
  'accept-language' = 'pl-PL,pl;q=0.9,en-US;q=0.8,en;q=0.7',
  'content-type' = 'application/x-www-form-urlencoded; charset=UTF-8',
  'origin' = 'https://www.enthealth.org',
  'referer' = 'https://www.enthealth.org/find-ent/',
  'sec-ch-ua' = '"Google Chrome";v="111", "Not(A:Brand";v="8", "Chromium";v="111"',
  'sec-ch-ua-mobile' = '?0',
  'sec-ch-ua-platform' = '"Windows"',
  'sec-fetch-dest' = 'empty',
  'sec-fetch-mode' = 'cors',
  'sec-fetch-site' = 'same-origin',
  'user-agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36',
  'x-requested-with' = 'XMLHttpRequest'
)

set_body <- function(page_number) {
  body = paste0('action=find_ent_response&_ent_nonce=', ent, '&paged=', page_number, '&radiuszip=&distance=&lname=&city=&state=&country=', country, '&specialty=&ajaxrequest=true&submit=Submit+Form')
  return(body)
}

html_text_na <- function(x, ...) {
  
  txt <- try(html_text(x, ...))
  if (inherits(txt, "try-error") |
      (length(txt)==0)) { return(NA) }
  return(txt)
  
}

# Search page navigation
search <- function(page_number) {
  # POST
  r = httr::POST(base_url, add_headers(headers), body = set_body(page_number), encode="json")
  
  # Select results from JSON
  s <- content(r, 'text') %>% fromJSON()
  results <- s$results_html %>% read_html
  
  # Select URL's to individuals
  # Filter by United States
  results %<>%
    html_nodes('.result')
  urls <- c()
  for (result in results) {
    is_us <- result %>% 
      html_node('.address') %>% 
      html_text_na() %>% 
      stri_detect_regex(country) %>%
      {ifelse(is.na(.), TRUE, .)}
    if (is_us) {
      urls %<>% c(
        result %>%
        html_nodes('a') %>%
        html_attr("href") %>%
        paste0('https://www.enthealth.org', .) %>%
        stri_trans_general(id = "Latin-ASCII") %>%
        stri_split_fixed('?') %>%
        extract2(1) %>% extract(1)
      )
    }
  }
  # Check if there is a next page
  next_page_number <- s$results_pagination %>% 
    read_html %>% 
    html_node('.next') %>%
    html_attr("href")
  if (!is.na(next_page_number)) {
    next_page_number %<>% 
      stri_extract_all_regex('[0-9]+$') %>%
      extract2(1) %>%
      as.integer()
  } else {
    next_page_number <- 0
  }
  
  page_numbers <- (s$results_rows %/% 10) + 1
  
  return(list("urls" = urls, 
              "next_page_number" = next_page_number,
              "page_numbers" = page_numbers))
}

# Extract data from individual page
extract_data <- function(url) {
  s <- session(url)
  
  result <- list(
    "url" = url,
    "full_name" = s %>% html_nodes('.name') %>% html_text_na(),
    "specialty_primary" = s %>% html_nodes('.primary-specialty') %>% html_text_na(),
    "specialty_secondary" = s %>% html_nodes('.secondary-specialty') %>% html_text_na(),
    "company" = s %>% html_nodes(".company") %>% html_text_na(),
    "address_line_1" = s %>% html_nodes(".address") %>% extract(1) %>% html_text_na(),
    "address_line_2" = s %>% html_nodes(".address") %>% extract(2) %>% html_text_na(),
    "phone_number" = s %>% html_nodes(".phone") %>% html_text_na(),
    "fellowship" = s %>% html_nodes('li:contains("Fellowship: ")') %>% html_text_na() %>% stri_replace_all_fixed("Fellowship: ", "") %>% {ifelse(any(is.na(.)), NA, paste(., collapse=', '))},
    "residency" = s %>% html_nodes('li:contains("Residency: ")') %>% html_text_na() %>% stri_replace_all_fixed("Residency: ", "") %>% {ifelse(any(is.na(.)), NA, paste(., collapse=', '))},
    "medical_school" = s %>% html_nodes('li:contains("Medical School: ")') %>% html_text_na() %>% stri_replace_all_fixed("Medical School: ", "") %>% {ifelse(any(is.na(.)), NA, paste(., collapse=', '))},
    "certification" = s %>% html_nodes('h3:contains("Board Certifications") + ul > li') %>% html_text_na() %>% {ifelse(any(is.na(.)), NA, paste(., collapse=', '))}
  )
  
  return(result)
}

do_search <- function() {
  print(paste0('Get all URLs from search page - filtered by ', country))
  page_numbers <- search(1)$page_numbers
  search_results <- pbapply::pblapply(1:page_numbers, search)
  urls <- unlist(lapply(search_results, function(x) {x$urls}))
  print(paste0('Save temporary data to ', temp_search_results))
  df <- data.frame(list("urls" = urls))
  df %>% write.xlsx(temp_search_results, row.names = FALSE)
}

do_extract_data <- function() {
  if (use_cached_data) {
    results_cached <- read.xlsx(temp_search_individuals, 1)
  } else {
    results_cached <- data.frame()
  }
  
  print('Get data from URLs')
  df <- read.xlsx(temp_search_results, 1)
  urls <- df$urls
  if (use_cached_data) {
    urls <- setdiff(urls, results_cached$url)
  }
  results <- pbapply::pblapply(urls, extract_data)
  print(paste0('Save temporary data to ', temp_search_individuals))
  data = do.call(rbind.data.frame, results)
  data %<>% rbind(results_cached)
  data %>% write.xlsx(temp_search_individuals, row.names = FALSE)
}

do_data_cleaning <- function() {
  print('Data cleaning...')
  df <- read.xlsx(temp_search_individuals, 1)
  
  # 
  df[(df$address_line_1 %>% 
        stri_detect_regex(country)) & is.na(df$address_line_2), 
     'address_line_2'] <- df[(df$address_line_1 %>% 
                                stri_detect_regex(country)) & is.na(df$address_line_2), 
                             'address_line_1']
  df[(df$address_line_1 %>% stri_detect_regex(country)), 'address_line_1'] <- NA
  
  # extract country
  df['country'] <- country
  df[['address_line_2']] %<>% stri_replace_all_regex(country, '') %>% trimws()
  
  # extract city
  df %<>% mutate('city' = stri_split_regex(address_line_2, ' [A-Z]{2} '))
  df[['city']] %<>% sapply(function(x){x[1]})
  df %<>% mutate('address_line_2' = stri_replace_all_regex(address_line_2, city, '') %>% trimws)
  
  # extract state code
  df %<>% mutate('state_code' = stri_extract_first_regex(address_line_2, '[A-Z]{2}'))
  df %<>% mutate('address_line_2' = stri_replace_all_regex(address_line_2, state_code, '') %>% trimws)
  
  # extract post code
  df %<>% mutate('post_code' = stri_extract_first_regex(address_line_2, '[0-9]+(-[0-9]+)?'))
  df %<>% mutate('address_line_2' = stri_replace_all_regex(address_line_2, post_code, '') %>% trimws)
  
  # final table
  data <- df %>%
    select(
      url, full_name, 
      company, address_line_1, city, state_code, post_code, country,
      phone_number, specialty_primary, specialty_secondary
    )
  for (col in colnames(data)) {
    data[[col]] %<>% trimws
    data[[col]] %<>% {ifelse(. == '', NA, .)}
  }
  data %<>% rename('company_name' = 'company', 'address' = 'address_line_1')
  
  # save data
  data %>% write.xlsx(output_file_name, row.names = FALSE, showNA = FALSE)
}

# Main script -------------------------------------------------------------

do_search()
do_extract_data()
do_data_cleaning()
```
 </details>
  
# Inclusion and Exclusion
Inclusion criteria: ENT physician with generalist and subspecialty training listed on enthealth.org find a physician list.  
Exclusion criteria: No phone number, outside the USA, unable to reach after 2 phone calls, on hold for 5 minutes or greater

# Code to clean the data output from enthealth.org find a doctor.  
This is what will be uploaded to RedCAP.  

<details>
<summary>Click to expand code</summary>
  
```R
# Set libPaths.
.libPaths("/Users/tylermuffly/.exploratory/R/4.2")

# Load required packages.
library(bizdays)
library(humaniformat)
library(gender)
library(janitor)
library(lubridate)
library(hms)
library(tidyr)
library(stringr)
library(readr)
library(cpp11)
library(forcats)
library(RcppRoll)
library(dplyr)
library(tibble)
library(bit64)
library(zipangu)
library(exploratory)

# Steps to produce zip_to_lat_long
`zip_to_lat_long` <- 
  # https://gist.github.com/mufflyt/369fee8b22cdffd21d77377876ece393
  exploratory::read_excel_file( "/Users/tylermuffly/Dropbox (Personal)/Mystery shopper/mystery_shopper/Corbi study/Data/zip to lat long.xlsx", sheet = 1, na = c('','NA'), skip=0, col_names=TRUE, trim_ws=TRUE, tzone='America/Denver') %>%
  readr::type_convert() %>%
  exploratory::clean_data_frame() %>%
  separate(`ZIP,LAT,LNG`, into = c("zip", "lat", "lng"), sep = "\\s*\\,\\s*", convert = TRUE) %>%
  mutate(zip = as.character(zip))

# Steps to produce the output

  # From Bart's scrape of AAO-HNS.  
  exploratory::read_excel_file( "/Users/tylermuffly/Dropbox (Personal)/Mystery shopper/mystery_shopper/Corbi study/ENT/Data/results.xlsx", sheet = 1, col_names=TRUE, trim_ws=TRUE, tzone='America/Denver') %>%
  readr::type_convert() %>%
  exploratory::clean_data_frame() %>%
  distinct(url, .keep_all = TRUE) %>%
  reorder_cols(full_name, company_name, address, city, state_code, post_code, country, phone_number, specialty_primary, specialty_secondary, url) %>%
  
  # They have to have a phone number listed to participate.  
  filter(!is.na(phone_number)) %>%
  
  # Only look at specialty_primary
  select(-address, -country, -specialty_secondary) %>%
  
  # Fill in "General Otolaryngology" for all NA values.  
  mutate(specialty_primary = impute_na(specialty_primary, type = "value", val = "General Otolaryngology")) %>%
  
  # Limited to six subspecialties.  
  filter(specialty_primary %nin% c("General Otolaryngology", "Allergy", "Endocrine Surgery", "Otology/Audiology", "Sleep Medicine")) %>%
  mutate(state_code = statecode(state_code, output_type = "name")) %>%
  mutate(state_code = impute_na(state_code, type = "value", val = "Colorado")) %>%
  
  # Change state name to Board of Governors Regions.  
  mutate(AAO_regions = recode(state_code, "Alabama" = "Region 4", "Alaska" = "Region 9", "Arizona" = "Region 10", "Arkansas" = "Region 6", "California" = "Region 10", "Colorado" = "Region 8", "Connecticut" = "Region 1", "Delaware" = "Region 3", "District of Columbia" = "Region 3", "Florida" = "Region 4", "Georgia" = "Region 4", "Hawaii" = "Region 10", "Idaho" = "Region 9", "Illinois" = "Region 5", "Indiana" = "Region 5", "Iowa" = "Region 7", "Kansas" = "Region 7", "Kentucky" = "Region 4", "Louisiana" = "Region 6", "Maryland" = "Region 3", "Massachusetts" = "Region 1", "Michigan" = "Region 5", "Minnesota" = "Region 5", "Mississippi" = "Region 4", "Missouri" = "Region 7", "Montana" = "Region 8", "Nebraska" = "Region 7", "Nevada" = "Region 10", "New Hampshire" = "Region 1", "New Jersey" = "Region 2", "New Mexico" = "Region 6", "New York" = "Region 2", "North Carolina" = "Region 4", "North Dakota" = "Region 8", "Ohio" = "Region 5", "Oklahoma" = "Region 6", "Oregon" = "Region 9", "Pennsylvania" = "Region 3", "Puerto Rico" = "Region 2", "Rhode Island" = "Region 1", "South Carolina" = "Region 4", "South Dakota" = "Region 8", "Tennessee" = "Region 4", "Texas" = "Region 6", "Utah" = "Region 8", "Vermont" = "Region 1", "Virgin Islands" = "Region 2", "Virginia" = "Region 3", "Washington" = "Region 9", "West Virginia" = "Region 3", "Wisconsin" = "Region 5", "Wyoming" = "Region 8"), .after = ifelse("state_code" %in% names(.), "state_code", last_col())) %>%
  mutate(across(c(AAO_regions, specialty_primary), factor)) %>%
  
  # Make sure that the AAO_regions are leveled from 1 to 10.  
  mutate(AAO_regions = fct_relevel(AAO_regions, "Region 1", "Region 2", "Region 3", "Region 4", "Region 5", "Region 6", "Region 7", "Region 8", "Region 9", "Region 10")) %>%
  mutate(specialty_primary = fct_infreq(specialty_primary)) %>%
  
  # Group by AAO_regions and specialty before sample.  
  group_by(AAO_regions, specialty_primary) %>%
  
  # Sampling step here.  More than 10 samples by region and by specialty starts to get problematic after more than 10.  
  sample_rows(10, seed = 1978) %>%
  
  # Clean up the postal code.  
  mutate(zip = str_extract_before(post_code, sep = "\\-"), .after = ifelse("post_code" %in% names(.), "post_code", last_col())) %>%
  
  # Bring together two columns of zip code: "zip" and "post_code".  
  mutate(zip = coalesce(zip, post_code)) %>%
  mutate(zip = parse_number(zip)) %>%
  mutate(zip = as.character(zip)) %>%
  
  # Match the zip code to latitude and longitude.  
  left_join(`zip_to_lat_long`, by = c("zip" = "zip"), target_columns = c("zip", "lat", "lng"), ignorecase=TRUE) %>%
  
  # Use humaniformat to clean the names so that matches can be made between dataframes based on names.  
  mutate(first = humaniformat::first_name(full_name)) %>%
  separate(full_name, into = c("full_name_1", "full_name_2"), sep = "\\s*\\,\\s*", remove = FALSE, convert = TRUE) %>%
  mutate(last = humaniformat::last_name(full_name_1)) %>%
  
  # Create the line of text with name, phone number, specialty, and insurance type.  
  mutate(calculation_1 = "Dr") %>%
  unite(united_column, calculation_1, last, sep = " ", remove = FALSE, na.rm = FALSE) %>%
  
  # Unite all parts of the name, specialty, etc.  
  unite(redcap_data, specialty_primary, united_column, phone_number, full_name, sep = ",  ", remove = FALSE, na.rm = FALSE) %>%
  ungroup() %>%
  
  # Amazing.  Creates a numbered row column.  
  mutate(id = 1:n()) %>%
  
  # Doubles amount of rows by stacking a copy of the rows on top of the dataframe. In this code, the . refers to the input data frame (df), and the duplicated data frame is created by binding it with itself using bind_rows(., .).
  bind_rows(., .) %>%
  
  # Arrange by url so that one person has two rows consecutively.  
  arrange(url) %>%
  
  # Add the two different insurances: BCBS and Medicaid for each person.  
  mutate(Insurance = rep(c("Blue Cross/Blue Shield", "Medicaid"), length.out = nrow(.))) %>%
  
  # Each physician has two duplicate rows with the same id number.  
  arrange(id) %>%
  select(-id) %>%
  
  # Unique row number for each row.  
  mutate(id = 1:n()) %>%
  
  # Unite all the information to upload to redcap: https://redcap.ucdenver.edu/redcap_v13.1.18/ProjectSetup/index.php?pid=28103. 
  unite(united_column, id, redcap_data, Insurance, sep = ", ", remove = FALSE, na.rm = FALSE) %>%
  filter(!str_detect(company_name, fixed("miliary", ignore_case=TRUE)) & !str_detect(company_name, fixed("Retired"))) %>%
  
  # Academic or Not based on strings.  
  mutate(academic = ifelse(str_detect(company_name, str_c(c("Medical College", "University of", "University", "Univ", "Children's", "Infirmary", "Medical School", "Medical Center", "Medical Center", "Children", "Health System", "Foundation", "Sch of Med", "Dept of Oto", "Mayo", "UAB", "OTO Dept", "Cancer Ctr", "Penn", "College of Medicine", "Cancer", "Cleveland Clinic", "Henry Ford", "Yale", "Brigham", "Dept of OTO", "Health Sciences Center", "SUNY"), collapse = "|", sep = "\\b|\\b", fixed = TRUE)), "University", "Private Practice")) %>%
  reorder_cols(AAO_regions, united_column, redcap_data, specialty_primary, full_name, full_name_1, full_name_2, company_name, academic, city, state_code, post_code, zip, phone_number, url, lat, lng, first, last, calculation_1, Insurance, id)
```
</details>

# RedCAP: The project name is called, "ENT subspecialty mystery caller".
Please note that any publication that results from a project utilizing REDCap should cite grant support (NIH/NCATS Colorado CTSA Grant Number UL1 TR002535).  Please cite the publications below in study manuscripts using REDCap for data collection and management. We recommend the following boilerplate language:

Study data were collected and managed using REDCap electronic data capture tools hosted at [YOUR INSTITUTION].1,2 REDCap (Research Electronic Data Capture) is a secure, web-based software platform designed to support data capture for research studies, providing 1) an intuitive interface for validated data capture; 2) audit trails for tracking data manipulation and export procedures; 3) automated export procedures for seamless data downloads to common statistical packages; and 4) procedures for data integration and interoperability with external sources.

1PA Harris, R Taylor, R Thielke, J Payne, N Gonzalez, JG. Conde, Research electronic data capture (REDCap) – A metadata-driven methodology and workflow process for providing translational research informatics support, J Biomed Inform. 2009 Apr;42(2):377-81.

2PA Harris, R Taylor, BL Minor, V Elliott, M Fernandez, L O’Neal, L McLeod, G Delacqua, F Delacqua, J Kirby, SN Duda, REDCap Consortium, The REDCap consortium: Building an international community of software partners, J Biomed Inform. 2019 May 9 [doi: 10.1016/j.jbi.2019.103208]


# Sign up for REDCap
https://cctsi.cuanschutz.edu/resources/informatics/redcap-resources#tutorials


# Corbisiero and lab
[![wait time image](https://qtxasset.com/styles/breakpoint_xl_880px_w/s3/2016-07/doctor%20time%20pressure_workflow_efficiency_3.jpg?uDX919pEHAYTO1r6lKp7qT3dGPFjo1R_&itok=bGaBk9j6)](https://qtxasset.com/styles/breakpoint_xl_880px_w/s3/2016-07/doctor%20time%20pressure_workflow_efficiency_3.jpg?uDX919pEHAYTO1r6lKp7qT3dGPFjo1R_&itok=bGaBk9j6) 

Data Sources 
==========
* https://www.psc.isr.umich.edu/dis/census/Features/tract2zip/, Geographic Correspondence Engine at Missouri Census Data Center
* http://mcdc.missouri.edu/applications/geocorr2018.html
* https://www.voicesforpfd.org/find-a-provider/
* https://acogpresident.files.wordpress.com/2013/03/districtmapupdated.jpg?w=608
* http://www.exploratory.io, Sign up for student version
* https://www.jessesadler.com/post/geocoding-with-r/
* https://console.cloud.google.com/google/maps-apis/overview?pli=1
* https://learn.r-journalism.com/en/mapping/geolocating/geolocating/

## Installation and use
These are scripts to pull and prepare data. This is an active project and scripts will change, so please always update to the latest version.

```r
# Set libPaths.
.libPaths("/Users/tylermuffly/.exploratory/R/4.0")

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

# Steps to produce Crosswalk_ACOG_Districts
`Crosswalk_ACOG_Districts` <- exploratory::read_delim_file("/Users/tylermuffly/Dropbox (Personal)/Mystery shopper/Crosswalk_ACOG_Districts.csv" , ",", quote = "\"", skip = 0 , col_names = TRUE , na = c('','NA') , locale=readr::locale(encoding = "UTF-8", decimal_mark = ".", tz = "America/Denver", grouping_mark = "," ), trim_ws = TRUE , progress = FALSE) %>%
  readr::type_convert() %>%
  exploratory::clean_data_frame() %>%
  mutate(State_Abbreviations = factor(State_Abbreviations))
```


# Steps to produce the output
```r
exploratory::read_delim_file("https://www.dropbox.com/s/81s4sfltiqwymq1/Downloaded%20%289035315-9050954%29%20%282019-08-13%2022.csv?raw=1" , ",", quote = "\"", skip = 0 , col_names = TRUE , na = c('','NA') , locale=readr::locale(encoding = "UTF-8", decimal_mark = ".", tz = "America/Denver", grouping_mark = "," ), trim_ws = TRUE , progress = FALSE) %>%
  readr::type_convert() %>%
  exploratory::clean_data_frame() %>%
  bind_rows(a2, a3, a4, a5, a6, a7, a8, a9, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32, a33, a34, a35, a36, a37, a38, a39, a40, a41, a42, a43, a44, a45, a46, a47, a48, a49, a50, a51, a52, a53, a55, a56, a59, a60, a61, a62, a63, a64, a65, a66, b1, b2, b3, b4, b5, c1, d1, d2, Physicians_970434_940841_2020_07_25_19_08_57, Physicians_961459_940841_2020_07_25_21_23_45, Physicians_953100_940841_2020_07_26_10_13_00, Physicians_940841_930841_2020_07_26_16_43_50, Physicians_940841_930841_2020_07_26_16_43_50_1, Physicians_940841_1_2020_07_27_07_32_01, Physicians_930207_9e_05_2020_07_27_13_27_18, Physicians_918005_907225_2020_07_27_19_18_17, Physicians_905914_904000_2020_07_27_20_19_46, Physicians_906000_904000_2020_07_27_19_17_05, Physicians_918005_907225_2020_07_27_18_05_25, Physicians_918005_907225_2020_07_27_19_18_17_1, Physicians_9e_05_926360_2020_07_27_16_52_16, Physicians_917084_907225_2020_07_28_07_14_32, Physicians_905914_904000_2020_07_27_23_39_44, Physicians_917084_907225_2020_07_28_07_14_32_1, Physicians_905914_904000_2020_07_27_23_39_44_1, force_data_type = TRUE) %>%
  mutate(sub1 = recode(sub1, FPM = "Female Pelvic Medicine & Reconstructive Surgery", `Female Pelvic Medicine & Reconstructive Surgery` = "Female Pelvic Medicine & Reconstructive Surgery", PAG = "Pediatric & Adolescent Gynecology", MFM = "Maternal-Fetal Medicine", `Gynecologic Oncology` = "Gynecologic Oncology", ONC = "Gynecologic Oncology", REI = "Reproductive Endocrinology and Infertility", HPM = "Hospice and Palliative Medicine", CRI = "Gynecologic Oncology")) %>%
  group_by(userid) %>%
  fill(everything(), .direction = "down") %>%
  fill(everything(), .direction = "up") %>%
  slice(1) %>%
  distinct(userid, .keep_all = TRUE) %>%
  select(userid, name, city, state, startDate, certStatus, mocStatus, sub1, sub1startDate, sub1certStatus, sub1mocStatus, sub2certStatus, clinicallyActive, orig_sub, orig_bas) %>%
  filter(sub1certStatus %nin% c("Retired")) %>%
  filter(sub1certStatus %nin% c("Retired") & state %nin% c("ON", "AB", "AP", "BC", "GU", "HR", "MB", "NB", "NL", "NS", "OT", "PU", "QC", "VI", "SK")) %>%
  mutate_at(vars(startDate, sub1startDate, orig_sub, orig_bas), funs(year)) %>%
  filter(sub1 %nin% c("Generalist", "Hospice and Palliative Medicine", "Pediatric & Adolescent Gynecology")) %>%
  distinct(userid, .keep_all = TRUE) %>%
  filter((is.na(name) | name != "TESTING IDS TESTING IDS")) %>%
  ungroup() %>%
  filter(certStatus %nin% c("Not Certified", "Not Currently Certified", "Approved with Annual Compliance Diplomate", "Deceased Diplomate", "Ineligible Diplomate", "Probationary", "Probationary Diplomate", "Retired Diplomate") & !is.na(certStatus) & !is.na(sub1)) %>%
  separate(name, into = c("full_name", "suffix"), sep = "\\s*\\,\\s*", remove = FALSE, convert = TRUE) %>%
  mutate(first_name = word(full_name, 1, sep = "\\s+"), last_name = word(full_name, -1, sep = "\\s+")) %>%
  rename(Board_certification_year = orig_sub) %>%
  mutate(state = factor(state)) %>%
  left_join(Crosswalk_ACOG_Districts, by = c("state" = "State_Abbreviations"), ignorecase=TRUE) %>%
  select(-certStatus, -mocStatus, -State) %>%
  filter((is.na(sub2certStatus) | sub2certStatus != "Retired") & clinicallyActive %nin% c("No")) %>%
  filter(!is.na(ACOG_District_of_medical_school)) %>%
  filter(!is.na(state)) %>%
  mutate(startDate_category = cut(startDate, breaks = 3, dig.lab = 10)) %>%
  group_by(sub1, state, startDate_category) %>%
  sample_rows(1, seed = 1234546) %>%
  arrange(state) %>%
  select(-startDate, -sub1startDate, -sub1certStatus, -sub1mocStatus, -sub2certStatus, -clinicallyActive) %>%
  select(-Board_certification_year, -orig_bas) %>%
  ungroup() %>%
  mutate(website_to_search = recode(sub1, `Female Pelvic Medicine & Reconstructive Surgery` = "https://www.voicesforpfd.org/find-a-provider/", `Maternal-Fetal Medicine` = "https://www.smfm.org/members/search?page=1", `Reproductive Endocrinology and Infertility` = "https://www.reproductivefacts.org/resources/find-a-health-professional/"), Instructions = recode(sub1, `Female Pelvic Medicine & Reconstructive Surgery` = "Surf to URL and \"enter first name\" and \"enter last name\" then hit the red \"Search\" button at the bottom.  ", `Reproductive Endocrinology and Infertility` = "Surf to the URL and enter the first name and last name in each of those fields then hit the greay \"Search\" button.  Click on the name to see details.  ", `Maternal-Fetal Medicine` = "Surf to the URL and you need to manually hit \"Next\" button to scroll through the results.  ")) 
```

### Get scripts into a new RStudio project:
`New Project - Version Control - Git -` https://github.com/mufflyt/mystery_shopper.git as `Repository URL`
(Our use your preferred way of cloning/downloading from GitHub.)

# Codebook
A codebook is a technical description of the data that was collected for a particular purpose. It describes how the data are arranged in the computer file or files, what the various numbers and letters mean, and any special instructions on how to use the data properly.

* Predictors under consideration:
1. `Exclusions` - Individual fields for exclusion and inclusion.  Exclusions are: Greater than five minutes on hold, Not in the USA, Schedule not available to make appointment, Busy Signal, Phone number to FPMRS physician's personal cell phone number, Registration required, Phone number disconnected, Closed for vacation, Integrated medical system, Military patients only, Requires referral, Required to see urogyn nurse practicioner before seeing FPMRS physician, Answered by Voicemail.  
2. `Business days until appointment` - I used the bizdays package in R to do this.  
3. `Insurance type asked before offering appointment` - "He sees those patients on Mondays"
4. `Gender of first available female pelvic medicine and reconstructive surgeon` - Male or Female, 2 level categorical
5. `Accept Medicare` - PArticipating in Medicare
6. `Number of transfers`  
7. `Hold Time (min)` 
8. `Central number` - Centralized scheduling?
9. `Length of call (min)`
10. `Clinic`
11. `First Available FPMRS Physician`- Name of FPMRS physician
12. `Date called`
13. `Appt date` 
14. `Able to contact`
15. `Zip code`
16. `state.x` - numerical variable
17. `latitude.y` 
18. `longitude.y`
19.  `County`
20.  `Rurality`
21.  `Median` - Median household income
22.  `Business Days Until Appointment` - Categorical
23.  `American Congress of Obstetricians and Gynecologists District` - See map link above

[![ACOG district map](https://acogpresident.files.wordpress.com/2013/03/districtmapupdated.jpg?w=608)](https://acogpresident.files.wordpress.com/2013/03/districtmapupdated.jpg?w=608) 

* [See crosswalk between states and ACOG districts](https://github.com/mufflyt/coi/blob/dev_01/Reference_Data/Crosswalk_ACOG_Districts.csv),  A way to look at large areas of the US that are geographically close.  

This data was cleaned with the help of exploratory.io. The script is present in github called: mystery_shopper.R.  Due to COVID-19 I was unable to meet with my resident to do the analysis sitting together.  Therefore I made several screencasts to describe the process.  The videos are in a playlist on my YouTube channel.  


# `table one.R`
Creates a table 1 of demographics using the incredible arsenal::tableby package.  I tried to tune the table to the standards of Obstetrics & Gynecology but still had to do quite a bit by hand.  It would be nice if there was a +/- sign for standard deviation and the ability to drop one level in the table (e.g. only keep female and not male).  

# `script from exploratory to clean the data.R`
Does what it says.  

# `correct_lat_long`
I had this from a separate project that I had done.  Next I geocoded the street address, city, state of each FPMRS into lat and long using the Google geocoding API.  Zip codes were challenging to use and the street address, city, state information was accurate without zip codes.  Any non-matches were omitted.  These data were written to a file called locations.csv.  Many thanks to Jesse Adler for the great code.  I need to put google key.  

[![Geocoding, how does it work](https://geospatialmedia.s3.amazonaws.com/wp-content/uploads/2018/05/geocoding-graph.jpg)](https://geospatialmedia.s3.amazonaws.com/wp-content/uploads/2018/05/geocoding-graph.jpg) 

[![Zip codes, how does it work](https://www.unitedstateszipcodes.org/images/zip-codes/zip-codes.png)](https://www.unitedstateszipcodes.org/images/zip-codes/zip-codes.png) 

# Geocoding using Google
```r
# Google geocoding of FPMRS physician locations ----
#Google map API, https://console.cloud.google.com/google/maps-apis/overview?pli=1

#Allows us to map the FPMRS to street address, city, state
library(ggmap)
gc(verbose = FALSE)
ggmap::register_google(key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
ggmap::ggmap_show_api_key()
ggmap::has_google_key()
colnames(full_list)

View(full_list$place_city_state)
dim(full_list)
sum(is.na(full_list$place_city_state))

locations_df <- ggmap::mutate_geocode(data = full_list, location = place_city_state, output="more", source="google")
locations <- tibble::as_tibble(locations_df) %>%
   tidyr::separate(place_city_state, into = c("city", "state"), sep = "\\s*\\,\\s*", convert = TRUE) %>%
   dplyr::mutate(state = statecode(state, output_type = "name"))
 colnames(locations)
 write_csv(locations, "/Users/tylermuffly/Dropbox/workforce/Rui_Project/locations.csv")
locations <- readr::read_csv("/Users/tylermuffly/Dropbox/workforce/Rui_Project/locations.csv")

head(locations)
dim(locations)  #See how many FPMRS offices you lost when could not be geocoded.
View(locations)
```

The mailing list will be kept on the RedCAP database.  

RedCAP database is used to store the data and enter it in real-time.  
https://redcap.ucdenver.edu/redcap_v9.5.23/index.php?pid=17708

The study was written using the STROBE checklist:
https://www.strobe-statement.org/index.php?id=available-checklists


Reference
==========
* https://www.merritthawkins.com/uploadedFiles/MerrittHawkins/Content/Pdf/MerrittHawkins_PhysiciansFoundation_Survey2018.pdf, Merritt-Hawkins Physicians Foundation Survey

Society Pages
==========
* https://web.archive.org/web/20070701222152/http://www.wcn.org/interior.cfm?diseaseid=13&featureid=4
* http://asrm.org
* https://www.smfm.org/members/search
* http://voicesforpfd.org

Get at least one person to call for each subspecialty.  Medical students?  All should probably be women or men.  Do an elective with Muffly in December to make the phone calls.  Able to work from home with the redcap database and a telephone.  Scenarios would be: 4 cm simple cyst, infertility, prior CHTN, and SUI.  

# How to pick physicians to call based off nomogram code
```r
dplyr::group_by(Match_Status, white_non_white, Gender) %>%  #selected equal numbers of people with various match_status, white_non_white, and genders.  
  exploratory::sample_rows(1) %>%
  as_tibble()
```

# Use of Mechanical Turk to get phone numbers from society web pages (Kati and Muffly Search for Physician Phone Numbers)
```r
<!-- You must include this JavaScript file -->
<script src="https://assets.crowd.aws/crowd-html-elements.js"></script>

<!-- For the full list of available Crowd HTML Elements and their input/output documentation,
      please refer to https://docs.aws.amazon.com/sagemaker/latest/dg/sms-ui-template-reference.html 
      
      
      Kati_Turner_calling_study
      TYLER THIS WOULD BE YOUR INPUT FILE
      
      
      -->

<!-- You must include crowd-form so that your task submits answers to MTurk -->
<crowd-form answer-format="flatten-objects">

  <p>
    Please search for this OBGYN physician first name, last name at this url:
    </p>
    
    <strong>  
      <p>    
        Website to Search: ${website_to_search}
      </strong>  
      </p>
    
    <strong>  
      <p>    
        Instructions: ${Instructions}
      </strong>  
      </p>

    <strong>

        <!-- The residency name you want researched when you publish a batch with a CSV input file containing multiple companies  -->
        <p>
        First name: ${first_name}  
          </p>
    
      <strong>  
      <p>    
        Last name: ${last_name}
      </strong>  
      </p>

    <strong>
        <p>
       State: ${state}
      </strong>  
      </p>
      
        </p>
    <p>
  
      </strong>  
      </p>
      
    <p>
        
    </p>
 <div>
     
                     <p><strong>Please copy and paste the ten digit phone number:</strong></p>
<p><crowd-input name="Phone_number" placeholder="please copy and paste phone number, (example: 555-234-5678)" ></crowd-input></p>

                <p><strong>Please copy and paste the first and the last name from the "Name" field:</strong></p>
<p><crowd-input name="physician_name" placeholder="please copy and paste the name, (NAME EXAMPLE)" required></crowd-input> </p>

                <p><strong>Please copy and paste the street address:</strong></p>
<p><crowd-input name="address" placeholder="please copy and paste state, (example: 777 Bannock Street)" ></crowd-input></p>

                <p><strong>Please copy and paste the city:</strong></p>
<p><crowd-input name="city" placeholder="please copy and paste state, (example: Anchorage)" ></crowd-input></p>

                <p><strong>Please copy and paste the state:</strong></p>
<p><crowd-input name="State" placeholder="please copy and paste state, (example: AK)" ></crowd-input></p>

                <p><strong>Please copy and paste the five-digit zip code:</strong></p>
<p><crowd-input name="zip" placeholder="please copy and paste zip, (example: 90210)" ></crowd-input></p>

<p><crowd-input name="comments" placeholder="Any comments or suggestions." ></crowd-input> </p>
    <p>
        Thank you!  
    </p>

            </div>
```
# Search for NPI related to physicians (Kati and Muffly Search for NPI number)
```r
<!-- You must include this JavaScript file -->
<script src="https://assets.crowd.aws/crowd-html-elements.js"></script>

<!-- For the full list of available Crowd HTML Elements and their input/output documentation,
      please refer to https://docs.aws.amazon.com/sagemaker/latest/dg/sms-ui-template-reference.html 
      
      
      merged_mturk_residencies_for_medical_school_search_on_mturk
      TYLER THIS WOULD BE YOUR INPUT FILE
      
      
      -->

<!-- You must include crowd-form so that your task submits answers to MTurk -->
<crowd-form answer-format="flatten-objects">

  <p>
    Please search for this OBGYN physician first name, last name, and state at this url:
    "https://npiregistry.cms.hhs.gov/registry/?" :

    <strong>

        <!-- The residency name you want researched when you publish a batch with a CSV input file containing multiple companies  -->
        <p>
        First name: ${first_name}  
          </p>
    
      <strong>  
      <p>    
        Last name: ${last_name}
      </strong>  
      </p>

    <strong>
        <p>
       State: ${state}
      </strong>  
      </p>
      
        </p>
    <p>
  
      </strong>  
      </p>
      
    <p>
        
    </p>
 <div>
     
                     <p><strong>Pick the top result.  Please copy and paste the ten digit "NPI number":</strong></p>
<p><crowd-input name="NPI" placeholder="please copy and paste NPI number, (example: 1234567899)" ></crowd-input></p>

                <p><strong>Please copy and paste the first and the last name from the "Name" field:</strong></p>
<p><crowd-input name="physician_name" placeholder="please copy and paste the name, (NAME EXAMPLE)" required></crowd-input> </p>

                <p><strong>Please copy and paste the state from the "Primary Practice Address":</strong></p>
<p><crowd-input name="State" placeholder="please copy and paste state, (example: CO)" ></crowd-input></p>

                <p><strong>Please copy and paste the taxonomy code from the "Primary Taxonomy":</strong></p>
<p><crowd-input name="Taxonomy" placeholder="please copy and paste taxonomy, (example: Obstetrics and Gynecology)" ></crowd-input></p>

<p><crowd-input name="comments" placeholder="Any comments or suggestions." ></crowd-input> </p>
    <p>
        Thank you!  
    </p>

            </div>
```

Abstract
==========
OBJECTIVE:  To evaluate the mean appointment wait time for a new patient visit at outpatient female pelvic medicine and reconstructive surgery offices for US women with the common and non-emergent complaint of uterine prolapse.
 
METHODS:  The American Urogynecologic Society “Find a Provider” tool was used to generate a list of female pelvic medicine and reconstructive surgery (FPMRS) offices across the United States.  Each of the 427 unique listed offices was called. The caller asked for the soonest appointment available for her mother, who was recently diagnosed with uterine prolapse.  Data for each office were collected including date of soonest appointment, FPMRS physician demographics, and office demographics.  Mean appointment wait time was calculated.  
 
RESULTS:  Four hundred twenty-seven FPMRS offices were called in 46 states plus the District of Columbia.  The mean appointment wait time was 23.1 business days for an appointment (standard deviation 19 business days).  The appointment wait time was six days longer when seeing a female FPMRS physician compared to a male FPMRS physician (mean 26 vs. 20 business days, p<0.02).  There was no difference in wait time by day of the week called. 
 
CONCLUSION:  Typically, a woman with uterine prolapse can expect to wait at least four weeks for a new patient appointment with an FPMRS board certified physician listed on the American Urogynecologic Society website.  First available appointment is more often with a male physician.  A patient can expect to wait six days longer to see a female FPMRS physician.   


We wrote the paper on GoogleDocs.  https://docs.google.com/document/d/1rg6Mf4ZHYE5o3s4v1CIz-KRAm7NSHbDIPWPyU3ezaws/edit?usp=sharing
GoogleDocs and Endnote do not play well together.  Therefore we used Endnote for references once the final product was exported into Microsoft Word.  I have an endnote x8 group called `MysteryCallerStudy` in the `gethispainthingdone.enlp` library.  I found the easiest way to use endnote was to click on the Online Search --> PubMed(NLM) and search for the articles that way.  Then I could pull the reference into the Word document.  
