# Documentación de indicadores — Observatorio GEIH

Definición, unidad de análisis y método de cálculo de cada indicador del dashboard.
Fuente metodológica: **DANE, DSO-GEIH-MET-001 (Metodología General GEIH, V11)** —
`metodologia_geih/`. Datos: GEIH 2022–2025 (microdatos consolidados por año).

---

## 1. Unidades de análisis y ponderación

La GEIH tiene **tres unidades de observación y análisis** (metodología §2.2.7): **viviendas,
hogares y personas**. Cada indicador debe agregarse en su unidad correcta.

| Unidad | Llave única | Qué la identifica | Nº (2024) |
|---|---|---|---|
| **Vivienda** | `DIRECTORIO` | la estructura física | 288.604 |
| **Hogar** | `DIRECTORIO + SECUENCIA_P` (≈ `+ HOGAR`) | grupo que comparte vivienda y comida | 290.968 |
| **Persona** | `DIRECTORIO + SECUENCIA_P + HOGAR + ORDEN` | cada residente habitual | 829.683 |

> **Regla crítica (metodología):** *"los datos de la vivienda se toman una sola vez, así exista
> más de un hogar"*. Las variables de vivienda/hogar (tenencia, servicios, materiales, sanitario)
> se **repiten en cada integrante**. Por eso **NO** se suman sobre personas (inflaría cada hogar
> por su tamaño, ~2.85 personas en promedio). Se agregan sobre **un registro por hogar = el jefe
> de hogar (`P6050 == 1`)**, que es único por hogar y porta el factor de expansión del hogar.

### Factor de expansión y divisor de periodo

- **Ponderador:** `FEX_C18` (factor de expansión calibrado con proyecciones del CNPV 2018). Toda
  estimación poblacional se pondera por `FEX_C18`; los conteos simples NO representan la población.
- **Divisor de periodo (`n_periodos`):** la GEIH es **mensual**. Sumar `FEX_C18` sobre N meses da
  N veces la población media mensual; para estimar el **promedio mensual** se divide por N (el nº
  real de meses del periodo, p. ej. 12 en un año). Nunca un divisor fijo por inercia (metodología,
  cuidado con dividir por 7/12 ciegamente). Implementado en `R/aggregate.R::n_periodos()`.
- En **razones** (tasas, porcentajes) el divisor se cancela y no se aplica.

Capa de código: `R/recodes.R` (etiquetas), `R/aggregate.R` (ponderación), `R/indicadores.R`
(indicadores), `preparacion/agregar.R` (pre-agregación → `agregados.rds`).

---

## 2. Fórmulas oficiales del mercado laboral (DANE)

Población base (metodología §2.1.5):

- **PT** — Población total. **PET** — Población en Edad de Trabajar (15 años y más).
- **FT** — Fuerza de Trabajo (ocupados + desocupados). **OC** — Ocupados. **DS** — Desocupados.

| Indicador | Fórmula | Significado |
|---|---|---|
| % PET | `PET / PT × 100` | peso de la población en edad de trabajar |
| **TGP** (participación) | `FT / PET × 100` | presión sobre el mercado laboral |
| TBP | `FT / PT × 100` | participación bruta |
| **TD** (desempleo) | `DS / FT × 100` | desocupados sobre fuerza de trabajo |
| **TO** (ocupación) | `OC / PET × 100` | ocupados sobre población en edad de trabajar |
| TS (subocupación) | `PS / FT × 100` | subocupados (insuf. horas/competencias/ingresos) |

> En el dashboard, `OC = OCI × FEX_C18`, `DS = DSI × FEX_C18`, `PET = (P6040 ≥ 15) × FEX_C18`,
> `FT = OC + DS`. Las tasas se calculan sobre estos agregados (el divisor de periodo se cancela).

---

## 3. Indicadores implementados (por pestaña)

Notación: **U** = unidad (P=persona, H=hogar). Todos ponderados por `FEX_C18` salvo indicación.

### Demografía  *(unidad: persona)*
| Indicador | Variable(s) | U | Cálculo |
|---|---|---|---|
| Pirámide poblacional | `P6040` (edad), `P3271` (sexo) | P | `Σ FEX/n_meses` por grupo quinquenal × sexo; % sobre total |
| Distribución por sexo | `P3271` | P | `Σ FEX/n_meses` por sexo; % |
| Estado civil | `P6070` | P | `Σ FEX/n_meses` por categoría |

### Educación  *(unidad: persona)*
| Indicador | Variable(s) | U | Cálculo |
|---|---|---|---|
| Nivel educativo alcanzado | `P3042` | P | `Σ FEX/n_meses` por nivel |
| Ingreso laboral por nivel | `INGLABO`, `P3042` | P | media **ponderada**: `Σ(INGLABO×FEX)/Σ FEX` por nivel |

### Mercado laboral  *(unidad: persona)*
| Indicador | Variable(s) | U | Cálculo |
|---|---|---|---|
| Ocupados / Desocupados | `OCI`, `DSI` | P | `Σ(OCI×FEX)/n_meses`, `Σ(DSI×FEX)/n_meses` |
| Tasa de desempleo (TD) | `OCI`, `DSI` | P | `DS / (OC+DS) × 100` |
| Tasa de ocupación (TO) | `OCI`, `P6040` | P | `OC / PET × 100`, `PET = P6040≥15` |
| Tasa de participación (TGP) | `OCI`, `DSI`, `P6040` | P | `(OC+DS) / PET × 100` (en la serie trimestral) |
| Tipo de trabajo (posición ocupacional) | `P6430` | P | `Σ FEX/n_meses` por categoría |
| Serie trimestral TGP·TO·TD | `OCI`,`DSI`,`P6040`,`MES` | P | por `ANIO × trimestre` (`serie_trim`) |

### Vivienda  *(unidad: HOGAR — jefe `P6050==1`)*
| Indicador | Variable(s) | U | Cálculo |
|---|---|---|---|
| Tenencia de la vivienda | `P5090` | H | `Σ FEX/n_meses` por categoría, **solo jefes** |
| Servicios públicos | `P4030S1/S2/S3/S5` | H | `% de hogares con "Sí"` por servicio (solo jefes) |
| Material de paredes | `P4010` | H | `Σ FEX/n_meses` por categoría (jefes) |
| Material del piso | `P4020` | H | `Σ FEX/n_meses` por categoría (jefes) |
| Servicio sanitario | `P5020` | H | `Σ FEX/n_meses` por tipo (jefes) |

### Salud  *(unidad: persona)*
| Indicador | Variable(s) | U | Cálculo |
|---|---|---|---|
| Acceso a salud (afiliación) | `P6090` | P | `Σ FEX/n_meses` por Sí/No/No informa |
| Tipo de afiliación (régimen) | `P6100` | P | `Σ FEX/n_meses` por régimen |

### Migración  *(unidad: persona; población venezolana, país `862`)*
| Indicador | Variable(s) | U | Cálculo |
|---|---|---|---|
| Motivos de migración | `P3386` | P | `Σ FEX/n_meses` por motivo |
| Migrantes por sexo | `P3271` | P | `Σ FEX/n_meses` por sexo |
| Serie trimestral de migrantes | `MES` | P | población venezolana por `ANIO × trimestre` |

Migrante venezolano: `P3373S3 == 862 & P3374S1 == 862` (código país 862).

### Datos
Tabla descargable (CSV/Excel) de cualquiera de los agregados anteriores, filtrada por
año/geografía/población.

---

## 4. Arquitectura de datos

```
datos/geih_AAAA.csv → cargar_anios.R (apila + selecciona) → etiquetar_geih (recodes)
   → indicadores.R (por unidad correcta) → agregar.R → agregados.rds (~0.4 MB)
   → la app solo lee y filtra (anio × geo × migrante)
```
`agregados.rds` contiene una tabla por indicador (clave `anio, geo, migrante`) + `serie_trim`
(serie trimestral para tendencias laborales y de migración).

---

## 5. Indicadores propuestos (alto valor, por incorporar)

Evaluados sobre la metodología; **todas las variables están disponibles 2022–2025**.

| # | Indicador | Pestaña | Variable(s) | Unidad | Valor | Cálculo propuesto |
|---|---|---|---|---|---|---|
| 1 | **Rama de actividad económica** | Laboral | `RAMA2D_R4` | P (ocupados) | ⭐⭐⭐ | distribución de ocupados por sector (CIIU 2 díg → ~13 ramas) |
| 2 | **Brecha salarial de género** | Laboral | `INGLABO`,`P3271` | P (ocupados) | ⭐⭐⭐ | ingreso medio ponderado H vs M; brecha `(IH−IM)/IH` |
| 3 | **Tasa de participación (TGP)** como KPI | Laboral | `OCI`,`DSI`,`P6040` | P | ⭐⭐ | `(OC+DS)/PET×100` (ya se calcula en la serie) |
| 4 | **Jefatura femenina de hogar** | Demografía | `P6050`,`P3271` | H | ⭐⭐⭐ | `% de hogares con jefa mujer` (jefe==1 & sexo==Mujer) |
| 5 | **Tasa de analfabetismo** | Educación | `P6160`,`P6040` | P | ⭐⭐⭐ | `% de 15+ que no sabe leer/escribir` (P6160==2) |
| 6 | **Asistencia escolar** | Educación | `P6170`,`P6040` | P | ⭐⭐ | `% de 5–24 años que asiste a estab. educativo` |
| 7 | **Cotización a pensión** | Salud/Laboral | `P6920` | P (ocupados) | ⭐⭐ | `% de ocupados que cotiza` (proxy de formalidad/seguridad social) |
| 8 | **Horas trabajadas** | Laboral | `P6800` | P (ocupados) | ⭐⭐ | promedio de horas semanales (ponderado) |
| 9 | **Razón de dependencia** | Demografía | `P6040` | P | ⭐⭐ | `(pob<15 + pob≥65)/pob 15–64 × 100` |
| 10 | **Informalidad laboral** | Laboral | (derivada: tamaño empresa / seg. social) | P | ⭐⭐⭐ | requiere definir metodología DANE (tamaño ≤5 ó cotización) |

**Recomendación prioritaria (mayor valor / menor esfuerzo):** #1 Rama de actividad, #2 Brecha
salarial de género, #4 Jefatura femenina de hogar, #5 Analfabetismo (y #3 TGP como KPI, casi gratis).
El #10 (informalidad) es muy valioso pero requiere decidir la definición operativa.

> Nota: variables de población campesina, LGBTI y discapacidad existen solo en 2022–2023 (no en
> 2024–2025), por lo que **no** se proponen para series comparables.
