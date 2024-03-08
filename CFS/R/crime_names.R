




library(data.table)
library(tidyverse)
namen <- read_csv("./CFS/CFS_names_big.csv") %>% rename(old_name = old_names)
colnames(namen) <- c("row", "old_name", "cons_name", "new_name")
cons_name <- unique(namen$cons_name) %>% .[!is.na(.)]
namen$new_name <- gsub(" ", "_", namen$new_name)
namen$new_name <- gsub("-", "", namen$new_name)
# ------------------------------------------------------------------------------
big_df <- read_rds("./CFS/CFS_counts.rds")
df <- big_df %>% 
  mutate_at(c(5:ncol(.)), parse_integer) %>%
  mutate_at(c(3:4), parse_double) %>% 
  mutate(date = as.Date(as.integer(date), origin = "1970-01-01")) %>% 
  arrange(address, date) %>% group_by(address, date) %>% summarise_all(sum) %>% 
  ungroup()
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

