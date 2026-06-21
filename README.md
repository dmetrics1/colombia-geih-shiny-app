# Colombia GEIH Shiny App

### Interactive Visualization and Analysis of Colombia's GEIH Data — A Shiny Application for Reproducible Demographic and Labor Market Research

[![R](https://img.shields.io/badge/R-4.0+-276DC3?style=flat-square&logo=r&logoColor=white)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-2563EB?style=flat-square&logo=rstudioide&logoColor=white)](https://shiny.posit.co/)
[![License](https://img.shields.io/github/license/dmetrics1/colombia-geih-shiny-app?style=flat-square&color=7C3AED)](LICENSE)
[![Live App](https://img.shields.io/badge/Live%20App-06B6D4?style=flat-square&logo=rstudio&logoColor=white)](https://jsidte-daniel-molina.shinyapps.io/shiny-app/)
[![DOI](https://img.shields.io/badge/DOI-10.1007%2F978--3--032--18455--9__8-10B981?style=flat-square)](https://doi.org/10.1007/978-3-032-18455-9_8)

Aplicación interactiva en **Shiny** para explorar la **Gran Encuesta Integrada de Hogares (GEIH) 2024** del [DANE](https://www.dane.gov.co/), con caracterización de la población **colombiana y venezolana** en demografía, educación, mercado laboral, vivienda, salud y migración, a nivel nacional y departamental.

> **🚀 App en vivo →** [jsidte-daniel-molina.shinyapps.io/shiny-app](https://jsidte-daniel-molina.shinyapps.io/shiny-app/)
> **📄 Artículo publicado →** *Communications in Computer and Information Science*, Springer (R Day 2025, Medellín). **[doi.org/10.1007/978-3-032-18455-9_8](https://doi.org/10.1007/978-3-032-18455-9_8)**

> 🛠️ **Herramienta desarrollada por Daniel Molina Barrios.** El software es el artefacto de un artículo de investigación publicado en co-autoría con Iván Cruz y Alic Barandica (ver [Cita](#-cita)).

---

## 📸 Capturas

> _Agrega 2–4 capturas de la app (resumen, pirámide poblacional, mercado laboral, migración) en `docs/screenshots/` y referéncialas aquí — elevan mucho el README._

---

## ✨ Funcionalidades

- **Módulos interactivos:** Demografía · Educación · Mercado laboral · Vivienda · Salud · Motivos de migración.
- **Enfoque en migración venezolana:** caracterización específica de la población venezolana en Colombia.
- **Dos niveles geográficos:** nacional y departamental, conmutables desde la barra lateral.
- **Visualizaciones avanzadas:** pirámides poblacionales, gráficos circulares y de barras, e interactivos con `plotly`.
- **Filtros dinámicos:** por nivel territorial y por condición migratoria.
- **Exportación:** descarga de datos procesados en CSV y Excel (`DT` + `openxlsx`).

## 🛠️ Stack técnico

**R** · **Shiny** + **shinydashboard** · `plotly` · `ggplot2` · `dplyr` / `tidyr` / `data.table` · `DT` · `viridis` / `paletteer` / `RColorBrewer` · `openxlsx` · desplegado en **shinyapps.io**.

## 📊 Datos

- **Fuente:** [Gran Encuesta Integrada de Hogares (GEIH) 2024](https://microdatos.dane.gov.co) — DANE, Colombia. Microdatos de libre acceso.
- **`geih_complete.csv`:** GEIH consolidada y limpia a partir de los archivos mensuales; es el insumo principal de los scripts de `preparacion/`. La consolidación inicial se apoyó en un proyecto previo de exploración de datos: [Alicbm/data-exploration](https://github.com/Alicbm/data-exploration).
- **`datos/`:** archivos mensuales originales de la GEIH (insumo de la consolidación; no usados directamente por la app).

## 🔁 Reproducibilidad

```r
# 1. Abre el proyecto en RStudio (colombia-geih-shiny-app.Rproj)

# 2. Instala dependencias
install.packages(c(
  "shiny", "shinydashboard", "plotly", "ggplot2", "dplyr", "tidyr",
  "data.table", "DT", "viridis", "paletteer", "RColorBrewer",
  "openxlsx", "reshape2", "bit64"
))

# 3. (Opcional) Reconstruye el dataset consolidado desde los mensuales
source("funciones/join_geih.R")
source("preparacion/preparacion.R")

# 4. Lanza la app localmente
shiny::runApp()
```

## ☁️ Despliegue

La app se publica en **shinyapps.io** con `rsconnect`. **Las credenciales nunca se versionan** — se leen de variables de entorno:

```r
rsconnect::setAccountInfo(
  name   = Sys.getenv("SHINYAPPS_NAME"),
  token  = Sys.getenv("SHINYAPPS_TOKEN"),
  secret = Sys.getenv("SHINYAPPS_SECRET")
)
rsconnect::deployApp()
```

## 🗂️ Estructura del repositorio

```
colombia-geih-shiny-app/
├── app.R                  # App Shiny principal (UI + server)
├── funciones/
│   └── join_geih.R        # Unión por llave de los módulos de la GEIH
├── preparacion/           # Procesamiento y ponderación
│   ├── preparacion.R
│   ├── caracterizacion_nacional.R
│   └── caracterizacion_departamento.R
├── www/                   # Recursos front-end (CSS, JS)
├── datos/                 # Módulos mensuales de la GEIH (DANE)
├── geih_complete.csv      # GEIH consolidada (insumo de la app)
├── LICENSE                # MIT
└── README.md
```

## 📑 Cita

Si usas esta aplicación o su código, por favor cita el artículo:

> Cruz, I., Molina, D., & Barandica, A. (2026). *Interactive Visualization and Analysis of Colombia's GEIH Data: A Shiny Application for Reproducible Demographic and Labor Market Research.* In **Communications in Computer and Information Science** (pp. 139–152). Springer, Cham. https://doi.org/10.1007/978-3-032-18455-9_8

<details>
<summary>BibTeX</summary>

```bibtex
@inproceedings{cruz2026geih,
  title     = {Interactive Visualization and Analysis of Colombia's GEIH Data: A Shiny Application for Reproducible Demographic and Labor Market Research},
  author    = {Cruz, Iv{\'a}n and Molina, Daniel and Barandica, Alic},
  booktitle = {Communications in Computer and Information Science},
  pages     = {139--152},
  year      = {2026},
  publisher = {Springer, Cham},
  doi       = {10.1007/978-3-032-18455-9_8}
}
```
</details>

## 🙌 Créditos

- **Desarrollo de la herramienta:** Daniel Molina Barrios.
- **Artículo de investigación (co-autoría):** Iván Cruz · Daniel Molina · Alic Barandica.
- **Datos:** DANE — Gran Encuesta Integrada de Hogares (GEIH) 2024.

## 📄 Licencia

Distribuido bajo licencia **MIT** — el código es de uso libre con atribución (ver [`LICENSE`](LICENSE)). Los microdatos de la GEIH son propiedad del **DANE** y están sujetos a sus términos de uso.

## 👤 Autor

**Daniel Molina Barrios** — Economista & Data Scientist · Santa Marta, Colombia

[![GitHub](https://img.shields.io/badge/GitHub-2563EB?style=flat-square&logo=github&logoColor=white)](https://github.com/dmetrics1)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-7C3AED?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/daniel-molina-b76a4323b/)
