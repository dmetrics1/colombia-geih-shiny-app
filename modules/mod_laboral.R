############################################################
# modules/mod_laboral.R — Pestaña Mercado Laboral
# KPIs + tasas por sexo + tipo de trabajo.
############################################################

laboralUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("kpis")),
    fluidRow(column(12, tendencia_card(ns("tendencia"),
                    "Tasas laborales 2022–2025 (TGP · TO · TD, trimestral)"))),
    fluidRow(
      column(5, div(class = "card-panel",
                    div(class = "card-title", "Tasas por sexo"),
                    plotlyOutput(ns("tasas"), height = "420px"))),
      column(7, div(class = "card-panel",
                    div(class = "card-title", "Tipo de trabajo"),
                    plotlyOutput(ns("tipo"), height = "420px")))
    ),
    fluidRow(
      column(7, div(class = "card-panel",
                    div(class = "card-title", "Rama de actividad económica"),
                    plotlyOutput(ns("rama"), height = "430px"))),
      column(5, div(class = "card-panel",
                    div(class = "card-title", "Ingreso laboral por sexo"),
                    plotlyOutput(ns("brecha"), height = "430px")))
    )
  )
}

laboralServer <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {

    output$kpis <- renderUI({
      d <- filtrar("laboral", ctx())
      if (!nrow(d)) return(NULL)
      td  <- sum(d$desocupados) / sum(d$fuerza_trabajo) * 100
      to  <- sum(d$ocupados) / sum(d$pet) * 100
      tgp <- sum(d$fuerza_trabajo) / sum(d$pet) * 100
      kpi_row(
        kpi_box("Tasa de participación", fmt_pct(tgp), "TGP"),
        kpi_box("Tasa de ocupación", fmt_pct(to), "TO"),
        kpi_box("Tasa de desempleo", fmt_pct(td), "TD"),
        kpi_box("Ocupados", fmt_num(sum(d$ocupados)), "promedio mensual")
      )
    })

    # Tendencia trimestral: TGP, TO, TD (estilo DANE)
    output$tendencia <- renderPlotly({
      s <- AGG$serie_trim[geo == ctx()$geo & migrante == ctx()$migrante]
      validate(need(nrow(s) > 1, "Sin serie temporal"))
      s <- s[order(anio, trimestre)]
      s[, periodo := anio + (trimestre - 1) / 4]
      s[, tgp := (ocupados + desocupados) / pet * 100]
      s[, to  := ocupados / pet * 100]
      s[, td  := desocupados / (ocupados + desocupados) * 100]
      eje_x <- list(title = "", tickmode = "array", tickvals = ANIOS,
                    ticktext = as.character(ANIOS), gridcolor = BRAND$grid)
      plot_ly(s, x = ~periodo) %>%
        add_trace(y = ~tgp, name = "Participación (TGP)", type = "scatter", mode = "lines+markers",
                  line = list(color = BRAND$primary, width = 2.5), marker = list(color = BRAND$primary, size = 6),
                  hovertemplate = "TGP: %{y:.1f}%<extra></extra>") %>%
        add_trace(y = ~to, name = "Ocupación (TO)", type = "scatter", mode = "lines+markers",
                  line = list(color = BRAND$cyan, width = 2.5), marker = list(color = BRAND$cyan, size = 6),
                  hovertemplate = "TO: %{y:.1f}%<extra></extra>") %>%
        add_trace(y = ~td, name = "Desempleo (TD)", type = "scatter", mode = "lines+markers",
                  line = list(color = "#94A3B8", width = 2.5), marker = list(color = "#94A3B8", size = 6),
                  hovertemplate = "TD: %{y:.1f}%<extra></extra>") %>%
        aplicar_tema(xaxis = eje_x, yaxis = list(title = "%", ticksuffix = "%"),
                     legend = list(orientation = "h", x = 0.5, xanchor = "center", y = 1.16),
                     margin = list(l = 50, r = 20, t = 34, b = 28)) %>% sin_barra()
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

    # Rama de actividad económica (ocupados)
    output$rama <- renderPlotly({
      d <- filtrar("rama_economica", ctx())[order(personas)]
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      plot_ly(x = d$personas, y = factor(d$rama_actividad, levels = d$rama_actividad),
              type = "bar", orientation = "h",
              marker = list(color = d$personas,
                            colorscale = list(c(0, BRAND$violet), c(1, BRAND$cyan)), line = list(width = 0)),
              text = format(round(d$personas), big.mark = ","), textposition = "auto",
              textfont = list(color = "#fff", family = FUENTE),
              hovertemplate = "%{y}: %{x:,.0f} ocupados<extra></extra>") %>%
        aplicar_tema(xaxis = list(title = "Ocupados"), yaxis = list(title = ""),
                     margin = list(l = 185, r = 20, t = 10, b = 36)) %>% sin_barra()
    })

    # Ingreso laboral medio por sexo (brecha salarial de género)
    output$brecha <- renderPlotly({
      d <- filtrar("ingreso_sexo", ctx())
      validate(need(nrow(d) >= 2, "Sin datos para esta selección"))
      ih <- d[sexo == "Hombre", ingreso]; im <- d[sexo == "Mujer", ingreso]
      brecha <- (ih - im) / ih * 100
      plot_ly(d, x = ~sexo, y = ~ingreso, type = "bar",
              marker = list(color = unname(COLOR_SEXO[d$sexo])),
              text = ~paste0("$", format(round(ingreso), big.mark = ",")), textposition = "outside",
              textfont = list(color = BRAND$text_body, family = FUENTE),
              hovertemplate = "%{x}: $%{y:,.0f}<extra></extra>") %>%
        aplicar_tema(xaxis = list(title = ""), yaxis = list(title = "Ingreso medio (COP)", tickformat = ".2s"),
                     margin = list(l = 60, r = 16, t = 36, b = 28)) %>%
        layout(annotations = list(text = paste0("Brecha de género: ", round(brecha, 1), "%"),
                                  x = 0.5, xref = "paper", y = 1.12, yref = "paper", showarrow = FALSE,
                                  font = list(color = BRAND$cyan, size = 14, family = FUENTE))) %>%
        sin_barra()
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
