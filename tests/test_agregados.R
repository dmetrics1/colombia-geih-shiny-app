############################################################
# Fase 4 — Verificación de agregados.rds (simula el filtrado de la app)
############################################################
suppressMessages(library(data.table))
ag <- readRDS("agregados.rds")

cat("Indicadores:", paste(setdiff(names(ag), ".meta"), collapse=", "), "\n")
cat("Años:", paste(ag$.meta$anios, collapse=", "), "\n")
cat("Geografías:", length(ag$.meta$geos), "(Nacional + deptos)\n\n")

# Simula: Nacional, 2024, Todos -> sexo (debe dar 48.6/51.4)
cat("== Sexo | Nacional | 2024 | Todos ==\n")
print(ag$sexo[geo=="Nacional" & anio==2024 & migrante=="Todos", .(sexo, personas=round(personas), pct)])

# Simula: tendencia de desempleo nacional 2022-2025 (Todos)
cat("\n== Tendencia TD nacional (Todos) ==\n")
td <- ag$laboral[geo=="Nacional" & migrante=="Todos",
                 .(td = round(sum(desocupados)/sum(fuerza_trabajo)*100,1)), by=anio]
print(td[order(anio)])

# Simula: Magdalena, 2025, Solo venezolanos -> educacion top
cat("\n== Educación | Magdalena | 2025 | Venezolano (top 3) ==\n")
print(head(ag$educacion[geo=="Magdalena" & anio==2025 & migrante=="Venezolano"][order(-personas)], 3))
