DATA_DIR <- "data"
CACHE_DIR <- file.path(DATA_DIR, "cache")
LOCAL_TZ <- "Europe/Lisbon"

LOCATION <- "Matosinhos"
DISTRICT <- "Porto"
DICO <- "1308"
GLOBAL_ID_LOCAL <- "1130800"
LATITUDE <- 41.1805
LONGITUDE <- -8.6810

BASELINE_START <- as.Date(Sys.getenv("ERA5_BASELINE_START", "1991-01-01"))
BASELINE_END <- as.Date(Sys.getenv("ERA5_BASELINE_END", "2020-12-31"))
BASELINE_PERIOD <- paste0(format(BASELINE_START, "%Y"), "-", format(BASELINE_END, "%Y"))
WINDOW_DAYS <- as.integer(Sys.getenv("ERA5_PERCENTILE_WINDOW_DAYS", "31"))
if (is.na(WINDOW_DAYS) || WINDOW_DAYS < 1) {
  WINDOW_DAYS <- 31L
}

DATASET <- Sys.getenv("ERA5_CDS_DATASET", "reanalysis-era5-land-timeseries")
VARIABLE <- Sys.getenv("ERA5_CDS_VARIABLE", "2m_temperature")
CDS_DATE_RANGE <- Sys.getenv(
  "ERA5_CDS_DATE_RANGE",
  paste0(format(BASELINE_START, "%Y-%m-%d"), "/", format(BASELINE_END, "%Y-%m-%d"))
)

RAW_DOWNLOAD_PATH <- file.path(
  CACHE_DIR,
  sprintf(
    "era5_land_matosinhos_hourly_temperature_%s_%s.zip",
    format(BASELINE_START, "%Y"),
    format(BASELINE_END, "%Y")
  )
)

DAILY_PATH <- file.path(DATA_DIR, "era5_matosinhos_daily_temperature_1991_2020.csv")
PERCENTILE_PATH <- file.path(DATA_DIR, "era5_matosinhos_temperature_percentiles.csv")
PERCENTILE_ALERTS_PATH <- file.path(
  DATA_DIR,
  "era5_matosinhos_temperature_percentile_alerts.csv"
)
PERCENTILE_ALERT_LATEST_PATH <- file.path(
  DATA_DIR,
  "era5_matosinhos_temperature_percentile_alert_latest.csv"
)

TEMPERATURE_PATH <- file.path(DATA_DIR, "ipma_matosinhos_temperaturas.csv")
FORECAST_LATEST_PATH <- file.path(DATA_DIR, "ipma_matosinhos_forecast_latest.csv")

DAILY_COLUMNS <- c(
  "date",
  "location",
  "district",
  "dico",
  "latitude",
  "longitude",
  "baseline_period",
  "tmin_c",
  "tmax_c",
  "tmean_c",
  "hourly_observations",
  "source",
  "source_file",
  "calculated_at"
)

PERCENTILE_COLUMNS <- c(
  "baseline_period",
  "location",
  "district",
  "dico",
  "latitude",
  "longitude",
  "window_days",
  "day_index",
  "month_day",
  "n_days",
  "tmin_p05_c",
  "tmin_p10_c",
  "tmin_p25_c",
  "tmin_p50_c",
  "tmin_p75_c",
  "tmin_p90_c",
  "tmin_p95_c",
  "tmin_p98_c",
  "tmin_p99_c",
  "tmax_p05_c",
  "tmax_p10_c",
  "tmax_p25_c",
  "tmax_p50_c",
  "tmax_p75_c",
  "tmax_p90_c",
  "tmax_p95_c",
  "tmax_p98_c",
  "tmax_p99_c",
  "source",
  "calculated_at"
)

ALERT_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "location",
  "district",
  "dico",
  "global_id_local",
  "target_date",
  "value_source_type",
  "value_source",
  "tmin_c",
  "tmin_p90_c",
  "tmin_p95_c",
  "tmin_p98_c",
  "tmin_alert",
  "tmin_alert_level",
  "tmax_c",
  "tmax_p90_c",
  "tmax_p95_c",
  "tmax_p98_c",
  "tmax_alert",
  "tmax_alert_level",
  "overall_percentile_alert",
  "overall_percentile_alert_level",
  "drivers",
  "source"
)

empty_frame <- function(columns) {
  out <- as.data.frame(
    matrix(character(), nrow = 0, ncol = length(columns)),
    stringsAsFactors = FALSE
  )
  names(out) <- columns
  out
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

has_value <- function(value) {
  !is.na(value) & nzchar(as.character(value))
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
  data[, columns, drop = FALSE]
}

python_available <- function() {
  python <- Sys.which("python3")
  if (!nzchar(python)) {
    python <- Sys.which("python")
  }
  nzchar(python)
}

cds_credentials_available <- function() {
  (has_value(Sys.getenv("CDSAPI_KEY")) && has_value(Sys.getenv("CDSAPI_URL"))) ||
    file.exists(path.expand("~/.cdsapirc"))
}

download_raw_era5 <- function(target_path = RAW_DOWNLOAD_PATH) {
  dir.create(dirname(target_path), recursive = TRUE, showWarnings = FALSE)

  if (file.exists(target_path) && file.info(target_path)$size > 0) {
    message("OK ERA5-Land raw cache already exists: ", target_path)
    return(target_path)
  }

  if (!python_available()) {
    message("SKIP ERA5-Land download - python3/python is not available.")
    return("")
  }

  if (!cds_credentials_available()) {
    message(
      "SKIP ERA5-Land download - define CDSAPI_URL/CDSAPI_KEY or ~/.cdsapirc."
    )
    return("")
  }

  python <- Sys.which("python3")
  if (!nzchar(python)) {
    python <- Sys.which("python")
  }

  py_file <- tempfile("download-era5-", fileext = ".py")
  on.exit(unlink(py_file), add = TRUE)

  python_code <- sprintf(
    paste(
      "import importlib.util",
      "import os",
      "import sys",
      "",
      "if importlib.util.find_spec('cdsapi') is None:",
      "    print('SKIP ERA5-Land download - python package cdsapi is not installed.')",
      "    sys.exit(3)",
      "",
      "import cdsapi",
      "",
      "dataset = %s",
      "target = %s",
      "request = {",
      "    'variable': [%s],",
      "    'date': %s,",
      "    'location': {'latitude': %.6f, 'longitude': %.6f},",
      "    'data_format': 'csv'",
      "}",
      "",
      "kwargs = {}",
      "if os.environ.get('CDSAPI_URL') and os.environ.get('CDSAPI_KEY'):",
      "    kwargs['url'] = os.environ['CDSAPI_URL']",
      "    kwargs['key'] = os.environ['CDSAPI_KEY']",
      "",
      "client = cdsapi.Client(**kwargs)",
      "try:",
      "    client.retrieve(dataset, request, target)",
      "except TypeError:",
      "    client.retrieve(dataset, request).download(target)",
      "",
      "print('OK ERA5-Land download:', target)",
      sep = "\n"
    ),
    shQuote(DATASET),
    shQuote(target_path),
    shQuote(VARIABLE),
    shQuote(CDS_DATE_RANGE),
    LATITUDE,
    LONGITUDE
  )

  writeLines(python_code, py_file, useBytes = TRUE)
  status <- system2(python, py_file)

  if (!identical(status, 0L)) {
    if (identical(status, 3L)) {
      return("")
    }
    stop("ERA5-Land download failed with exit code ", status, call. = FALSE)
  }

  if (!file.exists(target_path) || file.info(target_path)$size == 0) {
    stop("ERA5-Land download finished but target file is missing or empty.", call. = FALSE)
  }

  target_path
}

is_zip_file <- function(path) {
  if (!file.exists(path) || file.info(path)$size < 4) {
    return(FALSE)
  }
  magic <- readBin(path, what = "raw", n = 4)
  length(magic) >= 2 && identical(as.integer(magic[1:2]), c(0x50, 0x4b))
}

extract_csv_from_download <- function(path) {
  if (!file.exists(path)) {
    return("")
  }

  if (!is_zip_file(path)) {
    return(path)
  }

  extract_dir <- tempfile("era5-csv-")
  dir.create(extract_dir, recursive = TRUE, showWarnings = FALSE)
  files <- unzip(path, exdir = extract_dir)
  csv_files <- files[grepl("\\.csv$", files, ignore.case = TRUE)]
  if (length(csv_files) == 0) {
    stop("ERA5-Land archive does not contain a CSV file.", call. = FALSE)
  }

  csv_files[[1]]
}

parse_datetime_utc <- function(value) {
  value <- as.character(value)
  value[value == ""] <- NA_character_
  value <- sub("Z$", "", value)
  value <- sub("\\.[0-9]+$", "", value)

  formats <- c(
    "%Y-%m-%dT%H:%M:%S",
    "%Y-%m-%d %H:%M:%S",
    "%Y-%m-%dT%H:%M",
    "%Y-%m-%d %H:%M",
    "%Y-%m-%d"
  )

  parsed <- as.POSIXct(rep(NA_character_, length(value)), tz = "UTC")
  for (format_string in formats) {
    missing <- is.na(parsed) & !is.na(value)
    if (!any(missing)) {
      break
    }
    parsed[missing] <- as.POSIXct(value[missing], format = format_string, tz = "UTC")
  }

  parsed
}

find_time_column <- function(data) {
  names_lower <- tolower(names(data))
  candidates <- c("time", "valid_time", "datetime", "date")
  match <- match(candidates, names_lower)
  match <- match[!is.na(match)]
  if (length(match) > 0) {
    return(names(data)[[match[[1]]]])
  }

  time_like <- grep("time|date", names_lower)
  if (length(time_like) > 0) {
    return(names(data)[[time_like[[1]]]])
  }

  names(data)[[1]]
}

find_temperature_column <- function(data, time_column) {
  names_lower <- tolower(names(data))
  normalized <- gsub("[^a-z0-9]+", "_", names_lower)
  candidates <- c("2m_temperature", "t2m", "temperature", "tas")
  match <- match(candidates, normalized)
  match <- match[!is.na(match)]
  if (length(match) > 0) {
    return(names(data)[[match[[1]]]])
  }

  name_match <- grep("2m.*temperature|temperature|t2m", normalized)
  name_match <- setdiff(name_match, match(time_column, names(data)))
  if (length(name_match) > 0) {
    return(names(data)[[name_match[[1]]]])
  }

  numeric_candidates <- setdiff(seq_along(data), match(time_column, names(data)))
  numeric_scores <- vapply(numeric_candidates, function(index) {
    values <- suppressWarnings(as.numeric(data[[index]]))
    sum(!is.na(values))
  }, integer(1))

  numeric_candidates <- numeric_candidates[numeric_scores > 0]
  if (length(numeric_candidates) == 0) {
    stop("Could not identify ERA5-Land temperature column.", call. = FALSE)
  }

  names(data)[[numeric_candidates[[which.max(numeric_scores[numeric_scores > 0])]]]]
}

read_era5_hourly_csv <- function(path) {
  data <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  if (nrow(data) == 0) {
    stop("ERA5-Land CSV is empty.", call. = FALSE)
  }

  time_column <- find_time_column(data)
  temperature_column <- find_temperature_column(data, time_column)

  timestamps <- parse_datetime_utc(data[[time_column]])
  temperature <- to_num(data[[temperature_column]])
  median_temperature <- median(temperature, na.rm = TRUE)
  if (!is.na(median_temperature) && median_temperature > 100) {
    temperature <- temperature - 273.15
  }

  hourly <- data.frame(
    datetime_utc = timestamps,
    date_local = as.Date(format(timestamps, "%Y-%m-%d", tz = LOCAL_TZ)),
    temperature_c = temperature,
    stringsAsFactors = FALSE
  )

  hourly <- hourly[
    !is.na(hourly$datetime_utc) &
      !is.na(hourly$date_local) &
      !is.na(hourly$temperature_c),
    ,
    drop = FALSE
  ]

  hourly
}

build_daily_temperature <- function(hourly, source_file) {
  hourly <- hourly[
    hourly$date_local >= BASELINE_START & hourly$date_local <= BASELINE_END,
    ,
    drop = FALSE
  ]

  if (nrow(hourly) == 0) {
    stop("No ERA5-Land hourly rows remain inside the baseline period.", call. = FALSE)
  }

  dates <- sort(unique(hourly$date_local))
  rows <- lapply(dates, function(target_date) {
    values <- hourly$temperature_c[hourly$date_local == target_date]
    data.frame(
      date = as.character(target_date),
      location = LOCATION,
      district = DISTRICT,
      dico = DICO,
      latitude = LATITUDE,
      longitude = LONGITUDE,
      baseline_period = BASELINE_PERIOD,
      tmin_c = round(min(values, na.rm = TRUE), 3),
      tmax_c = round(max(values, na.rm = TRUE), 3),
      tmean_c = round(mean(values, na.rm = TRUE), 3),
      hourly_observations = length(values),
      source = paste0(
        "Copernicus CDS ERA5-Land hourly time-series ",
        VARIABLE,
        " nearest grid point"
      ),
      source_file = basename(source_file),
      calculated_at = utc_now(),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  select_columns(out, DAILY_COLUMNS)
}

leap_day_index <- function(date) {
  date <- as.Date(date)
  as.integer(as.Date(paste0("2020-", format(date, "%m-%d"))) - as.Date("2020-01-01")) + 1L
}

percentile_columns_for <- function(prefix) {
  paste0(prefix, "_p", c("05", "10", "25", "50", "75", "90", "95", "98", "99"), "_c")
}

quantile_values <- function(values) {
  probabilities <- c(0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.98, 0.99)
  if (all(is.na(values))) {
    return(rep(NA_real_, length(probabilities)))
  }
  round(as.numeric(quantile(values, probabilities, na.rm = TRUE, type = 8)), 3)
}

build_temperature_percentiles <- function(daily) {
  daily$date_as_date <- as.Date(daily$date)
  daily$day_index <- leap_day_index(daily$date_as_date)
  daily$tmin_numeric <- to_num(daily$tmin_c)
  daily$tmax_numeric <- to_num(daily$tmax_c)

  half_window <- floor(WINDOW_DAYS / 2)
  rows <- lapply(seq_len(366), function(day_index) {
    distance <- abs(daily$day_index - day_index)
    cyclic_distance <- pmin(distance, 366 - distance)
    window_rows <- daily[cyclic_distance <= half_window, , drop = FALSE]
    month_day <- format(as.Date("2020-01-01") + day_index - 1L, "%m-%d")

    values <- c(
      quantile_values(window_rows$tmin_numeric),
      quantile_values(window_rows$tmax_numeric)
    )
    names(values) <- c(
      percentile_columns_for("tmin"),
      percentile_columns_for("tmax")
    )

    data.frame(
      baseline_period = BASELINE_PERIOD,
      location = LOCATION,
      district = DISTRICT,
      dico = DICO,
      latitude = LATITUDE,
      longitude = LONGITUDE,
      window_days = WINDOW_DAYS,
      day_index = day_index,
      month_day = month_day,
      n_days = nrow(window_rows),
      as.list(values),
      source = paste0(
        "Copernicus CDS ERA5-Land hourly time-series ",
        VARIABLE,
        "; daily min/max in ",
        LOCAL_TZ,
        "; rolling day-of-year window"
      ),
      calculated_at = utc_now(),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })

  out <- do.call(rbind, rows)
  select_columns(out, PERCENTILE_COLUMNS)
}

build_climatology <- function(raw_path = RAW_DOWNLOAD_PATH) {
  if (!file.exists(raw_path)) {
    message("SKIP ERA5-Land climatology - raw download is not available.")
    return(FALSE)
  }

  csv_path <- extract_csv_from_download(raw_path)
  hourly <- read_era5_hourly_csv(csv_path)
  daily <- build_daily_temperature(hourly, csv_path)
  percentiles <- build_temperature_percentiles(daily)

  write_csv_file(daily, DAILY_PATH)
  write_csv_file(percentiles, PERCENTILE_PATH)

  message(sprintf(
    "OK ERA5-Land climatology - %d daily row(s), %d percentile row(s).",
    nrow(daily),
    nrow(percentiles)
  ))

  TRUE
}

alert_for_value <- function(value, p90, p95, p98) {
  value <- to_num(value)
  p90 <- to_num(p90)
  p95 <- to_num(p95)
  p98 <- to_num(p98)

  if (is.na(value) || is.na(p90) || is.na(p95) || is.na(p98)) {
    return(list(label = "Sem dados", level = -1L))
  }
  if (value >= p98) {
    return(list(label = "Vermelho", level = 3L))
  }
  if (value >= p95) {
    return(list(label = "Laranja", level = 2L))
  }
  if (value >= p90) {
    return(list(label = "Amarelo", level = 1L))
  }
  list(label = "Verde", level = 0L)
}

label_for_level <- function(level) {
  labels <- c(
    "-1" = "Sem dados",
    "0" = "Verde",
    "1" = "Amarelo",
    "2" = "Laranja",
    "3" = "Vermelho"
  )
  labels[[as.character(level)]]
}

driver_text <- function(metric, value, alert, p90, p95, p98) {
  if (is.na(alert$level) || alert$level <= 0) {
    return("")
  }

  threshold <- switch(
    as.character(alert$level),
    "1" = p90,
    "2" = p95,
    "3" = p98,
    NA_real_
  )
  percentile <- switch(
    as.character(alert$level),
    "1" = "P90",
    "2" = "P95",
    "3" = "P98",
    ""
  )

  if (is.na(threshold)) {
    return("")
  }

  sprintf("%s %.1f ºC >= %s %.1f ºC", metric, value, percentile, threshold)
}

build_observed_temperature_rows <- function() {
  observed <- read_character_csv(TEMPERATURE_PATH)
  if (nrow(observed) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  out <- data.frame(
    target_date = as.Date(observed$date),
    tmin_c = to_num(observed$tmin_c),
    tmax_c = to_num(observed$tmax_c),
    source_updated_at = if ("fetched_at" %in% names(observed)) observed$fetched_at else "",
    fetched_at = if ("fetched_at" %in% names(observed)) observed$fetched_at else "",
    value_source_type = "observed",
    value_source = if ("source" %in% names(observed)) observed$source else "IPMA observed temperature",
    stringsAsFactors = FALSE
  )
  out <- out[!is.na(out$target_date), , drop = FALSE]
  out[order(out$target_date, out$fetched_at), , drop = FALSE]
}

build_forecast_temperature_rows <- function() {
  forecasts <- read_character_csv(FORECAST_LATEST_PATH)
  if (nrow(forecasts) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  forecasts <- forecasts[
    forecasts$period_type == "daily" & has_value(forecasts$forecast_date),
    ,
    drop = FALSE
  ]
  if (nrow(forecasts) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  out <- data.frame(
    target_date = as.Date(forecasts$forecast_date),
    tmin_c = to_num(forecasts$tmin_c),
    tmax_c = to_num(forecasts$tmax_c),
    source_updated_at = forecasts$source_updated_at,
    fetched_at = forecasts$fetched_at,
    value_source_type = "forecast",
    value_source = forecasts$source,
    stringsAsFactors = FALSE
  )
  out <- out[!is.na(out$target_date), , drop = FALSE]
  out[order(out$target_date, out$fetched_at), , drop = FALSE]
}

build_current_temperature_rows <- function() {
  observed <- build_observed_temperature_rows()
  forecasts <- build_forecast_temperature_rows()

  if (nrow(observed) == 0 && nrow(forecasts) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  if (nrow(observed) == 0) {
    return(forecasts)
  }
  if (nrow(forecasts) == 0) {
    return(observed)
  }

  observed_dates <- observed$target_date
  forecasts <- forecasts[!forecasts$target_date %in% observed_dates, , drop = FALSE]
  out <- rbind(observed, forecasts)
  out[order(out$target_date), , drop = FALSE]
}

build_percentile_alerts <- function() {
  if (!file.exists(PERCENTILE_PATH)) {
    message("SKIP ERA5-Land percentile alerts - percentile file is not available.")
    return(FALSE)
  }

  percentiles <- read_character_csv(PERCENTILE_PATH)
  values <- build_current_temperature_rows()
  if (nrow(values) == 0) {
    write_csv_file(empty_frame(ALERT_COLUMNS), PERCENTILE_ALERTS_PATH)
    write_csv_file(empty_frame(ALERT_COLUMNS), PERCENTILE_ALERT_LATEST_PATH)
    message("SKIP ERA5-Land percentile alerts - no IPMA observed/forecast values.")
    return(FALSE)
  }

  percentile_by_day <- split(percentiles, as.integer(percentiles$day_index))
  rows <- lapply(seq_len(nrow(values)), function(index) {
    row <- values[index, , drop = FALSE]
    day_index <- leap_day_index(row$target_date)
    thresholds <- percentile_by_day[[as.character(day_index)]]
    if (is.null(thresholds) || nrow(thresholds) == 0) {
      thresholds <- as.list(rep(NA_character_, length(PERCENTILE_COLUMNS)))
      names(thresholds) <- PERCENTILE_COLUMNS
      thresholds <- as.data.frame(thresholds, stringsAsFactors = FALSE)
    }

    tmin_alert <- alert_for_value(
      row$tmin_c,
      thresholds$tmin_p90_c,
      thresholds$tmin_p95_c,
      thresholds$tmin_p98_c
    )
    tmax_alert <- alert_for_value(
      row$tmax_c,
      thresholds$tmax_p90_c,
      thresholds$tmax_p95_c,
      thresholds$tmax_p98_c
    )

    overall_level <- max(c(tmin_alert$level, tmax_alert$level), na.rm = TRUE)
    drivers <- c(
      driver_text(
        "Temperatura mínima",
        row$tmin_c,
        tmin_alert,
        to_num(thresholds$tmin_p90_c),
        to_num(thresholds$tmin_p95_c),
        to_num(thresholds$tmin_p98_c)
      ),
      driver_text(
        "Temperatura máxima",
        row$tmax_c,
        tmax_alert,
        to_num(thresholds$tmax_p90_c),
        to_num(thresholds$tmax_p95_c),
        to_num(thresholds$tmax_p98_c)
      )
    )
    drivers <- drivers[nzchar(drivers)]

    data.frame(
      source_updated_at = row$source_updated_at,
      fetched_at = row$fetched_at,
      location = LOCATION,
      district = DISTRICT,
      dico = DICO,
      global_id_local = GLOBAL_ID_LOCAL,
      target_date = as.character(row$target_date),
      value_source_type = row$value_source_type,
      value_source = row$value_source,
      tmin_c = round_num(row$tmin_c),
      tmin_p90_c = round_num(to_num(thresholds$tmin_p90_c)),
      tmin_p95_c = round_num(to_num(thresholds$tmin_p95_c)),
      tmin_p98_c = round_num(to_num(thresholds$tmin_p98_c)),
      tmin_alert = tmin_alert$label,
      tmin_alert_level = tmin_alert$level,
      tmax_c = round_num(row$tmax_c),
      tmax_p90_c = round_num(to_num(thresholds$tmax_p90_c)),
      tmax_p95_c = round_num(to_num(thresholds$tmax_p95_c)),
      tmax_p98_c = round_num(to_num(thresholds$tmax_p98_c)),
      tmax_alert = tmax_alert$label,
      tmax_alert_level = tmax_alert$level,
      overall_percentile_alert = label_for_level(overall_level),
      overall_percentile_alert_level = overall_level,
      drivers = paste(drivers, collapse = "; "),
      source = paste0(
        "IPMA observed/forecast temperatures compared with ERA5-Land ",
        BASELINE_PERIOD,
        " rolling day-of-year percentiles"
      ),
      stringsAsFactors = FALSE
    )
  })

  alerts <- do.call(rbind, rows)
  alerts <- select_columns(alerts, ALERT_COLUMNS)
  write_csv_file(alerts, PERCENTILE_ALERTS_PATH)

  forecast_rows <- alerts[alerts$value_source_type == "forecast", , drop = FALSE]
  if (nrow(forecast_rows) > 0) {
    horizon_start <- min(as.Date(forecast_rows$target_date), na.rm = TRUE)
    horizon_end <- max(as.Date(forecast_rows$target_date), na.rm = TRUE)
    latest <- alerts[
      as.Date(alerts$target_date) >= min(local_today(), horizon_start) &
        as.Date(alerts$target_date) <= horizon_end,
      ,
      drop = FALSE
    ]
  } else {
    latest_date <- max(as.Date(alerts$target_date), na.rm = TRUE)
    latest <- alerts[as.Date(alerts$target_date) == latest_date, , drop = FALSE]
  }
  latest <- select_columns(latest, ALERT_COLUMNS)
  write_csv_file(latest, PERCENTILE_ALERT_LATEST_PATH)

  message(sprintf(
    "OK ERA5-Land percentile alerts - %d row(s), %d latest row(s).",
    nrow(alerts),
    nrow(latest)
  ))

  TRUE
}

run_selftest <- function() {
  original_start <- BASELINE_START
  original_end <- BASELINE_END

  assign("BASELINE_START", as.Date("1991-01-01"), envir = .GlobalEnv)
  assign("BASELINE_END", as.Date("1993-12-31"), envir = .GlobalEnv)
  assign("BASELINE_PERIOD", "1991-1993", envir = .GlobalEnv)

  times <- seq(
    as.POSIXct("1991-01-01 00:00:00", tz = "UTC"),
    as.POSIXct("1993-12-31 23:00:00", tz = "UTC"),
    by = "hour"
  )
  local_dates <- as.Date(format(times, "%Y-%m-%d", tz = LOCAL_TZ))
  doy <- leap_day_index(local_dates)
  hour <- as.integer(format(times, "%H", tz = "UTC"))
  temp_k <- 285.15 +
    9 * sin(2 * pi * (doy - 80) / 366) +
    3 * sin(2 * pi * (hour - 6) / 24)

  raw <- data.frame(
    time = format(times, "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
    temperature = round(temp_k, 3),
    stringsAsFactors = FALSE
  )
  names(raw) <- c("time", "2m_temperature")

  temp_csv <- tempfile("era5-selftest-", fileext = ".csv")
  write.csv(raw, temp_csv, row.names = FALSE)

  hourly <- read_era5_hourly_csv(temp_csv)
  daily <- build_daily_temperature(hourly, temp_csv)
  percentiles <- build_temperature_percentiles(daily)

  stopifnot(nrow(daily) >= 1095)
  stopifnot(nrow(percentiles) == 366)
  stopifnot(all(to_num(percentiles$tmax_p90_c) >= to_num(percentiles$tmax_p50_c)))
  stopifnot(all(to_num(percentiles$tmin_p90_c) >= to_num(percentiles$tmin_p50_c)))

  assign("BASELINE_START", original_start, envir = .GlobalEnv)
  assign("BASELINE_END", original_end, envir = .GlobalEnv)
  assign("BASELINE_PERIOD", paste0(format(original_start, "%Y"), "-", format(original_end, "%Y")), envir = .GlobalEnv)

  unlink(temp_csv)
  message(sprintf(
    "OK ERA5-Land selftest - %d daily row(s), %d percentile row(s).",
    nrow(daily),
    nrow(percentiles)
  ))
}

dir.create(DATA_DIR, recursive = TRUE, showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args) >= 1 && nzchar(args[[1]])) {
  tolower(args[[1]])
} else {
  "alerts"
}

valid_modes <- c("all", "download", "build", "alerts", "selftest")
if (!mode %in% valid_modes) {
  stop(
    "Unknown mode: ",
    mode,
    ". Use one of: ",
    paste(valid_modes, collapse = ", "),
    call. = FALSE
  )
}

result <- if (mode == "selftest") {
  run_selftest()
} else if (mode == "download") {
  download_raw_era5()
} else if (mode == "build") {
  build_climatology()
} else if (mode == "alerts") {
  build_percentile_alerts()
} else if (mode == "all") {
  raw_path <- download_raw_era5()
  if (nzchar(raw_path)) {
    build_climatology(raw_path)
  }
  if (file.exists(PERCENTILE_PATH)) {
    build_percentile_alerts()
  } else {
    message(
      "SKIP ERA5-Land percentile alerts - climatology was not built in this run."
    )
    FALSE
  }
}

invisible(result)
