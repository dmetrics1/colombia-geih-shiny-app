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
    )
  )
}

demografiaServer <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {

    # KPIs: población total + estructura de edad
    output$kpis <- renderUI({
      ds <- filtrar("sexo", ctx())
      dp <- filtrar("piramide", ctx())
      if (!nrow(ds) || !nrow(dp)) return(NULL)
      ag <- dp[, .(p = sum(personas)), by = grupo_edad]
      tot   <- sum(ag$p)
      menor <- sum(ag[grupo_edad %in% c("0-4", "5-9", "10-14"), p])
      mayor <- sum(ag[grupo_edad %in% c("65-69", "70-74", "75-79", "80-84", "85+"), p])
      activa <- tot - menor - mayor
      dep <- (menor + mayor) / activa * 100
      kpi_row(
        kpi_box("Población", fmt_num(sum(ds$personas)), "promedio mensual"),
        kpi_box("Menores de 15", fmt_pct(menor / tot * 100), "de la población"),
        kpi_box("Adultos mayores (65+)", fmt_pct(mayor / tot * 100)),
        kpi_box("Razón de dependencia", format(round(dep, 1)), "por 100 en edad activa")
      )
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
