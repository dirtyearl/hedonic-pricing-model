




# ------------------------------------------------------------------------------
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(sf))

# ------------------------------------------------------------------------------
addr <- CFS_df <- read_rds("./CFS/spatial/mapping/CFS_formatted.rds")
addr <- addr %>% subset(select = c(address, date))
CFS_df <- CFS_df %>% st_drop_geometry() %>% as.data.table()
amen_df <- read_rds("./data/amenity_formatted.rds") %>% as.data.table()
df <- CFS_df[amen_df, on = .(address, date)] %>% as.data.frame() %>% 
  select(-starts_with("i.")) %>% full_join(addr, df, by = c("address", "date"))
df$geometry.y <- NULL
df <- df %>% st_as_sf(sf_column_name = "geometry.x", crs = 4326L) %>% rename(geometry = geometry.x)
CFS_fltr <- paste0("is.na(", colnames(df)[9:51], ")") %>%
  paste0(collapse = " & ")
amen_fltr <- paste0("is.na(", colnames(df)[52:58], ")") %>%
  paste0(collapse = " & ")
fltr <- paste0("!(", CFS_fltr, ")")
df <- df %>% filter(eval(parse(text = fltr))) %>%
  distinct(address, date, amount, .keep_all = TRUE)
hoods <- st_read("./shapefiles/Neighborhood_Statistical_Areas") %>%
  st_transform(crs = 4326L)
# ------------------------------------------------------------------------------
tmp <- df %>% select(-c(zip_code, district, lot, starts_with("L1."))) %>%
  filter(amount > 1500) %>%
  # mutate_at(4:53, ~ round(. / max(.), 3)) %>% mutate(amount = log(amount))
  mutate_at(4:53,
            ~ round((. - mean(., na.rm = TRUE)) / sd(., na.rm = TRUE), 3)) %>%
  mutate(amount = log(amount))

frml <- paste0(colnames(tmp)[3], " ~ ", paste0(colnames(tmp)[4:53], collapse = " + ")) %>% as.formula()
tmp_mod <- lm(frml, data = tmp)
#summary(tmp_mod)
pred_amnt <- predict(tmp_mod) #%>% exp()
pred_df <- cbind(tmp[1:3], pred_amnt) %>% st_drop_geometry() %>% 
  mutate_at(vars(amount, pred_amnt), exp)
