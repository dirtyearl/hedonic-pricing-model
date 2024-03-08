




library(tidyverse)
library(plotly)
dt <- read_rds("./CFS/CFS_Formatted.rds")
# ------------------------------------------------------------------------------
val <- function(x, type = "zip", date_range = NULL) {
  # x = 70116; 
  type = "zip"
  choice <- match.arg(type, c("address", "zipcode"))
  obs <- switch(choice, "address" = "address", "zipcode" = "zip_code")
  if (is.numeric(x)) obs <- "zip_code"
  if (is.character(x)) obs <- "address"
  if (is.null(date_range)) date_range <- as.Date(c("2018-07-01", "2018-07-31"))
  dt[which(dt[[obs]] == x & between(dt[["date"]],
                                    date_range[[1]],
                                    date_range[[2]])), ] %>% 
    summarise_at(vars(4:45), list(~ sum(., na.rm = TRUE))) %>% gather() %>% 
    transmute(Crime = key, 
              CFS = if_else(as.integer(value) == 0,
                            NA_integer_, as.integer(value)))
}
# ------------------------------------------------------------------------------
# addr <- val(70115, "zip") %>% gather() %>%
#   transmute(Crime = key, 
#   CFS = if_else(as.integer(value) == 0, NA_integer_, as.integer(value)))
# ------------------------------------------------------------------------------
pie_plot <- plot_ly(val(70115, "zip"), labels = ~Crime, values = ~CFS, type = 'pie') %>%
  layout(title = 'Calls for Service in Zipcode 70115 in July 1-31, 2018',
         xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
         yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))

# Create a shareable link to your chart
# Set up API credentials: https://plot.ly/r/getting-started
htmlwidgets::saveWidget(as_widget(pie_plot), "./crime_graph.html")
# chart_link = api_create(pie_plot, filename="pie-basic")
# chart_link
