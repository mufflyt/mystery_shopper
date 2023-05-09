# From Bartosz via upwork on 4/4/2023.  Scrapes the web site: https://www.enthealth.org/find-ent/.  Scrapes a wordpress PHP directory site.  Teh GET request isbuilt as: https://www.enthealth.org/find-ent/traci-bailey/page/44/?action=find_ent_response&_ent_nonce=60c020aee6&radiuszip&distance&lname&city&state&country=United%20States&specialty&ajaxrequest=true&submit=Submit%20Form.  

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
use_cached_data = TRUE  # don't remove temporary data
country = "United States"
output_file_name = "results.xlsx"  # path to final file

# Definition of variables and functions -----------------------------------
temp_search_results = "temp_1.xlsx"
temp_search_individuals = "temp_2.xlsx"

# Session ID
ent <- 'https://www.enthealth.org/find-ent/' %>%   # Create a variable "ent" and assign it the value of the URL to scrape
  session() %>%   # Start a new session to the website using the "session()" function
  html_node('input[name="_ent_nonce"]') %>%   # Select an HTML input element with the name "_ent_nonce" using the "html_node()" function
  html_attr("value")   # Retrieve the value of the "value" attribute of the selected HTML element using the "html_attr()" function


##########################
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

##########################
set_body <- function(page_number) {   # Define a function called "set_body" that takes one argument, "page_number"
 #Create a string variable "body" that contains several parameters for an HTTP POST request
  body = paste0('action=find_ent_response&_ent_nonce=', ent, '&paged=', page_number, '&radiuszip=&distance=&lname=&city=&state=&country=', country, '&specialty=&ajaxrequest=true&submit=Submit+Form')
  
  return(body)   # Return the "body" string from the function
}

##########################
html_text_na <- function(x, ...) {   # Define a function called "html_text_na" that takes one argument, "x", and additional arguments
  
  txt <- try(html_text(x, ...))   # Assign the result of calling "html_text(x, ...)" to "txt". The "try" function is used to handle any errors that may occur during the call.
  
  # Check if the "txt" object is a try-error OR if it has length zero. If so, return "NA".
  if (inherits(txt, "try-error") | (length(txt) == 0)) { 
    return(NA) 
  }
  
  return(txt)   # Otherwise, return the "txt" object
}



##########################
# Search page navigation
search <- function(page_number) {   # Define a function called "search" that takes one argument, "page_number"
  
  # Send an HTTP POST request to the "base_url" with the given headers and body
  r = httr::POST(base_url, add_headers(headers), body = set_body(page_number), encode = "json")
  
  # Parse the response content as JSON and extract the HTML results
  s <- content(r, 'text') %>% fromJSON()   # Parse the response content as JSON using the "fromJSON" function from the "jsonlite" package
  results <- s$results_html %>% read_html   # Extract the HTML results from the "s" object and parse them using the "read_html" function from the "rvest" package
  
  # Extract the URLs to individual listings
  # Filter the results by the United States
  results %<>% html_nodes('.result')   # Use the "html_nodes" function from the "rvest" package to select all HTML elements with the class "result"
  urls <- c()   # Initialize an empty vector "urls"
  for (result in results) {   # Loop over each "result" HTML element
    is_us <- result %>%  
      html_node('.address') %>%   # Select the HTML element with the class "address"
      html_text_na() %>%   # Extract the text content of the HTML element and replace any missing values with "NA" using the "html_text_na" function defined elsewhere
      stri_detect_regex(country) %>%   # Use the "stri_detect_regex" function from the "stringi" package to check if the text content contains the value of the "country" variable
      {ifelse(is.na(.), TRUE, .)}   # Replace any missing values with "TRUE" using the "ifelse" function
    if (is_us) {   # If the "is_us" variable is "TRUE"
      urls %<>% c(   
        result %>%   # The "result" HTML element
          html_nodes('a') %>%   # All HTML elements with the tag "a" that are descendants of the "result" element
          html_attr("href") %>%   # The value of the "href" attribute of each of the "a" elements
          paste0('https://www.enthealth.org', .) %>%   # Prepend the domain name to each URL using the "paste0" function
          stri_trans_general(id = "Latin-ASCII") %>%   # Use the "stri_trans_general" function from the "stringi" package to transliterate any non-ASCII characters in the URL
          stri_split_fixed('?') %>%   # Use the "stri_split_fixed" function to split the URL at the first occurrence of the "?" character
          extract2(1) %>% extract(1)   # Extract the first element of the resulting list and the first element of that vector
      )
    }
  }
  

##########################    
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

##########################
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
    "phone_number" = s %>% html_nodes(".phone") %>% html_text_na()
  )
  
  return(result)
}

##########################
do_search <- function() {
  print(paste0('Get all URLs from search page - filtered by ', country))
  page_numbers <- search(1)$page_numbers
  search_results <- pbapply::pblapply(1:page_numbers, search)
  urls <- unlist(lapply(search_results, function(x) {x$urls}))
  print(paste0('Save temporary data to ', temp_search_results))
  df <- data.frame(list("urls" = urls))
  df %>% write.xlsx(temp_search_results, row.names = FALSE)
}

##########################
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
  print(paste0('Save temporary data to ', temp_search_results))
  data = do.call(rbind.data.frame, results)
  data %<>% rbind(results_cached)
  data %>% write.xlsx(temp_search_individuals, row.names = FALSE)
}

##########################
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
