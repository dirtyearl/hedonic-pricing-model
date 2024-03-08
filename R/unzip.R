




# ------------------------------------------------------------------------------
library(DBI)
library(tidyverse)
library(stringi)
# ------------------------------------------------------------------------------
year <- c(2003:2015)
for (zfile in yr) {
  unzip(paste0(getwd(), "/LA-", zfile, ".zip"), exdir = paste0(getwd(), "/", zfile))
  if (identical(zfile, 2017L) || identical(zfile, 2016L)) {
    rd <- paste0(getwd(), "/", zfile, "/LA")
    stp <- paste0(getwd(), "/", 2015L)
  } else {
    stp <- rd <- paste0(getwd(), "/", zfile)
  }
  if (file.exists(zfile %s+% ".db")) next
}
# ------------------------------------------------------------------------------
# The following line must be run to create the database files by state:
# sqlite3 year.db < sqlite_setup.sql 
# sqlite3 year.db < sqlite_load.sql
yr = year[1]
db = paste(getwd(), yr, yr %s+% ".db", sep = "/")
con <- dbConnect(RSQLite::SQLite(), db)

dbDisconnect(con)
