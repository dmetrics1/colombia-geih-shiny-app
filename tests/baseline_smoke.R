############################################################
# Fase 0 — Baseline / smoke test sobre los datos nuevos
# Lee geih_2024.csv, valida estructura y ancla magnitudes
# contra cifras oficiales DANE (sanity check).
# Ponderación correcta: divisor = nº real de meses (uniqueN(MES)).
############################################################
suppressMessages(library(data.table))

f <- "datos/geih_2024.csv"
stopifnot(file.exists(f))

# Columnas clave (lectura selectiva para velocidad/memoria)
cols <- c("FEX_C18", "MES", "DPTO", "P3271", "OCI", "DSI", "P6040")
hdr  <- names(fread(f, nrows = 0))
use  <- intersect(cols, hdr)
faltan <- setdiff(cols, hdr)

cat("== Estructura ==\n")
cat("Columnas totales en el archivo:", length(hdr), "\n")
cat("Columnas clave presentes:", paste(use, collapse = ", "), "\n")
if (length(faltan)) cat("Columnas clave AUSENTES:", paste(faltan, collapse = ", "), "\n")

dt <- fread(f, select = use)
n_meses <- uniqueN(dt$MES)
cat("\n== Cobertura temporal ==\n")
cat("Filas:", format(nrow(dt), big.mark = ","), "\n")
cat("Meses distintos (uniqueN MES):", n_meses, "->", paste(sort(unique(dt$MES)), collapse = ","), "\n")

# Población promedio mensual 2024 (ponderada, divisor dinámico)
pob <- sum(dt$FEX_C18, na.rm = TRUE) / n_meses
cat("\n== Indicadores ancla (DANE) ==\n")
cat(sprintf("Poblacion promedio mensual 2024: %s  (DANE ~ 52 millones)\n",
            format(round(pob), big.mark = ",")))

# Distribucion por sexo (1=Hombre, 2=Mujer)
sx <- dt[!is.na(P3271), .(personas = sum(FEX_C18, na.rm = TRUE) / n_meses), by = P3271]
sx[, pct := round(personas / sum(personas) * 100, 1)]
cat("Distribucion por sexo (P3271):\n"); print(sx[order(P3271)])

# Tasa de desempleo nacional (el divisor se cancela en la razon)
if (all(c("OCI", "DSI") %in% use)) {
  ocup  <- sum(dt$OCI * dt$FEX_C18, na.rm = TRUE)
  desoc <- sum(dt$DSI * dt$FEX_C18, na.rm = TRUE)
  td <- desoc / (ocup + desoc) * 100
  cat(sprintf("Tasa de desempleo nacional 2024: %.1f%%  (DANE ~ 10%%)\n", td))
} else {
  ocup <- desoc <- td <- NA_real_
  cat("OCI/DSI no disponibles: no se calcula tasa de desempleo.\n")
}

# Guardar baseline reproducible
dir.create("tests", showWarnings = FALSE)
out <- data.table(
  indicador = c("anio", "filas", "meses", "poblacion_prom_mensual",
                "pct_hombres", "pct_mujeres", "tasa_desempleo"),
  valor = c(2024, nrow(dt), n_meses, round(pob),
            sx[P3271 == 1, pct], sx[P3271 == 2, pct],
            if (is.na(td)) NA else round(td, 2))
)
fwrite(out, "tests/baseline_2024.csv")
cat("\nBaseline guardada en tests/baseline_2024.csv\n")
