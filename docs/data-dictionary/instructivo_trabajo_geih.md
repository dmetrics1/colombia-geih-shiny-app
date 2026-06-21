# Instructivo operativo GEIH para agentes de IA

## Propósito de este documento

Este archivo existe para dejarle claro a cualquier agente de IA cómo debe trabajar los datos de la **GEIH** dentro de este proyecto.

Este instructivo está escrito para que el flujo pueda implementarse en:

- `Python`
- `R`
- `SQL`
- o cualquier otro stack que respete la lógica metodológica

La idea central es: **el agente debe entender cómo se organizan, pegan, limpian, documentan y analizan los datos de la GEIH**.

---

## 1. Punto de partida en este proyecto

En este proyecto se debe asumir lo siguiente:

- ya existen bases GEIH **pegadas/consolidadas** para el periodo **2022 a 2025**;
- el trabajo no parte necesariamente de volver a construir toda la base desde cero;
- el trabajo sí debe partir de entender **cómo fue construida**, **qué variables trae**, **qué diccionarios la explican** y **cómo se debe usar correctamente**.

Por tanto, cuando un agente entre a trabajar aquí, su primera pregunta no debe ser “cómo hago la app”, sino:

1. qué base consolidada ya existe;
2. qué años cubre;
3. qué nivel tiene la unidad de análisis;
4. qué diccionarios y metadatos explican las variables;
5. qué transformaciones previas ya fueron aplicadas;
6. qué parte del flujo debe reutilizar y qué parte debe rehacer.

---

## 2. Qué debe entender un agente antes de tocar la GEIH

Antes de escribir código, un agente debe revisar y dejar explícito:

- dónde están las bases consolidadas 2022-2025;
- en qué formato están: `csv`, `parquet`, `rds`, `feather`, `xlsx` u otro;
- si cada archivo corresponde a un mes, un año o un consolidado multianual;
- si la base está a nivel persona, hogar o una mezcla de ambos;
- qué variables identificadoras existen;
- qué variables de peso existen;
- qué variables de fecha o periodo existen;
- qué diccionarios de variables están disponibles;
- qué catálogos de etiquetas o equivalencias deben cargarse.

Si esta revisión no queda clara, el agente no debe avanzar a cálculos o visualizaciones.

---

## 3. Alcance de este instructivo

Este documento se enfoca en:

- cómo organizar los módulos mensuales;
- cómo hacer el **pegado** de módulos;
- cómo consolidar todos los meses;
- cómo recodificar variables;
- cómo seleccionar subconjuntos temáticos;
- cómo calcular indicadores ponderados;
- cómo dejar una lógica reusable para cualquier stack.

Este documento no está pensado para describir una app, un dashboard o una capa visual.

---

## 4. Estructura típica de la GEIH

La GEIH normalmente viene separada por módulos temáticos y por periodos. La organización recomendada es por mes:

```text
datos/
  enero/
  febrero/
  marzo/
  ...
```

Y dentro de cada mes aparecen archivos como:

- `Características generales, seguridad social en salud y educación.CSV`
- `Datos del hogar y la vivienda.CSV`
- `Fuerza de trabajo.CSV`
- `Ocupados.CSV`
- `No ocupados.CSV`
- `Otras formas de trabajo.CSV`
- `Otros ingresos e impuestos.CSV`
- `Migración.CSV`

Esto refleja algo clave para cualquier agente:

**la GEIH no se trabaja como una sola tabla original, sino como un conjunto de módulos que deben integrarse correctamente**.

---

## 5. Variables clave que un agente debe buscar

Las variables clave que un agente debe buscar son:

- `DIRECTORIO`
- `SECUENCIA_P`
- `ORDEN`
- `HOGAR`
- `FEX_C18`
- `DPTO`
- `AREA`
- `MES`
- `PERIODO`
- `PER`
- `OCI`
- `DSI`
- `INGLABO`
- `PT`
- `FT`
- `PET`

Además, el agente debe verificar si en las bases de este proyecto aparecen variables equivalentes o nombres alternativos según el año.

No se debe asumir que todos los años usan exactamente los mismos nombres.

---

## 6. Llaves de unión: qué revisar y cómo pensar el pegado

Una estructura de llaves útil como referencia es:

```r
c("DIRECTORIO", "SECUENCIA_P", "ORDEN", "HOGAR", "FEX_C18")
```

Y luego toma la intersección con las columnas realmente disponibles en cada módulo:

```r
new_key_variables <- intersect(colnames(df), key_variables)
```

### Lectura metodológica correcta

La llave fuerte de la GEIH normalmente está asociada a la identificación de:

- vivienda;
- hogar;
- persona.

Por eso, conceptualmente el agente debe pensar primero en:

- `DIRECTORIO`
- `SECUENCIA_P`
- `HOGAR`
- `ORDEN`

`FEX_C18` debe tratarse ante todo como **factor de expansión**. Si aparece en el `merge`, hay que validarlo, no copiarlo ciegamente.

### Regla operativa

El agente debe:

1. identificar qué llaves existen en cada módulo;
2. verificar la granularidad del módulo;
3. hacer la unión según la unidad de análisis;
4. documentar cualquier excepción.

---

## 7. Cómo se debe hacer el “pegado”

El flujo recomendado es:

1. ubicar la carpeta del mes;
2. listar todos los `.csv`;
3. leer un archivo base;
4. recorrer el resto de módulos;
5. hacer `merge` sucesivo por las llaves comunes;
6. limpiar columnas duplicadas `.x` y `.y`;
7. devolver una sola tabla ancha del mes.

Una operación tipo sería:

```r
final_df <- merge(final_df, df, by = new_key_variables, all.x = TRUE)
```

### Qué significa esto en lenguaje metodológico

- se conserva la estructura del archivo base;
- si una observación no aparece en otro módulo, se mantiene con `NA`;
- el resultado final es una base mensual integrada por persona/hogar.

### Traducción a cualquier lenguaje

Esto se puede implementar en `R`, `Python/pandas`, `polars`, `DuckDB`, `SQL` o `Spark`, siempre que se respete:

- identificación correcta de llaves;
- unión controlada;
- manejo de duplicados;
- preservación de la unidad de análisis.

---

## 8. Cómo se consolida el conjunto de meses

La consolidación mensual-anual debe hacer lo siguiente:

1. lista las carpetas mensuales;
2. ejecuta el pegado para cada mes;
3. apila todos los meses;
4. guarda una base completa.

La lógica central es:

```r
all_months <- rbindlist(list(all_months, merge_month(month)), fill = TRUE)
```

### Lectura práctica

- primero se pega dentro de cada mes;
- después se pegan los meses entre sí;
- `fill = TRUE` permite combinar meses incluso si cambian algunas columnas.

### Regla para este proyecto

Como aquí ya existen bases consolidadas 2022-2025, un agente debe:

- revisar si esos consolidados son el producto final de esta etapa;
- no rehacer el pegado completo salvo que haya una razón explícita;
- documentar si está usando bases ya pegadas o si está reconstruyendo el pipeline.

---

## 9. Qué diccionarios y metadatos debe traer un agente

Para trabajar bien la GEIH no basta con tener la base. También hay que traer los diccionarios y materiales de apoyo.

### Insumos que el agente debe buscar o construir

- diccionario de variables por año;
- tablas de etiquetas de categorías;
- equivalencias de nombres cuando cambian entre años;
- notas metodológicas del DANE;
- definición formal de indicadores;
- listado de variables clave por tema.

### Mínimos que deben quedar documentados

- nombre de la variable;
- significado;
- tipo de dato;
- universo poblacional;
- valores válidos;
- codificación de categorías;
- observaciones por cambio entre años.

### Regla importante

Si el proyecto tiene varios años, el agente debe crear o mantener una capa de **estandarización semántica**.  
No basta con leer columnas; hay que saber si una variable de 2022 significa exactamente lo mismo en 2025.

---

## 10. Recodificaciones que un agente debe contemplar

Un flujo serio de trabajo con GEIH debe contemplar transformaciones de este tipo:

Entre las recodificaciones encontradas están:

- `DPTO`: código a nombre del departamento;
- `P6070`: estado civil;
- `P3042`: nivel educativo;
- `P6090`: acceso a salud;
- `P6100`: afiliación al sistema de salud;
- `P6430`: posición ocupacional;
- `P5090`: tenencia de vivienda;
- `P3386`: motivo de migración;
- `P3271`: sexo;
- `P4030S1`, `P4030S2`, `P4030S3`, `P4030S5`: condiciones del hogar.


### Qué debe hacer un agente con esto

No copiar estas etiquetas solo por copiarlas. Debe:

1. verificar si aplican al año que está trabajando;
2. guardar estas equivalencias en una capa reusable;
3. separarlas de la lógica de análisis;
4. preferir estructuras tipo diccionario o tabla de mapeo, no `if` dispersos por todo el proyecto.

---

## 11. Funciones analíticas que un agente debería construir o mantener

Independientemente del lenguaje, el proyecto debería tener funciones reutilizables para:

- recodificación de variables;
- selección de variables temáticas;
- construcción de subconjuntos analíticos;
- indicadores nacionales;
- indicadores departamentales;
- indicadores por sexo;
- indicadores por edad;
- indicadores de educación;
- indicadores de vivienda;
- indicadores de salud;
- indicadores de mercado laboral.

### Cómo debe pensar esto un agente

Estas funciones deben existir como piezas modulares, no como lógica dispersa dentro de notebooks o visualizaciones.

---

## 12. Cómo se pasan los datos desde la base consolidada hacia análisis

El flujo recomendado es:

1. leer `geih_año.csv`;
2. recodificar variables;
3. definir subconjuntos temáticos;
4. construir tablas filtradas;
5. aplicar funciones de agregación ponderada.


### Regla general

Un agente debe trabajar la base consolidada en capas:

1. capa cruda consolidada;
2. capa estandarizada;
3. capa temática;
4. capa de indicadores.

No conviene mezclar todo en un solo archivo intermedio.

---

## 13. Uso del factor de expansión

Esta es una regla crítica.

Los indicadores se deben calcular ponderando con `FEX_C18`, por ejemplo:

```r
sum(FEX_C18, na.rm = TRUE)
sum(OCI * FEX_C18, na.rm = TRUE)
sum(DSI * FEX_C18, na.rm = TRUE)
```

### Lo que un agente debe asumir

- la GEIH es una encuesta;
- no se deben interpretar conteos simples como población real;
- los indicadores deben calcularse con el factor de expansión correcto;
- cualquier cambio de periodo o de universo debe revisarse metodológicamente.

### Regla adicional

Si un agente produce una métrica sin ponderación, debe marcarlo explícitamente como exploratorio y no como estimación oficial.

---

## 14. Cuidado con promedios anuales y divisiones por 12

En algunos flujos de trabajo pueden aparecer expresiones como:

```r
sum(FEX_C18, na.rm = TRUE) / 12
sum(OCI * FEX_C18, na.rm = TRUE) / 12
sum(DSI * FEX_C18, na.rm = TRUE) / 12
```

Esto sugiere que algunos resultados están pensados como promedio anual a partir de 12 meses consolidados.

### Regla metodológica

Un agente nunca debe dividir por `12` por inercia.

Primero debe verificar:

- si realmente hay 12 meses disponibles;
- si el objetivo es anual, mensual o trimestral;
- si el denominador correcto debe ser 12, el número de meses observados o ninguno;
- si el indicador debe calcularse sobre una base puntual o promedio.

---

## 15. Flujo recomendado de trabajo para un agente en este proyecto

### Fase 1. Reconocimiento

- localizar bases GEIH 2022-2025 ya consolidadas;
- inventariar formatos y nombres;
- identificar diccionarios, catálogos y documentación;
- registrar unidad de análisis y variables clave.

### Fase 2. Validación estructural

- revisar llaves;
- revisar duplicados;
- revisar cobertura temporal;
- revisar si cambian columnas entre años;
- revisar consistencia de tipos de datos.

### Fase 3. Estandarización

- homologar nombres de variables;
- consolidar etiquetas;
- construir tablas de mapeo reutilizables;
- separar variables crudas de variables recodificadas.

### Fase 4. Construcción analítica

- crear subconjuntos temáticos;
- definir funciones puras para indicadores;
- aplicar ponderación;
- documentar universo y filtros.

### Fase 5. Validación

- contrastar resultados con boletines o tabulados oficiales cuando aplique;
- revisar órdenes de magnitud;
- registrar decisiones metodológicas.

---

## 16. Arquitectura sugerida, independiente del lenguaje

El flujo ideal debe poder representarse así:

**microdatos o bases ya pegadas -> validación estructural -> diccionarios/metadatos -> estandarización -> subconjuntos temáticos -> indicadores -> productos analíticos**

### Componentes que deberían existir o construirse

- una carpeta de bases crudas o consolidadas;
- una carpeta de diccionarios;
- una carpeta de funciones;
- una capa de configuración o constantes;
- una capa de indicadores;
- una capa de validación.

### Regla de diseño

Las etiquetas, equivalencias y diccionarios no deben quedar enterrados dentro de notebooks o apps.  
Deben vivir en archivos reutilizables.

---

## 17. Qué no debe hacer un agente

- no empezar por la app o el dashboard;
- no asumir que una base consolidada ya está lista para analizar sin revisión;
- no usar `FEX_C18` como si fuera una columna cualquiera;
- no mezclar recodificación con visualización;
- no hardcodear etiquetas en muchos archivos;
- no asumir que 2022, 2023, 2024 y 2025 son idénticos;
- no copiar ciegamente decisiones del proyecto en `R` sin validarlas en este contexto.

---

## 18. Qué sí debe dejar listo un agente cuando trabaje la GEIH aquí

Como mínimo, debe dejar:

- inventario de bases disponibles 2022-2025;
- descripción de formatos y cobertura temporal;
- diccionario o mapa de variables clave;
- reglas de unión y unidad de análisis;
- funciones reutilizables para indicadores;
- notas metodológicas sobre ponderación;
- advertencias sobre diferencias entre años;
- separación clara entre base cruda, base estandarizada y base analítica.

---

## 19. Resumen ejecutivo para otro agente

Si entras a este proyecto a trabajar GEIH, debes asumir esto:

1. aquí ya hay bases consolidadas de 2022 a 2025;
2. tu trabajo principal es entenderlas, validarlas, documentarlas y usarlas bien;
3. tu trabajo es usar una metodología clara de pegado, estandarización y análisis, no empezar por una app;
4. necesitas traer diccionarios, equivalencias y metadatos;
5. debes trabajar con una lógica portable a `Python`, `R` o cualquier stack;
6. el factor de expansión `FEX_C18` es obligatorio en indicadores poblacionales;
7. primero va la metodología de datos, después cualquier producto visual.

---

## 20. Conclusión

La lección principal de este instructivo es esta:

**trabajar la GEIH bien no es solo “leer un CSV” ni “hacer una app”, sino construir una metodología reproducible para unir módulos, entender variables, estandarizar años, aplicar ponderaciones y producir indicadores confiables.**

Ese es el estándar que debe seguir cualquier agente de IA que entre a trabajar esta carpeta.
