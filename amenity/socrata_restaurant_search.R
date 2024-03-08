




library(tidyverse)
library(RSocrata)
# ------------------------------------------------------------------------------
# List all of the data.nola.gov public safety sources
NOLA_list <- ls.socrata("https://data.nola.gov/")
# ------------------------------------------------------------------------------
# Function to match a vector of keywords to match any instance of a particular
# keyword.
foody_match <- function(.) any(unlist(.) %in% c("restaurant", "food"))
# ------------------------------------------------------------------------------
# Pull the list of datasets that have the keyword associated with them.
foody_list <- NOLA_list[which(as.logical(lapply(NOLA_list$keyword,
                                              FUN = foody_match))),
                      c("identifier", "title", "keyword")]
# ------------------------------------------------------------------------------
# Read and write to Rds file each year of data:
walk(seq_len(nrow(foody_list)), ~ {
  write_rds(tryCatch(read.socrata(foody_list[["identifier"]][.x],
                                  email = .socrata_email,
                                  password = .socrata_password,
                                  stringsAsFactors = FALSE),
                     error = function(e) return(NULL)),
            paste0("./restaurants/", make.names(foody_list[["title"]][.x]), ".rds"))
})
# ------------------------------------------------------------------------------


