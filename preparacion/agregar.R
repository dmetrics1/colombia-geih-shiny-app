############################################################
# Fase 4 — Pre-agregación
#
# Precalcula TODAS las tablas que consume el dashboard, por
# año × geografía (Nacional + 33 deptos) × condición migratoria
# (Todos / Venezolano), usando las funciones validadas de
# R/indicadores.R. Resultado ligero -> datos/agregados.rds,
# que la app lee y solo filtra (sin microdato en memoria).
############################################################
suppressMessages(library(data.table))
source("R/aggregate.R")
source("R/recodes.R")
source("R/indicadores.R")
source("preparacion/cargar_anios.R")

ANIOS <- 2022:2025

# Indicadores a precalcular: nombre -> función(dt)
INDICADORES <- list(
  piramide          = piramide,
  sexo              = sexo_dist,
  estado_civil      = estado_civil,
  educacion         = educacion,
  ingreso_educacion = ingreso_educacion,
  laboral           = laboral,
  tipo_trabajo      = tipo_trabajo,
  tipo_vivienda     = tipo_vivienda,
  condiciones_hogar = condiciones_hogar,
  acceso_salud      = acceso_salud,
  afiliacion_salud  = afiliacion_salud,
  motivos_migracion = motivos_migracion
)

acc <- setNames(vector("list", length(INDICADORES)), names(INDICADORES))

push <- function(nombre, tbl, anio, geo, mig) {
  if (is.null(tbl) || nrow(tbl) == 0) return(invisible())
  tbl <- copy(tbl)[, `:=`(anio = anio, geo = geo, migrante = mig)]
  acc[[nombre]][[length(acc[[nombre]]) + 1]] <<- tbl
}

for (anio in ANIOS) {
  cat("Procesando", anio, "...\n")
  dt <- cargar_anio(anio)
  etiquetar_geih(dt)
  es_migrante_venezolano(dt)
  options(geih.n_periodos = uniqueN(dt$MES))   # divisor del periodo (=12)

  geos <- c("Nacional", sort(unique(na.omit(dt$departamento))))
  for (mig in c("Todos", "Venezolano")) {
    base <- if (mig == "Todos") dt else dt[migrante_ven == TRUE]
    for (g in geos) {
      sub <- if (g == "Nacional") base else base[departamento == g]
      if (nrow(sub) == 0) next
      for (nm in names(INDICADORES)) {
        res <- tryCatch(INDICADORES[[nm]](sub), error = function(e) NULL)
        push(nm, res, anio, g, mig)
      }
    }
  }
  options(geih.n_periodos = NULL)
  rm(dt); gc()
}

# Consolidar cada indicador en una sola tabla
agregados <- lapply(acc, rbindlist, fill = TRUE)

# Metadatos para la app
agregados$.meta <- list(
  anios = ANIOS,
  geos  = sort(unique(agregados$sexo$geo)),
  generado = "Fase 4"
)

saveRDS(agregados, "agregados.rds")   # en la raíz (versionable): lo consume la app

cat("\n== Agregados generados ==\n")
for (nm in names(INDICADORES))
  cat(sprintf("  %-18s %s filas\n", nm, format(nrow(agregados[[nm]]), big.mark = ",")))
sz <- file.info("agregados.rds")$size / 1024^2
cat(sprintf("\nagregados.rds -> %.2f MB\n", sz))
