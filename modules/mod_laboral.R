############################################################
# modules/mod_laboral.R — Pestaña Mercado Laboral
# KPIs + tasas por sexo + tipo de trabajo.
############################################################

laboralUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("kpis")),
    fluidRow(
      column(5, div(class = "card-panel",
                    div(class = "card-title", "Tasas por sexo"),
                    plotlyOutput(ns("tasas"), height = "420px"))),
      column(7, div(class = "card-panel",
                    div(class = "card-title", "Tipo de trabajo"),
                    plotlyOutput(ns("tipo"), height = "420px")))
    )
  )
}

laboralServer <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {

    output$kpis <- renderUI({
      d <- filtrar("laboral", ctx())
      if (!nrow(d)) return(NULL)
      td <- sum(d$desocupados) / sum(d$fuerza_trabajo) * 100
      to <- sum(d$ocupados) / sum(d$pet) * 100
      kpi_row(
        kpi_box("Tasa de desempleo", fmt_pct(td)),
        kpi_box("Tasa de ocupación", fmt_pct(to)),
        kpi_box("Ocupados", fmt_num(sum(d$ocupados)), "promedio mensual")
      )
    })

    # Tasas de desempleo y ocupación por sexo
    output$tasas <- renderPlotly({
      d <- filtrar("laboral", ctx())
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      plot_ly(d, x = ~sexo, y = ~round(tasa_desempleo, 1), type = "bar", name = "Desempleo",
              marker = list(color = BRAND$primary),
              text = ~paste0(round(tasa_desempleo, 1), "%"), textposition = "outside",
              textfont = list(color = BRAND$text_body, family = FUENTE),
              hovertemplate = "%{x} · desempleo: %{y:.1f}%<extra></extra>") %>%
        add_trace(y = ~round(tasa_ocupacion, 1), name = "Ocupación",
                  marker = list(color = BRAND$cyan),
                  text = ~paste0(round(tasa_ocupacion, 1), "%"),
                  hovertemplate = "%{x} · ocupación: %{y:.1f}%<extra></extra>") %>%
        aplicar_tema(xaxis = list(title = ""), yaxis = list(title = "%", ticksuffix = "%"),
                     legend = list(orientation = "h", x = 0.5, xanchor = "center", y = 1.12),
                     margin = list(l = 50, r = 20, t = 28, b = 30), barmode = "group") %>% sin_barra()
    })

    # Tipo de trabajo (posición ocupacional)
    output$tipo <- renderPlotly({
      d <- filtrar("tipo_trabajo", ctx())[order(personas)]
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      plot_ly(d, x = ~personas, y = ~factor(posicion_ocupacional, levels = posicion_ocupacional),
              type = "bar", orientation = "h",
              marker = list(color = d$personas,
                            colorscale = list(c(0, BRAND$violet), c(1, BRAND$cyan)), line = list(width = 0)),
              text = ~format(round(personas), big.mark = ","), textposition = "auto",
              textfont = list(color = "#fff", family = FUENTE),
              hovertemplate = "%{y}: %{x:,.0f}<extra></extra>") %>%
        aplicar_tema(xaxis = list(title = "Personas"), yaxis = list(title = ""),
                     margin = list(l = 175, r = 20, t = 10, b = 36)) %>% sin_barra()
    })
  })
}
