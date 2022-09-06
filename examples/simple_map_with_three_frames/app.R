#plot_ly(nc)

#num_features <- dim(nc)[1]


nc_names <- nc[,"NAME"] %>% st_drop_geometry()

set.seed(12)

years <- 2000:2002

fake_dta <-
  expand_grid(nc_names, year = years) %>%
  mutate(value = runif(n())) %>%
  mutate(
    text_value = glue::glue("In {NAME}, the value was {round(value, 2)}")
  )

# Join the data back

nc2 <- nc %>%
  left_join(fake_dta)


# Define UI for application that draws a histogram
ui <- fluidPage(

  # Application title
  titlePanel("Map with animation"),
  actionButton("generate_map", "Click to generate map"),

  plotlyOutput("animated_map"),
  hr(),
  verbatimTextOutput("hover"),
  verbatimTextOutput("click"),
  verbatimTextOutput("interrogate_click")
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  make_map <- reactive({
    input$generate_map

    p <-
      plot_ly(nc2, source = "main_anim_map") %>%
      add_sf(
        split = ~NAME,
        color = ~value,
        frame = ~year,
        stroke = I("black"),
        text = ~text_value,
        hoveron = "fills", hoverinfo = "text",
        showlegend = FALSE,
        type = "scatter",
        mode = "lines"
      )
    p
  })

  output$animated_map <- renderPlotly({
    p <- make_map()
    req(p)
    p %>% event_register(event = "plotly_selecting")
  })

  output$hover <- renderPrint({
    d <- event_data("plotly_hover", source = "main_anim_map")
    if (is.null(d)) "Hover events appear here (unhover to clear)" else d
  })

  output$click <- renderPrint({
    d <- event_data("plotly_click", source = "main_anim_map")
    if (is.null(d)) "Click events appear here (double-click to clear)" else d
  })

  output$interrogate_click <- renderPrint({
    d <- event_data("plotly_click", source = "main_anim_map")
    if (is.null(d)) "Click events appear here (double-click to clear)" else {
      this_curveNumber <- d$curveNumber
      p <- make_map()
      b <- plotly_build(p)
      this_place <- b$x$data[[this_curveNumber + 1]]$name
      this_year  <- b$x$data[[this_curveNumber + 1]]$frame
      # the +1 is needed as JavaScript is 0 indexed but R is 1 indexed
      glue::glue("curveNumber {this_curveNumber} is {this_place}. Is the selected year {this_year}?")
    }
  })



}

# Run the application
shinyApp(ui = ui, server = server)
