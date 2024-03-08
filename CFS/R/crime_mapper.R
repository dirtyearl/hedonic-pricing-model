




# ------------------------------------------------------------------------------
# The following script can be run using the batch script in Sharepoint. Using
# the batch script is suggested so that one can continue to work on projects
# without RStudio being occupied running the script itself. To use the batch
# script, open a command prompt in windows, direct it to the file, and type its
# name:
# ------------------------------------------------------------------------------
# yr = 2018 # Testing value for one year.
library(data.table)
library(tidyverse)
# `crime_mapper` is a function passed to each session used to run the entire
# dataset. Using the batch script on shrepoint, changing the appropriate values,
# will process all of the data in about 1 hour and 20 minutes. Processing the
# data using only one R session could take 25 hours:
crime_mapper <- function(yr) {
  # The librarys must be declared in the function so that they can be loaded in
  # parallel R session:
  require(xts)
  require(tidyverse)
  require(data.table)
  # Added in an attempt to run some of the calculation on the GPU. Not necessary:
  require(gpuR)
  # `Path` is needed to run the script batch process.
  Path <<- "C:\\Users\\edavis67\\OneDrive - DXC Production\\Documents\\Industrialized AI Badge\\Guild_Project"
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
  # Create a subset of the property data.frame with only the relevant
  # properties: anything since "2012-02-01", non-missing addresses and longitude
  # and latitude data, and a year that matches the year passed to the wrapping
  # function:
  pdf <- as.data.table(property_df)[order(date)][L1.month >= "2012-02-01"][
    !(is.na(address) | is.na(L1.month) | is.na(L1.year) | is.na(longitude) | is.na(latitude))
    ][, year := as.integer(format(L1.month, "%Y"))][year == yr]# [1:min(50, .N), ]
  # Removing the comment at the end of line 46 will run the entire dataset.
  pdf <- unique(pdf[, c("address", "date")])[pdf, on = c("address", "date")]
  # ------------------------------------------------------------------------------
  # Pull the crime data for the current and previous year. Should contain all of
  # the crime in the `pdf` locations and dates filtered above:
  crime_df <- map_df(c(yr - 1, yr), ~ {
    read_rds(paste0(paste0(Path, "/CFS/CFS_", .x, ".rds")))
  }) %>% as.data.table()
  # ------------------------------------------------------------------------------
  # Distance function is vectorised for speed. Tried to use the gpu, but the
  # code did not work and the vectorised calculation below is likely not the
  # bottleneck anyway. The functions access compiled C functions internally:
  dist_func <- function(p1, p2) {
    require(magrittr) # Needed for the `%>%` pipe operator...
    # require(geosphere) # Does not work.
    # tryCatch(distHaversine(p1, p2, r = 3963), error = function(e) NULL)
    # ------------------------------------------------------------------------------
    (((p1 - p2) ^ 2) %*% c(1, 1)) %>% sqrt() # Runs slightly faster...
    # ((p1 - p2) ^ 2) %>% rowSums() %>% sqrt() # Runs slightly slower...
  }
  # ------------------------------------------------------------------------------
  # Function used to calculate the relevant crime by distance and return a
  # data.frame row with the address, date, latitude, and longitude:
  crime_func <- function(date, address, longitude, latitude, L1.month, L1.year) {
    # matlab::tic(); 
    date <- date
    addr <- address
    long <- longitude
    lati <- latitude
    L1.month <- L1.month
    L1.year <- L1.year
    # ------------------------------------------------------------------------------
    # Filter out CFS that do not fall within a lag 1 month and lag 1 year and a
    # month. Filters out missing latitude and longitude. Calculates the distance
    # using the function above. Removes anything with a distance greater than 94
    # (indicating the latitude and longitude are encoded as 0). Finally keep
    # only the values < 0.001, or 0.1 if using Haversine distance:
    rel_crime <- crime_df[timecreate < L1.month & timecreate > L1.year] %>%
      .[!is.na(latitude) | !is.na(longitude)] %>%
      .[, distance :=
          dist_func(cbind(rep(long, .N), rep(lati, .N)),
                    cbind(longitude, latitude))] %>%
      .[!(distance > 94)] %>% .[distance < 0.001] 
    # distance < 0.001 if using rough euclidean distance, 0.1 if using Haversine
    # distance. Haversine does not work on the bulk dataset.
    # ------------------------------------------------------------------------------
    crime_count <- rel_crime[, .N, by = typetext][, percent_crime := N/sum(N)]
    cnt <- crime_count %>% transpose() %>% as.data.table()
    col_cnt <- unlist(cnt[1, ]) %>% unname()
    var_cnt <- unlist(cnt[2, ]) %>% unname() %>% as.integer()
    dt_row <- cbind(addr, date, lati, long, t(var_cnt)) %>% as.data.frame(stringsAsFactors = FALSE)
    colnames(dt_row) <- c("address", "date", "latitude", "longitude", col_cnt)
    return(dt_row)
    # matlab::toc()
  }
  pmap_dfr(pdf[, c("date", "address", "longitude", "latitude", "L1.month", "L1.year")], crime_func)
}
# ------------------------------------------------------------------------------
# Runs in about a minute to view a subset of the data by changing line 46:
# df <- lapply(seq(2012, 2019), crime_mapper) %>% bind_rows() %>%
#   write_rds(paste0(Path, "/CFS/CFS_counts_small.rds"))
# setDTthreads(percent = 80); getDTthreads()
# ------------------------------------------------------------------------------
# The following code runs the entire dataset in about an hour and twenty
# minutes. Comment out the end of line 46 and run using the command line:
system.time(
  parallel::parLapplyLB(
    parallel::makeCluster(getOption("cl.cores", 8)),
    seq(2012, 2019), crime_mapper) %>% bind_rows() %>%
    write_rds("C:\\Users\\edavis67\\OneDrive - DXC Production\\Documents\\Industrialized AI Badge\\Guild_Project/CFS/CFS_counts.rds")
)
