############################################################
# app.R — Dashboard GEIH 2022-2025 (v2, modular)
# Lee agregados.rds (ligero) y filtra por año/geografía/migración.
# Lógica en R/ ; pestañas en modules/ ; carga en global.R.
# Estética: identidad de marca "Premium Dark Tech" (www/brand.css).
############################################################
source("global.R")

ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(disable = TRUE),
  dashboardSidebar(
    div(class = "sb-brand",
        tags$img(class = "sb-logo", src = "logo-blanco.svg", alt = "Observatorio GEIH"),
        div(class = "sb-title", "Observatorio GEIH"),
        div(class = "sb-tag", "GEIH • DANE")),
    div(class = "sb-divider"),
    div(class = "sb-section", "Navegación"),
    sidebarMenu(
      id = "tabs",
      menuItem("Inicio", tabName = "inicio", icon = icon("house")),
      menuItem("Demografía", tabName = "demografia", icon = icon("users")),
      menuItem("Educación", tabName = "educacion", icon = icon("graduation-cap")),
      menuItem("Mercado laboral", tabName = "laboral", icon = icon("briefcase")),
      menuItem("Vivienda", tabName = "vivienda", icon = icon("building")),
      menuItem("Salud", tabName = "salud", icon = icon("heart-pulse")),
      menuItem("Migración", tabName = "migracion", icon = icon("plane-arrival")),
      menuItem("Datos", tabName = "datos", icon = icon("table"))
    ),
    div(class = "sidebar-footer",
        div(class = "sb-actions",
            tags$a(class = "sb-act", href = "https://www.linkedin.com/in/daniel-molina-b76a4323b/",
                   target = "_blank", title = "LinkedIn", icon("linkedin-in")),
            tags$a(class = "sb-act", href = "https://github.com/dmetrics1",
                   target = "_blank", title = "GitHub", icon("github")),
            tags$a(class = "sb-act", title = "Tema",
                   onclick = "document.body.classList.toggle('theme-light')", icon("moon"))))
  ),
  dashboardBody(
    tags$head(
      tags$title("GEIH 2022-2025 · Observatorio"),
      tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
      tags$link(rel = "preconnect", href = "https://fonts.gstatic.com", crossorigin = ""),
      tags$link(rel = "stylesheet",
                href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap"),
      tags$link(rel = "stylesheet", type = "text/css", href = "brand.css?v=9")
    ),
    conditionalPanel(
      condition = "input.tabs != 'inicio'",
    div(class = "card-panel filtros",
        div(class = "panel-head",
            h2(class = "panel-title", textOutput("seccion_titulo", inline = TRUE)),
            div(class = "panel-context", textOutput("contexto", inline = TRUE))),
        div(class = "filtros-label", "Filtros"),
        div(class = "filtros-row",
            div(class = "filtro", selectInput("anio", "Año", choices = ANIOS, selected = max(ANIOS))),
            div(class = "filtro", selectInput("nivel", "Nivel territorial",
                                              choices = c("Nacional", "Departamental"))),
            div(class = "filtro", selectInput("migracion", "Población",
                                              choices = c("Todos", "Solo venezolanos"))),
            conditionalPanel(
              condition = "input.nivel == 'Departamental'",
              div(class = "filtro", selectInput("depto", "Ubicación",
                                                choices = DEPTOS, selected = "Magdalena"))),
            div(class = "filtro-clear",
                actionButton("limpiar", "Limpiar", icon = icon("eraser"), class = "btn-limpiar")))
    )),
    tabItems(
      tabItem(tabName = "inicio", inicioUI("ini")),
      tabItem(tabName = "demografia", demografiaUI("demo")),
      tabItem(tabName = "educacion", educacionUI("edu")),
      tabItem(tabName = "laboral", laboralUI("lab")),
      tabItem(tabName = "vivienda", viviendaUI("viv")),
      tabItem(tabName = "salud", saludUI("sal")),
      tabItem(tabName = "migracion", migracionUI("mig")),
      tabItem(tabName = "datos", datosUI("dat"))
    )
  )
)

TITULOS_SECCION <- c(demografia = "Demografía", educacion = "Educación",
                     laboral = "Mercado laboral", vivienda = "Vivienda",
                     salud = "Salud", migracion = "Migración", tendencias = "Tendencias",
                     datos = "Datos")

server <- function(input, output, session) {
  ctx <- reactive({
    list(
      anio     = as.integer(input$anio),
      geo      = if (input$nivel == "Nacional") "Nacional" else input$depto,
      migrante = if (input$migracion == "Todos") "Todos" else "Venezolano"
    )
  })

  # Título de la sección activa
  output$seccion_titulo <- renderText({
    nm <- input$tabs
    if (is.null(nm) || !nm %in% names(TITULOS_SECCION)) "Demografía" else TITULOS_SECCION[[nm]]
  })

  # Línea de contexto dinámica
  output$contexto <- renderText({
    c <- ctx()
    pob <- if (c$migrante == "Todos") "Todos" else "Solo migración venezolana"
    paste0("Caracterización GEIH · DANE     |     Año: ", c$anio,
           "     |     Contexto: ", c$geo, "     |     Población: ", pob)
  })

  # Botón Limpiar: restablece filtros
  observeEvent(input$limpiar, {
    updateSelectInput(session, "anio", selected = max(ANIOS))
    updateSelectInput(session, "nivel", selected = "Nacional")
    updateSelectInput(session, "migracion", selected = "Todos")
    updateSelectInput(session, "depto", selected = "Magdalena")
  })

  inicioServer("ini")
  demografiaServer("demo", ctx)
  educacionServer("edu", ctx)
  laboralServer("lab", ctx)
  viviendaServer("viv", ctx)
  saludServer("sal", ctx)
  migracionServer("mig", ctx)
  datosServer("dat", ctx)
}

shinyApp(ui, server)
