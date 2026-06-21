############################################################
# Fase 3 — Validación de la capa refactorizada (recodes + indicadores)
# contra la baseline 2024 (48.6% H / 51.4% M, TD ~10.2%).
############################################################
suppressMessages(library(data.table))
source("R/aggregate.R")
source("R/recodes.R")
source("R/indicadores.R")
source("preparacion/cargar_anios.R")

geih <- cargar_anio(2024)          # un año, columnas de análisis
etiquetar_geih(geih)
es_migrante_venezolano(geih)

cat("== Sexo (nacional) ==\n");        print(sexo_dist(geih))
cat("\n== Estado civil (top) ==\n");   print(head(estado_civil(geih), 3))
cat("\n== Educación (top) ==\n");      print(head(educacion(geih), 3))

lab <- laboral(geih)
td_nac <- sum(lab$desocupados) / sum(lab$fuerza_trabajo) * 100
cat(sprintf("\n== Mercado laboral: TD nacional = %.1f%% (baseline 10.2%%) ==\n", td_nac))
print(lab[, .(sexo, tasa_desempleo = round(tasa_desempleo,1), tasa_ocupacion = round(tasa_ocupacion,1))])

cat("\n== Sexo (departamental: Magdalena) ==\n"); print(sexo_dist(geih, depto = "Magdalena"))

cat("\n== Migrantes venezolanos ==\n")
cat("  total ponderado:", format(round(poblacion_ponderada(geih[migrante_ven == TRUE])), big.mark=","), "\n")
cat("  sexo (migrantes):\n"); print(sexo_dist(geih[migrante_ven == TRUE]))

# Chequeo automático
ok_sexo <- abs(sexo_dist(geih)[sexo=="Mujer", pct] - 51.4) < 0.2
ok_td   <- abs(td_nac - 10.2) < 0.3
cat(sprintf("\nRESULTADO: sexo %s | TD %s\n",
            ifelse(ok_sexo,"OK","FALLA"), ifelse(ok_td,"OK","FALLA")))
