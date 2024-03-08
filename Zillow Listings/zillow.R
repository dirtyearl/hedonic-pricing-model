




library(ZillowR)
library(xts)
library(XML)
zpid <- read_file("./zillow/zillow.txt")
set_zillow_web_service_id(zpid)
df <- read_rds("./property.rds") %>% arrange(date)
# ------------------------------------------------------------------------------
# property_details <- GetUpdatedPropertyDetails(zpid = NULL, zws_id = getOption("ZillowR-zws_id"),
#                                               url = "http://www.zillow.com/webservice/GetUpdatedPropertyDetails.htm")
# search_results <- GetSearchResults(address = NULL, citystatezip = NULL,
#                                    rentzestimate = FALSE, zws_id = getOption("ZillowR-zws_id"),
#                                    url = "http://www.zillow.com/webservice/GetSearchResults.htm")
df_row <- c(df[28069, ])
address <- df_row$address
zipcode <- df_row$zip_code
res <- GetSearchResults(address = address, citystatezip = "New Orleans, LA",
                                   rentzestimate = FALSE, zws_id = getOption("ZillowR-zws_id"),
                                   url = "http://www.zillow.com/webservice/GetSearchResults.htm")
zpid <- list()
zpid <- map2(df[["address"]], df[["zip_code"]], ~ {
  csz <- paste0("New Orleans, LA ", .y)
  res <- GetSearchResults(.x, csz)
  if (is.null(res$response$results$result$zpid$text)) {
    return(NULL) 
  } else {
    print(res$response$results$result$zpid$text)
    return(res$response$results$result$zpid$text)
  }
})
