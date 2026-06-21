############################################################
# Fase 2 — Demostración del fix del divisor
# Cuantifica el bug del `/7` y valida el divisor dinámico
# contra la baseline (2024 = 51.55 M).
############################################################
suppressMessages(library(data.table))
source("R/aggregate.R")

# --- 2024: bug del /7 vs divisor dinámico ---
d24 <- fread("datos/geih_2024.csv", select = c("FEX_C18", "MES"))
nm  <- n_periodos(d24)
pob7   <- sum(d24$FEX_C18, na.rm = TRUE) / 7    # divisor hardcodeado (viejo)
pobdyn <- poblacion_ponderada(d24)              # divisor dinámico (correcto)

cat("== 2024 ==\n")
cat(sprintf("  Meses detectados: %d\n", nm))
cat(sprintf("  Poblacion con /7 (VIEJO, incorrecto): %s\n", format(round(pob7),  big.mark = ",")))
cat(sprintf("  Poblacion dinamica (CORRECTO):        %s\n", format(round(pobdyn), big.mark = ",")))
cat(sprintf("  Factor de inflacion del /7:           %.2fx\n", pob7 / pobdyn))
cat(sprintf("  Coincide con baseline (51,551,004)?   %s\n",
            ifelse(abs(round(pobdyn) - 51551004) < 5, "SI", "NO")))

# --- Serie 2022-2025: n_periodos debe detectar 48 ---
serie <- rbindlist(lapply(2022:2025, function(a) {
  x <- fread(sprintf("datos/geih_%d.csv", a), select = c("FEX_C18", "MES"))
  x[, ANIO := a][]
}))
cat("\n== Serie 2022-2025 ==\n")
cat(sprintf("  n_periodos() = %d (esperado 48)\n", n_periodos(serie)))
cat(sprintf("  Poblacion prom. mensual de la serie: %s\n",
            format(round(poblacion_ponderada(serie)), big.mark = ",")))
