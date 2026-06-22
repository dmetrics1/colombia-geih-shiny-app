############################################################
# modules/mod_tendencias.R — Pestaña Tendencias 2022-2025
# Series temporales (ignora el filtro de Año; usa geo + población).
############################################################

tendenciasUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("kpis")),
    fluidRow(
      column(6, div(class = "card-panel",
                    div(class = "card-title", "Tasas laborales 2022–2025"),
                    plotlyOutput(ns("tasas"), height = "420px"))),
      column(6, div(class = "card-panel",
                    div(class = "card-title", "Población 2022–2025"),
                    plotlyOutput(ns("poblacion"), height = "420px")))
    )
  )
}

tendenciasServer <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {

    # Series por año para el geo + población seleccionados
    serie_lab <- reactive({
      d <- AGG$laboral[geo == ctx()$geo & migrante == ctx()$migrante]
      d[, .(td = sum(desocupados) / sum(fuerza_trabajo) * 100,
            to = sum(ocupados) / sum(pet) * 100), by = anio][order(anio)]
    })
    serie_pob <- reactive({
      AGG$sexo[geo == ctx()$geo & migrante == ctx()$migrante][
        , .(pob = sum(personas)), by = anio][order(anio)]
    })

    output$kpis <- renderUI({
      s <- serie_lab(); p <- serie_pob()
      if (!nrow(s)) return(NULL)
      a1 <- min(s$anio); a2 <- max(s$anio)
      d_td  <- s[anio == a2, td] - s[anio == a1, td]
      d_pob <- p[anio == a2, pob] - p[anio == a1, pob]
      flecha <- function(x, inv = FALSE) {
        if (is.na(x)) return("")
        up <- x >= 0
        paste0(if (up) "▲ " else "▼ ", abs(round(x, 1)))
      }
      kpi_row(
        kpi_box(paste0("Población ", a2), fmt_num(p[anio == a2, pob]),
                paste0(flecha(d_pob / 1e6), " M vs ", a1)),
        kpi_box(paste0("Desempleo ", a2), fmt_pct(s[anio == a2, td]),
                paste0(flecha(d_td), " pp vs ", a1)),
        kpi_box("Periodo", paste0(a1, "–", a2), "4 años GEIH")
      )
    })

    output$tasas <- renderPlotly({
      s <- serie_lab()
      validate(need(nrow(s) > 0, "Sin datos para esta selección"))
      plot_ly(s, x = ~anio) %>%
        add_trace(y = ~td, name = "Desempleo", type = "scatter", mode = "lines+markers",
                  line = list(color = BRAND$primary, width = 3), marker = list(color = BRAND$primary, size = 9),
                  hovertemplate = "%{x}: %{y:.1f}%<extra>Desempleo</extra>") %>%
        add_trace(y = ~to, name = "Ocupación", type = "scatter", mode = "lines+markers",
                  line = list(color = BRAND$cyan, width = 3), marker = list(color = BRAND$cyan, size = 9),
                  hovertemplate = "%{x}: %{y:.1f}%<extra>Ocupación</extra>") %>%
        aplicar_tema(xaxis = list(title = "", dtick = 1, tickformat = "d"),
                     yaxis = list(title = "%", ticksuffix = "%"),
                     legend = list(orientation = "h", x = 0.5, xanchor = "center", y = 1.14),
                     margin = list(l = 50, r = 20, t = 30, b = 34)) %>% sin_barra()
    })

    output$poblacion <- renderPlotly({
      p <- serie_pob()
      validate(need(nrow(p) > 0, "Sin datos para esta selección"))
      plot_ly(p, x = ~anio, y = ~pob, type = "scatter", mode = "lines+markers",
              fill = "tozeroy", fillcolor = "rgba(6,182,212,0.12)",
              line = list(color = BRAND$cyan, width = 3), marker = list(color = BRAND$cyan, size = 9),
              text = ~vapply(pob, fmt_num, character(1)),
              hovertemplate = "%{x}: %{text}<extra>Población</extra>") %>%
        aplicar_tema(xaxis = list(title = "", dtick = 1, tickformat = "d"),
                     yaxis = list(title = "Personas", tickformat = ".2s"),
                     margin = list(l = 60, r = 20, t = 20, b = 34)) %>% sin_barra()
    })
  })
}
