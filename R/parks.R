




library(tidyverse)
parks <- read_csv("./parks.csv", col_names = FALSE)
parks$X1 <- NULL
parks <- parks[-c(1:17, 232:nrow(parks)), ]
even <- parks[c(TRUE, FALSE), 1]
odd <- parks[!c(TRUE, FALSE), 1]

even <- even %>% mutate(parks = as.character(X2))
str_func <- function(.) {
  . <- str_split(., pattern = "/")
  . <- unlist(.)[3:4]
  .[2] <- str_remove_all(.[2], "[\\,>,<,\"]")
  names(.) <- .[2]
  . <- .[1]
}
park_list <- lapply(even$parks, str_func)

