############################################################
# modules/mod_demografia.R — Pestaña Demografía
# Pirámide poblacional, distribución por sexo, estado civil.
# Estilo: tema de marca (R/plot_theme.R). Datos: agregados.rds.
############################################################

demografiaUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("kpis")),
    fluidRow(
      column(7, div(class = "card-panel",
                    div(class = "card-title", "Pirámide poblacional"),
                    plotlyOutput(ns("piramide"), height = "440px"))),
      column(5, div(class = "card-panel",
                    div(class = "card-title", "Distribución por sexo"),
                    plotlyOutput(ns("sexo"), height = "440px")))
    ),
    fluidRow(
      column(12, div(class = "card-panel",
                     div(class = "card-title", "Estado civil"),
                     plotlyOutput(ns("civil"), height = "360px")))
    ),
    fluidRow(column(12, tendencia_card(ns("tendencia"), "Población 2022–2025")))
  )
}

demografiaServer <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {

    # KPIs
    output$kpis <- renderUI({
      d <- filtrar("sexo", ctx())
      if (!nrow(d)) return(NULL)
      kpi_row(
        kpi_box("Población", fmt_num(sum(d$personas)), "promedio mensual"),
        kpi_box("Hombres", fmt_pct(d[sexo == "Hombre", pct])),
        kpi_box("Mujeres", fmt_pct(d[sexo == "Mujer", pct]))
      )
    })

    # Tendencia de población 2022-2025
    output$tendencia <- renderPlotly({
      s <- AGG$sexo[geo == ctx()$geo & migrante == ctx()$migrante][
        , .(valor = sum(personas)), by = anio]
      validate(need(nrow(s) > 1, "Sin serie temporal"))
      grafico_tendencia(s, es_pct = FALSE, etiqueta = "Población")
    })

    # Pirámide poblacional (hombres a la derecha, mujeres a la izquierda)
    output$piramide <- renderPlotly({
      d <- filtrar("piramide", ctx())
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      d[, grupo_edad := factor(grupo_edad, levels = NIVELES_EDAD)]
      h <- d[sexo == "Hombre"][order(grupo_edad)]
      m <- d[sexo == "Mujer"][order(grupo_edad)]
      plot_ly() %>%
        add_bars(y = h$grupo_edad, x = h$pct, name = "Hombre", orientation = "h",
                 marker = list(color = COLOR_SEXO[["Hombre"]]),
                 hovertemplate = "Hombre %{y}: %{x:.1f}%<extra></extra>") %>%
        add_bars(y = m$grupo_edad, x = -m$pct, name = "Mujer", orientation = "h",
                 marker = list(color = COLOR_SEXO[["Mujer"]]),
                 hovertemplate = "Mujer %{y}: %{customdata:.1f}%<extra></extra>",
                 customdata = m$pct) %>%
        aplicar_tema(
          xaxis = list(title = "% de la población", tickformat = ".0f",
                       ticksuffix = "%", tickvals = seq(-5, 5, 1),
                       ticktext = paste0(abs(seq(-5, 5, 1)), "%")),
          yaxis = list(title = "", categoryorder = "array", categoryarray = NIVELES_EDAD,
                       tickfont = list(family = FUENTE, color = BRAND$text_body, size = 10)),
          legend = list(orientation = "h", x = 0.5, xanchor = "center", y = 1.08),
          margin = list(l = 52, r = 16, t = 24, b = 36),
          barmode = "overlay"
        ) %>% sin_barra()
    })

    # Distribución por sexo (dona)
    output$sexo <- renderPlotly({
      d <- filtrar("sexo", ctx())
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      plot_ly(d, labels = ~sexo, values = ~personas, type = "pie", hole = 0.55,
              sort = FALSE, direction = "clockwise",
              marker = list(colors = unname(COLOR_SEXO[d$sexo]),
                            line = list(color = BRAND$bg, width = 3)),
              textinfo = "label+percent",
              insidetextfont = list(color = "#fff", size = 15, family = FUENTE),
              hovertemplate = "%{label}: %{value:,.0f}<extra></extra>") %>%
        layout(font = list(family = FUENTE, color = BRAND$text_body),
               showlegend = FALSE,
               plot_bgcolor = "rgba(0,0,0,0)", paper_bgcolor = "rgba(0,0,0,0)",
               margin = list(l = 10, r = 10, t = 10, b = 10),
               annotations = list(text = "Sexo", showarrow = FALSE,
                                  font = list(color = BRAND$text_muted, size = 14, family = FUENTE))) %>%
        config(displayModeBar = FALSE)
    })

    # Estado civil (barras horizontales)
    output$civil <- renderPlotly({
      d <- filtrar("estado_civil", ctx())[order(personas)]
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      plot_ly(d, x = ~personas, y = ~factor(estado_civil, levels = estado_civil),
              type = "bar", orientation = "h",
              marker = list(color = d$personas,
                            colorscale = list(c(0, BRAND$violet), c(1, BRAND$cyan)),
                            line = list(width = 0)),
              text = ~format(round(personas), big.mark = ","),
              textposition = "auto", textfont = list(color = "#fff", family = FUENTE),
              hovertemplate = "%{y}: %{x:,.0f}<extra></extra>") %>%
        aplicar_tema(
          xaxis = list(title = "Personas"),
          yaxis = list(title = ""),
          legend = list(), margin = list(l = 150, r = 24, t = 12, b = 36)
        ) %>% sin_barra()
    })
  })
}
