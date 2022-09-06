library(sf)
library(plotly)
library(tidyverse)
library(shiny)

fname <- system.file("shape/nc.shp", package="sf")
nc <- st_read(fname)

plot_ly(nc)

num_features <- dim(nc)[1]

# for each feature, imagine 10 years of data

years <- 2000:2010

# for each feature, and for each of the 10 years, imagine there are two variables a and b

nc_names <- nc[,"NAME"] %>% st_drop_geometry()

set.seed(12)

fake_dta <-
  expand_grid(nc_names, year = years) %>%
  mutate(a = runif(n()),
         b = runif(n())
  ) %>%

  mutate(
    text_a = glue::glue("In {NAME} in {year}, a was {round(a, 2)}"),
    text_b = glue::glue("In {NAME} in {year}, b was {round(b, 2)}")
  )

# Join the data back

nc2 <- nc %>%
  left_join(fake_dta)


# Question is how to plot both a and b as two maps, side by side, sharing the same
# time slider

ui <- fluidPage(
  plotlyOutput(outputId = "main_plot"),
)

server <- function(input, output, ...) {

  output$main_plot <- renderPlotly({
    map_a <-
      plot_ly(nc2) %>%
      add_sf(
        split = ~NAME,
        color = ~a,
        frame = ~year,
        stroke = I("black"),
        text = ~text_a,
        hoveron = "fills", hoverinfo = "text",
        showlegend = FALSE,
        type = "scatter",
        mode = "lines"#,
      ) %>%
      add_annotations(
        text = "A",
        x = 0.5, y = 1,
        yref = "paper",
        xref = "paper",
        yanchor = "bottom",
        valign = "middle",
        align = "center",
        showarrow = FALSE,
        font = list(size = 15)
      ) %>%
      layout(
        showlegend = FALSE,
        shapes = list(
          type = "rect",
          x0 = 0,
          x1 = 1,
          xref = "paper",
          y0 = 0,
          y1 = 16,
          yanchor = 1,
          yref = "paper",
          ysizemode = "pixel",
          fillcolor = toRGB("gray80"),
          line = list(color = "transparent")
        )
      )
    map_a

    # to map b
    map_b <-
      plot_ly(nc2) %>%
      add_sf(
        split = ~NAME,
        color = ~b,
        frame = ~year,
        stroke = I("black"),
        text = ~text_b,
        hoveron = "fills", hoverinfo = "text",
        showlegend = FALSE,
        type = "scatter",
        mode = "lines"#,
      ) %>%
      add_annotations(
        text = "B",
        x = 0.5, y = 1,
        yref = "paper",
        xref = "paper",
        yanchor = "bottom",
        valign = "middle",
        align = "center",
        showarrow = FALSE,
        font = list(size = 15)
      ) %>%
      layout(
        showlegend = FALSE,
        shapes = list(
          type = "rect",
          x0 = 0,
          x1 = 1,
          xref = "paper",
          y0 = 0,
          y1 = 16,
          yanchor = 1,
          yref = "paper",
          ysizemode = "pixel",
          fillcolor = toRGB("gray80"),
          line = list(color = "transparent")
        )
      )

    map_b

    # These produce warnings: line.color doesn't (yet) support data arrays
    # Only one fillcolor per trace allowed

    # and both together

    subplot(map_a, map_b)
  })

}

shinyApp(ui, server)

# to map a
