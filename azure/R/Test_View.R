




suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(arrow))
library("AzureAuth")
library("AzureStor")

# walk(seq_len(2), ~ {
#   assign(paste0("df_", .x),
#          read_rds(paste0("./CFS/spatial/mapping/Group_2_", .x, "_CFS.rds")),
#          envir = .GlobalEnv)
# })

df <- data.frame()
for (i in list.files("./CFS/spatial/mapping")) {
  df <- read_rds(paste0("./CFS/spatial/mapping/", i)) %>% 
    mutate_at(c("date", "L1.month", "L1.year"), as.integer) %>% 
    {bind_rows(df, .)}
}
df <- distinct(df)
df %>% write_rds(paste(tempdir(), "CFS_counts.rds", sep = "/"))
# Write `.parquet` data instead of `.rds`, may not work:
# df %>% write_parquet(paste(tempdir(), "CFS_counts.parquet", sep = "/"))
# ------------------------------------------------------------------------------
token <- get_azure_token("https://storage.azure.com",
                         tenant = "93f33571-550f-43cf-b09f-cd331338d086",
                         app = "1a9f5ae8-c492-44e6-a785-34d4bd58a2ad", 
                         password = "f15c9a8a-2c2d-4c5a-b11d-4e62c8934eca")

cont <- storage_endpoint(
  "https://aiguildstorageacct.dfs.core.windows.net",
  token = token, 
  key = "AXFWoO/dsp5/vf58IBRRi8xY3YX/e5bBLcmAS+5tINPdUoyeZxd8lavLvQISmgOwtDHk1cSa7MAQgjVM59TCYA==") %>% 
  storage_container("cfs")

storage_upload(
  cont, 
  src = paste(tempdir(), "CFS_counts.rds", sep = "/"),
  # src = paste(tempdir(), "CFS_counts.parquet", sep = "/"),
  dest = "CFS_counts.rds")
