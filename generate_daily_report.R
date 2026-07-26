source("report_summary.R", encoding = "UTF-8")

LOCAL_TZ <- "Europe/Lisbon"
DAILY_DIR <- "daily"

args <- commandArgs(trailingOnly = TRUE)
report_date <- if (length(args) > 0 && nzchar(args[[1]])) {
  args[[1]]
} else {
  format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ)
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
updated <- finalize_daily_report(content, report_date, model)
writeLines(updated, report_path, useBytes = TRUE)
quick_report_path <- write_quick_daily_report(report_date, model)

message(sprintf(
  "OK report - generated %s and %s.",
  report_path,
  quick_report_path
))
