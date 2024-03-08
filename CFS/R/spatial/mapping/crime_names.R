




library(data.table)
library(tidyverse)
library(sf)
namen <- read_csv("./CFS/CFS_names_big.csv") %>% rename(old_name = old_names)
colnames(namen) <- c("row", "old_name", "cons_name", "new_name")
cons_name <- unique(namen$cons_name) %>% .[!is.na(.)]
namen$new_name <- gsub(" ", "_", namen$new_name)
namen$new_name <- gsub("-", "", namen$new_name)
# ------------------------------------------------------------------------------
df <- read_rds("./CFS/spatial/mapping/CFS_counts.rds")
geom_df <- df[, c("address", "date", "geometry")] %>%
  st_as_sf() %>%
  unique()

df <- df %>%
  select(-c(zip_code, amount, district, lot, L1.month, L1.year, geometry)) %>%
  unique() %>% arrange(date, address) %>% group_by(date, address) %>%
  summarise_all(sum) %>% ungroup()
# ------------------------------------------------------------------------------
dt <- data.table(address = df$address, date = df$date) %>% unique()
for (n in cons_name) {
  # n = cons_name[1]
  nm <- namen$old_name[namen$new_name %in% n]
  name_list <- colnames(df)[colnames(df) %in% namen$old_name[namen$new_name %in% n]]
  temp <- df %>% transmute(address = address, date = date,
                           !!(n) := rowSums(.[, name_list], na.rm = TRUE)) %>% 
    as.data.table()
  dt <- dt[temp, on = c("address", "date")]
}
# ------------------------------------------------------------------------------
df <- dt %>% as.data.frame() %>%
  left_join(geom_df, by = c("address", "date")) %>%
  mutate(date = as.Date(as.integer(date), origin = "1970-01-01")) %>%
  st_as_sf()

