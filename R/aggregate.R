############################################################
# R/aggregate.R — Agregación ponderada con divisor DINÁMICO
#
# Reemplaza el antiguo `/ 7` hardcodeado (32 veces) por el
# nº REAL de periodos mensuales del subconjunto. Regla del
# instructivo §14: nunca dividir por un número fijo.
#
# La GEIH es una encuesta mensual; al sumar FEX_C18 sobre N
# meses se obtiene N veces la población media mensual. Para
# estimar el promedio mensual se divide por ese N.
############################################################
suppressMessages(library(data.table))

# Nº de periodos mensuales distintos en los datos.
#  - Varios años (hay ANIO): combinaciones ANIO×MES (p. ej. 48 en 2022-2025).
#  - Un solo periodo: meses distintos (p. ej. 12 en un año).
n_periodos <- function(dt) {
  stopifnot("MES" %in% names(dt))
  if ("ANIO" %in% names(dt)) uniqueN(dt[, .(ANIO, MES)]) else uniqueN(dt$MES)
}

# Población ponderada (promedio mensual) de TODO el subconjunto.
poblacion_ponderada <- function(dt, peso = "FEX_C18") {
  sum(dt[[peso]], na.rm = TRUE) / n_periodos(dt)
}

# Conteo ponderado (promedio mensual) de "personas" por grupo(s).
#   by: character vector de columnas de agrupación.
#   filtro_var: opcional, columna 0/1 (p. ej. OCI, DSI) a multiplicar por el peso.
conteo_ponderado <- function(dt, by, peso = "FEX_C18", filtro_var = NULL) {
  np <- n_periodos(dt)
  if (is.null(filtro_var)) {
    dt[, .(personas = sum(get(peso), na.rm = TRUE) / np), by = by]
  } else {
    dt[, .(personas = sum(get(filtro_var) * get(peso), na.rm = TRUE) / np), by = by]
  }
}

# Nota: en RAZONES (tasa de desempleo/ocupación, porcentajes) el divisor se
# cancela entre numerador y denominador; no es necesario aplicarlo allí.
