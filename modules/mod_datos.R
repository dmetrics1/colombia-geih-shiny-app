############################################################
# modules/mod_datos.R — Pestaña Datos
# Tabla interactiva descargable (CSV/Excel) desde agregados.rds.
# Reemplaza los Excel generados a mano de la v1.
############################################################

TABLAS_DATOS <- c(
  "Población por sexo"     = "sexo",
  "Estado civil"           = "estado_civil",
  "Pirámide poblacional"   = "piramide",
  "Nivel educativo"        = "educacion",
  "Ingreso por educación"  = "ingreso_educacion",
  "Mercado laboral"        = "laboral",
  "Tipo de trabajo"        = "tipo_trabajo",
  "Tenencia de vivienda"   = "tipo_vivienda",
  "Servicios del hogar"    = "condiciones_hogar",
  "Acceso a salud"         = "acceso_salud",
  "Afiliación a salud"     = "afiliacion_salud",
  "Motivos de migración"   = "motivos_migracion"
)

datosUI <- function(id) {
  ns <- NS(id)
  div(class = "card-panel",
      div(class = "card-title", "Explorar y descargar datos"),
      fluidRow(
        column(6, selectInput(ns("tabla"), "Indicador", choices = TABLAS_DATOS)),
        column(6, div(class = "datos-dl",
                      downloadButton(ns("csv"), "CSV", class = "btn-limpiar"),
                      downloadButton(ns("xlsx"), "Excel", class = "btn-limpiar")))
      ),
      DT::DTOutput(ns("tabla_out")))
}

datosServer <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {

    tabla_data <- reactive({
      key <- input$tabla; req(key)
      d <- AGG[[key]][anio == ctx()$anio & geo == ctx()$geo & migrante == ctx()$migrante]
      d <- copy(d)
      num <- names(which(vapply(d, is.numeric, logical(1))))
      num <- setdiff(num, "anio")
      if (length(num)) d[, (num) := lapply(.SD, round, 1), .SDcols = num]
      d[]
    })

    output$tabla_out <- DT::renderDT({
      d <- tabla_data()
      validate(need(nrow(d) > 0, "Sin datos para esta selección"))
      DT::datatable(d, rownames = FALSE, class = "display compact",
                    options = list(pageLength = 12, dom = "tip"))
    })

    nombre_arch <- function(ext) paste0("geih_", input$tabla, "_", ctx()$anio, ".", ext)
    output$csv  <- downloadHandler(
      filename = function() nombre_arch("csv"),
      content  = function(f) utils::write.csv(tabla_data(), f, row.names = FALSE, fileEncoding = "UTF-8"))
    output$xlsx <- downloadHandler(
      filename = function() nombre_arch("xlsx"),
      content  = function(f) openxlsx::write.xlsx(tabla_data(), f))
  })
}
