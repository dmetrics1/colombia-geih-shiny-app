############################################################
# R/recodes.R — Recodificación de variables GEIH
#
# Reemplaza los ~8 replacement_map_* sueltos y el fcase de
# departamentos de preparacion.R por UNA función central,
# basada en el protocolo del diccionario (códigos como texto,
# se crean columnas con nombre legible y se conserva el código).
#
# Convención: la columna cruda (P3271, ...) se conserva; se
# añade una columna con nombre semántico (sexo, ...).
############################################################
suppressMessages(library(data.table))

# --- Tablas de mapeo (código como texto -> etiqueta) -----------------------
.map_dpto <- c(
  "5"="Antioquia","8"="Atlántico","11"="Bogotá","13"="Bolívar","15"="Boyacá",
  "17"="Caldas","18"="Caquetá","19"="Cauca","20"="Cesar","23"="Córdoba",
  "25"="Cundinamarca","27"="Chocó","41"="Huila","44"="La Guajira","47"="Magdalena",
  "50"="Meta","52"="Nariño","54"="Norte de Santander","63"="Quindío","66"="Risaralda",
  "68"="Santander","70"="Sucre","73"="Tolima","76"="Valle del Cauca","81"="Arauca",
  "85"="Casanare","86"="Putumayo","88"="San Andrés y Providencia","91"="Amazonas",
  "94"="Guainía","95"="Guaviare","97"="Vaupés","99"="Vichada")

.map_sexo  <- c("1"="Hombre","2"="Mujer")
.map_civil <- c("1"="Unión <2 años","2"="Unión >2 años","3"="Casado(a)",
                "4"="Separado(a)/Divorciado(a)","5"="Viudo(a)","6"="Soltero(a)")
.map_educ  <- c("1"="Ninguno","2"="Preescolar","3"="Primaria","4"="Secundaria",
                "5"="Media académica","6"="Media técnica","7"="Normalista",
                "8"="Técnica prof.","9"="Tecnológica","10"="Universitaria",
                "11"="Especialización","12"="Maestría","13"="Doctorado","99"="No sabe")
.map_salud <- c("1"="Sí","2"="No","9"="No informa")
.map_afil  <- c("1"="Contributivo","2"="Especial","3"="Subsidiado","9"="No informa")
.map_ocup  <- c("1"="Empleado particular","2"="Empleado gobierno","3"="Empleado doméstico",
                "4"="Cuenta propia","5"="Empleador","6"="Familiar sin pago",
                "7"="Trabajador sin pago","8"="Jornalero","9"="Otro")
.map_viv   <- c("1"="Propia, pagada","2"="Propia, pagando","3"="Arriendo/subarriendo",
                "4"="Usufructo","5"="Posesión sin título","6"="Propiedad colectiva","7"="Otra")
.map_migra <- c("1"="Trabajo","2"="Estudio","3"="Salud","4"="Conflicto armado","5"="Violencia",
                "6"="Desastres","7"="Nuevo hogar","8"="Acompañar hogar","9"="Motivos culturales",
                "10"="Vivienda propia","12"="Otro")
.map_sino  <- c("1"="Sí","2"="No")
.map_pared <- c("1"="Ladrillo/bloque/prefab.","2"="Madera pulida","3"="Adobe/tapia pisada",
                "4"="Bahareque","5"="Madera burda","6"="Guadua","7"="Caña/vegetal",
                "8"="Zinc/desechos/plástico","9"="Sin paredes")
.map_piso  <- c("1"="Tierra/arena","2"="Cemento/gravilla","3"="Madera burda",
                "4"="Baldosa/ladrillo/vinilo","5"="Mármol","6"="Madera pulida","7"="Alfombra")
.map_sanit <- c("1"="Inodoro a alcantarillado","2"="Inodoro a pozo séptico","3"="Inodoro sin conexión",
                "4"="Letrina","5"="Bajamar","6"="Sin servicio sanitario")
.map_sanit_uso <- c("1"="Exclusivo del hogar","2"="Compartido")

# Aplica un mapeo (código->etiqueta) creando una columna nueva si la cruda existe.
.recode <- function(dt, cruda, nueva, mapa) {
  if (cruda %in% names(dt)) dt[, (nueva) := mapa[as.character(get(cruda))]]
  invisible(dt)
}

# --- Función principal -----------------------------------------------------
etiquetar_geih <- function(dt) {
  .recode(dt, "DPTO",    "departamento",   .map_dpto)
  .recode(dt, "P3271",   "sexo",           .map_sexo)
  .recode(dt, "P6070",   "estado_civil",   .map_civil)
  .recode(dt, "P3042",   "nivel_educativo",.map_educ)
  .recode(dt, "P6090",   "acceso_salud",   .map_salud)
  .recode(dt, "P6100",   "afiliacion_salud",.map_afil)
  .recode(dt, "P6430",   "posicion_ocupacional", .map_ocup)
  .recode(dt, "P5090",   "tenencia_vivienda",    .map_viv)
  .recode(dt, "P3386",   "motivo_migracion",     .map_migra)
  .recode(dt, "P4010",   "material_paredes",     .map_pared)
  .recode(dt, "P4020",   "material_pisos",       .map_piso)
  .recode(dt, "P5020",   "sanitario_tipo",       .map_sanit)
  .recode(dt, "P5030",   "sanitario_uso",        .map_sanit_uso)
  for (s in c("P4030S1","P4030S2","P4030S3","P4030S5"))
    .recode(dt, s, paste0(s, "_lbl"), .map_sino)

  # Grupo de edad quinquenal (para pirámide poblacional)
  if ("P6040" %in% names(dt)) {
    dt[, grupo_edad := cut(P6040,
        breaks = c(seq(0, 85, 5), Inf), right = FALSE,
        labels = c("0-4","5-9","10-14","15-19","20-24","25-29","30-34","35-39",
                   "40-44","45-49","50-54","55-59","60-64","65-69","70-74",
                   "75-79","80-84","85+"))]
  }
  invisible(dt)
}

# Marca de migrante venezolano (código país 862 en P3373S3 y P3374S1).
es_migrante_venezolano <- function(dt) {
  dt[, migrante_ven := !is.na(P3373S3) & !is.na(P3374S1) &
                       P3373S3 == 862 & P3374S1 == 862]
  invisible(dt)
}
