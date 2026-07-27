source("report_summary.R", encoding = "UTF-8")

LOCAL_TZ <- "Europe/Lisbon"
DAILY_DIR <- "daily"

args <- commandArgs(trailingOnly = TRUE)
generated_at <- Sys.time()
report_date <- if (length(args) > 0 && nzchar(args[[1]])) {
  args[[1]]
} else {
  format(generated_at, "%Y-%m-%d", tz = LOCAL_TZ)
}
cycle_id <- if (length(args) > 1 && nzchar(args[[2]])) {
  args[[2]]
} else {
  paste0(
    report_date,
    "-manual-",
    format(generated_at, "%H%M%S", tz = LOCAL_TZ)
  )
}

dir.create(DAILY_DIR, showWarnings = FALSE, recursive = TRUE)
report_path <- file.path(DAILY_DIR, paste0(report_date, ".md"))

content <- if (file.exists(report_path)) {
  readLines(report_path, warn = FALSE, encoding = "UTF-8")
} else {
  c(
    summary_report_title(report_date)
  )
}

model <- summary_build_operational_model(report_date)
model <- rsm_attach_report_context(
  model,
  cycle_id = cycle_id,
  generated_at = generated_at
)
updated <- finalize_daily_report(content, report_date, model)
writeLines(updated, report_path, useBytes = TRUE)
quick_report_path <- write_quick_daily_report(report_date, model)

if (report_date == format(generated_at, "%Y-%m-%d", tz = LOCAL_TZ)) {
  tryCatch(
    rsm_write_snapshot(
      model,
      cycle_id = cycle_id,
      generated_at = generated_at
    ),
    error = function(error) {
      warning(
        "Report generated, but signal snapshot could not be saved: ",
        conditionMessage(error),
        call. = FALSE
      )
    }
  )
}

message(sprintf(
  "OK report - generated %s and %s.",
  report_path,
  quick_report_path
))
