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
      menuItem("Demografía", tabName = "demografia", icon = icon("users"))
      # Educación, Mercado laboral, Vivienda, Salud, Migración, Tendencias, Datos -> siguiente
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
      tags$link(rel = "stylesheet", type = "text/css", href = "brand.css")
    ),
    div(class = "card-panel filtros",
        div(class = "card-title", "Filtros"),
        fluidRow(
          column(3, selectInput("anio", "Año:", choices = ANIOS, selected = max(ANIOS))),
          column(3, selectInput("nivel", "Nivel:", choices = c("Nacional", "Departamental"))),
          column(3, selectInput("migracion", "Población:",
                                choices = c("Todos", "Solo venezolanos"))),
          column(3, conditionalPanel(
            condition = "input.nivel == 'Departamental'",
            selectInput("depto", "Departamento:", choices = DEPTOS, selected = "Magdalena")))
        )
    ),
    tabItems(
      tabItem(tabName = "demografia", demografiaUI("demo"))
    )
  )
)

server <- function(input, output, session) {
  ctx <- reactive({
    list(
      anio     = as.integer(input$anio),
      geo      = if (input$nivel == "Nacional") "Nacional" else input$depto,
      migrante = if (input$migracion == "Todos") "Todos" else "Venezolano"
    )
  })

  demografiaServer("demo", ctx)
}

shinyApp(ui, server)
