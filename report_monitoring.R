RSM_SNAPSHOT_PATH <- "data/daily_report_signal_snapshots.csv"
RSM_STATUS_PATH <- "data/pipeline_source_status_latest.csv"
RSM_STATION_PATH <- "data/ipma_matosinhos_station_observations.csv"

rsm_source_registry <- function() {
  data.frame(
    source = c(
      "IPMA meteorologia",
      "Open-Meteo temperatura",
      "QualAr",
      "SNS/INSA",
      "Clima Extremo",
      "Avisos IPMA",
      "Águas balneares APA",
      "Noites tropicais IPMA",
      "Erro das previsões IPMA",
      "Comparação IPMA/Open-Meteo",
      "Temperatura percentil ERA5-Land"
    ),
    display = c(
      "IPMA meteorologia",
      "Open-Meteo",
      "QualAr",
      "SNS/INSA",
      "Clima Extremo",
      "Avisos IPMA",
      "Águas balneares",
      "Noites tropicais",
      "Erro das previsões IPMA",
      "Comparação IPMA/Open-Meteo",
      "Temperatura percentil ERA5-Land"
    ),
    source_type = c(
      rep("external", 7),
      rep("processing", 4)
    ),
    observation = c(
      "Previsões, observações, DSP, onda de calor, UTCI e UV.",
      "Previsões térmicas e arquivo de previsões.",
      "Previsões de qualidade do ar.",
      "Índices ÍCARO e FRIESA.",
      "Risco térmico em edifícios.",
      "Avisos meteorológicos e perigo de incêndio.",
      "Estado e restrições balneares.",
      "Derivação do indicador a partir dos dados IPMA.",
      "Atualização da avaliação de desempenho.",
      "Comparação pareada das duas fontes.",
      "Cálculo dependente da climatologia ERA5-Land."
    ),
    stringsAsFactors = FALSE
  )
}

rsm_read_csv <- function(path) {
  if (!file.exists(path)) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  rows <- suppressMessages(readr::read_csv(
    path,
    show_col_types = FALSE,
    col_types = readr::cols(.default = "c")
  ))
  as.data.frame(rows, stringsAsFactors = FALSE)
}

rsm_text <- function(value, fallback = "") {
  if (length(value) == 0 || is.na(value[[1]]) || value[[1]] == "") {
    return(fallback)
  }
  as.character(value[[1]])
}

rsm_utc_time <- function(value) {
  value <- rsm_text(value)
  if (value == "") {
    return(as.POSIXct(NA))
  }
  as.POSIXct(
    value,
    format = "%Y-%m-%dT%H:%M:%OSZ",
    tz = "UTC"
  )
}

rsm_iso_utc <- function(value) {
  format(
    as.POSIXct(value, tz = "UTC"),
    "%Y-%m-%dT%H:%M:%SZ",
    tz = "UTC"
  )
}

rsm_iso_local <- function(value) {
  format(
    as.POSIXct(value, tz = "UTC"),
    "%Y-%m-%dT%H:%M:%S%z",
    tz = "Europe/Lisbon"
  )
}

rsm_snapshot_rows <- function(model, cycle_id, generated_at = Sys.time()) {
  signals <- model$signals
  if (length(signals) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  do.call(rbind, lapply(signals, function(signal) {
    data.frame(
      cycle_id = cycle_id,
      report_date = as.character(model$report_date),
      generated_at_utc = rsm_iso_utc(generated_at),
      generated_at_local = rsm_iso_local(generated_at),
      domain = rsm_text(signal$domain),
      today = rsm_text(signal$today),
      today_order = as.character(signal$today_order),
      future = rsm_text(signal$future),
      future_order = as.character(signal$future_order),
      driver = rsm_text(signal$driver),
      future_driver = rsm_text(signal$future_driver),
      horizon = rsm_text(signal$horizon),
      stringsAsFactors = FALSE
    )
  }))
}

rsm_previous_snapshot <- function(
  report_date,
  current_cycle_id = "",
  snapshot_path = RSM_SNAPSHOT_PATH
) {
  rows <- rsm_read_csv(snapshot_path)
  required <- c(
    "cycle_id",
    "report_date",
    "generated_at_utc",
    "domain",
    "today",
    "today_order",
    "future",
    "future_order"
  )
  if (nrow(rows) == 0 || !all(required %in% names(rows))) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  rows <- rows[
    rows$report_date == as.character(report_date) &
      rows$cycle_id != current_cycle_id,
    ,
    drop = FALSE
  ]
  if (nrow(rows) == 0) {
    return(rows)
  }

  timestamps <- vapply(rows$generated_at_utc, function(value) {
    as.numeric(rsm_utc_time(value))
  }, numeric(1))
  valid <- is.finite(timestamps)
  rows <- rows[valid, , drop = FALSE]
  timestamps <- timestamps[valid]
  if (nrow(rows) == 0) {
    return(rows)
  }

  latest_timestamp <- max(timestamps)
  latest_cycle <- tail(unique(rows$cycle_id[timestamps == latest_timestamp]), 1)
  rows[rows$cycle_id == latest_cycle, , drop = FALSE]
}

rsm_write_snapshot <- function(
  model,
  cycle_id,
  generated_at = Sys.time(),
  snapshot_path = RSM_SNAPSHOT_PATH
) {
  current <- rsm_snapshot_rows(model, cycle_id, generated_at)
  if (nrow(current) == 0) {
    return(invisible(snapshot_path))
  }

  existing <- rsm_read_csv(snapshot_path)
  if (nrow(existing) > 0 && "cycle_id" %in% names(existing)) {
    existing <- existing[existing$cycle_id != cycle_id, , drop = FALSE]
  }
  combined <- if (nrow(existing) == 0) current else rbind(existing, current)
  combined <- combined[order(
    combined$generated_at_utc,
    combined$domain
  ), , drop = FALSE]

  dir.create(dirname(snapshot_path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(combined, snapshot_path, na = "")
  invisible(snapshot_path)
}

rsm_order <- function(value) {
  out <- suppressWarnings(as.numeric(value))
  if (length(out) == 0 || is.na(out[[1]])) -1 else out[[1]]
}

rsm_change_value <- function(value, order) {
  paste0(
    summary_risk_icon(order),
    " ",
    summary_display_date_text(rsm_text(value, "Sem dados"))
  )
}

rsm_signal_changes <- function(model, previous) {
  if (nrow(previous) == 0) {
    return("- Primeiro boletim do dia; sem edição anterior para comparação.")
  }

  output <- list()
  for (signal in model$signals) {
    prior <- previous[previous$domain == signal$domain, , drop = FALSE]
    if (nrow(prior) == 0) {
      if (max(rsm_order(signal$today_order), rsm_order(signal$future_order)) > 0) {
        output[[length(output) + 1L]] <- list(
          order = max(rsm_order(signal$today_order), rsm_order(signal$future_order)),
          line = paste0(
            "- **",
            signal$domain,
            ":** novo sinal no boletim."
          )
        )
      }
      next
    }

    prior <- prior[nrow(prior), , drop = FALSE]
    today_order <- rsm_order(signal$today_order)
    prior_today_order <- rsm_order(prior$today_order)
    future_order <- rsm_order(signal$future_order)
    prior_future_order <- rsm_order(prior$future_order)
    today_text <- rsm_text(signal$today)
    prior_today_text <- rsm_text(prior$today)
    future_text <- rsm_text(signal$future)
    prior_future_text <- rsm_text(prior$future)

    parts <- character()
    if (today_order != prior_today_order) {
      parts <- c(parts, paste0(
        "hoje: ",
        rsm_change_value(prior_today_text, prior_today_order),
        " → ",
        rsm_change_value(today_text, today_order)
      ))
    } else if (today_order > 0 && today_text != prior_today_text) {
      parts <- c(parts, paste0(
        "valor atual: ",
        rsm_change_value(prior_today_text, prior_today_order),
        " → ",
        rsm_change_value(today_text, today_order)
      ))
    }

    if (future_order != prior_future_order) {
      parts <- c(parts, paste0(
        "previsão: ",
        rsm_change_value(prior_future_text, prior_future_order),
        " → ",
        rsm_change_value(future_text, future_order)
      ))
    } else if (future_order > 0 && future_text != prior_future_text) {
      parts <- c(parts, paste0(
        "previsão atualizada: ",
        rsm_change_value(prior_future_text, prior_future_order),
        " → ",
        rsm_change_value(future_text, future_order)
      ))
    }

    if (length(parts) > 0) {
      output[[length(output) + 1L]] <- list(
        order = max(today_order, future_order),
        line = paste0(
          "- **",
          signal$domain,
          ":** ",
          paste(parts, collapse = "; "),
          "."
        )
      )
    }
  }

  if (length(output) == 0) {
    return("- Sem alterações com impacto operacional.")
  }
  orders <- vapply(output, function(value) value$order, numeric(1))
  lines <- vapply(output[order(-orders)], function(value) value$line, character(1))
  if (length(lines) <= 8) {
    return(lines)
  }
  c(lines[seq_len(8)], paste0("- ", length(lines) - 8, " alteração(ões) adicional(is) no quadro detalhado."))
}

rsm_previous_heading <- function(previous) {
  if (nrow(previous) == 0) {
    return("### Alterações desde o boletim anterior")
  }
  timestamp <- rsm_utc_time(previous$generated_at_utc[[1]])
  if (is.na(timestamp)) {
    return("### Alterações desde o boletim anterior")
  }
  paste0(
    "### Alterações desde o boletim das ",
    format(timestamp, "%H:%M", tz = "Europe/Lisbon")
  )
}

rsm_status_cutoff <- function(report_date, generated_at) {
  local_date <- format(generated_at, "%Y-%m-%d", tz = "Europe/Lisbon")
  if (local_date != as.character(report_date)) {
    return(as.POSIXct(NA))
  }
  local_hour <- as.integer(format(generated_at, "%H", tz = "Europe/Lisbon"))
  cutoff_hour <- if (local_hour >= 13) 15 else 9
  as.POSIXct(
    paste(report_date, sprintf("%02d:00:00", cutoff_hour)),
    tz = "Europe/Lisbon"
  )
}

rsm_status_rows <- function(
  report_date,
  generated_at = Sys.time(),
  status_path = RSM_STATUS_PATH
) {
  registry <- rsm_source_registry()
  status <- rsm_read_csv(status_path)
  if (nrow(status) > 0 &&
      all(c("local_date", "phase", "source") %in% names(status))) {
    status <- status[
      status$local_date == as.character(report_date) &
        status$phase == "data",
      ,
      drop = FALSE
    ]
  } else {
    status <- data.frame(stringsAsFactors = FALSE)
  }

  cutoff <- rsm_status_cutoff(report_date, generated_at)
  output <- lapply(seq_len(nrow(registry)), function(index) {
    entry <- registry[index, , drop = FALSE]
    selected <- if (nrow(status) > 0) {
      status[status$source == entry$source, , drop = FALSE]
    } else {
      data.frame(stringsAsFactors = FALSE)
    }
    if (nrow(selected) > 1) {
      selected <- selected[nrow(selected), , drop = FALSE]
    }

    completed <- if (nrow(selected) > 0 && "completed_at_utc" %in% names(selected)) {
      rsm_utc_time(selected$completed_at_utc)
    } else {
      as.POSIXct(NA)
    }
    raw_status <- if (nrow(selected) > 0 && "status" %in% names(selected)) {
      rsm_text(selected$status)
    } else {
      ""
    }
    message <- if (nrow(selected) > 0 && "message" %in% names(selected)) {
      rsm_text(selected$message)
    } else {
      ""
    }

    if (nrow(selected) == 0) {
      state <- "missing"
      state_label <- "⚠️ Sem registo"
      note <- "Sem registo de execução para esta data."
    } else if (raw_status != "ok") {
      state <- "error"
      state_label <- "❌ Falha"
      detail <- gsub("[|\\r\\n]+", " ", message)
      detail <- trimws(gsub("\\s+", " ", detail))
      note <- if (detail == "") {
        "A atualização falhou sem detalhe adicional."
      } else {
        paste0(substr(detail, 1, 140), if (nchar(detail) > 140) "..." else "")
      }
    } else if (grepl("\\bSKIP\\b", message, ignore.case = TRUE)) {
      state <- "skipped"
      state_label <- "➖ Não executada"
      note <- if (grepl("percentile file is not available", message, ignore.case = TRUE)) {
        "Climatologia percentil ainda indisponível."
      } else {
        "Etapa não aplicável ou sem base disponível."
      }
    } else if (!is.na(cutoff) &&
        (is.na(completed) || as.numeric(completed) < as.numeric(cutoff))) {
      state <- "stale"
      state_label <- "⚠️ Desatualizada"
      note <- paste0(
        "Não corresponde ao ciclo das ",
        format(cutoff, "%H:%M", tz = "Europe/Lisbon"),
        "."
      )
    } else {
      state <- "updated"
      state_label <- "✅ Atualizada"
      note <- entry$observation
    }

    data.frame(
      source = entry$source,
      display = entry$display,
      source_type = entry$source_type,
      state = state,
      state_label = state_label,
      completed_at_utc = if (is.na(completed)) "" else rsm_iso_utc(completed),
      completed_local = if (is.na(completed)) {
        "—"
      } else {
        format(completed, "%d/%m %H:%M", tz = "Europe/Lisbon")
      },
      note = note,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, output)
}

rsm_station_coverage <- function(
  report_date,
  station_path = RSM_STATION_PATH
) {
  rows <- rsm_read_csv(station_path)
  expected_ids <- c("1200545", "1210649")
  target_date <- as.Date(report_date) - 1
  if (nrow(rows) == 0 ||
      !all(c("date_local", "station_id", "datetime_utc") %in% names(rows))) {
    return(list(complete = 0L, expected = length(expected_ids), target_date = target_date))
  }

  rows <- rows[
    as.Date(rows$date_local) == target_date &
      rows$station_id %in% expected_ids,
    ,
    drop = FALSE
  ]
  counts <- vapply(expected_ids, function(station_id) {
    length(unique(rows$datetime_utc[rows$station_id == station_id]))
  }, integer(1))
  list(
    complete = sum(counts >= 20),
    expected = length(expected_ids),
    target_date = target_date
  )
}

rsm_source_quality <- function(
  report_date,
  generated_at = Sys.time(),
  status_path = RSM_STATUS_PATH,
  station_path = RSM_STATION_PATH
) {
  rows <- rsm_status_rows(report_date, generated_at, status_path)
  external <- rows[rows$source_type == "external", , drop = FALSE]
  updated <- sum(external$state == "updated")
  total <- nrow(external)
  failures <- sum(external$state == "error")
  icon <- if (failures > 0) "❌" else if (updated == total) "✅" else "⚠️"
  coverage <- rsm_station_coverage(report_date, station_path)

  exceptions <- external[external$state != "updated", , drop = FALSE]
  exception_text <- if (nrow(exceptions) == 0) {
    character()
  } else {
    labels <- paste0(exceptions$display, ": ", sub("^[^ ]+ ", "", exceptions$state_label))
    if (length(labels) > 2) {
      c(labels[1:2], paste0("+", length(labels) - 2, " fonte(s)"))
    } else {
      labels
    }
  }

  completed <- vapply(external$completed_at_utc, function(value) {
    as.numeric(rsm_utc_time(value))
  }, numeric(1))
  latest <- if (any(is.finite(completed))) {
    as.POSIXct(max(completed[is.finite(completed)]), origin = "1970-01-01", tz = "UTC")
  } else {
    as.POSIXct(NA)
  }

  parts <- c(
    paste0(icon, " ", updated, "/", total, " fontes externas atualizadas"),
    if (length(exception_text) > 0) paste(exception_text, collapse = "; ") else NULL,
    paste0(
      "observações D-1 com cobertura ≥20 h em ",
      coverage$complete,
      "/",
      coverage$expected,
      " estações"
    ),
    if (!is.na(latest)) {
      paste0(
        "última recolha: ",
        format(latest, "%H:%M", tz = "Europe/Lisbon")
      )
    } else {
      "sem hora de recolha disponível"
    }
  )

  list(
    banner = paste0("> **Estado dos dados:** ", paste(parts, collapse = " · "), "."),
    rows = rows,
    coverage = coverage
  )
}

rsm_source_table_lines <- function(quality) {
  rows <- quality$rows
  c(
    "| Fonte/etapa | Estado | Última atualização | Observação |",
    "|---|---|---:|---|",
    vapply(seq_len(nrow(rows)), function(index) {
      row <- rows[index, , drop = FALSE]
      paste0(
        "| ",
        row$display,
        " | ",
        row$state_label,
        " | ",
        row$completed_local,
        " | ",
        gsub("\\|", "/", row$note),
        " |"
      )
    }, character(1))
  )
}

rsm_attach_report_context <- function(
  model,
  cycle_id,
  generated_at = Sys.time(),
  snapshot_path = RSM_SNAPSHOT_PATH,
  status_path = RSM_STATUS_PATH,
  station_path = RSM_STATION_PATH
) {
  previous <- rsm_previous_snapshot(
    model$report_date,
    current_cycle_id = cycle_id,
    snapshot_path = snapshot_path
  )
  model$cycle_id <- cycle_id
  model$generated_at <- generated_at
  model$previous_snapshot <- previous
  model$changes_heading <- rsm_previous_heading(previous)
  model$change_lines <- rsm_signal_changes(model, previous)
  model$source_quality <- rsm_source_quality(
    model$report_date,
    generated_at = generated_at,
    status_path = status_path,
    station_path = station_path
  )
  model
}
