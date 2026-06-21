############################################################
# Fase 1 — Resumen cuantitativo por año (2022-2025)
# Lee columnas selectivas de cada CSV y valida magnitudes
# contra cifras oficiales (sanity check de la serie completa).
############################################################
suppressMessages(library(data.table))

anios <- 2022:2025
use   <- c("FEX_C18","MES","P3271","OCI","DSI","P3373S3","P3374S1")

res <- rbindlist(lapply(anios, function(a) {
  dt <- fread(sprintf("datos/geih_%d.csv", a), select = use)
  nmes  <- uniqueN(dt$MES)
  pob   <- sum(dt$FEX_C18, na.rm = TRUE) / nmes
  ocup  <- sum(dt$OCI * dt$FEX_C18, na.rm = TRUE)
  desoc <- sum(dt$DSI * dt$FEX_C18, na.rm = TRUE)
  td    <- desoc / (ocup + desoc) * 100
  # Migrantes venezolanos (código país 862 en P3373S3 y P3374S1)
  ven <- dt[P3373S3 == 862 & P3374S1 == 862,
            .(personas = sum(FEX_C18, na.rm = TRUE) / nmes)]$personas
  data.table(
    anio = a, filas = nrow(dt), meses = nmes,
    poblacion = round(pob),
    pct_desempleo = round(td, 1),
    migrantes_ven = round(ven)
  )
}))

cat("== Resumen de la serie GEIH 2022-2025 ==\n")
print(res)
fwrite(res, "tests/resumen_anual_2022_2025.csv")
cat("\nGuardado en tests/resumen_anual_2022_2025.csv\n")
