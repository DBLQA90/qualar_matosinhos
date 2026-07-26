suppressPackageStartupMessages({
  library(dplyr)
})

source("evaluate_temperature_forecasts.R")

ipma <- data.frame(
  collection_date = c("2026-07-01", "2026-07-01"),
  issue_cycle = c("morning", "morning"),
  target_date = c("2026-07-01", "2026-07-02"),
  horizon_days = c(0L, 1L),
  ipma_snapshot_at_utc = c(
    "2026-07-01T09:30:00Z",
    "2026-07-01T09:30:00Z"
  ),
  ipma_product_updated_at = c(
    "2026-07-01T08:00:00",
    "2026-07-01T08:00:00"
  ),
  ipma_tmin_c = c(19, 20),
  ipma_tmax_c = c(29, 28),
  stringsAsFactors = FALSE
)

openmeteo <- data.frame(
  collection_date = c("2026-07-01", "2026-07-01"),
  issue_cycle = c("morning", "morning"),
  target_date = c("2026-07-01", "2026-07-02"),
  horizon_days = c(0L, 1L),
  openmeteo_snapshot_at_utc = c(
    "2026-07-01T09:31:00Z",
    "2026-07-01T09:31:00Z"
  ),
  openmeteo_product = c("best_match", "best_match"),
  openmeteo_tmin_c = c(18, 21),
  openmeteo_tmax_c = c(31, 29.5),
  stringsAsFactors = FALSE
)

references <- data.frame(
  observation_date = c("2026-07-01", "2026-07-02"),
  reference_id = c("test_reference", "test_reference"),
  reference_label = c("Test reference", "Test reference"),
  reference_role = c("test", "test"),
  reference_quality = c("complete_station_day", "complete_station_day"),
  observed_tmin_c = c(18, 20),
  observed_tmax_c = c(30, 30),
  station_count = c(1L, 1L),
  station_ids = c("1", "1"),
  station_names = c("Test", "Test"),
  min_hourly_observations = c(24L, 24L),
  source = c("Test", "Test"),
  source_updated_at = c(
    "2026-07-02T00:00:00Z",
    "2026-07-03T00:00:00Z"
  ),
  stringsAsFactors = FALSE
)

paired <- build_paired_comparison(ipma, openmeteo, references)
stopifnot(nrow(paired) == 2L)
stopifnot(paired$ipma_error_tmax_c[[1]] == -1)
stopifnot(paired$openmeteo_error_tmax_c[[1]] == 1)
stopifnot(paired$tmax_winner[[1]] == "tie")
stopifnot(paired$tmax_winner[[2]] == "openmeteo")
stopifnot(paired$tmin_winner[[1]] == "openmeteo")
stopifnot(paired$tmin_winner[[2]] == "ipma")

summary <- build_comparison_summary(paired)
tmax_d1 <- summary %>%
  filter(
    scope == "cycle_horizon",
    metric == "tmax",
    issue_cycle == "morning",
    horizon_days == 1L
  )

stopifnot(nrow(tmax_d1) == 1L)
stopifnot(tmax_d1$ipma_bias_c[[1]] == -2)
stopifnot(tmax_d1$openmeteo_bias_c[[1]] == -0.5)
stopifnot(tmax_d1$ipma_minus_openmeteo_mae_c[[1]] == 1.5)
stopifnot(tmax_d1$openmeteo_better_n[[1]] == 1L)

cat("Temperature forecast comparison tests passed.\n")
