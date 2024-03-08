




library(tidyverse)
library(RSocrata)
# ------------------------------------------------------------------------------
# List all of the data.nola.gov public safety sources
NOLA_list <- ls.socrata("https://data.nola.gov/")
# ------------------------------------------------------------------------------
# Pull the list of datasets that have the keyword associated with them.
Complaint_list <- NOLA_list[which(NOLA_list$title == "311 OPCD Calls (2012-Present)"), c("identifier", "title")]
# ------------------------------------------------------------------------------
# Generates latitude and longitude for each type of accomodation:
Complaints <- read.socrata(Complaint_list[["identifier"]][1]) # %>%
  # mutate(latitude = latlong(Location)$latitude,
  #        longitude = latlong(Location)$longitude) %>% select(-Location)


