############################################################
# Fase 1 — Procesar diccionario.xlsx -> capa de mapeo reusable
# (protocolo: códigos como texto, conservar original + label,
#  reporte de cobertura)
############################################################
suppressMessages(library(openxlsx))
suppressMessages(library(data.table))

fp <- "docs/data-dictionary/diccionario.xlsx"
d  <- as.data.table(read.xlsx(fp, sheet = 1))

cat("== Estructura del diccionario ==\n")
cat("dim:", nrow(d), "x", ncol(d), "\n")
cat("cols:", paste(names(d), collapse = " | "), "\n\n")

# Normalizar nombres de columna (minúsculas)
setnames(d, tolower(names(d)))
need <- c("nombre_variable", "codigo_categoria", "categoria")
if (!all(need %in% names(d))) {
  cat("⚠️ Faltan columnas esperadas. Encontradas:", paste(names(d), collapse=", "), "\n")
}

# Códigos como TEXTO (preservar ceros a la izquierda)
d[, codigo_categoria := trimws(as.character(codigo_categoria))]
d[, nombre_variable  := trimws(as.character(nombre_variable))]
d[, categoria        := trimws(as.character(categoria))]

# Filas que sí son categorías (tienen código y etiqueta)
cats <- d[!is.na(codigo_categoria) & codigo_categoria != "" &
          !is.na(categoria) & categoria != ""]

cat("== Cobertura ==\n")
cat("Variables distintas en el diccionario:", uniqueN(d$nombre_variable), "\n")
cat("Variables con categorías mapeables:", uniqueN(cats$nombre_variable), "\n\n")

# Construir mapeo: variable -> named vector(code = category)
mapa <- split(cats, by = "nombre_variable", keep.by = FALSE)
mapa <- lapply(mapa, function(x) setNames(x$categoria, x$codigo_categoria))

# Variables que usa el dashboard
dash <- c("DPTO","P3271","P6070","P3042","P6090","P6100","P6430","P5090",
          "P3386","P4030S1","P4030S2","P4030S3","P4030S5","P6050","P6880","AREA")
cat("== Cobertura de variables del dashboard ==\n")
for (v in dash) {
  if (!is.null(mapa[[v]]))
    cat(sprintf("  %-9s OK  (%d categorías)\n", v, length(mapa[[v]])))
  else
    cat(sprintf("  %-9s -- sin mapeo en diccionario\n", v))
}

# Ejemplos
cat("\n== Ejemplo P3271 (sexo) ==\n");  print(mapa[["P3271"]])
cat("\n== Ejemplo P6090 (salud) ==\n"); print(mapa[["P6090"]])

# Guardar la capa de mapeo
saveRDS(mapa, "docs/data-dictionary/mapeos_variables.rds")
fwrite(cats[, .(nombre_variable, codigo_categoria, categoria)],
       "docs/data-dictionary/diccionario_categorias.csv")
cat("\nGuardado: mapeos_variables.rds + diccionario_categorias.csv\n")
