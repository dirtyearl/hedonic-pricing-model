





library(xts)
library(tidyverse)
library(data.table)
# ------------------------------------------------------------------------------
# Distance function:
dist_func <- function(x1, y1, x2, y2) {
  sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
}
# ------------------------------------------------------------------------------
# Crime close by:
crime_func <- function(address, date, longitude, latitude) {
  matlab::tic()
  lati <- latitude
  long <- longitude
  year <- format(date, "%Y") %>% as.numeric()
  crime_df <- bind_rows(read_rds(paste0("./CFS/CFS_", year, ".rds")),
                        read_rds(paste0("./CFS/CFS_", year - 1, ".rds"))) %>% 
    as.data.table()
  L1.date <- as.Date(date - 30)
  L1.year <- L1.date - 365
  rel_crime <- crime_df[timecreate < L1.date & timecreate > L1.year] %>%
    .[!is.na(latitude) | !is.na(longitude)] %>% 
    .[, distance := dist_func(long, lati, longitude, latitude)] %>% 
    .[!(distance > 94)] %>% .[distance < 0.001]
  crime_count <- rel_crime[, .N, by = typetext][, percent_crime := N/sum(N)]
  colnames(crime_count) <- make.names(crime_count[1, ])
  crime_count <- crime_count[-1, ]
  data.frame(date = date, address = address, crimes = list(crime_count))
  matlab::toc()
}
# ------------------------------------------------------------------------------





