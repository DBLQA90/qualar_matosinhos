library(httr)
library(jsonlite)
library(dplyr)
library(readr)
source("report_summary.R", encoding = "UTF-8")

CSV_PATH <- "qualar_matosinhos.csv"
DAILY_DIR <- "daily"
QUALAR_URL <- "https://qualar.apambiente.pt/api/app.php"
QUALAR_KEY <- "s7GmWp8U"

LOCATION <- "Matosinhos, Porto, Portugal"
LATITUDE <- "41.1821"
LONGITUDE <- "-8.6891"
LOCAL_TZ <- "Europe/Lisbon"

CSV_COLUMNS <- c(
  "location",
  "latitude",
  "longitude",
  "forecast_date",
  "qualar_index",
  "source",
  "responsible_pollutants",
  "no2_ug_m3",
  "o3_ug_m3",
  "pm10_ug_m3",
  "pm25_ug_m3",
  "no2_alert",
  "o3_alert",
  "pm10_alert",
  "pm25_alert",
  "overall_alert_level",
  "overall_alert_label",
  "alert_drivers",
  "fetched_at"
)

KEY_COLUMNS <- c("location", "latitude", "longitude", "forecast_date")
COMPARE_COLUMNS <- setdiff(CSV_COLUMNS, "fetched_at")

POLLUTANT_COLUMNS <- c(
  "NO2" = "no2_ug_m3",
  "O3" = "o3_ug_m3",
  "PM10" = "pm10_ug_m3",
  "PM2.5" = "pm25_ug_m3"
)

ALERT_COLUMNS <- c(
  "NO2" = "no2_alert",
  "O3" = "o3_alert",
  "PM10" = "pm10_alert",
  "PM2.5" = "pm25_alert"
)

ALERT_NAMES <- c("Verde", "Amarelo", "Laranja", "Vermelho")

THRESHOLDS <- list(
  "O3" = c(green = 99, yellow = 179, orange = 239),
  "NO2" = c(green = 139, yellow = 199, orange = 399),
  "PM10" = c(green = 34, yellow = 49, orange = 119),
  "PM2.5" = c(green = 14, yellow = 24, orange = 49)
)

SOURCE_LINKS <- c(
  "- APA/DGS, Índice QualAr e classificação por poluente: https://www.dgs.pt/paginas-de-sistema/saude-de-a-a-z/qualidade-do-ar-ambiente/indice-de-qualidade-do-ar.aspx",
  "- DGS, recomendações de saúde para níveis Fraco e Mau: https://www.dgs.pt/paginas-de-sistema/saude-de-a-a-z/qualidade-do-ar-ambiente/recomendacoes-de-saude.aspx",
  "- Agência Europeia do Ambiente, mensagens de saúde por severidade: https://www.eea.europa.eu/pt/help/perguntas-frequentes/o-que-significam-os-valores",
  "- OMS Europa, medidas pessoais para reduzir exposição à poluição atmosférica: https://www.who.int/publications/i/item/WHO-EURO-2024-9115-48887-72806",
  "- EPA, ozono troposférico e redução de esforço ao ar livre: https://www.epa.gov/ozone-pollution-and-your-patients-health/what-ozone",
  "- EPA, NO₂ e efeitos respiratórios: https://www.epa.gov/no2-pollution/basic-information-about-no2"
)

empty_csv <- function() {
  out <- as.data.frame(
    matrix(character(), nrow = 0, ncol = length(CSV_COLUMNS)),
    stringsAsFactors = FALSE
  )
  names(out) <- CSV_COLUMNS
  out
}

as_text <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return("")
  }

  x <- x[[1]]
  if (is.na(x)) {
    return("")
  }

  as.character(x)
}

alert_label <- function(level) {
  paste0(ALERT_NAMES[level + 1], " (", level, ")")
}

classify_value <- function(value, pollutant) {
  value_num <- suppressWarnings(as.numeric(as_text(value)))

  if (is.na(value_num) || !pollutant %in% names(THRESHOLDS)) {
    return(list(level = NA_integer_, label = "Sem dados"))
  }

  limits <- THRESHOLDS[[pollutant]]
  level <- if (value_num <= limits[["green"]]) {
    0
  } else if (value_num <= limits[["yellow"]]) {
    1
  } else if (value_num <= limits[["orange"]]) {
    2
  } else {
    3
  }

  list(level = level, label = alert_label(level))
}

measurement_value <- function(measurements, pollutant) {
  match <- Filter(
    function(item) identical(as_text(item$pol), pollutant),
    measurements
  )

  if (length(match) == 0) {
    return("")
  }

  as_text(match[[1]]$val)
}

format_responsible_pollutants <- function(pollutants) {
  if (length(pollutants) == 0) {
    return("")
  }

  paste(
    vapply(
      pollutants,
      function(item) paste0(as_text(item$pol), "=", as_text(item$val)),
      character(1)
    ),
    collapse = ";"
  )
}

fetch_prediction <- function() {
  response <- GET(
    QUALAR_URL,
    query = list(
      type = "prediction",
      key = QUALAR_KEY,
      lat = LATITUDE,
      lon = LONGITUDE
    ),
    add_headers(
      `User-Agent` = "Mozilla/5.0",
      `Referer` = "https://qualar.apambiente.pt/"
    ),
    timeout(30)
  )
  stop_for_status(response)

  body <- content(response, as = "text", encoding = "UTF-8")
  parsed <- fromJSON(body, simplifyVector = FALSE)

  if (!identical(parsed$result, "success")) {
    stop("QualAr API returned result: ", as_text(parsed$result))
  }

  if (length(parsed$data) == 0) {
    stop("QualAr API returned no prediction data.")
  }

  parsed$data
}

flatten_prediction <- function(item, fetched_at) {
  data.frame(
    location = LOCATION,
    latitude = LATITUDE,
    longitude = LONGITUDE,
    forecast_date = as_text(item$date),
    qualar_index = as_text(item$ind),
    source = as_text(item$src),
    responsible_pollutants = format_responsible_pollutants(item$pols),
    no2_ug_m3 = measurement_value(item$meas, "NO2"),
    o3_ug_m3 = measurement_value(item$meas, "O3"),
    pm10_ug_m3 = measurement_value(item$meas, "PM10"),
    pm25_ug_m3 = measurement_value(item$meas, "PM2.5"),
    fetched_at = fetched_at,
    stringsAsFactors = FALSE
  )
}

classify_row <- function(row) {
  rows <- lapply(names(POLLUTANT_COLUMNS), function(pollutant) {
    column <- POLLUTANT_COLUMNS[[pollutant]]
    value <- as_text(row[[column]])
    classification <- classify_value(value, pollutant)
    data.frame(
      pollutant = pollutant,
      value = value,
      level = classification$level,
      label = classification$label,
      stringsAsFactors = FALSE
    )
  })

  bind_rows(rows)
}

format_pollutant <- function(pollutant, value, label) {
  paste0(pollutant, " ", value, " µg/m³ - ", label)
}

add_alert_columns <- function(data) {
  if (nrow(data) == 0) {
    for (column in setdiff(CSV_COLUMNS, names(data))) {
      data[[column]] <- character()
    }
    return(data[, CSV_COLUMNS])
  }

  for (column in c(ALERT_COLUMNS, "overall_alert_level", "overall_alert_label", "alert_drivers")) {
    data[[column]] <- ""
  }

  for (i in seq_len(nrow(data))) {
    info <- classify_row(data[i, , drop = FALSE])
    valid <- info[!is.na(info$level), , drop = FALSE]
    overall_level <- if (nrow(valid) == 0) 0 else max(valid$level)
    drivers <- valid[valid$level == overall_level & valid$level > 0, , drop = FALSE]
    active <- valid[valid$level > 0, , drop = FALSE]

    for (pollutant in names(ALERT_COLUMNS)) {
      data[[ALERT_COLUMNS[[pollutant]]]][i] <- info$label[info$pollutant == pollutant]
    }

    data$overall_alert_level[i] <- as.character(overall_level)
    data$overall_alert_label[i] <- alert_label(overall_level)
    data$alert_drivers[i] <- if (nrow(active) == 0) {
      "Nenhum"
    } else {
      paste(
        mapply(format_pollutant, active$pollutant, active$value, active$label),
        collapse = "; "
      )
    }

    if (nrow(drivers) > 0) {
      data$alert_drivers[i] <- paste(
        mapply(format_pollutant, active$pollutant, active$value, active$label),
        collapse = "; "
      )
    }
  }

  data[, CSV_COLUMNS]
}

read_existing <- function(path) {
  if (!file.exists(path)) {
    return(empty_csv())
  }

  existing <- read_csv(
    path,
    show_col_types = FALSE,
    col_types = cols(.default = "c")
  )

  if (!all(CSV_COLUMNS %in% names(existing))) {
    message("Existing CSV uses an older schema; replacing it with classified prediction API rows.")
    return(empty_csv())
  }

  existing <- as.data.frame(existing[, CSV_COLUMNS], stringsAsFactors = FALSE)
  existing[] <- lapply(existing, as.character)
  existing
}

same_values <- function(existing_row, new_row) {
  all(vapply(
    COMPARE_COLUMNS,
    function(column) identical(
      as_text(existing_row[[column]]),
      as_text(new_row[[column]])
    ),
    logical(1)
  ))
}

same_key <- function(existing, new_row) {
  matches <- rep(TRUE, nrow(existing))
  for (column in KEY_COLUMNS) {
    matches <- matches & existing[[column]] == new_row[[column]][1]
  }
  matches
}

upsert_predictions <- function(existing, predictions) {
  combined <- existing

  for (i in seq_len(nrow(predictions))) {
    new_row <- predictions[i, , drop = FALSE]
    matches <- if (nrow(combined) == 0) {
      logical()
    } else {
      same_key(combined, new_row)
    }
    match_index <- which(matches)

    if (length(match_index) > 0 &&
        same_values(combined[match_index[1], , drop = FALSE], new_row)) {
      next
    }

    if (length(match_index) > 0) {
      combined <- combined[-match_index, , drop = FALSE]
    }

    combined <- bind_rows(combined, new_row)
  }

  combined %>%
    arrange(forecast_date, location, latitude, longitude) %>%
    distinct(across(all_of(KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

pollutant_phrase <- function(info, min_level = 1) {
  selected <- info[!is.na(info$level) & info$level >= min_level, , drop = FALSE]

  if (nrow(selected) == 0) {
    return("sem poluentes acima de Verde")
  }

  paste(
    mapply(format_pollutant, selected$pollutant, selected$value, selected$label),
    collapse = "; "
  )
}

specific_pollutant_advice <- function(info) {
  active <- info[!is.na(info$level) & info$level > 0, , drop = FALSE]
  pollutants <- active$pollutant
  advice <- character()

  if ("O3" %in% pollutants) {
    advice <- c(
      advice,
      "Como o ozono está acima de Verde, privilegiar atividades ao ar livre de manhã cedo; no período quente, evitar atividade física intensa sobretudo entre as 15h e as 19h, quando o ozono tende a ser mais problemático."
    )
  }

  if (any(c("PM10", "PM2.5") %in% pollutants)) {
    advice <- c(
      advice,
      "Como há partículas acima de Verde, reduzir exposição a poeiras, fumo e vias com muito tráfego; nos níveis mais elevados, manter janelas fechadas quando viável e usar recirculação/filtração de ar."
    )
  }

  if ("NO2" %in% pollutants) {
    advice <- c(
      advice,
      "Como o NO₂ está acima de Verde, evitar esforço físico junto a eixos de tráfego e escolher percursos mais afastados de ruas congestionadas."
    )
  }

  if (length(advice) == 0) {
    return("Sem medidas específicas por poluente para além da vigilância habitual.")
  }

  paste(advice, collapse = " ")
}

recommendation_text <- function(row) {
  info <- classify_row(row)
  valid <- info[!is.na(info$level), , drop = FALSE]
  overall_level <- if (nrow(valid) == 0) 0 else max(valid$level)
  overall_label <- alert_label(overall_level)
  pollutant_detail <- pollutant_phrase(info, min_level = 0)
  active_detail <- pollutant_phrase(info, min_level = 1)
  specific_advice <- specific_pollutant_advice(info)

  general <- switch(
    as.character(overall_level),
    "0" = "Comunicação geral: mensagem tranquila e factual. A qualidade do ar prevista está em nível Verde (0); podem manter-se as atividades habituais ao ar livre, mantendo apenas a vigilância normal de sintomas em pessoas mais sensíveis.",
    "1" = "Comunicação geral: post em redes sociais com mensagem neutra e informativa. A qualidade do ar está em nível Amarelo (1); pessoas com doenças respiratórias ou cardiovasculares, crianças, grávidas e idosos devem estar atentos a sintomas e reduzir atividade física intensa ao ar livre se surgirem tosse, pieira, irritação ocular/garganta ou falta de ar.",
    "2" = "Comunicação geral: mensagem preventiva. A qualidade do ar está em nível Laranja (2); a população geral deve reduzir esforços prolongados ao ar livre se tiver sintomas, e os grupos vulneráveis devem evitar atividade física intensa ao ar livre.",
    "3" = "Comunicação geral: mensagem de alerta. A qualidade do ar está em nível Vermelho (3); a população geral deve evitar esforços físicos e limitar atividade ao ar livre, e os grupos vulneráveis devem permanecer no interior sempre que viável.",
    "Comunicação geral: sem classificação disponível; confirmar dados antes de emitir recomendação pública."
  )

  vulnerable <- switch(
    as.character(overall_level),
    "0" = "Grupos vulneráveis: manter rotinas habituais, com atenção a sintomas respiratórios ou cardiovasculares e cumprimento da medicação habitual.",
    "1" = "Grupos vulneráveis: evitar atividade física intensa ao ar livre se houver sintomas; quem utiliza medicação inalatória deve mantê-la de acordo com indicação médica e ter medicação de alívio acessível quando prescrita.",
    "2" = "Grupos vulneráveis: evitar atividade física intensa ao ar livre, preferir períodos e locais de menor exposição, manter tratamentos em curso e contactar SNS 24 ou serviços de saúde se houver agravamento de sintomas.",
    "3" = "Grupos vulneráveis: permanecer no interior com janelas fechadas sempre que viável, evitar esforço ao ar livre, manter tratamentos médicos em curso e contactar SNS 24 (808 24 24 24) ou serviços de saúde se houver agravamento de sintomas.",
    "Grupos vulneráveis: aguardar confirmação dos dados."
  )

  establishments <- switch(
    as.character(overall_level),
    "0" = "Estabelecimentos: manter atividades previstas, incluindo atividades exteriores, com monitorização diária.",
    "1" = "Estabelecimentos: manter atividades exteriores leves; condicionar atividades intensas para pessoas vulneráveis e preferir horários de menor exposição.",
    "2" = "Estabelecimentos: adaptar passeios, terapias e aulas de educação física; preferir atividades no interior ou de baixa intensidade e, se houver ozono, planear atividades exteriores antes das 11h.",
    "3" = "Estabelecimentos: suspender ou substituir atividades físicas intensas ao ar livre; privilegiar espaços interiores, reduzir exposição a ar exterior nos períodos críticos e acompanhar sintomas dos utentes.",
    "Estabelecimentos: aguardar confirmação dos dados."
  )

  paste(
    paste0(
      "Nível global: ", overall_label, ". Valores por poluente: ",
      pollutant_detail, ". Poluentes acima de Verde: ", active_detail, "."
    ),
    general,
    vulnerable,
    establishments,
    specific_advice,
    sep = "\n\n"
  )
}

section_for_day <- function(row, title) {
  date_text <- as_text(row$forecast_date)
  source <- as_text(row$source)
  body <- recommendation_text(row)

  c(
    paste0("### Qualidade do ar - ", title, " - ", date_text),
    "",
    paste0("Fonte dos valores: ", source, "."),
    "",
    body
  )
}

build_daily_report <- function(predictions, report_date) {
  report_day <- as.Date(report_date)
  next_day <- report_day + 1

  today_row <- predictions[predictions$forecast_date == as.character(report_day), , drop = FALSE]
  tomorrow_row <- predictions[predictions$forecast_date == as.character(next_day), , drop = FALSE]

  if (nrow(today_row) == 0) {
    today_row <- predictions[1, , drop = FALSE]
  }

  if (nrow(tomorrow_row) == 0 && nrow(predictions) >= 2) {
    tomorrow_row <- predictions[2, , drop = FALSE]
  }

  content <- c(
    paste0("# Boletim diário - ", LOCATION),
    "",
    paste0("Ficheiro diário: ", report_date),
    "",
    "## Detalhe por indicador",
    "",
    "Escala operacional usada: Verde (0), Amarelo (1), Laranja (2), Vermelho (3), conforme a tabela de estratificação por poluente indicada para O₃, NO₂, PM10 e PM2.5.",
    ""
  )

  if (nrow(today_row) > 0) {
    content <- c(content, section_for_day(today_row[1, , drop = FALSE], "Hoje"), "")
  }

  if (nrow(tomorrow_row) > 0) {
    content <- c(content, section_for_day(tomorrow_row[1, , drop = FALSE], "Amanhã"), "")
  }

  c(
    content,
    build_report_sources_section()
  )
}

extract_marked_section <- function(existing, marker) {
  start <- which(existing == paste0("<!-- ", marker, ":start -->"))
  end <- which(existing == paste0("<!-- ", marker, ":end -->"))

  if (length(start) == 0 || length(end) == 0 || end[1] <= start[1]) {
    return(character())
  }

  existing[start[1]:end[1]]
}

insert_marked_section <- function(content, section) {
  if (length(section) == 0) {
    return(content)
  }

  source_header <- grep(SOURCES_HEADER_PATTERN, content)
  if (length(source_header) > 0) {
    before <- if (source_header[1] > 1) {
      content[seq_len(source_header[1] - 1)]
    } else {
      character()
    }
    after <- content[source_header[1]:length(content)]
    return(c(before, section, "", after))
  }

  c(content, "", section)
}

insert_existing_managed_sections <- function(content, existing) {
  markers <- c(
    "temperatura-dsp",
    "onda-calor",
    "utci",
    "sns-health",
    "clima-extremo",
    "uv",
    "ipma-alerts"
  )
  for (marker in markers) {
    content <- insert_marked_section(
      content,
      extract_marked_section(existing, marker)
    )
  }

  content
}

write_daily_report <- function(predictions, report_date) {
  dir.create(DAILY_DIR, showWarnings = FALSE, recursive = TRUE)
  report_path <- file.path(DAILY_DIR, paste0(report_date, ".md"))
  content <- build_daily_report(predictions, report_date)

  if (file.exists(report_path)) {
    existing <- readLines(report_path, warn = FALSE, encoding = "UTF-8")
    content <- insert_existing_managed_sections(content, existing)
  }

  content <- finalize_daily_report(content, report_date)
  writeLines(content, report_path, useBytes = TRUE)
  report_path
}

fetched_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
report_date <- format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ)
api_data <- fetch_prediction()
new_data <- bind_rows(lapply(api_data, flatten_prediction, fetched_at = fetched_at))
new_data <- as.data.frame(new_data, stringsAsFactors = FALSE)
new_data[] <- lapply(new_data, as.character)
new_data <- add_alert_columns(new_data)

existing <- read_existing(CSV_PATH)
combined <- upsert_predictions(existing, new_data)
write_csv(combined, CSV_PATH, na = "")
report_path <- write_daily_report(new_data, report_date)

message(sprintf(
  "OK - %d forecast row(s) fetched; CSV now has %d row(s); daily report: %s.",
  nrow(new_data),
  nrow(combined),
  report_path
))
