




library(shiny)
library(shinydashboard)
library(tidyverse)
library(plotly)
# ------------------------------------------------------------------------------
dt <- read_rds(paste0("data/CFS_Formatted.rds"))
ui <- dashboardPage(
  # includeCSS("file.css")
  dashboardHeader(title = "Crime"),
  dashboardSidebar(
    dateRangeInput("dateRange", label = "Date Range",
                   start = "2018-07-01", end = "2018-07-31"),
    selectInput("zipCode", label = "Zipcode",
                choices = c(70112L, 70113L, 70114L, 70115L,
                            70116L, 70117L, 70118L, 70119L, 
                            70121L, 70122L, 70123L, 70124L,
                            70125L, 70126L, 70127L, 70128L, 
                            70129L, 70130L, 70131L, 70170L),
                selected = 70115),
    # ------------------------------------------------------------------------------
    checkboxGroupInput("callNames", label = "Call Type:", 
                       c("abandoned_property", "aggravated_crime", "armed_crime", 
                         "auto_accident", "bad_checks", "burgular_alarm", "burgulary", 
                         "carjacking", "check", "complaint_or_disturbance",
                         "contributing_to_delinquency", "creeper", 
                         "criminal_damage", "criminal_mischief", "death", "discharging_firearm", 
                         "drugs_or_alcohol", "dui", "electronic_monitoring", "extortion", 
                         "fire_rescue", "fugitive_attachment", "hit_and_run", "homocide", 
                         "illegal_carry", "lost_or_stolen", "municipal_attchment", "negligent_injury", 
                         "obscene_indecent", "officer_needs_assistance", "possession_stolen_property", 
                         "recovery_of_vehicle", "return_for_info", "silent_911", "silent_912", 
                         "simple_crime", "theft", "traffic_event", "unauthorized_use_vehicle", 
                         "underage_drinking", "violation_of_protection_order", "walking_beat", 
                         "warrant_stop"))),
  dashboardBody(
    dataTableOutput("dataTable"),
    plotlyOutput("piePlot"))
)
# ------------------------------------------------------------------------------
server <- function(input, output, session) {
  inputValue <- reactive({
    dt[which(dt[["zip_code"]] == input$zipCode & between(dt[["date"]],
                                                         input$dateRange[[1]],
                                                         input$dateRange[[2]])), ] %>%
      summarise_at(vars(4:ncol(.)), list(~ sum(., na.rm = TRUE))) %>% gather() %>%
      transmute(Crime = key,
                CFS = if_else(as.integer(value) == 0,
                              NA_integer_, as.integer(value))) %>% 
      filter(Crime %in% input$callNames)
  })
  inputPlot <- reactive({
    plot_ly((inputValue() %>% .[.$CFS > 8, ]),
            labels = ~Crime, values = ~CFS, type = 'pie') %>%
      layout(title = paste0("Calls for Service in Zipcode ",
                            input$zipCode, " from ",
                            input$dateRange[[1]],
                            " to ", input$dateRange[[2]]),
             xaxis = list(showgrid = FALSE, zeroline = FALSE,
                          showticklabels = FALSE),
             yaxis = list(showgrid = FALSE, zeroline = FALSE,
                          showticklabels = FALSE))
  })
  output$dataTable <- renderDataTable({
    inputValue() %>% .[which(.$CFS > 8), ]
  })
  output$piePlot <- renderPlotly({
    inputPlot()
  })
}
# ------------------------------------------------------------------------------
shinyApp(ui, server)




