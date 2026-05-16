SUMMARY_MARKER <- "sintese"
SOURCES_HEADER_PATTERN <- "^## Fontes (usadas para recomendações|e metodologia)"

REPORT_SOURCE_SECTIONS <- list(
  "Nível local sugerido" = c(
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
    "- DGS, recomendações para ondas de calor: https://www.dgs.pt/saude-ambiental-calor/recomendacoes.aspx",
    "- DGS, temperaturas elevadas - recomendações: https://www.dgs.pt/em-destaque/temperaturas-elevadas-recomendacoes-da-dgs.aspx",
    "- SNS/DGS/INSA, recomendações contra o calor: https://www.sns.min-saude.pt/comunicado-conjunto-aumento-da-temperatura-recomendacoes-contra-o-calor/"
  ),
  "Onda de calor" = c(
    "- IPMA, definição de Onda de Calor: https://www.ipma.pt/pt/enciclopedia/clima/index.html?page=onda.calor.xml",
    "- IPMA, monitorização de Ondas de Calor: https://www.ipma.pt/pt/oclima/ondascalor/",
    "- IPMA, Normal Climatológica 1991-2020 - Porto/Pedras Rubras: https://www.ipma.pt/opencms/bin/file.data/climate-normal/cn_91-20_PORTO_PEDRAS_RUBRAS.pdf",
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
  future_order = -1
) {
  list(
    domain = domain,
    today = today,
    future = future,
    driver = driver,
    today_order = today_order,
    future_order = future_order
  )
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

summary_qualar_signal <- function(report_date) {
  rows <- summary_read_csv("qualar_matosinhos.csv")
  if (nrow(rows) == 0) {
    return(summary_signal("Qualidade do ar"))
  }

  today <- summary_date_rows(rows, "forecast_date", report_date)
  if (nrow(today) == 0) {
    today <- summary_first_future_row(rows, "forecast_date", report_date)
  }

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

  driver <- if (nrow(today) > 0) {
    driver_value <- summary_clean(today$alert_drivers, "Nenhum")
    if (driver_value == "Nenhum") {
      "sem poluentes acima de Verde"
    } else {
      driver_value
    }
  } else {
    "sem dados"
  }

  summary_signal(
    "Qualidade do ar",
    today_status,
    future_status,
    driver,
    summary_to_num(today$overall_alert_level),
    summary_to_num(future_highest$overall_alert_level)
  )
}

summary_temperature_signal <- function(report_date) {
  rows <- summary_read_csv("data/ipma_matosinhos_temperature_alert_latest.csv")
  if (nrow(rows) == 0) {
    return(summary_signal("Temperatura DSP"))
  }

  today <- summary_date_rows(rows, "target_date", report_date)
  future <- summary_after_date_rows(rows, "target_date", report_date)
  future_highest <- summary_highest_row(future, "overall_temperature_alert_level", "target_date")

  summary_signal(
    "Temperatura DSP",
    if (nrow(today) > 0) summary_clean(today$overall_temperature_alert) else "Sem dados",
    if (nrow(future_highest) > 0) {
      future_alert <- summary_clean(future_highest$overall_temperature_alert)
      if (future_alert == "Sem dados") {
        "A recalcular com novas observações"
      } else {
        paste0(
          summary_clean(future_highest$target_date),
          ": ",
          future_alert
        )
      }
    } else {
      "Sem dados"
    },
    if (nrow(today) > 0) {
      paste0(
        "máx. ",
        summary_clean(today$tmax_alert),
        "; mín. ",
        summary_clean(today$tmin_alert)
      )
    } else {
      "sem dados"
    },
    summary_to_num(today$overall_temperature_alert_level),
    summary_to_num(future_highest$overall_temperature_alert_level)
  )
}

summary_heat_wave_signal <- function(report_date) {
  rows <- summary_read_csv("data/ipma_matosinhos_heat_waves_latest.csv")
  if (nrow(rows) == 0) {
    return(summary_signal("Onda de calor"))
  }

  today <- summary_date_rows(rows, "target_date", report_date)
  future <- summary_after_date_rows(rows, "target_date", report_date)
  future_highest <- summary_highest_row(future, "heat_wave_level", "target_date")

  summary_signal(
    "Onda de calor",
    if (nrow(today) > 0) summary_clean(today$heat_wave_status) else "Sem dados",
    if (nrow(future_highest) > 0) {
      paste0(
        summary_clean(future_highest$target_date),
        ": ",
        summary_clean(future_highest$heat_wave_status)
      )
    } else {
      "Sem dados"
    },
    if (nrow(future_highest) > 0) {
      paste0(
        "sequência máxima ",
        summary_clean(future_highest$consecutive_exceedance_days, "0"),
        " dia(s)"
      )
    } else {
      "sem dados"
    },
    summary_to_num(today$heat_wave_level),
    summary_to_num(future_highest$heat_wave_level)
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
    if (nrow(future_highest) > 0) {
      paste0(
        "UTCI ",
        summary_clean(future_highest$utci_c),
        " ºC"
      )
    } else {
      "sem dados"
    },
    summary_to_num(today_highest$thermal_level_order),
    summary_to_num(future_highest$thermal_level_order)
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
    if (nrow(future_highest) > 0) {
      summary_clean(future_highest$protection_required)
    } else {
      "sem dados"
    },
    summary_to_num(today$uv_level_order),
    summary_to_num(future_highest$uv_level_order)
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
    summary_to_num(future_highest$risk_level_order)
  )
}

summary_clima_extremo_signal <- function(report_date) {
  rows <- summary_read_csv("data/clima_extremo_matosinhos_risk_latest.csv")
  if (nrow(rows) == 0) {
    return(summary_signal("Clima Extremo"))
  }

  today <- summary_date_rows(rows, "target_date", report_date)
  if (nrow(today) == 0) {
    today <- summary_first_future_row(rows, "target_date", report_date)
  }

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
    summary_to_num(future_highest$risk_level_order)
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
    summary_to_num(future_highest$alert_level_order)
  )
}

summary_collect_signals <- function(report_date) {
  list(
    summary_qualar_signal(report_date),
    summary_ipma_alert_signal(report_date),
    summary_temperature_signal(report_date),
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

summary_local_risk_domain_level <- function(signal) {
  order <- summary_signal_planning_order(signal)
  if (is.na(order) || order <= 0) {
    return(list(level = 0, critical = FALSE))
  }

  domain <- signal$domain
  if (domain %in% c("Avisos IPMA", "Qualidade do ar", "Clima Extremo")) {
    return(list(level = min(3, max(1, floor(order))), critical = order >= 3))
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

summary_local_risk_candidates <- function(signals) {
  rows <- lapply(signals, function(signal) {
    mapped <- summary_local_risk_domain_level(signal)
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
      stringsAsFactors = FALSE
    ))
  }

  do.call(rbind, rows)
}

summary_local_risk_assessment <- function(signals) {
  candidates <- summary_local_risk_candidates(signals)
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

summary_local_risk_snapshot_lines <- function(assessment, global_level) {
  c(
    paste0("**Estado hoje:** ", global_level, "."),
    paste0("**Nível local sugerido (hoje e horizonte de previsão):** ", assessment$label, "."),
    paste0("**Conduta operacional:** ", summary_operational_action(assessment$level)),
    paste0("**Justificação:** ", assessment$reason, "."),
    paste0("**Limitação:** ", assessment$limitation)
  )
}

summary_active_factor_lines <- function(signals) {
  active <- Filter(function(signal) {
    (!is.na(signal$today_order) && signal$today_order > 0) ||
      (!is.na(signal$future_order) && signal$future_order > 0)
  }, signals)

  if (length(active) == 0) {
    return("- Sem sinais relevantes acima da vigilância habitual.")
  }

  active_order <- vapply(active, summary_signal_planning_order, numeric(1))
  active <- active[order(-active_order)]

  vapply(active, function(signal) {
    paste0(
      "- ",
      signal$domain,
      ": hoje ",
      signal$today,
      "; próximos dias ",
      signal$future,
      "; motivo: ",
      signal$driver,
      "."
    )
  }, character(1))
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

summary_today_recommendations <- function(signals) {
  general <- character()
  vulnerable <- character()
  establishments <- character()

  if (summary_has_domain(signals, "Avisos IPMA")) {
    alert_text <- summary_domain_text(signals, "Avisos IPMA")
    general <- c(
      general,
      paste0(
        "Há aviso/risco IPMA relevante hoje (",
        alert_text,
        "); acompanhar atualizações e adaptar atividades dependentes da meteorologia."
      )
    )
    vulnerable <- c(
      vulnerable,
      "Evitar deslocações ou atividades exteriores de maior exposição durante precipitação forte/trovoada; confirmar contacto regular com pessoas idosas, crianças, pessoas com doença crónica, mobilidade reduzida ou isolamento social."
    )
    establishments <- c(
      establishments,
      "Rever planos de contingência, contactos e atividades exteriores; condicionar saídas em períodos de precipitação forte, trovoada, vento ou outro fenómeno ativo."
    )
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

  if (summary_has_domain(signals, "Temperatura DSP") ||
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
      "Garantir água, sombra/abrigo e possibilidade de ajustar horários ou intensidade das atividades."
    )
  }

  if (summary_has_domain(signals, "Clima Extremo")) {
    clima_text <- summary_domain_text(signals, "Clima Extremo")
    clima_driver <- summary_domain_text(signals, "Clima Extremo", "driver")
    general <- c(
      general,
      paste0(
        "O Clima Extremo assinala risco em edifícios (",
        clima_text,
        "; ",
        clima_driver,
        "); reforçar vigilância de conforto térmico em casa e equipamentos."
      )
    )
    vulnerable <- c(
      vulnerable,
      "Garantir ambiente interior confortável, água e medicação acessível para pessoas idosas, crianças, pessoas com doença crónica, mobilidade reduzida ou isolamento social."
    )
    establishments <- c(
      establishments,
      "Confirmar conforto térmico das salas, água disponível, sombra/abrigo e possibilidade de adaptar atividades se outros indicadores agravarem."
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
        "O índice UV requer proteção hoje (",
        uv_today,
        "); usar óculos com filtro UV, chapéu e protetor solar em exposição prolongada."
      )
    )
    vulnerable <- c(
      vulnerable,
      "Crianças, pessoas com pele clara, antecedentes de cancro cutâneo, doença ocular ou medicação fotossensibilizante devem reforçar chapéu, óculos UV, roupa protetora e protetor solar."
    )
    establishments <- c(
      establishments,
      "Garantir sombra, água, pausas e disponibilidade/incentivo a chapéu, óculos e protetor solar em atividades exteriores."
    )
  }

  if (length(general) == 0) {
    general <- "Manter atividades habituais, com vigilância diária das atualizações."
  } else {
    general <- paste(general, collapse = " ")
  }

  if (length(vulnerable) == 0) {
    vulnerable <- "Manter rotinas habituais, com atenção a sintomas respiratórios, cardiovasculares ou desconforto térmico."
  } else {
    vulnerable <- paste(vulnerable, collapse = " ")
  }

  if (length(establishments) == 0) {
    establishments <- "Manter atividades previstas, garantindo canais de comunicação, água e possibilidade de adaptação se os indicadores agravarem."
  } else {
    establishments <- paste(establishments, collapse = " ")
  }

  c(
    paste0("**Comunicação geral:** ", general),
    "",
    paste0("**Grupos vulneráveis:** ", vulnerable),
    "",
    paste0("**Estabelecimentos:** ", establishments)
  )
}

summary_future_lines <- function(signals) {
  future_active <- Filter(function(signal) {
    !is.na(signal$future_order) && signal$future_order > 0
  }, signals)

  if (length(future_active) == 0) {
    return("- Sem agravamento relevante identificado nos próximos dias disponíveis.")
  }

  future_order <- vapply(future_active, summary_signal_planning_order, numeric(1))
  future_active <- future_active[order(-future_order)]

  vapply(future_active, function(signal) {
    paste0(
      "- ",
      signal$domain,
      ": ",
      signal$future,
      " (",
      signal$driver,
      ")."
    )
  }, character(1))
}

summary_table_lines <- function(signals) {
  c(
    "| Dimensão | Hoje | Próximos dias | Principal motivo |",
    "|---|---|---|---|",
    vapply(signals, function(signal) {
      paste0(
        "| ",
        signal$domain,
        " | ",
        signal$today,
        " | ",
        signal$future,
        " | ",
        signal$driver,
        " |"
      )
    }, character(1))
  )
}

build_operational_summary_section <- function(report_date) {
  signals <- summary_collect_signals(report_date)
  global_level <- summary_global_level(signals)
  local_risk <- summary_local_risk_assessment(signals)
  generated_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

  c(
    paste0("<!-- ", SUMMARY_MARKER, ":start -->"),
    "## Síntese operacional",
    "",
    paste0("Data do boletim: ", report_date, ". Síntese gerada em ", generated_at, "."),
    "",
    summary_local_risk_snapshot_lines(local_risk, global_level),
    "",
    "## O que recomendar hoje",
    "",
    summary_today_recommendations(signals),
    "",
    "## Sinais que justificam",
    "",
    summary_active_factor_lines(signals),
    "",
    "## Próximos dias a vigiar",
    "",
    summary_future_lines(signals),
    "",
    "## Quadro rápido de risco",
    "",
    summary_table_lines(signals),
    paste0("<!-- ", SUMMARY_MARKER, ":end -->")
  )
}

replace_operational_summary <- function(content, report_date) {
  section <- build_operational_summary_section(report_date)
  start_marker <- paste0("<!-- ", SUMMARY_MARKER, ":start -->")
  end_marker <- paste0("<!-- ", SUMMARY_MARKER, ":end -->")
  start <- which(content == start_marker)
  end <- which(content == end_marker)

  if (length(start) > 0 && length(end) > 0 && end[1] > start[1]) {
    before <- if (start[1] > 1) content[seq_len(start[1] - 1)] else character()
    after <- if (end[1] < length(content)) content[(end[1] + 1):length(content)] else character()
    return(summary_compact_blank_lines(c(before, section, after)))
  }

  file_line <- grep("^Ficheiro diário:", content)
  if (length(file_line) > 0) {
    before <- content[seq_len(file_line[1])]
    after <- if (file_line[1] < length(content)) {
      content[(file_line[1] + 1):length(content)]
    } else {
      character()
    }
    return(summary_compact_blank_lines(c(before, "", section, after)))
  }

  summary_compact_blank_lines(c(section, "", content))
}

finalize_daily_report <- function(content, report_date) {
  content <- replace_operational_summary(content, report_date)
  replace_report_sources(content)
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
