




library(xts)
library(tidyverse)
property_df <- read_rds("./property.rds")
airbnb_df <- read_rds("./STR_License.rds")

# ------------------------------------------------------------------------------
# STR Distance function:
dist_func <- function(x1, y1, x2, y2) {
  sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
}
# ------------------------------------------------------------------------------
# AirBnB close by:
airbnb_func <- function(address, date, longitude, latitude) {
  L1.date <- as.Date(date - 30)
  L1.year <- L1.date - 365
  rel_str <- airbnb_df %>% filter(Expiration.Date > L1.year & Issue_Date < L1.date)
  if (identical(NROW(rel_str), 0)) {
    print(paste0("invalid ", address))
    return(NA)
  }
  rel_str[["distance"]] <- dist_func(longitude, latitude,
                                     unlist(rel_str[["longitude"]]),
                                     unlist(rel_str[["latitude"]]))
  sd_ <- sd(rel_str[["distance"]], na.rm = TRUE)
  mean_ <- mean(rel_str[["distance"]], na.rm = TRUE)
  rel_str$std_err <- rel_str$distance/sd_
  airbnb_count <- rel_str %>% summarise(airbnb_count = n())
  airbnb_median <- rel_str %>% filter(std_err < 0.01) %>% summarise(airbnb_n = n())
  bind_cols(date = date, address = address, airbnb_median, airbnb_count, prcnt_nearby = airbnb_median/airbnb_count)
}

df <- pmap_dfr(property_df[c("address", "date", "longitude", "latitude")], airbnb_func)
df %>% arrange(desc(airbnb_n1)) %>% filter(!is.nan(airbnb_n1)) %>% View()
