############################################################
# R/plot_theme.R — Tema visual de marca para plotly
# Identidad "Premium Dark Tech" de Daniel Molina.
# (Tokens espejo de personal_landing/colores_paleta.md)
############################################################
suppressMessages(library(plotly))

# --- Tokens de marca --------------------------------------------------------
BRAND <- list(
  bg          = "#0A0E1A",
  surface_1   = "#0F1729",
  surface_alt = "#131C31",
  surface_2   = "#18233C",
  surface_3   = "#202D4E",
  violet      = "#1E40AF",
  primary     = "#2563EB",
  cyan        = "#06B6D4",
  accent      = "#10B981",
  text_title  = "#F9FAFB",
  text_body   = "#E5E7EB",
  text_muted  = "#9CA3AF",
  grid        = "rgba(255,255,255,0.06)",
  zero        = "rgba(255,255,255,0.14)"
)
FUENTE <- "Inter, system-ui, -apple-system, sans-serif"

# Paleta secuencial del gradiente de marca (violet -> primary -> cyan)
PALETA   <- colorRampPalette(c(BRAND$violet, BRAND$primary, BRAND$cyan))(9)
paleta_n <- function(n) colorRampPalette(c(BRAND$violet, BRAND$primary, BRAND$cyan))(max(n, 2))

# Colores por sexo
COLOR_SEXO <- c(Hombre = BRAND$primary, Mujer = BRAND$cyan)

# Compatibilidad: fondo usado por módulos antiguos (ahora transparente)
COLOR_FONDO <- "rgba(0,0,0,0)"

.f <- function(color = BRAND$text_body, size = 12) list(family = FUENTE, color = color, size = size)

# Aplica el tema de marca a un gráfico plotly.
# xaxis/yaxis: listas con overrides puntuales (se fusionan con el estilo base).
aplicar_tema <- function(p, xaxis = list(), yaxis = list(),
                         legend = list(), margin = list(l = 80, r = 24, t = 16, b = 40),
                         barmode = NULL) {
  base_x <- list(gridcolor = BRAND$grid, zerolinecolor = BRAND$zero, zerolinewidth = 1,
                 linecolor = BRAND$grid, tickfont = .f(BRAND$text_muted), titlefont = .f(BRAND$text_body, 13))
  base_y <- list(gridcolor = BRAND$grid, zerolinecolor = BRAND$zero,
                 tickfont = .f(BRAND$text_body), titlefont = .f(BRAND$text_body, 13), automargin = TRUE)
  layout(p,
    font          = .f(),
    xaxis         = modifyList(base_x, xaxis),
    yaxis         = modifyList(base_y, yaxis),
    legend        = modifyList(list(font = .f(), bgcolor = "rgba(0,0,0,0)"), legend),
    barmode       = barmode,
    plot_bgcolor  = "rgba(0,0,0,0)",
    paper_bgcolor = "rgba(0,0,0,0)",
    margin        = margin,
    hoverlabel    = list(font = list(family = FUENTE, color = "#fff"),
                         bgcolor = BRAND$surface_2, bordercolor = BRAND$cyan)
  )
}

# Quita la barra de herramientas de plotly (look más limpio).
sin_barra <- function(p) config(p, displayModeBar = FALSE)
