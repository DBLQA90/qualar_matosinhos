library(dplyr)
library(readr)

DATA_DIR <- "data"
IPMA_FORECAST_PATH <- file.path(DATA_DIR, "ipma_matosinhos_forecasts.csv")
OPENMETEO_FORECAST_PATH <- file.path(
  DATA_DIR,
  "openmeteo_matosinhos_forecasts.csv"
)
MUNICIPALITY_TEMPERATURE_PATH <- file.path(
  DATA_DIR,
  "ipma_matosinhos_temperaturas.csv"
)
STATION_OBSERVATIONS_PATH <- file.path(
  DATA_DIR,
  "ipma_matosinhos_station_observations.csv"
)
STATION_DAILY_PATH <- file.path(
  DATA_DIR,
  "ipma_matosinhos_station_daily_temperatures.csv"
)

OBSERVATION_REFERENCES_PATH <- file.path(
  DATA_DIR,
  "temperature_observation_references.csv"
)
PAIRED_COMPARISON_PATH <- file.path(
  DATA_DIR,
  "temperature_forecast_comparison_paired.csv"
)
COMPARISON_SUMMARY_PATH <- file.path(
  DATA_DIR,
  "temperature_forecast_comparison_summary.csv"
)

LOCAL_TIMEZONE <- "Europe/Lisbon"
MIN_COMPLETE_HOURLY_OBSERVATIONS <- 20L
WINNER_TOLERANCE_C <- 0.05

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

to_num <- function(value) {
  suppressWarnings(as.numeric(value))
}

round_num <- function(value, digits = 3) {
  ifelse(is.na(value), NA_real_, round(value, digits))
}

latest_text_timestamp <- function(...) {
  values <- list(...)
  values <- lapply(values, function(value) {
    value <- as.character(value)
    value[is.na(value)] <- ""
    value
  })
  do.call(pmax, c(values, list(na.rm = TRUE)))
}

parse_utc_datetime <- function(value) {
  value <- as.character(value)
  value[is.na(value) | value == ""] <- NA_character_
  value <- sub("Z$", "", value)

  parsed <- as.POSIXct(value, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
  missing <- is.na(parsed) & !is.na(value)
  parsed[missing] <- as.POSIXct(
    value[missing],
    format = "%Y-%m-%d %H:%M:%S",
    tz = "UTC"
  )
  parsed
}

format_utc_datetime <- function(value) {
  ifelse(
    is.na(value),
    "",
    format(value, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )
}

local_collection_date <- function(value) {
  parsed <- parse_utc_datetime(value)
  fallback <- substr(as.character(value), 1, 10)
  ifelse(
    is.na(parsed),
    fallback,
    format(parsed, "%Y-%m-%d", tz = LOCAL_TIMEZONE)
  )
}

collection_cycle <- function(value) {
  parsed <- parse_utc_datetime(value)
  local_hour <- suppressWarnings(as.integer(
    format(parsed, "%H", tz = LOCAL_TIMEZONE)
  ))
  ifelse(
    is.na(local_hour),
    "unknown",
    ifelse(local_hour < 14L, "morning", "afternoon")
  )
}

collapse_sorted <- function(value) {
  paste(sort(unique(as.character(value))), collapse = ";")
}

reference_label_for_station <- function(station_id, station_name) {
  paste0(station_name, " (", station_id, "), dia completo")
}

build_station_daily <- function() {
  observations <- read_character_csv(STATION_OBSERVATIONS_PATH)
  if (nrow(observations) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  observations %>%
    mutate(
      observation_date = as.Date(date_local),
      temperature_c = to_num(temperature_c),
      observation_datetime_utc = as.character(datetime_utc),
      observation_fetched_at = as.character(fetched_at)
    ) %>%
    filter(
      !is.na(observation_date),
      !is.na(temperature_c),
      observation_datetime_utc != ""
    ) %>%
    arrange(
      observation_date,
      station_id,
      observation_datetime_utc,
      observation_fetched_at
    ) %>%
    group_by(observation_date, station_id, observation_datetime_utc) %>%
    slice_tail(n = 1L) %>%
    ungroup() %>%
    group_by(observation_date, station_id, station_name) %>%
    summarise(
      hourly_observations = n_distinct(observation_datetime_utc),
      observed_tmin_c = min(temperature_c),
      observed_tmax_c = max(temperature_c),
      first_hour_utc = min(observation_datetime_utc),
      last_hour_utc = max(observation_datetime_utc),
      source_updated_at = max(observation_fetched_at),
      .groups = "drop"
    ) %>%
    mutate(
      observation_date = as.character(observation_date),
      is_complete = hourly_observations >= MIN_COMPLETE_HOURLY_OBSERVATIONS
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

municipality_references <- function() {
  history <- read_character_csv(MUNICIPALITY_TEMPERATURE_PATH)
  if (nrow(history) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  history %>%
    mutate(
      observation_date = as.Date(date),
      observed_tmin_c = to_num(tmin_c),
      observed_tmax_c = to_num(tmax_c),
      source = as.character(source),
      source_updated_at = as.character(fetched_at)
    ) %>%
    filter(
      !is.na(observation_date),
      !is.na(observed_tmin_c),
      !is.na(observed_tmax_c),
      grepl("observation/climate", source, ignore.case = TRUE)
    ) %>%
    arrange(observation_date, desc(source_updated_at)) %>%
    distinct(observation_date, .keep_all = TRUE) %>%
    transmute(
      observation_date = as.character(observation_date),
      reference_id = "ipma_municipality_grid",
      reference_label = "IPMA observado/interpolado por concelho",
      reference_role = "official_municipality_reference",
      reference_quality = "official_interpolated",
      observed_tmin_c,
      observed_tmax_c,
      station_count = NA_integer_,
      station_ids = "",
      station_names = "",
      min_hourly_observations = NA_integer_,
      source,
      source_updated_at
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

complete_station_references <- function(station_daily) {
  if (nrow(station_daily) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  station_daily %>%
    filter(is_complete) %>%
    transmute(
      observation_date,
      reference_id = paste0("station_", station_id, "_complete"),
      reference_label = reference_label_for_station(station_id, station_name),
      reference_role = "individual_station_sensitivity",
      reference_quality = "complete_station_day",
      observed_tmin_c,
      observed_tmax_c,
      station_count = 1L,
      station_ids = as.character(station_id),
      station_names = as.character(station_name),
      min_hourly_observations = as.integer(hourly_observations),
      source = "IPMA station hourly observations",
      source_updated_at
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

mean_complete_station_references <- function(station_daily) {
  if (nrow(station_daily) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  station_daily %>%
    filter(is_complete) %>%
    group_by(observation_date) %>%
    summarise(
      observed_tmin_c = mean(observed_tmin_c),
      observed_tmax_c = mean(observed_tmax_c),
      station_count = n_distinct(station_id),
      station_ids = collapse_sorted(station_id),
      station_names = collapse_sorted(station_name),
      min_hourly_observations = min(hourly_observations),
      source_updated_at = max(source_updated_at),
      .groups = "drop"
    ) %>%
    transmute(
      observation_date,
      reference_id = "mean_complete_stations",
      reference_label = "Média das estações IPMA com dia completo",
      reference_role = "primary_actual_observation",
      reference_quality = ifelse(
        station_count >= 2L,
        "two_complete_stations",
        "one_complete_station"
      ),
      observed_tmin_c,
      observed_tmax_c,
      station_count = as.integer(station_count),
      station_ids,
      station_names,
      min_hourly_observations = as.integer(min_hourly_observations),
      source = paste0(
        "IPMA station hourly observations; complete day >= ",
        MIN_COMPLETE_HOURLY_OBSERVATIONS,
        " values"
      ),
      source_updated_at
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

two_complete_station_references <- function(station_daily) {
  means <- mean_complete_station_references(station_daily)
  if (nrow(means) == 0) {
    return(means)
  }

  means %>%
    filter(station_count >= 2L) %>%
    mutate(
      reference_id = "two_complete_station_mean",
      reference_label = "Média Pedras Rubras/S. Gens, ambos os dias completos",
      reference_role = "strict_two_station_sensitivity",
      reference_quality = "two_complete_stations"
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

operational_fallback_references <- function() {
  daily <- read_character_csv(STATION_DAILY_PATH)
  if (nrow(daily) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  daily %>%
    mutate(
      observation_date = as.Date(date),
      observed_tmin_c = to_num(tmin_c),
      observed_tmax_c = to_num(tmax_c),
      station_count = suppressWarnings(as.integer(station_count)),
      min_hourly_observations = suppressWarnings(
        as.integer(min_hourly_observations)
      )
    ) %>%
    filter(
      !is.na(observation_date),
      !is.na(observed_tmin_c),
      !is.na(observed_tmax_c)
    ) %>%
    transmute(
      observation_date = as.character(observation_date),
      reference_id = "operational_station_fallback",
      reference_label = "Fallback operacional Pedras Rubras/S. Gens",
      reference_role = "operational_reference_with_incomplete_days",
      reference_quality = case_when(
        station_count >= 2L &
          min_hourly_observations >= MIN_COMPLETE_HOURLY_OBSERVATIONS ~
          "two_complete_stations",
        min_hourly_observations >= MIN_COMPLETE_HOURLY_OBSERVATIONS ~
          "one_or_more_complete_stations",
        TRUE ~ "incomplete_station_day"
      ),
      observed_tmin_c,
      observed_tmax_c,
      station_count,
      station_ids = as.character(station_ids),
      station_names = as.character(station_names),
      min_hourly_observations,
      source = as.character(source),
      source_updated_at = as.character(fetched_at)
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

build_observation_references <- function() {
  station_daily <- build_station_daily()

  bind_rows(
    municipality_references(),
    mean_complete_station_references(station_daily),
    two_complete_station_references(station_daily),
    complete_station_references(station_daily),
    operational_fallback_references()
  ) %>%
    filter(
      !is.na(observation_date),
      !is.na(observed_tmin_c),
      !is.na(observed_tmax_c)
    ) %>%
    arrange(observation_date, reference_id) %>%
    distinct(observation_date, reference_id, .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

prepare_ipma_forecasts <- function() {
  forecasts <- read_character_csv(IPMA_FORECAST_PATH)
  if (nrow(forecasts) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  forecasts %>%
    mutate(
      snapshot_at_utc = parse_utc_datetime(fetched_at),
      collection_date = local_collection_date(fetched_at),
      issue_cycle = collection_cycle(fetched_at),
      target_date_as_date = as.Date(forecast_date),
      collection_date_as_date = as.Date(collection_date),
      horizon_days = as.integer(target_date_as_date - collection_date_as_date),
      forecast_tmin_c = to_num(tmin_c),
      forecast_tmax_c = to_num(tmax_c)
    ) %>%
    filter(
      period_type == "daily",
      !is.na(target_date_as_date),
      !is.na(collection_date_as_date),
      horizon_days >= 0L,
      !is.na(forecast_tmin_c),
      !is.na(forecast_tmax_c)
    ) %>%
    arrange(
      collection_date,
      issue_cycle,
      target_date_as_date,
      snapshot_at_utc
    ) %>%
    group_by(collection_date, issue_cycle, target_date_as_date, horizon_days) %>%
    slice_tail(n = 1L) %>%
    ungroup() %>%
    transmute(
      collection_date,
      issue_cycle,
      target_date = as.character(target_date_as_date),
      horizon_days,
      ipma_snapshot_at_utc = format_utc_datetime(snapshot_at_utc),
      ipma_product_updated_at = as.character(source_updated_at),
      ipma_tmin_c = forecast_tmin_c,
      ipma_tmax_c = forecast_tmax_c
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

prepare_openmeteo_forecasts <- function() {
  forecasts <- read_character_csv(OPENMETEO_FORECAST_PATH)
  if (nrow(forecasts) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  forecasts %>%
    mutate(
      snapshot_at_utc = parse_utc_datetime(fetched_at),
      collection_date = local_collection_date(fetched_at),
      issue_cycle = collection_cycle(fetched_at),
      target_date_as_date = as.Date(forecast_date),
      collection_date_as_date = as.Date(collection_date),
      horizon_days = as.integer(target_date_as_date - collection_date_as_date),
      forecast_tmin_c = to_num(temperature_2m_min_c),
      forecast_tmax_c = to_num(temperature_2m_max_c)
    ) %>%
    filter(
      !is.na(target_date_as_date),
      !is.na(collection_date_as_date),
      horizon_days >= 0L,
      !is.na(forecast_tmin_c),
      !is.na(forecast_tmax_c)
    ) %>%
    arrange(
      collection_date,
      issue_cycle,
      target_date_as_date,
      snapshot_at_utc
    ) %>%
    group_by(collection_date, issue_cycle, target_date_as_date, horizon_days) %>%
    slice_tail(n = 1L) %>%
    ungroup() %>%
    transmute(
      collection_date,
      issue_cycle,
      target_date = as.character(target_date_as_date),
      horizon_days,
      openmeteo_snapshot_at_utc = format_utc_datetime(snapshot_at_utc),
      openmeteo_product = as.character(model),
      openmeteo_tmin_c = forecast_tmin_c,
      openmeteo_tmax_c = forecast_tmax_c
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

winner_from_errors <- function(ipma_error, openmeteo_error) {
  difference <- abs(ipma_error) - abs(openmeteo_error)
  case_when(
    is.na(difference) ~ "not_available",
    abs(difference) <= WINNER_TOLERANCE_C ~ "tie",
    difference < 0 ~ "ipma",
    TRUE ~ "openmeteo"
  )
}

observed_tmax_band <- function(value) {
  case_when(
    is.na(value) ~ "not_available",
    value < 25 ~ "<25",
    value < 30 ~ "25-29.9",
    TRUE ~ ">=30"
  )
}

build_paired_comparison <- function(ipma, openmeteo, references) {
  if (nrow(ipma) == 0 || nrow(openmeteo) == 0 || nrow(references) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  paired_forecasts <- inner_join(
    ipma,
    openmeteo,
    by = c(
      "collection_date",
      "issue_cycle",
      "target_date",
      "horizon_days"
    )
  )

  inner_join(
    paired_forecasts,
    references,
    by = c("target_date" = "observation_date"),
    relationship = "many-to-many"
  ) %>%
    mutate(
      horizon_label = paste0("D+", horizon_days),
      target_month = substr(target_date, 1, 7),
      observed_tmax_band = observed_tmax_band(observed_tmax_c),
      ipma_error_tmin_c = ipma_tmin_c - observed_tmin_c,
      openmeteo_error_tmin_c = openmeteo_tmin_c - observed_tmin_c,
      ipma_abs_error_tmin_c = abs(ipma_error_tmin_c),
      openmeteo_abs_error_tmin_c = abs(openmeteo_error_tmin_c),
      tmin_winner = winner_from_errors(
        ipma_error_tmin_c,
        openmeteo_error_tmin_c
      ),
      ipma_error_tmax_c = ipma_tmax_c - observed_tmax_c,
      openmeteo_error_tmax_c = openmeteo_tmax_c - observed_tmax_c,
      ipma_abs_error_tmax_c = abs(ipma_error_tmax_c),
      openmeteo_abs_error_tmax_c = abs(openmeteo_error_tmax_c),
      tmax_winner = winner_from_errors(
        ipma_error_tmax_c,
        openmeteo_error_tmax_c
      ),
      forecast_difference_tmin_c = ipma_tmin_c - openmeteo_tmin_c,
      forecast_difference_tmax_c = ipma_tmax_c - openmeteo_tmax_c,
      calculated_at = latest_text_timestamp(
        ipma_snapshot_at_utc,
        openmeteo_snapshot_at_utc,
        source_updated_at
      )
    ) %>%
    select(
      collection_date,
      issue_cycle,
      target_date,
      target_month,
      horizon_days,
      horizon_label,
      reference_id,
      reference_label,
      reference_role,
      reference_quality,
      station_count,
      station_ids,
      station_names,
      min_hourly_observations,
      observed_tmax_band,
      observed_tmin_c,
      observed_tmax_c,
      ipma_snapshot_at_utc,
      ipma_product_updated_at,
      ipma_tmin_c,
      ipma_tmax_c,
      openmeteo_snapshot_at_utc,
      openmeteo_product,
      openmeteo_tmin_c,
      openmeteo_tmax_c,
      forecast_difference_tmin_c,
      forecast_difference_tmax_c,
      ipma_error_tmin_c,
      openmeteo_error_tmin_c,
      ipma_abs_error_tmin_c,
      openmeteo_abs_error_tmin_c,
      tmin_winner,
      ipma_error_tmax_c,
      openmeteo_error_tmax_c,
      ipma_abs_error_tmax_c,
      openmeteo_abs_error_tmax_c,
      tmax_winner,
      source,
      source_updated_at,
      calculated_at
    ) %>%
    arrange(
      reference_id,
      collection_date,
      issue_cycle,
      target_date
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

bias_confidence_limit <- function(errors, side = c("lower", "upper")) {
  side <- match.arg(side)
  errors <- errors[!is.na(errors)]
  if (length(errors) < 2L) {
    return(NA_real_)
  }

  margin <- qt(0.975, df = length(errors) - 1L) *
    sd(errors) / sqrt(length(errors))
  if (side == "lower") {
    mean(errors) - margin
  } else {
    mean(errors) + margin
  }
}

correlation_or_na <- function(forecast, observed) {
  complete <- !is.na(forecast) & !is.na(observed)
  if (sum(complete) < 3L ||
      sd(forecast[complete]) == 0 ||
      sd(observed[complete]) == 0) {
    return(NA_real_)
  }
  cor(forecast[complete], observed[complete])
}

metric_frame <- function(paired, metric) {
  suffix <- if (metric == "tmin") "tmin" else "tmax"

  paired %>%
    transmute(
      reference_id,
      reference_label,
      reference_role,
      reference_quality,
      collection_date,
      issue_cycle,
      target_date,
      target_month,
      horizon_days,
      horizon_label,
      observed_tmax_band,
      calculated_at,
      metric = metric,
      observed_c = .data[[paste0("observed_", suffix, "_c")]],
      ipma_forecast_c = .data[[paste0("ipma_", suffix, "_c")]],
      openmeteo_forecast_c = .data[[paste0("openmeteo_", suffix, "_c")]],
      ipma_error_c = .data[[paste0("ipma_error_", suffix, "_c")]],
      openmeteo_error_c =
        .data[[paste0("openmeteo_error_", suffix, "_c")]],
      winner = .data[[paste0(suffix, "_winner")]]
    ) %>%
    filter(
      !is.na(observed_c),
      !is.na(ipma_forecast_c),
      !is.na(openmeteo_forecast_c)
    )
}

summarise_metric <- function(metric_data, scope, segment_column = NULL) {
  grouping <- c(
    "reference_id",
    "reference_label",
    "reference_role",
    "issue_cycle",
    "metric",
    "horizon_days",
    "horizon_label"
  )

  if (!is.null(segment_column)) {
    metric_data <- metric_data %>%
      mutate(segment = as.character(.data[[segment_column]]))
    grouping <- c(grouping, "segment")
  } else {
    metric_data$segment <- "all"
    grouping <- c(grouping, "segment")
  }

  metric_data %>%
    group_by(across(all_of(grouping))) %>%
    summarise(
      n = n(),
      high_quality_n = sum(
        reference_quality %in% c(
          "official_interpolated",
          "two_complete_stations",
          "one_complete_station",
          "complete_station_day"
        )
      ),
      first_collection_date = min(collection_date),
      last_collection_date = max(collection_date),
      first_target_date = min(target_date),
      last_target_date = max(target_date),
      calculated_at = max(calculated_at),
      observed_mean_c = mean(observed_c),
      ipma_mean_forecast_c = mean(ipma_forecast_c),
      openmeteo_mean_forecast_c = mean(openmeteo_forecast_c),
      ipma_bias_c = mean(ipma_error_c),
      ipma_bias_ci95_low_c = bias_confidence_limit(ipma_error_c, "lower"),
      ipma_bias_ci95_high_c = bias_confidence_limit(ipma_error_c, "upper"),
      ipma_mae_c = mean(abs(ipma_error_c)),
      ipma_rmse_c = sqrt(mean(ipma_error_c^2)),
      ipma_p90_abs_error_c = as.numeric(
        quantile(abs(ipma_error_c), 0.9, names = FALSE)
      ),
      ipma_correlation = correlation_or_na(ipma_forecast_c, observed_c),
      openmeteo_bias_c = mean(openmeteo_error_c),
      openmeteo_bias_ci95_low_c =
        bias_confidence_limit(openmeteo_error_c, "lower"),
      openmeteo_bias_ci95_high_c =
        bias_confidence_limit(openmeteo_error_c, "upper"),
      openmeteo_mae_c = mean(abs(openmeteo_error_c)),
      openmeteo_rmse_c = sqrt(mean(openmeteo_error_c^2)),
      openmeteo_p90_abs_error_c = as.numeric(
        quantile(abs(openmeteo_error_c), 0.9, names = FALSE)
      ),
      openmeteo_correlation =
        correlation_or_na(openmeteo_forecast_c, observed_c),
      ipma_better_n = sum(winner == "ipma"),
      openmeteo_better_n = sum(winner == "openmeteo"),
      tie_n = sum(winner == "tie"),
      .groups = "drop"
    ) %>%
    mutate(
      scope = scope,
      ipma_minus_openmeteo_mae_c = ipma_mae_c - openmeteo_mae_c,
      ipma_better_percent = 100 * ipma_better_n / n,
      openmeteo_better_percent = 100 * openmeteo_better_n / n,
      tie_percent = 100 * tie_n / n,
      sample_status = case_when(
        n < 10L ~ "insufficient",
        n < 30L ~ "limited",
        n < 60L ~ "preliminary",
        TRUE ~ "more_stable"
      ),
      ipma_bias_signal = case_when(
        ipma_bias_ci95_high_c < 0 ~ "systematic_underforecast",
        ipma_bias_ci95_low_c > 0 ~ "systematic_overforecast",
        TRUE ~ "inconclusive"
      ),
      openmeteo_bias_signal = case_when(
        openmeteo_bias_ci95_high_c < 0 ~ "systematic_underforecast",
        openmeteo_bias_ci95_low_c > 0 ~ "systematic_overforecast",
        TRUE ~ "inconclusive"
      )
    ) %>%
    select(
      scope,
      segment,
      reference_id,
      reference_label,
      reference_role,
      issue_cycle,
      metric,
      horizon_days,
      horizon_label,
      n,
      high_quality_n,
      sample_status,
      first_collection_date,
      last_collection_date,
      first_target_date,
      last_target_date,
      observed_mean_c,
      ipma_mean_forecast_c,
      openmeteo_mean_forecast_c,
      ipma_bias_c,
      ipma_bias_ci95_low_c,
      ipma_bias_ci95_high_c,
      ipma_bias_signal,
      ipma_mae_c,
      ipma_rmse_c,
      ipma_p90_abs_error_c,
      ipma_correlation,
      openmeteo_bias_c,
      openmeteo_bias_ci95_low_c,
      openmeteo_bias_ci95_high_c,
      openmeteo_bias_signal,
      openmeteo_mae_c,
      openmeteo_rmse_c,
      openmeteo_p90_abs_error_c,
      openmeteo_correlation,
      ipma_minus_openmeteo_mae_c,
      ipma_better_n,
      openmeteo_better_n,
      tie_n,
      ipma_better_percent,
      openmeteo_better_percent,
      tie_percent,
      calculated_at
    ) %>%
    mutate(
      across(
        where(is.numeric) & !matches("^(horizon_days|n|.*_n)$"),
        ~ round_num(.x)
      )
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

build_comparison_summary <- function(paired) {
  if (nrow(paired) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  metrics <- bind_rows(
    metric_frame(paired, "tmin"),
    metric_frame(paired, "tmax")
  )

  bind_rows(
    summarise_metric(metrics, "cycle_horizon"),
    summarise_metric(metrics, "target_month", "target_month"),
    summarise_metric(
      filter(metrics, metric == "tmax"),
      "observed_tmax_band",
      "observed_tmax_band"
    )
  ) %>%
    arrange(
      reference_id,
      metric,
      issue_cycle,
      horizon_days,
      scope,
      segment
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

write_output <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write_csv(data, path, na = "")
}

evaluate_temperature_forecasts <- function() {
  references <- build_observation_references()
  write_output(references, OBSERVATION_REFERENCES_PATH)

  ipma <- prepare_ipma_forecasts()
  openmeteo <- prepare_openmeteo_forecasts()
  paired <- build_paired_comparison(ipma, openmeteo, references)
  summary <- build_comparison_summary(paired)

  write_output(paired, PAIRED_COMPARISON_PATH)
  write_output(summary, COMPARISON_SUMMARY_PATH)

  message(sprintf(
    paste0(
      "Temperature forecast comparison updated: ",
      "%d observation references, %d paired rows and %d summary rows."
    ),
    nrow(references),
    nrow(paired),
    nrow(summary)
  ))
}

if (sys.nframe() == 0L) {
  evaluate_temperature_forecasts()
}
