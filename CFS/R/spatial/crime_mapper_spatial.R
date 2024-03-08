




# ------------------------------------------------------------------------------
# The following script can be run using the batch script in Sharepoint. Using
# the batch script is suggested so that one can continue to work on projects
# without RStudio being occupied running the script itself. To use the batch
# script, open a command prompt in windows, direct it to the file, and type its
# name:
# ------------------------------------------------------------------------------
# yr = 2018 # Testing value for one year.
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))
# `crime_mapper` is a function passed to each session used to run the entire
# dataset. Using the batch script on shrepoint, changing the appropriate values,
# will process all of the data in about 1 hour and 20 minutes. Processing the
# data using only one R session could take 25 hours:
crime_mapper <- function(yr) {
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
  Path <<- "C:\\Users\\edavis67\\OneDrive - DXC Production\\Documents/Industrialized AI Badge\\Guild_Project"
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
    !(is.na(address) | is.na(L1.month) | is.na(L1.year) | is.na(longitude) | is.na(latitude))
    ][, year := as.integer(format(L1.month, "%Y"))][year == yr][1:min(50, .N), ]
  # Removing the comment at the end of line 46 will run the entire dataset.
  pdf <- unique(pdf[, c("address", "date")])[pdf, on = c("address", "date")] %>% 
    as.data.frame() %>% st_as_sf(coords = c("longitude", "latitude"), 
                                 crs = 4326L, na.fail = FALSE)
  # ------------------------------------------------------------------------------
  # Pull the crime data for the current and previous year. Should contain all of
  # the crime in the `pdf` locations and dates filtered above:
  crime_df <- map_df(c(yr - 1, yr), ~ {
    read_rds(paste0(Path, "/CFS/CFS_", .x, ".rds"))
  }) %>% st_as_sf(coords = c("longitude", "latitude"), 
                  crs = 4326L, na.fail = FALSE)
  # ------------------------------------------------------------------------------
  crime_func <- function(addr) {
    matlab::tic()
    # addr = pdf[1, ]
    geom_addr <- addr$geometry %>% st_point() %>% st_sfc(crs = 4326L)
    addr$geometry <- NULL
    addr <- addr %>% as.data.frame() %>% mutate(date = as.Date(date),
                                                L1.year = as.Date(L1.year),
                                                L1.month = as.Date(L1.month),
                                                geometry = geom_addr) %>%
      st_as_sf() %>% st_set_geometry("geometry")
    # ------------------------------------------------------------------------------
    rel_crime <- crime_df %>%
      filter(timecreate > addr[["L1.year"]] & timecreate <= addr[["L1.month"]]) %>% 
      filter(st_is_within_distance(., geom_addr, 300, sparse = FALSE))
    if (nrow(rel_crime) < 1) return(NULL)
    # ------------------------------------------------------------------------------
    crime_count <- rel_crime %>% group_by(typetext) %>%
      summarise(N = n()) %>%
      st_drop_geometry() %>%
      spread(key = typetext, value = N) %>% mutate(geometry = geom_addr) %>%
      st_as_sf() %>% st_set_geometry("geometry")
    # tryCatch(error = function(e) simpleError("crime_count f!@#ed..."))
    res <- st_join(addr, crime_count, join = st_equals)
    matlab::toc()
    return(res)
  }
  tmp <- apply(pdf, 1, crime_func)
}
# ------------------------------------------------------------------------------
# Runs in about a minute to view a subset of the data by changing line 46:
df <- map(seq(2012, 2019), crime_mapper) %>% bind_rows(stringsAsFactors = FALSE) %>% 
  write_rds(paste0(Path, "/CFS/spatial/CFS_counts_small.rds"))
# setDTthreads(percent = 80); getDTthreads()
# ------------------------------------------------------------------------------
# The following code runs the entire dataset in about an hour and twenty
# minutes. Comment out the end of line 46 and run using the command line:
system.time(
  parallel::parLapplyLB(
    parallel::makeCluster(getOption("cl.cores", 8)),
    seq(2012, 2019), crime_mapper) %>% bind_rows() %>%
    write_rds("C:\\Users\\edavis67\\OneDrive - DXC Production\\Documents\\Industrialized AI Badge\\Guild_Project/CFS/spatial/CFS_counts.rds")
)
