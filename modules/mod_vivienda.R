############################################################
# modules/mod_vivienda.R — Pestaña Vivienda
# KPIs + tipo de vivienda (tenencia) + condiciones del hogar.
############################################################

viviendaUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("kpis")),
    fluidRow(
      column(7, div(class = "card-panel",
                    div(class = "card-title", "Tenencia de la vivienda"),
                    plotlyOutput(ns("tenencia"), height = "430px"))),
      column(5, div(class = "card-panel",
                    div(class = "card-title", "Servicios públicos del hogar"),
                    plotlyOutput(ns("servicios"), height = "430px")))
    ),
    fluidRow(column(12, tendencia_card(ns("tendencia"), "Vivienda propia 2022–2025")))
  )
}

viviendaServer <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {

    output$kpis <- renderUI({
      d <- filtrar("tipo_vivienda", ctx())
      if (!nrow(d)) return(NULL)
      tot <- sum(d$personas)
      propia <- sum(d[tenencia_vivienda %in% c("Propia, pagada", "Propia, pagando"), personas])
      arriendo <- sum(d[tenencia_vivienda == "Arriendo/subarriendo", personas])
      dc <- filtrar("condiciones_hogar", ctx())
      acue <- dc[servicio == "acueducto", porcentaje]
      kpi_row(
        kpi_box("Vivienda propia", fmt_pct(propia / tot * 100), "pagada o pagando"),
        kpi_box("En arriendo", fmt_pct(arriendo / tot * 100)),
        kpi_box("Con acueducto", fmt_pct(acue))
      )
    })

    output$tendencia <- renderPlotly({
      propia <- c("Propia, pagada", "Propia, pagando")
      s <- AGG$tipo_vivienda[geo == ctx()$geo & migrante == ctx()$migrante][
        , .(valor = sum(personas[tenencia_vivienda %in% propia]) / sum(personas) * 100), by = anio]
      validate(need(nrow(s) > 1, "Sin serie temporal"))
      grafico_tendencia(s, es_pct = TRUE, etiqueta = "% Propia")
    })

    output$tenencia <- renderPlotly({
      d <- filtrar("tipo_vivienda", ctx())[order(personas)]
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      plot_ly(d, x = ~personas, y = ~factor(tenencia_vivienda, levels = tenencia_vivienda),
              type = "bar", orientation = "h",
              marker = list(color = d$personas,
                            colorscale = list(c(0, BRAND$violet), c(1, BRAND$cyan)), line = list(width = 0)),
              text = ~format(round(personas), big.mark = ","), textposition = "auto",
              textfont = list(color = "#fff", family = FUENTE),
              hovertemplate = "%{y}: %{x:,.0f}<extra></extra>") %>%
        aplicar_tema(xaxis = list(title = "Personas"), yaxis = list(title = ""),
                     margin = list(l = 160, r = 20, t = 10, b = 36)) %>% sin_barra()
    })

    output$servicios <- renderPlotly({
      d <- filtrar("condiciones_hogar", ctx())
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      etq <- c(electricidad = "Energía eléctrica", gas = "Gas natural",
               alcantarillado = "Alcantarillado", acueducto = "Acueducto")
      d[, lbl := etq[servicio]]
      d <- d[order(porcentaje)]
      plot_ly(d, x = ~porcentaje, y = ~factor(lbl, levels = lbl),
              type = "bar", orientation = "h",
              marker = list(color = BRAND$cyan, line = list(width = 0)),
              text = ~paste0(round(porcentaje, 1), "%"), textposition = "auto",
              textfont = list(color = "#fff", family = FUENTE),
              hovertemplate = "%{y}: %{x:.1f}%<extra></extra>") %>%
        aplicar_tema(xaxis = list(title = "% de hogares", ticksuffix = "%", range = c(0, 100)),
                     yaxis = list(title = ""), margin = list(l = 120, r = 20, t = 10, b = 36)) %>% sin_barra()
    })
  })
}
