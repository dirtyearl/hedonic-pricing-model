




library(tidyverse)
library(sf)
library(leaflet)
# ------------------------------------------------------------------------------
crime_df <- read_rds("./CFS/CFS_Formatted.rds")
prop_df <- read_rds("./property.rds")
sch_df <- read_rds("./schools.rds")
# ------------------------------------------------------------------------------
nola <- tigris::tracts(state = "LA", county = "Orleans")
tmp <- st_as_sf(nola)

plot(tmp, max.plot = 12)
ggplot(data = tmp) +
  geom_sf()
describe(tmp)
