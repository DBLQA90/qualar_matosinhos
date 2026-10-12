source("dsp_rules.R", encoding = "UTF-8")

TSC_IPMA_FORECAST_PATH <- "data/ipma_matosinhos_forecast_latest.csv"
TSC_OPENMETEO_FORECAST_PATH <- "data/openmeteo_matosinhos_forecast_latest.csv"
TSC_TEMPERATURE_HISTORY_PATH <- "data/ipma_matosinhos_temperaturas.csv"
TSC_STATION_OBSERVATIONS_PATH <- "data/ipma_matosinhos_station_observations.csv"
TSC_TROPICAL_NIGHT_THRESHOLD_C <- 20
TSC_HEAT_WAVE_NORMAL_TMAX <- c(
  "1" = 14.0,
  "2" = 15.0,
  "3" = 17.0,
  "4" = 18.1,
  "5" = 20.3,
  "6" = 22.7,
  "7" = 24.3,
  "8" = 24.8,
  "9" = 23.5,
  "10" = 20.7,
  "11" = 16.8,
  "12" = 14.7
)

tsc_read_csv <- function(path) {
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

tsc_num <- function(value) {
  suppressWarnings(as.numeric(value))
}

tsc_text <- function(value, fallback = "") {
  if (length(value) == 0 || is.na(value[[1]]) || value[[1]] == "") {
    return(fallback)
  }
  as.character(value[[1]])
}

tsc_latest_by_date <- function(rows, date_col, timestamp_cols) {
  if (nrow(rows) == 0 || !date_col %in% names(rows)) {
    return(rows)
  }

  timestamps <- rep("", nrow(rows))
  for (column in timestamp_cols) {
    if (column %in% names(rows)) {
      value <- as.character(rows[[column]])
      value[is.na(value)] <- ""
      timestamps <- pmax(timestamps, value)
    }
  }
  dates <- as.Date(rows[[date_col]])
  rows <- rows[!is.na(dates), , drop = FALSE]
  timestamps <- timestamps[!is.na(dates)]
  dates <- dates[!is.na(dates)]
  if (nrow(rows) == 0) {
    return(rows)
  }

  rows$.tsc_date <- dates
  rows$.tsc_timestamp <- timestamps
  rows <- rows[order(rows$.tsc_date, rows$.tsc_timestamp), , drop = FALSE]
  rows <- rows[!duplicated(rows$.tsc_date, fromLast = TRUE), , drop = FALSE]
  rows$.tsc_date <- NULL
  rows$.tsc_timestamp <- NULL
  rows
}

tsc_forecasts <- function() {
  ipma <- tsc_read_csv(TSC_IPMA_FORECAST_PATH)
  if (nrow(ipma) > 0) {
    if ("period_type" %in% names(ipma)) {
      ipma <- ipma[ipma$period_type == "daily", , drop = FALSE]
    }
    ipma <- tsc_latest_by_date(
      ipma,
      "forecast_date",
      c("fetched_at", "source_updated_at")
    )
    ipma_rows <- data.frame(
      source_id = "ipma",
      source_label = "IPMA",
      target_date = as.character(ipma$forecast_date),
      tmin_c = tsc_num(ipma$tmin_c),
      tmax_c = tsc_num(ipma$tmax_c),
      source_updated_at = as.character(ipma$source_updated_at),
      fetched_at = as.character(ipma$fetched_at),
      model = "IPMA Matosinhos",
      stringsAsFactors = FALSE
    )
  } else {
    ipma_rows <- data.frame(stringsAsFactors = FALSE)
  }

  openmeteo <- tsc_read_csv(TSC_OPENMETEO_FORECAST_PATH)
  if (nrow(openmeteo) > 0) {
    openmeteo <- tsc_latest_by_date(
      openmeteo,
      "forecast_date",
      c("fetched_at", "source_updated_at")
    )
    openmeteo_rows <- data.frame(
      source_id = "openmeteo",
      source_label = "Open-Meteo",
      target_date = as.character(openmeteo$forecast_date),
      tmin_c = tsc_num(openmeteo$temperature_2m_min_c),
      tmax_c = tsc_num(openmeteo$temperature_2m_max_c),
      source_updated_at = as.character(openmeteo$source_updated_at),
      fetched_at = as.character(openmeteo$fetched_at),
      model = paste0("Open-Meteo ", as.character(openmeteo$model)),
      stringsAsFactors = FALSE
    )
  } else {
    openmeteo_rows <- data.frame(stringsAsFactors = FALSE)
  }

  available <- Filter(
    function(rows) nrow(rows) > 0,
    list(ipma_rows, openmeteo_rows)
  )
  if (length(available) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  rows <- do.call(rbind, available)
  rows[order(rows$source_id, as.Date(rows$target_date)), , drop = FALSE]
}

tsc_observations <- function() {
  rows <- tsc_read_csv(TSC_TEMPERATURE_HISTORY_PATH)
  if (nrow(rows) == 0) {
    return(rows)
  }

  rows <- tsc_latest_by_date(rows, "date", c("fetched_at"))
  data.frame(
    target_date = as.character(rows$date),
    tmin_c = tsc_num(rows$tmin_c),
    tmax_c = tsc_num(rows$tmax_c),
    source = as.character(rows$source),
    fetched_at = as.character(rows$fetched_at),
    stringsAsFactors = FALSE
  )
}

tsc_value_for_date <- function(rows, date_value, column) {
  if (nrow(rows) == 0 || !column %in% names(rows)) {
    return(NA_real_)
  }
  selected <- rows[
    as.Date(rows$target_date) == as.Date(date_value),
    ,
    drop = FALSE
  ]
  if (nrow(selected) == 0) {
    return(NA_real_)
  }
  tsc_num(selected[[column]][[1]])
}

tsc_forecast_for_date <- function(rows, source_id, date_value, column) {
  if (nrow(rows) == 0 || !column %in% names(rows)) {
    return(NA_real_)
  }
  selected <- rows[
    rows$source_id == source_id &
      as.Date(rows$target_date) == as.Date(date_value),
    ,
    drop = FALSE
  ]
  if (nrow(selected) == 0) {
    return(NA_real_)
  }
  tsc_num(selected[[column]][[1]])
}

# A regra DSP vive em dsp_rules.R e é partilhada com fetch_ipma.R. Estes wrappers
# existem só para manter os nomes tsc_* usados neste ficheiro e nos testes.
tsc_dsp_classify_tmax <- function(date_value, observed, forecast) {
  dsp_classify_tmax(date_value, observed, forecast)
}

tsc_dsp_classify_tmin <- function(date_value, observed, forecast) {
  dsp_classify_tmin(date_value, observed, forecast)
}

tsc_dsp_comparison <- function(report_date) {
  report_date <- as.Date(report_date)
  forecasts <- tsc_forecasts()
  observations <- tsc_observations()
  if (nrow(forecasts) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  observed_tmax <- vapply(
    report_date - 3:1,
    function(value) tsc_value_for_date(observations, value, "tmax_c"),
    numeric(1)
  )
  observed_tmin <- vapply(
    report_date - 2:1,
    function(value) tsc_value_for_date(observations, value, "tmin_c"),
    numeric(1)
  )

  rows <- lapply(unique(forecasts$source_id), function(source_id) {
    source_rows <- forecasts[forecasts$source_id == source_id, , drop = FALSE]
    forecast_tmax <- c(
      tsc_forecast_for_date(forecasts, source_id, report_date, "tmax_c"),
      tsc_forecast_for_date(forecasts, source_id, report_date + 1, "tmax_c")
    )
    forecast_tmin <- c(
      tsc_forecast_for_date(forecasts, source_id, report_date, "tmin_c"),
      tsc_forecast_for_date(forecasts, source_id, report_date + 1, "tmin_c")
    )
    tmax <- tsc_dsp_classify_tmax(report_date, observed_tmax, forecast_tmax)
    tmin <- tsc_dsp_classify_tmin(report_date, observed_tmin, forecast_tmin)
    overall_label <- dsp_overall_alert(tmax$alert, tmin$alert)
    overall_level <- tsc_num(dsp_alert_level(overall_label))

    data.frame(
      source_id = source_id,
      source_label = tsc_text(source_rows$source_label, source_id),
      source_updated_at = max(source_rows$source_updated_at, na.rm = TRUE),
      tmax_observed_d_minus_3_c = observed_tmax[[1]],
      tmax_observed_d_minus_2_c = observed_tmax[[2]],
      tmax_observed_d_minus_1_c = observed_tmax[[3]],
      tmax_forecast_d0_c = forecast_tmax[[1]],
      tmax_forecast_d_plus_1_c = forecast_tmax[[2]],
      tmax_alert = tmax$alert,
      tmax_alert_level = tsc_num(tmax$level),
      tmin_observed_d_minus_2_c = observed_tmin[[1]],
      tmin_observed_d_minus_1_c = observed_tmin[[2]],
      tmin_forecast_d0_c = forecast_tmin[[1]],
      tmin_forecast_d_plus_1_c = forecast_tmin[[2]],
      tmin_alert = tmin$alert,
      tmin_alert_level = tsc_num(tmin$level),
      overall_alert = overall_label,
      overall_alert_level = overall_level,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, rows)
}

tsc_contiguous_lengths <- function(values) {
  values[is.na(values)] <- FALSE
  run <- rle(values)
  rep(ifelse(run$values, run$lengths, 0L), run$lengths)
}

tsc_source_series <- function(report_date, source_id, value_column) {
  report_date <- as.Date(report_date)
  observations <- tsc_observations()
  forecasts <- tsc_forecasts()
  source_forecasts <- forecasts[
    forecasts$source_id == source_id &
      as.Date(forecasts$target_date) >= report_date,
    ,
    drop = FALSE
  ]
  if (nrow(source_forecasts) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  observed <- data.frame(
    target_date = as.Date(observations$target_date),
    value_c = tsc_num(observations[[value_column]]),
    value_type = "observed",
    stringsAsFactors = FALSE
  )
  observed <- observed[
    !is.na(observed$target_date) & observed$target_date < report_date,
    ,
    drop = FALSE
  ]
  forecast <- data.frame(
    target_date = as.Date(source_forecasts$target_date),
    value_c = tsc_num(source_forecasts[[value_column]]),
    value_type = "forecast",
    stringsAsFactors = FALSE
  )

  combined <- rbind(observed, forecast)
  combined <- combined[!is.na(combined$target_date), , drop = FALSE]
  combined <- combined[order(combined$target_date, combined$value_type), , drop = FALSE]
  combined <- combined[!duplicated(combined$target_date, fromLast = TRUE), , drop = FALSE]
  full <- data.frame(
    target_date = seq(min(combined$target_date), max(combined$target_date), by = "day"),
    stringsAsFactors = FALSE
  )
  merge(full, combined, by = "target_date", all.x = TRUE, sort = TRUE)
}

tsc_tropical_nights <- function(report_date) {
  forecasts <- tsc_forecasts()
  if (nrow(forecasts) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  rows <- lapply(unique(forecasts$source_id), function(source_id) {
    series <- tsc_source_series(report_date, source_id, "tmin_c")
    if (nrow(series) == 0) {
      return(NULL)
    }
    criterion <- !is.na(series$value_c) &
      series$value_c >= TSC_TROPICAL_NIGHT_THRESHOLD_C
    series$sequence_length <- tsc_contiguous_lengths(criterion)
    selected <- series[
      series$target_date >= as.Date(report_date) &
        series$value_type == "forecast",
      ,
      drop = FALSE
    ]
    if (nrow(selected) == 0) {
      return(NULL)
    }
    selected$source_id <- source_id
    selected$source_label <- tsc_text(
      forecasts$source_label[forecasts$source_id == source_id],
      source_id
    )
    selected$tropical_night <- !is.na(selected$value_c) &
      selected$value_c >= TSC_TROPICAL_NIGHT_THRESHOLD_C
    selected$status <- ifelse(
      is.na(selected$value_c),
      "Sem dados",
      ifelse(
        selected$tropical_night,
        "Noite tropical prevista",
        "Sem critério de noite tropical"
      )
    )
    selected$signal_level_order <- ifelse(
      is.na(selected$value_c),
      -1,
      ifelse(selected$tropical_night, 1, 0)
    )
    selected[, c(
      "source_id",
      "source_label",
      "target_date",
      "value_c",
      "tropical_night",
      "sequence_length",
      "status",
      "signal_level_order"
    )]
  })

  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  do.call(rbind, rows)
}

tsc_heat_wave_threshold <- function(date_value) {
  month_value <- as.character(as.integer(format(as.Date(date_value), "%m")))
  normal <- unname(TSC_HEAT_WAVE_NORMAL_TMAX[[month_value]])
  if (length(normal) == 0 || is.na(normal)) {
    return(NA_real_)
  }
  normal + 5
}

tsc_heat_waves <- function(report_date) {
  forecasts <- tsc_forecasts()
  if (nrow(forecasts) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  rows <- lapply(unique(forecasts$source_id), function(source_id) {
    series <- tsc_source_series(report_date, source_id, "tmax_c")
    if (nrow(series) == 0) {
      return(NULL)
    }
    series$threshold_c <- vapply(
      series$target_date,
      tsc_heat_wave_threshold,
      numeric(1)
    )
    series$exceeds_threshold <- !is.na(series$value_c) &
      !is.na(series$threshold_c) &
      series$value_c > series$threshold_c
    series$sequence_length <- tsc_contiguous_lengths(series$exceeds_threshold)
    selected <- series[
      series$target_date >= as.Date(report_date) &
        series$value_type == "forecast",
      ,
      drop = FALSE
    ]
    if (nrow(selected) == 0) {
      return(NULL)
    }
    selected$source_id <- source_id
    selected$source_label <- tsc_text(
      forecasts$source_label[forecasts$source_id == source_id],
      source_id
    )
    selected$status <- ifelse(
      is.na(selected$value_c) | is.na(selected$threshold_c),
      "Sem dados",
      ifelse(
        selected$sequence_length >= 6,
        "Possível Onda de Calor",
        ifelse(
          selected$sequence_length == 5,
          "Sinal preventivo de 5 dias",
          "Sem critério"
        )
      )
    )
    selected$heat_wave_level <- ifelse(
      selected$status == "Possível Onda de Calor",
      2,
      ifelse(
        selected$status == "Sinal preventivo de 5 dias",
        1,
        ifelse(selected$status == "Sem critério", 0, -1)
      )
    )
    selected[, c(
      "source_id",
      "source_label",
      "target_date",
      "value_c",
      "threshold_c",
      "exceeds_threshold",
      "sequence_length",
      "status",
      "heat_wave_level"
    )]
  })

  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  do.call(rbind, rows)
}

tsc_recent_station_observations <- function(report_date, days = 3L) {
  rows <- tsc_read_csv(TSC_STATION_OBSERVATIONS_PATH)
  if (nrow(rows) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  rows$target_date <- as.Date(rows$date_local)
  rows$temperature_c <- tsc_num(rows$temperature_c)
  rows <- rows[
    !is.na(rows$target_date) &
      rows$target_date >= as.Date(report_date) - days &
      rows$target_date < as.Date(report_date) &
      !is.na(rows$temperature_c),
    ,
    drop = FALSE
  ]
  if (nrow(rows) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  key <- paste(rows$target_date, rows$station_id, rows$datetime_utc, sep = "|")
  rows <- rows[order(key, rows$fetched_at), , drop = FALSE]
  rows <- rows[!duplicated(key, fromLast = TRUE), , drop = FALSE]
  groups <- split(rows, paste(rows$target_date, rows$station_id, sep = "|"))
  output <- lapply(groups, function(group) {
    data.frame(
      target_date = as.character(group$target_date[[1]]),
      station_id = tsc_text(group$station_id),
      station_name = tsc_text(group$station_name),
      hourly_observations = length(unique(group$datetime_utc)),
      tmin_c = min(group$temperature_c),
      tmax_c = max(group$temperature_c),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, output)
}
