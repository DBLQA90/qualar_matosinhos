library(httr)
library(jsonlite)
library(dplyr)
library(readr)

DATA_DIR <- "data"
TEMPERATURE_PATH <- file.path(DATA_DIR, "ipma_matosinhos_temperaturas.csv")
FORECAST_PATH <- file.path(DATA_DIR, "ipma_matosinhos_forecasts.csv")
FORECAST_LATEST_PATH <- file.path(DATA_DIR, "ipma_matosinhos_forecast_latest.csv")
STATION_OBSERVATIONS_PATH <- file.path(
  DATA_DIR,
  "ipma_matosinhos_station_observations.csv"
)
STATION_DAILY_TEMPERATURES_PATH <- file.path(
  DATA_DIR,
  "ipma_matosinhos_station_daily_temperatures.csv"
)
TEMPERATURE_ALERTS_PATH <- file.path(DATA_DIR, "ipma_matosinhos_temperature_alerts.csv")
TEMPERATURE_ALERTS_LATEST_PATH <- file.path(
  DATA_DIR,
  "ipma_matosinhos_temperature_alert_latest.csv"
)
UV_INDEX_PATH <- file.path(DATA_DIR, "ipma_matosinhos_uv_index.csv")
UV_INDEX_LATEST_PATH <- file.path(DATA_DIR, "ipma_matosinhos_uv_index_latest.csv")
DAILY_DIR <- "daily"

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
STATION_OBSERVATIONS_URL <- paste0(
  IPMA_BASE,
  "/open-data/observation/meteorology/stations/observations.json"
)

FALLBACK_STATIONS <- data.frame(
  station_id = c("1200545", "1210649"),
  station_name = c("Porto, Pedras Rubras", "S. Gens"),
  stringsAsFactors = FALSE
)

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

STATION_OBSERVATION_COLUMNS <- c(
  "datetime_utc",
  "datetime_local",
  "date_local",
  "station_id",
  "station_name",
  "temperature_c",
  "source",
  "fetched_at"
)

STATION_DAILY_TEMPERATURE_COLUMNS <- c(
  "date",
  "location",
  "district",
  "station_count",
  "station_ids",
  "station_names",
  "tmin_c",
  "tmax_c",
  "min_hourly_observations",
  "source",
  "fetched_at"
)

TEMPERATURE_ALERT_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "location",
  "district",
  "dico",
  "global_id_local",
  "target_date",
  "season_rule",
  "tmax_alert",
  "tmax_alert_level",
  "tmax_yellow_threshold_c",
  "tmax_red_threshold_c",
  "tmax_observed_d_minus_3_c",
  "tmax_observed_d_minus_2_c",
  "tmax_observed_d_minus_1_c",
  "tmax_forecast_d0_c",
  "tmax_forecast_d_plus_1_c",
  "tmin_alert",
  "tmin_alert_level",
  "tmin_yellow_threshold_c",
  "tmin_red_threshold_c",
  "tmin_observed_d_minus_2_c",
  "tmin_observed_d_minus_1_c",
  "tmin_forecast_d0_c",
  "tmin_forecast_d_plus_1_c",
  "overall_temperature_alert",
  "overall_temperature_alert_level",
  "missing_inputs",
  "recommendation_summary",
  "source"
)

UV_INDEX_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "location",
  "district",
  "global_id_local",
  "target_date",
  "uv_index",
  "uv_level",
  "uv_level_order",
  "uv_color",
  "protection_required",
  "recommendation_summary",
  "source"
)

TEMPERATURE_KEY_COLUMNS <- "date"
FORECAST_KEY_COLUMNS <- c(
  "source_updated_at",
  "global_id_local",
  "forecast_datetime_utc",
  "period_hours"
)
STATION_OBSERVATION_KEY_COLUMNS <- c("datetime_utc", "station_id")
STATION_DAILY_TEMPERATURE_KEY_COLUMNS <- "date"
TEMPERATURE_ALERT_KEY_COLUMNS <- c("source_updated_at", "target_date")
UV_INDEX_KEY_COLUMNS <- c("source_updated_at", "target_date")

HEAT_LEVELS <- c(
  "Fora de época" = -2,
  "Sem dados" = -1,
  "Verde" = 0,
  "Amarelo" = 1,
  "Vermelho" = 3
)

HEAT_SOURCE_LINKS <- c(
  "- IPMA, API de dados meteorológicos: https://api.ipma.pt/",
  "- DGS, recomendações para ondas de calor: https://www.dgs.pt/saude-ambiental-calor/recomendacoes.aspx",
  "- DGS, temperaturas elevadas - recomendações: https://www.dgs.pt/em-destaque/temperaturas-elevadas-recomendacoes-da-dgs.aspx",
  "- SNS/DGS/INSA, recomendações contra o calor: https://www.sns.min-saude.pt/comunicado-conjunto-aumento-da-temperatura-recomendacoes-contra-o-calor/"
)

UV_LEVELS <- c(
  "Sem dados" = -1,
  "Baixo" = 0,
  "Moderado" = 1,
  "Alto" = 2,
  "Muito Alto" = 3,
  "Extremo" = 4
)

UV_SOURCE_LINKS <- c(
  "- IPMA, Índice Ultravioleta e classes IUV: https://www.ipma.pt/pt/enciclopedia/amb.atmosfera/uv/index.html",
  "- IPMA, previsão do Índice Ultravioleta: https://www.ipma.pt/pt/otempo/prev.uv/",
  "- OMS, índice UV e recomendações de proteção: https://www.who.int/news-room/questions-and-answers/item/radiation-the-ultraviolet-%28uv%29-index",
  "- OMS, radiação ultravioleta e proteção: https://www.who.int/news-room/fact-sheets/detail/ultraviolet-radiation",
  "- EPA, escala do Índice UV conforme orientações internacionais: https://www.epa.gov/sunsafety/uv-index-scale-0"
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
      "Existing file has an older schema; adding missing columns to ",
      path,
      "."
    )
    for (column in missing_columns) {
      existing[[column]] <- ""
    }
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

parse_ipma_datetime <- function(value) {
  value <- sub("Z$", "", value)
  format <- ifelse(grepl(":\\d{2}:\\d{2}$", value), "%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M")
  as.POSIXct(value, format = format, tz = "UTC")
}

station_name <- function(station_id) {
  match <- FALLBACK_STATIONS$station_name[FALLBACK_STATIONS$station_id == station_id]
  if (length(match) == 0) {
    return("")
  }

  match[[1]]
}

flatten_station_observations <- function(api_data) {
  rows <- list()

  for (datetime_text in names(api_data)) {
    timestamp <- parse_ipma_datetime(datetime_text)
    if (is.na(timestamp)) {
      next
    }

    datetime_utc <- format(timestamp, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    datetime_local <- format(timestamp, "%Y-%m-%dT%H:%M:%S%z", tz = LOCAL_TZ)
    date_local <- format(timestamp, "%Y-%m-%d", tz = LOCAL_TZ)

    for (station_id in FALLBACK_STATIONS$station_id) {
      if (!station_id %in% names(api_data[[datetime_text]])) {
        next
      }

      observation <- api_data[[datetime_text]][[station_id]]
      temperature <- field_text(observation, "temperatura")
      if (temperature == "") {
        next
      }

      rows[[length(rows) + 1]] <- data.frame(
        datetime_utc = datetime_utc,
        datetime_local = datetime_local,
        date_local = date_local,
        station_id = station_id,
        station_name = station_name(station_id),
        temperature_c = temperature,
        source = "IPMA station hourly observations",
        fetched_at = FETCHED_AT,
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(rows) == 0) {
    return(empty_frame(STATION_OBSERVATION_COLUMNS))
  }

  observations <- bind_rows(rows)
  observations[] <- lapply(observations, as.character)
  observations[, STATION_OBSERVATION_COLUMNS]
}

build_station_observations <- function() {
  flatten_station_observations(fetch_json(STATION_OBSERVATIONS_URL))
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

write_station_observations <- function(new_data) {
  existing <- read_existing(STATION_OBSERVATIONS_PATH, STATION_OBSERVATION_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    STATION_OBSERVATION_COLUMNS,
    STATION_OBSERVATION_KEY_COLUMNS,
    setdiff(STATION_OBSERVATION_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(datetime_utc, station_id) %>%
    distinct(across(all_of(STATION_OBSERVATION_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, STATION_OBSERVATIONS_PATH, na = "")
  combined
}

build_station_daily_temperatures <- function(station_observations) {
  if (nrow(station_observations) == 0) {
    return(empty_frame(STATION_DAILY_TEMPERATURE_COLUMNS))
  }

  today <- as.Date(format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ))

  station_daily <- station_observations %>%
    mutate(
      date = as.character(date_local),
      temperature_num = to_num(temperature_c)
    ) %>%
    filter(!is.na(temperature_num), as.Date(date) < today) %>%
    group_by(date, station_id, station_name) %>%
    summarise(
      station_tmin_c = min(temperature_num, na.rm = TRUE),
      station_tmax_c = max(temperature_num, na.rm = TRUE),
      hourly_observations = n(),
      .groups = "drop"
    )

  if (nrow(station_daily) == 0) {
    return(empty_frame(STATION_DAILY_TEMPERATURE_COLUMNS))
  }

  daily <- station_daily %>%
    group_by(date) %>%
    summarise(
      location = LOCATION,
      district = DISTRICT,
      station_count = n_distinct(station_id),
      station_ids = paste(sort(unique(station_id)), collapse = ";"),
      station_names = paste(sort(unique(station_name)), collapse = "; "),
      tmin_c = round(mean(station_tmin_c, na.rm = TRUE), 3),
      tmax_c = round(mean(station_tmax_c, na.rm = TRUE), 3),
      min_hourly_observations = min(hourly_observations, na.rm = TRUE),
      source = "IPMA station fallback: daily mean of Pedras Rubras and S. Gens station extrema",
      fetched_at = FETCHED_AT,
      .groups = "drop"
    ) %>%
    arrange(date) %>%
    select(all_of(STATION_DAILY_TEMPERATURE_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)

  daily[] <- lapply(daily, as.character)
  daily
}

write_station_daily_temperatures <- function(new_data) {
  existing <- read_existing(STATION_DAILY_TEMPERATURES_PATH, STATION_DAILY_TEMPERATURE_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    STATION_DAILY_TEMPERATURE_COLUMNS,
    STATION_DAILY_TEMPERATURE_KEY_COLUMNS,
    setdiff(STATION_DAILY_TEMPERATURE_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(date) %>%
    distinct(across(all_of(STATION_DAILY_TEMPERATURE_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, STATION_DAILY_TEMPERATURES_PATH, na = "")
  combined
}

is_blank <- function(value) {
  value <- as_text(value)
  value == "" || is.na(to_num(value))
}

recalculate_tmean <- function(row) {
  tmin <- to_num(row$tmin_c)
  tmax <- to_num(row$tmax_c)
  if (is.na(tmin) || is.na(tmax)) {
    return("")
  }

  as.character(round((tmin + tmax) / 2, 3))
}

station_daily_as_temperature_rows <- function(station_daily) {
  if (nrow(station_daily) == 0) {
    return(empty_frame(TEMPERATURE_COLUMNS))
  }

  rows <- station_daily %>%
    transmute(
      date = as.character(date),
      location = LOCATION,
      district = DISTRICT,
      dico = DICO,
      tmean_estimated_c = as.character(round((to_num(tmin_c) + to_num(tmax_c)) / 2, 3)),
      tmin_c = as.character(round(to_num(tmin_c), 3)),
      tmax_c = as.character(round(to_num(tmax_c), 3)),
      tmin_concelho_min_c = "",
      tmin_concelho_max_c = "",
      tmax_concelho_min_c = "",
      tmax_concelho_max_c = "",
      source = paste0(
        source,
        " (station_count=",
        station_count,
        "; station_names=",
        station_names,
        ")"
      ),
      fetched_at = FETCHED_AT
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)

  rows[] <- lapply(rows, as.character)
  rows[, TEMPERATURE_COLUMNS]
}

apply_station_temperature_fallback <- function(climate_data, station_daily) {
  fallback_rows <- station_daily_as_temperature_rows(station_daily)
  combined <- climate_data

  for (i in seq_len(nrow(fallback_rows))) {
    fallback <- fallback_rows[i, , drop = FALSE]
    match_index <- which(combined$date == fallback$date[1])

    if (length(match_index) == 0) {
      combined <- bind_rows(combined, fallback)
      next
    }

    index <- match_index[1]
    used_fallback <- FALSE

    if (is_blank(combined$tmin_c[index]) && !is_blank(fallback$tmin_c[1])) {
      combined$tmin_c[index] <- fallback$tmin_c[1]
      used_fallback <- TRUE
    }

    if (is_blank(combined$tmax_c[index]) && !is_blank(fallback$tmax_c[1])) {
      combined$tmax_c[index] <- fallback$tmax_c[1]
      used_fallback <- TRUE
    }

    if (used_fallback) {
      combined$tmean_estimated_c[index] <- recalculate_tmean(combined[index, , drop = FALSE])
      combined$source[index] <- paste(combined$source[index], fallback$source[1], sep = "; ")
    }
  }

  combined %>%
    arrange(date) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

latest_source_update <- function(data) {
  valid <- data$source_updated_at[data$source_updated_at != ""]
  if (length(valid) == 0) {
    return("")
  }

  max(valid, na.rm = TRUE)
}

daily_forecast_rows <- function(forecasts) {
  forecasts %>%
    filter(period_hours == "24") %>%
    arrange(forecast_date) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

value_for_date <- function(data, date, column) {
  match <- data[data$date == as.character(date), , drop = FALSE]
  if (nrow(match) == 0 || !column %in% names(match)) {
    return(NA_real_)
  }

  value <- to_num(match[[column]][1])
  ifelse(is.na(value), NA_real_, value)
}

forecast_value_for_date <- function(daily_forecasts, date, column) {
  match <- daily_forecasts[daily_forecasts$forecast_date == as.character(date), , drop = FALSE]
  if (nrow(match) == 0 || !column %in% names(match)) {
    return(NA_real_)
  }

  value <- to_num(match[[column]][1])
  ifelse(is.na(value), NA_real_, value)
}

has_missing <- function(values) {
  any(is.na(unlist(values, use.names = FALSE)))
}

alert_level <- function(label) {
  if (!label %in% names(HEAT_LEVELS)) {
    return("")
  }

  as.character(HEAT_LEVELS[[label]])
}

season_thresholds <- function(target_date, kind) {
  month_value <- as.integer(format(as.Date(target_date), "%m"))
  applicable <- month_value >= 5 && month_value <= 10
  warm_rule <- month_value >= 7 && month_value <= 10

  if (!applicable) {
    return(list(
      applicable = FALSE,
      rule = "fora de epoca DSP",
      thresholds = c(yellow = NA_real_, red = NA_real_)
    ))
  }

  if (kind == "max") {
    thresholds <- if (warm_rule) {
      c(yellow = 33, red = 35)
    } else {
      c(yellow = 32, red = 34)
    }
  } else {
    thresholds <- if (warm_rule) {
      c(yellow = 22, red = 25)
    } else {
      c(yellow = 21, red = 24)
    }
  }

  list(
    applicable = TRUE,
    rule = ifelse(
      warm_rule,
      "mes 7-10",
      "mes 5-6"
    ),
    thresholds = thresholds
  )
}

classify_tmax_alert <- function(target_date, obs_m3, obs_m2, obs_m1, forecast_d0, forecast_p1) {
  season <- season_thresholds(target_date, "max")
  thresholds <- season$thresholds
  values <- c(obs_m3, obs_m2, obs_m1, forecast_d0, forecast_p1)

  if (!season$applicable) {
    return(list(
      alert = "Fora de época",
      level = alert_level("Fora de época"),
      yellow = "",
      red = ""
    ))
  }

  if (has_missing(values)) {
    return(list(
      alert = "Sem dados",
      level = alert_level("Sem dados"),
      yellow = thresholds[["yellow"]],
      red = thresholds[["red"]]
    ))
  }

  alert <- if (all(values >= thresholds[["red"]])) {
    "Vermelho"
  } else if (all(c(obs_m1, forecast_d0, forecast_p1) >= thresholds[["yellow"]])) {
    "Amarelo"
  } else {
    "Verde"
  }

  list(
    alert = alert,
    level = alert_level(alert),
    yellow = thresholds[["yellow"]],
    red = thresholds[["red"]]
  )
}

classify_tmin_alert <- function(target_date, obs_m2, obs_m1, forecast_d0, forecast_p1) {
  season <- season_thresholds(target_date, "min")
  thresholds <- season$thresholds
  values <- c(obs_m2, obs_m1, forecast_d0, forecast_p1)

  if (!season$applicable) {
    return(list(
      alert = "Fora de época",
      level = alert_level("Fora de época"),
      yellow = "",
      red = ""
    ))
  }

  if (has_missing(values)) {
    return(list(
      alert = "Sem dados",
      level = alert_level("Sem dados"),
      yellow = thresholds[["yellow"]],
      red = thresholds[["red"]]
    ))
  }

  alert <- if (all(values >= thresholds[["red"]])) {
    "Vermelho"
  } else if (all(values >= thresholds[["yellow"]])) {
    "Amarelo"
  } else {
    "Verde"
  }

  list(
    alert = alert,
    level = alert_level(alert),
    yellow = thresholds[["yellow"]],
    red = thresholds[["red"]]
  )
}

overall_heat_alert <- function(tmax_alert, tmin_alert) {
  levels <- c(to_num(alert_level(tmax_alert)), to_num(alert_level(tmin_alert)))
  if (all(levels == to_num(alert_level("Fora de época")))) {
    return("Fora de época")
  }

  if (all(levels < 0)) {
    return("Sem dados")
  }

  max_level <- max(levels, na.rm = TRUE)
  names(HEAT_LEVELS)[HEAT_LEVELS == max_level][1]
}

format_temp <- function(value) {
  if (is.na(value)) {
    return("")
  }

  as.character(round(value, 1))
}

display_temp <- function(value) {
  value <- as_text(value)
  if (value == "") {
    return("sem dados")
  }

  value
}

threshold_pair_text <- function(yellow, red) {
  yellow <- as_text(yellow)
  red <- as_text(red)

  if (yellow == "" || red == "") {
    return("não aplicáveis")
  }

  paste0(yellow, "/", red, " ºC")
}

missing_inputs_text <- function(values) {
  missing <- names(values)[is.na(unlist(values, use.names = FALSE))]
  if (length(missing) == 0) {
    return("")
  }

  paste(missing, collapse = "; ")
}

recommendation_summary <- function(overall_alert, tmax_alert, tmin_alert) {
  if (overall_alert == "Fora de época") {
    return("Indicador DSP de temperatura fora da época de aplicação operacional (maio a outubro).")
  }

  if (overall_alert == "Sem dados") {
    return("Dados insuficientes para emitir alerta automático de temperatura DSP.")
  }

  if (overall_alert == "Verde") {
    return("Manter vigilância habitual, hidratação regular e monitorização das atualizações meteorológicas.")
  }

  advice <- character()

  if (tmax_alert %in% c("Amarelo", "Vermelho")) {
    advice <- c(
      advice,
      "calor diurno persistente: reduzir exposição direta ao sol e esforço físico nas horas de maior calor"
    )
  }

  if (tmin_alert %in% c("Amarelo", "Vermelho")) {
    advice <- c(
      advice,
      "noites quentes persistentes: reforçar arrefecimento noturno, hidratação e contacto com pessoas isoladas"
    )
  }

  paste(advice, collapse = "; ")
}

build_temperature_alerts <- function(temperature_history, latest_forecasts) {
  daily_forecasts <- daily_forecast_rows(latest_forecasts)
  source_update <- latest_source_update(daily_forecasts)

  if (nrow(daily_forecasts) == 0 || source_update == "") {
    return(empty_frame(TEMPERATURE_ALERT_COLUMNS))
  }

  rows <- lapply(seq_len(nrow(daily_forecasts)), function(i) {
    target_date <- as.Date(daily_forecasts$forecast_date[i])
    season <- season_thresholds(target_date, "max")

    tmax_obs_m3 <- value_for_date(temperature_history, target_date - 3, "tmax_c")
    tmax_obs_m2 <- value_for_date(temperature_history, target_date - 2, "tmax_c")
    tmax_obs_m1 <- value_for_date(temperature_history, target_date - 1, "tmax_c")
    tmax_forecast_d0 <- forecast_value_for_date(daily_forecasts, target_date, "tmax_c")
    tmax_forecast_p1 <- forecast_value_for_date(daily_forecasts, target_date + 1, "tmax_c")

    tmin_obs_m2 <- value_for_date(temperature_history, target_date - 2, "tmin_c")
    tmin_obs_m1 <- value_for_date(temperature_history, target_date - 1, "tmin_c")
    tmin_forecast_d0 <- forecast_value_for_date(daily_forecasts, target_date, "tmin_c")
    tmin_forecast_p1 <- forecast_value_for_date(daily_forecasts, target_date + 1, "tmin_c")

    tmax <- classify_tmax_alert(
      target_date,
      tmax_obs_m3,
      tmax_obs_m2,
      tmax_obs_m1,
      tmax_forecast_d0,
      tmax_forecast_p1
    )
    tmin <- classify_tmin_alert(
      target_date,
      tmin_obs_m2,
      tmin_obs_m1,
      tmin_forecast_d0,
      tmin_forecast_p1
    )
    overall <- overall_heat_alert(tmax$alert, tmin$alert)

    missing <- missing_inputs_text(c(
      tmax_observed_d_minus_3_c = tmax_obs_m3,
      tmax_observed_d_minus_2_c = tmax_obs_m2,
      tmax_observed_d_minus_1_c = tmax_obs_m1,
      tmax_forecast_d0_c = tmax_forecast_d0,
      tmax_forecast_d_plus_1_c = tmax_forecast_p1,
      tmin_observed_d_minus_2_c = tmin_obs_m2,
      tmin_observed_d_minus_1_c = tmin_obs_m1,
      tmin_forecast_d0_c = tmin_forecast_d0,
      tmin_forecast_d_plus_1_c = tmin_forecast_p1
    ))

    data.frame(
      source_updated_at = source_update,
      fetched_at = FETCHED_AT,
      location = LOCATION,
      district = DISTRICT,
      dico = DICO,
      global_id_local = GLOBAL_ID_LOCAL,
      target_date = as.character(target_date),
      season_rule = season$rule,
      tmax_alert = tmax$alert,
      tmax_alert_level = tmax$level,
      tmax_yellow_threshold_c = as.character(tmax$yellow),
      tmax_red_threshold_c = as.character(tmax$red),
      tmax_observed_d_minus_3_c = format_temp(tmax_obs_m3),
      tmax_observed_d_minus_2_c = format_temp(tmax_obs_m2),
      tmax_observed_d_minus_1_c = format_temp(tmax_obs_m1),
      tmax_forecast_d0_c = format_temp(tmax_forecast_d0),
      tmax_forecast_d_plus_1_c = format_temp(tmax_forecast_p1),
      tmin_alert = tmin$alert,
      tmin_alert_level = tmin$level,
      tmin_yellow_threshold_c = as.character(tmin$yellow),
      tmin_red_threshold_c = as.character(tmin$red),
      tmin_observed_d_minus_2_c = format_temp(tmin_obs_m2),
      tmin_observed_d_minus_1_c = format_temp(tmin_obs_m1),
      tmin_forecast_d0_c = format_temp(tmin_forecast_d0),
      tmin_forecast_d_plus_1_c = format_temp(tmin_forecast_p1),
      overall_temperature_alert = overall,
      overall_temperature_alert_level = alert_level(overall),
      missing_inputs = missing,
      recommendation_summary = recommendation_summary(overall, tmax$alert, tmin$alert),
      source = "DSP temperature rule using IPMA observed municipality temperatures and IPMA forecasts",
      stringsAsFactors = FALSE
    )
  })

  alerts <- bind_rows(rows)
  alerts[] <- lapply(alerts, as.character)
  alerts[, TEMPERATURE_ALERT_COLUMNS]
}

write_temperature_alerts <- function(new_data) {
  existing <- read_existing(TEMPERATURE_ALERTS_PATH, TEMPERATURE_ALERT_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    TEMPERATURE_ALERT_COLUMNS,
    TEMPERATURE_ALERT_KEY_COLUMNS,
    setdiff(TEMPERATURE_ALERT_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(source_updated_at, target_date) %>%
    distinct(across(all_of(TEMPERATURE_ALERT_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, TEMPERATURE_ALERTS_PATH, na = "")

  latest_update <- latest_source_update(combined)
  latest <- combined[combined$source_updated_at == latest_update, , drop = FALSE]
  write_csv(latest, TEMPERATURE_ALERTS_LATEST_PATH, na = "")

  list(combined = combined, latest = latest)
}

classify_uv <- function(value) {
  uv <- to_num(value)
  if (is.na(uv)) {
    return(list(
      level = "Sem dados",
      order = as.character(UV_LEVELS[["Sem dados"]]),
      color = "",
      protection = "Sem dados"
    ))
  }

  if (uv < 3) {
    return(list(
      level = "Baixo",
      order = as.character(UV_LEVELS[["Baixo"]]),
      color = "Verde",
      protection = "Proteção mínima"
    ))
  }

  if (uv < 6) {
    return(list(
      level = "Moderado",
      order = as.character(UV_LEVELS[["Moderado"]]),
      color = "Amarelo",
      protection = "Proteção necessária"
    ))
  }

  if (uv < 8) {
    return(list(
      level = "Alto",
      order = as.character(UV_LEVELS[["Alto"]]),
      color = "Laranja",
      protection = "Proteção reforçada"
    ))
  }

  if (uv < 11) {
    return(list(
      level = "Muito Alto",
      order = as.character(UV_LEVELS[["Muito Alto"]]),
      color = "Vermelho",
      protection = "Proteção extra"
    ))
  }

  list(
    level = "Extremo",
    order = as.character(UV_LEVELS[["Extremo"]]),
    color = "Violeta",
    protection = "Evitar exposição"
  )
}

uv_recommendation_summary <- function(level) {
  switch(
    level,
    "Sem dados" = "Sem dados de Índice UV para emitir recomendação automática.",
    "Baixo" = "Risco baixo; manter vigilância e proteção básica para pele/olhos sensíveis.",
    "Moderado" = "Proteção necessária; usar óculos com filtro UV, chapéu, roupa que cubra a pele e protetor solar em pele exposta.",
    "Alto" = "Proteção reforçada; reduzir exposição nas horas centrais, procurar sombra e usar proteção ocular, chapéu, roupa e protetor solar.",
    "Muito Alto" = "Proteção extra; evitar exposição prolongada nas horas centrais e reforçar sombra, roupa, chapéu, óculos e protetor solar.",
    "Extremo" = "Evitar exposição solar tanto quanto possível, sobretudo nas horas centrais; atividades exteriores devem ser adiadas ou fortemente condicionadas.",
    "Confirmar manualmente o nível UV antes de comunicar."
  )
}

build_uv_index <- function(latest_forecasts) {
  daily_forecasts <- daily_forecast_rows(latest_forecasts)
  source_update <- latest_source_update(daily_forecasts)

  if (nrow(daily_forecasts) == 0 || source_update == "") {
    return(empty_frame(UV_INDEX_COLUMNS))
  }

  rows <- lapply(seq_len(nrow(daily_forecasts)), function(i) {
    uv_value <- field_text(as.list(daily_forecasts[i, , drop = FALSE]), "uv_index")
    classification <- classify_uv(uv_value)

    data.frame(
      source_updated_at = source_update,
      fetched_at = FETCHED_AT,
      location = LOCATION,
      district = DISTRICT,
      global_id_local = GLOBAL_ID_LOCAL,
      target_date = as_text(daily_forecasts$forecast_date[i]),
      uv_index = uv_value,
      uv_level = classification$level,
      uv_level_order = classification$order,
      uv_color = classification$color,
      protection_required = classification$protection,
      recommendation_summary = uv_recommendation_summary(classification$level),
      source = "IPMA public-data forecast aggregate daily UV index",
      stringsAsFactors = FALSE
    )
  })

  uv <- bind_rows(rows)
  uv[] <- lapply(uv, as.character)
  uv[, UV_INDEX_COLUMNS]
}

write_uv_index <- function(new_data) {
  existing <- read_existing(UV_INDEX_PATH, UV_INDEX_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    UV_INDEX_COLUMNS,
    UV_INDEX_KEY_COLUMNS,
    setdiff(UV_INDEX_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(source_updated_at, target_date) %>%
    distinct(across(all_of(UV_INDEX_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, UV_INDEX_PATH, na = "")

  latest_update <- latest_source_update(combined)
  latest <- combined[combined$source_updated_at == latest_update, , drop = FALSE]
  write_csv(latest, UV_INDEX_LATEST_PATH, na = "")

  list(combined = combined, latest = latest)
}

temperature_recommendations <- function(row) {
  overall <- as_text(row$overall_temperature_alert)
  tmax_alert <- as_text(row$tmax_alert)
  tmin_alert <- as_text(row$tmin_alert)

  if (overall == "Fora de época") {
    return(paste(
      "Comunicação geral: o indicador Temperatura DSP não é aplicado automaticamente fora do período de maio a outubro; manter apenas vigilância meteorológica habitual.",
      "Grupos vulneráveis: manter cuidados gerais adequados à temperatura prevista e validar manualmente qualquer situação excecional de calor fora de época.",
      "Estabelecimentos: sem ativação automática por este indicador fora da época DSP; manter planos de contingência disponíveis caso exista aviso meteorológico ou orientação das autoridades de saúde.",
      sep = "\n\n"
    ))
  }

  if (overall == "Sem dados") {
    return(paste(
      "Comunicação geral: não emitir mensagem automática de risco térmico sem validação manual; faltam dados para aplicar integralmente a regra DSP.",
      "Grupos vulneráveis: manter vigilância de rotina em pessoas idosas, crianças pequenas, grávidas, pessoas com doença crónica, pessoas isoladas e trabalhadores no exterior; confirmar a situação meteorológica antes de escalar medidas.",
      "Estabelecimentos: manter monitorização das previsões IPMA e preparar medidas de calor, mas sem ativação automática por este indicador enquanto os dados estiverem incompletos.",
      sep = "\n\n"
    ))
  }

  general <- switch(
    overall,
    "Verde" = "Comunicação geral: mensagem simples de vigilância. Manter hidratação regular, refeições leves nos dias mais quentes e atenção às atualizações meteorológicas.",
    "Amarelo" = "Comunicação geral: mensagem preventiva. Reforçar ingestão de água, procurar locais frescos e reduzir exposição solar direta e esforço físico no exterior, sobretudo entre as 11h e as 17h.",
    "Vermelho" = "Comunicação geral: mensagem de alerta. Evitar exposição direta ao sol e esforço físico no exterior nas horas de maior calor; procurar ambientes frescos ou climatizados e acompanhar sinais de desidratação, exaustão ou agravamento de doença crónica.",
    "Comunicação geral: confirmar manualmente o nível de alerta antes de comunicar."
  )

  vulnerable <- switch(
    overall,
    "Verde" = "Grupos vulneráveis: manter rotinas habituais, com hidratação frequente e atenção a sintomas em pessoas idosas, crianças, grávidas e pessoas com doenças cardiovasculares, respiratórias, renais, diabetes ou medicação sensível ao calor.",
    "Amarelo" = "Grupos vulneráveis: beber água mesmo sem sede, permanecer em ambientes frescos pelo menos 2 a 3 horas por dia, evitar saídas e esforço físico nas horas de maior calor e garantir contacto regular com pessoas isoladas.",
    "Vermelho" = "Grupos vulneráveis: permanecer em ambiente fresco ou climatizado sempre que possível, reforçar contacto ativo com pessoas isoladas, ajustar atividades ao início da manhã ou ao fim do dia e contactar SNS 24 (808 24 24 24) ou cuidados de saúde se houver agravamento de sintomas.",
    "Grupos vulneráveis: aguardar validação manual dos dados."
  )

  establishments <- switch(
    overall,
    "Verde" = "Estabelecimentos: manter atividades previstas, garantindo disponibilidade de água e locais de sombra/descanso.",
    "Amarelo" = "Estabelecimentos: adaptar atividades ao ar livre, privilegiar manhã cedo, reforçar pausas, água, sombra e vigilância de utentes ou trabalhadores vulneráveis.",
    "Vermelho" = "Estabelecimentos: suspender ou substituir atividades físicas intensas ao ar livre, reforçar arrefecimento dos espaços, organizar pausas frequentes, acompanhar sintomas e garantir contacto rápido com famílias/cuidadores quando aplicável.",
    "Estabelecimentos: aguardar validação manual dos dados."
  )

  specific <- character()
  if (tmax_alert %in% c("Amarelo", "Vermelho")) {
    specific <- c(
      specific,
      "Sinal de máxima: risco associado a calor diurno persistente; deslocar tarefas, passeios, terapias e exercício para horários mais frescos e evitar viaturas estacionadas ao sol."
    )
  }

  if (tmin_alert %in% c("Amarelo", "Vermelho")) {
    specific <- c(
      specific,
      "Sinal de mínima: risco associado a noites quentes e menor recuperação fisiológica; reforçar arrefecimento noturno seguro, roupa leve, hidratação e acompanhamento de pessoas que vivem sozinhas."
    )
  }

  if (length(specific) == 0) {
    specific <- "Sem medidas adicionais por sinal térmico para além da vigilância habitual."
  } else {
    specific <- paste(specific, collapse = " ")
  }

  paste(general, vulnerable, establishments, specific, sep = "\n\n")
}

temperature_values_text <- function(row) {
  paste0(
    "Máxima: observadas D-3/D-2/D-1 = ",
    paste(
      vapply(
        c(
        as_text(row$tmax_observed_d_minus_3_c),
        as_text(row$tmax_observed_d_minus_2_c),
        as_text(row$tmax_observed_d_minus_1_c)
        ),
        display_temp,
        character(1)
      ),
      collapse = "/"
    ),
    " ºC; previstas D/D+1 = ",
    paste(
      vapply(
        c(as_text(row$tmax_forecast_d0_c), as_text(row$tmax_forecast_d_plus_1_c)),
        display_temp,
        character(1)
      ),
      collapse = "/"
    ),
    " ºC. Mínima: observadas D-2/D-1 = ",
    paste(
      vapply(
        c(as_text(row$tmin_observed_d_minus_2_c), as_text(row$tmin_observed_d_minus_1_c)),
        display_temp,
        character(1)
      ),
      collapse = "/"
    ),
    " ºC; previstas D/D+1 = ",
    paste(
      vapply(
        c(as_text(row$tmin_forecast_d0_c), as_text(row$tmin_forecast_d_plus_1_c)),
        display_temp,
        character(1)
      ),
      collapse = "/"
    ),
    " ºC."
  )
}

build_temperature_daily_section <- function(row) {
  target_date <- as_text(row$target_date)
  missing <- as_text(row$missing_inputs)

  content <- c(
    "<!-- temperatura-dsp:start -->",
    paste0("## Temperatura DSP - ", target_date),
    "",
    paste0(
      "Fonte dos valores: IPMA. Atualização IPMA: ",
      as_text(row$source_updated_at),
      " UTC."
    ),
    "",
    paste0(
      "Nível global de temperatura: ",
      as_text(row$overall_temperature_alert),
      ". Alerta por máxima: ",
      as_text(row$tmax_alert),
      " (limiares ",
      threshold_pair_text(row$tmax_yellow_threshold_c, row$tmax_red_threshold_c),
      "). Alerta por mínima: ",
      as_text(row$tmin_alert),
      " (limiares ",
      threshold_pair_text(row$tmin_yellow_threshold_c, row$tmin_red_threshold_c),
      ")."
    ),
    "",
    temperature_values_text(row),
    ""
  )

  if (missing != "") {
    content <- c(
      content,
      paste0("Dados em falta para a regra automática: ", missing, "."),
      ""
    )
  }

  c(
    content,
    temperature_recommendations(row),
    "",
    "Fontes de apoio para recomendações de temperatura:",
    "",
    HEAT_SOURCE_LINKS,
    "<!-- temperatura-dsp:end -->"
  )
}

uv_recommendations <- function(row) {
  level <- as_text(row$uv_level)

  if (level == "Sem dados") {
    return(paste(
      "Comunicação geral: não emitir recomendação automática de UV sem confirmar a previsão; manter referência às medidas gerais de proteção solar quando houver exposição.",
      "Grupos vulneráveis: crianças, pessoas idosas, pessoas com pele clara, antecedentes de cancro cutâneo, doença ocular ou medicação fotossensibilizante devem manter proteção reforçada se houver exposição ao sol.",
      "Estruturas: manter monitorização da previsão UV e garantir disponibilidade de sombra, água e protetor solar quando houver atividades exteriores.",
      sep = "\n\n"
    ))
  }

  general <- switch(
    level,
    "Baixo" = "Comunicação geral: risco UV baixo. A exposição ao ar livre pode decorrer normalmente; pessoas com pele/olhos sensíveis devem manter óculos de sol com filtro UV e proteção básica.",
    "Moderado" = "Comunicação geral: risco UV moderado. Usar óculos de sol com filtro UV, chapéu e protetor solar nas zonas expostas; preferir sombra nas horas centrais se a exposição for prolongada.",
    "Alto" = "Comunicação geral: risco UV alto. Procurar sombra entre o final da manhã e o meio da tarde, usar roupa que cubra a pele, chapéu de abas, óculos com filtro UV e protetor solar em pele exposta.",
    "Muito Alto" = "Comunicação geral: risco UV muito alto. Evitar exposição prolongada nas horas centrais; se for inevitável estar no exterior, combinar sombra, roupa, chapéu, óculos com filtro UV e protetor solar, reaplicando quando necessário.",
    "Extremo" = "Comunicação geral: risco UV extremo. Evitar exposição solar tanto quanto possível, sobretudo nas horas centrais; adiar atividades exteriores não essenciais e usar proteção máxima quando a exposição for inevitável.",
    "Comunicação geral: confirmar manualmente o nível UV antes de comunicar."
  )

  vulnerable <- switch(
    level,
    "Baixo" = "Grupos vulneráveis: manter proteção básica e evitar exposição desnecessária em bebés, pessoas com pele muito clara, antecedentes de cancro cutâneo ou doença ocular.",
    "Moderado" = "Grupos vulneráveis: crianças, grávidas, pessoas idosas, pessoas com pele clara ou medicação fotossensibilizante devem usar chapéu, roupa protetora, óculos UV e protetor solar; bebés devem ficar fora da exposição direta.",
    "Alto" = "Grupos vulneráveis: evitar sol direto nas horas centrais, privilegiar sombra e espaços interiores frescos; reforçar proteção ocular e cutânea e vigiar sinais de queimadura solar.",
    "Muito Alto" = "Grupos vulneráveis: evitar atividades ao sol nas horas centrais; crianças e pessoas muito sensíveis devem permanecer à sombra ou no interior, com proteção completa se tiverem de sair.",
    "Extremo" = "Grupos vulneráveis: não programar exposição solar direta; manter crianças e pessoas de maior risco no interior ou em sombra densa e garantir proteção total em deslocações inevitáveis.",
    "Grupos vulneráveis: aguardar validação manual dos dados."
  )

  structures <- switch(
    level,
    "Baixo" = "Estruturas: manter atividades exteriores previstas, com acesso a água e sombra disponível.",
    "Moderado" = "Estruturas: planear pausas à sombra, disponibilizar protetor solar e incentivar chapéu/óculos em atividades exteriores prolongadas.",
    "Alto" = "Estruturas: ajustar horários de atividades exteriores, privilegiar manhã cedo ou fim do dia, garantir sombra efetiva e controlar proteção de crianças, utentes e trabalhadores.",
    "Muito Alto" = "Estruturas: reduzir ou relocalizar atividades exteriores para espaços sombreados/interiores; reforçar comunicação, pausas, supervisão e disponibilidade de protetor solar.",
    "Extremo" = "Estruturas: suspender ou adiar atividades exteriores não essenciais nas horas centrais; ativar alternativas interiores/sombreadas e supervisionar deslocações inevitáveis.",
    "Estruturas: aguardar validação manual dos dados."
  )

  paste(general, vulnerable, structures, sep = "\n\n")
}

has_uv_index_value <- function(row) {
  as_text(row$uv_index) != ""
}

uv_rows_for_report <- function(uv_index, report_date) {
  uv_dates <- as.Date(uv_index$target_date)
  report_date_value <- as.Date(report_date)
  future_rows <- uv_index[
    !is.na(uv_dates) & uv_dates >= report_date_value,
    ,
    drop = FALSE
  ]

  if (nrow(future_rows) == 0) {
    future_rows <- uv_index
  }

  rows_with_values <- future_rows[
    vapply(seq_len(nrow(future_rows)), function(i) {
      has_uv_index_value(future_rows[i, , drop = FALSE])
    }, logical(1)),
    ,
    drop = FALSE
  ]

  if (nrow(rows_with_values) > 0) {
    return(rows_with_values %>%
      arrange(target_date) %>%
      as.data.frame(stringsAsFactors = FALSE))
  }

  future_rows %>%
    arrange(target_date) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

uv_table_lines <- function(rows) {
  if (nrow(rows) == 0) {
    return("Sem previsões UV preenchidas no último snapshot IPMA.")
  }

  c(
    "| Data | Índice UV | Nível | Proteção |",
    "|---|---:|---|---|",
    vapply(seq_len(nrow(rows)), function(i) {
      row <- rows[i, , drop = FALSE]
      paste0(
        "| ",
        as_text(row$target_date),
        " | ",
        display_temp(row$uv_index),
        " | ",
        as_text(row$uv_level),
        " | ",
        as_text(row$protection_required),
        " |"
      )
    }, character(1))
  )
}

highest_uv_row <- function(rows) {
  rows_with_values <- rows[
    vapply(seq_len(nrow(rows)), function(i) {
      has_uv_index_value(rows[i, , drop = FALSE])
    }, logical(1)),
    ,
    drop = FALSE
  ]

  if (nrow(rows_with_values) == 0) {
    return(rows[1, , drop = FALSE])
  }

  rows_with_values %>%
    mutate(
      uv_level_order_num = to_num(uv_level_order),
      uv_index_num = to_num(uv_index)
    ) %>%
    arrange(desc(uv_level_order_num), desc(uv_index_num), target_date) %>%
    slice(1) %>%
    select(all_of(UV_INDEX_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

build_uv_daily_section <- function(rows, report_date) {
  source_update <- latest_source_update(rows)
  if (source_update == "") {
    source_update <- as_text(rows$source_updated_at)
  }

  rows_with_values <- rows[
    vapply(seq_len(nrow(rows)), function(i) {
      has_uv_index_value(rows[i, , drop = FALSE])
    }, logical(1)),
    ,
    drop = FALSE
  ]
  recommendation_row <- highest_uv_row(rows)

  if (nrow(rows_with_values) > 0) {
    first_date <- min(as.Date(rows_with_values$target_date), na.rm = TRUE)
    last_date <- max(as.Date(rows_with_values$target_date), na.rm = TRUE)
    date_scope <- if (first_date == last_date) {
      as.character(first_date)
    } else {
      paste0(as.character(first_date), " a ", as.character(last_date))
    }
  } else {
    date_scope <- report_date
  }

  c(
    "<!-- uv:start -->",
    paste0("## Índice UV - previsões disponíveis em ", report_date),
    "",
    paste0(
      "Fonte dos valores: IPMA. Atualização IPMA: ",
      source_update,
      " UTC. Período com valor previsto: ",
      date_scope,
      "."
    ),
    "",
    uv_table_lines(rows_with_values),
    "",
    paste0(
      "Nível máximo no período: ",
      as_text(recommendation_row$uv_level),
      " em ",
      as_text(recommendation_row$target_date),
      " (Índice UV ",
      display_temp(recommendation_row$uv_index),
      "). As recomendações abaixo seguem este nível mais exigente."
    ),
    "",
    uv_recommendations(recommendation_row),
    "",
    "Fontes de apoio para recomendações UV:",
    "",
    UV_SOURCE_LINKS,
    "<!-- uv:end -->"
  )
}

replace_marked_section <- function(existing, section, marker) {
  start_marker <- paste0("<!-- ", marker, ":start -->")
  end_marker <- paste0("<!-- ", marker, ":end -->")
  start <- which(existing == start_marker)
  end <- which(existing == end_marker)

  if (length(start) > 0 && length(end) > 0 && end[1] > start[1]) {
    before <- if (start[1] > 1) existing[seq_len(start[1] - 1)] else character()
    after <- if (end[1] < length(existing)) existing[(end[1] + 1):length(existing)] else character()
    return(c(before, section, after))
  }

  source_header <- grep("^## Fontes usadas para recomendações", existing)
  if (length(source_header) > 0) {
    before <- if (source_header[1] > 1) existing[seq_len(source_header[1] - 1)] else character()
    after <- existing[source_header[1]:length(existing)]
    return(c(before, section, "", after))
  }

  c(existing, "", section)
}

replace_managed_section <- function(existing, section) {
  replace_marked_section(existing, section, "temperatura-dsp")
}

update_daily_temperature_report <- function(alerts) {
  if (nrow(alerts) == 0) {
    return("")
  }

  report_date <- format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ)
  selected <- alerts[alerts$target_date == report_date, , drop = FALSE]
  if (nrow(selected) == 0) {
    selected <- alerts[alerts$target_date >= report_date, , drop = FALSE]
  }
  if (nrow(selected) == 0) {
    selected <- alerts[1, , drop = FALSE]
  }

  target_report_date <- as_text(selected$target_date)
  dir.create(DAILY_DIR, showWarnings = FALSE, recursive = TRUE)
  report_path <- file.path(DAILY_DIR, paste0(target_report_date, ".md"))

  if (file.exists(report_path)) {
    existing <- readLines(report_path, warn = FALSE, encoding = "UTF-8")
  } else {
    existing <- c(
      paste0("# Relatório diário - ", LOCATION, ", ", DISTRICT),
      "",
      paste0("Ficheiro diário: ", target_report_date),
      ""
    )
  }

  section <- build_temperature_daily_section(selected[1, , drop = FALSE])
  updated <- replace_managed_section(existing, section)
  writeLines(updated, report_path, useBytes = TRUE)
  report_path
}

update_daily_uv_report <- function(uv_index) {
  if (nrow(uv_index) == 0) {
    return("")
  }

  report_date <- format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ)
  uv_dates <- as.Date(uv_index$target_date)
  if (!any(!is.na(uv_dates) & uv_dates >= as.Date(report_date))) {
    report_date <- as_text(uv_index$target_date[1])
  }
  selected <- uv_rows_for_report(uv_index, report_date)

  dir.create(DAILY_DIR, showWarnings = FALSE, recursive = TRUE)
  report_path <- file.path(DAILY_DIR, paste0(report_date, ".md"))

  if (file.exists(report_path)) {
    existing <- readLines(report_path, warn = FALSE, encoding = "UTF-8")
  } else {
    existing <- c(
      paste0("# Relatório diário - ", LOCATION, ", ", DISTRICT),
      "",
      paste0("Ficheiro diário: ", report_date),
      ""
    )
  }

  section <- build_uv_daily_section(selected, report_date)
  updated <- replace_marked_section(existing, section, "uv")
  writeLines(updated, report_path, useBytes = TRUE)
  report_path
}

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

climate_temperature_data <- build_temperature_history()

station_observations_data <- build_station_observations()
station_observations_history <- write_station_observations(station_observations_data)

station_daily_data <- build_station_daily_temperatures(station_observations_history)
station_daily_history <- write_station_daily_temperatures(station_daily_data)

temperature_data <- apply_station_temperature_fallback(
  climate_temperature_data,
  station_daily_history
)
temperature_history <- write_temperature_history(temperature_data)

forecast_data <- build_forecasts()
forecast_result <- write_forecasts(forecast_data)

temperature_alerts_data <- build_temperature_alerts(
  temperature_history,
  forecast_result$latest
)
temperature_alerts_result <- write_temperature_alerts(temperature_alerts_data)
daily_temperature_report_path <- update_daily_temperature_report(temperature_alerts_result$latest)

uv_index_data <- build_uv_index(forecast_result$latest)
uv_index_result <- write_uv_index(uv_index_data)
daily_uv_report_path <- update_daily_uv_report(uv_index_result$latest)

message(sprintf(
  paste(
    "OK - %d climate temperature row(s) fetched; %d station observation row(s) fetched.",
    "Station observation archive has %d row(s); station daily fallback has %d row(s).",
    "%d temperature row(s) prepared; temperature history has %d row(s).",
    "%d forecast row(s) fetched; forecast archive has %d row(s); latest snapshot has %d row(s).",
    "%d temperature alert row(s) calculated; alert archive has %d row(s); temperature report: %s.",
    "%d UV row(s) calculated; UV archive has %d row(s); UV report: %s."
  ),
  nrow(climate_temperature_data),
  nrow(station_observations_data),
  nrow(station_observations_history),
  nrow(station_daily_history),
  nrow(temperature_data),
  nrow(temperature_history),
  nrow(forecast_data),
  nrow(forecast_result$combined),
  nrow(forecast_result$latest),
  nrow(temperature_alerts_data),
  nrow(temperature_alerts_result$combined),
  daily_temperature_report_path,
  nrow(uv_index_data),
  nrow(uv_index_result$combined),
  daily_uv_report_path
))
