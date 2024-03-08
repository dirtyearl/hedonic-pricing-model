




library(tidyverse)
library(RSocrata)
# ------------------------------------------------------------------------------
# List all of the data.nola.gov public safety sources
NOLA_list <- ls.socrata("https://data.nola.gov/")
# ------------------------------------------------------------------------------
# Function to match a vector of keywords to match any instance of a particular
# keyword.
AirBnB_match <- function(.) any(unlist(.) %in% c("hotel", "short-term rentals", "str", "motel", "b&b"))
# ------------------------------------------------------------------------------
# Pull the list of datasets that have the keyword associated with them.
AirBnB_list <- NOLA_list[which(as.logical(lapply(NOLA_list$keyword,
                                              FUN = AirBnB_match))), c("identifier", "title")]
# ------------------------------------------------------------------------------
# Function to separate the latitude and longitude:
latlong <- function(.data) {
  xy <- str_split(.data, " ") %>% lapply(parse_number)
  list(latitude = lapply(xy, function(.) .[1]),
       longitude = lapply(xy, function(.) .[2]))
  
}
# ------------------------------------------------------------------------------
# Generates latitude and longitude for each type of accomodation:
STR_License <- read.socrata(AirBnB_list[["identifier"]][1]) %>%
  mutate(latitude = latlong(Location)$latitude,
         longitude = latlong(Location)$longitude) %>% select(-Location)

Hotels_Motels <- read.socrata(AirBnB_list[["identifier"]][2]) %>% 
  mutate(latitude = latlong(Location)$latitude,
         longitude = latlong(Location)$longitude) %>% select(-Location)

Vacation_Rentals <- read.socrata(AirBnB_list[["identifier"]][3]) %>% 
  mutate(latitude = latlong(Location)$latitude,
         longitude = latlong(Location)$longitude) %>% select(-Location)
# ------------------------------------------------------------------------------
# Saves each dataset to a separate file:
walk(c("STR_License", "Hotels_Motels", "Vacation_Rentals"),
     ~ write_rds(get(.), paste0("./", ., ".rds")))
