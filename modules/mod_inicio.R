############################################################
# modules/mod_inicio.R — Hoja de inicio (landing)
# Portada institucional: identidad, objetivo, metodología,
# guía de uso y autoría. Usa los recursos de marca.
############################################################

.dim_card <- function(ic, titulo, desc) {
  div(class = "dim-card",
      div(class = "dim-ic", icon(ic)),
      div(div(class = "dim-t", titulo), div(class = "dim-d", desc)))
}

inicioUI <- function(id) {
  ns <- NS(id)
  div(class = "landing",

    # ---- Hero ----
    div(class = "hero",
        img(class = "hero-logo", src = "logo-blanco.svg", alt = "DM"),
        h1(class = "hero-title", "Observatorio ", span(class = "grad", "GEIH")),
        div(class = "hero-tag", "Gran Encuesta Integrada de Hogares · Colombia 2022–2025"),
        p(class = "hero-desc",
          "Tablero interactivo para explorar la caracterización ", strong("demográfica, educativa, "),
          strong("laboral, de vivienda, salud y migración"), " de la población colombiana y venezolana, ",
          "a partir de los microdatos oficiales de la GEIH del DANE."),
        uiOutput(ns("highlights"))
    ),

    # ---- Objetivo + Metodología ----
    fluidRow(
      column(6, div(class = "landing-card",
        div(class = "lc-title", icon("bullseye"), "Objetivo del sistema"),
        p(class = "lc-text",
          "Poner a disposición, de forma visual y accesible, los principales indicadores ",
          "sociodemográficos y del mercado laboral de Colombia. Permite comparar entre ",
          strong("años (2022–2025)"), ", entre ", strong("nivel nacional y departamental"),
          ", y filtrar por la ", strong("población migrante venezolana"),
          ", apoyando el análisis, la investigación y la toma de decisiones."))),
      column(6, div(class = "landing-card",
        div(class = "lc-title", icon("flask"), "Metodología"),
        tags$ul(class = "lc-list",
          tags$li(strong("Fuente:"), " GEIH — DANE (microdatos 2022–2025, 4 años)."),
          tags$li(strong("Ponderación:"), " factor de expansión ", tags$code("FEX_C18"),
                  " (promedio mensual; nunca conteos simples)."),
          tags$li(strong("Unidad de análisis:"), " persona, hogar o vivienda según el indicador ",
                  "(p. ej. tenencia y servicios se miden por hogar, no por persona)."),
          tags$li(strong("Tasas laborales:"), " definiciones oficiales DANE (TGP, TO, TD).")),
        div(class = "lc-foot", "Detalle en ", tags$code("docs/INDICADORES.md"))))
    ),

    # ---- Cómo usar ----
    div(class = "landing-section-title", "Cómo usar el dashboard"),
    div(class = "landing-sub",
        "Usa los filtros superiores (", strong("Año · Nivel territorial · Población"),
        ") para acotar el análisis; los gráficos y KPIs se actualizan al instante. ",
        "Cada menú agrupa una dimensión:"),
    fluidRow(
      column(4, .dim_card("users", "Demografía", "Pirámide poblacional, sexo y estructura de edad.")),
      column(4, .dim_card("graduation-cap", "Educación", "Nivel educativo, ingresos y analfabetismo.")),
      column(4, .dim_card("briefcase", "Mercado laboral", "Empleo, desempleo, ramas, ingresos y brecha de género."))
    ),
    fluidRow(
      column(4, .dim_card("building", "Vivienda", "Tenencia, servicios, materiales y sanitario (por hogar).")),
      column(4, .dim_card("heart-pulse", "Salud", "Acceso y tipo de afiliación al sistema de salud.")),
      column(4, .dim_card("plane-arrival", "Migración", "Población venezolana y motivos de migración."))
    ),
    fluidRow(
      column(4, .dim_card("table", "Datos", "Tablas interactivas descargables en CSV y Excel.")),
      column(8, div(class = "dim-card tip",
        div(class = "dim-ic", icon("lightbulb")),
        div(div(class = "dim-t", "Interpretación"),
            div(class = "dim-d", "Pasa el cursor sobre los gráficos para ver el detalle. ",
                "Los porcentajes y tasas son comparables entre periodos; los conteos están ",
                "expresados como promedio mensual ponderado."))))
    ),

    # ---- Footer / autoría ----
    div(class = "landing-footer",
        div(class = "lf-by", "Desarrollado por ", strong("Daniel Molina")),
        div(class = "lf-role", "Economista & Data Scientist"),
        div(class = "lf-links",
            tags$a(href = "https://www.linkedin.com/in/daniel-molina-b76a4323b/", target = "_blank", icon("linkedin-in")),
            tags$a(href = "https://github.com/dmetrics1", target = "_blank", icon("github"))),
        div(class = "lf-src", "Fuente de datos: DANE — Gran Encuesta Integrada de Hogares (GEIH)"))
  )
}

inicioServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$highlights <- renderUI({
      a <- max(AGG$.meta$anios)
      g <- function(k) AGG[[k]][geo == "Nacional" & anio == a & migrante == "Todos"]
      pob <- sum(g("sexo")$personas)
      lab <- g("laboral"); td <- sum(lab$desocupados) / sum(lab$fuerza_trabajo) * 100
      hog <- AGG$conteo_unidades[geo == "Nacional" & anio == a & migrante == "Todos"]$hogares
      ven <- sum(AGG$sexo[geo == "Nacional" & anio == a & migrante == "Venezolano"]$personas)
      hl <- function(v, l) div(class = "hl", div(class = "hl-v", v), div(class = "hl-l", l))
      div(class = "hl-row",
          hl(fmt_num(pob), paste0("Población ", a)),
          hl(fmt_num(hog), "Hogares"),
          hl(fmt_pct(td), "Tasa de desempleo"),
          hl(fmt_num(ven), "Migrantes venezolanos"))
    })
  })
}
