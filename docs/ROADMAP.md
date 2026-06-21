# Roadmap — Colombia GEIH Shiny App v2

Plan por fases para llevar el proyecto a un nivel superior: **datos GEIH 2022–2025 con eje
temporal**, código refactorizado y limpio, arquitectura escalable y un diseño moderno.

> Estado base (junio 2026): app cross-seccional de 2024, divisor `/7` hardcodeado (32 veces),
> caracterizaciones `nacional`/`departamento` duplicadas ~90%, pestaña "Datos" dependiente de
> Excel generados a mano, script `data.frame/archivos de excel.R` desconectado del pipeline,
> IDs de UI duplicados (`level_selection`), restos de despliegue (`.libPaths`) en `app.R`.

## Insumos de datos recibidos (jun 2026)

Ya están en el proyecto las bases **GEIH consolidadas por año 2022–2025** (no módulos mensuales):

- `datos/geih_2022.csv … geih_2025.csv` — 4 archivos, ~2.5 GB, 524 columnas, separador coma,
  con `FEX_C18`, `MES`, `DPTO`, etc. (en `.gitignore`).
- `docs/data-dictionary/diccionario.xlsx` — diccionario de variables (`nombre_variable`,
  `codigo_categoria`, `categoria`, `pregunta_literal`, `tipo_variable`).
- `docs/data-dictionary/instructivo_trabajo_geih.md` y `protocolo_diccionario_geih.md` —
  **metodología de trabajo de la GEIH (vinculante para este proyecto).**

**Implicaciones para el plan:**
- Como los años **ya vienen pegados**, el merge de módulos mensuales de `funciones/join_geih.R`
  **queda obsoleto**. La ingesta se reduce a: leer los 4 CSV → añadir `ANIO` → recodificar → agregar.
- La recodificación debe ser **dirigida por `diccionario.xlsx`** (capa de mapeo reusable), tratando
  los códigos como **texto** (preservar ceros a la izquierda, p. ej. `AREA = "05"`), conservando la
  columna original y creando `*_label` (estrategia auditable del protocolo), con **reporte de cobertura**.
- Confirma el fix del `/7`: el instructivo (§14) prohíbe dividir por inercia; el divisor debe ser el
  **nº real de meses** del periodo (`uniqueN(MES)`).
- El protocolo aporta recodes más ricos que la app actual (grupo de edad, posición ocupacional,
  rama de actividad `RAMA2D_R4`, lugar de trabajo, pensión) → insumos para nuevos análisis (Fase 5).
- Arquitectura en capas recomendada: **cruda → estandarizada → temática → indicadores**.

---

## Decisión arquitectónica central: pre-agregación

El dashboard nunca consulta microdato individual: siempre muestra **agregados ponderados** por
`FEX_C18`. Por eso la estrategia para escalar a 4 años es **precalcular las tablas de resumen una
sola vez (offline) y que la app solo lea/filtre agregados**.

```
datos/geih_2022.csv … geih_2025.csv   (consolidados por año, ~2.5 GB, IGNORADO en git)
        │  preparacion/  (apila años + recodifica vía diccionario + pondera +
        │                 PRE-AGREGA por año × geo × sexo × migrante)
        ▼
agregados.parquet|rds     (tablas resumidas, < 10 MB, IGNORADO o versionable)
        ▼
app.R                     (lee agregados, filtra, grafica — sin microdato en memoria)
```

**Beneficios:** carga instantánea en shinyapps.io · repo y deploy mínimos · elimina el problema
de los Excel hechos a mano (pestaña "Datos" se alimenta de los mismos agregados) · permite añadir
2022–2025 sin costo de memoria · corrige el `/7` en un solo lugar.

---

## Estructura objetivo del proyecto (v2)

Migración incremental del `app.R` monolítico a una estructura modular y data-driven:

```
shiny-app/
├── app.R                       # Solo arranque: source(global) + shinyApp(ui, server)
├── global.R                    # Carga agregados.parquet, librerías, constantes globales
├── R/                          # Lógica reutilizable (cargada por global.R)
│   ├── recodes.R               # Diccionarios de recodificación (data-driven, no 8 mapas sueltos)
│   ├── aggregate.R             # Funciones de agregación ponderada (divisor dinámico /n_meses)
│   ├── plot_theme.R            # tema_plotly(): estilo común (fondos, fuentes, márgenes)
│   └── helpers.R               # Utilidades varias
├── modules/                    # Módulos Shiny, uno por pestaña (UI + server encapsulados)
│   ├── mod_demografia.R
│   ├── mod_educacion.R
│   ├── mod_laboral.R
│   ├── mod_vivienda.R
│   ├── mod_salud.R
│   ├── mod_migracion.R         # NUEVO (hoy documentado pero inexistente)
│   ├── mod_tendencias.R        # NUEVO (series 2022–2025)
│   └── mod_datos.R             # Tabla descargable, alimentada por agregados
├── preparacion/
│   ├── cargar_anios.R          # Lee geih_2022..2025.csv, añade ANIO, apila (rbindlist fill)
│   ├── recodificar.R           # Aplica diccionario (etiquetar_geih: código→*_label)
│   └── agregar.R               # PRE-AGREGA → agregados.parquet
│   # (funciones/join_geih.R queda obsoleto: los años ya vienen consolidados)
├── tests/                      # testthat + baseline de cifras
├── www/                        # CSS/JS
├── docs/
│   ├── data-dictionary/        # diccionario.xlsx + instructivo + protocolo (metodología)
│   └── screenshots/            # capturas para el README
├── datos/                      # geih_2022..2025.csv consolidados  (en .gitignore)
├── agregados.parquet           # salida ligera que consume la app
├── renv.lock                   # versiones fijadas
└── README.md
```

---

## Estimación de esfuerzo y orden de ejecución

Estimación en **sesiones de trabajo** (≈ media jornada cada una); el orden respeta dependencias.
La app queda **funcional al final de cada fase** (refactor incremental).

| Orden | Fase | Esfuerzo | Depende de | Hito visible |
|------|------|----------|-----------|--------------|
| 1 | 0 — Salvaguardas | 0.5 | — | Rama + baseline + renv |
| 2 | 2 — Fix `/7` (sobre datos actuales) | 0.5 | 0 | Cifras correctas, sin inflar |
| 3 | 3 — Refactor y limpieza | 2–3 | 2 | Código modular, sin dead code |
| 4 | 4 — Pre-agregación | 1–2 | 3 | `agregados.parquet`, app rápida |
| 5 | 1 — Datos 2022–2025 | 2–3 | 1 | 4 años unidos y validados |
| 6 | 5 — Analítica temporal | 2–3 | 4, 5 | Tendencias + pestaña migración |
| 7 | 6 — Rediseño UI | 1–2 | 5 | Tema nuevo + capturas |
| 8 | 7 — Calidad y docs | 1–2 | 6 | Tests + docs coherentes |
| 9 | 8 — Despliegue | 0.5 | 8 | v2 en shinyapps.io |

> **Total estimado:** ~11–18 sesiones. Nota de orden: hacemos el **fix `/7` (Fase 2) y el
> refactor (Fase 3) ANTES** de meter los 4 años, para no arrastrar deuda técnica ni recalcular
> sobre código duplicado. La descarga DANE de 2022–2025 (Fase 1) puede ir avanzando en paralelo
> desde el inicio, ya que es trabajo manual independiente del código.

---

## Fase 0 — Salvaguardas y línea base  *(rápida, antes de tocar código)*  — EN CURSO

**Objetivo:** trabajar seguro y poder comparar "antes vs después".

- [x] Crear rama `feature/v2-2022-2025` (no trabajar en `master`). ✅
- [x] Configurar identidad git: `Daniel Molina <dm0025900@gmail.com>` (local), sin co-autoría. ✅
- [x] Revisar el `stash@{0}` (wip oct-2025). **Decisión: NO hacer pop.** Su parte útil era el cambio
      `/7`→`/12` *hardcodeado*, superado por el divisor dinámico del plan; el resto (regenerar el CSV
      viejo, credenciales) es obsoleto. Se conserva el stash por si se quiere el `.Rproj` que incluía.
- [x] Congelar **línea base de cifras** sobre los datos NUEVOS (`tests/baseline_smoke.R` →
      `tests/baseline_2024.csv`). Validado contra DANE: pob. 51.55 M (~52 M), TD 10.2% (~10%),
      48.6% H / 51.4% M, 12 meses completos. Confirma data limpia + divisor dinámico correcto. ✅
- [ ] **Rotar el token de shinyapps.io** 🔴 — *pendiente del usuario*. Confirmado: el token del
      **commit `8e44899`** está expuesto en GitHub (ver `docs/SECURITY_TODO.md`). Account → Tokens → Remove.
- [ ] Inicializar `renv` — *pospuesto*: no está instalado e init modifica `.Rprofile`/lib del
      proyecto (riesgo de romper RStudio). Se hará en un punto estable (Fase 7) o con visto bueno.

**Entregable:** rama limpia ✅, baseline guardada ✅, token rotado (pendiente), `renv.lock` (pospuesto).

---

## Fase 1 — Datos 2022–2025: ingesta y validación de continuidad — ✅ COMPLETADA

**Objetivo:** incorporar los 4 años (ya consolidados) y verificar que las variables son comparables
entre años (la GEIH tuvo rediseño ~2021; hay que confirmar códigos y nombres, instructivo §17).

- [x] `preparacion/cargar_anios.R`: lee los 4 CSV (selección de 40 vars de análisis), **añade `ANIO`**,
      apila con `rbindlist(fill = TRUE)`. Verificado: las 40 vars están en los 4 años. ✅
- [x] **Procesar `diccionario.xlsx`** (`03_diccionario.R`): 676 vars, 188 mapeables → capa de mapeo
      (códigos como texto) `mapeos_variables.rds` + `diccionario_categorias.csv`. Cobertura del
      dashboard completa salvo `P3271` (mapa explícito) y `DPTO`/`AREA` (mapa de 33 deptos). ✅
- [x] **Continuidad entre años** (`01_validar_continuidad.R`): 502 columnas comunes; 28 vars clave y
      5 de migración presentes en los 4 años; diferencias solo en módulos especiales no usados. ✅
- [x] **Sanity check de la serie** (`02_resumen_anual.R`): 12 meses/año; población 50.5→52.1 M,
      desempleo 11.2→8.9 %, migrantes venez. ~2.0–2.3 M — todo coherente con DANE. ✅

**Entregable:** `cargar_anios.R` + capa de mapeo + reporte `docs/data_continuity.md`. ✅

---

## Fase 2 — Corregir la ponderación (`/7` → dinámico)  🔴 *crítico* — ✅ COMPLETADA

**Objetivo:** que las estimaciones poblacionales sean correctas con cualquier nº de meses.

> Ajuste de enfoque: como la Fase 1 ya está hecha, NO se parchan los 32 `/7` de los archivos
> viejos (que la Fase 3 reemplazará). El fix se construye en la **capa central** `R/aggregate.R`,
> que es donde vivirá la lógica tras el refactor. Cero trabajo desechable.

- [x] `R/aggregate.R`: divisor **dinámico** `n_periodos()` = meses distintos (`uniqueN(MES)`) o
      combinaciones `ANIO×MES` en multi-año. Helpers `poblacion_ponderada()`, `conteo_ponderado()`. ✅
- [x] Validado (`04_demo_divisor.R`): 2024 con `/7` daría **88.4 M** (×1.71 inflado); con divisor
      dinámico da **51.551.004**, exacto a la baseline. Serie 2022-2025: `n_periodos()=48` correcto. ✅
- [x] Lógica de ponderación documentada en `docs/REPRODUCIBILITY.md`. ✅

**Entregable:** capa central de ponderación correcta y verificada (`R/aggregate.R`). ✅

---

## Fase 3 — Refactor y limpieza de código — EN CURSO (capa de lógica ✅)

**Objetivo:** un proyecto factorizado, sin duplicación ni código muerto, fácil de mantener.

- [x] **Unificar caracterizaciones:** `R/indicadores.R` — 11 funciones (una por indicador) con
      parámetro `depto=NULL`; sirven nacional, departamental y migrante. Reemplazan las ~25 funciones
      duplicadas con `/7`. **Validado vs baseline:** sexo 48.6/51.4, TD 10.2%, depto y migrante OK. ✅
- [x] **Recodificación dirigida por diccionario:** `R/recodes.R` con `etiquetar_geih()` (códigos como
      texto → columnas con nombre legible: `sexo`, `estado_civil`, `nivel_educativo`, `departamento`,
      `grupo_edad`, …) + `es_migrante_venezolano()`. Reemplaza los 8+ `replacement_map_*` y el `fcase`. ✅
- [x] **Tematizar plotly:** `R/plot_theme.R` (`tema_plotly()`, `PALETA`, `barra_horizontal()`) —
      centraliza el estilo repetido en los 12 gráficos. ✅
- [ ] **Modularizar la app** con Shiny modules: `global.R` (carga datos + `source` de `R/`), un módulo
      por pestaña, en lugar del `app.R` monolítico de ~970 líneas.
- [ ] **Eliminar código muerto / problemas detectados:**
      - `.libPaths("/root/R/...")` (resabio de deploy) en `app.R:1`.
      - ID duplicado `level_selection` (filtro global vs pestaña Datos) → renombrar uno.
      - `print()` de depuración en el server.
      - `data.frame/archivos de excel.R` (roto, rutas absolutas, `install.packages` embebido) →
        eliminar / reescribir como generador de agregados (Fase 4).
      - `funciones/join_geih.R`, `preparacion/caracterizacion_*.R`, `preparacion.R` viejos → retirar.

**Entregable:** código modular, DRY, sin dead code; `app.R` reducido a orquestación.
**Avance:** capa de datos/lógica (`R/recodes.R`, `R/indicadores.R`, `R/plot_theme.R`) lista y validada;
falta la modularización de la UI y la limpieza de archivos viejos.

---

## Fase 4 — Pre-agregación y almacenamiento eficiente

**Objetivo:** implementar la decisión arquitectónica central.

- [ ] Script `preparacion/agregar.R`: a partir del consolidado, **precalcular todas las tablas**
      que consumen los gráficos, con claves `ANIO × DPTO × P3271 × es_migrante` (+ las categorías
      propias de cada indicador).
- [ ] Guardar en formato compacto (`agregados.parquet` con `arrow`, o `.rds`), < 10 MB.
- [ ] Reescribir `app.R` para leer agregados y **filtrar** (sin recálculo de microdato).
- [ ] Alimentar la **pestaña "Datos"** desde estos mismos agregados (fin de los Excel manuales).

**Entregable:** app que arranca en segundos con 4 años de datos; pestaña Datos reproducible.

---

## Fase 5 — Nuevas funcionalidades analíticas *(el salto de nivel)*

**Objetivo:** explotar la dimensión temporal 2022–2025.

- [ ] **Selector de año / periodo** en la barra de filtros.
- [ ] **Gráficos de tendencia** 2022–2025 para indicadores clave (tasa de desempleo, ocupación,
      acceso a salud, población migrante, ingreso medio) — líneas temporales.
- [ ] **KPIs (value boxes)** con totales y variación interanual.
- [ ] **Implementar la pestaña "Motivos de migración"** (hoy documentada pero inexistente; `P3386`
      ya se recodifica y no se grafica).
- [ ] Comparaciones: año vs año, departamento vs nacional.

**Entregable:** dashboard con análisis longitudinal, no solo cross-seccional.

---

## Fase 6 — Rediseño UI/UX

**Objetivo:** una interfaz moderna, coherente y accesible.

- [ ] Evaluar migración de `shinydashboard` a **`bslib` (Bootstrap 5)** o `shinydashboardPlus`.
- [ ] Sistema visual consistente: paleta, tipografía, contraste accesible (WCAG), estados de carga.
- [ ] Layout responsive y encabezado con identidad del proyecto (DANE / Uni. Magdalena).
- [ ] Capturas para el README (`docs/screenshots/`) — placeholder ya referenciado.

**Entregable:** UI renovada + capturas en el README.

---

## Fase 7 — Calidad, pruebas y documentación

**Objetivo:** dejar el proyecto al estándar de un artefacto científico publicable.

- [ ] Pruebas `testthat` para las funciones de agregación (totales coherentes con la baseline/DANE).
- [ ] (Opcional) CI con GitHub Actions: lint + tests en cada push.
- [ ] Actualizar `README.md`, `REPRODUCIBILITY.md`; añadir **diccionario de variables**
      (`docs/data_dictionary.md`) y este roadmap como histórico.
- [ ] Corregir discrepancias doc↔código (módulos reales, pestaña Datos vs "Motivos de migración").

**Entregable:** suite de tests + documentación completa y coherente.

---

## Fase 8 — Despliegue y cierre

- [ ] Desplegar v2 en shinyapps.io con el token nuevo.
- [ ] Completar descriptores del repo en GitHub (description, topics, website).
- [ ] Tag de versión `v2.0.0` y nota de actualización del artefacto del paper.

---

## Riesgos a verificar (no asumir)

| Riesgo | Acción |
|---|---|
| **Cambios de variables entre años** (la GEIH se rediseñó ~2021). Códigos o nombres pueden diferir 2022 vs 2025. | Verificar diccionarios DANE por año en Fase 1 antes de unir. |
| **Factor de expansión** puede cambiar de nombre/base entre años (`FEX_C18` vs otros). | Confirmar la columna de ponderación correcta por año. |
| **Variables de migración** (`P3373S3`, `P3374S1`, `P3386`) podrían no estar en todos los módulos/meses. | Verificar disponibilidad; documentar cobertura temporal del análisis migrante. |
| **Memoria en shinyapps.io** (plan free ~1 GB). | La pre-agregación (Fase 4) lo mitiga; validar tras desplegar. |
| **Comparabilidad de tasas entre años** (cambios muestrales). | Notas metodológicas en la UI y el paper. |

---

## Decisiones confirmadas (jun 2026)

1. ✅ **Modelo temporal:** selector de año/periodo **+ gráficos de tendencia 2022–2025**.
2. ✅ **Almacenamiento:** **pre-agregados** (`parquet`/`rds`, < 10 MB) — no se sube microdato.
3. ✅ **Framework UI:** se mantiene en **Shiny** con `shinydashboard` **tematizado** (encaja con el
   refactor incremental y no rehace la app). `bslib`/Bootstrap 5 queda como mejora opcional a futuro.
4. ✅ **Alcance del refactor:** **modularización incremental** (app funcional en cada paso).

## Capacidad de hosting — resuelto

**El volumen de datos NO es el limitante.** Gracias a la pre-agregación, el archivo que consume la
app pesa < 10 MB y usa **menos** RAM que el microdato actual, así que 4 años (2022–2025) caben sin
problema incluso en el tier free de shinyapps.io. Lo único que escalaría el plan a futuro es el
**tráfico** (horas activas/mes), no la cantidad de años. Conclusión: **seguimos en shinyapps.io tal
cual**; revisar el plan solo si el uso crece mucho.
