source("derive_tropical_nights.R", encoding = "UTF-8")

expect_tn <- function(actual, expected, label) {
  if (!identical(actual, expected)) {
    stop(
      sprintf("%s\nExpected: %s\nActual: %s", label, expected, actual),
      call. = FALSE
    )
  }
}

history <- data.frame(
  date = c("2026-07-24", "2026-07-25"),
  tmin_c = c("19.9", "20.5"),
  source = c("IPMA observation", "IPMA observation"),
  fetched_at = c("2026-07-25T10:00:00Z", "2026-07-26T10:00:00Z"),
  stringsAsFactors = FALSE
)
forecast <- data.frame(
  source_updated_at = c(
    "2026-07-26T08:00:00",
    "2026-07-26T08:00:00"
  ),
  forecast_date = c("2026-07-26", "2026-07-27"),
  period_hours = c("24", "24"),
  tmin_c = c("21.0", "19.0"),
  stringsAsFactors = FALSE
)

observed_rows <- tn_prepare_observed(history)
forecast_rows <- tn_prepare_forecast(forecast)
combined <- tn_add_sequence_metadata(bind_rows(observed_rows, forecast_rows))

day_24 <- combined[combined$target_date == "2026-07-24", , drop = FALSE]
day_25 <- combined[combined$target_date == "2026-07-25", , drop = FALSE]
day_26 <- combined[combined$target_date == "2026-07-26", , drop = FALSE]
day_27 <- combined[combined$target_date == "2026-07-27", , drop = FALSE]

expect_tn(
  day_24$tropical_night,
  "FALSE",
  "A minimum below 20 ºC must not be a tropical night."
)
expect_tn(
  day_25$tropical_night,
  "TRUE",
  "A minimum equal to or above 20 ºC must be a tropical night."
)
expect_tn(
  day_25$sequence_length,
  "2",
  "Consecutive observed and forecast tropical nights must form one sequence."
)
expect_tn(
  day_26$observed_nights_in_sequence,
  "1",
  "The sequence must retain its observed component."
)
expect_tn(
  day_26$forecast_nights_in_sequence,
  "1",
  "The sequence must retain its forecast component."
)
expect_tn(
  day_27$signal_level_order,
  "0",
  "A forecast minimum below the threshold must have no tropical-night signal."
)

cat("OK tropical-night derivation tests\n")
