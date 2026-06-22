############################################################
# modules/mod_salud.R — Pestaña Salud
# KPIs + acceso a salud + tipo de afiliación al sistema.
############################################################

saludUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("kpis")),
    fluidRow(
      column(5, div(class = "card-panel",
                    div(class = "card-title", "Acceso a salud"),
                    plotlyOutput(ns("acceso"), height = "430px"))),
      column(7, div(class = "card-panel",
                    div(class = "card-title", "Tipo de afiliación al sistema"),
                    plotlyOutput(ns("afiliacion"), height = "430px")))
    )
  )
}

saludServer <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {

    output$kpis <- renderUI({
      d <- filtrar("acceso_salud", ctx())
      if (!nrow(d)) return(NULL)
      cobertura <- sum(d[acceso_salud == "Sí", personas]) / sum(d$personas) * 100
      da <- filtrar("afiliacion_salud", ctx())
      tota <- sum(da$personas)
      contrib <- sum(da[afiliacion_salud == "Contributivo", personas]) / tota * 100
      subsid  <- sum(da[afiliacion_salud == "Subsidiado", personas]) / tota * 100
      kpi_row(
        kpi_box("Acceso a salud", fmt_pct(cobertura), "afiliados al sistema"),
        kpi_box("Régimen contributivo", fmt_pct(contrib)),
        kpi_box("Régimen subsidiado", fmt_pct(subsid))
      )
    })

    # Acceso a salud (dona)
    output$acceso <- renderPlotly({
      d <- filtrar("acceso_salud", ctx())
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      cols <- c("Sí" = BRAND$cyan, "No" = BRAND$primary, "No informa" = BRAND$surface_3)
      plot_ly(d, labels = ~acceso_salud, values = ~personas, type = "pie", hole = 0.55,
              sort = FALSE, marker = list(colors = unname(cols[d$acceso_salud]),
                                          line = list(color = BRAND$bg, width = 3)),
              textinfo = "label+percent", insidetextfont = list(color = "#fff", size = 14, family = FUENTE),
              hovertemplate = "%{label}: %{value:,.0f}<extra></extra>") %>%
        layout(font = list(family = FUENTE, color = BRAND$text_body), showlegend = FALSE,
               plot_bgcolor = "rgba(0,0,0,0)", paper_bgcolor = "rgba(0,0,0,0)",
               margin = list(l = 10, r = 10, t = 10, b = 10),
               annotations = list(text = "Salud", showarrow = FALSE,
                                  font = list(color = BRAND$text_muted, size = 14, family = FUENTE))) %>%
        config(displayModeBar = FALSE)
    })

    # Afiliación al sistema (barras)
    output$afiliacion <- renderPlotly({
      d <- filtrar("afiliacion_salud", ctx())[order(personas)]
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      plot_ly(d, x = ~personas, y = ~factor(afiliacion_salud, levels = afiliacion_salud),
              type = "bar", orientation = "h",
              marker = list(color = d$personas,
                            colorscale = list(c(0, BRAND$violet), c(1, BRAND$cyan)), line = list(width = 0)),
              text = ~format(round(personas), big.mark = ","), textposition = "auto",
              textfont = list(color = "#fff", family = FUENTE),
              hovertemplate = "%{y}: %{x:,.0f}<extra></extra>") %>%
        aplicar_tema(xaxis = list(title = "Personas"), yaxis = list(title = ""),
                     margin = list(l = 130, r = 20, t = 10, b = 36)) %>% sin_barra()
    })
  })
}
