############################################################
# modules/mod_educacion.R — Pestaña Educación
# KPIs + nivel educativo alcanzado + ingreso por nivel.
############################################################

educacionUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("kpis")),
    fluidRow(
      column(6, div(class = "card-panel",
                    div(class = "card-title", "Nivel educativo alcanzado"),
                    plotlyOutput(ns("nivel"), height = "440px"))),
      column(6, div(class = "card-panel",
                    div(class = "card-title", "Ingreso laboral por nivel educativo"),
                    plotlyOutput(ns("ingreso"), height = "440px")))
    )
  )
}

educacionServer <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {

    output$kpis <- renderUI({
      d <- filtrar("educacion", ctx())
      if (!nrow(d)) return(NULL)
      sup <- c("Universitaria", "Especialización", "Maestría", "Doctorado")
      pct_sup <- sum(d[nivel_educativo %in% sup, personas]) / sum(d$personas) * 100
      di <- filtrar("ingreso_educacion", ctx())
      ing_u <- di[nivel_educativo == "Universitaria", ingreso]
      da <- filtrar("alfabetismo", ctx())
      analf <- if (nrow(da)) sum(da[alfabetismo == "No", personas]) / sum(da$personas) * 100 else NA
      media <- c("Media académica", "Media técnica", "Normalista", "Técnica prof.",
                 "Tecnológica", "Universitaria", "Especialización", "Maestría", "Doctorado")
      pct_media <- sum(d[nivel_educativo %in% media, personas]) / sum(d$personas) * 100
      kpi_row(
        kpi_box("Educación media o más", fmt_pct(pct_media), "bachiller o superior"),
        kpi_box("Educación superior", fmt_pct(pct_sup), "universitaria o más"),
        kpi_box("Analfabetismo", fmt_pct(analf), "población 15+ años"),
        kpi_box("Ingreso universitario", fmt_pesos(ing_u), "promedio mensual")
      )
    })

    output$nivel <- renderPlotly({
      d <- filtrar("educacion", ctx())[order(personas)]
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      plot_ly(d, x = ~personas, y = ~factor(nivel_educativo, levels = nivel_educativo),
              type = "bar", orientation = "h",
              marker = list(color = d$personas,
                            colorscale = list(c(0, BRAND$violet), c(1, BRAND$cyan)), line = list(width = 0)),
              text = ~format(round(personas), big.mark = ","), textposition = "auto",
              textfont = list(color = "#fff", family = FUENTE),
              hovertemplate = "%{y}: %{x:,.0f}<extra></extra>") %>%
        aplicar_tema(xaxis = list(title = "Personas"), yaxis = list(title = ""),
                     margin = list(l = 150, r = 20, t = 10, b = 36)) %>% sin_barra()
    })

    output$ingreso <- renderPlotly({
      d <- filtrar("ingreso_educacion", ctx())[order(ingreso)]
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      plot_ly(d, x = ~ingreso, y = ~factor(nivel_educativo, levels = nivel_educativo),
              type = "bar", orientation = "h",
              marker = list(color = d$ingreso,
                            colorscale = list(c(0, BRAND$violet), c(1, BRAND$cyan)), line = list(width = 0)),
              text = ~paste0("$", format(round(ingreso), big.mark = ",")), textposition = "auto",
              textfont = list(color = "#fff", family = FUENTE),
              hovertemplate = "%{y}: $%{x:,.0f}<extra></extra>") %>%
        aplicar_tema(xaxis = list(title = "Ingreso medio (COP)"), yaxis = list(title = ""),
                     margin = list(l = 150, r = 20, t = 10, b = 36)) %>% sin_barra()
    })
  })
}
