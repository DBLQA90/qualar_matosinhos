source("report_summary.R", encoding = "UTF-8")

expect_true <- function(value, message) {
  if (!isTRUE(value)) {
    stop(message, call. = FALSE)
  }
}

temp_dir <- tempfile("report-monitoring-")
dir.create(temp_dir, recursive = TRUE)
snapshot_path <- file.path(temp_dir, "snapshots.csv")
status_path <- file.path(temp_dir, "status.csv")
station_path <- file.path(temp_dir, "stations.csv")

previous_model <- summary_build_operational_model(
  "2026-07-27",
  signals = list(summary_signal(
    "Qualidade do ar",
    today = "Verde (0)",
    future = "Amanhã: Amarelo (1)",
    driver = "sem poluentes acima de Verde",
    today_order = 0,
    future_order = 1,
    horizon = "Qualidade do ar: previsto em 28/07"
  ))
)
rsm_write_snapshot(
  previous_model,
  cycle_id = "2026-07-27-morning",
  generated_at = as.POSIXct("2026-07-27 09:00:00", tz = "UTC"),
  snapshot_path = snapshot_path
)

registry <- rsm_source_registry()
status_fixture <- data.frame(
  cycle_id = "2026-07-27-afternoon",
  local_date = "2026-07-27",
  phase = "data",
  source = registry$source,
  status = "ok",
  started_at_utc = "2026-07-27T14:35:00Z",
  completed_at_utc = "2026-07-27T14:40:00Z",
  exit_code = "0",
  message = ifelse(
    registry$source == "Temperatura percentil ERA5-Land",
    "SKIP ERA5-Land percentile alerts - percentile file is not available.",
    "OK"
  ),
  stringsAsFactors = FALSE
)
readr::write_csv(status_fixture, status_path)

station_fixture <- do.call(rbind, lapply(
  c("1200545", "1210649"),
  function(station_id) {
    data.frame(
      date_local = "2026-07-26",
      station_id = station_id,
      datetime_utc = paste0(
        "2026-07-26T",
        sprintf("%02d", 0:19),
        ":00:00Z"
      ),
      stringsAsFactors = FALSE
    )
  }
))
readr::write_csv(station_fixture, station_path)

current_model <- summary_build_operational_model(
  "2026-07-27",
  signals = list(summary_signal(
    "Qualidade do ar",
    today = "Verde (0)",
    future = "Amanhã: Laranja (2)",
    driver = "sem poluentes acima de Verde",
    today_order = 0,
    future_order = 2,
    horizon = "Qualidade do ar: pico em 28/07"
  ))
)
current_model <- rsm_attach_report_context(
  current_model,
  cycle_id = "2026-07-27-afternoon",
  generated_at = as.POSIXct("2026-07-27 15:00:00", tz = "UTC"),
  snapshot_path = snapshot_path,
  status_path = status_path,
  station_path = station_path
)

expect_true(
  identical(
    current_model$changes_heading,
    "### Alterações desde o boletim das 10:00"
  ),
  "The change section must identify the previous edition."
)
expect_true(
  any(grepl(
    "Qualidade do ar.*previsão.*Amarelo.*Laranja",
    current_model$change_lines
  )),
  "A forecast class change must be shown explicitly."
)
expect_true(
  grepl("7/7 fontes externas atualizadas", current_model$source_quality$banner) &&
    grepl("2/2 estações", current_model$source_quality$banner),
  "The compact data banner must show source and station coverage."
)
expect_true(
  current_model$source_quality$rows$state[
    current_model$source_quality$rows$source ==
      "Temperatura percentil ERA5-Land"
  ] == "skipped",
  "A deliberately skipped processing step must not be presented as updated."
)

status_fixture$completed_at_utc[
  status_fixture$source == "QualAr"
] <- "2026-07-27T08:00:00Z"
readr::write_csv(status_fixture, status_path)
stale_quality <- rsm_source_quality(
  "2026-07-27",
  generated_at = as.POSIXct("2026-07-27 15:00:00", tz = "UTC"),
  status_path = status_path,
  station_path = station_path
)
expect_true(
  grepl("6/7 fontes externas atualizadas", stale_quality$banner) &&
    stale_quality$rows$state[
      stale_quality$rows$source == "QualAr"
    ] == "stale",
  "A source from the previous cycle must be marked as stale."
)

unlink(temp_dir, recursive = TRUE)
cat("Report monitoring tests passed.\n")
