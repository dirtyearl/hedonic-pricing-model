




library(tidyverse)
library(sf)
# ------------------------------------------------------------------------------
sch_df <- read_csv("./School_Locations_data.csv")
tg <- sch_df %>% separate(the_geom, c("point", "lon", "lat"), sep = " ") %>%
  select(-point) %>% mutate(lon = parse_number(lon),
                            lat = parse_number(lat))
write_rds(tg, "./schools.rds")
