library(dplyr)
library(readr)
source("report_summary.R", encoding = "UTF-8")

TN_TEMPERATURE_PATH <- "data/ipma_matosinhos_temperaturas.csv"
TN_FORECAST_LATEST_PATH <- "data/ipma_matosinhos_forecast_latest.csv"
TN_OBSERVED_PATH <- "data/ipma_matosinhos_tropical_nights_observed.csv"
TN_FORECAST_PATH <- "data/ipma_matosinhos_tropical_nights_forecasts.csv"
TN_LATEST_PATH <- "data/ipma_matosinhos_tropical_nights_latest.csv"
TN_DAILY_DIR <- "daily"
TN_LOCAL_TZ <- "Europe/Lisbon"
TN_THRESHOLD_C <- 20
TN_ASSESSED_AT <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

TN_COLUMNS <- c(
  "source_updated_at",
  "assessed_at",
  "location",
  "district",
  "global_id_local",
  "target_date",
  "value_type",
  "tmin_c",
  "threshold_c",
  "tropical_night",
  "sequence_length",
  "sequence_start",
  "sequence_end",
  "observed_nights_in_sequence",
  "forecast_nights_in_sequence",
  "status",
  "signal_level",
  "signal_level_order",
  "recommendation_summary",
  "source"
)

tn_empty <- function() {
  out <- as.data.frame(
    matrix(character(), nrow = 0, ncol = length(TN_COLUMNS)),
    stringsAsFactors = FALSE
  )
  names(out) <- TN_COLUMNS
  out
}

tn_text <- function(value) {
  if (is.null(value) || length(value) == 0 || is.na(value[[1]])) {
    return("")
  }
  as.character(value[[1]])
}

tn_num <- function(value) {
  suppressWarnings(as.numeric(value))
}

tn_read_csv <- function(path) {
  if (!file.exists(path)) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  as.data.frame(
    suppressMessages(read_csv(
      path,
      show_col_types = FALSE,
      col_types = cols(.default = "c")
    )),
    stringsAsFactors = FALSE
  )
}

tn_read_existing <- function(path) {
  rows <- tn_read_csv(path)
  if (nrow(rows) == 0) {
    return(tn_empty())
  }
  for (column in setdiff(TN_COLUMNS, names(rows))) {
    rows[[column]] <- ""
  }
  rows <- rows[, TN_COLUMNS, drop = FALSE]
  rows[] <- lapply(rows, function(column) {
    column <- as.character(column)
    column[is.na(column)] <- ""
    column
  })
  rows
}

tn_prepare_observed <- function(history) {
  required <- c("date", "tmin_c")
  if (nrow(history) == 0 || !all(required %in% names(history))) {
    return(tn_empty())
  }

  fetched_at <- if ("fetched_at" %in% names(history)) {
    as.character(history$fetched_at)
  } else {
    rep("", nrow(history))
  }
  source <- if ("source" %in% names(history)) {
    as.character(history$source)
  } else {
    rep("IPMA", nrow(history))
  }

  rows <- data.frame(
    source_updated_at = fetched_at,
    assessed_at = TN_ASSESSED_AT,
    location = "Matosinhos",
    district = "Porto",
    global_id_local = "1130800",
    target_date = as.character(history$date),
    value_type = "observed",
    tmin_c = as.character(history$tmin_c),
    threshold_c = as.character(TN_THRESHOLD_C),
    tropical_night = "",
    sequence_length = "",
    sequence_start = "",
    sequence_end = "",
    observed_nights_in_sequence = "",
    forecast_nights_in_sequence = "",
    status = "",
    signal_level = "",
    signal_level_order = "",
    recommendation_summary = "",
    source = paste0(source, "; derivação noite tropical IPMA"),
    stringsAsFactors = FALSE
  )

  valid_dates <- !is.na(as.Date(rows$target_date))
  rows[valid_dates, TN_COLUMNS, drop = FALSE]
}

tn_prepare_forecast <- function(forecasts) {
  required <- c(
    "source_updated_at",
    "forecast_date",
    "period_hours",
    "tmin_c"
  )
  if (nrow(forecasts) == 0 || !all(required %in% names(forecasts))) {
    return(tn_empty())
  }

  source_updates <- forecasts$source_updated_at[
    forecasts$source_updated_at != "" & !is.na(forecasts$source_updated_at)
  ]
  if (length(source_updates) == 0) {
    return(tn_empty())
  }
  source_update <- max(source_updates)
  selected <- forecasts[
    forecasts$source_updated_at == source_update &
      forecasts$period_hours == "24",
    ,
    drop = FALSE
  ]
  if (nrow(selected) == 0) {
    return(tn_empty())
  }

  selected <- selected[
    order(
      selected$forecast_date,
      selected$tmin_c == "" | is.na(selected$tmin_c)
    ),
    ,
    drop = FALSE
  ]
  selected <- selected[!duplicated(selected$forecast_date), , drop = FALSE]

  data.frame(
    source_updated_at = as.character(selected$source_updated_at),
    assessed_at = TN_ASSESSED_AT,
    location = "Matosinhos",
    district = "Porto",
    global_id_local = "1130800",
    target_date = as.character(selected$forecast_date),
    value_type = "forecast",
    tmin_c = as.character(selected$tmin_c),
    threshold_c = as.character(TN_THRESHOLD_C),
    tropical_night = "",
    sequence_length = "",
    sequence_start = "",
    sequence_end = "",
    observed_nights_in_sequence = "",
    forecast_nights_in_sequence = "",
    status = "",
    signal_level = "",
    signal_level_order = "",
    recommendation_summary = "",
    source = "IPMA public-data forecast aggregate by local; derivação noite tropical",
    stringsAsFactors = FALSE
  )[, TN_COLUMNS, drop = FALSE]
}

tn_add_sequence_metadata <- function(rows) {
  if (nrow(rows) == 0) {
    return(tn_empty())
  }

  dates <- as.Date(rows$target_date)
  rows <- rows[order(dates, rows$value_type), , drop = FALSE]
  rows <- rows[!duplicated(rows$target_date, fromLast = TRUE), , drop = FALSE]
  dates <- as.Date(rows$target_date)
  temperatures <- tn_num(rows$tmin_c)
  tropical <- !is.na(temperatures) & temperatures >= TN_THRESHOLD_C

  rows$tropical_night <- ifelse(
    is.na(temperatures),
    "",
    ifelse(tropical, "TRUE", "FALSE")
  )
  rows$sequence_length <- ifelse(is.na(temperatures), "", "0")
  rows$sequence_start <- ""
  rows$sequence_end <- ""
  rows$observed_nights_in_sequence <- ifelse(is.na(temperatures), "", "0")
  rows$forecast_nights_in_sequence <- ifelse(is.na(temperatures), "", "0")

  index <- 1L
  while (index <= nrow(rows)) {
    if (!tropical[index]) {
      index <- index + 1L
      next
    }

    run_start <- index
    run_end <- index
    while (
      run_end < nrow(rows) &&
        tropical[run_end + 1L] &&
        !is.na(dates[run_end]) &&
        !is.na(dates[run_end + 1L]) &&
        as.integer(dates[run_end + 1L] - dates[run_end]) == 1L
    ) {
      run_end <- run_end + 1L
    }

    run_indices <- run_start:run_end
    run_length <- length(run_indices)
    observed_count <- sum(rows$value_type[run_indices] == "observed")
    forecast_count <- sum(rows$value_type[run_indices] == "forecast")
    rows$sequence_length[run_indices] <- as.character(run_length)
    rows$sequence_start[run_indices] <- as.character(dates[run_start])
    rows$sequence_end[run_indices] <- as.character(dates[run_end])
    rows$observed_nights_in_sequence[run_indices] <- as.character(observed_count)
    rows$forecast_nights_in_sequence[run_indices] <- as.character(forecast_count)
    index <- run_end + 1L
  }

  rows$status <- vapply(seq_len(nrow(rows)), function(i) {
    if (is.na(temperatures[i])) {
      return("Sem dados")
    }
    if (!tropical[i]) {
      return("Sem critério de noite tropical")
    }

    nature <- if (rows$value_type[i] == "observed") "observada" else "prevista"
    length_value <- as.integer(rows$sequence_length[i])
    if (is.na(length_value) || length_value <= 1L) {
      return(paste("Noite tropical", nature))
    }
    paste0(
      "Sequência de ",
      length_value,
      " noites tropicais (",
      rows$observed_nights_in_sequence[i],
      " observada(s), ",
      rows$forecast_nights_in_sequence[i],
      " prevista(s))"
    )
  }, character(1))

  rows$signal_level <- ifelse(
    is.na(temperatures),
    "Sem dados",
    ifelse(tropical, "Vigilância", "Sem sinal")
  )
  rows$signal_level_order <- ifelse(
    is.na(temperatures),
    "-1",
    ifelse(tropical, "1", "0")
  )
  rows$recommendation_summary <- ifelse(
    tropical,
    paste(
      "Favorecer arrefecimento noturno seguro, hidratação e vigilância",
      "de pessoas vulneráveis ou em habitações com sobreaquecimento."
    ),
    ifelse(
      is.na(temperatures),
      "Não emitir recomendação automática sem temperatura mínima.",
      "Sem medidas adicionais por noite tropical."
    )
  )

  rows[] <- lapply(rows, as.character)
  rows[, TN_COLUMNS, drop = FALSE]
}

tn_upsert <- function(existing, incoming, key_columns) {
  if (nrow(incoming) == 0) {
    return(existing)
  }
  combined <- existing
  for (i in seq_len(nrow(incoming))) {
    row <- incoming[i, , drop = FALSE]
    matches <- rep(TRUE, nrow(combined))
    for (column in key_columns) {
      matches <- matches & combined[[column]] == row[[column]][1]
    }
    if (any(matches)) {
      combined <- combined[!matches, , drop = FALSE]
    }
    combined <- bind_rows(combined, row)
  }
  combined[, TN_COLUMNS, drop = FALSE]
}

tn_write_outputs <- function(observed, forecast, latest, report_date) {
  dir.create("data", showWarnings = FALSE, recursive = TRUE)

  observed_existing <- tn_read_existing(TN_OBSERVED_PATH)
  observed_all <- tn_upsert(observed_existing, observed, "target_date") %>%
    arrange(target_date)
  write_csv(observed_all, TN_OBSERVED_PATH, na = "")

  forecast_existing <- tn_read_existing(TN_FORECAST_PATH)
  forecast_all <- tn_upsert(
    forecast_existing,
    forecast,
    c("source_updated_at", "target_date")
  ) %>%
    arrange(source_updated_at, target_date)
  write_csv(forecast_all, TN_FORECAST_PATH, na = "")

  latest_dates <- as.Date(latest$target_date)
  latest <- latest[
    !is.na(latest_dates) & latest_dates >= as.Date(report_date) - 7,
    ,
    drop = FALSE
  ]
  write_csv(latest, TN_LATEST_PATH, na = "")

  list(observed = observed_all, forecasts = forecast_all, latest = latest)
}

tn_display_temp <- function(value) {
  number <- tn_num(value)
  if (is.na(number)) {
    return("Sem dados")
  }
  format(round(number, 1), trim = TRUE, nsmall = 1, decimal.mark = ",")
}

tn_table_lines <- function(rows) {
  if (nrow(rows) == 0) {
    return("Sem temperaturas mínimas IPMA disponíveis para este período.")
  }
  c(
    "| Data | Tmin | Natureza | Critério | Sequência |",
    "|---|---:|---|---|---|",
    vapply(seq_len(nrow(rows)), function(i) {
      row <- rows[i, , drop = FALSE]
      nature <- if (tn_text(row$value_type) == "observed") {
        "Observada"
      } else {
        "Prevista"
      }
      criterion <- if (tn_text(row$tropical_night) == "TRUE") {
        "Sim"
      } else if (tn_text(row$tropical_night) == "FALSE") {
        "Não"
      } else {
        "Sem dados"
      }
      sequence <- if (tn_text(row$sequence_length) %in% c("", "0")) {
        "-"
      } else {
        paste0(
          tn_text(row$sequence_length),
          " noite(s), ",
          tn_text(row$sequence_start),
          " a ",
          tn_text(row$sequence_end)
        )
      }
      paste0(
        "| ",
        tn_text(row$target_date),
        " | ",
        tn_display_temp(row$tmin_c),
        " ºC | ",
        nature,
        " | ",
        criterion,
        " | ",
        sequence,
        " |"
      )
    }, character(1))
  )
}

tn_recommendations <- function(rows, report_date) {
  relevant <- rows[
    !is.na(as.Date(rows$target_date)) &
      as.Date(rows$target_date) >= as.Date(report_date) &
      rows$tropical_night == "TRUE",
    ,
    drop = FALSE
  ]
  if (nrow(relevant) == 0) {
    return(paste(
      "Comunicação geral: sem critério de noite tropical no horizonte IPMA disponível; manter vigilância das atualizações.",
      "Grupos vulneráveis: manter hidratação e atenção ao conforto térmico noturno, sobretudo em habitações quentes.",
      "Estabelecimentos/equipamentos: manter disponíveis as medidas habituais de ventilação, hidratação e controlo da temperatura interior.",
      sep = "\n\n"
    ))
  }

  paste(
    "Comunicação geral: estão observadas ou previstas temperaturas mínimas iguais ou superiores a 20 ºC. Manter hidratação e favorecer o arrefecimento noturno seguro da habitação, ventilando quando a temperatura exterior estiver mais baixa e a qualidade do ar o permitir.",
    "Grupos vulneráveis: reforçar o contacto ao fim do dia e na manhã seguinte com pessoas idosas, crianças pequenas, pessoas com doença crónica, mobilidade reduzida, isolamento social ou habitação com sobreaquecimento. Vigiar sono perturbado, desidratação, exaustão e agravamento da doença habitual.",
    "Estabelecimentos/equipamentos: verificar a temperatura dos quartos e espaços de permanência, assegurar água acessível, roupa de cama adequada e ventilação/arrefecimento seguro; registar e corrigir espaços que permaneçam excessivamente quentes durante a noite.",
    sep = "\n\n"
  )
}

tn_build_daily_section <- function(rows, report_date) {
  selected <- rows[
    !is.na(as.Date(rows$target_date)) &
      as.Date(rows$target_date) >= as.Date(report_date) - 2,
    ,
    drop = FALSE
  ]
  source_updates <- unique(selected$source_updated_at[selected$source_updated_at != ""])
  source_text <- if (length(source_updates) == 0) {
    "sem atualização identificada"
  } else {
    paste(sort(source_updates), collapse = "; ")
  }

  c(
    "<!-- tropical-nights:start -->",
    paste0("### Noites tropicais - observação e previsão em ", report_date),
    "",
    paste0(
      "Fonte dos valores: IPMA para Matosinhos. Critério: temperatura mínima diária >= ",
      TN_THRESHOLD_C,
      " ºC. Atualizações consideradas: ",
      source_text,
      ". Este é um sinal complementar de vigilância e não possui, isoladamente, limiar aprovado para ativação formal do plano local."
    ),
    "",
    tn_table_lines(selected),
    "",
    tn_recommendations(selected, report_date),
    "<!-- tropical-nights:end -->"
  )
}

tn_replace_section_after <- function(existing, section, marker, anchor_marker) {
  start_marker <- paste0("<!-- ", marker, ":start -->")
  end_marker <- paste0("<!-- ", marker, ":end -->")
  start <- which(existing == start_marker)
  end <- which(existing == end_marker)
  if (length(start) > 0 && length(end) > 0 && end[1] > start[1]) {
    before <- if (start[1] > 1) existing[seq_len(start[1] - 1)] else character()
    after <- if (end[1] < length(existing)) existing[(end[1] + 1):length(existing)] else character()
    existing <- c(before, after)
  }

  anchor_end <- which(existing == paste0("<!-- ", anchor_marker, ":end -->"))
  if (length(anchor_end) > 0) {
    before <- existing[seq_len(anchor_end[1])]
    after <- if (anchor_end[1] < length(existing)) {
      existing[(anchor_end[1] + 1):length(existing)]
    } else {
      character()
    }
    return(c(before, "", section, after))
  }

  source_header <- grep(SOURCES_HEADER_PATTERN, existing)
  if (length(source_header) > 0) {
    before <- if (source_header[1] > 1) existing[seq_len(source_header[1] - 1)] else character()
    after <- existing[source_header[1]:length(existing)]
    return(c(before, section, "", after))
  }
  c(existing, "", section)
}

tn_update_daily_report <- function(rows, report_date) {
  dir.create(TN_DAILY_DIR, showWarnings = FALSE, recursive = TRUE)
  report_path <- file.path(TN_DAILY_DIR, paste0(report_date, ".md"))
  existing <- if (file.exists(report_path)) {
    readLines(report_path, warn = FALSE, encoding = "UTF-8")
  } else {
    c(summary_report_title(report_date), "")
  }
  section <- tn_build_daily_section(rows, report_date)
  updated <- tn_replace_section_after(
    existing,
    section,
    "tropical-nights",
    "temperatura-dsp"
  )
  updated <- finalize_daily_report(updated, report_date)
  writeLines(updated, report_path, useBytes = TRUE)
  report_path
}

tn_run <- function(report_date = format(Sys.time(), "%Y-%m-%d", tz = TN_LOCAL_TZ)) {
  history <- tn_read_csv(TN_TEMPERATURE_PATH)
  forecasts <- tn_read_csv(TN_FORECAST_LATEST_PATH)
  if (nrow(history) == 0 && nrow(forecasts) == 0) {
    stop("No IPMA temperature observations or forecasts are available.", call. = FALSE)
  }

  observed_raw <- tn_prepare_observed(history)
  forecast_raw <- tn_prepare_forecast(forecasts)
  observed <- tn_add_sequence_metadata(observed_raw)

  recent_observed <- observed_raw[
    !is.na(as.Date(observed_raw$target_date)) &
      as.Date(observed_raw$target_date) < as.Date(report_date),
    ,
    drop = FALSE
  ]
  combined <- tn_add_sequence_metadata(bind_rows(recent_observed, forecast_raw))
  forecast <- combined[combined$value_type == "forecast", , drop = FALSE]
  outputs <- tn_write_outputs(observed, forecast, combined, report_date)
  report_path <- tn_update_daily_report(outputs$latest, report_date)

  message(sprintf(
    paste(
      "OK tropical nights - %d observed row(s), %d forecast row(s);",
      "latest has %d row(s); report: %s."
    ),
    nrow(outputs$observed),
    nrow(forecast),
    nrow(outputs$latest),
    report_path
  ))
  invisible(outputs)
}

if (sys.nframe() == 0L) {
  tn_run()
}
