# Shiny app script for Lehigh's Office of International Affairs that displays
# partnership agreements.
# Updated - 7/20/2023 (jsm4)
#
# Packages ----------------------------------------------------------------
# Load required packages
library(htmltools)
library(rnaturalearth)
library(rnaturalearthdata)
library(tidyverse)
library(sf)
library(leaflet)
library(reactable)
library(bslib)
library(shiny)
library(bsicons)
library(shinydashboard)
library(shinycssloaders)
library(leafem)

# Data --------------------------------------------------------------------
# Country boundary sf object
sf <- ne_countries(scale = 'medium', returnclass = 'sf')
sf <- sf |> 
  select(name_long) |> 
  st_transform(crs=4326) |> 
  mutate(id=row_number())

# Partnership locations (geocoded)
df <- read_csv('data/oia_partnerships_geocoded.csv')
df <- df |> drop_na(lon)
df <- st_as_sf(df, coords = c("lon","lat"), crs = 4326)

# Shiny app ---------------------------------------------------------------
# User interface ----
# ui <- fixedPage(
#   theme = bslib::bs_theme(version = 5),
#   title = 'Lehigh University Office of International Affairs - Partnerships',
#   br(),
#   h3(tags$img(src = 'Lehigh_logo.png',width = 50,),'Lehigh University Office of International Affairs - Partnership Dashboard'),
#   hr(),
#   tabsetPanel(
#     tabPanel(
#       title = "Map",
#       fluidRow(
#         column(
#           width = 9,
#           withSpinner(leafletOutput(
#             outputId = "map",
#             width = "100%",
#             height = "700px"
#           ))
#         ),
#         column(
#           width = 3,
#           br(),
#           actionButton("reset_button", "Reset map view"),
#           br(),
#           br(),
#           value_box(
#             title = 'Total Number of Partnerships', 
#             value = nrow(df),
#             p("*Click on the map",bs_icon("map"), "for country specific numbers."),
#             #p("Click on the map for country specific numbers", bs_icon("map")),
#             showcase = bs_icon("bank"),
#             theme_color = "secondary"
#           ),
#           br(),
#           uiOutput('card'),
#         )
#       )
#     ),
#     tabPanel(
#       title = "Data table",
#       reactableOutput(outputId = "table")
#     )
#   )
# )

# Server function ----
server <- function(input, output, session) {
  
  df.tbl <- df |> 
    select(Name,City,Country,Description,Link) |> 
    st_drop_geometry() |> 
    mutate(
       Name=iconv(Name, to = "UTF-8"),
       City=iconv(City, to = "UTF-8"),
       Country=iconv(Country, to = "UTF-8"),
       Description=iconv(Description, to = "UTF-8"),
       Link=iconv(Link, to = "UTF-8"))
  
  output$table <- renderReactable({
    
    theme <- reactableTheme(borderColor = "#dfe2e5",
                            stripedColor = "#f6f8fa",
                            highlightColor = "#f0f5f9",
                            cellPadding = "8px 12px")
    
    reactable(df.tbl,
              theme = theme,
              filterable = TRUE,
              showPageSizeOptions = TRUE,
              striped = TRUE,
              height = "auto",
              columns = list(
                Country = colDef(
                  filterInput = function(values, name) {
                    tags$select(
                      # Set to undefined to clear the filter
                      onchange = sprintf("Reactable.setFilter('country-select', '%s', event.target.value || undefined)", name),
                      # "All" has an empty value to clear the filter, and is the default option
                      tags$option(value = "", "All"),
                      lapply(unique(values), tags$option),
                      "aria-label" = sprintf("Filter %s", name),
                      style = "width: 100%; height: 28px;")}),
                Link = colDef(cell = function(value) {
                  htmltools::tags$a(href = value, target = "_blank", value)
        })),
        defaultPageSize = 10,
        elementId = "country-select"
    )
  })
  
  output$map <- renderLeaflet({
    # Default view location
    lat  <- 30.868406
    lng  <- -32.689948
    zoom <- 3
    
    # Leaflet map
    map <- {
        leaflet(sf) |> 
        setView(lat = lat,
                lng = lng,
                zoom = zoom) |> 
        addTiles("https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png") |>
        addMarkers(data = df,
                   clusterOptions = markerClusterOptions(),
                   label = ~as.character(Name),
                   group = "markers",
                   options = markerOptions(
                     opacity = 1
                   )) |>
        addPolygons(color='black',
                    fillColor='white',
                    stroke=TRUE,
                    weight=0.1,
                    opacity=0,
                    fillOpacity=0,
                    label = ~name_long,
                    layerId = ~id,
                    options = list(clickable = TRUE),
                    highlightOptions = highlightOptions(
                      weight = 2,
                      color = "blue",
                      opacity = 0.5,
                      fillOpacity = 0,
                      bringToFront = TRUE),
                    group = 'country')
    }
  })
  
  observeEvent(input$map_shape_click, {
    click <- input$map_shape_click
    
    layer_id <- click$id
    
    sf.sub <- sf |> filter(id == layer_id)
    
    df.sub <- df |> 
      filter(Country == sf.sub$name_long) |> 
      select(Name,place,Description,Link) |> 
      st_drop_geometry() |> 
      rename(Location=place)
    
    print(layer_id)
    
    output$card <- renderUI({
      value_box(
        title = paste0('Number of Partnerships in ', sf.sub$name_long),
        value = nrow(df.sub),
        showcase = bs_icon("bank"),
        theme_color = "secondary"
      )
    })
  })
  
  # Add the hover highlight behavior
  observeEvent(input$myMap_shape_myLayer_mouseover, {
    leafletProxy("map") %>%
      clearGroup("highlight") %>%
      highlight("country", layerId = input$myMap_shape_myLayer_mouseover, group = "highlight")
  })
  
  # Remove the hover highlight behavior
  observeEvent(input$myMap_shape_myLayer_mouseout, {
    leafletProxy("map") %>%
      clearGroup("highlight")
  })
  
  observeEvent(input$reset_button, {
    lat  <- 30.868406
    lng  <- -32.689948
    zoom <- 3
    #input$reset_button
    leafletProxy('map') %>% setView(lat = lat, lng = lng, zoom = zoom)
  })
  
}

shinyApp(ui=htmlTemplate("www/index.html"), server)
