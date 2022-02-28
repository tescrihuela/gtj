suppressMessages(library(shiny))
suppressMessages(library(leaflet))
suppressMessages(library(dplyr))
suppressMessages(library(htmltools))


#### Input data ####
trace <- readRDS("www/data/trace.rds")
heberg <- readRDS("www/data/hebergements.rds")


#### Infobulles ####
trace$tooltip <- sprintf(
  "<strong>Trace : </strong>%s<br>
  <strong>Longueur : </strong>%s km<br>",
  trace$nom, round(trace$longueur/1000, 1)
) %>% lapply(htmltools::HTML)
heberg$tooltip <- sprintf(
  "<h5>%s</h5>
  <strong>URL : </strong><a href=%s target=_blank>%s</a><br>",
  heberg$nom, heberg$url, heberg$url
) %>% lapply(htmltools::HTML)


####  UI  ####
ui <- fluidPage(

  # Chargement du CSS
  tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "css/default.css")),

  # Création de la layout
  navbarPage("Week-end Jura", id = "main",
    tabPanel("GTJ depuis Les Rousses jusqu'à Giron",
      div(class = "outer",
        leafletOutput(
          outputId = "mymap",
          height = "100%",
          width = "100%"
        )
      )
    )
  )
)


#### Server ####
server <- function(input, output, session) {

  ## La carto
  output$mymap <- renderLeaflet({
    leaflet() %>% 
    setView(lng = 5.93804, lat = 46.36085, zoom = 11) %>%
    
    addTiles(group="OSM") %>%
    addTiles("http://wxs.ign.fr/choisirgeoportail/wmts?REQUEST=GetTile&SERVICE=WMTS&VERSION=1.0.0&STYLE=normal&TILEMATRIXSET=PM&FORMAT=image/jpeg&LAYER=ORTHOIMAGERY.ORTHOPHOTOS&TILEMATRIX={z}&TILEROW={y}&TILECOL={x}", options = WMSTileOptions(tileSize = 256),group = "Orthos") %>%      
    addTiles("http://wxs.ign.fr/cartes/wmts?REQUEST=GetTile&SERVICE=WMTS&VERSION=1.0.0&STYLE=normal&TILEMATRIXSET=PM&FORMAT=image/png&LAYER=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2&TILEMATRIX={z}&TILEROW={y}&TILECOL={x}",options = WMSTileOptions(tileSize = 256),group = "Plan IGN") %>%
    addTiles("https://a.tile.opentopomap.org/{z}/{x}/{y}.png", group = "OpenTopoMap") %>%


    addPolylines(
      data = trace,
      stroke = TRUE,
      dashArray =  "5",
      color = "brown",
      group = "Trace",
      weight = 3,
      popup = trace$tooltip,
      label = trace$tooltip
    ) %>%               

    addCircleMarkers(
      data = heberg,
      stroke = TRUE,
      color = "blue",
      fillColor = "red",
      fillOpacity = 0.8,
      group = "Hébergements",
      radius = 10,
      popup = heberg$tooltip,
      label = heberg$tooltip
    ) %>%
    
    addLayersControl(
      baseGroups = c("OSM", "OpenTopoMap", "Orthos", "Plan IGN"),
      overlayGroups = c("Trace", "Hébergements"),
      position = "topright",
      options = layersControlOptions(collapsed = FALSE)
    )
  })
}

shinyApp(ui, server)