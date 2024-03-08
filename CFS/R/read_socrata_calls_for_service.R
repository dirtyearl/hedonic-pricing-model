




library(tidyverse)
library(RSocrata)
# ------------------------------------------------------------------------------
# List all of the data.nola.gov public safety sources
NOLA_list <- ls.socrata("https://data.nola.gov/")
# ------------------------------------------------------------------------------
# Function to match a vector of keywords to match any instance of a particular
# keyword.
cfs_match <- function(.) any(unlist(.) %in% c("calls for service"))
# ------------------------------------------------------------------------------
# Pull the list of datasets that have the keyword associated with them.
cfs_list <- NOLA_list[which(as.logical(lapply(NOLA_list$keyword,
                                                 FUN = cfs_match))),
                      c("identifier", "title")]
# ------------------------------------------------------------------------------
# Read and write to Rds file each year of data:
walk(seq_len(nrow(cfs_list)), ~ {
  write_rds(tryCatch(read.socrata(cfs_list[["identifier"]][.x]),
                     error = function(e) return(NULL)),
            paste0("./", make.names(cfs_list[["title"]][.x]), ".rds"))
})
# ------------------------------------------------------------------------------
# 2018 did not read initially. Tried again below. It worked::
# write_rds(read.socrata(cfs_list[["identifier"]][3L]),
# Update 2019 on 20191104
write_rds(read.socrata(cfs_list[["identifier"]][6L]),
          paste0("./", make.names(cfs_list[["title"]][6L]), ".rds"))
