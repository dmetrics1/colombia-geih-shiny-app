# Protocolo para trabajar `diccionario.xlsx` de la GEIH

## Objetivo

Este documento explica cómo debe usar un agente de IA el archivo:

`portafolio\bases_datos\geih\diccionario.xlsx`

La meta es convertir ese archivo en una capa de mapeo reusable para interpretar las variables codificadas de la GEIH.

---

## 1. Archivo fuente

El diccionario de este proyecto está en:

`portafolio\bases_datos\geih\diccionario.xlsx`

Las bases de datos están en:

`portafolio\bases_datos\geih\datos`

El agente debe asumir que muchas columnas de la GEIH vienen codificadas y que no se pueden interpretar directamente sin consultar este diccionario.

---

## 2. Estructura observada del diccionario

El archivo `diccionario.xlsx` tiene actualmente:

- una hoja: `Hoja1`

Y las columnas observadas son:

- `nombre_variable`
- `etiqueta_variable`
- `descripcion`
- `pregunta_literal`
- `tipo_variable`
- `codigo_categoria`
- `categoria`

### Interpretación de estas columnas

- `nombre_variable`: nombre técnico de la variable en la base.
- `etiqueta_variable`: etiqueta corta o nombre legible de la variable.
- `descripcion`: descripción adicional, si existe.
- `pregunta_literal`: texto de la pregunta o contexto del campo.
- `tipo_variable`: tipo esperado de la variable.
- `codigo_categoria`: código almacenado en la base.
- `categoria`: significado del código.

---

## 3. Qué debe hacer un agente con este diccionario

El agente no debe limitarse a leer el Excel. Debe convertirlo en una estructura de trabajo reusable.

Como mínimo, debe construir:

- un diccionario por variable;
- una tabla de equivalencias `codigo -> categoria`;
- una capa de metadatos de variables;
- una forma automática de recodificar columnas de la base.

---

## 4. Regla principal de interpretación

Si una variable aparece codificada en la base, el agente debe buscarla en `diccionario.xlsx` y construir su mapeo a partir de:

- `nombre_variable`
- `codigo_categoria`
- `categoria`

La relación central es:

**nombre_variable + codigo_categoria -> categoria**

---

## 5. Estructuras mínimas que el agente debe generar

### A. Tabla maestra del diccionario

Debe conservar la tabla completa del Excel, limpiando:

- espacios sobrantes;
- filas vacías;
- tipos inconsistentes;
- duplicados exactos.

### B. Diccionario de mapeo por variable

Ejemplo conceptual:

```text
{
  "AREA": {
    "05": "Medellín AM",
    "08": "Barranquilla AM",
    "11": "Bogotá DC"
  },
  "P3271": {
    "1": "Hombre",
    "2": "Mujer"
  }
}
```

### C. Tabla de metadatos por variable

Ejemplo conceptual:

```text
nombre_variable | etiqueta_variable | descripcion | pregunta_literal | tipo_variable
```

Esto sirve para documentación, validación y trazabilidad.

---

## 6. Flujo recomendado de trabajo

### Paso 1. Leer el diccionario

Leer `diccionario.xlsx` y normalizar nombres de columnas.

### Paso 2. Limpiar tipos

El agente debe convertir `codigo_categoria` a texto para evitar errores como:

- `05` leído como `5`;
- códigos numéricos mezclados con texto;
- pérdida de ceros a la izquierda.

### Paso 3. Agrupar por variable

Agrupar por `nombre_variable` para construir un mapa de categorías por variable.

### Paso 4. Separar metadatos y categorías

Conviene tener dos capas:

- metadatos de la variable;
- categorías de la variable.

### Paso 5. Aplicar recodificación a las bases

Cuando una columna de datos coincida con `nombre_variable`, el agente debe:

1. convertir sus valores a texto si hace falta;
2. buscar el código en el mapa;
3. crear una columna recodificada o reemplazar la original, según la estrategia del proyecto.

---

## 7. Regla sobre tipos y ceros a la izquierda

Este punto es crítico.

Hay variables como `AREA` donde códigos como `05`, `08` o `11` tienen significado y no deben perder formato.

Por eso:

- `codigo_categoria` debe tratarse como texto;
- las variables geográficas o categóricas codificadas deben compararse como texto;
- no se debe forzar a entero si eso elimina ceros a la izquierda.

---

## 8. Estrategias válidas para recodificar

### Opción 1. Mantener columna original y crear columna etiquetada

Ejemplo:

- `AREA` se conserva;
- `AREA_label` se crea con el nombre de la categoría.

Esta opción es la más segura para análisis y auditoría.

### Opción 2. Reemplazar directamente la columna

Esto solo conviene si:

- el proyecto ya no necesita el código original;
- no habrá merges posteriores con el código;
- la trazabilidad no se pierde.

### Recomendación

Preferir la opción 1:

- conservar código;
- agregar etiqueta;
- documentar el origen del mapeo.

---

## 9. Validaciones mínimas que debe hacer un agente

Después de construir el mapeo, el agente debe validar:

- cuántas variables de la base tienen correspondencia en el diccionario;
- cuántos códigos de una variable no encontraron categoría;
- si hay categorías duplicadas para el mismo código;
- si hay variables en el diccionario que no existen en la base;
- si hay variables en la base codificadas pero no documentadas en el diccionario.

### Regla de calidad

Si una variable tiene códigos sin mapeo, el agente debe reportarlo explícitamente.

---

## 10. Salidas recomendadas

El procesamiento del diccionario debería dejar, como mínimo:

- una tabla limpia del diccionario;
- un archivo de mapeos por variable;
- un archivo de metadatos por variable;
- un reporte de cobertura del mapeo.

Ejemplos de salidas útiles:

- `diccionario_limpio.parquet`
- `mapeos_variables.json`
- `metadata_variables.parquet`
- `reporte_cobertura_diccionario.md`

No es obligatorio usar esos nombres exactos, pero sí conviene dejar productos equivalentes.

---

## 11. Cómo debería pensarlo un agente en Python

Estrategia sugerida:

1. leer el Excel con `pandas`;
2. convertir `codigo_categoria` a `string`;
3. agrupar por `nombre_variable`;
4. crear un `dict` de mapeos;
5. aplicar `.map()` o `merge()` sobre la base.

### Patrón conceptual

```python
mapeo = {
    variable: {codigo: categoria}
}
```

Luego:

```python
df["AREA_label"] = df["AREA"].astype("string").map(mapeo["AREA"])
```

---

## 12. Cómo debería pensarlo un agente en R

A continuación se muestra un **ejemplo explícito de cómo se hace el mapeo con R** usando la librería `data.table`. Esta macro-función sirve como plantilla integral que un agente debe tomar como base para interpretar las recodificaciones. Contiene los mapeos del diccionario más frecuentes, re-clasificaciones (como educación, grupos de edad y ramas) y factores esenciales de la GEIH:

```r
library(data.table)

# Plantilla base integral de recodificación GEIH en R
etiquetar_geih <- function(data) {
  
  # 1. Departamentos (reemplazo de códigos, manteniendo ceros a la izquierda idealmente, o fcase)
  data[, DPTO := fcase(
      DPTO == "05" | DPTO == "5", "Antioquia",        DPTO == "08" | DPTO == "8", "Atlántico", 
      DPTO == "11", "Bogotá",           DPTO == "13", "Bolívar",         DPTO == "15", "Boyacá",       
      DPTO == "17", "Caldas",           DPTO == "18", "Caquetá",         DPTO == "19", "Cauca",        
      DPTO == "20", "Cesar",            DPTO == "23", "Córdoba",         DPTO == "25", "Cundinamarca", 
      DPTO == "27", "Chocó",            DPTO == "41", "Huila",           DPTO == "44", "La Guajira",   
      DPTO == "47", "Magdalena",        DPTO == "50", "Meta",            DPTO == "52", "Nariño",       
      DPTO == "54", "Norte de Santander", DPTO == "63", "Quindío",       DPTO == "66", "Risaralda",    
      DPTO == "68", "Santander",        DPTO == "70", "Sucre",           DPTO == "73", "Tolima",       
      DPTO == "76", "Valle del Cauca",  DPTO == "81", "Arauca",          DPTO == "85", "Casanare",     
      DPTO == "86", "Putumayo",         DPTO == "88", "San Andrés y Providencia", DPTO == "91", "Amazonas", 
      DPTO == "94", "Guainía",          DPTO == "95", "Guaviare",        DPTO == "97", "Vaupés", 
      DPTO == "99", "Vichada",          default = NA_character_
  )]

  # 2. Edades categóricas (P6040)
  data[, grupo_edad := fcase(
    P6040 >= 10 & P6040 <= 24, "10 a 24 años",
    P6040 >= 25 & P6040 <= 39, "25 a 39 años",
    P6040 >= 40 & P6040 <= 64, "40 a 64 años",
    P6040 >= 65,              "Mayor a 65 años",
    default = "No especificado"
  )]
  
  # 3. Demografía base
  data[, sexo := factor(P3271, levels = c(1, 2, 9), labels = c("Hombre", "Mujer", "No informa"))]
  
  data[, estado_civil := factor(P6070, levels = 1:6, labels = c(
    "Pareja con menos de 2 años", "Pareja con mayor 2 años", "Casado(a)", 
    "Separado(a) o divorciado(a)", "Viudo(a)", "Soltero(a)"
  ))]

  data[, posicion_hogar := factor(P6050, levels = 1:13, labels = c(
    "Jefe(a)", "Pareja", "Hijo(a)", "Padre/madre", "Suegro(a)", "Hermano(a)", 
    "Yerno/Nuera", "Nieto(a)", "Otro pariente", "Empleado servicio doméstico", 
    "Pensionista", "Trabajador", "Otro no pariente"
  ))]

  # 4. Educación y Salud
  data[, nivel_educativo := factor(P3042, levels = c(1:13, 99), labels = c(
    "Ninguno", "Preescolar", "Básica primaria (1o - 5o)", "Básica secundaria (6o - 9o)", 
    "Media académica", "Media técnica", "Normalista", "Técnica profesional", 
    "Tecnológica", "Universitaria", "Especialización", "Maestría", "Doctorado", "No sabe"
  ))]

  data[, P6090 := c("9" = "No informa", "2" = "No", "1" = "Sí")[as.character(P6090)]]
  data[, P6100 := c("1" = "Contributivo", "2" = "Especial", "3" = "Subsidiado", "9" = "No informa")[as.character(P6100)]]
  data[, pension := factor(P6920, levels = 1:3, labels = c("Sí", "No", "Ya es pensionado"))]

  # 5. Mercado Laboral
  data[, lugar_trabajo := factor(P6880, levels = 1:11, labels = c(
    "En esta vivienda", "En otras viviendas", "En kiosco/caseta", "En un vehículo", 
    "De puerta en puerta", "En sitio descubierto/calle", "En local/oficina/fábrica", 
    "Área rural/mar/río", "Obra en construcción", "Mina o cantera", "Otro"
  ))]

  data[, posicion_ocupacional := factor(P6430, levels = 1:9, labels = c(
    "Empleado empresa particular", "Empleado gobierno", "Empleado doméstico", 
    "Cuenta propia", "Patrón o empleador", "Trabajador familiar sin remuneración", 
    "Trabajador sin remuneración", "Jornalero o peón", "Otro"
  ))]

  # 6. Ramas de actividad a dos dígitos (sin dummies - RAMA2D_R4)
  data[, PREFIX_RAMA2D_R4 := as.numeric(substr(RAMA2D_R4, 1, 2))]
  data[, rama_actividad := fcase(
    PREFIX_RAMA2D_R4 <= 3,       "Agro, caza, pesca",
    PREFIX_RAMA2D_R4 %in% c(5:9, 35:39), "Electricidad, gas, agua, desechos",
    PREFIX_RAMA2D_R4 %in% 10:33, "Industria manufacturera",
    PREFIX_RAMA2D_R4 %in% 41:43, "Construcción",
    PREFIX_RAMA2D_R4 %in% 45:47, "Comercio y reparación vehículos",
    PREFIX_RAMA2D_R4 %in% 49:53, "Transporte y almacenamiento",
    PREFIX_RAMA2D_R4 %in% 55:56, "Alojamiento y comida",
    PREFIX_RAMA2D_R4 %in% 58:63, "Información y comunicaciones",
    PREFIX_RAMA2D_R4 %in% 64:66, "Financieras y seguros",
    PREFIX_RAMA2D_R4 == 68,      "Inmobiliarias",
    PREFIX_RAMA2D_R4 %in% 69:82, "Profesionales, científicas y técnicas",
    PREFIX_RAMA2D_R4 %in% 84:88, "Administración pública, educación, salud",
    PREFIX_RAMA2D_R4 >= 90,      "Artes, recreación y otros servicios",
    default = "No clasificado"
  )]

  # 7. Migración y Hogar (usando vector lookup para strings)
  data[, P3386 := c("1"="Trabajo", "2"="Estudio", "3"="Salud", "4"="Conflicto armado", 
                    "5"="Violencia", "6"="Desastres", "7"="Nuevo hogar", "8"="Acompañar hogar", 
                    "9"="Motivos culturales", "10"="Vivienda propia", "12"="Otro")[as.character(P3386)]]
  
  data[, P5090 := c("1"="Propia, pagada", "2"="Propia, la están pagando", "3"="En arriendo/subarriendo", 
                    "4"="En usufructo", "5"="Posesión sin título", "6"="Propiedad colectiva", "7"="Otra")[as.character(P5090)]]
  
  # Condiciones de hogar (1=sí, 2=no)
  rep_con <- c("1" = "si", "2" = "no")
  data[, c("P4030S1", "P4030S2", "P4030S3", "P4030S5") := .(
      rep_con[as.character(P4030S1)], rep_con[as.character(P4030S2)], 
      rep_con[as.character(P4030S3)], rep_con[as.character(P4030S5)]
  )]

  return(data)
}
```

Es mandatario que un agente entienda y asuma este pipeline cuando tenga que "traducir" los códigos crudos de la GEIH a clasificaciones listas para análisis y dashboards usando `R`.

---

## 13. Qué no debe hacer un agente

- no inventar etiquetas;
- no recodificar con supuestos sin revisar el diccionario;
- no convertir automáticamente todos los códigos a enteros;
- no perder ceros a la izquierda;
- no mezclar metadatos con categorías sin control;
- no sobrescribir la base sin conservar una versión auditable.

---

## 14. Regla final

El diccionario no es un archivo auxiliar menor.  
Es parte central del pipeline de trabajo con la GEIH.

Si un agente no usa bien `diccionario.xlsx`, corre el riesgo de:

- interpretar mal variables;
- asignar categorías incorrectas;
- producir indicadores erróneos;
- romper la comparabilidad entre años.

Por eso, toda transformación de variables codificadas debe quedar trazable y apoyada en el diccionario.

