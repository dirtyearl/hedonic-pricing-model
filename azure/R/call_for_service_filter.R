




# data.table version with parallelization. Fastest version as of now:
read_write_dt <- function(yr) {
  # yr = 2018L
  require("magrittr")
  require("tidyverse")
  require("data.table")
  require("odbc")
  require("DBI")
# ------------------------------------------------------------------------------
  latlong <- function(.data) {
    xy <- stringr::str_split(.data, " ") %>% lapply(readr::parse_number)
    list(latitude = lapply(xy, function(.) .[1]),
         longitude = lapply(xy, function(.) .[2]))
  }
# ------------------------------------------------------------------------------
  con <- dbConnect(odbc(), dsn = "AI Guild Project", 
                   uid = "AIGuildAdmin", 
                   pwd = "terrible_password_01",
                   dbname = "nolacfs",
                   timeout = 30)
# ------------------------------------------------------------------------------
  dbReadTable(con, paste0("Calls.for.Service.", yr)) %>% 
    # readr::read_rds(paste0("./CFS/Calls.for.Service.", yr, ".rds")) %>% 
    as.data.table() %>%
    .[dispositiontext %in%
        c("REPORT TO FOLLOW", "Necessary Action Taken", "GONE ON ARRIVAL")] %>%
    # .[!(typetext %in% c("AUTO ACCIDENT WITH INJURY", 
    #                   "RETURN FOR ADDITIONAL INFO", "TRAFFIC INCIDENT",
    #                   "AUTO ACCIDENT", "COMPLAINT OTHER", "HIT & RUN"))] %>% 
    .[, c("latitude", "longitude") := .(unlist(latlong(location)$latitude),
                                        unlist(latlong(location)$longitude))] %>%
    .[, location := NULL] %>% 
    readr::write_rds(path = paste0("./CFS/CFS_", yr, ".rds")) 
  print(as.character(yr))
}
# Calls the previous function and allocates the work across 9 cores on the laptop:
system.time(
invisible(parallel::clusterApply(
  parallel::makeCluster(getOption("cl.cores", 9)),
  seq(2011, 2019), read_write_dt))
)
# ------------------------------------------------------------------------------
library("AzureAuth")
library("AzureStor")
token <- get_azure_token(
  "https://storage.azure.com",
  tenant = "93f33571-550f-43cf-b09f-cd331338d086",
  app = "1a9f5ae8-c492-44e6-a785-34d4bd58a2ad", 
  password = "f15c9a8a-2c2d-4c5a-b11d-4e62c8934eca")

cont <- storage_endpoint(
  "https://aiguildstorageacct.dfs.core.windows.net",
  token = token, 
  key = "AXFWoO/dsp5/vf58IBRRi8xY3YX/e5bBLcmAS+5tINPdUoyeZxd8lavLvQISmgOwtDHk1cSa7MAQgjVM59TCYA==") %>% 
  storage_container("cfs")

walk(list.files("./CFS", pattern = "CFS_\\d{4}.rds"), ~ {
  storage_upload(cont, src = paste0("./CFS/", .x), dest = .x)
})
# ------------------------------------------------------------------------------
# Easier to follow original Version. Would take a long time to run without
# parallelization:
# ------------------------------------------------------------------------------
# library(xts)
# library(tidyverse)
# library(data.table)
# ------------------------------------------------------------------------------
# Function to separate the latitude and longitude:
# latlong <- function(.data) {
#   xy <- str_split(.data, " ") %>% lapply(parse_number)
#   list(latitude = lapply(xy, function(.) .[1]),
#        longitude = lapply(xy, function(.) .[2]))
#   
# }
# ------------------------------------------------------------------------------
# walk(seq(2011, 2019), ~ {
#   read_rds(paste0("./CFS/Calls.for.Service.", .x, ".rds")) %>%
#     filter(dispositiontext %in% c("REPORT TO FOLLOW", "Necessary Action Taken",
#                                   "GONE ON ARRIVAL")) %>% 
#     mutate(latitude = latlong(location)$latitude,
#            longitude = latlong(location)$longitude) %>% select(-location) %>% 
#     write_rds(path = paste0("./CFS/CFS_", .x, ".rds"))
# })
