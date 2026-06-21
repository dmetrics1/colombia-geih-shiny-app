############################################################
# Fase 1 — Validación de continuidad entre años (2022-2025)
# Compara los encabezados de los 4 CSV y la presencia de
# variables clave. Solo lee cabeceras (instantáneo).
############################################################
suppressMessages(library(data.table))

anios   <- 2022:2025
archivos <- sprintf("datos/geih_%d.csv", anios)
names(archivos) <- anios
stopifnot(all(file.exists(archivos)))

# Encabezados por año
headers <- lapply(archivos, function(f) names(fread(f, nrows = 0)))

cat("== Nº de columnas por año ==\n")
for (a in as.character(anios)) cat(sprintf("  %s: %d columnas\n", a, length(headers[[a]])))

# Núcleo común y diferencias
comunes <- Reduce(intersect, headers)
cat(sprintf("\n== Columnas comunes a los 4 años: %d ==\n", length(comunes)))
for (a in as.character(anios)) {
  solo <- setdiff(headers[[a]], comunes)
  cat(sprintf("  Solo en %s (%d): %s\n", a, length(solo),
              if (length(solo)) paste(head(solo, 30), collapse = ", ") else "—"))
}

# Variables clave que el proyecto necesita
clave <- c("DIRECTORIO","SECUENCIA_P","ORDEN","HOGAR","FEX_C18","DPTO","AREA","MES",
           "PERIODO","PER","OCI","DSI","INGLABO","PT","FT","PET","P3271","P6040",
           "P6070","P3042","P6090","P6100","P6430","P5090",
           "P4030S1","P4030S2","P4030S3","P4030S5")
migra <- c("P3373S3","P3374S1","P3374S2","P3374S3","P3386")

chk <- function(vars, titulo) {
  cat(sprintf("\n== %s ==\n", titulo))
  tab <- sapply(as.character(anios), function(a) ifelse(vars %in% headers[[a]], "sí", "NO"))
  rownames(tab) <- vars
  print(tab, quote = FALSE)
  faltan_alguno <- vars[apply(tab, 1, function(r) any(r == "NO"))]
  if (length(faltan_alguno))
    cat("  ⚠️ Faltan en algún año:", paste(faltan_alguno, collapse = ", "), "\n")
  else cat("  ✅ Presentes en los 4 años\n")
}
chk(clave, "Variables clave (estructura/indicadores)")
chk(migra, "Variables de migración")
