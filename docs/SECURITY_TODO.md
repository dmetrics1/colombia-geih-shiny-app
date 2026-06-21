# 🔴 Pendientes de seguridad

## 1. Token de shinyapps.io expuesto en el historial de git

**Qué pasó:** el archivo `clave.R` (credenciales de despliegue: `name`, `token`, `secret`) estuvo
versionado. Aunque luego se borró y hoy está en `.gitignore`, **borrar un archivo no lo elimina del
historial**: las credenciales siguen siendo recuperables.

**Commits afectados:**
- `8e44899` — subió `clave.R` con el token de la cuenta **`jsidte-daniel-molina`** (la cuenta de la
  app en vivo). **Este commit está en GitHub → token público.**
- `a6182a1` — "Delete clave.R" (lo borra del árbol, pero NO del historial).
- Un segundo juego de credenciales (cuenta `7pwu2b-daniel-molina`) existe solo en el stash local
  `stash@{0}` (no está en GitHub).

### Acciones (en orden)

1. **Rotar/revocar el token YA** en shinyapps.io → *Account → Tokens → Remove* y generar uno nuevo.
   Esto invalida el token filtrado y es lo más importante. Hacer lo mismo para ambas cuentas si
   ambas siguen activas.
2. **No volver a versionar `clave.R`** (ya está en `.gitignore`). Usar variables de entorno /
   `.Renviron` (también ignorado) para las credenciales.
3. *(Opcional, más invasivo)* **Purgar el historial** para borrar el secret de los commits viejos
   con `git filter-repo` o BFG, seguido de `git push --force`. Reescribe hashes; coordinar antes de
   hacerlo. Si el token ya fue rotado, el riesgo del histórico queda neutralizado aunque no se purgue.

> Estado: **token aún no rotado** (acción del usuario). Una vez rotado, marcar esta sección como resuelta.
