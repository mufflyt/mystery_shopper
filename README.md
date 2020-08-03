# Appointment Wait Times in Female Pelvic Medicine and Reconstructive Surgery: A Mystery Caller Study
Rabice, Schultz, Muffly

*Objective:  *
*To evaluate the mean appointment wait time for a new patient visit at outpatient female pelvic medicine and reconstructive surgery offices for US women with the common and non-emergent complaint of uterine prolapse.*

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
