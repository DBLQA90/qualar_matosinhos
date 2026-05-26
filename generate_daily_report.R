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
    "# Boletim diário - Matosinhos, Porto, Portugal",
    "",
    paste0("Ficheiro diário: ", report_date)
  )
}

updated <- finalize_daily_report(content, report_date)
writeLines(updated, report_path, useBytes = TRUE)

message(sprintf("OK report - generated %s.", report_path))
