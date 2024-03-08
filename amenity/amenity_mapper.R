




# ------------------------------------------------------------------------------
# The librarys must be declared in the function so that they can be loaded in
# parallel R session:
# ------------------------------------------------------------------------------
suppressPackageStartupMessages(require(tidyverse))
suppressPackageStartupMessages(require(sf))
# ------------------------------------------------------------------------------
# Load the property values and locations:
pdf <- read_rds("./property.rds") %>% arrange(date) %>%
  filter(date >= "2012-01-01") %>%
  st_as_sf(coords = c("longitude", "latitude"), 
           crs = 4326L, na.fail = FALSE)
source("./data/process_data.R")
# ------------------------------------------------------------------------------
t = 0
matlab::tic()
amen_func <- function(addr) {
  # addr = as.list(pdf[1, ]); addr$geometry = addr$geometry %>% unlist()
  geom_addr <- addr$geometry %>% st_point() %>% st_sfc(crs = 4326L)
  addr$geometry <- attr(addr, "sf_column") <- attr(addr, "agr") <- NULL
  # ------------------------------------------------------------------------------
  amenity <- c("Culinary.Arts", "Festivals.and.Markets", "Grocery.Stores", 
               "park_df", "Restaurants", "School.Locations", "Urban.Gardens")
  rel_amen <- map(amenity, ~ {
    get(.x) %>% filter(
      st_is_within_distance(
        geom_addr, ., dist = 300, sparse = FALSE)) %>% st_drop_geometry() %>%
      summarize(!!(.x) := n())
  }) %>% bind_cols()         
  # ------------------------------------------------------------------------------
  addr <- addr %>% as.data.frame(stringsAsFactors = FALSE)
  res <- bind_cols(addr, rel_amen) %>%
    mutate(geometry = geom_addr) %>% st_as_sf() %>% 
    st_set_geometry("geometry")
  t <<- t + 1L
  if (!(t %% 1000)) matlab::toc()
  return(res)
}
amen_df <- apply(pdf, 1, amen_func) %>% bind_rows()
write_rds(amen_df, "./data/amenity_df.rds")
