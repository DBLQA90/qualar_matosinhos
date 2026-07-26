library(httr)
library(jsonlite)
library(dplyr)
library(readr)
source("report_summary.R", encoding = "UTF-8")

BW_ARCHIVE_PATH <- "data/apa_matosinhos_bathing_water.csv"
BW_LATEST_PATH <- "data/apa_matosinhos_bathing_water_latest.csv"
BW_DAILY_DIR <- "daily"
BW_LOCAL_TZ <- "Europe/Lisbon"
BW_FETCHED_AT <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
BW_SNAPSHOT_DATE <- format(Sys.time(), "%Y-%m-%d", tz = BW_LOCAL_TZ)
BW_LAYER_URL <- paste0(
  "https://sniambgeoogc.apambiente.pt/getogc/rest/services/",
  "SNIAmb/Praias/MapServer/0/query"
)

BW_COLUMNS <- c(
  "source_updated_at",
  "source_timestamp_available",
  "fetched_at",
  "snapshot_date",
  "location",
  "district",
  "dico",
  "hydrographic_region",
  "beach_code",
  "beach_name",
  "bathing_water_code",
  "bathing_water_name",
  "bathing_season_start",
  "bathing_season_end",
  "in_bathing_season",
  "bathing_water_category_code",
  "annual_classification_code",
  "quality_status",
  "restriction_code",
  "restriction_type",
  "restriction_reason",
  "risk_label",
  "risk_level_order",
  "surveillance",
  "first_aid",
  "accessible_beach",
  "blue_flag",
  "works_in_progress",
  "cliff_risk",
  "special_wave_conditions",
  "latitude",
  "longitude",
  "infoagua_url",
  "snirh_url",
  "recommendation_summary",
  "source"
)

bw_empty <- function() {
  out <- as.data.frame(
    matrix(character(), nrow = 0, ncol = length(BW_COLUMNS)),
    stringsAsFactors = FALSE
  )
  names(out) <- BW_COLUMNS
  out
}

bw_text <- function(value) {
  if (is.null(value) || length(value) == 0 || is.na(value[[1]])) {
    return("")
  }
  as.character(value[[1]])
}

bw_num <- function(value) {
  suppressWarnings(as.numeric(bw_text(value)))
}

bw_attr <- function(attributes, name) {
  if (is.null(attributes) || !name %in% names(attributes)) {
    return("")
  }
  bw_text(attributes[[name]])
}

bw_normalize <- function(value) {
  value <- iconv(bw_text(value), from = "UTF-8", to = "ASCII//TRANSLIT")
  tolower(ifelse(is.na(value), "", value))
}

bw_epoch_date <- function(value) {
  milliseconds <- bw_num(value)
  if (is.na(milliseconds)) {
    return("")
  }
  format(
    as.POSIXct(milliseconds / 1000, origin = "1970-01-01", tz = "UTC"),
    "%Y-%m-%d",
    tz = "UTC"
  )
}

bw_boolean <- function(value) {
  numeric_value <- bw_num(value)
  if (is.na(numeric_value)) {
    return("")
  }
  ifelse(numeric_value == 1, "TRUE", "FALSE")
}

bw_in_season <- function(snapshot_date, start_date, end_date) {
  date <- as.Date(snapshot_date)
  start <- as.Date(start_date)
  end <- as.Date(end_date)
  if (is.na(date) || is.na(start) || is.na(end)) {
    return(NA)
  }
  date >= start && date <= end
}

bw_restriction <- function(quality_status, restriction_code, in_season) {
  quality <- bw_normalize(quality_status)
  code <- bw_num(restriction_code)

  restriction_type <- if (grepl("interdit", quality)) {
    "Banho interdito"
  } else if (grepl("desaconselh", quality)) {
    "Banho desaconselhado"
  } else if (!is.na(code) && code > 0) {
    "Restrição ativa"
  } else {
    "Sem restrição"
  }

  if (isFALSE(in_season)) {
    return(list(
      restriction_type = restriction_type,
      risk_label = "Fora da época balnear",
      risk_level_order = 0L
    ))
  }
  if (is.na(in_season)) {
    return(list(
      restriction_type = restriction_type,
      risk_label = "Sem dados de época balnear",
      risk_level_order = -1L
    ))
  }
  if (restriction_type == "Banho interdito") {
    return(list(
      restriction_type = restriction_type,
      risk_label = "Interdição",
      risk_level_order = 3L
    ))
  }
  if (restriction_type %in% c("Banho desaconselhado", "Restrição ativa")) {
    return(list(
      restriction_type = restriction_type,
      risk_label = if (
        restriction_type == "Banho desaconselhado"
      ) "Desaconselhamento" else "Restrição ativa",
      risk_level_order = 2L
    ))
  }
  if (grepl("adequada", quality)) {
    return(list(
      restriction_type = restriction_type,
      risk_label = "Sem restrição",
      risk_level_order = 0L
    ))
  }

  list(
    restriction_type = restriction_type,
    risk_label = "Sem dados de estado",
    risk_level_order = -1L
  )
}

bw_recommendation <- function(classification) {
  if (classification$risk_level_order >= 3) {
    return(
      "Não entrar na água. Cumprir a interdição e a sinalização local; retomar a prática balnear apenas após levantamento oficial."
    )
  }
  if (classification$risk_level_order >= 2) {
    return(
      "Não tomar banho nem entrar na água enquanto vigorar o desaconselhamento/restrição; acompanhar InfoÁgua e sinalização local."
    )
  }
  if (classification$risk_level_order == 0) {
    return(
      "Sem restrição ativa no snapshot; respeitar sinalização, nadadores-salvadores e atualizações oficiais."
    )
  }
  "Não inferir segurança balnear sem estado oficial preenchido."
}

bw_fetch <- function() {
  response <- GET(
    BW_LAYER_URL,
    query = list(
      where = "UPPER(concelho)='MATOSINHOS'",
      outFields = "*",
      returnGeometry = "true",
      outSR = "4326",
      f = "json"
    ),
    user_agent("qualar-matosinhos/1.0"),
    config(connecttimeout = 20),
    timeout(45)
  )
  stop_for_status(response)
  parsed <- fromJSON(
    content(response, as = "text", encoding = "UTF-8"),
    simplifyVector = FALSE
  )
  if (!is.null(parsed$error)) {
    stop(
      "APA ArcGIS API returned an error: ",
      bw_text(parsed$error$message),
      call. = FALSE
    )
  }
  if (is.null(parsed$features) || length(parsed$features) == 0) {
    stop("APA ArcGIS API returned no beaches for Matosinhos.", call. = FALSE)
  }
  parsed
}

bw_flatten_feature <- function(
  feature,
  snapshot_date = BW_SNAPSHOT_DATE,
  fetched_at = BW_FETCHED_AT
) {
  attributes <- feature$attributes
  geometry <- feature$geometry
  start_date <- bw_epoch_date(attributes$data_inicio_epoca_balnear)
  end_date <- bw_epoch_date(attributes$data_fim_epoca_balnear)
  in_season <- bw_in_season(snapshot_date, start_date, end_date)
  classification <- bw_restriction(
    bw_attr(attributes, "qualidade_agua_balnear_dsc"),
    bw_attr(attributes, "motivo_desacons_interdicao"),
    in_season
  )

  data.frame(
    source_updated_at = fetched_at,
    source_timestamp_available = "FALSE",
    fetched_at = fetched_at,
    snapshot_date = snapshot_date,
    location = "Matosinhos",
    district = "Porto",
    dico = "1308",
    hydrographic_region = bw_attr(attributes, "arh"),
    beach_code = bw_attr(attributes, "codigo_praia"),
    beach_name = bw_attr(attributes, "nome_praia"),
    bathing_water_code = bw_attr(attributes, "codigo_agua_balnear"),
    bathing_water_name = bw_attr(attributes, "nome_agua_balnear"),
    bathing_season_start = start_date,
    bathing_season_end = end_date,
    in_bathing_season = ifelse(
      is.na(in_season),
      "",
      ifelse(in_season, "TRUE", "FALSE")
    ),
    bathing_water_category_code = bw_attr(
      attributes,
      "categoria_agua_balnear"
    ),
    annual_classification_code = bw_attr(
      attributes,
      "classificacao_agua_balnear"
    ),
    quality_status = bw_attr(attributes, "qualidade_agua_balnear_dsc"),
    restriction_code = bw_attr(
      attributes,
      "motivo_desacons_interdicao"
    ),
    restriction_type = classification$restriction_type,
    restriction_reason = bw_attr(
      attributes,
      "motivo_desacons_interdicao_dsc"
    ),
    risk_label = classification$risk_label,
    risk_level_order = as.character(classification$risk_level_order),
    surveillance = bw_boolean(bw_attr(attributes, "vigilancia")),
    first_aid = bw_boolean(bw_attr(attributes, "posto_socorros")),
    accessible_beach = bw_boolean(bw_attr(attributes, "acessivel")),
    blue_flag = bw_boolean(bw_attr(attributes, "bandeira_azul")),
    works_in_progress = bw_boolean(bw_attr(attributes, "obras_em_curso")),
    cliff_risk = bw_boolean(bw_attr(attributes, "risco_derrocada")),
    special_wave_conditions = bw_boolean(
      bw_attr(attributes, "ondas_especial_valor")
    ),
    latitude = if (is.null(geometry)) "" else bw_text(geometry$y),
    longitude = if (is.null(geometry)) "" else bw_text(geometry$x),
    infoagua_url = bw_attr(attributes, "url_infopraia"),
    snirh_url = bw_attr(attributes, "url_snirh"),
    recommendation_summary = bw_recommendation(classification),
    source = paste(
      "APA/SNIAmb ArcGIS Praia layer 0;",
      "municipality-filtered current bathing-water status"
    ),
    stringsAsFactors = FALSE
  )[, BW_COLUMNS, drop = FALSE]
}

bw_flatten <- function(
  api_data,
  snapshot_date = BW_SNAPSHOT_DATE,
  fetched_at = BW_FETCHED_AT
) {
  rows <- bind_rows(lapply(
    api_data$features,
    bw_flatten_feature,
    snapshot_date = snapshot_date,
    fetched_at = fetched_at
  ))
  if (nrow(rows) == 0) {
    return(bw_empty())
  }
  rows[] <- lapply(rows, as.character)
  rows %>%
    arrange(beach_name) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

bw_read_existing <- function(path) {
  if (!file.exists(path)) {
    return(bw_empty())
  }
  rows <- as.data.frame(
    suppressMessages(read_csv(
      path,
      show_col_types = FALSE,
      col_types = cols(.default = "c")
    )),
    stringsAsFactors = FALSE
  )
  for (column in setdiff(BW_COLUMNS, names(rows))) {
    rows[[column]] <- ""
  }
  rows <- rows[, BW_COLUMNS, drop = FALSE]
  rows[] <- lapply(rows, function(column) {
    column <- as.character(column)
    column[is.na(column)] <- ""
    column
  })
  rows
}

bw_write <- function(rows) {
  dir.create("data", showWarnings = FALSE, recursive = TRUE)
  existing <- bw_read_existing(BW_ARCHIVE_PATH)
  if (nrow(existing) > 0) {
    replace_keys <- paste(rows$snapshot_date, rows$beach_code, sep = "\r")
    existing_keys <- paste(
      existing$snapshot_date,
      existing$beach_code,
      sep = "\r"
    )
    existing <- existing[!existing_keys %in% replace_keys, , drop = FALSE]
  }
  archive <- bind_rows(existing, rows) %>%
    arrange(snapshot_date, beach_name) %>%
    as.data.frame(stringsAsFactors = FALSE)
  write_csv(archive, BW_ARCHIVE_PATH, na = "")
  write_csv(rows, BW_LATEST_PATH, na = "")
  list(archive = archive, latest = rows)
}

bw_table_lines <- function(rows) {
  if (nrow(rows) == 0) {
    return("Sem dados APA disponíveis para as praias de Matosinhos.")
  }
  orders <- suppressWarnings(as.numeric(rows$risk_level_order))
  rows <- rows[order(-orders, rows$beach_name), , drop = FALSE]

  c(
    "| Praia | Água balnear | Estado | Motivo | Época |",
    "|---|---|---|---|---|",
    vapply(seq_len(nrow(rows)), function(i) {
      row <- rows[i, , drop = FALSE]
      reason <- bw_text(row$restriction_reason)
      if (reason == "") {
        reason <- "-"
      }
      season <- if (bw_text(row$in_bathing_season) == "TRUE") {
        paste0(
          bw_text(row$bathing_season_start),
          " a ",
          bw_text(row$bathing_season_end)
        )
      } else {
        "Fora da época"
      }
      paste0(
        "| [",
        bw_text(row$beach_name),
        "](",
        bw_text(row$infoagua_url),
        ") | ",
        bw_text(row$bathing_water_name),
        " | ",
        bw_text(row$risk_label),
        " | ",
        reason,
        " | ",
        season,
        " |"
      )
    }, character(1))
  )
}

bw_recommendations <- function(rows) {
  orders <- suppressWarnings(as.numeric(rows$risk_level_order))
  active <- rows[!is.na(orders) & orders > 0, , drop = FALSE]
  if (nrow(active) == 0) {
    return(paste(
      "Comunicação geral: sem desaconselhamentos ou interdições ativos no último snapshot APA; confirmar sempre a sinalização local e as atualizações do InfoÁgua.",
      "Grupos vulneráveis: manter cuidados habituais e evitar banho fora das águas identificadas e monitorizadas.",
      "Estabelecimentos/equipamentos: confirmar o estado oficial antes de atividades aquáticas organizadas e manter alternativa caso surja uma restrição.",
      sep = "\n\n"
    ))
  }

  beaches <- paste(unique(active$beach_name), collapse = ", ")
  reasons <- unique(active$restriction_reason[active$restriction_reason != ""])
  reason_text <- if (length(reasons) == 0) {
    "motivo não indicado"
  } else {
    paste(reasons, collapse = "; ")
  }
  has_interdiction <- any(
    orders > 0 & rows$restriction_type == "Banho interdito",
    na.rm = TRUE
  )
  restriction_word <- if (has_interdiction) "interdição" else "desaconselhamento/restrição"
  beach_location <- if (nrow(active) == 1) " na praia " else " nas praias "

  paste(
    paste0(
      "Comunicação geral: existe ",
      restriction_word,
      beach_location,
      beaches,
      " (",
      reason_text,
      "). Não tomar banho nem entrar na água e respeitar a sinalização e as indicações das autoridades."
    ),
    "Grupos vulneráveis: crianças, pessoas idosas, grávidas, pessoas imunocomprometidas ou com feridas/doença de pele devem evitar rigorosamente contacto com a água afetada. Se ocorreu exposição e surgirem sintomas gastrointestinais, cutâneos, oculares ou febre, contactar um profissional de saúde/SNS 24.",
    "Estabelecimentos/equipamentos: cancelar atividades aquáticas nas praias afetadas, informar utentes, famílias e equipas, manter alternativa sem contacto com a água e só retomar após levantamento oficial da restrição.",
    sep = "\n\n"
  )
}

bw_build_daily_section <- function(rows, report_date) {
  fetched_values <- unique(rows$fetched_at[rows$fetched_at != ""])
  fetched_text <- if (length(fetched_values) == 0) {
    "sem timestamp de recolha"
  } else {
    paste(sort(fetched_values), collapse = "; ")
  }
  c(
    "<!-- bathing-water:start -->",
    paste0("### Águas balneares - Matosinhos em ", report_date),
    "",
    paste0(
      "Fonte dos valores: APA/SNIAmb, estado corrente por praia e água balnear. Recolha: ",
      fetched_text,
      ". A fonte não expõe timestamp próprio de atualização; a data indicada é a da recolha. Desaconselhamentos são emitidos pela APA e interdições pela Autoridade de Saúde."
    ),
    "",
    bw_table_lines(rows),
    "",
    bw_recommendations(rows),
    "<!-- bathing-water:end -->"
  )
}

bw_replace_section_after <- function(existing, section, marker, anchor_marker) {
  start_marker <- paste0("<!-- ", marker, ":start -->")
  end_marker <- paste0("<!-- ", marker, ":end -->")
  start <- which(existing == start_marker)
  end <- which(existing == end_marker)
  if (length(start) > 0 && length(end) > 0 && end[1] > start[1]) {
    before <- if (start[1] > 1) existing[seq_len(start[1] - 1)] else character()
    after <- if (end[1] < length(existing)) existing[(end[1] + 1):length(existing)] else character()
    existing <- c(before, after)
  }

  anchor_end <- which(existing == paste0("<!-- ", anchor_marker, ":end -->"))
  if (length(anchor_end) > 0) {
    before <- existing[seq_len(anchor_end[1])]
    after <- if (anchor_end[1] < length(existing)) {
      existing[(anchor_end[1] + 1):length(existing)]
    } else {
      character()
    }
    return(c(before, "", section, after))
  }

  source_header <- grep(SOURCES_HEADER_PATTERN, existing)
  if (length(source_header) > 0) {
    before <- if (source_header[1] > 1) existing[seq_len(source_header[1] - 1)] else character()
    after <- existing[source_header[1]:length(existing)]
    return(c(before, section, "", after))
  }
  c(existing, "", section)
}

bw_update_daily_report <- function(rows, report_date = BW_SNAPSHOT_DATE) {
  dir.create(BW_DAILY_DIR, showWarnings = FALSE, recursive = TRUE)
  report_path <- file.path(BW_DAILY_DIR, paste0(report_date, ".md"))
  existing <- if (file.exists(report_path)) {
    readLines(report_path, warn = FALSE, encoding = "UTF-8")
  } else {
    c(summary_report_title(report_date), "")
  }
  section <- bw_build_daily_section(rows, report_date)
  updated <- bw_replace_section_after(
    existing,
    section,
    "bathing-water",
    "ipma-alerts"
  )
  updated <- finalize_daily_report(updated, report_date)
  writeLines(updated, report_path, useBytes = TRUE)
  report_path
}

bw_run <- function() {
  rows <- bw_flatten(bw_fetch())
  result <- bw_write(rows)
  report_path <- bw_update_daily_report(result$latest)
  restrictions <- sum(
    suppressWarnings(as.numeric(result$latest$risk_level_order)) > 0,
    na.rm = TRUE
  )
  message(sprintf(
    paste(
      "OK bathing water - %d Matosinhos beach row(s), %d active restriction(s);",
      "archive has %d row(s); report: %s."
    ),
    nrow(result$latest),
    restrictions,
    nrow(result$archive),
    report_path
  ))
  invisible(result)
}

if (sys.nframe() == 0L) {
  bw_run()
}
