############################################################
# modules/mod_vivienda.R — Pestaña Vivienda
# Indicadores A NIVEL DE HOGAR (jefe de hogar), no por persona
# (metodología GEIH: los datos de vivienda/hogar se toman una vez).
# Tenencia, servicios públicos, materiales y servicio sanitario.
############################################################

# Barra horizontal de "hogares" por categoría (reutilizable)
.barra_hogares <- function(d, ycol, margin_l = 150) {
  d <- d[order(personas)]
  yvals <- factor(d[[ycol]], levels = d[[ycol]])
  plot_ly(x = d$personas, y = yvals, type = "bar", orientation = "h",
          marker = list(color = d$personas,
                        colorscale = list(c(0, BRAND$violet), c(1, BRAND$cyan)), line = list(width = 0)),
          text = format(round(d$personas), big.mark = ","), textposition = "auto",
          textfont = list(color = "#fff", family = FUENTE),
          hovertemplate = "%{y}: %{x:,.0f} hogares<extra></extra>") %>%
    aplicar_tema(xaxis = list(title = "Hogares"), yaxis = list(title = ""),
                 margin = list(l = margin_l, r = 20, t = 10, b = 36)) %>% sin_barra()
}

viviendaUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("kpis")),
    fluidRow(
      column(7, div(class = "card-panel",
                    div(class = "card-title", "Tenencia de la vivienda"),
                    plotlyOutput(ns("tenencia"), height = "400px"))),
      column(5, div(class = "card-panel",
                    div(class = "card-title", "Servicios públicos del hogar"),
                    plotlyOutput(ns("servicios"), height = "400px")))
    ),
    fluidRow(
      column(6, div(class = "card-panel",
                    div(class = "card-title", "Material de las paredes"),
                    plotlyOutput(ns("paredes"), height = "380px"))),
      column(6, div(class = "card-panel",
                    div(class = "card-title", "Material del piso"),
                    plotlyOutput(ns("pisos"), height = "380px")))
    ),
    fluidRow(
      column(12, div(class = "card-panel",
                     div(class = "card-title", "Servicio sanitario"),
                     plotlyOutput(ns("sanitario"), height = "360px")))
    )
  )
}

viviendaServer <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {

    output$kpis <- renderUI({
      d <- filtrar("tipo_vivienda", ctx())
      if (!nrow(d)) return(NULL)
      tot <- sum(d$personas)
      propia <- sum(d[tenencia_vivienda %in% c("Propia, pagada", "Propia, pagando"), personas])
      dc <- filtrar("condiciones_hogar", ctx())
      acue <- dc[servicio == "acueducto", porcentaje]
      ds <- filtrar("sanitario", ctx())
      alc <- if (nrow(ds)) sum(ds[sanitario_tipo == "Inodoro a alcantarillado", personas]) / sum(ds$personas) * 100 else NA
      kpi_row(
        kpi_box("Hogares", fmt_num(tot), "promedio mensual"),
        kpi_box("Vivienda propia", fmt_pct(propia / tot * 100), "pagada o pagando"),
        kpi_box("Con acueducto", fmt_pct(acue)),
        kpi_box("Inodoro a alcantarillado", fmt_pct(alc))
      )
    })

    output$tenencia <- renderPlotly({
      d <- filtrar("tipo_vivienda", ctx())
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      .barra_hogares(d, "tenencia_vivienda", margin_l = 160)
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
              hovertemplate = "%{y}: %{x:.1f}% de hogares<extra></extra>") %>%
        aplicar_tema(xaxis = list(title = "% de hogares", ticksuffix = "%", range = c(0, 100)),
                     yaxis = list(title = ""), margin = list(l = 120, r = 20, t = 10, b = 36)) %>% sin_barra()
    })

    output$paredes <- renderPlotly({
      d <- filtrar("material_paredes", ctx())
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      .barra_hogares(d, "material_paredes", margin_l = 150)
    })

    output$pisos <- renderPlotly({
      d <- filtrar("material_pisos", ctx())
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      .barra_hogares(d, "material_pisos", margin_l = 150)
    })

    output$sanitario <- renderPlotly({
      d <- filtrar("sanitario", ctx())
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      .barra_hogares(d, "sanitario_tipo", margin_l = 170)
    })
  })
}
