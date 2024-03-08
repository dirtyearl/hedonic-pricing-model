




library(data.table)
library(tidyverse)
# ------------------------------------------------------------------------------
# Load and format the variable names. Names were consolidated by hand in Excel
# and saved to a csv file:
namen <- read_csv("./CFS/CFS_names_big.csv") %>% rename(old_name = old_names)
colnames(namen) <- c("row", "old_name", "cons_name", "new_name")
cons_name <- unique(namen$cons_name) %>% .[!is.na(.)]
namen$new_name <- gsub(" ", "_", namen$new_name)
namen$new_name <- gsub("-", "", namen$new_name)
# ------------------------------------------------------------------------------
# Reads the Calls for Service (CFS) data:
big_df <- read_rds("./CFS/CFS_counts.rds")
zipcode <- read_rds("./property.rds") %>% select(address, zip_code) %>% unique() %>% as.data.table()
big_df <- full_join(zipcode, big_df, by = "address")
# Formats the CFS data, converting from character data to integer, double, and
# date formats:
addr <- big_df$address %>% str_remove_all("\\.$") %>% 
  str_replace("Street$", "St") %>% str_replace("Pl$", "Place") %>% 
  str_replace("Drive$", "Dr") %>% str_replace("Lane$", "Ln")

df <- big_df %>% 
  mutate(address = addr) %>% 
  mutate_at(c(6:ncol(.)), parse_integer) %>%
  mutate_at(c("longitude", "latitude"), parse_double) %>% 
  mutate(date = as.Date(as.integer(date), origin = "1970-01-01")) %>% 
  # Some of the locations and dates are duplicated for some reason, so we
  # summarise across the rows by summation. Should probably check to make sure
  # that the summation is correct:
  arrange(address, date, zip_code) %>% group_by(address, date, zip_code) %>% summarise_all(sum) %>% 
  ungroup()
# ------------------------------------------------------------------------------
# Creates a data.table object with unique addresses and dates. It is consistent
# with the data.frame above:
dt <- data.table(address = df$address, date = df$date, zip_code = df$zip_code) %>% unique()
# The loop uses the old and new name vectors above to create a new name variable
# that is the sum of the old name variables across rows:
for (n in cons_name) {
  # n = cons_name[1] # Declared for testing an instance of the loop:
  nm <- namen$old_name[namen$new_name %in% n]
  name_list <- colnames(df)[colnames(df) %in% namen$old_name[namen$new_name %in% n]]
  temp <- df %>% transmute(address = address, date = date, zip_code = zip_code,
                           !!(n) := rowSums(.[, name_list], na.rm = TRUE)) %>% 
    as.data.table()
  # Each temp data.frame is joined to the data.table:
  dt <- dt[temp, on = c("address", "date", "zip_code")]
}
write_rds(dt, "./CFS/app/data/CFS_Formatted.rds")
