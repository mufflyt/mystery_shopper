# Appointment Wait Times in Female Pelvic Medicine and Reconstructive Surgery: A Mystery Caller Study
Rabice, Schultz, Muffly

*Objective:  *
*To evaluate the mean appointment wait time for a new patient visit at outpatient female pelvic medicine and reconstructive surgery offices for US women with the common and non-emergent complaint of uterine prolapse.*

Data Sources 
==========
* https://www.psc.isr.umich.edu/dis/census/Features/tract2zip/, Geographic Correspondence Engine at Missouri Census Data Center
* http://mcdc.missouri.edu/applications/geocorr2018.html
* https://www.voicesforpfd.org/find-a-provider/
* https://acogpresident.files.wordpress.com/2013/03/districtmapupdated.jpg?w=608
* http://www.exploratory.io
* https://www.jessesadler.com/post/geocoding-with-r/
* https://console.cloud.google.com/google/maps-apis/overview?pli=1

## Installation and use
These are scripts to pull and prepare data. This is an active project and scripts will change, so please always update to the latest version.

```r
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

This data was cleaned with the help of exploratory.io. The script is present in github called: mystery_shopper.R.  

# `myster_shopper.R`
Mainly a ton of data cleaning because we didn't have our database set up properly from the very start.  

# `table one.R`
Creates a table 1 of demographics using the incredible arsenal::tableby package.  I tried to tune the table to the standards of Obstetrics & Gynecology but still had to do quite a bit by hand.  It would be nice if there was a +/- sign for standard deviation and the ability to drop one level in the table (e.g. only keep female and not male).  

# `script from exploratory to clean the data.R`
Does what it says.  

# `correct_lat_long`
I had this from a separate project that I had done.  Next I geocoded the street address, city, state of each FPMRS into lat and long using the Google geocoding API.  Zip codes were challenging to use and the street address, city, state information was accurate without zip codes.  Any non-matches were omitted.  These data were written to a file called locations.csv.  Many thanks to Jesse Adler for the great code.  I need to put google key.  

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

Abstract
==========
OBJECTIVE:  To evaluate the mean appointment wait time for a new patient visit at outpatient female pelvic medicine and reconstructive surgery offices for US women with the common and non-emergent complaint of uterine prolapse.
 
METHODS:  The American Urogynecologic Society “Find a Provider” tool was used to generate a list of female pelvic medicine and reconstructive surgery (FPMRS) offices across the United States.  Each of the 427 unique listed offices was called. The caller asked for the soonest appointment available for her mother, who was recently diagnosed with uterine prolapse.  Data for each office were collected including date of soonest appointment, FPMRS physician demographics, and office demographics.  Mean appointment wait time was calculated.  
 
RESULTS:  Four hundred twenty-seven FPMRS offices were called in 46 states plus the District of Columbia.  The mean appointment wait time was 23.1 business days for an appointment (standard deviation 19 business days).  The appointment wait time was six days longer when seeing a female FPMRS physician compared to a male FPMRS physician (mean 26 vs. 20 business days, p<0.02).  There was no difference in wait time by day of the week called. 
 
CONCLUSION:  Typically, a woman with uterine prolapse can expect to wait at least four weeks for a new patient appointment with an FPMRS board certified physician listed on the American Urogynecologic Society website.  First available appointment is more often with a male physician.  A patient can expect to wait six days longer to see a female FPMRS physician.   


We wrote the paper on GoogleDocs.  https://docs.google.com/document/d/1rg6Mf4ZHYE5o3s4v1CIz-KRAm7NSHbDIPWPyU3ezaws/edit?usp=sharing
GoogleDocs and Endnote do not play well together.  Therefore we used Endnote for references once the final product was exported into Microsoft Word.  I have an endnote x8 group called `MysteryCallerStudy`.  

The mailing list was kept on Google Sheets.  
The data was not sensitive so it was kept on Dropbox.  

Some results from Wait Times by Individual Female Pelvic Medicine and Reconstructive Surgery Office
* https://exploratory.io/viz/8171776323392484/Dot-map-VQG6RIQ9cT
* https://exploratory.io/viz/8171776323392484/Included-only-map-bZN1KRg1sh


RedCAP database is used to store the data and enter it in real-time.  
https://redcap.ucdenver.edu/redcap_v9.5.23/index.php?pid=17708

The study was written using the STROBE checklist:
https://www.strobe-statement.org/index.php?id=available-checklists
