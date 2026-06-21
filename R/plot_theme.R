############################################################
# R/plot_theme.R — Tema visual centralizado para plotly
#
# Extrae el estilo repetido en los 12 gráficos de app.R
# (fondo #013B63, fuentes blancas en negrita, márgenes) a
# una sola función reutilizable.
############################################################
suppressMessages(library(plotly))

# Paleta azul secuencial del dashboard.
PALETA <- c("#B4D4DAFF","#A9D2DCFF","#9ECFDDFF","#93CDDFFF","#86CAE1FF",
            "#7AC7E2FF","#76C1DFFF","#72BCDCFF","#6EB6D9FF","#6AB1D6FF",
            "#64AAD2FF","#5BA2CCFF","#529AC6FF","#4993C0FF","#3F8BBAFF",
            "#3885B6FF","#3281B5FF","#2D7DB4FF","#2678B3FF","#1F74B1FF",
            "#1C6FAEFF","#1C6AA8FF","#1C65A3FF","#1C5F9EFF","#1C5A99FF")
COLOR_FONDO   <- "#013B63"
COLOR_SEXO    <- c(Hombre = PALETA[10], Mujer = PALETA[20])

# Fuente blanca en negrita (reutilizada en ejes/leyenda).
.fuente_blanca <- function(size = 12) list(size = size, color = "white", family = "bold")

# Aplica el tema común a un gráfico plotly.
#   x_title, y_title: títulos de ejes (opcionales).
#   x_format: formato de ticks del eje X (p. ej. ",", ".0%").
tema_plotly <- function(p, x_title = "", y_title = "",
                        x_format = NULL, x_range = NULL, margin_l = 120) {
  p %>% layout(
    xaxis = list(title = x_title, tickformat = x_format, range = x_range,
                 tickfont = .fuente_blanca(), titlefont = .fuente_blanca(14)),
    yaxis = list(title = y_title, automargin = TRUE,
                 tickfont = .fuente_blanca(), titlefont = .fuente_blanca(14)),
    legend = list(font = .fuente_blanca()),
    plot_bgcolor  = COLOR_FONDO,
    paper_bgcolor = COLOR_FONDO,
    margin = list(l = margin_l, r = 40, t = 30, b = 40)
  )
}

# Barra horizontal estándar (personas por categoría).
barra_horizontal <- function(data, x, y, color = NULL) {
  plot_ly(data, x = x, y = y, color = color, colors = PALETA,
          type = "bar", orientation = "h",
          text = ~format(round(x, 0), big.mark = ","), textposition = "auto",
          textfont = .fuente_blanca(14), hoverinfo = "text",
          marker = list(line = list(color = "black", width = 1)))
}
