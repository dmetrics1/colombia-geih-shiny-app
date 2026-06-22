############################################################
# global.R — Carga única para la app v2
# Lee los agregados ligeros (NO microdato) y la capa visual.
############################################################
suppressMessages({
  library(shiny)
  library(shinydashboard)
  library(plotly)
  library(data.table)
  library(DT)
})

source("R/plot_theme.R")
source("R/helpers.R")

# Datos pre-agregados (0.29 MB) — generados por preparacion/agregar.R
AGG    <- readRDS("agregados.rds")
ANIOS  <- AGG$.meta$anios
DEPTOS <- setdiff(AGG$.meta$geos, "Nacional")

# Orden de grupos de edad para la pirámide
NIVELES_EDAD <- c("0-4","5-9","10-14","15-19","20-24","25-29","30-34","35-39",
                  "40-44","45-49","50-54","55-59","60-64","65-69","70-74",
                  "75-79","80-84","85+")

# Filtra una tabla de indicador por el contexto (año, geografía, migración)
filtrar <- function(indic, ctx) {
  AGG[[indic]][anio == ctx$anio & geo == ctx$geo & migrante == ctx$migrante]
}

# Módulos de la app
source("modules/mod_demografia.R")
source("modules/mod_educacion.R")
source("modules/mod_laboral.R")
source("modules/mod_vivienda.R")
source("modules/mod_salud.R")
source("modules/mod_migracion.R")
source("modules/mod_tendencias.R")
