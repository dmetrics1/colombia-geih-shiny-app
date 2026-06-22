############################################################
# Fase 1 — Ingesta de la serie GEIH 2022-2025
# Los años YA vienen consolidados (datos/geih_AAAA.csv).
# Esta función reemplaza al antiguo merge mensual de
# funciones/join_geih.R (obsoleto): solo lee, selecciona,
# añade ANIO y apila.
############################################################
suppressMessages(library(data.table))

# Variables que el dashboard y las recodificaciones necesitan.
# (Lectura selectiva: evita cargar las 524 columnas en memoria.)
VARS_ANALISIS <- c(
  # Identificación y diseño muestral
  "DIRECTORIO","SECUENCIA_P","ORDEN","HOGAR","FEX_C18","DPTO","AREA","MES","PERIODO","PER",
  # Demografía
  "P6040","P3271","P6070","P6050",
  # Educación e ingreso
  "P3042","P6170","P6160","INGLABO",
  # Mercado laboral
  "OCI","DSI","PT","FT","PET","P6430","P6880","P6920","RAMA2D_R4",
  # Vivienda y hogar (P6050 = parentesco, para identificar jefe de hogar)
  "P5090","P4030S1","P4030S2","P4030S3","P4030S5","P6008","P70",
  "P4010","P4020","P5020","P5030",
  # Salud
  "P6090","P6100",
  # Migración
  "P3373S3","P3374S1","P3374S2","P3374S3","P3386"
)

# Lee un año, selecciona columnas disponibles y añade ANIO.
cargar_anio <- function(anio, vars = VARS_ANALISIS) {
  f <- sprintf("datos/geih_%d.csv", anio)
  stopifnot(file.exists(f))
  disp <- intersect(vars, names(fread(f, nrows = 0)))
  dt <- fread(f, select = disp)
  dt[, ANIO := anio]
  dt[]
}

# Apila los años indicados en un solo data.table.
cargar_serie <- function(anios = 2022:2025, vars = VARS_ANALISIS) {
  rbindlist(lapply(anios, cargar_anio, vars = vars), use.names = TRUE, fill = TRUE)
}

# Uso:
#   source("preparacion/cargar_anios.R")
#   geih <- cargar_serie()              # toda la serie 2022-2025
#   geih <- cargar_serie(2024)          # un solo año
