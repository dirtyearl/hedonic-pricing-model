




# Parallelize the conversion from .rds to .csv files. Initialize 9 cores (my
# fancy laptop has 12, but there are only 9 years to parallelize:
cluster <- parallel::makeCluster(getOption("cl.cores", 9))
# ------------------------------------------------------------------------------
# Function that reads the data from .rds and writes the data to .csv:
read_write_csv <- function(.x) {
  require(magrittr)
  readr::read_rds(paste0("./CFS/Calls.for.Service.", .x, ".rds")) %>% 
    readr::write_csv(paste0("./CFS/Calls.for.Service.", .x, ".csv"))
}
# ------------------------------------------------------------------------------
# `invisible` will prevent the `parallel` function from writing its result to the
# desktop as a list:
invisible(
  parallel::clusterApply(cluster, seq(2011, 2019), read_write_csv)
)
# ------------------------------------------------------------------------------
# Same as above: The previous lines can be nested in the following, with an anonymous function
# declared inline. (The R equivalent of a Python lambda function.):
invisible(
  parallel::clusterApply(parallel::makeCluster(getOption("cl.cores", 9)),
                         seq(2011, 2019), 
                         function(.x) {
                           require(magrittr)
                           readr::read_rds(paste0("./CFS/Calls.for.Service.", .x, ".rds")) %>% 
                             readr::write_csv(paste0("./CFS/Calls.for.Service.", .x, ".csv"))
                         }
  )
)
