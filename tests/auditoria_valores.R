############################################################
# Auditoría de coherencia de valores (año de referencia 2024, Nacional, Todos)
#  1) agregados.rds vs recálculo directo desde microdato (deben coincidir)
#  2) coherencia interna (relaciones que deben cumplirse)
#  3) rangos oficiales DANE
############################################################
suppressMessages(library(data.table))
source("R/aggregate.R"); source("R/recodes.R"); source("R/indicadores.R")
A <- 2024
ag <- readRDS("agregados.rds")
gA <- function(k) ag[[k]][geo == "Nacional" & anio == A & migrante == "Todos"]

# --- Microdato directo (2024) ---
cols <- c("FEX_C18","MES","P3271","OCI","DSI","P6040","P6050","HOGAR","P6160","P6090","P3042")
d <- fread(sprintf("datos/geih_%d.csv", A), select = cols)
nm <- uniqueN(d$MES)
W  <- function(x) sum(d$FEX_C18[x], na.rm = TRUE) / nm   # ponderado / meses

pob_d  <- W(rep(TRUE, nrow(d)))
oc_d   <- sum(d$OCI * d$FEX_C18, na.rm = TRUE) / nm
ds_d   <- sum(d$DSI * d$FEX_C18, na.rm = TRUE) / nm
pet_d  <- W(d$P6040 >= 15)
hog_d  <- W(d$P6050 == 1)
viv_d  <- W(d$P6050 == 1 & d$HOGAR == 1)

ok <- function(cond) if (isTRUE(cond)) "PASS" else "FALLA"
rel <- function(a, b) if (b == 0) NA else abs(a - b) / b * 100   # % de diferencia
cmp <- function(nombre, val_ag, val_dir, tol = 0.1) {
  diff <- rel(val_ag, val_dir)
  cat(sprintf("  %-28s ag=%-14s dir=%-14s dif=%.3f%%  [%s]\n",
              nombre, format(round(val_ag), big.mark=","), format(round(val_dir), big.mark=","),
              diff, ok(diff < tol)))
}

cat("== 1) AGREGADOS vs MICRODATO (2024 Nacional Todos) ==\n")
cmp("Población",  sum(gA("sexo")$personas), pob_d)
lab <- gA("laboral")
cmp("Ocupados",   sum(lab$ocupados), oc_d)
cmp("Desocupados",sum(lab$desocupados), ds_d)
cmp("PET (15+)",  sum(lab$pet), pet_d)
cmp("Hogares",    gA("conteo_unidades")$hogares, hog_d)
cmp("Viviendas",  gA("conteo_unidades")$viviendas, viv_d)

cat("\n== 2) COHERENCIA INTERNA ==\n")
sx <- gA("sexo")
cat(sprintf("  Sexo %% suma 100:            %.1f  [%s]\n", sum(sx$pct), ok(abs(sum(sx$pct)-100)<0.2)))
# Pirámide: suma de grupos = población
pir <- gA("piramide"); cat(sprintf("  Pirámide total vs Población: dif=%.3f%%  [%s]\n",
    rel(sum(pir$personas), sum(sx$personas)), ok(rel(sum(pir$personas), sum(sx$personas))<0.1)))
# Laboral: ocupados+desocupados = fuerza_trabajo
cat(sprintf("  OC+DS = Fuerza de trabajo:  dif=%.3f%%  [%s]\n",
    rel(sum(lab$ocupados)+sum(lab$desocupados), sum(lab$fuerza_trabajo)),
    ok(rel(sum(lab$ocupados)+sum(lab$desocupados), sum(lab$fuerza_trabajo))<0.01)))
TD  <- sum(lab$desocupados)/sum(lab$fuerza_trabajo)*100
TO  <- sum(lab$ocupados)/sum(lab$pet)*100
TGP <- sum(lab$fuerza_trabajo)/sum(lab$pet)*100
cat(sprintf("  TO = TGP*(1-TD):            TO=%.1f  esperado=%.1f  [%s]\n",
    TO, TGP*(1-TD/100), ok(abs(TO - TGP*(1-TD/100))<0.1)))
# Rama: total ocupados rama ~ ocupados laboral
cat(sprintf("  Rama total ~ Ocupados:      dif=%.2f%%  [%s]\n",
    rel(sum(gA("rama_economica")$personas), sum(lab$ocupados)),
    ok(rel(sum(gA("rama_economica")$personas), sum(lab$ocupados))<3)))
# Vivienda: viviendas <= hogares; tenencia suma = hogares
u <- gA("conteo_unidades")
cat(sprintf("  Viviendas <= Hogares:       %s <= %s  [%s]\n",
    format(round(u$viviendas),big.mark=","), format(round(u$hogares),big.mark=","), ok(u$viviendas<=u$hogares)))
cat(sprintf("  Tenencia suma = Hogares:    dif=%.2f%%  [%s]\n",
    rel(sum(gA("tipo_vivienda")$personas), u$hogares), ok(rel(sum(gA("tipo_vivienda")$personas), u$hogares)<1)))
cat(sprintf("  Materiales/Sanitario=Hogares: par=%.1f%% san=%.1f%%\n",
    rel(sum(gA("material_paredes")$personas),u$hogares), rel(sum(gA("sanitario")$personas),u$hogares)))

cat("\n== 3) RANGOS OFICIALES DANE (2024) ==\n")
rango <- function(nombre, val, lo, hi, u="") cat(sprintf("  %-26s %8.1f%s   esperado [%g-%g]  [%s]\n",
    nombre, val, u, lo, hi, ok(val>=lo & val<=hi)))
rango("Población (millones)", sum(sx$personas)/1e6, 51, 53)
rango("Tasa desempleo TD %", TD, 8, 12)
rango("Tasa ocupación TO %", TO, 54, 62)
rango("Tasa participación TGP %", TGP, 62, 67)
al <- gA("alfabetismo"); analf <- sum(al[alfabetismo=="No",personas])/sum(al$personas)*100
rango("Analfabetismo 15+ %", analf, 3, 6)
sal <- gA("acceso_salud"); cob <- sum(sal[acceso_salud=="Sí",personas])/sum(sal$personas)*100
rango("Cobertura salud %", cob, 92, 99)
rango("Hogares (millones)", u$hogares/1e6, 16, 19)
ven <- sum(ag$sexo[geo=="Nacional"&anio==A&migrante=="Venezolano"]$personas)
rango("Migrantes venezolanos (M)", ven/1e6, 1.5, 3.0)

cat("\nAuditoría finalizada.\n")
