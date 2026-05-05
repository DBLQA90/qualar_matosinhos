library(httr)
library(jsonlite)
library(dplyr)
library(readr)

CSV_PATH <- "qualar_matosinhos.csv"
QUALAR_URL <- "https://qualar.apambiente.pt/api/app.php"
QUALAR_KEY <- "s7GmWp8U"

LOCATION <- "Matosinhos, Porto, Portugal"
LATITUDE <- "41.1821"
LONGITUDE <- "-8.6891"

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
  "fetched_at"
)

KEY_COLUMNS <- c("location", "latitude", "longitude", "forecast_date")
COMPARE_COLUMNS <- setdiff(CSV_COLUMNS, "fetched_at")

empty_csv <- function() {
  out <- as.data.frame(
    matrix(character(), nrow = 0, ncol = length(CSV_COLUMNS)),
    stringsAsFactors = FALSE
  )
  names(out) <- CSV_COLUMNS
  out
}

as_text <- function(x) {
  if (length(x) == 0 || is.null(x) || is.na(x)) {
    return("")
  }
  as.character(x)
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
    message("Existing CSV uses the old schema; replacing it with prediction API rows.")
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
      as_text(existing_row[[column]][1]),
      as_text(new_row[[column]][1])
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

fetched_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
api_data <- fetch_prediction()
new_data <- bind_rows(lapply(api_data, flatten_prediction, fetched_at = fetched_at))
new_data <- as.data.frame(new_data[, CSV_COLUMNS], stringsAsFactors = FALSE)
new_data[] <- lapply(new_data, as.character)

existing <- read_existing(CSV_PATH)
combined <- upsert_predictions(existing, new_data)
write_csv(combined, CSV_PATH, na = "")

message(sprintf(
  "OK - %d forecast row(s) fetched; CSV now has %d row(s).",
  nrow(new_data),
  nrow(combined)
))
