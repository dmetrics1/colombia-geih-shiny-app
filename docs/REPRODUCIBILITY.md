# Guía de reproducibilidad — v2 (2022–2025)

El repositorio versiona **solo el código** y los **agregados ligeros** (`agregados.rds`). Los
microdatos de la GEIH (`datos/geih_AAAA.csv`, ~2.5 GB) están en [`.gitignore`](../.gitignore) y se
**descargan del DANE**. Toda la cadena es reproducible desde fuentes públicas.

---

## 1. Requisitos

- **R 4.5+**. Dependencias:

```r
install.packages(c("shiny", "shinydashboard", "plotly", "data.table",
                   "DT", "openxlsx", "readxl"))
```

## 2. Descargar los microdatos del DANE

1. En **[microdatos.dane.gov.co](https://microdatos.dane.gov.co)**, busca la **GEIH** y descarga
   los años **2022, 2023, 2024 y 2025** (consolidados por año).
2. Colócalos como:

```
datos/
├── geih_2022.csv
├── geih_2023.csv
├── geih_2024.csv
└── geih_2025.csv
```

Cada archivo trae las ~520 columnas de la GEIH (todas las personas/hogares del año), incluido el
factor de expansión `FEX_C18` y la variable de mes `MES`.

## 3. Pipeline de datos

```
datos/geih_AAAA.csv
   │  preparacion/cargar_anios.R   cargar_serie(): lee los 4 CSV, selecciona ~45 variables,
   │                               añade ANIO y los apila (rbindlist).
   │  R/recodes.R                  etiquetar_geih(): recodifica códigos → etiquetas legibles
   │                               (departamento, sexo, nivel educativo, rama, materiales…).
   │  R/indicadores.R              calcula cada indicador en su UNIDAD correcta (persona/hogar/
   │                               vivienda), ponderado por FEX_C18.
   │  R/aggregate.R                ponderación: n_periodos() = nº real de meses (divisor dinámico).
   ▼
preparacion/agregar.R  ──►  agregados.rds   (tabla por indicador, clave: anio × geo × migrante;
                                             + serie_trim trimestral para tendencias)
   ▼
app.R / global.R  ──►  la app solo LEE y FILTRA agregados.rds (sin microdato en memoria)
```

### Regenerar los agregados

```r
# Desde la raíz del repo (R 4.5)
source("preparacion/agregar.R")   # sourcea aggregate/recodes/indicadores/cargar_anios y
                                  # escribe agregados.rds (~0.4 MB). Tarda ~4–5 min (lee 2.5 GB).
```

### Lanzar la app

```r
shiny::runApp()   # global.R carga agregados.rds y los módulos
```

## 4. Ponderación y unidad de análisis (reglas clave)

- **Factor de expansión:** siempre `FEX_C18`. Los conteos se expresan como **promedio mensual**:
  `Σ FEX_C18 / n_meses` (divisor = nº real de meses del periodo, p. ej. 12 en un año). En **tasas
  y porcentajes** el divisor se cancela.
- **Unidad por indicador:**
  - **Persona** — demografía, educación, salud, mercado laboral, migración.
  - **Hogar** (`P6050 == 1`, jefe de hogar) — tenencia, servicios, materiales, sanitario.
  - **Vivienda** (`P6050 == 1 & HOGAR == 1`, 1 por `DIRECTORIO`) — conteo de viviendas.
- Detalle por indicador en [`INDICADORES.md`](INDICADORES.md).

## 5. Validación

```r
Rscript tests/auditoria_valores.R   # agregados == microdato + coherencia interna + rangos DANE
```

## 6. Credenciales y despliegue

Las credenciales de **shinyapps.io** **nunca** se versionan (`clave.R`, `.Renviron` en `.gitignore`);
se leen de variables de entorno. Ver [`SECURITY_TODO.md`](SECURITY_TODO.md) — **rotación de token
pendiente** antes de redesplegar.

```r
rsconnect::setAccountInfo(name = Sys.getenv("SHINYAPPS_NAME"),
                          token = Sys.getenv("SHINYAPPS_TOKEN"),
                          secret = Sys.getenv("SHINYAPPS_SECRET"))
rsconnect::deployApp()
```
