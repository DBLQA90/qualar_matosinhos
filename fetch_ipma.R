library(httr)
library(jsonlite)
library(dplyr)
library(readr)

DATA_DIR <- "data"
TEMPERATURE_PATH <- file.path(DATA_DIR, "ipma_matosinhos_temperaturas.csv")
FORECAST_PATH <- file.path(DATA_DIR, "ipma_matosinhos_forecasts.csv")
FORECAST_LATEST_PATH <- file.path(DATA_DIR, "ipma_matosinhos_forecast_latest.csv")

LOCAL_TZ <- "Europe/Lisbon"
FETCHED_AT <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

LOCATION <- "Matosinhos"
DISTRICT <- "Porto"
DICO <- "1308"
GLOBAL_ID_LOCAL <- "1130800"
LATITUDE <- "41.1805"
LONGITUDE <- "-8.6810"

IPMA_BASE <- "https://api.ipma.pt"
TMIN_URL <- paste0(
  IPMA_BASE,
  "/open-data/observation/climate/temperature-min/porto/mtnmn-1308-matosinhos.csv"
)
TMAX_URL <- paste0(
  IPMA_BASE,
  "/open-data/observation/climate/temperature-max/porto/mtxmx-1308-matosinhos.csv"
)
FORECAST_URL <- paste0(IPMA_BASE, "/public-data/forecast/aggregate/1130800.json")

TEMPERATURE_COLUMNS <- c(
  "date",
  "location",
  "district",
  "dico",
  "tmean_estimated_c",
  "tmin_c",
  "tmax_c",
  "tmin_concelho_min_c",
  "tmin_concelho_max_c",
  "tmax_concelho_min_c",
  "tmax_concelho_max_c",
  "source",
  "fetched_at"
)

FORECAST_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "location",
  "district",
  "global_id_local",
  "latitude",
  "longitude",
  "forecast_datetime_utc",
  "forecast_date",
  "period_hours",
  "period_type",
  "intervalo_hora",
  "weather_type_id",
  "precipitation_intensity_id",
  "precipitation_probability_percent",
  "tmed_c",
  "tmin_c",
  "tmax_c",
  "humidity_percent",
  "utci_c",
  "wind_speed_kmh",
  "wind_speed_class_id",
  "wind_direction",
  "uv_index",
  "source"
)

TEMPERATURE_KEY_COLUMNS <- "date"
FORECAST_KEY_COLUMNS <- c(
  "source_updated_at",
  "global_id_local",
  "forecast_datetime_utc",
  "period_hours"
)

as_text <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return("")
  }

  value <- x[[1]]
  if (is.na(value)) {
    return("")
  }

  as.character(value)
}

field_text <- function(item, field) {
  if (!field %in% names(item)) {
    return("")
  }

  value <- as_text(item[[field]])
  if (value %in% c("-99", "-99.0", "-99.00")) {
    return("")
  }

  value
}

to_num <- function(x) {
  suppressWarnings(as.numeric(x))
}

round_value <- function(x, digits = 3) {
  value <- to_num(x)
  ifelse(is.na(value), NA_real_, round(value, digits))
}

empty_frame <- function(columns) {
  out <- as.data.frame(
    matrix(character(), nrow = 0, ncol = length(columns)),
    stringsAsFactors = FALSE
  )
  names(out) <- columns
  out
}

fetch_text <- function(url) {
  response <- GET(
    url,
    user_agent("qualar-matosinhos/1.0"),
    timeout(30)
  )
  stop_for_status(response)
  content(response, as = "text", encoding = "UTF-8")
}

fetch_csv <- function(url) {
  read_csv(
    I(fetch_text(url)),
    show_col_types = FALSE,
    col_types = cols(.default = "c")
  )
}

fetch_json <- function(url) {
  parsed <- fromJSON(fetch_text(url), simplifyVector = FALSE)
  if (length(parsed) == 0) {
    stop("IPMA returned no data for: ", url)
  }
  parsed
}

read_existing <- function(path, columns) {
  if (!file.exists(path)) {
    return(empty_frame(columns))
  }

  existing <- read_csv(
    path,
    show_col_types = FALSE,
    col_types = cols(.default = "c")
  )

  missing_columns <- setdiff(columns, names(existing))
  if (length(missing_columns) > 0) {
    message(
      "Existing file has an older schema; rebuilding ",
      path,
      " from current IPMA data."
    )
    return(empty_frame(columns))
  }

  existing <- as.data.frame(existing[, columns], stringsAsFactors = FALSE)
  existing[] <- lapply(existing, as.character)
  existing
}

same_values <- function(existing_row, new_row, compare_columns) {
  all(vapply(
    compare_columns,
    function(column) identical(
      as_text(existing_row[[column]]),
      as_text(new_row[[column]])
    ),
    logical(1)
  ))
}

same_key <- function(existing, new_row, key_columns) {
  matches <- rep(TRUE, nrow(existing))
  for (column in key_columns) {
    matches <- matches & existing[[column]] == new_row[[column]][1]
  }
  matches
}

upsert_rows <- function(existing, new_rows, columns, key_columns, compare_columns) {
  combined <- existing

  for (i in seq_len(nrow(new_rows))) {
    new_row <- new_rows[i, , drop = FALSE]
    matches <- if (nrow(combined) == 0) {
      logical()
    } else {
      same_key(combined, new_row, key_columns)
    }
    match_index <- which(matches)

    if (length(match_index) > 0 &&
        same_values(combined[match_index[1], , drop = FALSE], new_row, compare_columns)) {
      next
    }

    if (length(match_index) > 0) {
      combined <- combined[-match_index, , drop = FALSE]
    }

    combined <- bind_rows(combined, new_row)
  }

  combined[, columns]
}

build_temperature_history <- function() {
  tmin <- fetch_csv(TMIN_URL)
  tmax <- fetch_csv(TMAX_URL)

  tmin_daily <- tmin %>%
    transmute(
      date = as.character(date),
      tmin_c = round_value(mean),
      tmin_concelho_min_c = round_value(minimum),
      tmin_concelho_max_c = round_value(maximum)
    )

  tmax_daily <- tmax %>%
    transmute(
      date = as.character(date),
      tmax_c = round_value(mean),
      tmax_concelho_min_c = round_value(minimum),
      tmax_concelho_max_c = round_value(maximum)
    )

  output <- full_join(tmin_daily, tmax_daily, by = "date") %>%
    mutate(
      location = LOCATION,
      district = DISTRICT,
      dico = DICO,
      tmean_estimated_c = round((tmin_c + tmax_c) / 2, 3),
      source = paste(
        "IPMA open-data observation/climate temperature-min",
        "and temperature-max by municipality"
      ),
      fetched_at = FETCHED_AT
    ) %>%
    arrange(date) %>%
    select(all_of(TEMPERATURE_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)

  output[] <- lapply(output, as.character)
  output
}

period_type <- function(period_hours) {
  switch(
    as.character(period_hours),
    "1" = "hourly",
    "3" = "three_hourly",
    "24" = "daily",
    "other"
  )
}

forecast_date <- function(forecast_datetime) {
  if (forecast_datetime == "") {
    return("")
  }

  substr(forecast_datetime, 1, 10)
}

flatten_forecast <- function(item) {
  period_hours <- field_text(item, "idPeriodo")
  data.frame(
    source_updated_at = field_text(item, "dataUpdate"),
    fetched_at = FETCHED_AT,
    location = LOCATION,
    district = DISTRICT,
    global_id_local = GLOBAL_ID_LOCAL,
    latitude = LATITUDE,
    longitude = LONGITUDE,
    forecast_datetime_utc = field_text(item, "dataPrev"),
    forecast_date = forecast_date(field_text(item, "dataPrev")),
    period_hours = period_hours,
    period_type = period_type(period_hours),
    intervalo_hora = field_text(item, "intervaloHora"),
    weather_type_id = field_text(item, "idTipoTempo"),
    precipitation_intensity_id = field_text(item, "idIntensidadePrecipita"),
    precipitation_probability_percent = field_text(item, "probabilidadePrecipita"),
    tmed_c = field_text(item, "tMed"),
    tmin_c = field_text(item, "tMin"),
    tmax_c = field_text(item, "tMax"),
    humidity_percent = field_text(item, "hR"),
    utci_c = field_text(item, "utci"),
    wind_speed_kmh = field_text(item, "ffVento"),
    wind_speed_class_id = field_text(item, "idFfxVento"),
    wind_direction = field_text(item, "ddVento"),
    uv_index = field_text(item, "iUv"),
    source = "IPMA public-data forecast aggregate by local",
    stringsAsFactors = FALSE
  )
}

build_forecasts <- function() {
  api_data <- fetch_json(FORECAST_URL)
  forecasts <- bind_rows(lapply(api_data, flatten_forecast))
  forecasts[] <- lapply(forecasts, as.character)

  forecasts %>%
    arrange(source_updated_at, forecast_datetime_utc, period_hours) %>%
    select(all_of(FORECAST_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

write_temperature_history <- function(new_data) {
  existing <- read_existing(TEMPERATURE_PATH, TEMPERATURE_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    TEMPERATURE_COLUMNS,
    TEMPERATURE_KEY_COLUMNS,
    setdiff(TEMPERATURE_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(date) %>%
    distinct(across(all_of(TEMPERATURE_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, TEMPERATURE_PATH, na = "")
  combined
}

write_forecasts <- function(new_data) {
  existing <- read_existing(FORECAST_PATH, FORECAST_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    FORECAST_COLUMNS,
    FORECAST_KEY_COLUMNS,
    setdiff(FORECAST_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(source_updated_at, forecast_datetime_utc, period_hours) %>%
    distinct(across(all_of(FORECAST_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, FORECAST_PATH, na = "")

  latest_source_update <- max(combined$source_updated_at, na.rm = TRUE)
  latest <- combined[combined$source_updated_at == latest_source_update, , drop = FALSE]
  write_csv(latest, FORECAST_LATEST_PATH, na = "")

  list(combined = combined, latest = latest)
}

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

temperature_data <- build_temperature_history()
temperature_history <- write_temperature_history(temperature_data)

forecast_data <- build_forecasts()
forecast_result <- write_forecasts(forecast_data)

message(sprintf(
  paste(
    "OK - %d temperature row(s) fetched; temperature history has %d row(s).",
    "%d forecast row(s) fetched; forecast archive has %d row(s); latest snapshot has %d row(s)."
  ),
  nrow(temperature_data),
  nrow(temperature_history),
  nrow(forecast_data),
  nrow(forecast_result$combined),
  nrow(forecast_result$latest)
))
