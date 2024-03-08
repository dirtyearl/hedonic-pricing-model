




# ------------------------------------------------------------------------------
# The following script can be run using the batch script in Sharepoint. Using
# the batch script is suggested so that one can continue to work on projects
# without RStudio being occupied running the script itself. To use the batch
# script, open a command prompt in windows, direct it to the file, and type the
# filename:
# ------------------------------------------------------------------------------
# yr = 2018 # Testing value for one year.
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))
# `crime_mapper` is a function passed to each session used to run the entire
# dataset. Using the batch script on sharepoint, changing the appropriate values,
# will process all of the data in about 1 hour and 20 minutes. Processing the
# data using only one R session could take 25 hours:
# ------------------------------------------------------------------------------
library("AzureAuth")
library("AzureStor")
token <- get_azure_token(
  "https://storage.azure.com",
  tenant = "93f33571-550f-43cf-b09f-cd331338d086",
  app = "1a9f5ae8-c492-44e6-a785-34d4bd58a2ad", 
  password = "f15c9a8a-2c2d-4c5a-b11d-4e62c8934eca")

cont <- storage_endpoint(
  "https://aiguildstorageacct.dfs.core.windows.net",
  token = token, 
  key = "AXFWoO/dsp5/vf58IBRRi8xY3YX/e5bBLcmAS+5tINPdUoyeZxd8lavLvQISmgOwtDHk1cSa7MAQgjVM59TCYA==") %>% 
  storage_container("cfs")

walk(list_storage_files(cont)$name, ~ {
  # .x = list_storage_files(cont)$name[[1]]
  if (file.exists(paste(tempdir(), .x, sep = "/"))) return(print(.x))
  storage_download(
    cont, 
    src = .x, # paste0("CFS/", .x), 
    dest = paste(tempdir(), .x, sep = "/"),
    overwrite = TRUE)
})
# ------------------------------------------------------------------------------
temppath <- tempdir()
crime_mapper <- function(prop_range) {
  # prop_range = c(24601, 28090)
  # ------------------------------------------------------------------------------
  # The librarys must be declared in the function so that they can be loaded in
  # parallel R session:
  # ------------------------------------------------------------------------------
  suppressPackageStartupMessages(require(xts))
  suppressPackageStartupMessages(require(tidyverse))
  suppressPackageStartupMessages(require(data.table))
  suppressPackageStartupMessages(require(sf))
  suppressPackageStartupMessages(require(gpuR))
  # ------------------------------------------------------------------------------
  Path <<- temppath
  # Sets the number of threads for data.table. Might not be necessary:
  # setDTthreads(threads = 0); getDTthreads()
  setDTthreads(percent = 80) # ; getDTthreads()
  # ------------------------------------------------------------------------------
  # Load the property values and locations:
  property_df <- read_rds(paste0(Path, "/property.rds"))
  # Create a 30 day lag and a 1 year and 30 day lag as the decision window:
  property_df$L1.month <- lubridate::ymd(property_df$date) - lubridate::days(30)
  property_df$L1.year <- lubridate::ymd(property_df$L1.month) - lubridate::years(1)
  # ------------------------------------------------------------------------------
  pdf <- as.data.table(property_df)[order(date)][L1.month >= "2012-02-01"][
    !(is.na(address) | is.na(L1.month) | is.na(L1.year) |
        is.na(longitude) | is.na(latitude))
    ][prop_range[[1]]:prop_range[[2]], ] #[1:min(50, .N), ]
  # Removing the comment at the end of line 46 will run the entire dataset.
  pdf <- unique(pdf[, c("address", "date")])[pdf, on = c("address", "date")] %>% 
    as.data.frame() %>% st_as_sf(coords = c("longitude", "latitude"), 
                                 crs = 4326L, na.fail = FALSE)
  
  yr_range <- range(pdf$L1.year, pdf$L1.month, finite = TRUE) %>%
    lapply(function(.x) .x %>% format("%Y") %>% as.integer())
  # ------------------------------------------------------------------------------
  # Pull the crime data for the current and previous year. Should contain all of
  # the crime in the `pdf` locations and dates filtered above:
  crime_df <- map_df(seq(yr_range[[1]], yr_range[[2]]), ~ {
    read_rds(paste0(Path, "/CFS/CFS_", .x, ".rds"))
  }) %>% mutate(call_date = as.Date(timecreate, format = "%Y-%m-%d")) %>%
    st_as_sf(coords = c("longitude", "latitude"), 
             crs = 4326L, na.fail = FALSE)
# ------------------------------------------------------------------------------
  crime_func <- function(addr) {
    matlab::tic()
    # addr = as.list(pdf[1, ]); addr$geometry = addr$geometry %>% unlist()
    geom_addr <- addr$geometry %>% st_point() %>% st_sfc(crs = 4326L)
    addr$geometry <- attr(addr, "sf_column") <- attr(addr, "agr") <- NULL
    L1.year <- as.Date(addr$L1.year, format = "%Y-%m-%d")
    L1.month <- as.Date(addr$L1.month, format = "%Y-%m-%d")
    # ------------------------------------------------------------------------------
    rel_crime <- crime_df %>%
      filter(st_is_within_distance(geom_addr, ., dist = 300, sparse = FALSE)) %>%
      as.data.table()
    rel_crime <- rel_crime[call_date < L1.month & call_date > L1.year, ][, .N, by = typetext]
    if (nrow(rel_crime) < 1) return(NULL)
    # ------------------------------------------------------------------------------
    crime_count <- rel_crime %>%
      as.data.frame(stringsAsFactors = FALSE) %>%
      spread(key = typetext, value = N)
    addr <- addr %>% as.data.frame(stringsAsFactors = FALSE)
    res <- bind_cols(addr, crime_count) %>%
      mutate(geometry = geom_addr) %>% st_as_sf() %>% 
      st_set_geometry("geometry")
    matlab::toc()
    return(res)
  }
  apply(pdf, 1, crime_func) %>% bind_rows()
}
# ------------------------------------------------------------------------------
Range <- c(0, 2809L, 5619L, 8430L, 11200L, 14000L, 16900L, 19700L, 
           22500L, 25299L, 28090L)
prop_range <- lapply(seq_along(Range)[-length(Range)], function(.) {
  c(c(Range[[.]] + 1, Range[[. + 1]]))
})
# Runs in 6 minutes to view a subset of the data by changing line 44:
# df <- map(prop_range, crime_mapper) %>% bind_rows() %>% 
#   write_rds(paste0(Path, "/CFS/spatial/CFS_counts_small.rds"))
# setDTthreads(percent = 80); getDTthreads()
# ------------------------------------------------------------------------------
# The following code runs the entire dataset in about an hour and twenty
# minutes. Comment out the end of line 46 and run using the command line:
walk(seq_along(prop_range), ~ {
  Range <- prop_range[[.x]]
  group <- seq(Range[[1]], Range[[2]]) %>% split(cut(., 10, label = FALSE))
  for (i in seq_along(group)) {
    name <- paste("Group", .x, i, "CFS.rds", sep = "_")
    Path <- "C:/Users/edavis67/OneDrive - DXC Production/Documents/Industrialized AI Badge/Guild_Project"
    # df <- map(lapply(group, range), crime_mapper) %>% bind_rows() %>%
    #   write_rds(paste0(Path, "/CFS/spatial/mapping/", name))
    if (name %in% list.files(paste0(Path, "/CFS/spatial/mapping"))) next
    system.time(
      parallel::parLapplyLB(
      parallel::makeCluster(getOption("cl.cores", 10)),
      lapply(group[[i]], range), crime_mapper) %>% bind_rows() %>%
        write_rds(paste0(Path, "/CFS/spatial/mapping/", name))
    )
  }
}
)
