




library(tidyverse)
library(RSocrata)
# ------------------------------------------------------------------------------
# List all of the data.nola.gov public safety sources
NOLA_list <- ls.socrata("https://data.nola.gov/Public-Safety-and-Preparedness/")
# ------------------------------------------------------------------------------
# Function to match a vector of keywords to match any instance of a particular
# keyword.
EPR_match <- function(.) any(unlist(.) %in% "electronic police report")
# ------------------------------------------------------------------------------
# Pull the list of datasets that have the keyword associated with them.
EPR_list <- NOLA_list[which(as.logical(lapply(NOLA_list$keyword,
                                              FUN = EPR_match))), c("identifier", "title")]
# ------------------------------------------------------------------------------
# Walk the list of titles and identifiers to assign the dataset to its title. It
# creates individual datasets by year. Ok solution.
walk2(EPR_list[["title"]], EPR_list[["identifier"]], ~ assign(.x, read.socrata(.y), envir = .GlobalEnv))
# ------------------------------------------------------------------------------
# Alternatively iterate through the identifers, read the data, and bind by row.
# It creates the dataframe by row and assigns it. Best solution.
df <- map_dfr(EPR_list[["identifier"]], read.socrata)
      