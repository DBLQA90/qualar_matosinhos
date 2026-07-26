source("report_summary.R")

expect_identical <- function(actual, expected, label) {
  if (!identical(actual, expected)) {
    stop(
      sprintf(
        "%s\nExpected: %s\nActual:   %s",
        label,
        expected,
        actual
      ),
      call. = FALSE
    )
  }
}

horizon <- function(dates, orders, values = NULL) {
  rows <- data.frame(
    target_date = dates,
    level = orders,
    stringsAsFactors = FALSE
  )
  value_col <- NULL
  if (!is.null(values)) {
    rows$value <- values
    value_col <- "value"
  }

  summary_horizon_from_rows(
    "Teste",
    rows,
    "target_date",
    "level",
    "2026-07-26",
    value_col = value_col
  )
}

expect_identical(
  horizon("2026-07-26", 1),
  "Teste: hoje - sem dados para os próximos dias",
  "A single current value must not imply future duration."
)

expect_identical(
  horizon(c("2026-07-26", "2026-07-27"), c(1, 1)),
  "Teste: previsto até 27/07",
  "A continuous stable alert should report its supported end date."
)

expect_identical(
  horizon(
    as.character(as.Date("2026-07-26") + 0:2),
    c(0, 1, 1)
  ),
  "Teste: previsto de 27/07 a 28/07",
  "A future-only alert should state the supported start and end dates."
)

expect_identical(
  horizon(c("2026-07-26", "2026-07-27"), c(1, 0)),
  "Teste: pico hoje, tendência a melhorar a partir de 27/07",
  "A known reduction after today must not be described as persistence."
)

expect_identical(
  horizon(
    as.character(as.Date("2026-07-26") + 0:4),
    c(3, 3, 2, 3, 3),
    c(8.6, 8.2, 7.6, 8.3, 8.9)
  ),
  "Teste: pico em 30/07",
  "A later higher value in the same class must determine the peak."
)

expect_identical(
  horizon(
    as.character(as.Date("2026-07-26") + 0:3),
    c(1, 3, 2, 1)
  ),
  "Teste: pico em 27/07, tendência a melhorar a partir de 28/07",
  "A monotonic reduction after the peak supports an improving trend."
)

expect_identical(
  horizon(
    as.character(as.Date("2026-07-26") + 0:3),
    c(3, 2, 1, 2)
  ),
  "Teste: pico hoje",
  "A rebound must not be described as a sustained improving trend."
)

expect_identical(
  horizon(c("2026-07-26", "2026-07-28"), c(1, 1)),
  "Teste: picos em 26/07 e 28/07",
  "Missing forecast days must not be presented as continuous duration."
)

cat("OK report summary horizon tests\n")
