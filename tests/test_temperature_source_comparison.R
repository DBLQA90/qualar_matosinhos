source("temperature_source_comparison.R")

expect_true <- function(value, message) {
  if (!isTRUE(value)) {
    stop(message, call. = FALSE)
  }
}

expect_identical <- function(actual, expected, message) {
  if (!identical(actual, expected)) {
    stop(message, call. = FALSE)
  }
}

# Os patamares da regra DSP são testados em tests/test_dsp_rules.R. Aqui só se
# verifica que estes wrappers delegam no módulo partilhado, sem regra própria.
expect_identical(
  tsc_dsp_classify_tmax(as.Date("2026-07-26"), c(30, 31, 33), c(34, 34)),
  dsp_classify_tmax(as.Date("2026-07-26"), c(30, 31, 33), c(34, 34)),
  "The maximum wrapper must delegate to the shared DSP module."
)

expect_identical(
  tsc_dsp_classify_tmin(as.Date("2026-07-26"), c(23, 23), c(23, 23)),
  dsp_classify_tmin(as.Date("2026-07-26"), c(23, 23), c(23, 23)),
  "The minimum wrapper must delegate to the shared DSP module."
)

expect_identical(
  as.integer(tsc_contiguous_lengths(c(FALSE, TRUE, TRUE, FALSE, TRUE))),
  c(0L, 2L, 2L, 0L, 1L),
  "Thermal sequences must remain contiguous."
)

fixture_dir <- tempfile("temperature-source-comparison-")
dir.create(fixture_dir, recursive = TRUE)
old_paths <- c(
  TSC_IPMA_FORECAST_PATH,
  TSC_OPENMETEO_FORECAST_PATH,
  TSC_TEMPERATURE_HISTORY_PATH,
  TSC_STATION_OBSERVATIONS_PATH
)
on.exit({
  TSC_IPMA_FORECAST_PATH <<- old_paths[[1]]
  TSC_OPENMETEO_FORECAST_PATH <<- old_paths[[2]]
  TSC_TEMPERATURE_HISTORY_PATH <<- old_paths[[3]]
  TSC_STATION_OBSERVATIONS_PATH <<- old_paths[[4]]
}, add = TRUE)

TSC_IPMA_FORECAST_PATH <- file.path(fixture_dir, "ipma.csv")
TSC_OPENMETEO_FORECAST_PATH <- file.path(fixture_dir, "openmeteo.csv")
TSC_TEMPERATURE_HISTORY_PATH <- file.path(fixture_dir, "history.csv")
TSC_STATION_OBSERVATIONS_PATH <- file.path(fixture_dir, "stations.csv")

write.csv(data.frame(
  period_type = c("daily", "daily"),
  forecast_date = c("2026-07-26", "2026-07-27"),
  tmin_c = c(18, 18),
  tmax_c = c(32, 32),
  source_updated_at = c(
    "2026-07-26T08:00:00",
    "2026-07-26T08:00:00"
  ),
  fetched_at = c(
    "2026-07-26T09:30:00Z",
    "2026-07-26T09:30:00Z"
  )
), TSC_IPMA_FORECAST_PATH, row.names = FALSE)

write.csv(data.frame(
  forecast_date = c("2026-07-26", "2026-07-27"),
  temperature_2m_min_c = c(21, 21),
  temperature_2m_max_c = c(34, 34),
  source_updated_at = c(
    "2026-07-26T09:31:00Z",
    "2026-07-26T09:31:00Z"
  ),
  fetched_at = c(
    "2026-07-26T09:31:00Z",
    "2026-07-26T09:31:00Z"
  ),
  model = c("best_match", "best_match")
), TSC_OPENMETEO_FORECAST_PATH, row.names = FALSE)

write.csv(data.frame(
  date = c("2026-07-23", "2026-07-24", "2026-07-25"),
  tmin_c = c(18, 18, 18),
  tmax_c = c(30, 31, 33),
  source = c("test", "test", "test"),
  fetched_at = c(
    "2026-07-24T00:00:00Z",
    "2026-07-25T00:00:00Z",
    "2026-07-26T00:00:00Z"
  )
), TSC_TEMPERATURE_HISTORY_PATH, row.names = FALSE)

comparison <- tsc_dsp_comparison("2026-07-26")
expect_true(
  identical(comparison$overall_alert[comparison$source_id == "ipma"], "Verde"),
  "The IPMA fixture must remain green."
)
expect_true(
  identical(
    comparison$overall_alert[comparison$source_id == "openmeteo"],
    "Amarelo"
  ),
  "The Open-Meteo fixture must independently trigger a yellow DSP signal."
)

out_of_season <- tsc_dsp_comparison("2026-11-26")
expect_true(
  all(out_of_season$overall_alert == "Fora de época"),
  "Outside May-October the aggregated DSP signal must stay out of season, not missing data."
)
expect_true(
  all(out_of_season$overall_alert_level == -2),
  "Out of season must keep a code distinct from missing data all the way to the report."
)

tropical <- tsc_tropical_nights("2026-07-26")
expect_true(
  any(
    tropical$source_id == "openmeteo" &
      tropical$tropical_night
  ),
  "Open-Meteo tropical-night signals must be preserved independently."
)
expect_true(
  !any(
    tropical$source_id == "ipma" &
      tropical$tropical_night
  ),
  "An Open-Meteo signal must not be copied to IPMA."
)

cat("Temperature source comparison tests passed.\n")
