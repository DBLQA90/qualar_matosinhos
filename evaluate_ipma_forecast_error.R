library(dplyr)
library(readr)

DATA_DIR <- "data"
FORECAST_PATH <- file.path(DATA_DIR, "ipma_matosinhos_forecasts.csv")
TEMPERATURE_PATH <- file.path(DATA_DIR, "ipma_matosinhos_temperaturas.csv")
STATION_DAILY_TEMPERATURES_PATH <- file.path(
  DATA_DIR,
  "ipma_matosinhos_station_daily_temperatures.csv"
)
FORECAST_ERROR_PATH <- file.path(DATA_DIR, "ipma_matosinhos_forecast_errors.csv")
FORECAST_ERROR_SUMMARY_PATH <- file.path(
  DATA_DIR,
  "ipma_matosinhos_forecast_error_summary.csv"
)

ERROR_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "forecast_issue_datetime_utc",
  "forecast_issue_date",
  "forecast_issue_hour_utc",
  "forecast_date",
  "horizon_days",
  "horizon_label",
  "location",
  "district",
  "global_id_local",
  "forecast_tmin_c",
  "observed_tmin_c",
  "error_tmin_c",
  "abs_error_tmin_c",
  "forecast_tmax_c",
  "observed_tmax_c",
  "error_tmax_c",
  "abs_error_tmax_c",
  "observed_source_type",
  "observed_source",
  "observation_status",
  "forecast_source",
  "calculated_at"
)

SUMMARY_COLUMNS <- c(
  "metric",
  "horizon_days",
  "horizon_label",
  "n",
  "mean_error_c",
  "mae_c",
  "rmse_c",
  "median_abs_error_c",
  "p90_abs_error_c",
  "min_error_c",
  "max_error_c",
  "municipality_observed_n",
  "station_fallback_n",
  "first_forecast_date",
  "last_forecast_date",
  "calculated_at"
)

empty_frame <- function(columns) {
  output <- as.data.frame(
    matrix(character(), nrow = 0, ncol = length(columns)),
    stringsAsFactors = FALSE
  )
  names(output) <- columns
  output
}

read_character_csv <- function(path) {
  if (!file.exists(path)) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  read_csv(
    path,
    show_col_types = FALSE,
    col_types = cols(.default = "c")
  ) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

as_text <- function(value) {
  if (length(value) == 0 || is.na(value)) {
    return("")
  }
  as.character(value)
}

to_num <- function(value) {
  suppressWarnings(as.numeric(value))
}

round_num <- function(value, digits = 3) {
  ifelse(is.na(value), NA_real_, round(value, digits))
}

latest_timestamp <- function(primary, secondary) {
  primary <- as.character(primary)
  secondary <- as.character(secondary)
  primary[is.na(primary)] <- ""
  secondary[is.na(secondary)] <- ""
  ifelse(
    primary == "",
    secondary,
    ifelse(secondary == "", primary, pmax(primary, secondary))
  )
}

max_timestamp <- function(value) {
  value <- as.character(value)
  value <- value[!is.na(value) & value != ""]
  if (length(value) == 0) {
    return("")
  }
  max(value)
}

parse_ipma_datetime <- function(value) {
  value <- as.character(value)
  value[is.na(value) | value == ""] <- NA_character_
  value <- sub("Z$", "", value)
  parsed <- as.POSIXct(value, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
  missing <- is.na(parsed) & !is.na(value)
  parsed[missing] <- as.POSIXct(
    value[missing],
    format = "%Y-%m-%dT%H:%M",
    tz = "UTC"
  )
  parsed
}

horizon_label <- function(days) {
  ifelse(is.na(days), "", paste0("D+", days))
}

observed_source_type <- function(source) {
  case_when(
    grepl("station fallback", source, ignore.case = TRUE) ~ "station_fallback",
    grepl("station extrema", source, ignore.case = TRUE) ~ "station_fallback",
    grepl("observation/climate", source, ignore.case = TRUE) ~ "municipality_observed",
    source == "" | is.na(source) ~ "missing",
    TRUE ~ "other"
  )
}

observation_status <- function(tmin, tmax, source_type) {
  case_when(
    is.na(tmin) & is.na(tmax) ~ "pending",
    is.na(tmin) | is.na(tmax) ~ "partial",
    source_type == "municipality_observed" ~ "matched_municipality_observed",
    source_type == "station_fallback" ~ "matched_station_fallback",
    TRUE ~ "matched_other"
  )
}

build_observations <- function() {
  temperature_history <- read_character_csv(TEMPERATURE_PATH)
  station_daily <- read_character_csv(STATION_DAILY_TEMPERATURES_PATH)

  observations <- list()

  if (nrow(temperature_history) > 0) {
    observations[["temperature_history"]] <- temperature_history %>%
      transmute(
        observed_date = as.Date(date),
        observed_tmin_c = to_num(tmin_c),
        observed_tmax_c = to_num(tmax_c),
        observed_source = as.character(source),
        observed_fetched_at = as.character(fetched_at),
        source_rank = case_when(
          observed_source_type(source) == "municipality_observed" ~ 1L,
          observed_source_type(source) == "station_fallback" ~ 2L,
          TRUE ~ 3L
        )
      )
  }

  if (nrow(station_daily) > 0) {
    observations[["station_daily"]] <- station_daily %>%
      transmute(
        observed_date = as.Date(date),
        observed_tmin_c = to_num(tmin_c),
        observed_tmax_c = to_num(tmax_c),
        observed_source = as.character(source),
        observed_fetched_at = as.character(fetched_at),
        source_rank = 2L
      )
  }

  if (length(observations) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  bind_rows(observations) %>%
    filter(!is.na(observed_date)) %>%
    arrange(observed_date, source_rank, desc(observed_fetched_at)) %>%
    distinct(observed_date, .keep_all = TRUE) %>%
    mutate(
      observed_date = as.character(observed_date),
      observed_source_type = observed_source_type(observed_source)
    ) %>%
    select(
      observed_date,
      observed_tmin_c,
      observed_tmax_c,
      observed_source_type,
      observed_source,
      observed_fetched_at
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

build_forecast_errors <- function() {
  forecasts <- read_character_csv(FORECAST_PATH)
  if (nrow(forecasts) == 0) {
    return(empty_frame(ERROR_COLUMNS))
  }

  observations <- build_observations()
  issue_datetime <- parse_ipma_datetime(forecasts$source_updated_at)

  daily_forecasts <- forecasts %>%
    mutate(
      forecast_issue_datetime_utc = issue_datetime,
      forecast_issue_date = as.Date(forecast_issue_datetime_utc),
      forecast_issue_hour_utc = format(forecast_issue_datetime_utc, "%H:%M", tz = "UTC"),
      forecast_date_as_date = as.Date(forecast_date),
      horizon_days = as.integer(forecast_date_as_date - forecast_issue_date)
    ) %>%
    filter(period_type == "daily", !is.na(forecast_date_as_date)) %>%
    transmute(
      source_updated_at = as.character(source_updated_at),
      fetched_at = as.character(fetched_at),
      forecast_issue_datetime_utc = ifelse(
        is.na(forecast_issue_datetime_utc),
        "",
        format(forecast_issue_datetime_utc, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      ),
      forecast_issue_date = as.character(forecast_issue_date),
      forecast_issue_hour_utc = ifelse(is.na(forecast_issue_hour_utc), "", forecast_issue_hour_utc),
      forecast_date = as.character(forecast_date_as_date),
      horizon_days = horizon_days,
      horizon_label = horizon_label(horizon_days),
      location = as.character(location),
      district = as.character(district),
      global_id_local = as.character(global_id_local),
      forecast_tmin_c = to_num(tmin_c),
      forecast_tmax_c = to_num(tmax_c),
      forecast_source = as.character(source)
    )

  if (nrow(observations) == 0) {
    joined <- daily_forecasts
    joined$observed_tmin_c <- NA_real_
    joined$observed_tmax_c <- NA_real_
    joined$observed_source_type <- "missing"
    joined$observed_source <- ""
    joined$observed_fetched_at <- ""
  } else {
    joined <- daily_forecasts %>%
      left_join(observations, by = c("forecast_date" = "observed_date"))
  }

  joined %>%
    mutate(
      observed_source_type = ifelse(
        is.na(observed_source_type) | observed_source_type == "",
        "missing",
        observed_source_type
      ),
      observed_source = ifelse(is.na(observed_source), "", observed_source),
      observed_fetched_at = ifelse(is.na(observed_fetched_at), "", observed_fetched_at),
      error_tmin_c = forecast_tmin_c - observed_tmin_c,
      abs_error_tmin_c = abs(error_tmin_c),
      error_tmax_c = forecast_tmax_c - observed_tmax_c,
      abs_error_tmax_c = abs(error_tmax_c),
      observation_status = observation_status(
        observed_tmin_c,
        observed_tmax_c,
        observed_source_type
      ),
      calculated_at = latest_timestamp(fetched_at, observed_fetched_at)
    ) %>%
    transmute(
      source_updated_at,
      fetched_at,
      forecast_issue_datetime_utc,
      forecast_issue_date,
      forecast_issue_hour_utc,
      forecast_date,
      horizon_days = as.character(horizon_days),
      horizon_label,
      location,
      district,
      global_id_local,
      forecast_tmin_c = round_num(forecast_tmin_c),
      observed_tmin_c = round_num(observed_tmin_c),
      error_tmin_c = round_num(error_tmin_c),
      abs_error_tmin_c = round_num(abs_error_tmin_c),
      forecast_tmax_c = round_num(forecast_tmax_c),
      observed_tmax_c = round_num(observed_tmax_c),
      error_tmax_c = round_num(error_tmax_c),
      abs_error_tmax_c = round_num(abs_error_tmax_c),
      observed_source_type,
      observed_source,
      observation_status,
      forecast_source,
      calculated_at
    ) %>%
    arrange(source_updated_at, forecast_date, horizon_days) %>%
    select(all_of(ERROR_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

summary_for_metric <- function(errors, metric, forecast_column, observed_column, error_column, abs_column) {
  metric_data <- errors %>%
    transmute(
      metric = metric,
      horizon_days = to_num(horizon_days),
      horizon_label = horizon_label(horizon_days),
      forecast_date = as.character(forecast_date),
      forecast_value = to_num(.data[[forecast_column]]),
      observed_value = to_num(.data[[observed_column]]),
      error_c = to_num(.data[[error_column]]),
      abs_error_c = to_num(.data[[abs_column]]),
      observed_source_type = as.character(observed_source_type),
      calculated_at = as.character(calculated_at)
    ) %>%
    filter(
      !is.na(horizon_days),
      !is.na(forecast_value),
      !is.na(observed_value),
      !is.na(error_c)
    )

  if (nrow(metric_data) == 0) {
    return(empty_frame(SUMMARY_COLUMNS))
  }

  metric_data %>%
    group_by(metric, horizon_days, horizon_label) %>%
    summarise(
      n = n(),
      mean_error_c = round(mean(error_c), 3),
      mae_c = round(mean(abs_error_c), 3),
      rmse_c = round(sqrt(mean(error_c^2)), 3),
      median_abs_error_c = round(median(abs_error_c), 3),
      p90_abs_error_c = round(as.numeric(quantile(abs_error_c, 0.9, na.rm = TRUE)), 3),
      min_error_c = round(min(error_c), 3),
      max_error_c = round(max(error_c), 3),
      municipality_observed_n = sum(observed_source_type == "municipality_observed"),
      station_fallback_n = sum(observed_source_type == "station_fallback"),
      first_forecast_date = min(forecast_date),
      last_forecast_date = max(forecast_date),
      calculated_at = max_timestamp(calculated_at),
      .groups = "drop"
    ) %>%
    mutate(
      horizon_days = as.character(as.integer(horizon_days))
    ) %>%
    arrange(metric, as.integer(horizon_days)) %>%
    select(all_of(SUMMARY_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

build_forecast_error_summary <- function(errors) {
  if (nrow(errors) == 0) {
    return(empty_frame(SUMMARY_COLUMNS))
  }

  bind_rows(
    summary_for_metric(
      errors,
      "tmin_c",
      "forecast_tmin_c",
      "observed_tmin_c",
      "error_tmin_c",
      "abs_error_tmin_c"
    ),
    summary_for_metric(
      errors,
      "tmax_c",
      "forecast_tmax_c",
      "observed_tmax_c",
      "error_tmax_c",
      "abs_error_tmax_c"
    )
  ) %>%
    select(all_of(SUMMARY_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

errors <- build_forecast_errors()
summary <- build_forecast_error_summary(errors)

write_csv(errors, FORECAST_ERROR_PATH, na = "")
write_csv(summary, FORECAST_ERROR_SUMMARY_PATH, na = "")

message(sprintf(
  "OK forecast error - %d forecast row(s), %d summary row(s).",
  nrow(errors),
  nrow(summary)
))
