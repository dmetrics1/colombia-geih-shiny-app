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
