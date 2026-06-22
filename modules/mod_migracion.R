############################################################
# modules/mod_migracion.R — Pestaña Migración (población venezolana)
# Esta pestaña SIEMPRE caracteriza a los migrantes venezolanos,
# sin importar el filtro de población. Muestra motivos de migración.
############################################################

migracionUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("kpis")),
    fluidRow(
      column(7, div(class = "card-panel",
                    div(class = "card-title", "Motivos de migración"),
                    plotlyOutput(ns("motivos"), height = "430px"))),
      column(5, div(class = "card-panel",
                    div(class = "card-title", "Migrantes por sexo"),
                    plotlyOutput(ns("sexo"), height = "430px")))
    ),
    fluidRow(column(12, tendencia_card(ns("tendencia"), "Migrantes venezolanos 2022–2025")))
  )
}

migracionServer <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {

    # Fuerza el contexto a población venezolana
    ctxm <- reactive({ c <- ctx(); c$migrante <- "Venezolano"; c })

    output$kpis <- renderUI({
      ds <- filtrar("sexo", ctxm())
      if (!nrow(ds)) return(NULL)
      dm <- filtrar("motivos_migracion", ctxm())
      motivo <- if (nrow(dm)) dm[order(-personas)][1, motivo_migracion] else "—"
      kpi_row(
        kpi_box("Migrantes venezolanos", fmt_num(sum(ds$personas)), "promedio mensual"),
        kpi_box("Mujeres", fmt_pct(ds[sexo == "Mujer", pct])),
        kpi_box("Principal motivo", motivo)
      )
    })

    output$tendencia <- renderPlotly({
      s <- AGG$sexo[geo == ctxm()$geo & migrante == "Venezolano"][
        , .(valor = sum(personas)), by = anio]
      validate(need(nrow(s) > 1, "Sin serie temporal"))
      grafico_tendencia(s, es_pct = FALSE, etiqueta = "Migrantes")
    })

    output$motivos <- renderPlotly({
      d <- filtrar("motivos_migracion", ctxm())[order(personas)]
      validate(need(nrow(d) > 0, "Sin datos de motivos para esta selección"))
      plot_ly(d, x = ~personas, y = ~factor(motivo_migracion, levels = motivo_migracion),
              type = "bar", orientation = "h",
              marker = list(color = d$personas,
                            colorscale = list(c(0, BRAND$violet), c(1, BRAND$cyan)), line = list(width = 0)),
              text = ~format(round(personas), big.mark = ","), textposition = "auto",
              textfont = list(color = "#fff", family = FUENTE),
              hovertemplate = "%{y}: %{x:,.0f}<extra></extra>") %>%
        aplicar_tema(xaxis = list(title = "Personas"), yaxis = list(title = ""),
                     margin = list(l = 150, r = 20, t = 10, b = 36)) %>% sin_barra()
    })

    output$sexo <- renderPlotly({
      d <- filtrar("sexo", ctxm())
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      plot_ly(d, labels = ~sexo, values = ~personas, type = "pie", hole = 0.55, sort = FALSE,
              marker = list(colors = unname(COLOR_SEXO[d$sexo]), line = list(color = BRAND$bg, width = 3)),
              textinfo = "label+percent", insidetextfont = list(color = "#fff", size = 15, family = FUENTE),
              hovertemplate = "%{label}: %{value:,.0f}<extra></extra>") %>%
        layout(font = list(family = FUENTE, color = BRAND$text_body), showlegend = FALSE,
               plot_bgcolor = "rgba(0,0,0,0)", paper_bgcolor = "rgba(0,0,0,0)",
               margin = list(l = 10, r = 10, t = 10, b = 10),
               annotations = list(text = "Sexo", showarrow = FALSE,
                                  font = list(color = BRAND$text_muted, size = 14, family = FUENTE))) %>%
        config(displayModeBar = FALSE)
    })
  })
}
