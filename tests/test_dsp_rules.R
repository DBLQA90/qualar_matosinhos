source("dsp_rules.R", encoding = "UTF-8")

failures <- 0

expect_identical <- function(actual, expected, message) {
  if (!identical(actual, expected)) {
    failures <<- failures + 1
    cat(sprintf(
      "FALHA: %s\n  esperado: %s\n  obtido:   %s\n",
      message,
      paste(format(expected), collapse = ", "),
      paste(format(actual), collapse = ", ")
    ))
  }
}

expect_error <- function(expression, message) {
  caught <- tryCatch({
    force(expression)
    FALSE
  }, error = function(error) TRUE)
  if (!caught) {
    failures <<- failures + 1
    cat(sprintf("FALHA: %s\n", message))
  }
}

tmax <- function(date_value, observed, forecast) {
  dsp_classify_tmax(as.Date(date_value), observed, forecast)$alert
}

tmin <- function(date_value, observed, forecast) {
  dsp_classify_tmin(as.Date(date_value), observed, forecast)$alert
}

# --- Limiares e época -------------------------------------------------------

expect_identical(
  dsp_thresholds(as.Date("2026-07-20"), "tmax")$thresholds,
  c(yellow = 33, red = 35),
  "Julho a outubro usa os limiares de verão da máxima."
)
expect_identical(
  dsp_thresholds(as.Date("2026-06-20"), "tmax")$thresholds,
  c(yellow = 32, red = 34),
  "Maio e junho usam os limiares mais baixos da máxima."
)
expect_identical(
  dsp_thresholds(as.Date("2026-07-20"), "tmin")$thresholds,
  c(yellow = 22, red = 25),
  "Julho a outubro usa os limiares de verão da mínima."
)
expect_identical(
  dsp_thresholds(as.Date("2026-06-20"), "tmin")$thresholds,
  c(yellow = 21, red = 24),
  "Maio e junho usam os limiares mais baixos da mínima."
)
expect_identical(
  vapply(
    sprintf("2026-%02d-15", 1:12),
    function(d) dsp_thresholds(as.Date(d), "tmax")$applicable,
    logical(1),
    USE.NAMES = FALSE
  ),
  c(rep(FALSE, 4), rep(TRUE, 6), FALSE, FALSE),
  "A regra DSP só se aplica de maio a outubro."
)
expect_identical(
  dsp_thresholds(as.Date("2026-06-30"), "tmax")$rule,
  "mes 5-6",
  "30 de junho ainda pertence à regra de maio-junho."
)
expect_identical(
  dsp_thresholds(as.Date("2026-07-01"), "tmax")$rule,
  "mes 7-10",
  "1 de julho já pertence à regra de julho-outubro."
)
expect_error(
  dsp_thresholds(as.Date("2026-07-20"), "max"),
  "Um tipo de regra desconhecido deve falhar em vez de escolher limiares errados."
)

# --- Máxima: patamares ------------------------------------------------------

expect_identical(tmax("2026-07-20", c(36, 36, 36), c(36, 36)), "Vermelho",
  "Cinco valores acima do limiar vermelho da máxima dão Vermelho.")
expect_identical(tmax("2026-07-20", c(35, 35, 35), c(35, 35)), "Vermelho",
  "O limiar vermelho da máxima é inclusivo.")
expect_identical(tmax("2026-07-20", c(34, 36, 36), c(36, 36)), "Amarelo",
  "Um único dia abaixo do limiar vermelho impede o Vermelho da máxima.")
expect_identical(tmax("2026-07-20", c(30, 31, 33), c(34, 34)), "Amarelo",
  "A regra amarela da máxima usa D-1, D e D+1.")
expect_identical(tmax("2026-07-20", c(36, 36, 32), c(36, 36)), "Verde",
  "D-1 abaixo do limiar amarelo impede o Amarelo da máxima.")
expect_identical(tmax("2026-07-20", c(20, 20, 20), c(20, 20)), "Verde",
  "Temperaturas baixas dão Verde.")
expect_identical(tmax("2026-06-20", c(30, 31, 32), c(32, 32)), "Amarelo",
  "Em junho o limiar amarelo da máxima é 32 ºC.")

# --- Máxima: dados em falta -------------------------------------------------

expect_identical(tmax("2026-07-20", c(NA, 30, 34), c(34, 34)), "Amarelo",
  "D-3 em falta não suprime um Amarelo determinável da máxima.")
expect_identical(tmax("2026-07-20", c(30, NA, 34), c(34, 34)), "Amarelo",
  "D-2 em falta não suprime um Amarelo determinável da máxima.")
expect_identical(tmax("2026-07-20", c(NA, NA, 34), c(34, 34)), "Amarelo",
  "D-2 e D-3 em falta em simultâneo não suprimem o Amarelo da máxima.")
expect_identical(tmax("2026-07-20", c(NA, 36, 36), c(36, 36)), "Amarelo",
  "Com D-3 em falta o Vermelho fica indeterminável, mas o Amarelo mantém-se.")
expect_identical(tmax("2026-07-20", c(NA, 30, 30), c(30, 30)), "Verde",
  "Uma regra amarela falhada exclui o Vermelho, logo o Verde fica determinado.")
expect_identical(tmax("2026-07-20", c(30, 30, NA), c(34, 34)), "Sem dados",
  "D-1 em falta impede avaliar a regra amarela da máxima.")
expect_identical(tmax("2026-07-20", c(30, 30, 34), c(NA, 34)), "Sem dados",
  "D em falta impede avaliar a regra amarela da máxima.")
expect_identical(tmax("2026-07-20", c(30, 30, 34), c(34, NA)), "Sem dados",
  "D+1 em falta impede avaliar a regra amarela da máxima.")

# --- Mínima -----------------------------------------------------------------

expect_identical(tmin("2026-07-20", c(26, 26), c(26, 26)), "Vermelho",
  "Quatro valores acima do limiar vermelho da mínima dão Vermelho.")
expect_identical(tmin("2026-07-20", c(23, 23), c(23, 23)), "Amarelo",
  "Quatro valores acima do limiar amarelo da mínima dão Amarelo.")
expect_identical(tmin("2026-07-20", c(21, 23), c(23, 23)), "Verde",
  "D-2 abaixo do limiar amarelo impede o Amarelo da mínima.")
expect_identical(tmin("2026-07-20", c(NA, 23), c(23, 23)), "Sem dados",
  "A regra amarela da mínima depende de D-2, logo a sua ausência é Sem dados.")
expect_identical(tmin("2026-06-20", c(22, 22), c(22, 22)), "Amarelo",
  "Em junho o limiar amarelo da mínima é 21 ºC.")

# --- Fora de época ----------------------------------------------------------

expect_identical(tmax("2026-11-20", c(36, 36, 36), c(36, 36)), "Fora de época",
  "Novembro está fora da época DSP, mesmo com valores extremos.")
expect_identical(tmin("2026-03-20", c(26, 26), c(26, 26)), "Fora de época",
  "Março está fora da época DSP.")
expect_identical(tmax("2026-11-20", c(NA, NA, NA), c(NA, NA)), "Fora de época",
  "Fora de época tem precedência sobre dados em falta.")
expect_identical(
  dsp_classify_tmax(as.Date("2026-11-20"), c(36, 36, 36), c(36, 36))$yellow,
  "",
  "Fora de época não expõe limiares numéricos."
)

# --- Agregação --------------------------------------------------------------

expect_identical(dsp_overall_alert("Amarelo", "Vermelho"), "Vermelho",
  "O nível global é o mais elevado entre máxima e mínima.")
expect_identical(dsp_overall_alert("Verde", "Amarelo"), "Amarelo",
  "Um Amarelo isolado sobe o nível global.")
expect_identical(dsp_overall_alert("Sem dados", "Verde"), "Verde",
  "Um lado sem dados não impede o outro de determinar o nível global.")
expect_identical(dsp_overall_alert("Sem dados", "Sem dados"), "Sem dados",
  "Sem dados dos dois lados mantém-se Sem dados.")
expect_identical(dsp_overall_alert("Sem dados", "Amarelo"), "Amarelo",
  "Sem dados nunca reduz um sinal determinado do outro lado.")

# Regressão da divergência entre implementações: fora de época tem de continuar
# distinto de Sem dados até ao rótulo agregado, que é o que chega ao boletim.
expect_identical(dsp_overall_alert("Fora de época", "Fora de época"), "Fora de época",
  "Fora de época não pode colapsar em Sem dados na agregação.")
expect_identical(
  dsp_alert_level("Fora de época"),
  "-2",
  "Fora de época tem código próprio, distinto de Sem dados."
)
expect_identical(
  dsp_alert_level("Sem dados"),
  "-1",
  "Sem dados mantém o seu código próprio."
)
expect_identical(dsp_overall_alert("Fora de época", "Sem dados"), "Sem dados",
  "Uma regra sem dados junto de outra fora de época não é fora de época.")

# --- Contratos de entrada ---------------------------------------------------

expect_error(
  dsp_classify_tmax(as.Date("2026-07-20"), c(30, 30), c(34, 34)),
  "A máxima exige três observações; menos do que isso deve falhar de imediato."
)
expect_error(
  dsp_classify_tmin(as.Date("2026-07-20"), c(23, 23, 23), c(23, 23)),
  "A mínima exige duas observações; mais do que isso deve falhar de imediato."
)
expect_error(
  dsp_classify_tmax(as.Date("2026-07-20"), c(30, 30, 30), 34),
  "A previsão exige D e D+1; menos do que isso deve falhar de imediato."
)

if (failures > 0) {
  stop(sprintf("%d asserção/asserções da regra DSP falharam.", failures), call. = FALSE)
}

cat("OK DSP rule tests\n")
