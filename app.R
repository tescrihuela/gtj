suppressMessages(library(shiny))
suppressMessages(library(leaflet))
suppressMessages(library(dplyr))
suppressMessages(library(htmltools))
suppressMessages(library(rgdal))


#### Input data ####
trace <- readOGR("www/data/trace.geojson", encoding = 'utf8')
gtj_pied <- readOGR("www/data/gtj_pied.geojson", encoding = 'utf8')
gtj_raquettes <- readOGR("www/data/gtj_raquettes.geojson", encoding = 'utf8')
# heberg <- readRDS("www/data/hebergements.rds")
dep_arr <- readOGR("www/data/departs_arrivees.geojson", encoding = 'utf8')
dep_arr_icon <- makeIcon("www/svg/accommodation_youth_hostel.svg", 30, 30)

#### Infobulles ####
trace$tooltip <- sprintf(
  "<strong>Trace : </strong>%s<br>
  <strong>Longueur : </strong>%s km<br>",
  trace$nom, round(trace$longueur/1000, 1)
) %>% lapply(htmltools::HTML)
# heberg$tooltip <- sprintf(
#   "<h5>%s</h5>
#   <strong>URL : </strong><a href=%s target=_blank>%s</a><br>",
#   heberg$nom, heberg$url, heberg$url
# ) %>% lapply(htmltools::HTML)


####  UI  ####
ui <- fluidPage(

  # Chargement du CSS
  tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "css/default.css")),

  # Création de la layout
  navbarPage("Week-end Jura", id = "main",
    tabPanel("La GTJ en raquettes",
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
      data = gtj_pied,
      stroke = TRUE,
      dashArray =  "5",
      color = "blue",
      group = "GTJ Pied",
      weight = 5,
      # popup = trace$tooltip,
      # label = trace$tooltip,
      highlightOptions = highlightOptions(
        color = "#b16694", 
        weight = 3,
        bringToFront = TRUE
      )
    ) %>%               

    addPolylines(
      data = gtj_raquettes,
      stroke = TRUE,
      dashArray =  "5",
      color = "purple",
      group = "GTJ Raquettes",
      weight = 5,
      # popup = trace$tooltip,
      # label = trace$tooltip,
      highlightOptions = highlightOptions(
        color = "#b16694", 
        weight = 3,
        bringToFront = TRUE
      )
    ) %>%               

    addPolylines(
      data = trace,
      stroke = TRUE,
      dashArray =  "5",
      color = "brown",
      group = "Trace initiale",
      weight = 3,
      popup = trace$tooltip,
      label = trace$tooltip,
      highlightOptions = highlightOptions(
        color = "#b16694", 
        weight = 3,
        bringToFront = TRUE
      )
    ) %>%
    
    addMarkers(
      data = dep_arr,
      icon = dep_arr_icon,
      label = dep_arr$nom,
      group = "Départs / Arrivées"
    ) %>% 

    addMeasure(
      position = "topleft",
      primaryLengthUnit="kilometers", 
      primaryAreaUnit = "sqmeters",
      activeColor = "#3D535D",
      completedColor = "#7D4479"
    ) %>%

    addLayersControl(
      baseGroups = c("OSM", "OpenTopoMap", "Orthos", "Plan IGN"),
      overlayGroups = c("GTJ Pied", "GTJ Raquettes", "Trace initiale", "Départs / Arrivées"),
      position = "topright",
      options = layersControlOptions(collapsed = FALSE)
    ) %>% 
    
    hideGroup("Trace initiale")
  })
}

shinyApp(ui, server)