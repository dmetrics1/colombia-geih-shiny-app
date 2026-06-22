############################################################
# R/helpers.R — Utilidades de formato y KPIs
############################################################

# Formatea números grandes: 51.6 M, 1,234, etc.
fmt_num <- function(x) {
  if (length(x) == 0 || is.na(x)) return("—")
  if (abs(x) >= 1e6) paste0(format(round(x / 1e6, 1), nsmall = 1, trim = TRUE), " M")
  else if (abs(x) >= 1e3) format(round(x / 1e3, 1), nsmall = 1, trim = TRUE) |> paste0(" mil")
  else format(round(x), big.mark = ",", trim = TRUE)
}
fmt_pct  <- function(x) if (length(x) == 0 || is.na(x)) "—" else paste0(format(round(x, 1), nsmall = 1, trim = TRUE), "%")
fmt_pesos <- function(x) if (length(x) == 0 || is.na(x)) "—" else paste0("$", fmt_num(x))

# Tarjeta KPI (número grande en cian).
kpi_box <- function(label, value, sub = NULL) {
  div(class = "kpi",
      div(class = "kpi-label", label),
      div(class = "kpi-value", value),
      if (!is.null(sub)) div(class = "kpi-sub", sub))
}

# Fila de KPIs (columnas iguales).
kpi_row <- function(...) {
  cajas <- list(...)
  w <- max(1, floor(12 / length(cajas)))
  div(class = "kpi-row",
      fluidRow(lapply(cajas, function(b) column(width = w, b))))
}

# Tarjeta de tendencia anual a todo el ancho (para insertar en una pestaña).
tendencia_card <- function(ns_id, titulo = "Tendencia 2022–2025") {
  div(class = "card-panel",
      div(class = "card-title", titulo),
      plotlyOutput(ns_id, height = "280px"))
}

# Gráfico de tendencia (línea + área) desde un data.table con columnas anio y valor.
grafico_tendencia <- function(df, es_pct = FALSE, etiqueta = "Valor") {
  df <- df[order(anio)]
  txt <- if (es_pct) paste0(format(round(df$valor, 1), nsmall = 1), "%")
         else vapply(df$valor, fmt_num, character(1))
  plot_ly(df, x = ~anio, y = ~valor, type = "scatter", mode = "lines+markers",
          fill = "tozeroy", fillcolor = "rgba(6,182,212,0.10)",
          line = list(color = BRAND$cyan, width = 3),
          marker = list(color = BRAND$cyan, size = 8),
          text = txt, hovertemplate = paste0("%{x}: %{text}<extra>", etiqueta, "</extra>")) %>%
    aplicar_tema(xaxis = list(title = "", dtick = 1, tickformat = "d"),
                 yaxis = list(title = "", ticksuffix = if (es_pct) "%" else "",
                              tickformat = if (es_pct) "" else ".2s"),
                 margin = list(l = 58, r = 16, t = 10, b = 30)) %>% sin_barra()
}
