




library("tidyverse")
library("RSocrata")
library("odbc")
library("DBI")
# ------------------------------------------------------------------------------
# List all of the data.nola.gov public safety sources
NOLA_list <- ls.socrata("https://data.nola.gov/")
# ------------------------------------------------------------------------------
# Function to match a vector of keywords to match any instance of a particular
# keyword.
cfs_match <- function(.) any(unlist(.) %in% c("calls for service"))
# ------------------------------------------------------------------------------
# Pull the list of datasets that have the keyword associated with them.
cfs_list <- NOLA_list[
  which(
    as.logical(
      lapply(
        NOLA_list$keyword, FUN = cfs_match))), c("identifier", "title")]
# ------------------------------------------------------------------------------
# Read and write to database each year of data:
con <- dbConnect(odbc(), dsn = "AI Guild Project", 
                 uid = "AIGuildAdmin", 
                 pwd = "terrible_password_01",
                 dbname = "nolacfs")
# ------------------------------------------------------------------------------
read_csv("./CFS/CFS_names_big.csv") %>% 
  {dbWriteTable(conn = con, 
                dbname = "nolacfs",
                name = "CFS_names_big",
                value = ., overwrite = TRUE)}

walk(seq_len(nrow(cfs_list)), ~ {
  df <- tryCatch(read.socrata(cfs_list[["identifier"]][.x]),
                     error = function(e) return(NULL))
  if (!is.null(df)) {
    print(paste0(.x, " succeeded")) 
  } else {
    print(paste0(.x, " failed"))
  }
  if (dbExistsTable(con, make.names(cfs_list[["title"]][.x]))) {
    return(print(make.names(cfs_list[["title"]][.x])))
  } else {
    dbWriteTable(conn = con, 
                 # name = dbQuoteString(con, cfs_list[["title"]][.x]),
                 dbname = "nolacfs",
                 name = make.names(cfs_list[["title"]][.x]),
                 value = df, overwrite = TRUE)
  }
})
# ------------------------------------------------------------------------------
# 2018 did not read initially. Tried again below. It worked::
# write_rds(read.socrata(cfs_list[["identifier"]][3L]),
# Update 2019 on 20191104
# write_rds(read.socrata(cfs_list[["identifier"]][6L]),
#           paste0("./", make.names(cfs_list[["title"]][6L]), ".rds"))
