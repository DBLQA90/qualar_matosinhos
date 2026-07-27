SUMMARY_MARKER <- "sintese"
SOURCE_STATUS_MARKER <- "source-status"
INDEX_MARKER <- "indice"
SOURCES_HEADER_PATTERN <- "^## Fontes (usadas para recomendações|e metodologia)"
source("temperature_source_comparison.R", encoding = "UTF-8")

REPORT_SOURCE_SECTIONS <- list(
  "Síntese de risco" = c(
    paste(
      "- Metodologia local: o nível de hoje resulta dos sinais aplicáveis à data;",
      "a previsão acrescenta preparação (Vermelho futuro -> Laranja hoje;",
      "Amarelo/Laranja futuro -> Amarelo hoje), sem reclassificar o risco temporal como já ocorrido."
    ),
    "- Plano Local de Preparação e Resposta Sazonal em Saúde da ULSM 2026-2027 (documento interno fornecido pela USP).",
    "- Plano Nacional de Preparação e Resposta Sazonal em Saúde 2026-2027: https://www.sns.min-saude.pt/wp-content/uploads/2026/04/Plano-Sazonal-26_27.pdf"
  ),
  "Qualidade do ar" = c(
    "- APA/DGS, Índice QualAr e classificação por poluente: https://www.dgs.pt/paginas-de-sistema/saude-de-a-a-z/qualidade-do-ar-ambiente/indice-de-qualidade-do-ar.aspx",
    "- DGS, recomendações de saúde para níveis Fraco e Mau: https://www.dgs.pt/paginas-de-sistema/saude-de-a-a-z/qualidade-do-ar-ambiente/recomendacoes-de-saude.aspx",
    "- Agência Europeia do Ambiente, mensagens de saúde por severidade: https://www.eea.europa.eu/pt/help/perguntas-frequentes/o-que-significam-os-valores",
    "- OMS Europa, medidas pessoais para reduzir exposição à poluição atmosférica: https://www.who.int/publications/i/item/WHO-EURO-2024-9115-48887-72806",
    "- EPA, ozono troposférico e redução de esforço ao ar livre: https://www.epa.gov/ozone-pollution-and-your-patients-health/what-ozone",
    "- EPA, NO₂ e efeitos respiratórios: https://www.epa.gov/no2-pollution/basic-information-about-no2"
  ),
  "Temperatura DSP" = c(
    "- IPMA, API de dados meteorológicos: https://api.ipma.pt/",
    "- Open-Meteo, Weather Forecast API e modelos disponíveis: https://open-meteo.com/en/docs",
    "- DGS, recomendações para ondas de calor: https://www.dgs.pt/saude-ambiental-calor/recomendacoes.aspx",
    "- DGS, temperaturas elevadas - recomendações: https://www.dgs.pt/em-destaque/temperaturas-elevadas-recomendacoes-da-dgs.aspx",
    "- SNS/DGS/INSA, recomendações contra o calor: https://www.sns.min-saude.pt/comunicado-conjunto-aumento-da-temperatura-recomendacoes-contra-o-calor/"
  ),
  "Noites tropicais" = c(
    "- IPMA, API de dados meteorológicos: https://api.ipma.pt/",
    "- Open-Meteo, Weather Forecast API: https://open-meteo.com/en/docs",
    "- IPMA, definição climatológica usada nos boletins: noite tropical corresponde a temperatura mínima do ar igual ou superior a 20 ºC.",
    "- DGS, recomendações para ondas de calor: https://www.dgs.pt/saude-ambiental-calor/recomendacoes.aspx",
    "- DGS, recomendações à população em períodos de calor: https://www.dgs.pt/em-destaque/recomendacoes-a-populacao-calor.aspx"
  ),
  "Onda de calor" = c(
    "- IPMA, definição de Onda de Calor: https://www.ipma.pt/pt/enciclopedia/clima/index.html?page=onda.calor.xml",
    "- IPMA, monitorização de Ondas de Calor: https://www.ipma.pt/pt/oclima/ondascalor/",
    "- IPMA, Normal Climatológica 1991-2020 - Porto/Pedras Rubras: https://www.ipma.pt/opencms/bin/file.data/climate-normal/cn_91-20_PORTO_PEDRAS_RUBRAS.pdf",
    "- Open-Meteo, Weather Forecast API: https://open-meteo.com/en/docs",
    "- DGS, recomendações para ondas de calor: https://www.dgs.pt/saude-ambiental-calor/recomendacoes.aspx",
    "- DGS, calor - perguntas e respostas: https://www.dgs.pt/paginas-de-sistema/saude-de-a-a-z/calor/perguntas-e-respostas.aspx"
  ),
  "Stress térmico UTCI" = c(
    "- IPMA, UTCI - Índice Climático Térmico Universal: https://www.ipma.pt/pt/enciclopedia/amb.atmosfera/index.bioclima/index.html?page=utci.xml",
    "- IPMA, API de dados meteorológicos: https://api.ipma.pt/",
    "- DGS, recomendações para ondas de calor: https://www.dgs.pt/saude-ambiental-calor/recomendacoes.aspx",
    "- DGS, calor - recomendações à população: https://www.dgs.pt/em-destaque/recomendacoes-a-populacao-calor.aspx",
    "- DGS, frio - recomendações gerais: https://www.dgs.pt/saude-ambiental/areas-de-intervencao/frio/recomendacoes-gerais.aspx",
    "- DGS, frio - grupos vulneráveis: https://www.dgs.pt/paginas-de-sistema/saude-de-a-a-z/frio/recomendacoes-para-os-grupos-vulneraveis.aspx"
  ),
  "ÍCARO e FRIESA" = c(
    "- SNS Transparência/INSA, Evolução diária do Índice ÍCARO: https://transparencia.sns.gov.pt/explore/dataset/evolucao-diaria-do-indice-icaro/",
    "- SNS Transparência/INSA, Índice FRIESA: https://transparencia.sns.gov.pt/explore/dataset/indice-friesa/",
    "- DGS, Índice-Alerta-ÍCARO no Plano de Contingência para Temperaturas Extremas Adversas: https://www.dgs.pt/directrizes-da-dgs/normas-e-circulares-normativas/norma-n-0072015-de-29042015-pdf.aspx",
    "- INSA, FRIESA - modelação e previsão do efeito do frio extremo na saúde: https://repositorio.insa.pt/bitstream/10400.18/3703/3/Newsletter%20fevereiro%202016_FRIESA.pdf",
    "- DGS, recomendações para ondas de calor: https://www.dgs.pt/saude-ambiental-calor/recomendacoes.aspx",
    "- DGS, frio - recomendações gerais: https://www.dgs.pt/saude-ambiental/areas-de-intervencao/frio/recomendacoes-gerais.aspx"
  ),
  "Clima Extremo" = c(
    "- CLIMA EXTREMO, painel de aviso de risco em edifícios: http://climaextremo.vps.tecnico.ulisboa.pt/",
    "- CLIMA EXTREMO, API pública de metadados: http://climaextremo.vps.tecnico.ulisboa.pt:8100/api/weather/metadata",
    "- DGS, recomendações para ondas de calor: https://www.dgs.pt/saude-ambiental-calor/recomendacoes.aspx",
    "- DGS, frio - recomendações gerais: https://www.dgs.pt/saude-ambiental/areas-de-intervencao/frio/recomendacoes-gerais.aspx",
    "- DGS, frio - grupos vulneráveis: https://www.dgs.pt/paginas-de-sistema/saude-de-a-a-z/frio/recomendacoes-para-os-grupos-vulneraveis.aspx"
  ),
  "Índice UV" = c(
    "- IPMA, Índice Ultravioleta e classes IUV: https://www.ipma.pt/pt/enciclopedia/amb.atmosfera/uv/index.html",
    "- IPMA, previsão do Índice Ultravioleta: https://www.ipma.pt/pt/otempo/prev.uv/",
    "- OMS, índice UV e recomendações de proteção: https://www.who.int/news-room/questions-and-answers/item/radiation-the-ultraviolet-%28uv%29-index",
    "- OMS, radiação ultravioleta e proteção: https://www.who.int/news-room/fact-sheets/detail/ultraviolet-radiation",
    "- EPA, escala do Índice UV conforme orientações internacionais: https://www.epa.gov/sunsafety/uv-index-scale-0"
  ),
  "Avisos IPMA" = c(
    "- IPMA, API de avisos meteorológicos e risco de incêndio: https://api.ipma.pt/",
    "- IPMA, guia dos avisos meteorológicos: https://www.ipma.pt/pt/enciclopedia/otempo/sam/index.html",
    "- IPMA, perigo de incêndio rural: https://www.ipma.pt/pt/enciclopedia/otempo/risco.incendio/index.jsp?page=pirdl.xml",
    "- ANEPC, avisos à população e medidas preventivas: https://prociv.gov.pt/pt/avisos-a-populacao/",
    "- ANEPC, perigo de incêndio rural - medidas preventivas: https://prociv.gov.pt/pt/noticias/20082025-perigo-de-incendio-rural-medidas-preventivas/"
  ),
  "Águas balneares" = c(
    "- APA, informação e monitorização das águas balneares: https://apambiente.pt/agua/aguas-balneares",
    "- APA, época balnear 2026 e acesso ao InfoÁgua: https://apambiente.pt/apa/epoca-balnear-2026",
    "- APA, restrições à prática balnear: https://apambiente.pt/apa/restricoes-pratica-balnear",
    "- APA/SNIAmb, serviço geográfico oficial das praias: https://sniambgeoogc.apambiente.pt/getogc/rest/services/SNIAmb/Praias/MapServer/0",
    "- APA, esclarecimento sobre desaconselhamentos e interdições: https://apambiente.pt/destaque2/epoca-balnear-2023-esclarecimento-apa"
  )
)

INLINE_SOURCE_HEADERS <- c(
  "Fontes de apoio para recomendações de temperatura:",
  "Fontes de apoio para definição e recomendações de onda de calor:",
  "Fontes de apoio para recomendações de stress térmico:",
  "Fontes de apoio para índices SNS/INSA e recomendações:",
  "Fontes de apoio para recomendações UV:",
  "Fontes de apoio para recomendações de avisos IPMA:"
)

summary_as_text <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return("")
  }

  x <- x[[1]]
  if (is.na(x)) {
    return("")
  }

  as.character(x)
}

summary_to_num <- function(x) {
  suppressWarnings(as.numeric(summary_as_text(x)))
}

summary_read_csv <- function(path) {
  if (!file.exists(path)) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  out <- suppressMessages(readr::read_csv(
    path,
    show_col_types = FALSE,
    col_types = readr::cols(.default = "c")
  ))
  as.data.frame(out, stringsAsFactors = FALSE)
}

summary_clean <- function(value, fallback = "Sem dados") {
  value <- summary_as_text(value)
  if (value == "") {
    return(fallback)
  }

  value
}

summary_date_rows <- function(rows, date_col, report_date, future = FALSE) {
  if (nrow(rows) == 0 || !date_col %in% names(rows)) {
    return(rows[0, , drop = FALSE])
  }

  dates <- as.Date(rows[[date_col]])
  report_date_value <- as.Date(report_date)
  keep <- !is.na(dates) & if (future) {
    dates >= report_date_value
  } else {
    dates == report_date_value
  }

  rows[keep, , drop = FALSE]
}

summary_after_date_rows <- function(rows, date_col, report_date) {
  if (nrow(rows) == 0 || !date_col %in% names(rows)) {
    return(rows[0, , drop = FALSE])
  }

  dates <- as.Date(rows[[date_col]])
  report_date_value <- as.Date(report_date)
  rows[!is.na(dates) & dates > report_date_value, , drop = FALSE]
}

summary_first_future_row <- function(rows, date_col, report_date) {
  future_rows <- summary_date_rows(rows, date_col, report_date, future = TRUE)
  if (nrow(future_rows) == 0) {
    return(rows[0, , drop = FALSE])
  }

  dates <- as.Date(future_rows[[date_col]])
  future_rows[order(dates), , drop = FALSE][1, , drop = FALSE]
}

summary_highest_row_with_value <- function(rows, order_col, value_col, date_col = NULL) {
  if (nrow(rows) == 0 || !order_col %in% names(rows) || !value_col %in% names(rows)) {
    return(rows[0, , drop = FALSE])
  }

  order_values <- suppressWarnings(as.numeric(rows[[order_col]]))
  order_values[is.na(order_values)] <- -1
  secondary_values <- suppressWarnings(as.numeric(rows[[value_col]]))
  secondary_values[is.na(secondary_values)] <- -Inf
  date_values <- if (!is.null(date_col) && date_col %in% names(rows)) {
    as.Date(rows[[date_col]])
  } else {
    rep(as.Date("9999-12-31"), nrow(rows))
  }
  date_values[is.na(date_values)] <- as.Date("9999-12-31")

  rows[order(-order_values, -secondary_values, date_values), , drop = FALSE][1, , drop = FALSE]
}

summary_highest_row <- function(rows, order_col, date_col = NULL) {
  if (nrow(rows) == 0 || !order_col %in% names(rows)) {
    return(rows[0, , drop = FALSE])
  }

  order_values <- suppressWarnings(as.numeric(rows[[order_col]]))
  order_values[is.na(order_values)] <- -1
  date_values <- if (!is.null(date_col) && date_col %in% names(rows)) {
    as.Date(rows[[date_col]])
  } else {
    rep(as.Date("9999-12-31"), nrow(rows))
  }
  date_values[is.na(date_values)] <- as.Date("9999-12-31")

  rows[order(-order_values, date_values), , drop = FALSE][1, , drop = FALSE]
}

summary_join_unique <- function(values, fallback = "sem fatores relevantes") {
  values <- unique(values[values != "" & !is.na(values)])
  if (length(values) == 0) {
    return(fallback)
  }

  paste(values, collapse = ", ")
}

summary_signal <- function(
  domain,
  today = "Sem dados",
  future = "Sem dados",
  driver = "sem dados",
  today_order = -1,
  future_order = -1,
  horizon = "",
  future_driver = ""
) {
  list(
    domain = domain,
    today = today,
    future = future,
    driver = driver,
    today_order = today_order,
    future_order = future_order,
    horizon = horizon,
    future_driver = if (summary_as_text(future_driver) == "") driver else future_driver
  )
}

summary_short_date <- function(value) {
  date_value <- as.Date(value)
  if (is.na(date_value)) {
    return("")
  }

  format(date_value, "%d/%m")
}

summary_latest_date_text <- function(dates) {
  dates <- dates[!is.na(dates)]
  if (length(dates) == 0) {
    return("sem data válida")
  }

  as.character(max(dates))
}

summary_row_has_value <- function(rows, value_col = NULL) {
  if (nrow(rows) == 0) {
    return(FALSE)
  }
  if (is.null(value_col) || !value_col %in% names(rows)) {
    return(TRUE)
  }

  values <- as.character(rows[[value_col]])
  values <- values[!is.na(values)]
  any(nzchar(values))
}

summary_source_coverage_line <- function(
  label,
  path,
  date_col,
  report_date,
  require_today = TRUE,
  require_future = FALSE,
  value_col = NULL,
  rows_filter = NULL
) {
  rows <- summary_read_csv(path)
  if (nrow(rows) == 0) {
    return(paste0("- ", label, ": sem dados disponíveis em `", path, "`."))
  }
  if (!date_col %in% names(rows)) {
    return(paste0("- ", label, ": ficheiro sem coluna de data esperada (`", date_col, "`)."))
  }

  if (!is.null(rows_filter)) {
    rows <- rows_filter(rows)
  }
  if (nrow(rows) == 0) {
    return(paste0("- ", label, ": sem registos aplicáveis para este boletim."))
  }

  dates <- as.Date(rows[[date_col]])
  report_date_value <- as.Date(report_date)
  today_rows <- rows[!is.na(dates) & dates == report_date_value, , drop = FALSE]
  future_rows <- rows[!is.na(dates) & dates > report_date_value, , drop = FALSE]

  if (require_today && !summary_row_has_value(today_rows, value_col)) {
    return(paste0(
      "- ",
      label,
      ": sem valor para a data do boletim; última data disponível: ",
      summary_latest_date_text(dates),
      "."
    ))
  }

  if (require_future && nrow(future_rows) == 0) {
    return(paste0(
      "- ",
      label,
      ": sem previsão futura para além de ",
      as.character(report_date_value),
      "; não inferir duração."
    ))
  }

  ""
}

summary_sns_health_coverage_line <- function(report_date) {
  rows <- summary_read_csv("data/sns_matosinhos_temperature_health_indices_latest.csv")
  if (nrow(rows) == 0) {
    return("- SNS/INSA: sem dados ÍCARO/FRIESA disponíveis.")
  }

  month_value <- as.integer(format(as.Date(report_date), "%m"))
  expected_index <- if (month_value %in% 5:9) {
    "ÍCARO"
  } else if (month_value %in% c(11, 12, 1, 2, 3)) {
    "FRIESA"
  } else {
    ""
  }

  if (expected_index == "") {
    return("")
  }

  summary_source_coverage_line(
    paste0("SNS/INSA ", expected_index),
    "data/sns_matosinhos_temperature_health_indices_latest.csv",
    "target_date",
    report_date,
    require_today = TRUE,
    require_future = FALSE,
    rows_filter = function(data) {
      if (!"index_name" %in% names(data)) {
        return(data[0, , drop = FALSE])
      }
      data[data$index_name == expected_index, , drop = FALSE]
    }
  )
}

summary_horizon_from_rows <- function(
  domain,
  rows,
  date_col,
  order_col,
  report_date,
  value_col = NULL
) {
  if (nrow(rows) == 0 || !date_col %in% names(rows) || !order_col %in% names(rows)) {
    return("")
  }

  dates <- as.Date(rows[[date_col]])
  orders <- suppressWarnings(as.numeric(rows[[order_col]]))
  values <- if (!is.null(value_col) && value_col %in% names(rows)) {
    suppressWarnings(as.numeric(rows[[value_col]]))
  } else {
    rep(NA_real_, length(orders))
  }
  report_date_value <- as.Date(report_date)
  keep <- !is.na(dates) &
    !is.na(orders) &
    orders >= 0 &
    dates >= report_date_value
  if (!any(keep)) {
    return("")
  }

  dates <- dates[keep]
  orders <- orders[keep]
  values <- values[keep]

  daily_dates <- sort(unique(dates))
  daily <- do.call(rbind, lapply(daily_dates, function(date_value) {
    day_rows <- dates == date_value
    day_order <- max(orders[day_rows], na.rm = TRUE)
    day_values <- values[day_rows & orders == day_order]
    day_values <- day_values[is.finite(day_values)]
    data.frame(
      date = date_value,
      order = day_order,
      value = if (length(day_values) > 0) max(day_values) else NA_real_
    )
  }))
  daily$date <- as.Date(daily$date, origin = "1970-01-01")
  daily <- daily[order(daily$date), , drop = FALSE]

  active <- daily$order > 0
  if (!any(active)) {
    return("")
  }

  if (!any(daily$date > report_date_value)) {
    return(paste0(domain, ": hoje - sem dados para os próximos dias"))
  }

  max_order <- max(daily$order[active], na.rm = TRUE)
  active_dates <- daily$date[active]
  first_active_date <- min(active_dates)
  last_active_date <- max(active_dates)
  supported_span_dates <- seq(first_active_date, max(daily$date), by = "day")
  supported_span <- daily[
    daily$date %in% supported_span_dates,
    ,
    drop = FALSE
  ]
  continuous_supported_span <- nrow(supported_span) ==
    length(supported_span_dates) &&
    all(supported_span$date == supported_span_dates)

  if (continuous_supported_span &&
      all(supported_span$order == max_order)) {
    if (first_active_date == report_date_value) {
      return(paste0(
        domain,
        ": previsto até ",
        summary_short_date(last_active_date)
      ))
    }
    if (first_active_date == last_active_date) {
      return(paste0(
        domain,
        ": previsto em ",
        summary_short_date(first_active_date)
      ))
    }
    return(paste0(
      domain,
      ": previsto de ",
      summary_short_date(first_active_date),
      " a ",
      summary_short_date(last_active_date)
    ))
  }

  peak_candidates <- which(active & daily$order == max_order)
  finite_peak_values <- is.finite(daily$value[peak_candidates])
  if (any(finite_peak_values)) {
    max_value <- max(daily$value[peak_candidates][finite_peak_values])
    peak_candidates <- peak_candidates[
      is.finite(daily$value[peak_candidates]) &
        daily$value[peak_candidates] == max_value
    ]
  }
  peak_dates <- daily$date[peak_candidates]
  last_peak_index <- max(peak_candidates)

  peak_text <- if (length(peak_dates) == 1) {
    if (peak_dates[[1]] == report_date_value) {
      "pico hoje"
    } else {
      paste0("pico em ", summary_short_date(peak_dates[[1]]))
    }
  } else if (all(diff(as.integer(peak_dates)) == 1)) {
    paste0(
      "pico entre ",
      if (min(peak_dates) == report_date_value) {
        "hoje"
      } else {
        summary_short_date(min(peak_dates))
      },
      " e ",
      summary_short_date(max(peak_dates))
    )
  } else {
    peak_labels <- vapply(peak_dates, summary_short_date, character(1))
    paste0(
      "picos em ",
      if (length(peak_labels) == 2) {
        paste(peak_labels, collapse = " e ")
      } else {
        paste0(
          paste(peak_labels[-length(peak_labels)], collapse = ", "),
          " e ",
          peak_labels[[length(peak_labels)]]
        )
      }
    )
  }

  compare_risk <- function(current_index, previous_index) {
    order_difference <- daily$order[[current_index]] - daily$order[[previous_index]]
    if (order_difference != 0) {
      return(sign(order_difference))
    }

    current_value <- daily$value[[current_index]]
    previous_value <- daily$value[[previous_index]]
    if (is.finite(current_value) && is.finite(previous_value)) {
      return(sign(current_value - previous_value))
    }

    0
  }

  improvement_date <- as.Date(NA)
  after_peak <- seq.int(last_peak_index + 1L, nrow(daily))
  if (length(after_peak) > 0 &&
      after_peak[[1]] <= nrow(daily)) {
    horizon_dates <- seq(
      daily$date[[last_peak_index]],
      max(daily$date),
      by = "day"
    )
    continuous_after_peak <- length(horizon_dates) ==
      (nrow(daily) - last_peak_index + 1L) &&
      all(daily$date[last_peak_index:nrow(daily)] == horizon_dates)

    if (continuous_after_peak) {
      comparison_indices <- last_peak_index:nrow(daily)
      comparisons <- vapply(
        seq.int(2L, length(comparison_indices)),
        function(index) {
          compare_risk(
            comparison_indices[[index]],
            comparison_indices[[index - 1L]]
          )
        },
        numeric(1)
      )
      first_improvement <- which(comparisons < 0)
      if (length(first_improvement) > 0 &&
          all(comparisons <= 0)) {
        improvement_date <- daily$date[
          comparison_indices[[first_improvement[[1]] + 1L]]
        ]
      }
    }
  }

  if (!is.na(improvement_date)) {
    return(paste0(
      domain,
      ": ",
      peak_text,
      ", tendência a melhorar a partir de ",
      summary_short_date(improvement_date)
    ))
  }

  paste0(domain, ": ", peak_text)
}

summary_report_title <- function(report_date) {
  paste0("# PNPRSS Matosinhos | ", report_date)
}

normalize_report_header <- function(content, report_date) {
  content <- content[!grepl("^Ficheiro diário:", content)]

  first_nonblank <- which(content != "")
  if (length(first_nonblank) > 0 && grepl("^# ", content[[first_nonblank[1]]])) {
    content <- content[-first_nonblank[1]]
  }

  content <- content[!(seq_along(content) == 1 & content == "")]
  c(summary_report_title(report_date), "", content)
}

summary_compact_blank_lines <- function(content) {
  if (length(content) == 0) {
    return(content)
  }

  keep <- logical(length(content))
  blank_run <- 0
  for (i in seq_along(content)) {
    if (content[[i]] == "") {
      blank_run <- blank_run + 1
      keep[[i]] <- blank_run <= 1
    } else {
      blank_run <- 0
      keep[[i]] <- TRUE
    }
  }

  content[keep]
}

summary_index_slug <- function(value) {
  value <- iconv(value, from = "UTF-8", to = "ASCII//TRANSLIT")
  value[is.na(value)] <- "secao"
  value <- tolower(value)
  value <- gsub("[^a-z0-9]+", "-", value)
  value <- gsub("(^-+|-+$)", "", value)
  paste0("sec-", value)
}

summary_strip_report_index <- function(content) {
  start_marker <- paste0("<!-- ", INDEX_MARKER, ":start -->")
  end_marker <- paste0("<!-- ", INDEX_MARKER, ":end -->")
  start <- which(content == start_marker)
  end <- which(content == end_marker)
  if (length(start) > 0 && length(end) > 0 && end[[1]] >= start[[1]]) {
    before <- if (start[[1]] > 1) content[seq_len(start[[1]] - 1)] else
      character()
    after <- if (end[[1]] < length(content)) {
      content[(end[[1]] + 1):length(content)]
    } else {
      character()
    }
    content <- c(before, after)
  }
  content[!grepl("^<a id=\"sec-[^\"]+\"></a>$", content)]
}

summary_report_index_entries <- function(content) {
  h2 <- grep("^## ", content)
  detail <- which(content == "## Indicadores detalhados")
  sources <- grep(SOURCES_HEADER_PATTERN, content)
  h3 <- grep("^### ", content)

  detail_h3 <- if (length(detail) > 0) {
    end <- if (length(sources) > 0) sources[[1]] else length(content) + 1L
    h3[h3 > detail[[1]] & h3 < end]
  } else {
    integer()
  }
  indices <- sort(unique(c(h2, detail_h3)))
  indices <- indices[content[indices] != "## Índice"]
  if (length(indices) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  labels <- sub("^#{2,3} ", "", content[indices])
  base_ids <- vapply(labels, summary_index_slug, character(1))
  ids <- base_ids
  seen <- integer()
  names(seen) <- character()
  for (index in seq_along(ids)) {
    base <- base_ids[[index]]
    count <- if (base %in% names(seen)) seen[[base]] + 1L else 1L
    seen[[base]] <- count
    if (count > 1L) {
      ids[[index]] <- paste0(base, "-", count)
    }
  }

  data.frame(
    line_index = indices,
    label = labels,
    anchor_id = ids,
    stringsAsFactors = FALSE
  )
}

replace_report_index <- function(content) {
  content <- summary_strip_report_index(content)
  entries <- summary_report_index_entries(content)
  if (nrow(entries) == 0) {
    return(summary_compact_blank_lines(content))
  }

  anchored <- character()
  entry_lookup <- setNames(
    seq_len(nrow(entries)),
    as.character(entries$line_index)
  )
  for (index in seq_along(content)) {
    key <- as.character(index)
    if (key %in% names(entry_lookup)) {
      entry <- entries[entry_lookup[[key]], , drop = FALSE]
      anchored <- c(
        anchored,
        paste0("<a id=\"", entry$anchor_id, "\"></a>")
      )
    }
    anchored <- c(anchored, content[[index]])
  }

  index_section <- c(
    paste0("<!-- ", INDEX_MARKER, ":start -->"),
    "## Índice",
    "",
    paste0("- [", entries$label, "](#", entries$anchor_id, ")"),
    paste0("<!-- ", INDEX_MARKER, ":end -->")
  )
  title <- which(grepl("^# ", anchored))
  insert_after <- if (length(title) > 0) title[[1]] else 0L
  before <- if (insert_after > 0) anchored[seq_len(insert_after)] else
    character()
  after <- if (insert_after < length(anchored)) {
    anchored[(insert_after + 1):length(anchored)]
  } else {
    character()
  }

  summary_compact_blank_lines(c(before, "", index_section, "", after))
}

build_report_sources_section <- function() {
  section <- c(
    "## Fontes e metodologia",
    "",
    "As fontes abaixo fundamentam os valores, critérios e recomendações usados no boletim. Estão agrupadas por indicador para facilitar auditoria e revisão."
  )

  for (section_name in names(REPORT_SOURCE_SECTIONS)) {
    section <- c(
      section,
      "",
      paste0("### ", section_name),
      "",
      REPORT_SOURCE_SECTIONS[[section_name]]
    )
  }

  section
}

strip_inline_source_blocks <- function(content) {
  if (length(content) == 0) {
    return(content)
  }

  out <- character()
  i <- 1
  while (i <= length(content)) {
    if (content[[i]] %in% INLINE_SOURCE_HEADERS) {
      i <- i + 1
      while (
        i <= length(content) &&
          content[[i]] == ""
      ) {
        i <- i + 1
      }
      while (
        i <= length(content) &&
          content[[i]] != "" &&
          !grepl("^<!-- ", content[[i]]) &&
          !grepl("^#{2,3} ", content[[i]])
      ) {
        i <- i + 1
      }
      while (
        i <= length(content) &&
          content[[i]] == ""
      ) {
        i <- i + 1
      }
      next
    }

    out <- c(out, content[[i]])
    i <- i + 1
  }

  out
}

replace_report_sources <- function(content) {
  content <- strip_inline_source_blocks(content)
  source_header <- grep(SOURCES_HEADER_PATTERN, content)
  section <- build_report_sources_section()

  if (length(source_header) > 0) {
    before <- if (source_header[1] > 1) {
      content[seq_len(source_header[1] - 1)]
    } else {
      character()
    }
    return(summary_compact_blank_lines(c(before, section)))
  }

  summary_compact_blank_lines(c(content, "", section))
}

summary_source_error_lines <- function(report_date) {
  rows <- summary_read_csv("data/pipeline_source_status_latest.csv")
  if (nrow(rows) == 0 ||
      !"local_date" %in% names(rows) ||
      !"status" %in% names(rows)) {
    return(character())
  }

  rows <- rows[
    rows$local_date == as.character(report_date) &
      rows$status != "ok",
    ,
    drop = FALSE
  ]
  if (nrow(rows) == 0) {
    return(character())
  }

  vapply(seq_len(nrow(rows)), function(i) {
    row <- rows[i, , drop = FALSE]
    message <- summary_clean(row$message, "sem detalhe")
    message <- substr(message, 1, 280)
    paste0(
      "- ",
      summary_clean(row$source, "Fonte"),
      ": erro na fase ",
      summary_clean(row$phase, "desconhecida"),
      "; não foi possível atualizar automaticamente. Detalhe: ",
      message,
      "."
    )
  }, character(1))
}

summary_source_freshness_lines <- function(report_date) {
  lines <- c(
    summary_source_coverage_line(
      "QualAr",
      "qualar_matosinhos.csv",
      "forecast_date",
      report_date,
      require_today = TRUE,
      require_future = FALSE
    ),
    summary_source_coverage_line(
      "IPMA meteorologia",
      "data/ipma_matosinhos_forecast_latest.csv",
      "forecast_date",
      report_date,
      require_today = TRUE,
      require_future = TRUE
    ),
    summary_source_coverage_line(
      "Open-Meteo temperatura",
      "data/openmeteo_matosinhos_forecast_latest.csv",
      "forecast_date",
      report_date,
      require_today = TRUE,
      require_future = TRUE
    ),
    summary_source_coverage_line(
      "Temperatura DSP",
      "data/ipma_matosinhos_temperature_alert_latest.csv",
      "target_date",
      report_date,
      require_today = TRUE,
      require_future = FALSE
    ),
    summary_source_coverage_line(
      "Noites tropicais",
      "data/ipma_matosinhos_tropical_nights_latest.csv",
      "target_date",
      report_date,
      require_today = TRUE,
      require_future = TRUE,
      value_col = "tmin_c"
    ),
    summary_source_coverage_line(
      "Onda de calor",
      "data/ipma_matosinhos_heat_waves_latest.csv",
      "target_date",
      report_date,
      require_today = TRUE,
      require_future = TRUE
    ),
    summary_source_coverage_line(
      "Stress térmico UTCI",
      "data/ipma_matosinhos_thermal_stress_latest.csv",
      "target_date",
      report_date,
      require_today = TRUE,
      require_future = TRUE,
      value_col = "utci_c"
    ),
    summary_source_coverage_line(
      "Índice UV",
      "data/ipma_matosinhos_uv_index_latest.csv",
      "target_date",
      report_date,
      require_today = TRUE,
      require_future = TRUE,
      value_col = "uv_index"
    ),
    summary_sns_health_coverage_line(report_date),
    summary_source_coverage_line(
      "Clima Extremo",
      "data/clima_extremo_matosinhos_risk_latest.csv",
      "target_date",
      report_date,
      require_today = TRUE,
      require_future = TRUE
    ),
    summary_source_coverage_line(
      "Avisos IPMA",
      "data/ipma_matosinhos_alerts_latest.csv",
      "target_date",
      report_date,
      require_today = TRUE,
      require_future = FALSE
    ),
    summary_source_coverage_line(
      "Águas balneares",
      "data/apa_matosinhos_bathing_water_latest.csv",
      "snapshot_date",
      report_date,
      require_today = TRUE,
      require_future = FALSE
    )
  )

  lines[nzchar(lines)]
}

summary_source_status_section <- function(report_date) {
  error_lines <- summary_source_error_lines(report_date)
  freshness_lines <- summary_source_freshness_lines(report_date)

  if (length(error_lines) == 0 && length(freshness_lines) == 0) {
    return(character())
  }

  lines <- character()
  if (length(error_lines) > 0) {
    lines <- c(lines, "**Erros de extração:**", "", error_lines)
  }
  if (length(freshness_lines) > 0) {
    if (length(lines) > 0) {
      lines <- c(lines, "")
    }
    lines <- c(
      lines,
      "**Cobertura/frescura dos dados:**",
      "",
      freshness_lines
    )
  }

  c(
    paste0("<!-- ", SOURCE_STATUS_MARKER, ":start -->"),
    "## Estado das fontes",
    "",
    "O boletim foi gerado com os dados disponíveis. As notas abaixo indicam fontes que falharam, ficaram incompletas ou não têm cobertura suficiente para a data/horizonte do boletim.",
    "",
    lines,
    paste0("<!-- ", SOURCE_STATUS_MARKER, ":end -->")
  )
}

replace_source_status_section <- function(content, report_date) {
  start_marker <- paste0("<!-- ", SOURCE_STATUS_MARKER, ":start -->")
  end_marker <- paste0("<!-- ", SOURCE_STATUS_MARKER, ":end -->")
  start <- which(content == start_marker)
  end <- which(content == end_marker)

  if (length(start) > 0 && length(end) > 0 && end[1] >= start[1]) {
    before <- if (start[1] > 1) content[seq_len(start[1] - 1)] else character()
    after <- if (end[1] < length(content)) content[(end[1] + 1):length(content)] else character()
    content <- c(before, after)
  }

  section <- summary_source_status_section(report_date)
  if (length(section) == 0) {
    return(summary_compact_blank_lines(content))
  }

  source_header <- grep(SOURCES_HEADER_PATTERN, content)
  if (length(source_header) > 0) {
    before <- if (source_header[1] > 1) content[seq_len(source_header[1] - 1)] else character()
    after <- content[source_header[1]:length(content)]
    return(summary_compact_blank_lines(c(before, section, "", after)))
  }

  summary_compact_blank_lines(c(content, "", section))
}

summary_qualar_signal <- function(report_date) {
  rows <- summary_read_csv("qualar_matosinhos.csv")
  if (nrow(rows) == 0) {
    return(summary_signal("Qualidade do ar"))
  }

  today <- summary_date_rows(rows, "forecast_date", report_date)
  tomorrow <- summary_date_rows(
    rows,
    "forecast_date",
    as.character(as.Date(report_date) + 1)
  )
  future <- summary_after_date_rows(rows, "forecast_date", report_date)
  future_highest <- summary_highest_row(future, "overall_alert_level", "forecast_date")

  today_status <- if (nrow(today) > 0) {
    summary_clean(today$overall_alert_label)
  } else {
    "Sem dados"
  }
  future_status <- if (nrow(tomorrow) > 0) {
    paste0("Amanhã: ", summary_clean(tomorrow$overall_alert_label))
  } else if (nrow(future_highest) > 0) {
    paste0(
      summary_clean(future_highest$forecast_date),
      ": ",
      summary_clean(future_highest$overall_alert_label)
    )
  } else {
    "Sem previsão"
  }

  qualar_driver_text <- function(row) {
    if (nrow(row) == 0) {
      return("sem dados")
    }
    driver_value <- summary_clean(row$alert_drivers, "Nenhum")
    if (driver_value == "Nenhum") {
      return("sem poluentes acima de Verde")
    } else {
      return(driver_value)
    }
  }

  future_driver_row <- if (nrow(tomorrow) > 0) {
    tomorrow
  } else {
    future_highest
  }
  driver <- qualar_driver_text(today)
  future_driver <- qualar_driver_text(future_driver_row)

  summary_signal(
    "Qualidade do ar",
    today_status,
    future_status,
    driver,
    summary_to_num(today$overall_alert_level),
    summary_to_num(future_highest$overall_alert_level),
    summary_horizon_from_rows(
      "Qualidade do ar",
      rows,
      "forecast_date",
      "overall_alert_level",
      report_date
    ),
    future_driver = future_driver
  )
}

summary_temperature_signal <- function(report_date) {
  rows <- tsc_dsp_comparison(report_date)
  if (nrow(rows) == 0) {
    return(summary_signal("Temperatura DSP"))
  }

  status <- vapply(seq_len(nrow(rows)), function(index) {
    row <- rows[index, , drop = FALSE]
    paste0(
      row$source_label,
      " ",
      summary_risk_icon(row$overall_alert_level),
      " ",
      row$overall_alert
    )
  }, character(1))
  driver <- vapply(seq_len(nrow(rows)), function(index) {
    row <- rows[index, , drop = FALSE]
    paste0(
      row$source_label,
      ": máx. ",
      row$tmax_alert,
      "; mín. ",
      row$tmin_alert
    )
  }, character(1))
  levels <- suppressWarnings(as.numeric(rows$overall_alert_level))
  today_level <- if (all(is.na(levels))) -1 else max(levels, na.rm = TRUE)

  summary_signal(
    "Temperatura DSP",
    paste(status, collapse = "; "),
    "A recalcular com novas observações",
    paste(driver, collapse = "; "),
    today_level,
    -1,
    ""
  )
}

summary_heat_wave_signal <- function(report_date) {
  rows <- tsc_heat_waves(report_date)
  if (nrow(rows) == 0) {
    return(summary_signal("Onda de calor"))
  }

  today <- rows[as.Date(rows$target_date) == as.Date(report_date), , drop = FALSE]
  future <- rows[as.Date(rows$target_date) > as.Date(report_date), , drop = FALSE]
  source_status <- function(selected, include_date = FALSE) {
    sources <- unique(selected$source_id)
    if (length(sources) == 0) {
      return("Sem dados")
    }
    highest_rows <- lapply(sources, function(source_id) {
      source_rows <- selected[selected$source_id == source_id, , drop = FALSE]
      order_values <- suppressWarnings(as.numeric(source_rows$heat_wave_level))
      source_rows[which.max(order_values), , drop = FALSE]
    })
    highest_levels <- vapply(highest_rows, function(row) {
      suppressWarnings(as.numeric(row$heat_wave_level[[1]]))
    }, numeric(1))
    if (include_date && any(highest_levels > 0, na.rm = TRUE)) {
      highest_rows <- highest_rows[highest_levels > 0]
    }
    paste(vapply(highest_rows, function(highest) {
      prefix <- if (include_date) {
        paste0(summary_short_date(highest$target_date), ": ")
      } else {
        ""
      }
      paste0(
        highest$source_label,
        " ",
        summary_risk_icon(highest$heat_wave_level),
        " ",
        prefix,
        highest$status
      )
    }, character(1)), collapse = "; ")
  }
  today_levels <- suppressWarnings(as.numeric(today$heat_wave_level))
  future_levels <- suppressWarnings(as.numeric(future$heat_wave_level))
  today_level <- if (length(today_levels) == 0 || all(is.na(today_levels))) {
    -1
  } else {
    max(today_levels, na.rm = TRUE)
  }
  future_level <- if (length(future_levels) == 0 || all(is.na(future_levels))) {
    -1
  } else {
    max(future_levels, na.rm = TRUE)
  }

  summary_signal(
    "Onda de calor",
    source_status(today),
    source_status(future, include_date = TRUE),
    "critério comparado com a mesma normal IPMA 1991-2020",
    today_level,
    future_level,
    {
      parts <- vapply(split(rows, rows$source_id), function(source_rows) {
        summary_horizon_from_rows(
          paste0("Onda de calor - ", source_rows$source_label[[1]]),
          source_rows,
          "target_date",
          "heat_wave_level",
          report_date
        )
      }, character(1))
      paste(parts[nzchar(parts)], collapse = "; ")
    }
  )
}

summary_thermal_signal <- function(report_date) {
  rows <- summary_read_csv("data/ipma_matosinhos_thermal_stress_latest.csv")
  if (nrow(rows) == 0) {
    return(summary_signal("Stress térmico UTCI"))
  }

  today <- summary_date_rows(rows, "target_date", report_date)
  today_highest <- summary_highest_row(today, "thermal_level_order", "target_date")
  future <- summary_after_date_rows(rows, "target_date", report_date)
  future_highest <- summary_highest_row(future, "thermal_level_order", "target_date")

  summary_signal(
    "Stress térmico UTCI",
    if (nrow(today_highest) > 0) summary_clean(today_highest$thermal_level) else "Sem dados",
    if (nrow(future_highest) > 0) {
      paste0(
        summary_clean(future_highest$target_date),
        ": ",
        summary_clean(future_highest$thermal_level)
      )
    } else {
      "Sem dados"
    },
    if (nrow(today_highest) > 0) {
      paste0(
        "UTCI ",
        summary_clean(today_highest$utci_c),
        " ºC"
      )
    } else {
      "sem dados"
    },
    summary_to_num(today_highest$thermal_level_order),
    summary_to_num(future_highest$thermal_level_order),
    summary_horizon_from_rows(
      "Stress térmico UTCI",
      rows,
      "target_date",
      "thermal_level_order",
      report_date
    ),
    future_driver = if (nrow(future_highest) > 0) {
      paste0("UTCI ", summary_clean(future_highest$utci_c), " ºC")
    } else {
      "sem dados"
    }
  )
}

summary_uv_signal <- function(report_date) {
  rows <- summary_read_csv("data/ipma_matosinhos_uv_index_latest.csv")
  if (nrow(rows) == 0) {
    return(summary_signal("Índice UV"))
  }

  rows <- rows[rows$uv_index != "" & !is.na(rows$uv_index), , drop = FALSE]
  today <- summary_date_rows(rows, "target_date", report_date)
  future <- summary_after_date_rows(rows, "target_date", report_date)
  future_highest <- summary_highest_row_with_value(
    future,
    "uv_level_order",
    "uv_index",
    "target_date"
  )

  summary_signal(
    "Índice UV",
    if (nrow(today) > 0) {
      paste0(summary_clean(today$uv_level), " (", summary_clean(today$uv_index), ")")
    } else {
      "Sem dados"
    },
    if (nrow(future_highest) > 0) {
      paste0(
        summary_clean(future_highest$target_date),
        ": ",
        summary_clean(future_highest$uv_level),
        " (",
        summary_clean(future_highest$uv_index),
        ")"
      )
    } else {
      "Sem dados"
    },
    if (nrow(today) > 0) {
      summary_clean(today$protection_required)
    } else {
      "sem dados"
    },
    summary_to_num(today$uv_level_order),
    summary_to_num(future_highest$uv_level_order),
    summary_horizon_from_rows(
      "Índice UV",
      rows,
      "target_date",
      "uv_level_order",
      report_date,
      value_col = "uv_index"
    ),
    future_driver = if (nrow(future_highest) > 0) {
      summary_clean(future_highest$protection_required)
    } else {
      "sem dados"
    }
  )
}

summary_sns_signal <- function(report_date) {
  rows <- summary_read_csv("data/sns_matosinhos_temperature_health_indices_latest.csv")
  if (nrow(rows) == 0) {
    return(summary_signal("ÍCARO/FRIESA"))
  }

  report_date_value <- as.Date(report_date)
  month_value <- as.integer(format(report_date_value, "%m"))
  applicable <- rows[0, , drop = FALSE]
  notes <- character()

  if (month_value %in% 5:9) {
    applicable <- rbind(applicable, rows[rows$index_name == "ÍCARO", , drop = FALSE])
  } else {
    notes <- c(notes, "ÍCARO fora de época")
  }

  if (month_value %in% c(1, 2, 3, 11, 12)) {
    applicable <- rbind(applicable, rows[rows$index_name == "FRIESA", , drop = FALSE])
  } else {
    notes <- c(notes, "FRIESA fora de época")
  }

  applicable <- applicable[!is.na(as.Date(applicable$target_date)), , drop = FALSE]

  today <- summary_date_rows(applicable, "target_date", report_date)
  future <- summary_after_date_rows(applicable, "target_date", report_date)
  today_highest <- summary_highest_row(today, "risk_level_order", "target_date")
  future_highest <- summary_highest_row(future, "risk_level_order", "target_date")

  today_text <- if (nrow(today_highest) > 0) {
    paste0(
      summary_clean(today_highest$index_name),
      ": ",
      summary_clean(today_highest$risk_label)
    )
  } else if (length(notes) > 0) {
    paste(notes, collapse = "; ")
  } else {
    "Sem dados aplicáveis"
  }

  future_text <- if (nrow(future_highest) > 0) {
    paste0(
      summary_clean(future_highest$target_date),
      ": ",
      summary_clean(future_highest$index_name),
      " - ",
      summary_clean(future_highest$risk_label)
    )
  } else {
    paste(notes, collapse = "; ")
  }

  driver_parts <- notes
  if (nrow(future_highest) > 0) {
    driver_parts <- c(
      driver_parts,
      summary_clean(future_highest$provisional_note, "")
    )
  }
  driver_parts <- driver_parts[driver_parts != ""]

  summary_signal(
    "ÍCARO/FRIESA",
    today_text,
    future_text,
    if (length(driver_parts) > 0) paste(driver_parts, collapse = "; ") else "sem dados",
    summary_to_num(today_highest$risk_level_order),
    summary_to_num(future_highest$risk_level_order),
    summary_horizon_from_rows(
      "ÍCARO/FRIESA",
      applicable,
      "target_date",
      "risk_level_order",
      report_date
    )
  )
}

summary_clima_extremo_signal <- function(report_date) {
  rows <- summary_read_csv("data/clima_extremo_matosinhos_risk_latest.csv")
  if (nrow(rows) == 0) {
    return(summary_signal("Clima Extremo"))
  }

  today <- summary_date_rows(rows, "target_date", report_date)
  future <- summary_after_date_rows(rows, "target_date", report_date)
  future_highest <- summary_highest_row(future, "risk_level_order", "target_date")
  today_highest <- summary_highest_row(today, "risk_level_order", "target_date")

  risk_text <- function(row) {
    if (nrow(row) == 0) {
      return("Sem dados")
    }
    order <- summary_to_num(row$risk_level_order)
    raw_value <- summary_clean(row$risk_index, "")
    if (!is.na(order) && order < 0) {
      if (raw_value != "") {
        return(paste0("Sem dados (valor fora da escala: ", raw_value, ")"))
      }
      return("Sem dados")
    }
    paste0(
      summary_clean(row$risk_label),
      " (",
      raw_value,
      ")"
    )
  }

  driver_text <- function(row) {
    if (nrow(row) == 0) {
      return("sem dados")
    }
    order <- summary_to_num(row$risk_level_order)
    raw_value <- summary_clean(row$risk_index, "")
    prefix <- ""
    if (!is.na(order) && order < 0 && raw_value != "") {
      prefix <- paste0("risco bruto ", raw_value, " fora da escala; ")
    }
    paste0(
      prefix,
      "interior ",
      summary_clean(row$indoor_temperature_c),
      " ºC; exterior ",
      summary_clean(row$outdoor_temperature_c),
      " ºC; vulnerabilidade ",
      summary_clean(row$vulnerability_index),
      "/24"
    )
  }

  summary_signal(
    "Clima Extremo",
    risk_text(today_highest),
    if (nrow(future_highest) > 0) {
      paste0(summary_clean(future_highest$target_date), ": ", risk_text(future_highest))
    } else {
      "Sem previsão"
    },
    driver_text(today_highest),
    summary_to_num(today_highest$risk_level_order),
    summary_to_num(future_highest$risk_level_order),
    summary_horizon_from_rows(
      "Clima Extremo",
      rows,
      "target_date",
      "risk_level_order",
      report_date
    ),
    future_driver = driver_text(future_highest)
  )
}

summary_alert_active_rows <- function(rows, report_date) {
  if (nrow(rows) == 0) {
    return(rows)
  }

  report_date_value <- as.Date(report_date)
  target_dates <- as.Date(rows$target_date)
  start_dates <- as.Date(substr(rows$start_time, 1, 10))
  end_dates <- as.Date(substr(rows$end_time, 1, 10))

  keep <- (!is.na(target_dates) & target_dates == report_date_value) |
    (!is.na(start_dates) & start_dates <= report_date_value &
      (is.na(end_dates) | end_dates >= report_date_value))

  rows[keep, , drop = FALSE]
}

summary_ipma_alert_signal <- function(report_date) {
  rows <- summary_read_csv("data/ipma_matosinhos_alerts_latest.csv")
  if (nrow(rows) == 0) {
    return(summary_signal("Avisos IPMA"))
  }

  today <- summary_alert_active_rows(rows, report_date)
  future <- rows[
    (!is.na(as.Date(rows$target_date)) & as.Date(rows$target_date) >= as.Date(report_date)) |
      (!is.na(as.Date(substr(rows$end_time, 1, 10))) &
        as.Date(substr(rows$end_time, 1, 10)) >= as.Date(report_date)),
    ,
    drop = FALSE
  ]
  today_highest <- summary_highest_row(today, "alert_level_order", "target_date")
  future_highest <- summary_highest_row(future, "alert_level_order", "target_date")

  type_text <- function(selected) {
    if (nrow(selected) == 0) {
      return("Sem dados")
    }
    order_values <- suppressWarnings(as.numeric(selected$alert_level_order))
    order_values[is.na(order_values)] <- -1
    active <- selected[order_values > 0, , drop = FALSE]
    if (nrow(active) == 0) {
      return("Verde")
    }
    highest <- summary_highest_row(active, "alert_level_order", "target_date")
    paste0(
      summary_clean(highest$alert_level),
      " - ",
      summary_join_unique(active$alert_type, "fenómeno meteorológico")
    )
  }

  driver <- if (nrow(future_highest) > 0) {
    paste0(
      summary_clean(future_highest$alert_source),
      ": ",
      summary_clean(future_highest$alert_type)
    )
  } else {
    "sem dados"
  }

  summary_signal(
    "Avisos IPMA",
    type_text(today),
    type_text(future),
    driver,
    summary_to_num(today_highest$alert_level_order),
    summary_to_num(future_highest$alert_level_order),
    summary_horizon_from_rows(
      "Avisos IPMA",
      future,
      "target_date",
      "alert_level_order",
      report_date
    )
  )
}

summary_tropical_night_signal <- function(report_date) {
  rows <- tsc_tropical_nights(report_date)
  if (nrow(rows) == 0) {
    return(summary_signal("Noites tropicais"))
  }

  today <- rows[as.Date(rows$target_date) == as.Date(report_date), , drop = FALSE]
  future <- rows[as.Date(rows$target_date) > as.Date(report_date), , drop = FALSE]

  status_text <- function(selected, include_date = FALSE) {
    sources <- unique(selected$source_id)
    if (length(sources) == 0) {
      return("Sem dados")
    }
    highest_rows <- lapply(sources, function(source_id) {
      source_rows <- selected[selected$source_id == source_id, , drop = FALSE]
      order_values <- suppressWarnings(as.numeric(source_rows$signal_level_order))
      source_rows[which.max(order_values), , drop = FALSE]
    })
    highest_levels <- vapply(highest_rows, function(row) {
      suppressWarnings(as.numeric(row$signal_level_order[[1]]))
    }, numeric(1))
    if (include_date && any(highest_levels > 0, na.rm = TRUE)) {
      highest_rows <- highest_rows[highest_levels > 0]
    }
    paste(vapply(highest_rows, function(highest) {
      prefix <- if (include_date) {
        paste0(summary_short_date(highest$target_date), ": ")
      } else {
        ""
      }
      paste0(
        highest$source_label,
        " ",
        summary_risk_icon(highest$signal_level_order),
        " ",
        prefix,
        highest$status
      )
    }, character(1)), collapse = "; ")
  }

  driver_text <- function(selected) {
    if (nrow(selected) == 0) {
      return("sem dados")
    }
    highest <- lapply(unique(selected$source_id), function(source_id) {
      source_rows <- selected[selected$source_id == source_id, , drop = FALSE]
      source_rows[
        which.max(tsc_num(source_rows$signal_level_order)),
        ,
        drop = FALSE
      ]
    })
    highest_levels <- vapply(highest, function(row) {
      suppressWarnings(as.numeric(row$signal_level_order[[1]]))
    }, numeric(1))
    if (any(highest_levels > 0, na.rm = TRUE)) {
      highest <- highest[highest_levels > 0]
    }
    paste(vapply(highest, function(row) {
      paste0(
        row$source_label[[1]],
        ": Tmin ",
        row$value_c[[1]],
        " ºC; sequência ",
        row$sequence_length[[1]],
        " noite(s)"
      )
    }, character(1)), collapse = "; ")
  }
  today_levels <- suppressWarnings(as.numeric(today$signal_level_order))
  future_levels <- suppressWarnings(as.numeric(future$signal_level_order))
  today_level <- if (length(today_levels) == 0 || all(is.na(today_levels))) {
    -1
  } else {
    max(today_levels, na.rm = TRUE)
  }
  future_level <- if (length(future_levels) == 0 || all(is.na(future_levels))) {
    -1
  } else {
    max(future_levels, na.rm = TRUE)
  }

  summary_signal(
    "Noites tropicais",
    status_text(today),
    status_text(future, include_date = TRUE),
    driver_text(today),
    today_level,
    future_level,
    {
      parts <- vapply(split(rows, rows$source_id), function(source_rows) {
        summary_horizon_from_rows(
          paste0("Noites tropicais - ", source_rows$source_label[[1]]),
          source_rows,
          "target_date",
          "signal_level_order",
          report_date,
          value_col = "value_c"
        )
      }, character(1))
      paste(parts[nzchar(parts)], collapse = "; ")
    },
    future_driver = driver_text(future)
  )
}

summary_bathing_water_signal <- function(report_date) {
  rows <- summary_read_csv("data/apa_matosinhos_bathing_water_latest.csv")
  if (nrow(rows) == 0) {
    return(summary_signal("Águas balneares"))
  }

  today <- summary_date_rows(rows, "snapshot_date", report_date)
  if (nrow(today) == 0) {
    return(summary_signal("Águas balneares"))
  }

  orders <- suppressWarnings(as.numeric(today$risk_level_order))
  highest_order <- if (all(is.na(orders))) -1 else max(orders, na.rm = TRUE)

  active <- today[!is.na(orders) & orders > 0, , drop = FALSE]
  in_season <- today[
    tolower(today$in_bathing_season) %in% "true",
    ,
    drop = FALSE
  ]

  today_text <- if (nrow(active) > 0) {
    restriction_types <- summary_join_unique(
      active$restriction_type,
      "restrição ativa"
    )
    beach_count <- nrow(active)
    water_count <- length(unique(active$bathing_water_code))
    paste0(
      restriction_types,
      " em ",
      beach_count,
      if (beach_count == 1) " praia, " else " praias, ",
      water_count,
      if (water_count == 1) " água balnear" else " águas balneares"
    )
  } else if (nrow(in_season) == 0) {
    "Fora da época balnear"
  } else if (highest_order < 0) {
    "Sem dados de estado"
  } else {
    paste0("Sem restrições ativas (", nrow(in_season), " praia(s) monitorizada(s))")
  }

  driver <- if (nrow(active) > 0) {
    beach_names <- summary_join_unique(
      active$beach_name,
      "não identificada"
    )
    paste0(
      if (nrow(active) == 1) "praia " else "praias ",
      beach_names,
      "; ",
      summary_join_unique(active$restriction_reason, "não indicado")
    )
  } else {
    "sem praias com desaconselhamento ou interdição no último snapshot"
  }

  summary_signal(
    "Águas balneares",
    today_text,
    "Sem previsão",
    driver,
    highest_order,
    -1,
    ""
  )
}

summary_collect_signals <- function(report_date) {
  list(
    summary_qualar_signal(report_date),
    summary_ipma_alert_signal(report_date),
    summary_bathing_water_signal(report_date),
    summary_temperature_signal(report_date),
    summary_tropical_night_signal(report_date),
    summary_heat_wave_signal(report_date),
    summary_thermal_signal(report_date),
    summary_sns_signal(report_date),
    summary_clima_extremo_signal(report_date),
    summary_uv_signal(report_date)
  )
}

summary_global_level <- function(signals) {
  orders <- vapply(signals, function(signal) {
    value <- signal$today_order
    if (is.na(value)) {
      return(-1)
    }
    value
  }, numeric(1))
  max_order <- max(orders, na.rm = TRUE)

  if (is.na(max_order) || max_order <= 0) {
    return("Rotina")
  }
  if (max_order == 1) {
    return("Vigilância")
  }
  if (max_order == 2) {
    return("Atenção")
  }

  "Alerta"
}

summary_order_value <- function(value) {
  if (is.null(value) || length(value) == 0 || is.na(value)) {
    return(-1)
  }

  as.numeric(value)
}

summary_risk_icon <- function(order) {
  if (length(order) > 1) {
    return(vapply(order, summary_risk_icon, character(1)))
  }
  order <- summary_order_value(order)
  if (order < 0) {
    return("⚪")
  }
  if (order == 0) {
    return("🟢")
  }
  if (order == 1) {
    return("🟡")
  }
  if (order == 2) {
    return("🟠")
  }
  "🔴"
}

summary_badged_status <- function(text, order) {
  text <- summary_as_text(text)
  if (grepl("🟢|🟡|🟠|🔴|⚪", text)) {
    return(text)
  }
  paste(summary_risk_icon(order), text)
}

summary_signal_planning_order <- function(signal) {
  max(
    summary_order_value(signal$today_order),
    summary_order_value(signal$future_order),
    na.rm = TRUE
  )
}

summary_local_risk_level_label <- function(level) {
  switch(
    as.character(level),
    "0" = "Nível 0 - Verde - Preparação",
    "1" = "Nível 1 - Amarelo - Vigilância reforçada",
    "2" = "Nível 2 - Laranja - Resposta reforçada",
    "3" = "Nível 3 - Vermelho - Emergência",
    "Nível indeterminado"
  )
}

summary_local_risk_domain_level <- function(signal, order = NULL) {
  if (is.null(order)) {
    order <- summary_signal_planning_order(signal)
  }
  if (is.na(order) || order <= 0) {
    return(list(level = 0, critical = FALSE))
  }

  domain <- signal$domain
  if (domain %in% c("Avisos IPMA", "Qualidade do ar", "Clima Extremo")) {
    return(list(level = min(3, max(1, floor(order))), critical = order >= 3))
  }

  if (domain == "Águas balneares") {
    return(list(level = min(3, max(1, floor(order))), critical = order >= 3))
  }

  if (domain == "Noites tropicais") {
    # Complementary heat signal without an approved standalone activation threshold.
    return(list(level = 0, critical = FALSE))
  }

  if (domain == "ÍCARO/FRIESA") {
    if (order >= 4) {
      return(list(level = 3, critical = TRUE))
    }
    if (order >= 2) {
      return(list(level = 2, critical = FALSE))
    }
    return(list(level = 1, critical = FALSE))
  }

  if (domain %in% c("Temperatura DSP", "Onda de calor")) {
    if (order >= 2) {
      return(list(level = 2, critical = FALSE))
    }
    return(list(level = 1, critical = FALSE))
  }

  if (domain == "Stress térmico UTCI") {
    if (order >= 5) {
      return(list(level = 3, critical = TRUE))
    }
    if (order >= 3) {
      return(list(level = 2, critical = FALSE))
    }
    return(list(level = 1, critical = FALSE))
  }

  if (domain == "Índice UV") {
    if (order >= 4) {
      return(list(level = 2, critical = FALSE))
    }
    if (order >= 2) {
      return(list(level = 1, critical = FALSE))
    }
    return(list(level = 0, critical = FALSE))
  }

  list(level = min(3, max(1, floor(order))), critical = FALSE)
}

summary_local_risk_candidates <- function(
  signals,
  horizon = c("planning", "today", "future")
) {
  horizon <- match.arg(horizon)
  rows <- lapply(signals, function(signal) {
    order <- switch(
      horizon,
      planning = summary_signal_planning_order(signal),
      today = summary_order_value(signal$today_order),
      future = summary_order_value(signal$future_order)
    )
    mapped <- summary_local_risk_domain_level(signal, order)
    if (mapped$level <= 0) {
      return(NULL)
    }

    data.frame(
      domain = signal$domain,
      level = mapped$level,
      level_label = summary_local_risk_level_label(mapped$level),
      critical = mapped$critical,
      today = signal$today,
      future = signal$future,
      driver = signal$driver,
      raw_order = order,
      stringsAsFactors = FALSE
    )
  })

  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0) {
    return(data.frame(
      domain = character(),
      level = numeric(),
      level_label = character(),
      critical = logical(),
      today = character(),
      future = character(),
      driver = character(),
      raw_order = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  do.call(rbind, rows)
}

summary_local_risk_assessment <- function(
  signals,
  horizon = c("planning", "today", "future")
) {
  horizon <- match.arg(horizon)
  candidates <- summary_local_risk_candidates(signals, horizon)
  if (nrow(candidates) == 0) {
    return(list(
      level = 0,
      label = summary_local_risk_level_label(0),
      candidates = candidates,
      reason = "sem indicadores ambientais/epidemiológicos disponíveis acima da vigilância habitual",
      limitation = paste(
        "Não integra ainda indicadores assistenciais internos da ULSM",
        "(SU, CSP, internamento, SAC, UHD), SINAVE/surtos locais, escalas, camas ou stocks."
      )
    ))
  }

  critical <- candidates[candidates$critical, , drop = FALSE]
  selected <- if (nrow(critical) > 0) {
    critical
  } else {
    candidates
  }
  level <- max(selected$level, na.rm = TRUE)
  selected <- selected[selected$level == level, , drop = FALSE]

  trigger_text <- paste(unique(selected$domain), collapse = ", ")
  if (nrow(critical) > 0) {
    reason <- paste0("critério crítico/sinal extremo nos indicadores disponíveis: ", trigger_text)
  } else if (nrow(candidates) >= 2) {
    reason <- paste0(
      nrow(candidates),
      " indicadores relevantes em simultâneo, conforme lógica do plano local: ",
      paste(unique(candidates$domain), collapse = ", ")
    )
  } else {
    reason <- paste0(
      "um indicador relevante isolado (",
      trigger_text,
      "); a ativação formal deve confirmar nível nacional, critérios assistenciais ou segundo indicador"
    )
  }

  list(
    level = level,
    label = summary_local_risk_level_label(level),
    candidates = candidates[order(-candidates$level, candidates$domain), , drop = FALSE],
    reason = reason,
    limitation = paste(
      "Não integra ainda indicadores assistenciais internos da ULSM",
      "(SU, CSP, internamento, SAC, UHD), SINAVE/surtos locais, escalas, camas ou stocks."
    )
  )
}

summary_preparation_level <- function(future_level) {
  if (is.na(future_level) || future_level <= 0) {
    return(0)
  }
  if (future_level >= 3) {
    return(2)
  }

  1
}

summary_operational_phase <- function(today_level, future_level) {
  if (today_level <= 0 && future_level <= 0) {
    return("Vigilância de rotina")
  }
  if (today_level > 0 && future_level > today_level) {
    return("Resposta atual e preparação para agravamento")
  }
  if (today_level > 0) {
    return("Resposta proporcional aos sinais atuais")
  }
  if (future_level >= 3) {
    return("Preparação reforçada")
  }

  "Vigilância e preparação antecipada"
}

summary_build_operational_model <- function(report_date, signals = NULL) {
  if (is.null(signals)) {
    signals <- summary_collect_signals(report_date)
  }

  today <- summary_local_risk_assessment(signals, "today")
  future <- summary_local_risk_assessment(signals, "future")
  preparation_level <- summary_preparation_level(future$level)
  operational_level <- max(today$level, preparation_level, na.rm = TRUE)

  list(
    report_date = as.character(report_date),
    signals = signals,
    today = today,
    future = future,
    preparation_level = preparation_level,
    operational_level = operational_level,
    phase = summary_operational_phase(today$level, future$level)
  )
}

summary_local_risk_lines <- function(assessment) {
  lines <- c(
    paste0("Nível local sugerido com dados disponíveis: ", assessment$label, "."),
    paste0("Justificação: ", assessment$reason, "."),
    paste0("Limitação: ", assessment$limitation)
  )

  candidates <- assessment$candidates
  if (nrow(candidates) == 0) {
    return(lines)
  }

  c(
    lines,
    "",
    "Indicadores considerados para esta sugestão:",
    vapply(seq_len(nrow(candidates)), function(i) {
      row <- candidates[i, , drop = FALSE]
      paste0(
        "- ",
        row$domain,
        ": ",
        row$level_label,
        " (hoje ",
        row$today,
        "; próximos dias ",
        row$future,
        "; motivo: ",
        row$driver,
        ")."
      )
    }, character(1))
  )
}

summary_operational_action <- function(level) {
  if (is.na(level) || level <= 0) {
    return("Manter rotina e vigilância diária dos indicadores.")
  }
  if (level == 1) {
    return("Manter atividades previstas, com vigilância reforçada e adaptação prudente de atividades exteriores ou de grupos vulneráveis.")
  }
  if (level == 2) {
    return("Preparar resposta reforçada, rever recursos e condicionar atividades de maior exposição enquanto persistirem os sinais.")
  }

  "Ativar resposta de emergência, comunicação dirigida e acompanhamento ativo de pessoas e estruturas vulneráveis."
}

summary_operational_decision <- function(model) {
  level <- model$operational_level
  today_level <- model$today$level
  future_level <- model$future$level

  if (level == 2 && today_level <= 0 && future_level >= 3) {
    return(
      "Preparar hoje a resposta reforçada para o risco previsto, sem declarar emergência antes de o critério se aplicar."
    )
  }
  if (level == 2 && future_level > today_level) {
    return(
      "Aplicar medidas seletivas aos sinais atuais e preparar hoje o reforço dirigido para o agravamento previsto."
    )
  }

  summary_operational_action(level)
}

summary_operational_badge <- function(level) {
  switch(
    as.character(level),
    "0" = "🟢 Verde - Nível 0 - Preparação",
    "1" = "🟡 Amarelo - Nível 1 - Vigilância reforçada",
    "2" = "🟠 Laranja - Nível 2 - Resposta reforçada",
    "3" = "🔴 Vermelho - Nível 3 - Emergência",
    "Nível indeterminado"
  )
}

summary_local_risk_snapshot_lines <- function(model) {
  c(
    paste0(
      "**Nível operacional:** ",
      summary_operational_badge(model$operational_level),
      "."
    ),
    paste0("**Fase operacional:** ", model$phase, "."),
    paste0(
      "**Decisão:** ",
      summary_operational_decision(model)
    ),
    "**Próxima reavaliação:** no boletim seguinte ou antes, se surgir aviso oficial ou agravamento relevante."
  )
}

summary_signal_authority <- function(domain) {
  switch(
    domain,
    "Avisos IPMA" = "aviso/indicador oficial IPMA",
    "Águas balneares" = "estado/restrição oficial APA e Autoridade de Saúde",
    "Índice UV" = "previsão oficial IPMA",
    "ÍCARO/FRIESA" = "índice oficial SNS/INSA",
    "Qualidade do ar" = "previsão ambiental QualAr",
    "Temperatura DSP" = "regra técnica local; previsões IPMA/Open-Meteo",
    "Noites tropicais" = "critério climatológico; previsões IPMA/Open-Meteo",
    "Onda de calor" = "critério técnico; previsões IPMA/Open-Meteo",
    "Stress térmico UTCI" = "indicador bioclimático com dados IPMA",
    "Clima Extremo" = "sinal técnico complementar para edifícios",
    "indicador técnico"
  )
}

summary_future_requires_preparation <- function(signal) {
  future_order <- summary_order_value(signal$future_order)
  today_order <- summary_order_value(signal$today_order)

  future_order > 0 && (today_order <= 0 || future_order > today_order)
}

summary_preparation_signals <- function(signals) {
  Filter(summary_future_requires_preparation, signals)
}

summary_operational_basis_lines <- function(model) {
  current <- Filter(function(signal) {
    summary_order_value(signal$today_order) > 0
  }, model$signals)
  preparation <- summary_preparation_signals(model$signals)

  current_text <- if (length(current) == 0) {
    "sem sinais ativos para hoje"
  } else {
    paste(vapply(current, function(signal) signal$domain, character(1)), collapse = ", ")
  }
  preparation_text <- if (length(preparation) == 0) {
    "sem agravamento futuro que exija preparação adicional"
  } else {
    paste(
      vapply(preparation, function(signal) signal$domain, character(1)),
      collapse = ", "
    )
  }

  paste0(
    "**Fundamento temporal:** atuação hoje por ",
    current_text,
    "; preparação antecipada por ",
    preparation_text,
    "."
  )
}

summary_active_factor_lines <- function(signals) {
  active <- Filter(function(signal) {
    !is.na(signal$today_order) && signal$today_order > 0
  }, signals)

  if (length(active) == 0) {
    return("- Sem sinais relevantes acima da vigilância habitual.")
  }

  active_level <- vapply(active, function(signal) {
    summary_local_risk_domain_level(
      signal,
      summary_order_value(signal$today_order)
    )$level
  }, numeric(1))
  active_order <- vapply(active, function(signal) {
    summary_order_value(signal$today_order)
  }, numeric(1))
  active <- active[order(-active_level, -active_order)]

  vapply(active, function(signal) {
    paste0(
      "- ",
      summary_risk_icon(signal$today_order),
      " **",
      signal$domain,
      "** (",
      summary_signal_authority(signal$domain),
      ")",
      ": ",
      signal$today,
      "; motivo: ",
      signal$driver,
      "."
    )
  }, character(1))
}

summary_preparation_factor_lines <- function(signals) {
  preparation <- summary_preparation_signals(signals)
  if (length(preparation) == 0) {
    return("- Sem agravamentos previstos que exijam preparação adicional hoje.")
  }

  future_level <- vapply(preparation, function(signal) {
    summary_local_risk_domain_level(
      signal,
      summary_order_value(signal$future_order)
    )$level
  }, numeric(1))
  future_order <- vapply(preparation, function(signal) {
    summary_order_value(signal$future_order)
  }, numeric(1))
  preparation <- preparation[order(-future_level, -future_order)]

  vapply(preparation, function(signal) {
    future_driver <- summary_as_text(signal$future_driver)
    if (future_driver == "") {
      future_driver <- summary_as_text(signal$driver)
    }
    paste0(
      "- ",
      summary_risk_icon(signal$future_order),
      " **",
      signal$domain,
      "** (",
      summary_signal_authority(signal$domain),
      "): preparar hoje para ",
      summary_future_action_text(signal$future),
      "; motivo: ",
      future_driver,
      "."
    )
  }, character(1))
}

summary_signal_has_future_data <- function(signal) {
  future <- summary_as_text(signal$future)
  future != "" &&
    !future %in% c("Sem dados", "Sem previsão", "A recalcular com novas observações") &&
    !grepl("^Sem dados", future)
}

summary_extract_future_date <- function(text) {
  match <- regexpr("\\d{4}-\\d{2}-\\d{2}", summary_as_text(text))
  if (match < 0) {
    return("")
  }

  date_value <- as.Date(regmatches(summary_as_text(text), match))
  if (is.na(date_value)) {
    return("")
  }

  format(date_value, "%d/%m")
}

summary_display_date_text <- function(text) {
  text <- summary_as_text(text)
  matches <- gregexpr("\\d{4}-\\d{2}-\\d{2}", text)
  values <- regmatches(text, matches)[[1]]
  if (length(values) == 0 || identical(values, character(0))) {
    return(text)
  }

  replacements <- vapply(values, function(value) {
    date_value <- as.Date(value)
    if (is.na(date_value)) value else format(date_value, "%d/%m")
  }, character(1))
  regmatches(text, matches) <- list(replacements)
  text
}

summary_future_action_text <- function(text) {
  sub(
    "^Amanhã:",
    "amanhã,",
    summary_display_date_text(text)
  )
}

summary_horizon_part <- function(signal) {
  explicit_horizon <- summary_as_text(signal$horizon)
  if (explicit_horizon != "") {
    return(explicit_horizon)
  }

  today_order <- summary_order_value(signal$today_order)
  future_order <- summary_order_value(signal$future_order)

  if (!summary_signal_has_future_data(signal)) {
    return(paste0(signal$domain, ": hoje - sem dados para os próximos dias"))
  }

  future_date <- summary_extract_future_date(signal$future)
  future_date_text <- if (future_date == "") "no horizonte disponível" else future_date

  if (today_order > 0 && future_order < today_order) {
    return(paste0(
      signal$domain,
      ": pico hoje, tendência a melhorar a partir de ",
      future_date_text
    ))
  }

  if (future_order > today_order) {
    return(paste0(signal$domain, ": pico em ", future_date_text))
  }

  paste0(signal$domain, ": previsto até ", future_date_text)
}

summary_recommendation_horizon <- function(signals) {
  active <- Filter(function(signal) {
    summary_order_value(signal$today_order) > 0 ||
      summary_order_value(signal$future_order) > 0
  }, signals)

  if (length(active) == 0) {
    return("sem sinais ativos no horizonte disponível.")
  }

  paste(vapply(active, summary_horizon_part, character(1)), collapse = "; ")
}

summary_has_domain <- function(signals, domain, use_future = FALSE) {
  match_index <- which(vapply(signals, function(x) x$domain == domain, logical(1)))
  if (length(match_index) == 0) {
    return(FALSE)
  }
  signal <- signals[[match_index[1]]]

  order <- if (use_future) signal$future_order else signal$today_order
  !is.na(order) && order > 0
}

summary_domain_text <- function(signals, domain, field = "today") {
  matches <- Filter(function(signal) signal$domain == domain, signals)
  if (length(matches) == 0) {
    return("Sem dados")
  }

  matches[[1]][[field]]
}

summary_future_preparation_recommendations <- function(signals) {
  preparation <- summary_preparation_signals(signals)
  thermal_domains <- c(
    "Temperatura DSP",
    "Noites tropicais",
    "Onda de calor",
    "Stress térmico UTCI",
    "ÍCARO/FRIESA",
    "Clima Extremo"
  )
  thermal <- Filter(function(signal) signal$domain %in% thermal_domains, preparation)
  other <- Filter(function(signal) !signal$domain %in% thermal_domains, preparation)
  general <- character()
  vulnerable <- character()
  establishments <- character()

  for (signal in other) {
    future_text <- summary_future_action_text(signal$future)
    domain <- signal$domain

    if (domain == "Qualidade do ar") {
      general <- c(
        general,
        paste0(
          "Preparar comunicação sobre qualidade do ar para ",
          future_text,
          ", incluindo redução de esforço intenso ao ar livre se houver sintomas."
        )
      )
      vulnerable <- c(
        vulnerable,
        "Garantir medicação habitual acessível e possibilidade de reduzir exposição exterior se a qualidade do ar agravar."
      )
      establishments <- c(
        establishments,
        "Preparar alternativas às atividades exteriores intensas para grupos vulneráveis."
      )
    } else if (domain == "Avisos IPMA") {
      general <- c(
        general,
        paste0(
          "Acompanhar as atualizações IPMA e preparar comunicação preventiva para ",
          future_text,
          "."
        )
      )
      vulnerable <- c(
        vulnerable,
        "Confirmar contacto com pessoas vulneráveis que possam precisar de apoio em deslocações ou proteção."
      )
      establishments <- c(
        establishments,
        "Rever atividades exteriores, contactos e medidas de contingência aplicáveis ao fenómeno previsto."
      )
    } else if (domain == "Índice UV") {
      general <- c(
        general,
        paste0("Preparar comunicação de fotoproteção para ", future_text, ".")
      )
      vulnerable <- c(
        vulnerable,
        "Preparar proteção reforçada para crianças e pessoas particularmente sensíveis à radiação UV."
      )
      establishments <- c(
        establishments,
        "Planear horários, sombra e proteção individual para atividades exteriores no período previsto."
      )
    }
  }

  if (length(thermal) > 0) {
    thermal_text <- paste(
      vapply(thermal, function(signal) {
        paste0(
          signal$domain,
          " (",
          summary_display_date_text(signal$future),
          ")"
        )
      }, character(1)),
      collapse = "; "
    )
    general <- c(
      general,
      paste0(
        "Preparar reforço das medidas de proteção térmica perante ",
        thermal_text,
        "."
      )
    )
    vulnerable <- c(
      vulnerable,
      "Preparar contactos prioritários; confirmar água, medicação e acesso a ambiente termicamente confortável."
    )
    establishments <- c(
      establishments,
      "Verificar conforto térmico, água, sombra ou abrigo, capacidade de arrefecimento e alternativas às atividades de maior exposição."
    )
  }

  list(
    general = unique(general),
    vulnerable = unique(vulnerable),
    establishments = unique(establishments)
  )
}

summary_today_recommendations <- function(
  signals,
  include_horizon = TRUE,
  include_future = FALSE
) {
  general <- character()
  vulnerable <- character()
  establishments <- character()

  if (summary_has_domain(signals, "Avisos IPMA")) {
    alert_text <- summary_domain_text(signals, "Avisos IPMA")
    alert_driver <- summary_domain_text(signals, "Avisos IPMA", "driver")
    alert_context <- paste(alert_text, alert_driver)
    general <- c(
      general,
      paste0(
        "Há aviso/risco IPMA relevante hoje (",
        alert_text,
        "); acompanhar atualizações e adaptar atividades dependentes da meteorologia."
      )
    )
    if (grepl("Tempo Quente", alert_context, ignore.case = TRUE)) {
      vulnerable <- c(
        vulnerable,
        "Reforçar contacto com pessoas idosas, crianças, pessoas com doença crónica, mobilidade reduzida ou isolamento social; garantir hidratação, ambiente fresco e redução de esforço nas horas mais quentes."
      )
      establishments <- c(
        establishments,
        "Rever medidas de calor: água disponível, sombra ou espaços frescos, adaptação de horários e redução de esforço em atividades exteriores."
      )
    } else if (grepl("Precipitação|Trovoada|Vento", alert_context, ignore.case = TRUE)) {
      vulnerable <- c(
        vulnerable,
        "Evitar deslocações ou atividades exteriores de maior exposição durante precipitação forte, trovoada ou vento; confirmar contacto regular com pessoas vulneráveis."
      )
      establishments <- c(
        establishments,
        "Rever planos de contingência, contactos e atividades exteriores; condicionar saídas nos períodos de precipitação forte, trovoada ou vento."
      )
    } else {
      vulnerable <- c(
        vulnerable,
        "Confirmar contacto regular com pessoas idosas, crianças, pessoas com doença crónica, mobilidade reduzida ou isolamento social e adaptar exposição ao fenómeno ativo."
      )
      establishments <- c(
        establishments,
        "Rever planos de contingência, contactos e atividades exteriores; adaptar atividades ao fenómeno ativo e às orientações IPMA/Proteção Civil."
      )
    }
  }

  if (summary_has_domain(signals, "Qualidade do ar")) {
    air_text <- summary_domain_text(signals, "Qualidade do ar", "driver")
    general <- c(
      general,
      paste0(
        "A qualidade do ar exige vigilância (",
        air_text,
        "); reduzir esforço intenso ao ar livre se surgirem sintomas."
      )
    )
    vulnerable <- c(
      vulnerable,
      "Pessoas com doença respiratória/cardiovascular, crianças, grávidas e idosos devem estar atentos a tosse, pieira, irritação ocular/garganta ou falta de ar."
    )
    establishments <- c(
      establishments,
      "Preferir atividades exteriores leves e adaptar atividades intensas para pessoas vulneráveis."
    )
  }

  if (summary_has_domain(signals, "Águas balneares")) {
    water_text <- summary_domain_text(signals, "Águas balneares", "driver")
    general <- c(
      general,
      paste0("Não entrar na água nas praias com restrição (", water_text, "); respeitar a sinalização local.")
    )
    vulnerable <- c(
      vulnerable,
      "Crianças, pessoas idosas, grávidas, pessoas imunocomprometidas ou com feridas/doença de pele devem evitar contacto com a água balnear afetada."
    )
    establishments <- c(
      establishments,
      "Cancelar atividades aquáticas nas praias afetadas, informar utentes e equipas e só retomar após levantamento oficial da restrição."
    )
  }

  if (summary_has_domain(signals, "Temperatura DSP") ||
      summary_has_domain(signals, "Noites tropicais") ||
      summary_has_domain(signals, "Onda de calor") ||
      summary_has_domain(signals, "ÍCARO/FRIESA")) {
    general <- c(
      general,
      "Reforçar hidratação, roupa adequada à temperatura e consulta das atualizações meteorológicas."
    )
    vulnerable <- c(
      vulnerable,
      "Manter contacto ativo com pessoas vulneráveis e garantir água, medicação habitual e acesso a ambiente confortável."
    )
    establishments <- c(
      establishments,
      "Garantir água, sombra ou abrigo e possibilidade de ajustar horários ou intensidade das atividades."
    )
  }

  if (summary_has_domain(signals, "Noites tropicais")) {
    tropical_text <- summary_domain_text(signals, "Noites tropicais")
    general <- c(
      general,
      paste0(
        "Há sinal de noite tropical (",
        tropical_text,
        "); favorecer arrefecimento noturno seguro, ventilando quando o exterior estiver mais fresco e mantendo hidratação."
      )
    )
    vulnerable <- c(
      vulnerable,
      "Reforçar contacto ao fim do dia e na manhã seguinte com pessoas que vivam sós ou em habitações quentes, vigiando sono perturbado, desidratação e agravamento de doença crónica."
    )
    establishments <- c(
      establishments,
      "Verificar a temperatura dos quartos e espaços de permanência noturna, assegurar água acessível e aplicar o plano de arrefecimento dos edifícios."
    )
  }

  if (summary_has_domain(signals, "Clima Extremo")) {
    clima_text <- summary_domain_text(signals, "Clima Extremo")
    clima_driver <- summary_domain_text(signals, "Clima Extremo", "driver")
    general <- c(
      general,
      paste0(
        "Reforçar a vigilância do conforto térmico em casa e equipamentos: ",
        clima_text,
        "; ",
        clima_driver,
        "."
      )
    )
    vulnerable <- c(
      vulnerable,
      "Garantir ambiente interior confortável, água e medicação acessível para pessoas idosas, crianças, pessoas com doença crónica, mobilidade reduzida ou isolamento social."
    )
    establishments <- c(
      establishments,
      "Confirmar conforto térmico das salas, água disponível, sombra ou abrigo e possibilidade de adaptar atividades se outros indicadores agravarem."
    )
  }

  if (summary_has_domain(signals, "Stress térmico UTCI")) {
    thermal_today <- summary_domain_text(signals, "Stress térmico UTCI")
    general <- c(
      general,
      paste0("Há sinal de stress térmico (", thermal_today, "); adequar roupa e duração da exposição exterior.")
    )
    vulnerable <- c(
      vulnerable,
      "Vigiar desconforto térmico, agravamento respiratório/cardiovascular e sinais de exaustão, frio ou calor."
    )
    establishments <- c(
      establishments,
      "Adaptar duração de atividades exteriores e assegurar abrigo, água e pausas."
    )
  }

  if (summary_has_domain(signals, "Índice UV")) {
    uv_today <- summary_domain_text(signals, "Índice UV")
    general <- c(
      general,
      paste0(
        "Usar óculos com filtro UV, chapéu e protetor solar em exposição prolongada: ",
        uv_today,
        "."
      )
    )
    vulnerable <- c(
      vulnerable,
      "Crianças, pessoas com pele clara, antecedentes de cancro cutâneo, doença ocular ou medicação fotossensibilizante devem reforçar chapéu, óculos UV, roupa protetora e protetor solar."
    )
    establishments <- c(
      establishments,
      "Garantir sombra, água e pausas; incentivar chapéu, óculos e protetor solar em atividades exteriores."
    )
  }

  if (include_future) {
    preparation <- summary_future_preparation_recommendations(signals)
    general <- c(general, preparation$general)
    vulnerable <- c(vulnerable, preparation$vulnerable)
    establishments <- c(establishments, preparation$establishments)
  }

  if (length(general) == 0) {
    general <- "Manter atividades habituais e acompanhar as atualizações."
  }
  if (length(vulnerable) == 0) {
    vulnerable <- "Manter rotinas habituais e vigiar sintomas ou desconforto térmico."
  }
  if (length(establishments) == 0) {
    establishments <- "Manter atividades previstas e capacidade de adaptação."
  }
  general <- unique(general)
  vulnerable <- unique(vulnerable)
  establishments <- unique(establishments)

  horizon <- summary_recommendation_horizon(signals)

  recommendation_lines <- c(
    "### Comunicação geral",
    "",
    paste0("- ", general),
    "",
    "### Grupos vulneráveis",
    "",
    paste0("- ", vulnerable),
    "",
    "### Estabelecimentos/equipamentos",
    "",
    paste0("- ", establishments)
  )

  if (include_horizon) {
    return(c(paste0("Horizonte temporal: ", horizon), "", recommendation_lines))
  }

  recommendation_lines
}

summary_future_lines <- function(signals) {
  future_changed <- Filter(function(signal) {
    if (!summary_signal_has_future_data(signal)) {
      return(FALSE)
    }

    today_order <- summary_order_value(signal$today_order)
    future_order <- summary_order_value(signal$future_order)
    if (future_order < 0) {
      return(FALSE)
    }
    if (today_order < 0) {
      return(future_order > 0)
    }

    future_order != today_order
  }, signals)

  if (length(future_changed) == 0) {
    return("- Sem mudanças ou agravamentos previstos nos dados disponíveis.")
  }

  future_order <- vapply(future_changed, summary_signal_planning_order, numeric(1))
  future_changed <- future_changed[order(-future_order)]

  vapply(future_changed, function(signal) {
    future_driver <- summary_as_text(signal$future_driver)
    if (future_driver == "") {
      future_driver <- summary_as_text(signal$driver)
    }
    paste0(
      "- ",
      signal$domain,
      ": ",
      signal$future,
      " (",
      future_driver,
      ")."
    )
  }, character(1))
}

summary_operational_horizon_lines <- function(signals) {
  relevant <- Filter(function(signal) {
    summary_signal_has_future_data(signal) &&
      (
        summary_order_value(signal$today_order) > 0 ||
          summary_order_value(signal$future_order) > 0
      )
  }, signals)

  if (length(relevant) == 0) {
    return("- Sem horizonte futuro disponível para sinais relevantes.")
  }

  vapply(relevant, function(signal) {
    paste0("- ", summary_horizon_part(signal), ".")
  }, character(1))
}

summary_no_signal_lines <- function(signals) {
  inactive <- Filter(function(signal) {
    summary_order_value(signal$today_order) <= 0 &&
      summary_order_value(signal$future_order) <= 0
  }, signals)

  if (length(inactive) == 0) {
    return("- Sem indicadores inativos.")
  }

  vapply(inactive, function(signal) {
    paste0("- 🟢 ", signal$domain, ": ", signal$today, ".")
  }, character(1))
}

summary_signal_decision <- function(signal) {
  today_order <- summary_order_value(signal$today_order)
  future_order <- summary_order_value(signal$future_order)

  if (today_order > 0 && future_order > today_order) {
    return("Atuar hoje e preparar agravamento")
  }
  if (today_order > 0) {
    return("Aplicar medidas hoje")
  }
  if (future_order > 0) {
    return("Preparar e vigiar")
  }
  if (today_order < 0 && future_order < 0) {
    return("Dados indisponíveis")
  }

  "Sem ativação"
}

summary_table_lines <- function(signals) {
  c(
    "| Dimensão | Hoje | Previsão relevante | Decisão |",
    "|---|---|---|---|",
    vapply(signals, function(signal) {
      paste0(
        "| ",
        signal$domain,
        " | ",
        summary_badged_status(signal$today, signal$today_order),
        " | ",
        summary_badged_status(
          summary_display_date_text(signal$future),
          signal$future_order
        ),
        " | ",
        summary_signal_decision(signal),
        " |"
      )
    }, character(1))
  )
}

summary_data_limitation_lines <- function(report_date) {
  lines <- c(
    "- A síntese e os códigos de cor apoiam a decisão, mas não substituem avisos oficiais nem a ativação formal do plano.",
    "- A comparação IPMA/Open-Meteo aplica-se ao DSP, noites tropicais e onda de calor. O UTCI permanece exclusivamente IPMA, porque temperatura aparente e UTCI não são indicadores equivalentes.",
    paste(
      "- Não integra indicadores assistenciais internos da ULSM",
      "(SU, CSP, internamento, SAC, UHD), SINAVE/surtos locais, escalas, camas ou stocks."
    )
  )
  source_errors <- summary_source_error_lines(report_date)
  freshness <- summary_source_freshness_lines(report_date)

  if (length(source_errors) > 0) {
    lines <- c(lines, source_errors)
  }
  if (length(freshness) > 0) {
    lines <- c(lines, freshness)
  }

  lines
}

build_operational_summary_section <- function(report_date, model = NULL) {
  if (is.null(model)) {
    model <- summary_build_operational_model(report_date)
  }
  signals <- model$signals

  c(
    paste0("<!-- ", SUMMARY_MARKER, ":start -->"),
    "## Alertas e pré-alertas ativos",
    "",
    "### Sinais aplicáveis hoje",
    "",
    summary_active_factor_lines(signals),
    "",
    "### Preparação baseada na previsão",
    "",
    summary_preparation_factor_lines(signals),
    "",
    "## Horizonte temporal",
    "",
    summary_operational_horizon_lines(signals),
    "",
    "## Ações a executar hoje",
    "",
    summary_today_recommendations(
      signals,
      include_horizon = FALSE,
      include_future = TRUE
    ),
    "",
    "## Quadro rápido de risco",
    "",
    summary_table_lines(signals),
    "",
    "## Sem ativação adicional",
    "",
    summary_no_signal_lines(signals),
    "",
    "## Limitações dos dados",
    "",
    summary_data_limitation_lines(report_date),
    paste0("<!-- ", SUMMARY_MARKER, ":end -->")
  )
}

replace_operational_summary <- function(content, report_date, model = NULL) {
  section <- build_operational_summary_section(report_date, model)
  start_marker <- paste0("<!-- ", SUMMARY_MARKER, ":start -->")
  end_marker <- paste0("<!-- ", SUMMARY_MARKER, ":end -->")
  start <- which(content == start_marker)
  end <- which(content == end_marker)

  if (length(start) > 0 && length(end) > 0 && end[1] > start[1]) {
    before <- if (start[1] > 1) content[seq_len(start[1] - 1)] else character()
    after <- if (end[1] < length(content)) content[(end[1] + 1):length(content)] else character()
    return(summary_compact_blank_lines(c(before, section, after)))
  }

  title_line <- grep("^# ", content)
  if (length(title_line) > 0) {
    before <- content[seq_len(title_line[1])]
    after <- if (title_line[1] < length(content)) {
      content[(title_line[1] + 1):length(content)]
    } else {
      character()
    }
    return(summary_compact_blank_lines(c(before, "", section, after)))
  }

  summary_compact_blank_lines(c(section, "", content))
}

ensure_detail_heading <- function(content) {
  content[content == "## Detalhe por indicador"] <- "## Indicadores detalhados"
  if (any(content == "## Indicadores detalhados")) {
    return(content)
  }

  end_marker <- paste0("<!-- ", SUMMARY_MARKER, ":end -->")
  end <- which(content == end_marker)
  if (length(end) == 0 || end[1] >= length(content)) {
    return(content)
  }

  source_header <- grep(SOURCES_HEADER_PATTERN, content)
  search_end <- if (length(source_header) > 0) source_header[1] - 1 else length(content)
  if (search_end <= end[1]) {
    return(content)
  }

  detail_candidates <- which(
    seq_along(content) > end[1] &
      seq_along(content) <= search_end &
      (
        grepl("^### ", content) |
          grepl("^<!-- (temperatura-dsp|onda-calor|utci|sns-health|clima-extremo|uv|ipma-alerts):start -->$", content)
      )
  )

  if (length(detail_candidates) == 0) {
    return(content)
  }

  insert_at <- detail_candidates[1]
  before <- if (insert_at > 1) content[seq_len(insert_at - 1)] else character()
  after <- content[insert_at:length(content)]
  summary_compact_blank_lines(c(before, "## Indicadores detalhados", "", after))
}

summary_temperature_value <- function(value) {
  value <- suppressWarnings(as.numeric(value))
  if (length(value) == 0 || is.na(value[[1]])) {
    return("sem dados")
  }
  paste0(format(round(value[[1]], 1), trim = TRUE, nsmall = 1), " ºC")
}

summary_temperature_pair <- function(first, second) {
  paste(
    summary_temperature_value(first),
    summary_temperature_value(second),
    sep = " / "
  )
}

summary_replace_exact_marked_section <- function(content, marker, section) {
  start_marker <- paste0("<!-- ", marker, ":start -->")
  end_marker <- paste0("<!-- ", marker, ":end -->")
  start <- which(content == start_marker)
  end <- which(content == end_marker)
  if (length(start) == 0 || length(end) == 0 || end[[1]] < start[[1]]) {
    return(content)
  }

  before <- if (start[[1]] > 1) content[seq_len(start[[1]] - 1)] else
    character()
  after <- if (end[[1]] < length(content)) {
    content[(end[[1]] + 1):length(content)]
  } else {
    character()
  }
  summary_compact_blank_lines(c(before, section, after))
}

summary_station_observation_cell <- function(rows, date_value, station_id) {
  selected <- rows[
    rows$target_date == as.character(date_value) &
      rows$station_id == station_id,
    ,
    drop = FALSE
  ]
  if (nrow(selected) == 0) {
    return("sem dados")
  }
  paste0(
    summary_temperature_value(selected$tmin_c),
    " / ",
    summary_temperature_value(selected$tmax_c),
    " (",
    selected$hourly_observations,
    " h)"
  )
}

summary_temperature_observation_lines <- function(report_date) {
  station_rows <- tsc_recent_station_observations(report_date)
  history <- tsc_observations()
  dates <- as.Date(report_date) - 3:1

  c(
    "#### Observações usadas e estações de referência",
    "",
    "A série operacional usa o valor municipal IPMA quando disponível; nas datas recentes ainda sem esse registo, usa a média dos extremos diários de Pedras Rubras e S. Gens. As duas estações e a respetiva completude são apresentadas separadamente; o maior ou menor extremo não substitui automaticamente a série.",
    "",
    "| Data | Série usada Tmin/Tmax | Pedras Rubras Tmin/Tmax | S. Gens Tmin/Tmax |",
    "|---|---|---|---|",
    vapply(dates, function(date_value) {
      history_row <- history[
        as.Date(history$target_date) == date_value,
        ,
        drop = FALSE
      ]
      history_cell <- if (nrow(history_row) == 0) {
        "sem dados"
      } else {
        paste0(
          summary_temperature_value(history_row$tmin_c),
          " / ",
          summary_temperature_value(history_row$tmax_c)
        )
      }
      paste0(
        "| ",
        as.character(date_value),
        " | ",
        history_cell,
        " | ",
        summary_station_observation_cell(
          station_rows,
          date_value,
          "1200545"
        ),
        " | ",
        summary_station_observation_cell(
          station_rows,
          date_value,
          "1210649"
        ),
        " |"
      )
    }, character(1))
  )
}

summary_dsp_comparison_section <- function(report_date) {
  rows <- tsc_dsp_comparison(report_date)
  if (nrow(rows) == 0) {
    return(character())
  }

  levels <- suppressWarnings(as.numeric(rows$overall_alert_level))
  highest <- if (all(is.na(levels))) -1 else max(levels, na.rm = TRUE)
  labels <- paste0(
    rows$source_label,
    " ",
    summary_risk_icon(rows$overall_alert_level),
    " ",
    rows$overall_alert
  )
  interpretation <- if (length(unique(rows$overall_alert)) > 1) {
    paste0(
      "As fontes divergem: ",
      paste(labels, collapse = "; "),
      ". Usar o cenário mais exigente como pré-alerta técnico e manter o IPMA como referência oficial."
    )
  } else {
    paste0(
      "As fontes são concordantes: ",
      paste(labels, collapse = "; "),
      "."
    )
  }

  recommendations <- if (highest <= 0) {
    "- Sem medidas adicionais pelo indicador DSP; manter vigilância das atualizações."
  } else if (highest == 1) {
    c(
      "- Reforçar hidratação e reduzir exposição e esforço nas horas mais quentes.",
      "- Confirmar contacto, água, medicação e ambiente fresco para pessoas vulneráveis.",
      "- Rever horários, sombra, pausas e alternativas às atividades exteriores."
    )
  } else {
    c(
      "- Evitar exposição solar e esforço exterior nas horas de maior calor.",
      "- Reforçar acompanhamento ativo de pessoas vulneráveis e acesso a ambiente fresco.",
      "- Condicionar atividades exteriores intensas e ativar medidas de arrefecimento."
    )
  }

  c(
    "<!-- temperatura-dsp:start -->",
    paste0(
      "### Temperatura DSP - IPMA e Open-Meteo - ",
      report_date
    ),
    "",
    "A mesma regra DSP e as mesmas observações recentes são aplicadas separadamente às previsões das duas fontes. O Open-Meteo é complementar e não constitui aviso oficial.",
    "",
    "| Fonte da previsão | Tmax D/D+1 | Sinal máxima | Tmin D/D+1 | Sinal mínima | Sinal global |",
    "|---|---:|---|---:|---|---|",
    vapply(seq_len(nrow(rows)), function(index) {
      row <- rows[index, , drop = FALSE]
      paste0(
        "| ",
        row$source_label,
        " | ",
        summary_temperature_pair(
          row$tmax_forecast_d0_c,
          row$tmax_forecast_d_plus_1_c
        ),
        " | ",
        summary_badged_status(row$tmax_alert, row$tmax_alert_level),
        " | ",
        summary_temperature_pair(
          row$tmin_forecast_d0_c,
          row$tmin_forecast_d_plus_1_c
        ),
        " | ",
        summary_badged_status(row$tmin_alert, row$tmin_alert_level),
        " | ",
        summary_badged_status(row$overall_alert, row$overall_alert_level),
        " |"
      )
    }, character(1)),
    "",
    paste0("**Leitura comparada:** ", interpretation),
    "",
    summary_temperature_observation_lines(report_date),
    "",
    "#### Medidas associadas ao cenário mais exigente",
    "",
    recommendations,
    "<!-- temperatura-dsp:end -->"
  )
}

summary_parallel_dates <- function(rows, report_date) {
  sources <- unique(rows$source_id)
  if (length(sources) < 2) {
    return(sort(unique(as.Date(rows$target_date))))
  }
  dates <- lapply(sources, function(source_id) {
    as.Date(rows$target_date[rows$source_id == source_id])
  })
  common <- Reduce(intersect, lapply(dates, as.character))
  sort(as.Date(common[as.Date(common) >= as.Date(report_date)]))
}

summary_tropical_comparison_section <- function(report_date) {
  rows <- tsc_tropical_nights(report_date)
  if (nrow(rows) == 0) {
    return(character())
  }
  dates <- summary_parallel_dates(rows, report_date)
  source_ids <- c("ipma", "openmeteo")

  c(
    "<!-- tropical-nights:start -->",
    paste0(
      "### Noites tropicais - IPMA e Open-Meteo - ",
      report_date
    ),
    "",
    "Critério: Tmin >= 20 ºC. O indicador é complementar e não possui, isoladamente, limiar aprovado para ativação formal do plano local.",
    "",
    "| Data | IPMA Tmin | IPMA sinal | Open-Meteo Tmin | Open-Meteo sinal |",
    "|---|---:|---|---:|---|",
    vapply(dates, function(date_value) {
      selected <- lapply(source_ids, function(source_id) {
        rows[
          rows$source_id == source_id &
            as.Date(rows$target_date) == date_value,
          ,
          drop = FALSE
        ]
      })
      cells <- lapply(selected, function(row) {
        if (nrow(row) == 0) {
          return(c("sem dados", "⚪ Sem dados"))
        }
        c(
          summary_temperature_value(row$value_c),
          summary_badged_status(row$status, row$signal_level_order)
        )
      })
      paste0(
        "| ",
        as.character(date_value),
        " | ",
        cells[[1]][[1]],
        " | ",
        cells[[1]][[2]],
        " | ",
        cells[[2]][[1]],
        " | ",
        cells[[2]][[2]],
        " |"
      )
    }, character(1)),
    "",
    "A sequência é calculada separadamente por fonte, combinando as mesmas observações passadas com cada previsão.",
    "<!-- tropical-nights:end -->"
  )
}

summary_heat_wave_comparison_section <- function(report_date) {
  rows <- tsc_heat_waves(report_date)
  if (nrow(rows) == 0) {
    return(character())
  }
  dates <- summary_parallel_dates(rows, report_date)
  source_ids <- c("ipma", "openmeteo")

  c(
    "<!-- onda-calor:start -->",
    paste0(
      "### Onda de calor - IPMA e Open-Meteo - ",
      report_date
    ),
    "",
    "Critério IPMA aplicado em paralelo: pelo menos 6 dias consecutivos com Tmax superior em 5 ºC à normal mensal de Porto/Pedras Rubras 1991-2020. Uma sequência prevista é apresentada como possível onda de calor.",
    "",
    "| Data | Limiar | IPMA Tmax / sequência / estado | Open-Meteo Tmax / sequência / estado |",
    "|---|---:|---|---|",
    vapply(dates, function(date_value) {
      selected <- lapply(source_ids, function(source_id) {
        rows[
          rows$source_id == source_id &
            as.Date(rows$target_date) == date_value,
          ,
          drop = FALSE
        ]
      })
      cell <- function(row) {
        if (nrow(row) == 0) {
          return("⚪ sem dados")
        }
        paste0(
          summary_temperature_value(row$value_c),
          " / ",
          row$sequence_length,
          " d / ",
          summary_badged_status(row$status, row$heat_wave_level)
        )
      }
      threshold <- if (nrow(selected[[1]]) > 0) {
        selected[[1]]$threshold_c
      } else if (nrow(selected[[2]]) > 0) {
        selected[[2]]$threshold_c
      } else {
        NA_real_
      }
      paste0(
        "| ",
        as.character(date_value),
        " | ",
        summary_temperature_value(threshold),
        " | ",
        cell(selected[[1]]),
        " | ",
        cell(selected[[2]]),
        " |"
      )
    }, character(1)),
    "",
    "O resultado das duas fontes é mantido separado; não se prolonga nem combina uma sequência entre modelos.",
    "<!-- onda-calor:end -->"
  )
}

replace_parallel_temperature_sections <- function(content, report_date) {
  sections <- list(
    "temperatura-dsp" = summary_dsp_comparison_section(report_date),
    "tropical-nights" = summary_tropical_comparison_section(report_date),
    "onda-calor" = summary_heat_wave_comparison_section(report_date)
  )
  for (marker in names(sections)) {
    section <- sections[[marker]]
    if (length(section) > 0) {
      content <- summary_replace_exact_marked_section(
        content,
        marker,
        section
      )
    }
  }
  content
}

build_quick_daily_report <- function(report_date, model = NULL) {
  if (is.null(model)) {
    model <- summary_build_operational_model(report_date)
  }
  signals <- model$signals
  full_report_link <- paste0("../", report_date, ".md")

  summary_compact_blank_lines(c(
    summary_report_title(report_date),
    "",
    "## Alertas e pré-alertas ativos",
    "",
    "### Sinais aplicáveis hoje",
    "",
    summary_active_factor_lines(signals),
    "",
    "### Preparação baseada na previsão",
    "",
    summary_preparation_factor_lines(signals),
    "",
    "## Horizonte temporal",
    "",
    summary_operational_horizon_lines(signals),
    "",
    "## Ações a executar hoje",
    "",
    summary_today_recommendations(
      signals,
      include_horizon = FALSE,
      include_future = TRUE
    ),
    "",
    "## Sem ativação adicional",
    "",
    summary_no_signal_lines(signals),
    "",
    "## Limitações dos dados",
    "",
    summary_data_limitation_lines(report_date),
    "",
    "## Relatório completo",
    "",
    paste0("[Consultar o boletim técnico completo](", full_report_link, ").")
  ))
}

write_quick_daily_report <- function(
  report_date,
  model = NULL,
  quick_dir = file.path("daily", "resumo")
) {
  if (is.null(model)) {
    model <- summary_build_operational_model(report_date)
  }
  dir.create(quick_dir, showWarnings = FALSE, recursive = TRUE)
  report_path <- file.path(quick_dir, paste0(report_date, ".md"))
  writeLines(
    build_quick_daily_report(report_date, model),
    report_path,
    useBytes = TRUE
  )
  report_path
}

finalize_daily_report <- function(content, report_date, model = NULL) {
  if (is.null(model)) {
    model <- summary_build_operational_model(report_date)
  }
  content <- normalize_report_header(content, report_date)
  content <- replace_operational_summary(content, report_date, model)
  content <- replace_parallel_temperature_sections(content, report_date)
  content <- ensure_detail_heading(content)
  content <- replace_source_status_section(content, report_date)
  content <- replace_report_sources(content)
  content <- gsub(
    "evitar rigorosamente contacto",
    "evitar contacto",
    content,
    fixed = TRUE
  )
  replace_report_index(content)
}

refresh_daily_summary_file <- function(report_path, report_date) {
  if (!file.exists(report_path)) {
    return(report_path)
  }

  content <- readLines(report_path, warn = FALSE, encoding = "UTF-8")
  updated <- finalize_daily_report(content, report_date)
  writeLines(updated, report_path, useBytes = TRUE)
  report_path
}
