LOCAL_TZ <- "Europe/Lisbon"
DAILY_DIR <- "daily"
DEFAULT_RECIPIENTS <- c(
  "diogo.almeida@ulsm.min-saude.pt",
  "marciaisabel.balazeiro@ulsm.min-saude.pt"
)

env_value <- function(name, fallback = "") {
  value <- Sys.getenv(name, unset = "")
  if (nzchar(value)) {
    value
  } else {
    fallback
  }
}

split_recipients <- function(value) {
  value <- gsub(";", ",", value)
  recipients <- trimws(strsplit(value, ",", fixed = TRUE)[[1]])
  recipients[nzchar(recipients)]
}

require_env <- function(name) {
  value <- Sys.getenv(name, unset = "")
  if (!nzchar(value)) {
    stop("Missing required environment variable: ", name, call. = FALSE)
  }
  value
}

markdown_summary <- function(report_path) {
  content <- readLines(report_path, warn = FALSE, encoding = "UTF-8")
  stop_at <- grep("^## Indicadores sem sinal", content)
  if (length(stop_at) == 0) {
    stop_at <- grep(paste0("^<!-- ", "sintese", ":end -->$"), content)
  }

  if (length(stop_at) > 0 && stop_at[[1]] > 1) {
    content <- content[seq_len(stop_at[[1]] - 1)]
  }

  content[!grepl("^<!-- .* -->$", content)]
}

write_message <- function(path, from, recipients, subject, body) {
  headers <- c(
    paste0("From: ", from),
    paste0("To: ", paste(recipients, collapse = ", ")),
    paste0("Subject: ", subject),
    "MIME-Version: 1.0",
    "Content-Type: text/plain; charset=UTF-8",
    "Content-Transfer-Encoding: 8bit"
  )

  writeLines(c(headers, "", body), path, useBytes = TRUE)
}

send_with_curl <- function(message_path, from, recipients) {
  smtp_url <- env_value("SMTP_URL")
  if (!nzchar(smtp_url)) {
    smtp_server <- require_env("SMTP_SERVER")
    smtp_port <- env_value("SMTP_PORT", "587")
    smtp_url <- paste0("smtp://", smtp_server, ":", smtp_port)
  }

  username <- require_env("SMTP_USERNAME")
  password <- require_env("SMTP_PASSWORD")

  args <- c(
    "--silent",
    "--show-error",
    "--ssl-reqd",
    "--url", smtp_url,
    "--user", paste0(username, ":", password),
    "--mail-from", from
  )

  for (recipient in recipients) {
    args <- c(args, "--mail-rcpt", recipient)
  }

  args <- c(args, "--upload-file", message_path)
  status <- system2("curl", args)
  if (!identical(status, 0L)) {
    stop("curl SMTP send failed with status ", status, call. = FALSE)
  }
}

args <- commandArgs(trailingOnly = TRUE)
report_date <- if (length(args) > 0 && nzchar(args[[1]])) {
  args[[1]]
} else {
  format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ)
}

report_path <- file.path(DAILY_DIR, paste0(report_date, ".md"))
if (!file.exists(report_path)) {
  stop("Daily report not found: ", report_path, call. = FALSE)
}

repo_url <- env_value("GITHUB_REPOSITORY_URL", "https://github.com/DBLQA90/qualar_matosinhos")
report_url <- paste0(repo_url, "/blob/main/", report_path)
recipients <- split_recipients(env_value("MAIL_TO", paste(DEFAULT_RECIPIENTS, collapse = ",")))
if (length(recipients) == 0) {
  stop("No email recipients configured.", call. = FALSE)
}

from <- env_value("MAIL_FROM", env_value("SMTP_USERNAME"))
if (!nzchar(from) && env_value("DRY_RUN") != "1") {
  stop("MAIL_FROM or SMTP_USERNAME must be configured.", call. = FALSE)
}
if (!nzchar(from)) {
  from <- "pnprss-matosinhos@example.invalid"
}

subject <- env_value("MAIL_SUBJECT", paste0("PNPRSS Matosinhos | ", report_date))
body <- c(
  markdown_summary(report_path),
  "",
  paste0("Relatório completo: ", report_url)
)

message_file <- tempfile("pnprss-email-", fileext = ".eml")
write_message(message_file, from, recipients, subject, body)

if (env_value("DRY_RUN") == "1") {
  cat(readLines(message_file, warn = FALSE, encoding = "UTF-8"), sep = "\n")
  cat("\n")
} else {
  send_with_curl(message_file, from, recipients)
  message(sprintf("OK email - sent %s to %s.", report_path, paste(recipients, collapse = ", ")))
}
