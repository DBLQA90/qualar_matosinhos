# Regra DSP de temperatura da ULSM.
#
# Este módulo é a única implementação da regra e não tem efeitos laterais: não
# lê ficheiros, não faz pedidos de rede e não escreve nada. Pode ser carregado
# com source() por qualquer script ou teste.
#
# Consumidores: fetch_ipma.R (cálculo oficial IPMA arquivado em
# data/ipma_matosinhos_temperature_alerts.csv) e temperature_source_comparison.R
# (mesma regra aplicada em paralelo a IPMA e Open-Meteo no boletim).
#
# Regras, conforme INDICADORES.md > TEMP-DSP:
#   Época de aplicação: maio a outubro.
#   Limiares de julho a outubro: máxima 33/35 ºC, mínima 22/25 ºC.
#   Limiares de maio e junho:    máxima 32/34 ºC, mínima 21/24 ºC.
#   Máxima  Amarelo:  D-1, D e D+1 >= limiar amarelo.
#   Máxima  Vermelho: D-3, D-2, D-1, D e D+1 >= limiar vermelho.
#   Mínima  Amarelo:  D-2, D-1, D e D+1 >= limiar amarelo.
#   Mínima  Vermelho: D-2, D-1, D e D+1 >= limiar vermelho.

DSP_LEVELS <- c(
  "Fora de época" = -2,
  "Sem dados" = -1,
  "Verde" = 0,
  "Amarelo" = 1,
  "Vermelho" = 3
)

DSP_SEASON_MONTHS <- 5:10
DSP_WARM_RULE_MONTHS <- 7:10

DSP_THRESHOLDS <- list(
  tmax = list(warm = c(yellow = 33, red = 35), mild = c(yellow = 32, red = 34)),
  tmin = list(warm = c(yellow = 22, red = 25), mild = c(yellow = 21, red = 24))
)

dsp_alert_level <- function(label) {
  if (length(label) != 1 || is.na(label) || !label %in% names(DSP_LEVELS)) {
    return("")
  }

  as.character(DSP_LEVELS[[label]])
}

dsp_level_label <- function(level) {
  level <- suppressWarnings(as.numeric(level))
  if (length(level) != 1 || is.na(level) || !level %in% DSP_LEVELS) {
    return("Sem dados")
  }

  names(DSP_LEVELS)[DSP_LEVELS == level][1]
}

dsp_has_missing <- function(values) {
  any(is.na(suppressWarnings(as.numeric(unlist(values, use.names = FALSE)))))
}

dsp_thresholds <- function(target_date, kind) {
  if (!kind %in% names(DSP_THRESHOLDS)) {
    stop("Unknown DSP rule kind: ", kind, ". Use tmax or tmin.", call. = FALSE)
  }

  month_value <- as.integer(format(as.Date(target_date), "%m"))
  if (is.na(month_value) || !month_value %in% DSP_SEASON_MONTHS) {
    return(list(
      applicable = FALSE,
      rule = "fora de epoca DSP",
      thresholds = c(yellow = NA_real_, red = NA_real_)
    ))
  }

  warm_rule <- month_value %in% DSP_WARM_RULE_MONTHS
  list(
    applicable = TRUE,
    rule = if (warm_rule) "mes 7-10" else "mes 5-6",
    thresholds = if (warm_rule) {
      DSP_THRESHOLDS[[kind]]$warm
    } else {
      DSP_THRESHOLDS[[kind]]$mild
    }
  )
}

dsp_result <- function(alert, thresholds) {
  list(
    alert = alert,
    level = dsp_alert_level(alert),
    yellow = if (is.na(thresholds[["yellow"]])) "" else thresholds[["yellow"]],
    red = if (is.na(thresholds[["red"]])) "" else thresholds[["red"]]
  )
}

# Classifica a regra, dados os valores exigidos por cada patamar.
#
# `yellow_values` são os dias de que a regra amarela depende e `extra_red_values`
# os dias que só o vermelho exige. Como o patamar vermelho é sempre superior ao
# amarelo nos dias partilhados, uma regra amarela que falha exclui também o
# vermelho: nesse caso o Verde fica determinado mesmo com `extra_red_values` em
# falta, e não é uma suposição sobre dados ausentes.
dsp_classify <- function(target_date, kind, yellow_values, extra_red_values = numeric()) {
  season <- dsp_thresholds(target_date, kind)
  thresholds <- season$thresholds

  if (!season$applicable) {
    return(dsp_result("Fora de época", thresholds))
  }

  if (dsp_has_missing(yellow_values)) {
    return(dsp_result("Sem dados", thresholds))
  }

  red_values <- c(extra_red_values, yellow_values)
  meets_red <- !dsp_has_missing(red_values) &&
    all(red_values >= thresholds[["red"]])
  if (meets_red) {
    return(dsp_result("Vermelho", thresholds))
  }

  if (all(yellow_values >= thresholds[["yellow"]])) {
    return(dsp_result("Amarelo", thresholds))
  }

  dsp_result("Verde", thresholds)
}

# observed: temperaturas observadas em D-3, D-2 e D-1, por esta ordem.
# forecast: temperaturas previstas para D e D+1, por esta ordem.
dsp_classify_tmax <- function(target_date, observed, forecast) {
  if (length(observed) != 3 || length(forecast) != 2) {
    stop(
      "dsp_classify_tmax expects 3 observed values (D-3, D-2, D-1) and 2 forecast values (D, D+1).",
      call. = FALSE
    )
  }

  dsp_classify(
    target_date,
    "tmax",
    yellow_values = c(observed[[3]], forecast),
    extra_red_values = c(observed[[1]], observed[[2]])
  )
}

# observed: temperaturas observadas em D-2 e D-1, por esta ordem.
# forecast: temperaturas previstas para D e D+1, por esta ordem.
dsp_classify_tmin <- function(target_date, observed, forecast) {
  if (length(observed) != 2 || length(forecast) != 2) {
    stop(
      "dsp_classify_tmin expects 2 observed values (D-2, D-1) and 2 forecast values (D, D+1).",
      call. = FALSE
    )
  }

  # A regra amarela da mínima já depende de D-2, por isso não há dias exclusivos
  # do patamar vermelho.
  dsp_classify(target_date, "tmin", yellow_values = c(observed, forecast))
}

dsp_overall_alert <- function(tmax_alert, tmin_alert) {
  levels <- suppressWarnings(as.numeric(c(
    dsp_alert_level(tmax_alert),
    dsp_alert_level(tmin_alert)
  )))

  if (all(is.na(levels))) {
    return("Sem dados")
  }
  if (all(levels == DSP_LEVELS[["Fora de época"]], na.rm = TRUE)) {
    return("Fora de época")
  }
  if (all(levels < 0, na.rm = TRUE)) {
    return("Sem dados")
  }

  dsp_level_label(max(levels, na.rm = TRUE))
}
