




# ------------------------------------------------------------------------------
df <- read_rds("./data/amenity_df.rds") %>% st_as_sf() %>%
  mutate(date = as.Date(date, origin = "1970-01-01")) 
addr <- df$address %>%
  str_remove_all("\\s+$") %>%
  str_remove_all("\\.+") %>%
  str_to_lower() %>%
  str_replace("street$", "st") %>%
  str_replace("place$", "pl") %>% 
  str_replace("circle$", "cl") %>% 
  str_replace("drive$", "dr") %>%
  str_replace("court$", "ct") %>%
  str_replace("road$", "rd") %>%
  str_replace("lane$", "ln") %>% 
  str_replace("parkway$", "pkwy") %>% 
  str_replace("highway$", "hwy") %>% 
  str_to_upper()
df <- df %>% mutate(address = addr)
# ------------------------------------------------------------------------------
write_rds(df, "./data/amenity_formatted.rds")