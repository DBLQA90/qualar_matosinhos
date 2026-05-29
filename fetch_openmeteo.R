library(httr)
library(jsonlite)
library(dplyr)

DATA_DIR <- "data"
LOCAL_TZ <- "Europe/Lisbon"

LOCATION <- "Matosinhos"
DISTRICT <- "Porto"
DICO <- "1308"
LATITUDE <- 41.1805
LONGITUDE <- -8.6810
MODEL <- Sys.getenv("OPENMETEO_MODEL", "best_match")
HISTORY_MODEL <- Sys.getenv("OPENMETEO_HISTORY_MODEL", "era5_land")

OPENMETEO_FORECAST_URL <- "https://api.open-meteo.com/v1/forecast"
OPENMETEO_ARCHIVE_URL <- "https://archive-api.open-meteo.com/v1/archive"
OPENMETEO_HISTORICAL_FORECAST_URL <- "https://historical-forecast-api.open-meteo.com/v1/forecast"
OPENMETEO_PREVIOUS_RUNS_URL <- "https://previous-runs-api.open-meteo.com/v1/forecast"

HISTORY_PATH <- file.path(DATA_DIR, "openmeteo_matosinhos_history_daily.csv")
FORECAST_PATH <- file.path(DATA_DIR, "openmeteo_matosinhos_forecasts.csv")
FORECAST_LATEST_PATH <- file.path(DATA_DIR, "openmeteo_matosinhos_forecast_latest.csv")
HISTORICAL_FORECAST_PATH <- file.path(
  DATA_DIR,
  "openmeteo_matosinhos_historical_forecasts.csv"
)
PREVIOUS_RUNS_DAILY_PATH <- file.path(
  DATA_DIR,
  "openmeteo_matosinhos_previous_runs_daily.csv"
)
FORECAST_ERROR_PATH <- file.path(
  DATA_DIR,
  "openmeteo_matosinhos_forecast_errors.csv"
)
FORECAST_ERROR_SUMMARY_PATH <- file.path(
  DATA_DIR,
  "openmeteo_matosinhos_forecast_error_summary.csv"
)
STATUS_PATH <- file.path(DATA_DIR, "openmeteo_matosinhos_extraction_status.csv")
STATUS_LATEST_PATH <- file.path(
  DATA_DIR,
  "openmeteo_matosinhos_extraction_status_latest.csv"
)

HISTORY_COLUMNS <- c(
  "date",
  "fetched_at",
  "location",
  "district",
  "dico",
  "requested_latitude",
  "requested_longitude",
  "grid_latitude",
  "grid_longitude",
  "elevation_m",
  "timezone",
  "model",
  "temperature_2m_min_c",
  "temperature_2m_max_c",
  "temperature_2m_mean_c",
  "source"
)

FORECAST_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "location",
  "district",
  "dico",
  "requested_latitude",
  "requested_longitude",
  "grid_latitude",
  "grid_longitude",
  "elevation_m",
  "timezone",
  "model",
  "forecast_date",
  "horizon_days",
  "horizon_label",
  "temperature_2m_min_c",
  "temperature_2m_max_c",
  "temperature_2m_mean_c",
  "apparent_temperature_min_c",
  "apparent_temperature_max_c",
  "source"
)

HISTORICAL_FORECAST_COLUMNS <- c(
  "date",
  "fetched_at",
  "location",
  "district",
  "dico",
  "requested_latitude",
  "requested_longitude",
  "grid_latitude",
  "grid_longitude",
  "elevation_m",
  "timezone",
  "model",
  "temperature_2m_min_c",
  "temperature_2m_max_c",
  "temperature_2m_mean_c",
  "source"
)

PREVIOUS_RUNS_DAILY_COLUMNS <- c(
  "fetched_at",
  "location",
  "district",
  "dico",
  "requested_latitude",
  "requested_longitude",
  "grid_latitude",
  "grid_longitude",
  "elevation_m",
  "timezone",
  "model",
  "valid_date",
  "lead_days",
  "lead_label",
  "temperature_2m_min_c",
  "temperature_2m_max_c",
  "hourly_values_n",
  "source"
)

ERROR_COLUMNS <- c(
  "calculated_at",
  "valid_date",
  "lead_days",
  "lead_label",
  "location",
  "district",
  "dico",
  "forecast_tmin_c",
  "observed_tmin_c",
  "error_tmin_c",
  "abs_error_tmin_c",
  "forecast_tmax_c",
  "observed_tmax_c",
  "error_tmax_c",
  "abs_error_tmax_c",
  "forecast_source",
  "observed_source",
  "observation_status"
)

SUMMARY_COLUMNS <- c(
  "metric",
  "lead_days",
  "lead_label",
  "n",
  "mean_error_c",
  "mae_c",
  "rmse_c",
  "median_abs_error_c",
  "p90_abs_error_c",
  "min_error_c",
  "max_error_c",
  "first_valid_date",
  "last_valid_date",
  "calculated_at"
)

STATUS_COLUMNS <- c(
  "run_started_at",
  "task",
  "status",
  "started_at_utc",
  "completed_at_utc",
  "message"
)

empty_frame <- function(columns) {
  output <- as.data.frame(
    matrix(character(), nrow = 0, ncol = length(columns)),
    stringsAsFactors = FALSE
  )
  names(output) <- columns
  output
}

utc_now <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

local_today <- function() {
  as.Date(format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ))
}

to_num <- function(value) {
  suppressWarnings(as.numeric(value))
}

round_num <- function(value, digits = 3) {
  ifelse(is.na(value), NA_real_, round(value, digits))
}

read_character_csv <- function(path) {
  if (!file.exists(path)) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  read.csv(
    path,
    stringsAsFactors = FALSE,
    colClasses = "character",
    check.names = FALSE,
    fileEncoding = "UTF-8-BOM"
  )
}

write_csv_file <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write.csv(data, path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
}

select_columns <- function(data, columns) {
  missing_columns <- setdiff(columns, names(data))
  for (column in missing_columns) {
    data[[column]] <- ""
  }
  output <- data[, columns, drop = FALSE]
  output[] <- lapply(output, function(column) {
    column <- as.character(column)
    column[is.na(column)] <- ""
    column
  })
  output
}

as_text <- function(value) {
  if (is.null(value) || length(value) == 0 || is.na(value[[1]])) {
    return("")
  }
  as.character(value[[1]])
}

compact_message <- function(lines) {
  lines <- as.character(lines)
  lines <- lines[!is.na(lines) & nzchar(lines)]
  if (length(lines) == 0) {
    return("")
  }
  gsub("[[:space:]]+", " ", paste(lines, collapse = " | "))
}

append_deduplicated <- function(path, new_rows, columns, key_columns) {
  new_rows <- select_columns(new_rows, columns)
  existing <- read_character_csv(path)
  if (nrow(existing) > 0) {
    existing <- select_columns(existing, columns)
  } else {
    existing <- empty_frame(columns)
  }

  combined <- bind_rows(existing, new_rows)
  if (nrow(combined) > 0) {
    combined <- combined[!duplicated(combined[, key_columns, drop = FALSE], fromLast = TRUE), , drop = FALSE]
    combined <- combined[do.call(order, combined[, key_columns, drop = FALSE]), , drop = FALSE]
  }

  write_csv_file(select_columns(combined, columns), path)
  combined
}

date_chunks <- function(start_date, end_date, chunk_days = 3650L) {
  if (is.na(start_date) || is.na(end_date) || start_date > end_date) {
    return(list())
  }

  starts <- seq(start_date, end_date, by = paste(chunk_days, "days"))
  lapply(starts, function(chunk_start) {
    chunk_end <- min(chunk_start + chunk_days - 1L, end_date)
    c(start = chunk_start, end = chunk_end)
  })
}

openmeteo_get <- function(url, query, timeout_seconds = 90) {
  attempts <- as.integer(Sys.getenv("OPENMETEO_HTTP_RETRIES", "4"))
  if (is.na(attempts) || attempts < 1) {
    attempts <- 4L
  }

  response <- RETRY(
    "GET",
    url,
    query = query,
    timeout(timeout_seconds),
    user_agent("qualar_matosinhos/openmeteo"),
    times = attempts,
    pause_base = 2,
    pause_cap = 20,
    terminate_on = c(400, 401, 403, 404)
  )

  body <- content(response, as = "text", encoding = "UTF-8")
  if (http_error(response)) {
    stop(
      sprintf(
        "Open-Meteo HTTP %s: %s",
        status_code(response),
        substr(body, 1, 300)
      ),
      call. = FALSE
    )
  }

  parsed <- fromJSON(body, simplifyVector = TRUE)
  if (isTRUE(parsed$error)) {
    stop(sprintf("Open-Meteo API error: %s", as_text(parsed$reason)), call. = FALSE)
  }

  parsed
}

payload_meta <- function(payload) {
  data.frame(
    grid_latitude = as.character(payload$latitude),
    grid_longitude = as.character(payload$longitude),
    elevation_m = as.character(payload$elevation),
    timezone = as.character(payload$timezone),
    stringsAsFactors = FALSE
  )
}

daily_value <- function(daily, name) {
  n <- length(daily$time)
  if (name %in% names(daily)) {
    return(to_num(daily[[name]]))
  }
  rep(NA_real_, n)
}

fetch_archive_range <- function(start_date, end_date, fetched_at) {
  payload <- openmeteo_get(
    OPENMETEO_ARCHIVE_URL,
    list(
      latitude = LATITUDE,
      longitude = LONGITUDE,
      start_date = as.character(start_date),
      end_date = as.character(end_date),
      daily = "temperature_2m_max,temperature_2m_min,temperature_2m_mean",
      timezone = LOCAL_TZ,
      models = HISTORY_MODEL
    )
  )

  if (is.null(payload$daily) || length(payload$daily$time) == 0) {
    return(empty_frame(HISTORY_COLUMNS))
  }

  daily <- payload$daily
  meta <- payload_meta(payload)
  data.frame(
    date = as.character(daily$time),
    fetched_at = fetched_at,
    location = LOCATION,
    district = DISTRICT,
    dico = DICO,
    requested_latitude = as.character(LATITUDE),
    requested_longitude = as.character(LONGITUDE),
    grid_latitude = meta$grid_latitude,
    grid_longitude = meta$grid_longitude,
    elevation_m = meta$elevation_m,
    timezone = meta$timezone,
    model = HISTORY_MODEL,
    temperature_2m_min_c = round_num(daily_value(daily, "temperature_2m_min")),
    temperature_2m_max_c = round_num(daily_value(daily, "temperature_2m_max")),
    temperature_2m_mean_c = round_num(daily_value(daily, "temperature_2m_mean")),
    source = "Open-Meteo Historical Weather API (ERA5-Land)",
    stringsAsFactors = FALSE
  ) %>%
    filter(
      !is.na(temperature_2m_min_c) |
        !is.na(temperature_2m_max_c) |
        !is.na(temperature_2m_mean_c)
    ) %>%
    select(all_of(HISTORY_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

update_history <- function() {
  fetched_at <- utc_now()
  existing <- read_character_csv(HISTORY_PATH)
  initial_start <- as.Date(Sys.getenv("OPENMETEO_HISTORY_START", "1950-01-01"))
  lag_days <- as.integer(Sys.getenv("OPENMETEO_HISTORY_LAG_DAYS", "7"))
  overlap_days <- as.integer(Sys.getenv("OPENMETEO_HISTORY_OVERLAP_DAYS", "30"))
  if (is.na(lag_days) || lag_days < 0) {
    lag_days <- 7L
  }
  if (is.na(overlap_days) || overlap_days < 0) {
    overlap_days <- 30L
  }

  end_date <- local_today() - lag_days
  start_date <- initial_start
  if (nrow(existing) > 0 && "date" %in% names(existing)) {
    existing_dates <- suppressWarnings(as.Date(existing$date))
    earliest_date <- suppressWarnings(min(existing_dates, na.rm = TRUE))
    latest_date <- suppressWarnings(max(existing_dates, na.rm = TRUE))
    if (!is.na(earliest_date) && is.finite(earliest_date) && earliest_date > initial_start) {
      start_date <- initial_start
    } else if (!is.na(latest_date) && is.finite(latest_date)) {
      start_date <- max(initial_start, latest_date - overlap_days)
    }
  }

  if (is.na(start_date) || start_date > end_date) {
    message("Open-Meteo histórico sem novas datas disponíveis.")
    if (!file.exists(HISTORY_PATH)) {
      write_csv_file(empty_frame(HISTORY_COLUMNS), HISTORY_PATH)
    }
    return(0L)
  }

  chunks <- date_chunks(start_date, end_date)
  rows <- bind_rows(lapply(chunks, function(chunk) {
    fetch_archive_range(chunk[["start"]], chunk[["end"]], fetched_at)
  }))

  append_deduplicated(
    HISTORY_PATH,
    rows,
    HISTORY_COLUMNS,
    c("date", "model")
  )
  message(sprintf("Open-Meteo histórico atualizado: %d linha(s).", nrow(rows)))
  nrow(rows)
}

fetch_live_forecast <- function() {
  fetched_at <- utc_now()
  forecast_days <- as.integer(Sys.getenv("OPENMETEO_FORECAST_DAYS", "16"))
  if (is.na(forecast_days) || forecast_days < 1) {
    forecast_days <- 16L
  }

  payload <- openmeteo_get(
    OPENMETEO_FORECAST_URL,
    list(
      latitude = LATITUDE,
      longitude = LONGITUDE,
      daily = paste(
        c(
          "temperature_2m_max",
          "temperature_2m_min",
          "temperature_2m_mean",
          "apparent_temperature_max",
          "apparent_temperature_min"
        ),
        collapse = ","
      ),
      timezone = LOCAL_TZ,
      forecast_days = forecast_days,
      models = MODEL
    )
  )

  if (is.null(payload$daily) || length(payload$daily$time) == 0) {
    rows <- empty_frame(FORECAST_COLUMNS)
  } else {
    daily <- payload$daily
    meta <- payload_meta(payload)
    forecast_date <- as.Date(daily$time)
    horizon_days <- as.integer(forecast_date - local_today())
    rows <- data.frame(
      source_updated_at = fetched_at,
      fetched_at = fetched_at,
      location = LOCATION,
      district = DISTRICT,
      dico = DICO,
      requested_latitude = as.character(LATITUDE),
      requested_longitude = as.character(LONGITUDE),
      grid_latitude = meta$grid_latitude,
      grid_longitude = meta$grid_longitude,
      elevation_m = meta$elevation_m,
      timezone = meta$timezone,
      model = MODEL,
      forecast_date = as.character(forecast_date),
      horizon_days = as.character(horizon_days),
      horizon_label = paste0("D+", horizon_days),
      temperature_2m_min_c = round_num(daily_value(daily, "temperature_2m_min")),
      temperature_2m_max_c = round_num(daily_value(daily, "temperature_2m_max")),
      temperature_2m_mean_c = round_num(daily_value(daily, "temperature_2m_mean")),
      apparent_temperature_min_c = round_num(daily_value(daily, "apparent_temperature_min")),
      apparent_temperature_max_c = round_num(daily_value(daily, "apparent_temperature_max")),
      source = "Open-Meteo Forecast API",
      stringsAsFactors = FALSE
    ) %>%
      select(all_of(FORECAST_COLUMNS)) %>%
      as.data.frame(stringsAsFactors = FALSE)
  }

  append_deduplicated(
    FORECAST_PATH,
    rows,
    FORECAST_COLUMNS,
    c("source_updated_at", "model", "forecast_date")
  )
  write_csv_file(rows, FORECAST_LATEST_PATH)
  message(sprintf("Open-Meteo previsão futura atualizada: %d linha(s).", nrow(rows)))
  nrow(rows)
}

fetch_historical_forecast_range <- function(start_date, end_date, fetched_at) {
  payload <- openmeteo_get(
    OPENMETEO_HISTORICAL_FORECAST_URL,
    list(
      latitude = LATITUDE,
      longitude = LONGITUDE,
      start_date = as.character(start_date),
      end_date = as.character(end_date),
      daily = "temperature_2m_max,temperature_2m_min,temperature_2m_mean",
      timezone = LOCAL_TZ,
      models = MODEL
    )
  )

  if (is.null(payload$daily) || length(payload$daily$time) == 0) {
    return(empty_frame(HISTORICAL_FORECAST_COLUMNS))
  }

  daily <- payload$daily
  meta <- payload_meta(payload)
  data.frame(
    date = as.character(daily$time),
    fetched_at = fetched_at,
    location = LOCATION,
    district = DISTRICT,
    dico = DICO,
    requested_latitude = as.character(LATITUDE),
    requested_longitude = as.character(LONGITUDE),
    grid_latitude = meta$grid_latitude,
    grid_longitude = meta$grid_longitude,
    elevation_m = meta$elevation_m,
    timezone = meta$timezone,
    model = MODEL,
    temperature_2m_min_c = round_num(daily_value(daily, "temperature_2m_min")),
    temperature_2m_max_c = round_num(daily_value(daily, "temperature_2m_max")),
    temperature_2m_mean_c = round_num(daily_value(daily, "temperature_2m_mean")),
    source = "Open-Meteo Historical Forecast API",
    stringsAsFactors = FALSE
  ) %>%
    select(all_of(HISTORICAL_FORECAST_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

update_historical_forecast <- function() {
  fetched_at <- utc_now()
  existing <- read_character_csv(HISTORICAL_FORECAST_PATH)
  initial_start <- as.Date(Sys.getenv("OPENMETEO_HISTORICAL_FORECAST_START", "2022-01-01"))
  overlap_days <- as.integer(Sys.getenv("OPENMETEO_HISTORICAL_FORECAST_OVERLAP_DAYS", "30"))
  if (is.na(overlap_days) || overlap_days < 0) {
    overlap_days <- 30L
  }

  start_date <- initial_start
  end_date <- local_today()
  if (nrow(existing) > 0 && "date" %in% names(existing)) {
    existing_dates <- suppressWarnings(as.Date(existing$date))
    earliest_date <- suppressWarnings(min(existing_dates, na.rm = TRUE))
    latest_date <- suppressWarnings(max(existing_dates, na.rm = TRUE))
    if (!is.na(earliest_date) && is.finite(earliest_date) && earliest_date > initial_start) {
      start_date <- initial_start
    } else if (!is.na(latest_date) && is.finite(latest_date)) {
      start_date <- max(initial_start, latest_date - overlap_days)
    }
  }

  if (is.na(start_date) || start_date > end_date) {
    message("Open-Meteo arquivo de previsões sem novas datas disponíveis.")
    if (!file.exists(HISTORICAL_FORECAST_PATH)) {
      write_csv_file(empty_frame(HISTORICAL_FORECAST_COLUMNS), HISTORICAL_FORECAST_PATH)
    }
    return(0L)
  }

  chunks <- date_chunks(start_date, end_date, chunk_days = 730L)
  rows <- bind_rows(lapply(chunks, function(chunk) {
    fetch_historical_forecast_range(chunk[["start"]], chunk[["end"]], fetched_at)
  }))

  append_deduplicated(
    HISTORICAL_FORECAST_PATH,
    rows,
    HISTORICAL_FORECAST_COLUMNS,
    c("date", "model")
  )
  message(sprintf("Open-Meteo arquivo de previsões atualizado: %d linha(s).", nrow(rows)))
  nrow(rows)
}

previous_runs_column <- function(lead_days) {
  if (lead_days == 0L) {
    return("temperature_2m")
  }
  paste0("temperature_2m_previous_day", lead_days)
}

fetch_previous_runs_daily <- function() {
  fetched_at <- utc_now()
  existing <- read_character_csv(PREVIOUS_RUNS_DAILY_PATH)
  archive_start <- as.Date(Sys.getenv("OPENMETEO_PREVIOUS_RUNS_START", "2024-01-01"))
  past_days <- as.integer(Sys.getenv("OPENMETEO_PREVIOUS_RUNS_PAST_DAYS", "30"))
  forecast_days <- as.integer(Sys.getenv("OPENMETEO_PREVIOUS_RUNS_FORECAST_DAYS", "1"))
  max_lead_days <- as.integer(Sys.getenv("OPENMETEO_PREVIOUS_RUNS_MAX_LEAD_DAYS", "7"))
  max_past_days <- as.integer(Sys.getenv("OPENMETEO_PREVIOUS_RUNS_MAX_PAST_DAYS", "1500"))
  if (is.na(past_days) || past_days < 0) {
    past_days <- 30L
  }
  if (is.na(forecast_days) || forecast_days < 1) {
    forecast_days <- 1L
  }
  if (is.na(max_lead_days) || max_lead_days < 0 || max_lead_days > 7) {
    max_lead_days <- 7L
  }
  if (is.na(max_past_days) || max_past_days < 1) {
    max_past_days <- 1500L
  }

  if (nrow(existing) > 0 && "valid_date" %in% names(existing)) {
    existing_dates <- suppressWarnings(as.Date(existing$valid_date))
    earliest_date <- suppressWarnings(min(existing_dates, na.rm = TRUE))
    if (!is.na(earliest_date) && is.finite(earliest_date) && earliest_date > archive_start) {
      past_days <- max(past_days, as.integer(local_today() - archive_start) + 1L)
    }
  } else if (!is.na(archive_start)) {
    past_days <- max(past_days, as.integer(local_today() - archive_start) + 1L)
  }
  past_days <- min(past_days, max_past_days)

  requested_vars <- paste0("temperature_2m_previous_day", 0:max_lead_days)
  payload <- openmeteo_get(
    OPENMETEO_PREVIOUS_RUNS_URL,
    list(
      latitude = LATITUDE,
      longitude = LONGITUDE,
      hourly = paste(requested_vars, collapse = ","),
      timezone = LOCAL_TZ,
      past_days = past_days,
      forecast_days = forecast_days,
      models = MODEL
    ),
    timeout_seconds = if (past_days > 180) 300 else 120
  )

  if (is.null(payload$hourly) || length(payload$hourly$time) == 0) {
    rows <- empty_frame(PREVIOUS_RUNS_DAILY_COLUMNS)
  } else {
    hourly <- as.data.frame(payload$hourly, stringsAsFactors = FALSE)
    hourly$valid_date <- substr(as.character(hourly$time), 1, 10)
    meta <- payload_meta(payload)
    rows <- bind_rows(lapply(0:max_lead_days, function(lead_days) {
      column <- previous_runs_column(lead_days)
      if (!column %in% names(hourly)) {
        return(empty_frame(PREVIOUS_RUNS_DAILY_COLUMNS))
      }

      hourly %>%
        mutate(value = to_num(.data[[column]])) %>%
        filter(!is.na(value), !is.na(valid_date), valid_date != "") %>%
        group_by(valid_date) %>%
        summarise(
          temperature_2m_min_c = round(min(value, na.rm = TRUE), 3),
          temperature_2m_max_c = round(max(value, na.rm = TRUE), 3),
          hourly_values_n = sum(!is.na(value)),
          .groups = "drop"
        ) %>%
        mutate(
          fetched_at = fetched_at,
          location = LOCATION,
          district = DISTRICT,
          dico = DICO,
          requested_latitude = as.character(LATITUDE),
          requested_longitude = as.character(LONGITUDE),
          grid_latitude = meta$grid_latitude,
          grid_longitude = meta$grid_longitude,
          elevation_m = meta$elevation_m,
          timezone = meta$timezone,
          model = MODEL,
          lead_days = as.character(lead_days),
          lead_label = paste0("D+", lead_days),
          source = "Open-Meteo Previous Runs API"
        ) %>%
        select(all_of(PREVIOUS_RUNS_DAILY_COLUMNS)) %>%
        as.data.frame(stringsAsFactors = FALSE)
    }))
  }

  append_deduplicated(
    PREVIOUS_RUNS_DAILY_PATH,
    rows,
    PREVIOUS_RUNS_DAILY_COLUMNS,
    c("valid_date", "lead_days", "model")
  )
  message(sprintf("Open-Meteo previous runs atualizados: %d linha(s).", nrow(rows)))
  nrow(rows)
}

observation_status <- function(tmin, tmax) {
  case_when(
    is.na(tmin) & is.na(tmax) ~ "pending",
    is.na(tmin) | is.na(tmax) ~ "partial",
    TRUE ~ "matched_openmeteo_reanalysis"
  )
}

build_forecast_errors <- function() {
  previous_runs <- read_character_csv(PREVIOUS_RUNS_DAILY_PATH)
  history <- read_character_csv(HISTORY_PATH)

  if (nrow(previous_runs) == 0) {
    errors <- empty_frame(ERROR_COLUMNS)
    summary <- empty_frame(SUMMARY_COLUMNS)
    write_csv_file(errors, FORECAST_ERROR_PATH)
    write_csv_file(summary, FORECAST_ERROR_SUMMARY_PATH)
    message("Open-Meteo erros não calculados: previous runs sem dados.")
    return(0L)
  }

  if (nrow(history) == 0) {
    observations <- data.frame(
      date = character(),
      observed_tmin_c = numeric(),
      observed_tmax_c = numeric(),
      observed_source = character(),
      stringsAsFactors = FALSE
    )
  } else {
    observations <- history %>%
      transmute(
        date = as.character(date),
        observed_tmin_c = to_num(temperature_2m_min_c),
        observed_tmax_c = to_num(temperature_2m_max_c),
        observed_source = as.character(source)
      )
  }

  calculated_at <- utc_now()
  joined <- previous_runs %>%
    transmute(
      valid_date = as.character(valid_date),
      lead_days = as.character(lead_days),
      lead_label = as.character(lead_label),
      location = as.character(location),
      district = as.character(district),
      dico = as.character(dico),
      forecast_tmin_c = to_num(temperature_2m_min_c),
      forecast_tmax_c = to_num(temperature_2m_max_c),
      forecast_source = as.character(source)
    ) %>%
    left_join(observations, by = c("valid_date" = "date")) %>%
    mutate(
      observed_source = ifelse(is.na(observed_source), "", observed_source),
      error_tmin_c = forecast_tmin_c - observed_tmin_c,
      abs_error_tmin_c = abs(error_tmin_c),
      error_tmax_c = forecast_tmax_c - observed_tmax_c,
      abs_error_tmax_c = abs(error_tmax_c),
      observation_status = observation_status(observed_tmin_c, observed_tmax_c),
      calculated_at = calculated_at
    ) %>%
    transmute(
      calculated_at,
      valid_date,
      lead_days,
      lead_label,
      location,
      district,
      dico,
      forecast_tmin_c = round_num(forecast_tmin_c),
      observed_tmin_c = round_num(observed_tmin_c),
      error_tmin_c = round_num(error_tmin_c),
      abs_error_tmin_c = round_num(abs_error_tmin_c),
      forecast_tmax_c = round_num(forecast_tmax_c),
      observed_tmax_c = round_num(observed_tmax_c),
      error_tmax_c = round_num(error_tmax_c),
      abs_error_tmax_c = round_num(abs_error_tmax_c),
      forecast_source,
      observed_source,
      observation_status
    ) %>%
    arrange(valid_date, as.integer(lead_days)) %>%
    select(all_of(ERROR_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv_file(joined, FORECAST_ERROR_PATH)
  summary <- build_error_summary(joined)
  write_csv_file(summary, FORECAST_ERROR_SUMMARY_PATH)
  message(sprintf("Open-Meteo erros calculados: %d linha(s).", nrow(joined)))
  nrow(joined)
}

summary_for_metric <- function(errors, metric, forecast_column, observed_column, error_column, abs_column) {
  metric_data <- errors %>%
    transmute(
      metric = metric,
      lead_days = to_num(lead_days),
      lead_label = paste0("D+", lead_days),
      valid_date = as.character(valid_date),
      forecast_value = to_num(.data[[forecast_column]]),
      observed_value = to_num(.data[[observed_column]]),
      error_c = to_num(.data[[error_column]]),
      abs_error_c = to_num(.data[[abs_column]]),
      calculated_at = as.character(calculated_at)
    ) %>%
    filter(
      !is.na(lead_days),
      !is.na(forecast_value),
      !is.na(observed_value),
      !is.na(error_c)
    )

  if (nrow(metric_data) == 0) {
    return(empty_frame(SUMMARY_COLUMNS))
  }

  metric_data %>%
    group_by(metric, lead_days, lead_label) %>%
    summarise(
      n = n(),
      mean_error_c = round(mean(error_c), 3),
      mae_c = round(mean(abs_error_c), 3),
      rmse_c = round(sqrt(mean(error_c^2)), 3),
      median_abs_error_c = round(median(abs_error_c), 3),
      p90_abs_error_c = round(as.numeric(quantile(abs_error_c, 0.9, na.rm = TRUE)), 3),
      min_error_c = round(min(error_c), 3),
      max_error_c = round(max(error_c), 3),
      first_valid_date = min(valid_date),
      last_valid_date = max(valid_date),
      calculated_at = max(calculated_at),
      .groups = "drop"
    ) %>%
    mutate(lead_days = as.character(as.integer(lead_days))) %>%
    arrange(metric, as.integer(lead_days)) %>%
    select(all_of(SUMMARY_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

build_error_summary <- function(errors) {
  if (nrow(errors) == 0) {
    return(empty_frame(SUMMARY_COLUMNS))
  }

  bind_rows(
    summary_for_metric(
      errors,
      "temperature_2m_min_c",
      "forecast_tmin_c",
      "observed_tmin_c",
      "error_tmin_c",
      "abs_error_tmin_c"
    ),
    summary_for_metric(
      errors,
      "temperature_2m_max_c",
      "forecast_tmax_c",
      "observed_tmax_c",
      "error_tmax_c",
      "abs_error_tmax_c"
    )
  ) %>%
    select(all_of(SUMMARY_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

safe_task <- function(run_started_at, task, fun) {
  started_at <- utc_now()
  output <- character()
  status <- "ok"
  result <- tryCatch(
    withCallingHandlers(
      fun(),
      message = function(message) {
        output <<- c(output, conditionMessage(message))
      },
      warning = function(warning) {
        output <<- c(output, paste("WARNING:", conditionMessage(warning)))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(error) {
      status <<- "erro"
      output <<- c(output, conditionMessage(error))
      NA
    }
  )

  completed_at <- utc_now()
  if (status == "ok" && length(output) == 0) {
    output <- sprintf("Executado; resultado: %s.", as.character(result))
  }

  row <- data.frame(
    run_started_at = run_started_at,
    task = task,
    status = status,
    started_at_utc = started_at,
    completed_at_utc = completed_at,
    message = compact_message(output),
    stringsAsFactors = FALSE
  )

  prefix <- if (status == "ok") "OK" else "ERRO"
  cat(sprintf("%s Open-Meteo - %s\n", prefix, task))
  if (row$message != "") {
    cat(substr(row$message, 1, 1000), "\n")
  }

  row
}

append_status <- function(rows) {
  existing <- read_character_csv(STATUS_PATH)
  if (nrow(existing) > 0) {
    existing <- select_columns(existing, STATUS_COLUMNS)
  } else {
    existing <- empty_frame(STATUS_COLUMNS)
  }
  rows <- select_columns(rows, STATUS_COLUMNS)
  write_csv_file(bind_rows(existing, rows), STATUS_PATH)
  write_csv_file(rows, STATUS_LATEST_PATH)
}

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args) >= 1 && nzchar(args[[1]])) {
  tolower(args[[1]])
} else {
  "all"
}

tasks <- list(
  history = update_history,
  forecast = fetch_live_forecast,
  "historical-forecast" = update_historical_forecast,
  "previous-runs" = fetch_previous_runs_daily,
  errors = build_forecast_errors
)

aliases <- list(
  all = names(tasks),
  data = names(tasks),
  history = "history",
  forecast = "forecast",
  "historical-forecast" = "historical-forecast",
  "previous-runs" = "previous-runs",
  errors = "errors"
)

if (!mode %in% names(aliases)) {
  stop(
    "Unknown Open-Meteo mode: ",
    mode,
    ". Use all, data, history, forecast, historical-forecast, previous-runs or errors.",
    call. = FALSE
  )
}

dir.create(DATA_DIR, recursive = TRUE, showWarnings = FALSE)
run_started_at <- utc_now()
selected_tasks <- aliases[[mode]]
status_rows <- bind_rows(lapply(selected_tasks, function(task) {
  safe_task(run_started_at, task, tasks[[task]])
}))
append_status(status_rows)

error_count <- sum(status_rows$status != "ok")
if (error_count > 0) {
  message(sprintf(
    "Open-Meteo finished with %d recorded task error(s).",
    error_count
  ))
  quit(status = 1)
}

message("Open-Meteo finished without recorded task errors.")
