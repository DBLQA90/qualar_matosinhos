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

expect_true <- function(actual, label) {
  if (!isTRUE(actual)) {
    stop(label, call. = FALSE)
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

future_red <- list(summary_signal(
  "Clima Extremo",
  today = "Verde",
  future = "2026-07-27: Extremo (3)",
  today_order = 0,
  future_order = 3
))
future_red_model <- summary_build_operational_model(
  "2026-07-26",
  future_red
)
expect_identical(
  future_red_model$today$level,
  0,
  "A future red signal must not be classified as red today."
)
expect_identical(
  future_red_model$operational_level,
  2,
  "A future red signal must trigger orange preparation today."
)
expect_identical(
  future_red_model$phase,
  "Preparação reforçada",
  "A future-only red signal must produce a preparation phase."
)

current_red <- list(summary_signal(
  "Avisos IPMA",
  today = "Vermelho",
  future = "Vermelho",
  today_order = 3,
  future_order = 3
))
current_red_model <- summary_build_operational_model(
  "2026-07-26",
  current_red
)
expect_identical(
  current_red_model$operational_level,
  3,
  "A red signal applicable today must remain an operational emergency."
)

current_orange_future_red <- list(summary_signal(
  "Clima Extremo",
  today = "Alto (2)",
  future = "2026-07-27: Extremo (3)",
  today_order = 2,
  future_order = 3
))
escalation_model <- summary_build_operational_model(
  "2026-07-26",
  current_orange_future_red
)
expect_identical(
  escalation_model$operational_level,
  2,
  "A future escalation must not overwrite today's orange operational level."
)
expect_identical(
  escalation_model$phase,
  "Resposta atual e preparação para agravamento",
  "Current response and future preparation must be explicit."
)

quick <- build_quick_daily_report("2026-07-26", escalation_model)
full <- build_operational_summary_section("2026-07-26", escalation_model)
expect_true(
  !any(grepl("^## Decisão operacional$", quick)) &&
    !any(grepl("^## Decisão operacional$", full)),
  "The redundant operational decision section must be absent."
)
expect_true(
  any(grepl("^- 🔴 \\*\\*Clima Extremo\\*\\*", quick)) &&
    any(grepl("^- 🔴 \\*\\*Clima Extremo\\*\\*", full)),
  "Alerts and pre-alerts must expose a rapid colour code."
)
expect_true(
  match("## Horizonte temporal", quick) <
    match("## Ações a executar hoje", quick),
  "The forecast horizon must precede today's actions."
)
expect_true(
  "### Comunicação geral" %in% quick &&
    any(grepl("^- ", quick)),
  "Today's actions must be grouped into bullet lists."
)
expect_true(
  !any(grepl("^\\| Dimensão \\|", quick)),
  "The mobile summary must not include the wide risk table."
)
expect_true(
  any(grepl("boletim técnico completo", quick, fixed = TRUE)),
  "The mobile summary must link to the full report."
)
expect_identical(
  summary_display_date_text("2026-07-27: Extremo"),
  "27/07: Extremo",
  "Operational text must display forecast dates compactly."
)

index_fixture <- c(
  "# PNPRSS Matosinhos | 2026-07-26",
  "",
  "## Alertas e pré-alertas ativos",
  "",
  "## Indicadores detalhados",
  "",
  "### Temperatura DSP - teste",
  "",
  "## Fontes e metodologia",
  "",
  "### Temperatura DSP"
)
indexed_once <- replace_report_index(index_fixture)
indexed_twice <- replace_report_index(indexed_once)
expect_identical(
  indexed_twice,
  indexed_once,
  "The internal report index must be idempotent."
)
expect_true(
  any(grepl(
    "\\[Temperatura DSP - teste\\]\\(#sec-temperatura-dsp-teste\\)",
    indexed_once
  )),
  "Detailed indicators must be linked from the internal index."
)
expect_true(
  !any(grepl(
    "\\[Temperatura DSP\\]\\(#sec-temperatura-dsp\\)",
    indexed_once
  )),
  "Source subsections must not make the report index unnecessarily long."
)

tropical_only <- list(summary_signal(
  "Noites tropicais",
  today = "Noite tropical prevista",
  future = "2026-07-27: Noite tropical prevista",
  today_order = 1,
  future_order = 1
))
tropical_model <- summary_build_operational_model(
  "2026-07-26",
  tropical_only
)
expect_identical(
  tropical_model$operational_level,
  0,
  "Tropical nights must remain complementary until a standalone activation threshold is approved."
)

cat("OK report summary temporal and operational tests\n")
