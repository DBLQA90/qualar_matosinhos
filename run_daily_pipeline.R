DATA_DIR <- "data"
STATUS_ARCHIVE_PATH <- file.path(DATA_DIR, "pipeline_source_status.csv")
STATUS_LATEST_PATH <- file.path(DATA_DIR, "pipeline_source_status_latest.csv")
LOCAL_TZ <- "Europe/Lisbon"

STATUS_COLUMNS <- c(
  "cycle_id",
  "local_date",
  "phase",
  "source",
  "status",
  "started_at_utc",
  "completed_at_utc",
  "exit_code",
  "message"
)

empty_status <- function() {
  out <- as.data.frame(
    matrix(character(), nrow = 0, ncol = length(STATUS_COLUMNS)),
    stringsAsFactors = FALSE
  )
  names(out) <- STATUS_COLUMNS
  out
}

read_status <- function(path) {
  if (!file.exists(path)) {
    return(empty_status())
  }

  out <- read.csv(path, stringsAsFactors = FALSE, colClasses = "character")
  missing_columns <- setdiff(STATUS_COLUMNS, names(out))
  for (column in missing_columns) {
    out[[column]] <- ""
  }
  out <- out[, STATUS_COLUMNS, drop = FALSE]
  out[] <- lapply(out, function(column) {
    column <- as.character(column)
    column[is.na(column)] <- ""
    column
  })
  out
}

write_status <- function(rows, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  write.csv(rows[, STATUS_COLUMNS, drop = FALSE], path, row.names = FALSE, na = "")
}

utc_now <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

local_today <- function() {
  format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ)
}

compact_message <- function(lines) {
  lines <- as.character(lines)
  lines <- lines[!is.na(lines) & nzchar(lines)]
  if (length(lines) == 0) {
    return("")
  }

  text <- paste(lines, collapse = " | ")
  gsub("[[:space:]]+", " ", text)
}

run_step <- function(cycle_id, phase, source, command, args = character()) {
  started_at <- utc_now()
  stdout_file <- tempfile("pipeline-stdout-")
  stderr_file <- tempfile("pipeline-stderr-")
  on.exit(unlink(c(stdout_file, stderr_file)), add = TRUE)

  status <- tryCatch(
    system2(command, args, stdout = stdout_file, stderr = stderr_file),
    error = function(error) {
      attr(error, "exit_code") <- "error"
      error
    }
  )

  completed_at <- utc_now()
  output <- c(
    if (file.exists(stdout_file)) readLines(stdout_file, warn = FALSE, encoding = "UTF-8") else character(),
    if (file.exists(stderr_file)) readLines(stderr_file, warn = FALSE, encoding = "UTF-8") else character()
  )

  if (inherits(status, "error")) {
    exit_code <- "error"
    step_status <- "erro"
    message <- conditionMessage(status)
  } else {
    exit_code <- as.character(status)
    step_status <- if (identical(status, 0L)) "ok" else "erro"
    message <- compact_message(output)
  }

  if (message == "") {
    message <- if (step_status == "ok") "Execução concluída sem mensagem." else "Execução falhou sem mensagem."
  }

  row <- data.frame(
    cycle_id = cycle_id,
    local_date = local_today(),
    phase = phase,
    source = source,
    status = step_status,
    started_at_utc = started_at,
    completed_at_utc = completed_at,
    exit_code = exit_code,
    message = message,
    stringsAsFactors = FALSE
  )

  prefix <- if (step_status == "ok") "OK" else "ERRO"
  cat(sprintf("%s %s - %s\n", prefix, phase, source))
  if (message != "") {
    cat(substr(message, 1, 1000), "\n")
  }

  row
}

append_status <- function(new_rows, cycle_id) {
  existing <- read_status(STATUS_ARCHIVE_PATH)
  combined <- rbind(existing, new_rows[, STATUS_COLUMNS, drop = FALSE])
  combined <- combined[!duplicated(
    combined[, c("cycle_id", "phase", "source"), drop = FALSE],
    fromLast = TRUE
  ), , drop = FALSE]
  write_status(combined, STATUS_ARCHIVE_PATH)

  latest <- combined[combined$cycle_id == cycle_id, , drop = FALSE]
  write_status(latest, STATUS_LATEST_PATH)
}

args <- commandArgs(trailingOnly = TRUE)
cycle_id <- if (length(args) >= 1 && nzchar(args[[1]])) {
  args[[1]]
} else {
  paste0(local_today(), "-manual")
}
mode <- if (length(args) >= 2 && nzchar(args[[2]])) {
  tolower(args[[2]])
} else {
  "all"
}

if (!mode %in% c("all", "data", "report")) {
  stop("Unknown pipeline mode: ", mode, ". Use all, data or report.", call. = FALSE)
}

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

rows <- empty_status()
if (mode %in% c("all", "data")) {
  rows <- rbind(
    rows,
    run_step(
      cycle_id,
      "data",
      "IPMA meteorologia",
      "Rscript",
      c("fetch_ipma.R", "weather")
    ),
    run_step(
      cycle_id,
      "data",
      "SNS/INSA",
      "Rscript",
      c("fetch_ipma.R", "sns-health")
    ),
    run_step(
      cycle_id,
      "data",
      "Clima Extremo",
      "Rscript",
      c("fetch_ipma.R", "clima-extremo")
    ),
    run_step(
      cycle_id,
      "data",
      "Avisos IPMA",
      "Rscript",
      c("fetch_ipma.R", "alerts")
    ),
    run_step(
      cycle_id,
      "data",
      "Erro das previsões IPMA",
      "Rscript",
      "evaluate_ipma_forecast_error.R"
    ),
    run_step(
      cycle_id,
      "data",
      "Open-Meteo temperatura",
      "Rscript",
      "fetch_openmeteo.R"
    ),
    run_step(
      cycle_id,
      "data",
      "Temperatura percentil ERA5-Land",
      "Rscript",
      c("fetch_era5_temperature_climatology.R", "alerts")
    ),
    run_step(
      cycle_id,
      "data",
      "QualAr",
      "Rscript",
      "fetch_qualar.R"
    )
  )
}

if (mode %in% c("all", "report")) {
  rows <- rbind(
    rows,
    run_step(
      cycle_id,
      "report",
      "Relatório diário",
      "Rscript",
      "generate_daily_report.R"
    )
  )
}

append_status(rows, cycle_id)

errors <- rows[rows$status != "ok", , drop = FALSE]
if (nrow(errors) > 0) {
  message(sprintf(
    "Pipeline finished with %d recorded error(s), but did not abort.",
    nrow(errors)
  ))
} else {
  message("Pipeline finished without recorded source errors.")
}
