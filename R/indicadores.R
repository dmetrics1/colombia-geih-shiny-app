############################################################
# R/indicadores.R — Caracterizaciones unificadas
#
# Una función por indicador, sirve a nivel NACIONAL (depto=NULL)
# o DEPARTAMENTAL (depto="Magdalena"). Unifica las ~25 funciones
# duplicadas de caracterizacion_nacional/_departamento en ~11.
# Requiere R/aggregate.R (n_periodos, conteo_ponderado) y datos
# ya etiquetados con R/recodes.R (etiquetar_geih).
############################################################
suppressMessages(library(data.table))

# Filtra por departamento si se indica.
.filtra <- function(dt, depto) if (is.null(depto)) dt else dt[departamento == depto]

# Restringe a JEFES de hogar (P6050 == 1): 1 registro por hogar.
# Necesario para indicadores de vivienda/hogar (no contar por persona).
.hogares <- function(dt) dt[P6050 == 1]

# 1. Pirámide poblacional (grupo_edad × sexo)
piramide <- function(dt, depto = NULL) {
  dt <- .filtra(dt, depto)
  res <- conteo_ponderado(dt[!is.na(grupo_edad) & !is.na(sexo)], by = c("grupo_edad", "sexo"))
  res[, pct := personas / sum(personas) * 100]
  res[]
}

# 2. Distribución por sexo
sexo_dist <- function(dt, depto = NULL) {
  dt <- .filtra(dt, depto)
  res <- conteo_ponderado(dt[!is.na(sexo)], by = "sexo")
  res[, pct := round(personas / sum(personas) * 100, 1)][]
}

# 3. Estado civil
estado_civil <- function(dt, depto = NULL) {
  dt <- .filtra(dt, depto)
  conteo_ponderado(dt[!is.na(estado_civil)], by = "estado_civil")[order(-personas)]
}

# 4. Nivel educativo
educacion <- function(dt, depto = NULL) {
  dt <- .filtra(dt, depto)
  conteo_ponderado(dt[!is.na(nivel_educativo)], by = "nivel_educativo")[order(-personas)]
}

# 4b. Alfabetismo en población de 15 años y más (P6160)
alfabetismo <- function(dt, depto = NULL) {
  dt <- .filtra(dt, depto)
  conteo_ponderado(dt[P6040 >= 15 & !is.na(alfabetismo)], by = "alfabetismo")[order(-personas)]
}

# 5. Ingreso laboral medio por nivel educativo (media PONDERADA)
ingreso_educacion <- function(dt, depto = NULL) {
  dt <- .filtra(dt, depto)
  dt[!is.na(nivel_educativo) & !is.na(INGLABO),
     .(ingreso = sum(INGLABO * FEX_C18, na.rm = TRUE) / sum(FEX_C18, na.rm = TRUE)),
     by = nivel_educativo][order(-ingreso)]
}

# 6. Mercado laboral por sexo (ocupados, desocupados, tasas)
laboral <- function(dt, depto = NULL) {
  dt <- .filtra(dt, depto)[!is.na(sexo)]
  np <- n_periodos(dt)
  out <- dt[, .(
    ocupados    = sum(OCI * FEX_C18, na.rm = TRUE) / np,
    desocupados = sum(DSI * FEX_C18, na.rm = TRUE) / np,
    pet         = sum((P6040 >= 15) * FEX_C18, na.rm = TRUE) / np
  ), by = sexo]
  out[, fuerza_trabajo := ocupados + desocupados]
  out[, tasa_desempleo := desocupados / fuerza_trabajo * 100]
  out[, tasa_ocupacion := ocupados / pet * 100]
  out[]
}

# 7. Tipo de trabajo (posición ocupacional)
tipo_trabajo <- function(dt, depto = NULL) {
  dt <- .filtra(dt, depto)
  conteo_ponderado(dt[!is.na(posicion_ocupacional)], by = "posicion_ocupacional")[order(-personas)]
}

# 7b. Rama de actividad económica (solo ocupados)
rama_economica <- function(dt, depto = NULL) {
  dt <- .filtra(dt, depto)
  conteo_ponderado(dt[OCI == 1 & !is.na(rama_actividad)], by = "rama_actividad")[order(-personas)]
}

# 7c. Ingreso laboral medio por sexo (brecha salarial de género; ponderado, ocupados)
ingreso_sexo <- function(dt, depto = NULL) {
  dt <- .filtra(dt, depto)
  dt[OCI == 1 & !is.na(INGLABO) & !is.na(sexo),
     .(ingreso = sum(INGLABO * FEX_C18, na.rm = TRUE) / sum(FEX_C18, na.rm = TRUE)), by = sexo]
}

# --- Indicadores de VIVIENDA/HOGAR (a nivel de hogar = jefe, no persona) -----

# 8. Tenencia de la vivienda (por hogar)
tipo_vivienda <- function(dt, depto = NULL) {
  dt <- .hogares(.filtra(dt, depto))
  conteo_ponderado(dt[!is.na(tenencia_vivienda)], by = "tenencia_vivienda")[order(-personas)]
}

# 9. Condiciones del hogar: % de HOGARES con acceso a cada servicio público
condiciones_hogar <- function(dt, depto = NULL) {
  h <- .hogares(.filtra(dt, depto))
  servicios <- c(electricidad = "P4030S1_lbl", gas = "P4030S2_lbl",
                 alcantarillado = "P4030S3_lbl", acueducto = "P4030S5_lbl")
  rbindlist(lapply(names(servicios), function(s) {
    col <- servicios[[s]]
    tot <- h[!is.na(get(col)), sum(FEX_C18, na.rm = TRUE)]
    si  <- h[get(col) == "Sí",  sum(FEX_C18, na.rm = TRUE)]
    data.table(servicio = s, porcentaje = round(si / tot * 100, 1))
  }))
}

# 9b. Material de paredes y pisos (por hogar)
material_paredes <- function(dt, depto = NULL) {
  dt <- .hogares(.filtra(dt, depto))
  conteo_ponderado(dt[!is.na(material_paredes)], by = "material_paredes")[order(-personas)]
}
material_pisos <- function(dt, depto = NULL) {
  dt <- .hogares(.filtra(dt, depto))
  conteo_ponderado(dt[!is.na(material_pisos)], by = "material_pisos")[order(-personas)]
}

# 9c. Servicio sanitario (por hogar)
sanitario <- function(dt, depto = NULL) {
  dt <- .hogares(.filtra(dt, depto))
  conteo_ponderado(dt[!is.na(sanitario_tipo)], by = "sanitario_tipo")[order(-personas)]
}

# 10. Acceso a salud
acceso_salud <- function(dt, depto = NULL) {
  dt <- .filtra(dt, depto)
  conteo_ponderado(dt[!is.na(acceso_salud)], by = "acceso_salud")[order(-personas)]
}

# 11. Afiliación al sistema de salud
afiliacion_salud <- function(dt, depto = NULL) {
  dt <- .filtra(dt, depto)
  conteo_ponderado(dt[!is.na(afiliacion_salud)], by = "afiliacion_salud")[order(-personas)]
}

# 12. Motivos de migración (P3386; aplica a la población migrante)
motivos_migracion <- function(dt, depto = NULL) {
  dt <- .filtra(dt, depto)
  conteo_ponderado(dt[!is.na(motivo_migracion) & motivo_migracion != ""],
                   by = "motivo_migracion")[order(-personas)]
}
