#############################################
# Load necessary packages
#devtools::install_github("ropensci/npi")
library(npi)
library(tidyverse)
library(memoise)
library(humaniformat)

# Define a memoised version of the npi_search function
# Define the cache file system
gc()
fc <- cache_filesystem(file.path(".cache"))
npi_search_memo <- memoise(npi_search, cache = fc)

#This came from Bart's scrape of the OTO-HNS web site on 4/3/2023
df_ENT <- readxl::read_xlsx("/Users/tylermuffly/Dropbox (Personal)/Mystery shopper/mystery_shopper/Corbi study/ENT/Data/results.xlsx") %>%
  mutate(first = humaniformat::first_name(full_name)) %>%
  mutate(last= humaniformat::last_name(full_name)) %>%
  filter(country == "United States") %>%
  mutate(last = str_remove_all(last, "[^[:alnum:]]")) %>% #remove special characters
  na.omit(first) %>%
  na.omit(last)
glimpse(df_ENT)

df <- df_ENT
#df <- df[10:20, ] #only for testing

# Define input data from df
first_names <- df$first
last_names <- df$last

# Create empty list to store search results
out <- list()

# Loop over each name pair and search for NPI number
for (i in 1:length(first_names)) {
  tryCatch({
    out[[i]] <- npi_search(first_name = first_names[i], 
                           last_name = last_names[i], 
                           enumeration_type = "ind", # we could have matched by state as well but may be too specific
                           limit = 10)
  }, error = function(e) {
    message(sprintf("Error in row %s: %s %s\n%s", i, first_names[i], last_names[i], e$message))
    #Sys.sleep(10)
  })
}

# Combine search results into a single data frame
out <- do.call(rbind, out)

# Print search results
data <- npi_flatten(out) %>% #unnests all the NPI data
  distinct(npi, .keep_all = TRUE) %>% #keeps only the distinct/non-duplicated npi numbers
  filter(addresses_country_name == "United States") %>% #only keeps the US people
  mutate(basic_credential = str_remove_all(basic_credential, "[[\\p{P}][\\p{S}]]")) %>% #removes "special characters" that were causing problems.  
  filter(str_to_lower(basic_credential) %in% str_to_lower(c("MD", "DO"))) %>% #Filters out all non-MD and non-DO people to get a cleaner list
  arrange(basic_last_name) %>%

# add a column to the data dataframe that matches the first and last names in the df dataframe
########## data <- data %>% 
  mutate(full_name = paste(str_to_lower(basic_first_name), str_to_lower(basic_last_name)))

# join the data dataframe with the df dataframe, bring in the original data
result <- df %>%  ##This came from Bart's scrape of the OTO-HNS web site on 4/3/2023
  mutate(full_name = paste(str_to_lower(first), str_to_lower(last))) %>% 
  left_join(data, by = "full_name", multiple = "all") #%>%
  #rename_with(~paste0("original.df.", .), -matches("full_name|npi"))

result$npi <-  ifelse(is.na(result$npi), "NO MATCH FOUND", result$npi)

sum(result$npi == "NO MATCH FOUND")
paste0("Percentage of NO MATCH FOUND:  ", round((sum(result$npi == "NO MATCH FOUND")/nrow(result))*100, digits = 1), "%")

result <- result %>%
  filter(npi != "NO MATCH FOUND") %>%
  filter(str_detect(taxonomies_desc, regex("oto|plastic|sleep", ignore_case=TRUE))) %>%
  distinct(npi, .keep_all = TRUE) %>%
  select(url, full_name, company_name, address, city, state_code, post_code, country, phone_number, specialty_primary, specialty_secondary, first, last, npi, basic_first_name, basic_last_name, basic_credential, basic_sole_proprietor, basic_gender, basic_enumeration_date, basic_last_updated, basic_status, basic_name_prefix, basic_name_suffix, basic_certification_date, basic_middle_name) %>%
  distinct(url, .keep_all = TRUE) %>%
  select(-country, -basic_status, -basic_name_prefix, -basic_name_suffix, -basic_certification_date, -basic_middle_name) %>%
  mutate(basic_credential = str_to_upper(basic_credential)) %>%
  mutate(across(c(basic_enumeration_date, basic_last_updated), year)) #%>%
  
### Cleans data
  # No npi number found.
  filter(npi != "NO MATCH FOUND") %>%
  
  # Filter out the non-OTO-HNS people like family medicine, etc.  
  filter(str_detect(taxonomies_desc, regex("oto|plastic|sleep", ignore_case=TRUE))) %>%
  
  # Only one NPI number per person
  distinct(npi, .keep_all = TRUE) %>%
  
  # Select the needed columns.
  select(url, full_name, company_name, address, city, state_code, post_code, country, phone_number, specialty_primary, specialty_secondary, first, last, npi, basic_first_name, basic_last_name, basic_credential, basic_sole_proprietor, basic_gender, basic_enumeration_date, basic_last_updated, basic_status, basic_name_prefix, basic_name_suffix, basic_certification_date, basic_middle_name) %>%
  
  # Remove duplicated URLs.  
  distinct(url, .keep_all = TRUE) %>%
  select(-country, -basic_status, -basic_name_prefix, -basic_name_suffix, -basic_certification_date, -basic_middle_name) %>%
  
  # Clean up credentials so MD and M.D. are the same.  
  mutate(basic_credential = str_to_upper(basic_credential)) %>%
  
  # Pull out the year from date columns.  
  mutate(across(c(basic_enumeration_date, basic_last_updated), year)) %>%
  
  # Select only the needed subspecialties.  
  filter(specialty_primary %in% c("Facial Plastic and Reconstructive Surgery", "Head and Neck Surgery", "Laryngology", "Neurotology", "Otology/Audiology", "Pediatric Otolaryngology")) %>%
  arrange(full_name) %>%
  
  # Clean up the extra spaces, etc for company name
  mutate(across(c(company_name, address), str_clean)) %>%
  
  # Remove "Ste" or "Suite" from the address so it is easier to geocode.  
  mutate(address = str_remove_after(address, "\\bSte\\b")) %>%
  mutate(post_code = str_remove_after(post_code, sep = "\\-"))


readr::write_csv(result, "/Users/tylermuffly/Dropbox (Personal)/Mystery shopper/mystery_shopper/Corbi study/ENT/result.csv")
invisible(gc())
