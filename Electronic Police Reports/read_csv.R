





library(tidyverse)
source_list <- list(yr2017 = c("https://data.nola.gov/resource/qtcu-97s9.csv", 113688L),
                    yr2018 = c("https://data.nola.gov/resource/3m97-9vtw.csv", 122554L),
                    yr2016 = c("https://data.nola.gov/resource/4gc2-25he.csv", 101004L),
                    yr2019 = c("https://data.nola.gov/resource/mm32-zkg7.csv", 32888L),
                    yr2015 = c("https://data.nola.gov/resource/9ctg-u58a.csv", 99272L),
                    yr2014 = c("https://data.nola.gov/resource/6mst-xjhm.csv", 103849L),
                    yr2010 = c("https://data.nola.gov/resource/s25y-s63t.csv", 60980L),
                    yr2013 = c("https://data.nola.gov/resource/je4t-6qub.csv", 103545L),
                    yr2012 = c("https://data.nola.gov/resource/x7yt-gfg9.csv", 105755L),
                    yr2011 = c("https://data.nola.gov/resource/t596-ginn.csv", 98980L))

df <- map_df(source_list, ~ {
  limit = 50000L
  offset = 0
  records <- as.integer(.[2])
  df <- data.frame()
  while (records > nrow(df)) {
    if ((offset + limit) >= records) {
      # offset <- offset + records - limit
      offset_code <- NULL
    } else {
      offset <- offset + limit
      offset_code <- paste0("&$offset=", offset)
    }
    temp <- read_csv(paste0(.[1], "?$limit=", limit, offset))
    df <- bind_rows(df, temp)
    # Sys.sleep(3)
  }
  df
})

df_dupl <- df[duplicated(df), ]
write_csv(df, "C:/Users/edavis67/OneDrive - DXC Production/data/crime/EPR/Electronic_Police_Reports_2010-2019.csv")
write_rds(df, "C:/Users/edavis67/OneDrive - DXC Production/data/crime/EPR/Electronic_Police_Reports_2010-2019.rds")
