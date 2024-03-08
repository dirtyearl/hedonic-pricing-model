




# data.table version with parallelization. Fastest version as of now:
read_write_dt <- function(yr) {
  require(magrittr)
  require(data.table)
  latlong <- function(.data) {
    xy <- stringr::str_split(.data, " ") %>% lapply(readr::parse_number)
    list(latitude = lapply(xy, function(.) .[1]),
         longitude = lapply(xy, function(.) .[2]))
  }
  readr::read_rds(paste0("./CFS/Calls.for.Service.", yr, ".rds")) %>% as.data.table() %>%
    .[dispositiontext %in%
        c("REPORT TO FOLLOW", "Necessary Action Taken", "GONE ON ARRIVAL")] %>%
    # .[!(typetext %in% c("AUTO ACCIDENT WITH INJURY", 
    #                   "RETURN FOR ADDITIONAL INFO", "TRAFFIC INCIDENT",
    #                   "AUTO ACCIDENT", "COMPLAINT OTHER", "HIT & RUN"))] %>% 
    .[, c("latitude", "longitude") := .(unlist(latlong(location)$latitude),
                                        unlist(latlong(location)$longitude))] %>%
    .[, location := NULL] %>% readr::write_rds(path = paste0("./CFS/CFS_", yr, ".rds"))
  print(as.character(yr))
}
# Calls the previous function and allocates the work across 9 cores on the laptop:
system.time(
invisible(parallel::clusterApply(
  parallel::makeCluster(getOption("cl.cores", 9)),
  seq(2011, 2019), read_write_dt))
)
# ------------------------------------------------------------------------------
# Easier to follow original Version. Would take a long time to run without
# parallelization:
# ------------------------------------------------------------------------------
# library(xts)
# library(tidyverse)
# library(data.table)
# # ------------------------------------------------------------------------------
# # Function to separate the latitude and longitude:
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
