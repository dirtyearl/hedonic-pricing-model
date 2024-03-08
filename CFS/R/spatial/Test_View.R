




suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))
# walk(seq_len(2), ~ {
#   assign(paste0("df_", .x),
#          read_rds(paste0("./CFS/spatial/mapping/Group_2_", .x, "_CFS.rds")),
#          envir = .GlobalEnv)
# })

df <- data.frame()
for (i in list.files("./CFS/spatial/mapping")) {
  df <- read_rds(paste0("./CFS/spatial/mapping/", i)) %>% bind_rows(df, .)
}
write_rds(df, "./CFS/spatial/mapping/CFS_counts.rds")
