




library(tidyverse)
# ------------------------------------------------------------------------------
# There are commas in the fields that confuse the standard read_csv function, so
# we have to clean the data. Read the original csv file line by line and save it
# to an R object---a character vector:
output <- read_lines("./output.csv")
# ------------------------------------------------------------------------------
# We write our own function to digest the data line by line from`output`:
make_df <- function(.) {
  # Break down each line and add a newline so the tokenizer works, and unlist:
  tk <- unlist(tokenize(paste0(., "\n")))
  # Format the date. The tokenizer separates the month and day from the year,
  # and some of the months include period abbreviations, while others have the
  # full name---try both:
  dt <- as.Date(paste0(tk[1], ", ", tk[2]), tryFormats = c("%B %d, %Y", "%b. %d, %Y"))
  # The zip code is always the 3rd, and the address is always the 4th:
  zipcode <- tk[3]
  addr <- tk[4]
  # Most of the amounts have commas to delimit the millions and thousands. If
  # you only grab the 5th and 6th components, you miss anything over a million
  # dollars, and sometimes they are non-zero, so you check that there are three
  # characters:
  if (str_length(trimws(tk[6])) == 3 && str_length(trimws(tk[7])) == 3) {
    price <- paste0(tk[5:7], collapse = "")
    longitude <- tk[8]
    latitude <- tk[9]
    buyer_seller <- tk[10:(length(tk) - 2)]
    # Sometimes the amount does not have a thousands component, so we check the
    # first four characters to see if they are consistent with a longitude:
  } else if (str_sub(tk[6], 1, 4) == "-90." || str_sub(tk[6], 1, 4) == "-89.") {
    price <- paste0(tk[5], collapse = "")
    longitude <- tk[6]
    latitude <- tk[7]
    buyer_seller <- tk[8:(length(tk) - 2)]
    # Everything else should be < $1000000 and > $999:
  } else {
    price <- paste0(tk[5:6], collapse = "")
    longitude <- tk[7]
    latitude <- tk[8]
    buyer_seller <- tk[9:(length(tk) - 2)]
  }
  # The last two components are the lot and district:
  district <- tk[length(tk) - 1]
  lot <- tk[length(tk)]
  # Form a tibble (a dataframe that does not coerce characters into factors or
  # add row names to dataframes). The buyer_seller is a combined list of the
  # buyers and sellers. As they get mangled in the tokenization, they catch
  # everthing that cannot be classified otherwise:
  df <- tibble(date = dt, zip_code = zipcode, address = addr,
                   amount = price, longitude = longitude, latitude = latitude,
                   buyer_seller = list(buyer_seller), district = district, lot = lot, )
  return(df)
}
# Forms the dataframe by concatenating the individual rows formed from the above
# function: (Combined below with the data transformations.) 
# df <- map_df(output[-1], make_df)
# ------------------------------------------------------------------------------
# Three function wrappers to process the columns. They add '[EMPTY]' to the list
# of NA's. Wrapping the function is an alternative to passing the argument list
# in the mutate_at function below:
parse_int <- function(.) parse_integer(., na = c("", "NA", "[EMPTY]"))
parse_num <- function(.) parse_number(., na = c("", "NA", "[EMPTY]"))
parse_chr <- function(.) parse_character(., na = c("", "NA", "[EMPTY]"))
# ------------------------------------------------------------------------------
# Creates the dataframe, passing it to the functions that turn them into
# integer, number, and character vectors:
df <- map_df(output[-1], make_df) %>%
  mutate_at(vars(zip_code, district, lot), parse_int) %>% 
  mutate_at(vars(amount, longitude, latitude), parse_num) %>%
  mutate_at(vars(address), parse_chr)
# ------------------------------------------------------------------------------
tmp <- df
# Drop the buyer and seller to make exporting more convenient:
tmp$buyer_seller <- NULL
# Remove inconvenient punctuation if necessary:
tmp$address <- str_remove_all(tmp$address, "[.,]")
# Summary to check if the data make sense:
summary(tmp)
# Export to rds and csv formats:
write_rds(tmp, "./property.rds")
write_csv(tmp, "./property.csv")



