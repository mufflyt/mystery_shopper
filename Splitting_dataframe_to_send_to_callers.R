#Split the final graph.  
#I have a dataframe of 1224 rows.  I want to keep the file in the order it is in now.   I need to split it eight ways and then send a CSV of each split to a person.  What do you recommend?

library(tidyverse)
library(dplyr)
library(readr)
library(openxlsx)

# Load your data
sample_data <- read_csv("/Users/tylermuffly/Dropbox (Personal)/Mystery shopper/mystery_shopper/Corbi study/ENT/For_each_caller/for_each_caller.csv")

# Split the data into 8 parts
splits <- split(sample_data, cut(seq_len(nrow(sample_data)), 8, labels = c("Sophie", "Yasmine", "mie242", "nhg2112", "Madeline", "Drew", "Elizabeth", "Michaele")))

# Save each split to a separate CSV file
output_directory <- "/Users/tylermuffly/Dropbox (Personal)/Mystery shopper/mystery_shopper/Corbi study/ENT/For_each_caller"

for (name in names(splits)) {
  first_row_id <- splits[[name]]$id[1]
  last_row_id <- splits[[name]]$id[nrow(splits[[name]])]
  output_file <- paste0(output_directory, "/", name, "_", Sys.Date(), "_", nrow(splits[[name]]), "_rows_", first_row_id, "_to_", last_row_id, ".xlsx")
  write.xlsx(splits[[name]], output_file)
}

