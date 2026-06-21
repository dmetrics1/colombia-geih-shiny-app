# Validación de continuidad — GEIH 2022–2025 (Fase 1)

Reporte de la ingesta y validación estructural de la serie. Scripts:
`preparacion/01_validar_continuidad.R`, `02_resumen_anual.R`, `03_diccionario.R`, `cargar_anios.R`.

## 1. Inventario

Bases **consolidadas por año** en `datos/` (en `.gitignore`):

| Archivo | Tamaño | Filas | Columnas | Meses |
|---|---|---|---|---|
| `geih_2022.csv` | 693 MB | 919.459 | 534 | 12 |
| `geih_2023.csv` | 640 MB | 860.802 | 532 | 12 |
| `geih_2024.csv` | 616 MB | 829.683 | 524 | 12 |
| `geih_2025.csv` | 599 MB | 817.550 | 514 | 12 |

Separador coma · unidad de análisis persona/hogar · ponderador `FEX_C18`.

## 2. Continuidad de variables

- **502 columnas comunes** a los 4 años.
- **Las 28 variables clave** (identificación, diseño muestral e indicadores) están en **los 4 años**. ✅
- **Las 5 variables de migración** (`P3373S3`, `P3374S1`, `P3374S2`, `P3374S3`, `P3386`) están en **los 4 años**. ✅
- **Las 40 variables del set de análisis** (`VARS_ANALISIS` en `cargar_anios.R`) están en **los 4 años**. ✅

Las diferencias entre años son **módulos especiales que el DANE agrega/quita** y que el dashboard
no usa: batería `P3147S*`, `LGB_*`/`TRANS_NUMERICA`/`DISCAPACIDAD`/`CAMPESINA` (2022–2023),
`P4000`, `P6290`, `DSCY` (2022–2024), y nuevas en 2025 (`P4005`, `P5222S11`, `P7280S1`, …).

> **Conclusión:** el apilado multi-año es seguro para los fines del dashboard.

## 3. Sanity check de la serie (ponderado, divisor = nº real de meses)

| Año | Población prom. mensual | Tasa desempleo | Migrantes venezolanos |
|---|---|---|---|
| 2022 | 50.495.179 | 11.2 % | 2.336.004 |
| 2023 | 51.027.876 | 10.2 % | 2.229.007 |
| 2024 | 51.551.004 | 10.2 % | 2.225.261 |
| 2025 | 52.063.865 | 8.9 % | 2.048.223 |

Magnitudes coherentes con cifras DANE: población creciente (proyecciones), **desempleo
descendente** (tendencia real 2022→2025) y migrantes venezolanos en rango razonable.
Migrante venezolano = `P3373S3 == 862 & P3374S1 == 862` (código país 862).
Salida en `tests/resumen_anual_2022_2025.csv`.

## 4. Diccionario (`diccionario.xlsx`)

- 3.096 filas × 7 columnas (`nombre_variable`, `etiqueta_variable`, `descripcion`,
  `pregunta_literal`, `tipo_variable`, `codigo_categoria`, `categoria`).
- **676 variables**; **188 con categorías mapeables.**
- Capa de mapeo generada (códigos como **texto**): `docs/data-dictionary/mapeos_variables.rds`
  y `docs/data-dictionary/diccionario_categorias.csv`.
- **Cobertura de variables del dashboard:** completa, salvo:
  - `P3271` (sexo) **no está en el diccionario** → usar mapa explícito (`1=Hombre, 2=Mujer`).
  - `DPTO` (105 categorías) y `AREA` (36) incluyen subcódigos de áreas/municipios → conservar el
    mapa explícito de 33 departamentos en lugar del diccionario.

## 5. Notas metodológicas (vinculantes, de las guías)

- **Ponderación:** indicadores poblacionales siempre con `FEX_C18`. El divisor para promedio
  mensual es el **nº real de meses** (`uniqueN(MES)`), nunca un 7/12 fijo (instructivo §14).
- **Códigos como texto:** preservar ceros a la izquierda (`AREA = "05"`).
- **Recodificación auditable:** conservar columna original + crear `*_label` (protocolo).
- `funciones/join_geih.R` (merge mensual) queda **obsoleto**: los años ya vienen consolidados.

## 6. Entorno de ejecución

R no está en el PATH. Usar `C:\Program Files\R\R-4.5.2\bin\Rscript.exe` para `data.table`.
Ejecutar **scripts en archivo**, no `Rscript -e` inline (segfalla por el paso de argumentos en
Git Bash → Windows). Pendiente: `renv` en fase estable para fijar versiones.
