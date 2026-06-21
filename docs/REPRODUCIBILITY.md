# Guía de reproducibilidad

Este repositorio es **liviano por diseño**: versiona únicamente el código. Los microdatos de la
GEIH (`datos/`) y el consolidado (`geih_complete.csv`) están en [`.gitignore`](../.gitignore) y se
**regeneran** desde los microdatos públicos del DANE. Así el repo permanece limpio, clonable y
reproducible desde fuentes públicas — el estándar para el artefacto de un artículo científico.

---

## 1. Requisitos

- **R 4.0+** (probado con `data.table`, `shiny`, `plotly`).
- Dependencias:

```r
install.packages(c(
  "shiny", "shinydashboard", "plotly", "ggplot2", "dplyr", "tidyr",
  "data.table", "DT", "viridis", "paletteer", "RColorBrewer",
  "openxlsx", "reshape2", "bit64", "scales"
))
```

---

## 2. Descargar los microdatos del DANE

1. Entra a **[microdatos.dane.gov.co](https://microdatos.dane.gov.co)** y busca la
   **Gran Encuesta Integrada de Hogares (GEIH) 2024**.
2. Descarga los **12 meses** del año (enero a diciembre), cada mes con sus módulos en formato CSV.
3. Colócalos en `datos/<mes>/` usando nombres de mes en minúscula y en español:

```
datos/
├── enero/
│   ├── Caracteristicas generales (Personas).CSV
│   ├── Ocupados.CSV
│   ├── Desocupados.CSV
│   ├── Vivienda y hogares.CSV
│   └── ...  (resto de módulos del mes)
├── febrero/
│   └── ...
├── ...
└── diciembre/
    └── ...
```

> **Cómo se leen las carpetas.** `geih_completed()` recorre **todas las subcarpetas presentes**
> en `datos/` con `list.dirs(...)` y, dentro de cada mes, une **todos los `*.csv`** con
> `list.files(...)`. No hay una lista fija de meses ni de módulos: el pipeline procesa lo que
> encuentre. Si solo colocas algunos meses, el consolidado tendrá solo esos meses.

---

## 3. El pipeline de consolidación

```
datos/<mes>/*.csv
      │
      │  funciones/join_geih.R
      │  ├─ merge_month(month)   → une los módulos de UN mes por las llaves
      │  │                          DIRECTORIO, SECUENCIA_P, ORDEN, HOGAR, FEX_C18
      │  └─ geih_completed()     → apila (rbindlist) los 12 meses en un solo data.table
      ▼
preparacion/preparacion.R
      ├─ recodifica departamentos (DPTO → nombre), variables y categorías
      └─ fwrite(...) ───────────► geih_complete.csv      ← ¡aquí se ESCRIBE el archivo!
      ▼
app.R
      ├─ fread("geih_complete.csv")
      └─ source(caracterizacion_nacional.R / _departamento.R) → UI + server
```

> ⚠️ **Importante:** En `funciones/join_geih.R` la línea `fwrite(...)` está **comentada** a
> propósito; ese script solo *define* las funciones de unión y apilado. **Quien escribe
> `geih_complete.csv` en disco es `preparacion/preparacion.R`** (`fwrite(geih1, "geih_complete.csv", sep = "\t")`).

### Ejecución

```r
# Desde la raíz del repositorio
source("funciones/join_geih.R")      # define merge_month() y geih_completed()
source("preparacion/preparacion.R")  # recodifica y ESCRIBE geih_complete.csv
shiny::runApp()                      # app.R lee geih_complete.csv
```

---

## 4. Notas operativas

- **Llaves de unión:** `DIRECTORIO`, `SECUENCIA_P`, `ORDEN`, `HOGAR`, `FEX_C18`. En cada `merge`
  se conservan las columnas comunes (`.x`) y se descartan las duplicadas (`.y`).
- **Factor de expansión:** `FEX_C18` se usa como llave y como ponderador para las estimaciones
  poblacionales; no lo elimines de los módulos.
- **Tamaño:** el consolidado de 12 meses ronda ~90 MB. Por eso no se versiona.
- **Separador:** `geih_complete.csv` se escribe con tabulador (`sep = "\t"`); `fread` lo
  autodetecta al leerlo en `app.R`.

---

## 4b. Ponderación con divisor dinámico (v2)

La GEIH es una **encuesta mensual**. Al sumar `FEX_C18` sobre N meses se obtiene **N veces** la
población media mensual, así que para estimar el promedio mensual hay que **dividir por N**.

> ⚠️ El código v1 dividía por un **`7` fijo** (32 veces). Con 12 meses eso **infla las cifras
> ×12/7 ≈ 1.71** (p. ej. población 2024 saldría 88 M en vez de 51.5 M). Regla del instructivo §14:
> nunca dividir por un número fijo.

La v2 centraliza la lógica en [`R/aggregate.R`](../R/aggregate.R) con un divisor **dinámico**:

```r
n_periodos(dt)   # uniqueN(MES); o combinaciones ANIO×MES si la serie es multi-año (p. ej. 48)
poblacion_ponderada(dt)        # sum(FEX_C18) / n_periodos(dt)
conteo_ponderado(dt, by = ...) # personas por grupo, mismo divisor
```

- En **conteos de personas** (estado civil, educación, vivienda, salud…) se aplica el divisor.
- En **razones** (tasa de desempleo/ocupación, porcentajes) el divisor **se cancela**: no se aplica.
- Validado: 2024 → 51.551.004 (coincide con `tests/baseline_2024.csv`); serie 2022-2025 → 48 periodos.

---

## 5. Credenciales y despliegue

Las credenciales de **shinyapps.io** **nunca** se versionan. Están cubiertas por `.gitignore`
(`clave.R`, `.Renviron`) y se leen de variables de entorno:

```r
rsconnect::setAccountInfo(
  name   = Sys.getenv("SHINYAPPS_NAME"),
  token  = Sys.getenv("SHINYAPPS_TOKEN"),
  secret = Sys.getenv("SHINYAPPS_SECRET")
)
rsconnect::deployApp()
```

> 🔐 **Seguridad:** si un token estuvo alguna vez en el historial de git o en un archivo
> versionado, **rótalo** en shinyapps.io (*Account → Tokens → Remove* y genera uno nuevo).
> Borrarlo del archivo no lo elimina del historial.
