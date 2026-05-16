library(httr)
library(jsonlite)
library(dplyr)
library(readr)
source("report_summary.R", encoding = "UTF-8")

DATA_DIR <- "data"
TEMPERATURE_PATH <- file.path(DATA_DIR, "ipma_matosinhos_temperaturas.csv")
FORECAST_PATH <- file.path(DATA_DIR, "ipma_matosinhos_forecasts.csv")
FORECAST_LATEST_PATH <- file.path(DATA_DIR, "ipma_matosinhos_forecast_latest.csv")
STATION_OBSERVATIONS_PATH <- file.path(
  DATA_DIR,
  "ipma_matosinhos_station_observations.csv"
)
STATION_DAILY_TEMPERATURES_PATH <- file.path(
  DATA_DIR,
  "ipma_matosinhos_station_daily_temperatures.csv"
)
TEMPERATURE_ALERTS_PATH <- file.path(DATA_DIR, "ipma_matosinhos_temperature_alerts.csv")
TEMPERATURE_ALERTS_LATEST_PATH <- file.path(
  DATA_DIR,
  "ipma_matosinhos_temperature_alert_latest.csv"
)
UV_INDEX_PATH <- file.path(DATA_DIR, "ipma_matosinhos_uv_index.csv")
UV_INDEX_LATEST_PATH <- file.path(DATA_DIR, "ipma_matosinhos_uv_index_latest.csv")
HEAT_WAVE_PATH <- file.path(DATA_DIR, "ipma_matosinhos_heat_waves.csv")
HEAT_WAVE_LATEST_PATH <- file.path(DATA_DIR, "ipma_matosinhos_heat_waves_latest.csv")
THERMAL_STRESS_PATH <- file.path(DATA_DIR, "ipma_matosinhos_thermal_stress.csv")
THERMAL_STRESS_LATEST_PATH <- file.path(
  DATA_DIR,
  "ipma_matosinhos_thermal_stress_latest.csv"
)
SNS_HEALTH_INDEX_PATH <- file.path(
  DATA_DIR,
  "sns_matosinhos_temperature_health_indices.csv"
)
SNS_HEALTH_INDEX_LATEST_PATH <- file.path(
  DATA_DIR,
  "sns_matosinhos_temperature_health_indices_latest.csv"
)
CLIMA_EXTREMO_PATH <- file.path(DATA_DIR, "clima_extremo_matosinhos_risk.csv")
CLIMA_EXTREMO_LATEST_PATH <- file.path(
  DATA_DIR,
  "clima_extremo_matosinhos_risk_latest.csv"
)
IPMA_ALERTS_PATH <- file.path(DATA_DIR, "ipma_matosinhos_alerts.csv")
IPMA_ALERTS_LATEST_PATH <- file.path(DATA_DIR, "ipma_matosinhos_alerts_latest.csv")
DAILY_DIR <- "daily"

LOCAL_TZ <- "Europe/Lisbon"
FETCHED_AT <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

LOCATION <- "Matosinhos"
DISTRICT <- "Porto"
DICO <- "1308"
GLOBAL_ID_LOCAL <- "1130800"
LATITUDE <- "41.1805"
LONGITUDE <- "-8.6810"
WARNING_AREA_ID <- "PTO"
WARNING_AREA_NAME <- "Porto"

IPMA_BASE <- "https://api.ipma.pt"
TMIN_URL <- paste0(
  IPMA_BASE,
  "/open-data/observation/climate/temperature-min/porto/mtnmn-1308-matosinhos.csv"
)
TMAX_URL <- paste0(
  IPMA_BASE,
  "/open-data/observation/climate/temperature-max/porto/mtxmx-1308-matosinhos.csv"
)
FORECAST_URL <- paste0(IPMA_BASE, "/public-data/forecast/aggregate/1130800.json")
STATION_OBSERVATIONS_URL <- paste0(
  IPMA_BASE,
  "/open-data/observation/meteorology/stations/observations.json"
)
WEATHER_WARNINGS_URL <- paste0(
  IPMA_BASE,
  "/open-data/forecast/warnings/warnings_www.json"
)
FIRE_RISK_URLS <- paste0(
  IPMA_BASE,
  "/open-data/forecast/meteorology/rcm/rcm-d",
  0:1,
  ".json"
)
SNS_BASE <- "https://transparencia.sns.gov.pt"
SNS_ICARO_URL <- paste0(
  SNS_BASE,
  "/explore/dataset/evolucao-diaria-do-indice-icaro/download",
  "?format=json&timezone=Europe/Lisbon&use_labels_for_header=false"
)
SNS_FRIESA_URL <- paste0(
  SNS_BASE,
  "/explore/dataset/indice-friesa/download",
  "?format=json&timezone=Europe/Lisbon&use_labels_for_header=false"
)
CLIMA_EXTREMO_BASE <- "http://climaextremo.vps.tecnico.ulisboa.pt:8100"
CLIMA_EXTREMO_METADATA_URL <- paste0(CLIMA_EXTREMO_BASE, "/api/weather/metadata")
CLIMA_EXTREMO_DATES_URL <- paste0(CLIMA_EXTREMO_BASE, "/api/weather/dates")
CLIMA_EXTREMO_MAP_URL <- paste0(
  CLIMA_EXTREMO_BASE,
  "/api/map/getRegionBordersAndWeather?dateId="
)
CLIMA_EXTREMO_REGION <- "matosinhos"

FALLBACK_STATIONS <- data.frame(
  station_id = c("1200545", "1210649"),
  station_name = c("Porto, Pedras Rubras", "S. Gens"),
  stringsAsFactors = FALSE
)

TEMPERATURE_COLUMNS <- c(
  "date",
  "location",
  "district",
  "dico",
  "tmean_estimated_c",
  "tmin_c",
  "tmax_c",
  "tmin_concelho_min_c",
  "tmin_concelho_max_c",
  "tmax_concelho_min_c",
  "tmax_concelho_max_c",
  "source",
  "fetched_at"
)

FORECAST_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "location",
  "district",
  "global_id_local",
  "latitude",
  "longitude",
  "forecast_datetime_utc",
  "forecast_date",
  "period_hours",
  "period_type",
  "intervalo_hora",
  "weather_type_id",
  "precipitation_intensity_id",
  "precipitation_probability_percent",
  "tmed_c",
  "tmin_c",
  "tmax_c",
  "humidity_percent",
  "utci_c",
  "wind_speed_kmh",
  "wind_speed_class_id",
  "wind_direction",
  "uv_index",
  "source"
)

STATION_OBSERVATION_COLUMNS <- c(
  "datetime_utc",
  "datetime_local",
  "date_local",
  "station_id",
  "station_name",
  "temperature_c",
  "source",
  "fetched_at"
)

STATION_DAILY_TEMPERATURE_COLUMNS <- c(
  "date",
  "location",
  "district",
  "station_count",
  "station_ids",
  "station_names",
  "tmin_c",
  "tmax_c",
  "min_hourly_observations",
  "source",
  "fetched_at"
)

TEMPERATURE_ALERT_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "location",
  "district",
  "dico",
  "global_id_local",
  "target_date",
  "season_rule",
  "tmax_alert",
  "tmax_alert_level",
  "tmax_yellow_threshold_c",
  "tmax_red_threshold_c",
  "tmax_observed_d_minus_3_c",
  "tmax_observed_d_minus_2_c",
  "tmax_observed_d_minus_1_c",
  "tmax_forecast_d0_c",
  "tmax_forecast_d_plus_1_c",
  "tmin_alert",
  "tmin_alert_level",
  "tmin_yellow_threshold_c",
  "tmin_red_threshold_c",
  "tmin_observed_d_minus_2_c",
  "tmin_observed_d_minus_1_c",
  "tmin_forecast_d0_c",
  "tmin_forecast_d_plus_1_c",
  "overall_temperature_alert",
  "overall_temperature_alert_level",
  "missing_inputs",
  "recommendation_summary",
  "source"
)

UV_INDEX_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "location",
  "district",
  "global_id_local",
  "target_date",
  "uv_index",
  "uv_level",
  "uv_level_order",
  "uv_color",
  "protection_required",
  "recommendation_summary",
  "source"
)

HEAT_WAVE_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "location",
  "district",
  "dico",
  "global_id_local",
  "target_date",
  "tmax_c",
  "tmax_source",
  "normal_period",
  "normal_station",
  "normal_tmax_c",
  "threshold_c",
  "exceeds_threshold",
  "available_window_days",
  "consecutive_exceedance_days",
  "heat_wave_6day",
  "forecast_in_6day_window",
  "pre_heat_wave_5day",
  "forecast_in_5day_window",
  "heat_wave_window_start",
  "heat_wave_window_end",
  "pre_heat_wave_window_start",
  "pre_heat_wave_window_end",
  "heat_wave_status",
  "heat_wave_level",
  "missing_inputs",
  "recommendation_summary",
  "source"
)

THERMAL_STRESS_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "location",
  "district",
  "global_id_local",
  "target_date",
  "forecast_datetime_utc",
  "forecast_datetime_local",
  "period_hours",
  "utci_c",
  "thermal_level",
  "thermal_level_order",
  "thermal_color",
  "thermal_stress_type",
  "protection_required",
  "recommendation_summary",
  "source"
)

SNS_HEALTH_INDEX_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "location",
  "district",
  "dico",
  "index_name",
  "index_scope",
  "target_date",
  "index_value",
  "risk_label",
  "risk_level_order",
  "provisional_note",
  "season",
  "recommendation_summary",
  "source"
)

CLIMA_EXTREMO_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "location",
  "district",
  "dico",
  "region",
  "target_date",
  "date_id",
  "risk_index",
  "risk_label",
  "risk_level_order",
  "risk_color",
  "risk_alert",
  "indoor_temperature_c",
  "indoor_temperature_label",
  "indoor_temperature_alert",
  "outdoor_temperature_c",
  "vulnerability_index",
  "source_note",
  "recommendation_summary",
  "source"
)

IPMA_ALERT_COLUMNS <- c(
  "source_updated_at",
  "fetched_at",
  "location",
  "district",
  "dico",
  "global_id_local",
  "alert_source",
  "alert_scope",
  "target_date",
  "start_time",
  "end_time",
  "alert_type",
  "alert_level",
  "alert_level_order",
  "alert_color",
  "description",
  "recommendation_summary",
  "source"
)

TEMPERATURE_KEY_COLUMNS <- "date"
FORECAST_KEY_COLUMNS <- c(
  "source_updated_at",
  "global_id_local",
  "forecast_datetime_utc",
  "period_hours"
)
STATION_OBSERVATION_KEY_COLUMNS <- c("datetime_utc", "station_id")
STATION_DAILY_TEMPERATURE_KEY_COLUMNS <- "date"
TEMPERATURE_ALERT_KEY_COLUMNS <- c("source_updated_at", "target_date")
UV_INDEX_KEY_COLUMNS <- c("source_updated_at", "target_date")
HEAT_WAVE_KEY_COLUMNS <- c("source_updated_at", "target_date")
THERMAL_STRESS_KEY_COLUMNS <- c(
  "source_updated_at",
  "forecast_datetime_utc",
  "period_hours"
)
SNS_HEALTH_INDEX_KEY_COLUMNS <- c(
  "index_name",
  "index_scope",
  "target_date"
)
CLIMA_EXTREMO_KEY_COLUMNS <- c(
  "source_updated_at",
  "region",
  "target_date",
  "date_id"
)
IPMA_ALERT_KEY_COLUMNS <- c(
  "source_updated_at",
  "alert_source",
  "alert_scope",
  "target_date",
  "start_time",
  "end_time",
  "alert_type"
)

HEAT_LEVELS <- c(
  "Fora de época" = -2,
  "Sem dados" = -1,
  "Verde" = 0,
  "Amarelo" = 1,
  "Vermelho" = 3
)

HEAT_SOURCE_LINKS <- c(
  "- IPMA, API de dados meteorológicos: https://api.ipma.pt/",
  "- DGS, recomendações para ondas de calor: https://www.dgs.pt/saude-ambiental-calor/recomendacoes.aspx",
  "- DGS, temperaturas elevadas - recomendações: https://www.dgs.pt/em-destaque/temperaturas-elevadas-recomendacoes-da-dgs.aspx",
  "- SNS/DGS/INSA, recomendações contra o calor: https://www.sns.min-saude.pt/comunicado-conjunto-aumento-da-temperatura-recomendacoes-contra-o-calor/"
)

UV_LEVELS <- c(
  "Sem dados" = -1,
  "Baixo" = 0,
  "Moderado" = 1,
  "Alto" = 2,
  "Muito Alto" = 3,
  "Extremo" = 4
)

UV_SOURCE_LINKS <- c(
  "- IPMA, Índice Ultravioleta e classes IUV: https://www.ipma.pt/pt/enciclopedia/amb.atmosfera/uv/index.html",
  "- IPMA, previsão do Índice Ultravioleta: https://www.ipma.pt/pt/otempo/prev.uv/",
  "- OMS, índice UV e recomendações de proteção: https://www.who.int/news-room/questions-and-answers/item/radiation-the-ultraviolet-%28uv%29-index",
  "- OMS, radiação ultravioleta e proteção: https://www.who.int/news-room/fact-sheets/detail/ultraviolet-radiation",
  "- EPA, escala do Índice UV conforme orientações internacionais: https://www.epa.gov/sunsafety/uv-index-scale-0"
)

HEAT_WAVE_LEVELS <- c(
  "Sem dados" = -1,
  "Sem critério" = 0,
  "Sinal preventivo de 5 dias" = 1,
  "Possível Onda de Calor" = 2,
  "Onda de Calor" = 3
)

HEAT_WAVE_NORMAL_PERIOD <- "1991-2020"
HEAT_WAVE_NORMAL_STATION <- "Porto/Pedras Rubras (estação IPMA 545)"
HEAT_WAVE_NORMAL_TMAX <- c(
  "1" = 14.0,
  "2" = 15.0,
  "3" = 17.0,
  "4" = 18.1,
  "5" = 20.3,
  "6" = 22.7,
  "7" = 24.3,
  "8" = 24.8,
  "9" = 23.5,
  "10" = 20.7,
  "11" = 16.8,
  "12" = 14.7
)
HEAT_WAVE_THRESHOLD_DELTA_C <- 5

HEAT_WAVE_SOURCE_LINKS <- c(
  "- IPMA, definição de Onda de Calor: https://www.ipma.pt/pt/enciclopedia/clima/index.html?page=onda.calor.xml",
  "- IPMA, monitorização de Ondas de Calor: https://www.ipma.pt/pt/oclima/ondascalor/",
  "- IPMA, Normal Climatológica 1991-2020 - Porto/Pedras Rubras: https://www.ipma.pt/opencms/bin/file.data/climate-normal/cn_91-20_PORTO_PEDRAS_RUBRAS.pdf",
  "- DGS, recomendações para ondas de calor: https://www.dgs.pt/saude-ambiental-calor/recomendacoes.aspx",
  "- DGS, calor - perguntas e respostas: https://www.dgs.pt/paginas-de-sistema/saude-de-a-a-z/calor/perguntas-e-respostas.aspx"
)

THERMAL_STRESS_LEVELS <- c(
  "Sem dados" = -1,
  "Sem stress térmico" = 0,
  "Stress por frio ligeiro" = 1,
  "Stress por calor moderado" = 1,
  "Stress por frio moderado" = 2,
  "Stress por calor elevado" = 2,
  "Stress por frio elevado" = 3,
  "Stress por calor muito elevado" = 3,
  "Stress por frio muito elevado" = 4,
  "Stress por calor extremo" = 4,
  "Stress por frio extremo" = 5
)

THERMAL_STRESS_SOURCE_LINKS <- c(
  "- IPMA, UTCI - Índice Climático Térmico Universal: https://www.ipma.pt/pt/enciclopedia/amb.atmosfera/index.bioclima/index.html?page=utci.xml",
  "- IPMA, API de dados meteorológicos: https://api.ipma.pt/",
  "- DGS, recomendações para ondas de calor: https://www.dgs.pt/saude-ambiental-calor/recomendacoes.aspx",
  "- DGS, calor - recomendações à população: https://www.dgs.pt/em-destaque/recomendacoes-a-populacao-calor.aspx",
  "- DGS, frio - recomendações gerais: https://www.dgs.pt/saude-ambiental/areas-de-intervencao/frio/recomendacoes-gerais.aspx",
  "- DGS, frio - grupos vulneráveis: https://www.dgs.pt/paginas-de-sistema/saude-de-a-a-z/frio/recomendacoes-para-os-grupos-vulneraveis.aspx"
)

SNS_HEALTH_SOURCE_LINKS <- c(
  "- SNS Transparência/INSA, Evolução diária do Índice ÍCARO: https://transparencia.sns.gov.pt/explore/dataset/evolucao-diaria-do-indice-icaro/",
  "- SNS Transparência/INSA, Índice FRIESA: https://transparencia.sns.gov.pt/explore/dataset/indice-friesa/",
  "- DGS, Índice-Alerta-ÍCARO no Plano de Contingência para Temperaturas Extremas Adversas: https://www.dgs.pt/directrizes-da-dgs/normas-e-circulares-normativas/norma-n-0072015-de-29042015-pdf.aspx",
  "- INSA, FRIESA - modelação e previsão do efeito do frio extremo na saúde: https://repositorio.insa.pt/bitstream/10400.18/3703/3/Newsletter%20fevereiro%202016_FRIESA.pdf",
  "- DGS, recomendações para ondas de calor: https://www.dgs.pt/saude-ambiental-calor/recomendacoes.aspx",
  "- DGS, frio - recomendações gerais: https://www.dgs.pt/saude-ambiental/areas-de-intervencao/frio/recomendacoes-gerais.aspx"
)

CLIMA_EXTREMO_SOURCE_LINKS <- c(
  "- CLIMA EXTREMO, painel de aviso de risco em edifícios: http://climaextremo.vps.tecnico.ulisboa.pt/",
  "- CLIMA EXTREMO, API pública de metadados: http://climaextremo.vps.tecnico.ulisboa.pt:8100/api/weather/metadata",
  "- DGS, recomendações para ondas de calor: https://www.dgs.pt/saude-ambiental-calor/recomendacoes.aspx",
  "- DGS, frio - recomendações gerais: https://www.dgs.pt/saude-ambiental/areas-de-intervencao/frio/recomendacoes-gerais.aspx",
  "- DGS, frio - grupos vulneráveis: https://www.dgs.pt/paginas-de-sistema/saude-de-a-a-z/frio/recomendacoes-para-os-grupos-vulneraveis.aspx"
)

CLIMA_EXTREMO_RISK_LEVELS <- c(
  "Sem dados" = -1,
  "Baixo" = 0,
  "Médio" = 1,
  "Alto" = 2,
  "Extremo" = 3
)

IPMA_ALERT_SOURCE_LINKS <- c(
  "- IPMA, API de avisos meteorológicos e risco de incêndio: https://api.ipma.pt/",
  "- IPMA, guia dos avisos meteorológicos: https://www.ipma.pt/pt/enciclopedia/otempo/sam/index.html",
  "- IPMA, perigo de incêndio rural: https://www.ipma.pt/pt/enciclopedia/otempo/risco.incendio/index.jsp?page=pirdl.xml",
  "- ANEPC, avisos à população e medidas preventivas: https://prociv.gov.pt/pt/avisos-a-populacao/",
  "- ANEPC, perigo de incêndio rural - medidas preventivas: https://prociv.gov.pt/pt/noticias/20082025-perigo-de-incendio-rural-medidas-preventivas/"
)

as_text <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return("")
  }

  value <- x[[1]]
  if (is.na(value)) {
    return("")
  }

  as.character(value)
}

field_text <- function(item, field) {
  if (!field %in% names(item)) {
    return("")
  }

  value <- as_text(item[[field]])
  if (value %in% c("-99", "-99.0", "-99.00")) {
    return("")
  }

  value
}

to_num <- function(x) {
  suppressWarnings(as.numeric(x))
}

round_value <- function(x, digits = 3) {
  value <- to_num(x)
  ifelse(is.na(value), NA_real_, round(value, digits))
}

empty_frame <- function(columns) {
  out <- as.data.frame(
    matrix(character(), nrow = 0, ncol = length(columns)),
    stringsAsFactors = FALSE
  )
  names(out) <- columns
  out
}

fetch_text <- function(url) {
  response <- GET(
    url,
    user_agent("qualar-matosinhos/1.0"),
    config(connecttimeout = 20),
    timeout(30)
  )
  stop_for_status(response)
  content(response, as = "text", encoding = "UTF-8")
}

fetch_csv <- function(url) {
  read_csv(
    I(fetch_text(url)),
    show_col_types = FALSE,
    col_types = cols(.default = "c")
  )
}

fetch_json <- function(url) {
  parsed <- fromJSON(fetch_text(url), simplifyVector = FALSE)
  if (length(parsed) == 0) {
    stop("IPMA returned no data for: ", url)
  }
  parsed
}

read_existing <- function(path, columns) {
  if (!file.exists(path)) {
    return(empty_frame(columns))
  }

  existing <- read_csv(
    path,
    show_col_types = FALSE,
    col_types = cols(.default = "c")
  )

  missing_columns <- setdiff(columns, names(existing))
  if (length(missing_columns) > 0) {
    message(
      "Existing file has an older schema; adding missing columns to ",
      path,
      "."
    )
    for (column in missing_columns) {
      existing[[column]] <- ""
    }
  }

  existing <- as.data.frame(existing[, columns], stringsAsFactors = FALSE)
  existing[] <- lapply(existing, function(column) {
    column <- as.character(column)
    column[is.na(column)] <- ""
    column
  })
  existing
}

same_values <- function(existing_row, new_row, compare_columns) {
  all(vapply(
    compare_columns,
    function(column) identical(
      as_text(existing_row[[column]]),
      as_text(new_row[[column]])
    ),
    logical(1)
  ))
}

same_key <- function(existing, new_row, key_columns) {
  matches <- rep(TRUE, nrow(existing))
  for (column in key_columns) {
    matches <- matches & existing[[column]] == new_row[[column]][1]
  }
  matches
}

upsert_rows <- function(existing, new_rows, columns, key_columns, compare_columns) {
  combined <- existing

  for (i in seq_len(nrow(new_rows))) {
    new_row <- new_rows[i, , drop = FALSE]
    matches <- if (nrow(combined) == 0) {
      logical()
    } else {
      same_key(combined, new_row, key_columns)
    }
    match_index <- which(matches)

    if (length(match_index) > 0 &&
        same_values(combined[match_index[1], , drop = FALSE], new_row, compare_columns)) {
      next
    }

    if (length(match_index) > 0) {
      combined <- combined[-match_index, , drop = FALSE]
    }

    combined <- bind_rows(combined, new_row)
  }

  combined[, columns]
}

build_temperature_history <- function() {
  tmin <- fetch_csv(TMIN_URL)
  tmax <- fetch_csv(TMAX_URL)

  tmin_daily <- tmin %>%
    transmute(
      date = as.character(date),
      tmin_c = round_value(mean),
      tmin_concelho_min_c = round_value(minimum),
      tmin_concelho_max_c = round_value(maximum)
    )

  tmax_daily <- tmax %>%
    transmute(
      date = as.character(date),
      tmax_c = round_value(mean),
      tmax_concelho_min_c = round_value(minimum),
      tmax_concelho_max_c = round_value(maximum)
    )

  output <- full_join(tmin_daily, tmax_daily, by = "date") %>%
    mutate(
      location = LOCATION,
      district = DISTRICT,
      dico = DICO,
      tmean_estimated_c = round((tmin_c + tmax_c) / 2, 3),
      source = paste(
        "IPMA open-data observation/climate temperature-min",
        "and temperature-max by municipality"
      ),
      fetched_at = FETCHED_AT
    ) %>%
    arrange(date) %>%
    select(all_of(TEMPERATURE_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)

  output[] <- lapply(output, as.character)
  output
}

parse_ipma_datetime <- function(value) {
  value <- sub("Z$", "", value)
  format <- ifelse(grepl(":\\d{2}:\\d{2}$", value), "%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M")
  as.POSIXct(value, format = format, tz = "UTC")
}

station_name <- function(station_id) {
  match <- FALLBACK_STATIONS$station_name[FALLBACK_STATIONS$station_id == station_id]
  if (length(match) == 0) {
    return("")
  }

  match[[1]]
}

flatten_station_observations <- function(api_data) {
  rows <- list()

  for (datetime_text in names(api_data)) {
    timestamp <- parse_ipma_datetime(datetime_text)
    if (is.na(timestamp)) {
      next
    }

    datetime_utc <- format(timestamp, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    datetime_local <- format(timestamp, "%Y-%m-%dT%H:%M:%S%z", tz = LOCAL_TZ)
    date_local <- format(timestamp, "%Y-%m-%d", tz = LOCAL_TZ)

    for (station_id in FALLBACK_STATIONS$station_id) {
      if (!station_id %in% names(api_data[[datetime_text]])) {
        next
      }

      observation <- api_data[[datetime_text]][[station_id]]
      temperature <- field_text(observation, "temperatura")
      if (temperature == "") {
        next
      }

      rows[[length(rows) + 1]] <- data.frame(
        datetime_utc = datetime_utc,
        datetime_local = datetime_local,
        date_local = date_local,
        station_id = station_id,
        station_name = station_name(station_id),
        temperature_c = temperature,
        source = "IPMA station hourly observations",
        fetched_at = FETCHED_AT,
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(rows) == 0) {
    return(empty_frame(STATION_OBSERVATION_COLUMNS))
  }

  observations <- bind_rows(rows)
  observations[] <- lapply(observations, as.character)
  observations[, STATION_OBSERVATION_COLUMNS]
}

build_station_observations <- function() {
  flatten_station_observations(fetch_json(STATION_OBSERVATIONS_URL))
}

period_type <- function(period_hours) {
  switch(
    as.character(period_hours),
    "1" = "hourly",
    "3" = "three_hourly",
    "24" = "daily",
    "other"
  )
}

forecast_date <- function(forecast_datetime) {
  if (forecast_datetime == "") {
    return("")
  }

  substr(forecast_datetime, 1, 10)
}

flatten_forecast <- function(item) {
  period_hours <- field_text(item, "idPeriodo")
  data.frame(
    source_updated_at = field_text(item, "dataUpdate"),
    fetched_at = FETCHED_AT,
    location = LOCATION,
    district = DISTRICT,
    global_id_local = GLOBAL_ID_LOCAL,
    latitude = LATITUDE,
    longitude = LONGITUDE,
    forecast_datetime_utc = field_text(item, "dataPrev"),
    forecast_date = forecast_date(field_text(item, "dataPrev")),
    period_hours = period_hours,
    period_type = period_type(period_hours),
    intervalo_hora = field_text(item, "intervaloHora"),
    weather_type_id = field_text(item, "idTipoTempo"),
    precipitation_intensity_id = field_text(item, "idIntensidadePrecipita"),
    precipitation_probability_percent = field_text(item, "probabilidadePrecipita"),
    tmed_c = field_text(item, "tMed"),
    tmin_c = field_text(item, "tMin"),
    tmax_c = field_text(item, "tMax"),
    humidity_percent = field_text(item, "hR"),
    utci_c = field_text(item, "utci"),
    wind_speed_kmh = field_text(item, "ffVento"),
    wind_speed_class_id = field_text(item, "idFfxVento"),
    wind_direction = field_text(item, "ddVento"),
    uv_index = field_text(item, "iUv"),
    source = "IPMA public-data forecast aggregate by local",
    stringsAsFactors = FALSE
  )
}

build_forecasts <- function() {
  api_data <- fetch_json(FORECAST_URL)
  forecasts <- bind_rows(lapply(api_data, flatten_forecast))
  forecasts[] <- lapply(forecasts, as.character)

  forecasts %>%
    arrange(source_updated_at, forecast_datetime_utc, period_hours) %>%
    select(all_of(FORECAST_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

write_temperature_history <- function(new_data) {
  existing <- read_existing(TEMPERATURE_PATH, TEMPERATURE_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    TEMPERATURE_COLUMNS,
    TEMPERATURE_KEY_COLUMNS,
    setdiff(TEMPERATURE_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(date) %>%
    distinct(across(all_of(TEMPERATURE_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, TEMPERATURE_PATH, na = "")
  combined
}

write_forecasts <- function(new_data) {
  existing <- read_existing(FORECAST_PATH, FORECAST_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    FORECAST_COLUMNS,
    FORECAST_KEY_COLUMNS,
    setdiff(FORECAST_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(source_updated_at, forecast_datetime_utc, period_hours) %>%
    distinct(across(all_of(FORECAST_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, FORECAST_PATH, na = "")

  latest_source_update <- max(combined$source_updated_at, na.rm = TRUE)
  latest <- combined[combined$source_updated_at == latest_source_update, , drop = FALSE]
  write_csv(latest, FORECAST_LATEST_PATH, na = "")

  list(combined = combined, latest = latest)
}

write_station_observations <- function(new_data) {
  existing <- read_existing(STATION_OBSERVATIONS_PATH, STATION_OBSERVATION_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    STATION_OBSERVATION_COLUMNS,
    STATION_OBSERVATION_KEY_COLUMNS,
    setdiff(STATION_OBSERVATION_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(datetime_utc, station_id) %>%
    distinct(across(all_of(STATION_OBSERVATION_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, STATION_OBSERVATIONS_PATH, na = "")
  combined
}

build_station_daily_temperatures <- function(station_observations) {
  if (nrow(station_observations) == 0) {
    return(empty_frame(STATION_DAILY_TEMPERATURE_COLUMNS))
  }

  today <- as.Date(format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ))

  station_daily <- station_observations %>%
    mutate(
      date = as.character(date_local),
      temperature_num = to_num(temperature_c)
    ) %>%
    filter(!is.na(temperature_num), as.Date(date) < today) %>%
    group_by(date, station_id, station_name) %>%
    summarise(
      station_tmin_c = min(temperature_num, na.rm = TRUE),
      station_tmax_c = max(temperature_num, na.rm = TRUE),
      hourly_observations = n(),
      .groups = "drop"
    )

  if (nrow(station_daily) == 0) {
    return(empty_frame(STATION_DAILY_TEMPERATURE_COLUMNS))
  }

  daily <- station_daily %>%
    group_by(date) %>%
    summarise(
      location = LOCATION,
      district = DISTRICT,
      station_count = n_distinct(station_id),
      station_ids = paste(sort(unique(station_id)), collapse = ";"),
      station_names = paste(sort(unique(station_name)), collapse = "; "),
      tmin_c = round(mean(station_tmin_c, na.rm = TRUE), 3),
      tmax_c = round(mean(station_tmax_c, na.rm = TRUE), 3),
      min_hourly_observations = min(hourly_observations, na.rm = TRUE),
      source = "IPMA station fallback: daily mean of Pedras Rubras and S. Gens station extrema",
      fetched_at = FETCHED_AT,
      .groups = "drop"
    ) %>%
    arrange(date) %>%
    select(all_of(STATION_DAILY_TEMPERATURE_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)

  daily[] <- lapply(daily, as.character)
  daily
}

write_station_daily_temperatures <- function(new_data) {
  existing <- read_existing(STATION_DAILY_TEMPERATURES_PATH, STATION_DAILY_TEMPERATURE_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    STATION_DAILY_TEMPERATURE_COLUMNS,
    STATION_DAILY_TEMPERATURE_KEY_COLUMNS,
    setdiff(STATION_DAILY_TEMPERATURE_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(date) %>%
    distinct(across(all_of(STATION_DAILY_TEMPERATURE_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, STATION_DAILY_TEMPERATURES_PATH, na = "")
  combined
}

is_blank <- function(value) {
  value <- as_text(value)
  value == "" || is.na(to_num(value))
}

recalculate_tmean <- function(row) {
  tmin <- to_num(row$tmin_c)
  tmax <- to_num(row$tmax_c)
  if (is.na(tmin) || is.na(tmax)) {
    return("")
  }

  as.character(round((tmin + tmax) / 2, 3))
}

station_daily_as_temperature_rows <- function(station_daily) {
  if (nrow(station_daily) == 0) {
    return(empty_frame(TEMPERATURE_COLUMNS))
  }

  rows <- station_daily %>%
    transmute(
      date = as.character(date),
      location = LOCATION,
      district = DISTRICT,
      dico = DICO,
      tmean_estimated_c = as.character(round((to_num(tmin_c) + to_num(tmax_c)) / 2, 3)),
      tmin_c = as.character(round(to_num(tmin_c), 3)),
      tmax_c = as.character(round(to_num(tmax_c), 3)),
      tmin_concelho_min_c = "",
      tmin_concelho_max_c = "",
      tmax_concelho_min_c = "",
      tmax_concelho_max_c = "",
      source = paste0(
        source,
        " (station_count=",
        station_count,
        "; station_names=",
        station_names,
        ")"
      ),
      fetched_at = FETCHED_AT
    ) %>%
    as.data.frame(stringsAsFactors = FALSE)

  rows[] <- lapply(rows, as.character)
  rows[, TEMPERATURE_COLUMNS]
}

apply_station_temperature_fallback <- function(climate_data, station_daily) {
  fallback_rows <- station_daily_as_temperature_rows(station_daily)
  combined <- climate_data

  for (i in seq_len(nrow(fallback_rows))) {
    fallback <- fallback_rows[i, , drop = FALSE]
    match_index <- which(combined$date == fallback$date[1])

    if (length(match_index) == 0) {
      combined <- bind_rows(combined, fallback)
      next
    }

    index <- match_index[1]
    used_fallback <- FALSE

    if (is_blank(combined$tmin_c[index]) && !is_blank(fallback$tmin_c[1])) {
      combined$tmin_c[index] <- fallback$tmin_c[1]
      used_fallback <- TRUE
    }

    if (is_blank(combined$tmax_c[index]) && !is_blank(fallback$tmax_c[1])) {
      combined$tmax_c[index] <- fallback$tmax_c[1]
      used_fallback <- TRUE
    }

    if (used_fallback) {
      combined$tmean_estimated_c[index] <- recalculate_tmean(combined[index, , drop = FALSE])
      combined$source[index] <- paste(combined$source[index], fallback$source[1], sep = "; ")
    }
  }

  combined %>%
    arrange(date) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

latest_source_update <- function(data) {
  valid <- data$source_updated_at[data$source_updated_at != ""]
  if (length(valid) == 0) {
    return("")
  }

  max(valid, na.rm = TRUE)
}

daily_forecast_rows <- function(forecasts) {
  forecasts %>%
    filter(period_hours == "24") %>%
    arrange(forecast_date) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

value_for_date <- function(data, date, column) {
  match <- data[data$date == as.character(date), , drop = FALSE]
  if (nrow(match) == 0 || !column %in% names(match)) {
    return(NA_real_)
  }

  value <- to_num(match[[column]][1])
  ifelse(is.na(value), NA_real_, value)
}

forecast_value_for_date <- function(daily_forecasts, date, column) {
  match <- daily_forecasts[daily_forecasts$forecast_date == as.character(date), , drop = FALSE]
  if (nrow(match) == 0 || !column %in% names(match)) {
    return(NA_real_)
  }

  value <- to_num(match[[column]][1])
  ifelse(is.na(value), NA_real_, value)
}

has_missing <- function(values) {
  any(is.na(unlist(values, use.names = FALSE)))
}

alert_level <- function(label) {
  if (!label %in% names(HEAT_LEVELS)) {
    return("")
  }

  as.character(HEAT_LEVELS[[label]])
}

season_thresholds <- function(target_date, kind) {
  month_value <- as.integer(format(as.Date(target_date), "%m"))
  applicable <- month_value >= 5 && month_value <= 10
  warm_rule <- month_value >= 7 && month_value <= 10

  if (!applicable) {
    return(list(
      applicable = FALSE,
      rule = "fora de epoca DSP",
      thresholds = c(yellow = NA_real_, red = NA_real_)
    ))
  }

  if (kind == "max") {
    thresholds <- if (warm_rule) {
      c(yellow = 33, red = 35)
    } else {
      c(yellow = 32, red = 34)
    }
  } else {
    thresholds <- if (warm_rule) {
      c(yellow = 22, red = 25)
    } else {
      c(yellow = 21, red = 24)
    }
  }

  list(
    applicable = TRUE,
    rule = ifelse(
      warm_rule,
      "mes 7-10",
      "mes 5-6"
    ),
    thresholds = thresholds
  )
}

classify_tmax_alert <- function(target_date, obs_m3, obs_m2, obs_m1, forecast_d0, forecast_p1) {
  season <- season_thresholds(target_date, "max")
  thresholds <- season$thresholds
  values <- c(obs_m3, obs_m2, obs_m1, forecast_d0, forecast_p1)

  if (!season$applicable) {
    return(list(
      alert = "Fora de época",
      level = alert_level("Fora de época"),
      yellow = "",
      red = ""
    ))
  }

  if (has_missing(values)) {
    return(list(
      alert = "Sem dados",
      level = alert_level("Sem dados"),
      yellow = thresholds[["yellow"]],
      red = thresholds[["red"]]
    ))
  }

  alert <- if (all(values >= thresholds[["red"]])) {
    "Vermelho"
  } else if (all(c(obs_m1, forecast_d0, forecast_p1) >= thresholds[["yellow"]])) {
    "Amarelo"
  } else {
    "Verde"
  }

  list(
    alert = alert,
    level = alert_level(alert),
    yellow = thresholds[["yellow"]],
    red = thresholds[["red"]]
  )
}

classify_tmin_alert <- function(target_date, obs_m2, obs_m1, forecast_d0, forecast_p1) {
  season <- season_thresholds(target_date, "min")
  thresholds <- season$thresholds
  values <- c(obs_m2, obs_m1, forecast_d0, forecast_p1)

  if (!season$applicable) {
    return(list(
      alert = "Fora de época",
      level = alert_level("Fora de época"),
      yellow = "",
      red = ""
    ))
  }

  if (has_missing(values)) {
    return(list(
      alert = "Sem dados",
      level = alert_level("Sem dados"),
      yellow = thresholds[["yellow"]],
      red = thresholds[["red"]]
    ))
  }

  alert <- if (all(values >= thresholds[["red"]])) {
    "Vermelho"
  } else if (all(values >= thresholds[["yellow"]])) {
    "Amarelo"
  } else {
    "Verde"
  }

  list(
    alert = alert,
    level = alert_level(alert),
    yellow = thresholds[["yellow"]],
    red = thresholds[["red"]]
  )
}

overall_heat_alert <- function(tmax_alert, tmin_alert) {
  levels <- c(to_num(alert_level(tmax_alert)), to_num(alert_level(tmin_alert)))
  if (all(levels == to_num(alert_level("Fora de época")))) {
    return("Fora de época")
  }

  if (all(levels < 0)) {
    return("Sem dados")
  }

  max_level <- max(levels, na.rm = TRUE)
  names(HEAT_LEVELS)[HEAT_LEVELS == max_level][1]
}

format_temp <- function(value) {
  if (is.na(value)) {
    return("")
  }

  as.character(round(value, 1))
}

display_temp <- function(value) {
  value <- as_text(value)
  if (value == "") {
    return("sem dados")
  }

  value
}

threshold_pair_text <- function(yellow, red) {
  yellow <- as_text(yellow)
  red <- as_text(red)

  if (yellow == "" || red == "") {
    return("não aplicáveis")
  }

  paste0(yellow, "/", red, " ºC")
}

missing_inputs_text <- function(values) {
  missing <- names(values)[is.na(unlist(values, use.names = FALSE))]
  if (length(missing) == 0) {
    return("")
  }

  paste(missing, collapse = "; ")
}

recommendation_summary <- function(overall_alert, tmax_alert, tmin_alert) {
  if (overall_alert == "Fora de época") {
    return("Indicador DSP de temperatura fora da época de aplicação operacional (maio a outubro).")
  }

  if (overall_alert == "Sem dados") {
    return("Dados insuficientes para emitir alerta automático de temperatura DSP.")
  }

  if (overall_alert == "Verde") {
    return("Manter vigilância habitual, hidratação regular e monitorização das atualizações meteorológicas.")
  }

  advice <- character()

  if (tmax_alert %in% c("Amarelo", "Vermelho")) {
    advice <- c(
      advice,
      "calor diurno persistente: reduzir exposição direta ao sol e esforço físico nas horas de maior calor"
    )
  }

  if (tmin_alert %in% c("Amarelo", "Vermelho")) {
    advice <- c(
      advice,
      "noites quentes persistentes: reforçar arrefecimento noturno, hidratação e contacto com pessoas isoladas"
    )
  }

  paste(advice, collapse = "; ")
}

build_temperature_alerts <- function(temperature_history, latest_forecasts) {
  daily_forecasts <- daily_forecast_rows(latest_forecasts)
  source_update <- latest_source_update(daily_forecasts)

  if (nrow(daily_forecasts) == 0 || source_update == "") {
    return(empty_frame(TEMPERATURE_ALERT_COLUMNS))
  }

  rows <- lapply(seq_len(nrow(daily_forecasts)), function(i) {
    target_date <- as.Date(daily_forecasts$forecast_date[i])
    season <- season_thresholds(target_date, "max")

    tmax_obs_m3 <- value_for_date(temperature_history, target_date - 3, "tmax_c")
    tmax_obs_m2 <- value_for_date(temperature_history, target_date - 2, "tmax_c")
    tmax_obs_m1 <- value_for_date(temperature_history, target_date - 1, "tmax_c")
    tmax_forecast_d0 <- forecast_value_for_date(daily_forecasts, target_date, "tmax_c")
    tmax_forecast_p1 <- forecast_value_for_date(daily_forecasts, target_date + 1, "tmax_c")

    tmin_obs_m2 <- value_for_date(temperature_history, target_date - 2, "tmin_c")
    tmin_obs_m1 <- value_for_date(temperature_history, target_date - 1, "tmin_c")
    tmin_forecast_d0 <- forecast_value_for_date(daily_forecasts, target_date, "tmin_c")
    tmin_forecast_p1 <- forecast_value_for_date(daily_forecasts, target_date + 1, "tmin_c")

    tmax <- classify_tmax_alert(
      target_date,
      tmax_obs_m3,
      tmax_obs_m2,
      tmax_obs_m1,
      tmax_forecast_d0,
      tmax_forecast_p1
    )
    tmin <- classify_tmin_alert(
      target_date,
      tmin_obs_m2,
      tmin_obs_m1,
      tmin_forecast_d0,
      tmin_forecast_p1
    )
    overall <- overall_heat_alert(tmax$alert, tmin$alert)

    missing <- missing_inputs_text(c(
      tmax_observed_d_minus_3_c = tmax_obs_m3,
      tmax_observed_d_minus_2_c = tmax_obs_m2,
      tmax_observed_d_minus_1_c = tmax_obs_m1,
      tmax_forecast_d0_c = tmax_forecast_d0,
      tmax_forecast_d_plus_1_c = tmax_forecast_p1,
      tmin_observed_d_minus_2_c = tmin_obs_m2,
      tmin_observed_d_minus_1_c = tmin_obs_m1,
      tmin_forecast_d0_c = tmin_forecast_d0,
      tmin_forecast_d_plus_1_c = tmin_forecast_p1
    ))

    data.frame(
      source_updated_at = source_update,
      fetched_at = FETCHED_AT,
      location = LOCATION,
      district = DISTRICT,
      dico = DICO,
      global_id_local = GLOBAL_ID_LOCAL,
      target_date = as.character(target_date),
      season_rule = season$rule,
      tmax_alert = tmax$alert,
      tmax_alert_level = tmax$level,
      tmax_yellow_threshold_c = as.character(tmax$yellow),
      tmax_red_threshold_c = as.character(tmax$red),
      tmax_observed_d_minus_3_c = format_temp(tmax_obs_m3),
      tmax_observed_d_minus_2_c = format_temp(tmax_obs_m2),
      tmax_observed_d_minus_1_c = format_temp(tmax_obs_m1),
      tmax_forecast_d0_c = format_temp(tmax_forecast_d0),
      tmax_forecast_d_plus_1_c = format_temp(tmax_forecast_p1),
      tmin_alert = tmin$alert,
      tmin_alert_level = tmin$level,
      tmin_yellow_threshold_c = as.character(tmin$yellow),
      tmin_red_threshold_c = as.character(tmin$red),
      tmin_observed_d_minus_2_c = format_temp(tmin_obs_m2),
      tmin_observed_d_minus_1_c = format_temp(tmin_obs_m1),
      tmin_forecast_d0_c = format_temp(tmin_forecast_d0),
      tmin_forecast_d_plus_1_c = format_temp(tmin_forecast_p1),
      overall_temperature_alert = overall,
      overall_temperature_alert_level = alert_level(overall),
      missing_inputs = missing,
      recommendation_summary = recommendation_summary(overall, tmax$alert, tmin$alert),
      source = "DSP temperature rule using IPMA observed municipality temperatures and IPMA forecasts",
      stringsAsFactors = FALSE
    )
  })

  alerts <- bind_rows(rows)
  alerts[] <- lapply(alerts, as.character)
  alerts[, TEMPERATURE_ALERT_COLUMNS]
}

write_temperature_alerts <- function(new_data) {
  existing <- read_existing(TEMPERATURE_ALERTS_PATH, TEMPERATURE_ALERT_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    TEMPERATURE_ALERT_COLUMNS,
    TEMPERATURE_ALERT_KEY_COLUMNS,
    setdiff(TEMPERATURE_ALERT_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(source_updated_at, target_date) %>%
    distinct(across(all_of(TEMPERATURE_ALERT_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, TEMPERATURE_ALERTS_PATH, na = "")

  latest_update <- latest_source_update(combined)
  latest <- combined[combined$source_updated_at == latest_update, , drop = FALSE]
  write_csv(latest, TEMPERATURE_ALERTS_LATEST_PATH, na = "")

  list(combined = combined, latest = latest)
}

classify_uv <- function(value) {
  uv <- to_num(value)
  if (is.na(uv)) {
    return(list(
      level = "Sem dados",
      order = as.character(UV_LEVELS[["Sem dados"]]),
      color = "",
      protection = "Sem dados"
    ))
  }

  if (uv < 3) {
    return(list(
      level = "Baixo",
      order = as.character(UV_LEVELS[["Baixo"]]),
      color = "Verde",
      protection = "Proteção mínima"
    ))
  }

  if (uv < 6) {
    return(list(
      level = "Moderado",
      order = as.character(UV_LEVELS[["Moderado"]]),
      color = "Amarelo",
      protection = "Proteção necessária"
    ))
  }

  if (uv < 8) {
    return(list(
      level = "Alto",
      order = as.character(UV_LEVELS[["Alto"]]),
      color = "Laranja",
      protection = "Proteção reforçada"
    ))
  }

  if (uv < 11) {
    return(list(
      level = "Muito Alto",
      order = as.character(UV_LEVELS[["Muito Alto"]]),
      color = "Vermelho",
      protection = "Proteção extra"
    ))
  }

  list(
    level = "Extremo",
    order = as.character(UV_LEVELS[["Extremo"]]),
    color = "Violeta",
    protection = "Evitar exposição"
  )
}

uv_recommendation_summary <- function(level) {
  switch(
    level,
    "Sem dados" = "Sem dados de Índice UV para emitir recomendação automática.",
    "Baixo" = "Risco baixo; manter vigilância e proteção básica para pele/olhos sensíveis.",
    "Moderado" = "Proteção necessária; usar óculos com filtro UV, chapéu, roupa que cubra a pele e protetor solar em pele exposta.",
    "Alto" = "Proteção reforçada; reduzir exposição nas horas centrais, procurar sombra e usar proteção ocular, chapéu, roupa e protetor solar.",
    "Muito Alto" = "Proteção extra; evitar exposição prolongada nas horas centrais e reforçar sombra, roupa, chapéu, óculos e protetor solar.",
    "Extremo" = "Evitar exposição solar tanto quanto possível, sobretudo nas horas centrais; atividades exteriores devem ser adiadas ou fortemente condicionadas.",
    "Confirmar manualmente o nível UV antes de comunicar."
  )
}

build_uv_index <- function(latest_forecasts) {
  daily_forecasts <- daily_forecast_rows(latest_forecasts)
  source_update <- latest_source_update(daily_forecasts)

  if (nrow(daily_forecasts) == 0 || source_update == "") {
    return(empty_frame(UV_INDEX_COLUMNS))
  }

  rows <- lapply(seq_len(nrow(daily_forecasts)), function(i) {
    uv_value <- field_text(as.list(daily_forecasts[i, , drop = FALSE]), "uv_index")
    classification <- classify_uv(uv_value)

    data.frame(
      source_updated_at = source_update,
      fetched_at = FETCHED_AT,
      location = LOCATION,
      district = DISTRICT,
      global_id_local = GLOBAL_ID_LOCAL,
      target_date = as_text(daily_forecasts$forecast_date[i]),
      uv_index = uv_value,
      uv_level = classification$level,
      uv_level_order = classification$order,
      uv_color = classification$color,
      protection_required = classification$protection,
      recommendation_summary = uv_recommendation_summary(classification$level),
      source = "IPMA public-data forecast aggregate daily UV index",
      stringsAsFactors = FALSE
    )
  })

  uv <- bind_rows(rows)
  uv[] <- lapply(uv, as.character)
  uv[, UV_INDEX_COLUMNS]
}

write_uv_index <- function(new_data) {
  existing <- read_existing(UV_INDEX_PATH, UV_INDEX_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    UV_INDEX_COLUMNS,
    UV_INDEX_KEY_COLUMNS,
    setdiff(UV_INDEX_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(source_updated_at, target_date) %>%
    distinct(across(all_of(UV_INDEX_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, UV_INDEX_PATH, na = "")

  latest_update <- latest_source_update(combined)
  latest <- combined[combined$source_updated_at == latest_update, , drop = FALSE]
  write_csv(latest, UV_INDEX_LATEST_PATH, na = "")

  list(combined = combined, latest = latest)
}

normal_tmax_for_date <- function(date) {
  month_value <- as.character(as.integer(format(as.Date(date), "%m")))
  value <- HEAT_WAVE_NORMAL_TMAX[[month_value]]
  if (is.null(value)) {
    return(NA_real_)
  }

  value
}

heat_wave_level <- function(status) {
  if (!status %in% names(HEAT_WAVE_LEVELS)) {
    return("")
  }

  as.character(HEAT_WAVE_LEVELS[[status]])
}

build_heat_wave_series <- function(temperature_history, daily_forecasts) {
  observed <- temperature_history %>%
    transmute(
      date = as.Date(date),
      tmax_c = to_num(tmax_c),
      tmax_source = "observed"
    )

  forecast <- daily_forecasts %>%
    transmute(
      date = as.Date(forecast_date),
      tmax_c = to_num(tmax_c),
      tmax_source = "forecast"
    )

  combined <- bind_rows(observed, forecast) %>%
    filter(!is.na(date))

  if (nrow(combined) == 0) {
    return(data.frame(
      date = as.Date(character()),
      tmax_c = numeric(),
      tmax_source = character(),
      normal_tmax_c = numeric(),
      threshold_c = numeric(),
      exceeds_threshold = logical(),
      stringsAsFactors = FALSE
    ))
  }

  chosen <- combined %>%
    mutate(
      has_value = !is.na(tmax_c),
      preference = case_when(
        has_value & tmax_source == "observed" ~ 1,
        has_value & tmax_source == "forecast" ~ 2,
        tmax_source == "observed" ~ 3,
        TRUE ~ 4
      )
    ) %>%
    arrange(date, preference) %>%
    group_by(date) %>%
    slice(1) %>%
    ungroup() %>%
    select(date, tmax_c, tmax_source)

  full_dates <- data.frame(
    date = seq(min(chosen$date), max(chosen$date), by = "day"),
    stringsAsFactors = FALSE
  )

  series <- full_dates %>%
    left_join(chosen, by = "date") %>%
    arrange(date) %>%
    as.data.frame(stringsAsFactors = FALSE)

  series$normal_tmax_c <- vapply(
    seq_along(series$date),
    function(i) normal_tmax_for_date(series$date[i]),
    numeric(1)
  )
  series$threshold_c <- series$normal_tmax_c + HEAT_WAVE_THRESHOLD_DELTA_C
  series$exceeds_threshold <- !is.na(series$tmax_c) &
    !is.na(series$threshold_c) &
    series$tmax_c > series$threshold_c

  series
}

window_marks <- function(series, window_size) {
  n <- nrow(series)
  matched <- rep(FALSE, n)
  forecast_in_window <- rep(FALSE, n)
  window_start <- rep("", n)
  window_end <- rep("", n)

  if (n < window_size) {
    return(list(
      matched = matched,
      forecast_in_window = forecast_in_window,
      window_start = window_start,
      window_end = window_end
    ))
  }

  for (i in seq_len(n - window_size + 1)) {
    indices <- i:(i + window_size - 1)
    if (any(is.na(series$tmax_c[indices])) ||
        any(is.na(series$threshold_c[indices])) ||
        !all(series$exceeds_threshold[indices])) {
      next
    }

    uses_forecast <- any(series$tmax_source[indices] == "forecast")
    for (index in indices) {
      matched[index] <- TRUE
      forecast_in_window[index] <- forecast_in_window[index] || uses_forecast
      if (window_start[index] == "") {
        window_start[index] <- as.character(series$date[indices[1]])
        window_end[index] <- as.character(series$date[indices[window_size]])
      }
    }
  }

  list(
    matched = matched,
    forecast_in_window = forecast_in_window,
    window_start = window_start,
    window_end = window_end
  )
}

contiguous_lengths <- function(series, predicate) {
  n <- nrow(series)
  lengths <- rep(0L, n)

  for (i in seq_len(n)) {
    if (!isTRUE(predicate[i])) {
      next
    }

    left <- i
    while (left > 1 && isTRUE(predicate[left - 1])) {
      left <- left - 1
    }

    right <- i
    while (right < n && isTRUE(predicate[right + 1])) {
      right <- right + 1
    }

    lengths[i] <- right - left + 1L
  }

  lengths
}

heat_wave_status <- function(tmax, threshold, heat_wave, forecast_heat_wave, pre_heat_wave) {
  if (is.na(tmax) || is.na(threshold)) {
    return("Sem dados")
  }

  if (isTRUE(heat_wave) && isTRUE(forecast_heat_wave)) {
    return("Possível Onda de Calor")
  }

  if (isTRUE(heat_wave)) {
    return("Onda de Calor")
  }

  if (isTRUE(pre_heat_wave)) {
    return("Sinal preventivo de 5 dias")
  }

  "Sem critério"
}

heat_wave_missing_inputs <- function(tmax, threshold, available_window_days, exceeds_threshold) {
  missing <- character()
  if (is.na(tmax)) {
    missing <- c(missing, "tmax_c")
  }
  if (is.na(threshold)) {
    missing <- c(missing, "normal_tmax_c")
  }
  if (isTRUE(exceeds_threshold) && available_window_days < 6) {
    missing <- c(missing, "janela de 6 dias incompleta")
  }

  paste(missing, collapse = "; ")
}

heat_wave_recommendation_summary <- function(status) {
  switch(
    status,
    "Sem dados" = "Dados insuficientes para avaliar automaticamente o critério de onda de calor.",
    "Sem critério" = "Sem critério de onda de calor no horizonte disponível; manter vigilância e acompanhar atualizações.",
    "Sinal preventivo de 5 dias" = "Sinal preventivo: sequência de 5 dias acima do limiar; preparar medidas caso a tendência se prolongue.",
    "Possível Onda de Calor" = "Possível onda de calor com base em valores observados e previstos; reforçar medidas de prevenção do calor e acompanhar novas previsões.",
    "Onda de Calor" = "Onda de calor confirmada por 6 ou mais dias consecutivos acima do limiar; ativar medidas de prevenção e proteção de grupos vulneráveis.",
    "Confirmar manualmente o estado de onda de calor antes de comunicar."
  )
}

build_heat_waves <- function(temperature_history, latest_forecasts) {
  daily_forecasts <- daily_forecast_rows(latest_forecasts)
  source_update <- latest_source_update(daily_forecasts)

  if (nrow(daily_forecasts) == 0 || source_update == "") {
    return(empty_frame(HEAT_WAVE_COLUMNS))
  }

  series <- build_heat_wave_series(temperature_history, daily_forecasts)
  six_day <- window_marks(series, 6)
  five_day <- window_marks(series, 5)
  available_lengths <- contiguous_lengths(series, !is.na(series$tmax_c))
  exceedance_lengths <- contiguous_lengths(series, series$exceeds_threshold)

  target_dates <- sort(unique(as.Date(daily_forecasts$forecast_date)))
  target_dates <- target_dates[!is.na(target_dates)]

  rows <- lapply(seq_along(target_dates), function(i) {
    target_date <- target_dates[i]
    index <- match(target_date, series$date)
    if (is.na(index)) {
      tmax <- NA_real_
      source <- ""
      normal <- normal_tmax_for_date(target_date)
      threshold <- normal + HEAT_WAVE_THRESHOLD_DELTA_C
      exceeds <- FALSE
      available_window_days <- 0L
      consecutive_days <- 0L
      heat_wave <- FALSE
      forecast_heat_wave <- FALSE
      pre_heat_wave <- FALSE
      forecast_pre_heat_wave <- FALSE
      heat_start <- ""
      heat_end <- ""
      pre_start <- ""
      pre_end <- ""
    } else {
      tmax <- series$tmax_c[index]
      source <- as_text(series$tmax_source[index])
      normal <- series$normal_tmax_c[index]
      threshold <- series$threshold_c[index]
      exceeds <- isTRUE(series$exceeds_threshold[index])
      available_window_days <- available_lengths[index]
      consecutive_days <- exceedance_lengths[index]
      heat_wave <- six_day$matched[index]
      forecast_heat_wave <- six_day$forecast_in_window[index]
      pre_heat_wave <- five_day$matched[index]
      forecast_pre_heat_wave <- five_day$forecast_in_window[index]
      heat_start <- six_day$window_start[index]
      heat_end <- six_day$window_end[index]
      pre_start <- five_day$window_start[index]
      pre_end <- five_day$window_end[index]
    }

    status <- heat_wave_status(
      tmax,
      threshold,
      heat_wave,
      forecast_heat_wave,
      pre_heat_wave
    )

    data.frame(
      source_updated_at = source_update,
      fetched_at = FETCHED_AT,
      location = LOCATION,
      district = DISTRICT,
      dico = DICO,
      global_id_local = GLOBAL_ID_LOCAL,
      target_date = as.character(target_date),
      tmax_c = format_temp(tmax),
      tmax_source = source,
      normal_period = HEAT_WAVE_NORMAL_PERIOD,
      normal_station = HEAT_WAVE_NORMAL_STATION,
      normal_tmax_c = format_temp(normal),
      threshold_c = format_temp(threshold),
      exceeds_threshold = ifelse(
        is.na(tmax) || is.na(threshold),
        "",
        as.character(exceeds)
      ),
      available_window_days = as.character(available_window_days),
      consecutive_exceedance_days = as.character(consecutive_days),
      heat_wave_6day = as.character(isTRUE(heat_wave)),
      forecast_in_6day_window = as.character(isTRUE(forecast_heat_wave)),
      pre_heat_wave_5day = as.character(isTRUE(pre_heat_wave)),
      forecast_in_5day_window = as.character(isTRUE(forecast_pre_heat_wave)),
      heat_wave_window_start = heat_start,
      heat_wave_window_end = heat_end,
      pre_heat_wave_window_start = pre_start,
      pre_heat_wave_window_end = pre_end,
      heat_wave_status = status,
      heat_wave_level = heat_wave_level(status),
      missing_inputs = heat_wave_missing_inputs(
        tmax,
        threshold,
        available_window_days,
        exceeds
      ),
      recommendation_summary = heat_wave_recommendation_summary(status),
      source = paste(
        "IPMA heat wave definition using observed IPMA temperatures,",
        "IPMA Matosinhos forecasts and IPMA 1991-2020 Porto/Pedras Rubras normal"
      ),
      stringsAsFactors = FALSE
    )
  })

  heat_waves <- bind_rows(rows)
  heat_waves[] <- lapply(heat_waves, as.character)
  heat_waves[, HEAT_WAVE_COLUMNS]
}

write_heat_waves <- function(new_data) {
  existing <- read_existing(HEAT_WAVE_PATH, HEAT_WAVE_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    HEAT_WAVE_COLUMNS,
    HEAT_WAVE_KEY_COLUMNS,
    setdiff(HEAT_WAVE_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(source_updated_at, target_date) %>%
    distinct(across(all_of(HEAT_WAVE_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, HEAT_WAVE_PATH, na = "")

  latest_update <- latest_source_update(combined)
  latest <- combined[combined$source_updated_at == latest_update, , drop = FALSE]
  write_csv(latest, HEAT_WAVE_LATEST_PATH, na = "")

  list(combined = combined, latest = latest)
}

thermal_stress_level <- function(level) {
  if (!level %in% names(THERMAL_STRESS_LEVELS)) {
    return("")
  }

  as.character(THERMAL_STRESS_LEVELS[[level]])
}

classify_thermal_stress <- function(value) {
  utci <- to_num(value)
  if (is.na(utci)) {
    return(list(
      level = "Sem dados",
      order = thermal_stress_level("Sem dados"),
      color = "",
      stress_type = "Sem dados",
      protection = "Sem dados"
    ))
  }

  if (utci > 46) {
    return(list(
      level = "Stress por calor extremo",
      order = thermal_stress_level("Stress por calor extremo"),
      color = "Vermelho escuro",
      stress_type = "Calor",
      protection = "Evitar exposição"
    ))
  }

  if (utci >= 38) {
    return(list(
      level = "Stress por calor muito elevado",
      order = thermal_stress_level("Stress por calor muito elevado"),
      color = "Vermelho",
      stress_type = "Calor",
      protection = "Proteção muito reforçada"
    ))
  }

  if (utci >= 32) {
    return(list(
      level = "Stress por calor elevado",
      order = thermal_stress_level("Stress por calor elevado"),
      color = "Laranja",
      stress_type = "Calor",
      protection = "Proteção reforçada"
    ))
  }

  if (utci >= 26) {
    return(list(
      level = "Stress por calor moderado",
      order = thermal_stress_level("Stress por calor moderado"),
      color = "Amarelo",
      stress_type = "Calor",
      protection = "Proteção necessária"
    ))
  }

  if (utci >= 9) {
    return(list(
      level = "Sem stress térmico",
      order = thermal_stress_level("Sem stress térmico"),
      color = "Verde",
      stress_type = "Sem stress térmico",
      protection = "Vigilância habitual"
    ))
  }

  if (utci >= 0) {
    return(list(
      level = "Stress por frio ligeiro",
      order = thermal_stress_level("Stress por frio ligeiro"),
      color = "Azul claro",
      stress_type = "Frio",
      protection = "Proteção básica contra frio"
    ))
  }

  if (utci >= -13) {
    return(list(
      level = "Stress por frio moderado",
      order = thermal_stress_level("Stress por frio moderado"),
      color = "Azul",
      stress_type = "Frio",
      protection = "Proteção contra frio"
    ))
  }

  if (utci >= -27) {
    return(list(
      level = "Stress por frio elevado",
      order = thermal_stress_level("Stress por frio elevado"),
      color = "Azul escuro",
      stress_type = "Frio",
      protection = "Proteção reforçada contra frio"
    ))
  }

  if (utci >= -40) {
    return(list(
      level = "Stress por frio muito elevado",
      order = thermal_stress_level("Stress por frio muito elevado"),
      color = "Roxo",
      stress_type = "Frio",
      protection = "Evitar exposição prolongada"
    ))
  }

  list(
    level = "Stress por frio extremo",
    order = thermal_stress_level("Stress por frio extremo"),
    color = "Roxo escuro",
    stress_type = "Frio",
    protection = "Evitar exposição"
  )
}

thermal_stress_recommendation_summary <- function(level) {
  switch(
    level,
    "Sem dados" = "Sem dados UTCI para emitir recomendação automática de stress térmico.",
    "Sem stress térmico" = "Sem stress térmico relevante; manter vigilância habitual.",
    "Stress por calor moderado" = "Stress por calor moderado; reforçar hidratação, sombra e pausas em atividades exteriores.",
    "Stress por calor elevado" = "Stress por calor elevado; reduzir exposição nas horas de pico e adaptar esforço físico no exterior.",
    "Stress por calor muito elevado" = "Stress por calor muito elevado; evitar exposição prolongada, esforço intenso e proteger grupos vulneráveis.",
    "Stress por calor extremo" = "Stress por calor extremo; evitar exposição exterior não essencial e ativar medidas de contingência.",
    "Stress por frio ligeiro" = "Stress por frio ligeiro; usar proteção básica e vigiar pessoas vulneráveis.",
    "Stress por frio moderado" = "Stress por frio moderado; limitar exposição, usar camadas de roupa e manter espaços aquecidos com segurança.",
    "Stress por frio elevado" = "Stress por frio elevado; reduzir atividades exteriores e reforçar acompanhamento de grupos vulneráveis.",
    "Stress por frio muito elevado" = "Stress por frio muito elevado; evitar exposição prolongada e ativar medidas de proteção contra frio.",
    "Stress por frio extremo" = "Stress por frio extremo; evitar exposição exterior não essencial e ativar medidas de emergência para frio.",
    "Confirmar manualmente o nível UTCI antes de comunicar."
  )
}

forecast_datetime_local <- function(value) {
  timestamp <- parse_ipma_datetime(value)
  if (is.na(timestamp)) {
    return("")
  }

  format(timestamp, "%Y-%m-%d %H:%M", tz = LOCAL_TZ)
}

has_utci_value <- function(row) {
  !is.na(to_num(row$utci_c))
}

build_thermal_stress <- function(latest_forecasts) {
  source_update <- latest_source_update(latest_forecasts)
  if (nrow(latest_forecasts) == 0 || source_update == "") {
    return(empty_frame(THERMAL_STRESS_COLUMNS))
  }

  rows_with_utci <- latest_forecasts[
    vapply(seq_len(nrow(latest_forecasts)), function(i) {
      !is.na(to_num(latest_forecasts$utci_c[i]))
    }, logical(1)),
    ,
    drop = FALSE
  ]

  if (nrow(rows_with_utci) == 0) {
    return(empty_frame(THERMAL_STRESS_COLUMNS))
  }

  rows <- lapply(seq_len(nrow(rows_with_utci)), function(i) {
    row <- rows_with_utci[i, , drop = FALSE]
    classification <- classify_thermal_stress(row$utci_c)

    data.frame(
      source_updated_at = source_update,
      fetched_at = FETCHED_AT,
      location = LOCATION,
      district = DISTRICT,
      global_id_local = GLOBAL_ID_LOCAL,
      target_date = as_text(row$forecast_date),
      forecast_datetime_utc = as_text(row$forecast_datetime_utc),
      forecast_datetime_local = forecast_datetime_local(row$forecast_datetime_utc),
      period_hours = as_text(row$period_hours),
      utci_c = format_temp(to_num(row$utci_c)),
      thermal_level = classification$level,
      thermal_level_order = classification$order,
      thermal_color = classification$color,
      thermal_stress_type = classification$stress_type,
      protection_required = classification$protection,
      recommendation_summary = thermal_stress_recommendation_summary(classification$level),
      source = "IPMA public-data forecast aggregate UTCI/temperatura sentida",
      stringsAsFactors = FALSE
    )
  })

  thermal <- bind_rows(rows)
  thermal[] <- lapply(thermal, as.character)
  thermal[, THERMAL_STRESS_COLUMNS]
}

write_thermal_stress <- function(new_data) {
  existing <- read_existing(THERMAL_STRESS_PATH, THERMAL_STRESS_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    THERMAL_STRESS_COLUMNS,
    THERMAL_STRESS_KEY_COLUMNS,
    setdiff(THERMAL_STRESS_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(source_updated_at, target_date, forecast_datetime_utc, period_hours) %>%
    distinct(across(all_of(THERMAL_STRESS_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, THERMAL_STRESS_PATH, na = "")

  latest_update <- latest_source_update(combined)
  latest <- combined[combined$source_updated_at == latest_update, , drop = FALSE]
  write_csv(latest, THERMAL_STRESS_LATEST_PATH, na = "")

  list(combined = combined, latest = latest)
}

classify_icaro <- function(value) {
  index_value <- to_num(value)
  if (is.na(index_value)) {
    return(list(
      label = "Sem dados",
      order = "-1"
    ))
  }

  if (index_value <= 0) {
    return(list(
      label = "Efeito nulo sobre a mortalidade",
      order = "0"
    ))
  }

  if (index_value < 1) {
    return(list(
      label = "Efeito não significativo sobre a mortalidade",
      order = "1"
    ))
  }

  if (index_value < 3) {
    return(list(
      label = "Provável efeito sobre a mortalidade",
      order = "2"
    ))
  }

  if (index_value <= 5) {
    return(list(
      label = "Possível alerta de onda de calor em avaliação",
      order = "3"
    ))
  }

  list(
    label = "Alerta de onda de calor - esperadas consequências graves",
    order = "4"
  )
}

classify_friesa <- function(value) {
  index_value <- to_num(value)
  if (is.na(index_value)) {
    return(list(
      label = "Sem dados",
      order = "-1"
    ))
  }

  if (index_value <= 0) {
    return(list(
      label = "Sem aumento relativo estimado",
      order = "0"
    ))
  }

  list(
    label = "Aumento relativo estimado associado ao frio",
    order = "1"
  )
}

sns_health_recommendation_summary <- function(index_name, risk_label) {
  if (index_name == "ÍCARO") {
    return(switch(
      risk_label,
      "Efeito nulo sobre a mortalidade" = "Sem excesso estimado; manter vigilância e medidas gerais de calor.",
      "Efeito não significativo sobre a mortalidade" = "ÍCARO positivo mas não significativo; reforçar vigilância se existirem outros sinais de calor.",
      "Provável efeito sobre a mortalidade" = "Provável impacto do calor; reforçar medidas de proteção e vigilância ativa dos grupos vulneráveis.",
      "Possível alerta de onda de calor em avaliação" = "Possível alerta de onda de calor; preparar/ativar medidas de contingência para calor.",
      "Alerta de onda de calor - esperadas consequências graves" = "Alerta de calor com consequências graves esperadas; ativar medidas de contingência e comunicação reforçada.",
      "Sem dados ÍCARO para recomendação automática."
    ))
  }

  switch(
    risk_label,
    "Sem aumento relativo estimado" = "Sem aumento relativo estimado por frio no distrito do Porto.",
    "Aumento relativo estimado associado ao frio" = "FRIESA positivo no distrito do Porto; reforçar medidas de frio, sobretudo para pessoas idosas e vulneráveis.",
    "Sem dados FRIESA para recomendação automática."
  )
}

flatten_icaro <- function(item) {
  fields <- item$fields
  target_date <- field_text(fields, "periodo")
  index_value <- field_text(fields, "ii")
  classification <- classify_icaro(index_value)

  data.frame(
    source_updated_at = field_text(item, "record_timestamp"),
    fetched_at = FETCHED_AT,
    location = LOCATION,
    district = DISTRICT,
    dico = DICO,
    index_name = "ÍCARO",
    index_scope = "Nacional",
    target_date = target_date,
    index_value = format_temp(to_num(index_value)),
    risk_label = classification$label,
    risk_level_order = classification$order,
    provisional_note = "Últimos 3 dias provisórios; disponibilizado em dias úteis entre maio e setembro.",
    season = "maio-setembro",
    recommendation_summary = sns_health_recommendation_summary(
      "ÍCARO",
      classification$label
    ),
    source = "SNS Transparência/INSA evolução diária do Índice ÍCARO",
    stringsAsFactors = FALSE
  )
}

friesa_row <- function(item, field, scope) {
  fields <- item$fields
  index_value <- field_text(fields, field)
  classification <- classify_friesa(index_value)

  data.frame(
    source_updated_at = field_text(item, "record_timestamp"),
    fetched_at = FETCHED_AT,
    location = LOCATION,
    district = DISTRICT,
    dico = DICO,
    index_name = "FRIESA",
    index_scope = scope,
    target_date = field_text(fields, "data"),
    index_value = format_temp(to_num(index_value)),
    risk_label = classification$label,
    risk_level_order = classification$order,
    provisional_note = paste(
      "Últimos 9 dias provisórios; disponibilizado em dias úteis entre novembro e março.",
      "A API pública não inclui os limiares operacionais dos níveis de alerta FRIESA."
    ),
    season = "novembro-março",
    recommendation_summary = sns_health_recommendation_summary(
      "FRIESA",
      classification$label
    ),
    source = "SNS Transparência/INSA Índice FRIESA",
    stringsAsFactors = FALSE
  )
}

flatten_friesa <- function(item) {
  bind_rows(
    friesa_row(item, "porto", "Porto - população geral"),
    friesa_row(item, "porto65", "Porto - 65+ anos")
  )
}

build_sns_health_indices <- function() {
  icaro <- bind_rows(lapply(fetch_json(SNS_ICARO_URL), flatten_icaro))
  friesa <- bind_rows(lapply(fetch_json(SNS_FRIESA_URL), flatten_friesa))
  indices <- bind_rows(icaro, friesa)

  if (nrow(indices) == 0) {
    return(empty_frame(SNS_HEALTH_INDEX_COLUMNS))
  }

  indices[] <- lapply(indices, as.character)
  indices %>%
    arrange(index_name, index_scope, target_date) %>%
    select(all_of(SNS_HEALTH_INDEX_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

latest_sns_health_rows <- function(combined) {
  if (nrow(combined) == 0) {
    return(combined)
  }

  combined %>%
    mutate(target_date_value = as.Date(target_date)) %>%
    group_by(index_name, index_scope) %>%
    filter(
      !is.na(target_date_value),
      target_date_value >= max(target_date_value, na.rm = TRUE) - 9
    ) %>%
    ungroup() %>%
    arrange(index_name, index_scope, target_date) %>%
    select(all_of(SNS_HEALTH_INDEX_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

write_sns_health_indices <- function(new_data) {
  existing <- read_existing(SNS_HEALTH_INDEX_PATH, SNS_HEALTH_INDEX_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    SNS_HEALTH_INDEX_COLUMNS,
    SNS_HEALTH_INDEX_KEY_COLUMNS,
    setdiff(SNS_HEALTH_INDEX_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(index_name, index_scope, target_date) %>%
    distinct(across(all_of(SNS_HEALTH_INDEX_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, SNS_HEALTH_INDEX_PATH, na = "")

  latest <- latest_sns_health_rows(combined)
  write_csv(latest, SNS_HEALTH_INDEX_LATEST_PATH, na = "")

  list(combined = combined, latest = latest)
}

parse_clima_extremo_datetime <- function(value) {
  value <- as_text(value)
  if (value == "") {
    return(as.POSIXct(NA))
  }

  value <- sub("\\.[0-9]+Z$", "Z", value)
  as.POSIXct(value, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

clima_extremo_target_date <- function(value) {
  timestamp <- parse_clima_extremo_datetime(value)
  if (is.na(timestamp)) {
    return(substr(as_text(value), 1, 10))
  }

  format(timestamp, "%Y-%m-%d", tz = LOCAL_TZ)
}

clima_extremo_field_metadata <- function(metadata, field_name) {
  for (field in metadata) {
    if (field_text(field, "name") == field_name) {
      return(field)
    }
  }

  NULL
}

clima_extremo_range_for_value <- function(metadata, field_name, value) {
  field <- clima_extremo_field_metadata(metadata, field_name)
  value_num <- to_num(value)
  if (is.null(field) || is.na(value_num) || is.null(field$ranges)) {
    return(NULL)
  }

  for (range in rev(field$ranges)) {
    min_value <- if (is.null(range$min)) -Inf else to_num(range$min)
    max_value <- if (is.null(range$max)) Inf else to_num(range$max)
    if (is.na(min_value)) {
      min_value <- -Inf
    }
    if (is.na(max_value)) {
      max_value <- Inf
    }
    if (min_value <= value_num && value_num <= max_value) {
      return(range)
    }
  }

  NULL
}

clima_extremo_range_bounds <- function(metadata, field_name) {
  field <- clima_extremo_field_metadata(metadata, field_name)
  if (is.null(field) || is.null(field$ranges) || length(field$ranges) == 0) {
    return(NULL)
  }

  min_values <- vapply(field$ranges, function(range) {
    value <- if (is.null(range$min)) -Inf else to_num(range$min)
    if (is.na(value)) {
      -Inf
    } else {
      value
    }
  }, numeric(1))

  max_values <- vapply(field$ranges, function(range) {
    value <- if (is.null(range$max)) Inf else to_num(range$max)
    if (is.na(value)) {
      Inf
    } else {
      value
    }
  }, numeric(1))

  list(
    min = min(min_values, na.rm = TRUE),
    max = max(max_values, na.rm = TRUE)
  )
}

clima_extremo_outside_declared_scale <- function(metadata, field_name, value) {
  bounds <- clima_extremo_range_bounds(metadata, field_name)
  value_num <- to_num(value)
  if (is.null(bounds) || is.na(value_num)) {
    return(FALSE)
  }

  value_num < bounds$min || value_num > bounds$max
}

clima_extremo_risk_order <- function(label, value) {
  label <- as_text(label)
  if (label %in% names(CLIMA_EXTREMO_RISK_LEVELS)) {
    return(as.character(CLIMA_EXTREMO_RISK_LEVELS[[label]]))
  }

  value_num <- to_num(value)
  if (is.na(value_num) || value_num < 0 || value_num > 4) {
    return(as.character(CLIMA_EXTREMO_RISK_LEVELS[["Sem dados"]]))
  }
  if (value_num < 1) {
    return(as.character(CLIMA_EXTREMO_RISK_LEVELS[["Baixo"]]))
  }
  if (value_num < 2) {
    return(as.character(CLIMA_EXTREMO_RISK_LEVELS[["Médio"]]))
  }
  if (value_num < 3) {
    return(as.character(CLIMA_EXTREMO_RISK_LEVELS[["Alto"]]))
  }

  as.character(CLIMA_EXTREMO_RISK_LEVELS[["Extremo"]])
}

clima_extremo_classification <- function(metadata, field_name, value) {
  if (field_name == "icaro" &&
      clima_extremo_outside_declared_scale(metadata, field_name, value)) {
    return(list(
      label = "Sem dados",
      order = as.character(CLIMA_EXTREMO_RISK_LEVELS[["Sem dados"]]),
      color = "",
      alert = "FALSE",
      invalid = TRUE
    ))
  }

  range <- clima_extremo_range_for_value(metadata, field_name, value)
  label <- if (is.null(range)) "" else as_text(range$label)
  color <- if (is.null(range)) "" else as_text(range$color)
  alert <- if (is.null(range)) "" else as_text(range$alert)

  if (field_name == "icaro" && label == "") {
    order <- to_num(clima_extremo_risk_order(label, value))
    label <- names(CLIMA_EXTREMO_RISK_LEVELS)[CLIMA_EXTREMO_RISK_LEVELS == order][1]
  }

  list(
    label = label,
    order = clima_extremo_risk_order(label, value),
    color = color,
    alert = alert,
    invalid = FALSE
  )
}

clima_extremo_temperature_label <- function(metadata, field_name, value) {
  range <- clima_extremo_range_for_value(metadata, field_name, value)
  if (is.null(range)) {
    return(list(label = "", alert = ""))
  }

  label <- as_text(range$label)
  if (label == "") {
    label <- "Sem alerta"
  }

  list(label = label, alert = as_text(range$alert))
}

clima_extremo_feature_for_region <- function(map_data, region) {
  for (collection in map_data) {
    features <- collection$features
    if (is.null(features) || length(features) == 0) {
      next
    }
    for (feature in features) {
      weather <- feature$weather
      properties <- feature$properties
      if (field_text(weather, "region") == region ||
          field_text(properties, "region") == region) {
        return(feature)
      }
    }
  }

  NULL
}

clima_extremo_thermal_context <- function(indoor_temperature, outdoor_temperature) {
  indoor <- to_num(indoor_temperature)
  outdoor <- to_num(outdoor_temperature)

  if ((!is.na(indoor) && indoor >= 28) || (!is.na(outdoor) && outdoor >= 29)) {
    return("calor")
  }
  if ((!is.na(indoor) && indoor < 18) || (!is.na(outdoor) && outdoor < 8)) {
    return("frio")
  }

  "sem extremo térmico direto"
}

clima_extremo_recommendation_summary <- function(
  risk_label,
  indoor_temperature,
  outdoor_temperature,
  vulnerability
) {
  context <- clima_extremo_thermal_context(indoor_temperature, outdoor_temperature)
  order <- to_num(clima_extremo_risk_order(risk_label, NA))
  vulnerability_text <- if (as_text(vulnerability) == "") {
    "vulnerabilidade sem dados"
  } else {
    paste0("vulnerabilidade ", as_text(vulnerability), "/24")
  }

  if (is.na(order) || order < 0) {
    return("Sem dados suficientes do Clima Extremo para recomendação automática.")
  }

  if (order == 0) {
    return(paste0(
      "Risco baixo em edifícios; manter vigilância habitual de conforto térmico, ",
      vulnerability_text,
      "."
    ))
  }

  if (order == 1) {
    return(paste0(
      "Risco médio em edifícios; reforçar vigilância de conforto térmico em casa e equipamentos, ",
      vulnerability_text,
      ", contexto: ",
      context,
      "."
    ))
  }

  if (order == 2) {
    return(paste0(
      "Risco alto em edifícios; preparar medidas de proteção para ocupantes vulneráveis, ",
      vulnerability_text,
      ", contexto: ",
      context,
      "."
    ))
  }

  paste0(
    "Risco extremo em edifícios; ativar medidas de contingência e acompanhamento ativo dos ocupantes vulneráveis, ",
    vulnerability_text,
    ", contexto: ",
    context,
    "."
  )
}

flatten_clima_extremo_date <- function(date_item, metadata) {
  date_id <- field_text(date_item, "_id")
  target_date <- clima_extremo_target_date(field_text(date_item, "date"))
  if (date_id == "" || target_date == "") {
    return(NULL)
  }

  map_data <- fetch_json(paste0(CLIMA_EXTREMO_MAP_URL, URLencode(date_id, reserved = TRUE)))
  feature <- clima_extremo_feature_for_region(map_data, CLIMA_EXTREMO_REGION)
  if (is.null(feature)) {
    return(NULL)
  }

  weather <- feature$weather
  risk_value <- field_text(weather, "icaro")
  risk_classification <- clima_extremo_classification(metadata, "icaro", risk_value)
  risk_outside_scale <- isTRUE(risk_classification$invalid)
  indoor_temperature <- field_text(weather, "tindoor")
  outdoor_temperature <- field_text(weather, "toutdoor")
  vulnerability <- field_text(weather, "vulnerability")
  indoor_classification <- clima_extremo_temperature_label(
    metadata,
    "tindoor",
    indoor_temperature
  )
  source_note <- paste(
    "A API Clima Extremo não devolve timestamp de atualização nem recomendações preenchidas;",
    "source_updated_at corresponde ao momento de recolha."
  )
  recommendation_summary <- clima_extremo_recommendation_summary(
    risk_classification$label,
    indoor_temperature,
    outdoor_temperature,
    vulnerability
  )

  if (risk_outside_scale) {
    source_note <- paste(
      source_note,
      paste0(
        "Valor bruto do índice de risco (",
        risk_value,
        ") fora da escala declarada pela API para icaro; não usado como alerta automático."
      )
    )
    recommendation_summary <- paste0(
      "Índice de risco Clima Extremo fora da escala declarada pela API (valor bruto ",
      risk_value,
      "); manter leitura contextual de temperatura interior/exterior e vulnerabilidade, sem acionar alerta automático."
    )
  }

  data.frame(
    source_updated_at = FETCHED_AT,
    fetched_at = FETCHED_AT,
    location = LOCATION,
    district = DISTRICT,
    dico = DICO,
    region = field_text(weather, "region"),
    target_date = target_date,
    date_id = date_id,
    risk_index = risk_value,
    risk_label = risk_classification$label,
    risk_level_order = risk_classification$order,
    risk_color = risk_classification$color,
    risk_alert = risk_classification$alert,
    indoor_temperature_c = indoor_temperature,
    indoor_temperature_label = indoor_classification$label,
    indoor_temperature_alert = indoor_classification$alert,
    outdoor_temperature_c = outdoor_temperature,
    vulnerability_index = vulnerability,
    source_note = source_note,
    recommendation_summary = recommendation_summary,
    source = "CLIMA EXTREMO API municipal risk forecast",
    stringsAsFactors = FALSE
  )
}

build_clima_extremo_risk <- function() {
  metadata <- fetch_json(CLIMA_EXTREMO_METADATA_URL)
  dates <- fetch_json(CLIMA_EXTREMO_DATES_URL)

  rows <- lapply(dates, function(date_item) {
    tryCatch(
      flatten_clima_extremo_date(date_item, metadata = metadata),
      error = function(error) {
        warning(
          "Clima Extremo: a previsão ",
          field_text(date_item, "_id"),
          " foi ignorada: ",
          conditionMessage(error),
          call. = FALSE
        )
        NULL
      }
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0) {
    return(empty_frame(CLIMA_EXTREMO_COLUMNS))
  }

  risk <- bind_rows(rows)
  risk[] <- lapply(risk, as.character)
  risk %>%
    arrange(source_updated_at, target_date) %>%
    select(all_of(CLIMA_EXTREMO_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

write_clima_extremo_risk <- function(new_data) {
  existing <- read_existing(CLIMA_EXTREMO_PATH, CLIMA_EXTREMO_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    CLIMA_EXTREMO_COLUMNS,
    CLIMA_EXTREMO_KEY_COLUMNS,
    setdiff(CLIMA_EXTREMO_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(source_updated_at, target_date) %>%
    distinct(across(all_of(CLIMA_EXTREMO_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, CLIMA_EXTREMO_PATH, na = "")

  latest_update <- latest_source_update(combined)
  latest <- combined[combined$source_updated_at == latest_update, , drop = FALSE]
  write_csv(latest, CLIMA_EXTREMO_LATEST_PATH, na = "")

  list(combined = combined, latest = latest)
}

weather_warning_level <- function(color) {
  color <- tolower(as_text(color))
  switch(
    color,
    "green" = list(label = "Verde", order = "0", color = "Verde"),
    "yellow" = list(label = "Amarelo", order = "1", color = "Amarelo"),
    "orange" = list(label = "Laranja", order = "2", color = "Laranja"),
    "red" = list(label = "Vermelho", order = "3", color = "Vermelho"),
    list(label = "Sem dados", order = "-1", color = color)
  )
}

fire_risk_level <- function(rcm) {
  code <- as_text(rcm)
  switch(
    code,
    "1" = list(label = "Risco reduzido", order = "0", color = "Verde"),
    "2" = list(label = "Risco moderado", order = "1", color = "Amarelo"),
    "3" = list(label = "Risco elevado", order = "2", color = "Laranja"),
    "4" = list(label = "Risco muito elevado", order = "3", color = "Vermelho"),
    "5" = list(label = "Risco máximo", order = "4", color = "Vermelho escuro"),
    list(label = "Sem dados", order = "-1", color = "")
  )
}

weather_warning_summary <- function(alert_type, level) {
  if (level == "Verde") {
    return("Sem aviso meteorológico ativo acima de Verde para este parâmetro.")
  }

  base <- switch(
    level,
    "Amarelo" = "Situação de risco para atividades expostas à meteorologia; acompanhar atualizações IPMA e adaptar atividades sensíveis.",
    "Laranja" = "Situação de risco moderado a elevado; reforçar comunicação, condicionar atividades exteriores e seguir orientações da ANEPC.",
    "Vermelho" = "Situação de risco extremo; evitar exposição desnecessária, ativar planos de contingência e seguir orientações da ANEPC.",
    "Confirmar manualmente o aviso antes de comunicar."
  )

  specific <- switch(
    alert_type,
    "Agitação Marítima" = "Evitar molhes, arribas, praias e atividades náuticas expostas; reforçar vigilância junto à frente marítima.",
    "Precipitação" = "Prevenir inundações urbanas, limpar escoamentos e evitar atravessar zonas inundadas.",
    "Trovoada" = "Evitar espaços abertos, árvores isoladas, estruturas metálicas e atividades aquáticas durante trovoada.",
    "Vento" = "Fixar objetos soltos, evitar zonas arborizadas, andaimes e estruturas temporárias.",
    "Nevoeiro" = "Reduzir deslocações não essenciais e reforçar prudência rodoviária.",
    "Neve" = "Condicionar deslocações e atividades em zonas afetadas por neve ou gelo.",
    "Tempo Quente" = "Aplicar medidas de calor: hidratação, sombra, redução de esforço e proteção de grupos vulneráveis.",
    "Tempo Frio" = "Aplicar medidas de frio: aquecimento seguro, roupa adequada e acompanhamento de pessoas vulneráveis.",
    ""
  )

  paste(base, specific)
}

fire_risk_summary <- function(level) {
  switch(
    level,
    "Risco reduzido" = "Manter vigilância e evitar comportamentos de ignição no espaço rural.",
    "Risco moderado" = "Evitar fogo e fontes de ignição no exterior; confirmar regras municipais antes de queimas ou trabalhos com faísca.",
    "Risco elevado" = "Reforçar prevenção: não realizar queimas, fogueiras ou trabalhos que produzam faíscas sem validação/autorização; manter acessos e pontos de água desobstruídos.",
    "Risco muito elevado" = "Redobrar cuidados e cumprir restrições legais; evitar atividades com fogo, faíscas ou máquinas em espaço rural e preparar resposta rápida a sinais de fumo.",
    "Risco máximo" = "Evitar qualquer atividade de risco no espaço rural; seguir restrições legais e orientações da Proteção Civil, autarquia e forças de segurança.",
    "Confirmar manualmente o risco de incêndio antes de comunicar."
  )
}

build_weather_warnings <- function() {
  api_data <- fetch_json(WEATHER_WARNINGS_URL)
  rows <- lapply(api_data, function(item) {
    if (field_text(item, "idAreaAviso") != WARNING_AREA_ID) {
      return(NULL)
    }

    level <- weather_warning_level(field_text(item, "awarenessLevelID"))
    alert_type <- field_text(item, "awarenessTypeName")
    description <- field_text(item, "text")
    start_time <- field_text(item, "startTime")
    end_time <- field_text(item, "endTime")

    data.frame(
      source_updated_at = "",
      fetched_at = FETCHED_AT,
      location = LOCATION,
      district = DISTRICT,
      dico = DICO,
      global_id_local = GLOBAL_ID_LOCAL,
      alert_source = "Avisos meteorológicos",
      alert_scope = paste0("Distrito do Porto (área de aviso ", WARNING_AREA_ID, ")"),
      target_date = substr(start_time, 1, 10),
      start_time = start_time,
      end_time = end_time,
      alert_type = alert_type,
      alert_level = level$label,
      alert_level_order = level$order,
      alert_color = level$color,
      description = description,
      recommendation_summary = weather_warning_summary(alert_type, level$label),
      source = "IPMA open-data forecast/warnings/warnings_www.json",
      stringsAsFactors = FALSE
    )
  })

  warnings <- bind_rows(rows)
  if (nrow(warnings) == 0) {
    return(empty_frame(IPMA_ALERT_COLUMNS))
  }

  update <- max(warnings$start_time[warnings$start_time != ""], na.rm = TRUE)
  warnings$source_updated_at <- update
  warnings[] <- lapply(warnings, as.character)
  warnings[, IPMA_ALERT_COLUMNS]
}

build_fire_risk_day <- function(url) {
  api_data <- fetch_json(url)
  local <- api_data$local[[DICO]]
  if (is.null(local)) {
    return(empty_frame(IPMA_ALERT_COLUMNS))
  }

  rcm <- field_text(local$data, "rcm")
  level <- fire_risk_level(rcm)
  target_date <- field_text(api_data, "dataPrev")
  source_update <- field_text(api_data, "fileDate")

  row <- data.frame(
    source_updated_at = source_update,
    fetched_at = FETCHED_AT,
    location = LOCATION,
    district = DISTRICT,
    dico = DICO,
    global_id_local = GLOBAL_ID_LOCAL,
    alert_source = "Risco de incêndio rural",
    alert_scope = "Concelho de Matosinhos",
    target_date = target_date,
    start_time = target_date,
    end_time = "",
    alert_type = "Risco de Incêndio Rural",
    alert_level = level$label,
    alert_level_order = level$order,
    alert_color = level$color,
    description = paste0("RCM ", rcm, " - ", level$label),
    recommendation_summary = fire_risk_summary(level$label),
    source = "IPMA open-data forecast/meteorology/rcm",
    stringsAsFactors = FALSE
  )

  row[] <- lapply(row, as.character)
  row[, IPMA_ALERT_COLUMNS]
}

build_fire_risk <- function() {
  bind_rows(lapply(FIRE_RISK_URLS, build_fire_risk_day)) %>%
    arrange(target_date) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

build_ipma_alerts <- function() {
  alerts <- bind_rows(build_weather_warnings(), build_fire_risk())
  if (nrow(alerts) == 0) {
    return(empty_frame(IPMA_ALERT_COLUMNS))
  }

  alerts[] <- lapply(alerts, as.character)
  alerts[, IPMA_ALERT_COLUMNS]
}

write_ipma_alerts <- function(new_data) {
  existing <- read_existing(IPMA_ALERTS_PATH, IPMA_ALERT_COLUMNS)
  combined <- upsert_rows(
    existing,
    new_data,
    IPMA_ALERT_COLUMNS,
    IPMA_ALERT_KEY_COLUMNS,
    setdiff(IPMA_ALERT_COLUMNS, "fetched_at")
  )

  combined <- combined %>%
    arrange(source_updated_at, alert_source, target_date, alert_type) %>%
    distinct(across(all_of(IPMA_ALERT_KEY_COLUMNS)), .keep_all = TRUE) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(combined, IPMA_ALERTS_PATH, na = "")

  latest_updates <- combined %>%
    group_by(alert_source) %>%
    filter(source_updated_at == max(source_updated_at, na.rm = TRUE)) %>%
    filter(fetched_at == max(fetched_at, na.rm = TRUE)) %>%
    ungroup() %>%
    arrange(alert_source, target_date, alert_type) %>%
    as.data.frame(stringsAsFactors = FALSE)

  write_csv(latest_updates, IPMA_ALERTS_LATEST_PATH, na = "")

  list(combined = combined, latest = latest_updates)
}

temperature_recommendations <- function(row) {
  overall <- as_text(row$overall_temperature_alert)
  tmax_alert <- as_text(row$tmax_alert)
  tmin_alert <- as_text(row$tmin_alert)

  if (overall == "Fora de época") {
    return(paste(
      "Comunicação geral: o indicador Temperatura DSP não é aplicado automaticamente fora do período de maio a outubro; manter apenas vigilância meteorológica habitual.",
      "Grupos vulneráveis: manter cuidados gerais adequados à temperatura prevista e validar manualmente qualquer situação excecional de calor fora de época.",
      "Estabelecimentos: sem ativação automática por este indicador fora da época DSP; manter planos de contingência disponíveis caso exista aviso meteorológico ou orientação das autoridades de saúde.",
      sep = "\n\n"
    ))
  }

  if (overall == "Sem dados") {
    return(paste(
      "Comunicação geral: não emitir mensagem automática de risco térmico sem validação manual; faltam dados para aplicar integralmente a regra DSP.",
      "Grupos vulneráveis: manter vigilância de rotina em pessoas idosas, crianças pequenas, grávidas, pessoas com doença crónica, pessoas isoladas e trabalhadores no exterior; confirmar a situação meteorológica antes de escalar medidas.",
      "Estabelecimentos: manter monitorização das previsões IPMA e preparar medidas de calor, mas sem ativação automática por este indicador enquanto os dados estiverem incompletos.",
      sep = "\n\n"
    ))
  }

  general <- switch(
    overall,
    "Verde" = "Comunicação geral: mensagem simples de vigilância. Manter hidratação regular, refeições leves nos dias mais quentes e atenção às atualizações meteorológicas.",
    "Amarelo" = "Comunicação geral: mensagem preventiva. Reforçar ingestão de água, procurar locais frescos e reduzir exposição solar direta e esforço físico no exterior, sobretudo entre as 11h e as 17h.",
    "Vermelho" = "Comunicação geral: mensagem de alerta. Evitar exposição direta ao sol e esforço físico no exterior nas horas de maior calor; procurar ambientes frescos ou climatizados e acompanhar sinais de desidratação, exaustão ou agravamento de doença crónica.",
    "Comunicação geral: confirmar manualmente o nível de alerta antes de comunicar."
  )

  vulnerable <- switch(
    overall,
    "Verde" = "Grupos vulneráveis: manter rotinas habituais, com hidratação frequente e atenção a sintomas em pessoas idosas, crianças, grávidas e pessoas com doenças cardiovasculares, respiratórias, renais, diabetes ou medicação sensível ao calor.",
    "Amarelo" = "Grupos vulneráveis: beber água mesmo sem sede, permanecer em ambientes frescos pelo menos 2 a 3 horas por dia, evitar saídas e esforço físico nas horas de maior calor e garantir contacto regular com pessoas isoladas.",
    "Vermelho" = "Grupos vulneráveis: permanecer em ambiente fresco ou climatizado sempre que possível, reforçar contacto ativo com pessoas isoladas, ajustar atividades ao início da manhã ou ao fim do dia e contactar SNS 24 (808 24 24 24) ou cuidados de saúde se houver agravamento de sintomas.",
    "Grupos vulneráveis: aguardar validação manual dos dados."
  )

  establishments <- switch(
    overall,
    "Verde" = "Estabelecimentos: manter atividades previstas, garantindo disponibilidade de água e locais de sombra/descanso.",
    "Amarelo" = "Estabelecimentos: adaptar atividades ao ar livre, privilegiar manhã cedo, reforçar pausas, água, sombra e vigilância de utentes ou trabalhadores vulneráveis.",
    "Vermelho" = "Estabelecimentos: suspender ou substituir atividades físicas intensas ao ar livre, reforçar arrefecimento dos espaços, organizar pausas frequentes, acompanhar sintomas e garantir contacto rápido com famílias/cuidadores quando aplicável.",
    "Estabelecimentos: aguardar validação manual dos dados."
  )

  specific <- character()
  if (tmax_alert %in% c("Amarelo", "Vermelho")) {
    specific <- c(
      specific,
      "Sinal de máxima: risco associado a calor diurno persistente; deslocar tarefas, passeios, terapias e exercício para horários mais frescos e evitar viaturas estacionadas ao sol."
    )
  }

  if (tmin_alert %in% c("Amarelo", "Vermelho")) {
    specific <- c(
      specific,
      "Sinal de mínima: risco associado a noites quentes e menor recuperação fisiológica; reforçar arrefecimento noturno seguro, roupa leve, hidratação e acompanhamento de pessoas que vivem sozinhas."
    )
  }

  if (length(specific) == 0) {
    specific <- "Sem medidas adicionais por sinal térmico para além da vigilância habitual."
  } else {
    specific <- paste(specific, collapse = " ")
  }

  paste(general, vulnerable, establishments, specific, sep = "\n\n")
}

temperature_values_text <- function(row) {
  paste0(
    "Máxima: observadas D-3/D-2/D-1 = ",
    paste(
      vapply(
        c(
        as_text(row$tmax_observed_d_minus_3_c),
        as_text(row$tmax_observed_d_minus_2_c),
        as_text(row$tmax_observed_d_minus_1_c)
        ),
        display_temp,
        character(1)
      ),
      collapse = "/"
    ),
    " ºC; previstas D/D+1 = ",
    paste(
      vapply(
        c(as_text(row$tmax_forecast_d0_c), as_text(row$tmax_forecast_d_plus_1_c)),
        display_temp,
        character(1)
      ),
      collapse = "/"
    ),
    " ºC. Mínima: observadas D-2/D-1 = ",
    paste(
      vapply(
        c(as_text(row$tmin_observed_d_minus_2_c), as_text(row$tmin_observed_d_minus_1_c)),
        display_temp,
        character(1)
      ),
      collapse = "/"
    ),
    " ºC; previstas D/D+1 = ",
    paste(
      vapply(
        c(as_text(row$tmin_forecast_d0_c), as_text(row$tmin_forecast_d_plus_1_c)),
        display_temp,
        character(1)
      ),
      collapse = "/"
    ),
    " ºC."
  )
}

build_temperature_daily_section <- function(row) {
  target_date <- as_text(row$target_date)
  missing <- as_text(row$missing_inputs)

  content <- c(
    "<!-- temperatura-dsp:start -->",
    paste0("### Temperatura DSP - ", target_date),
    "",
    paste0(
      "Fonte dos valores: IPMA. Atualização IPMA: ",
      as_text(row$source_updated_at),
      " UTC."
    ),
    "",
    paste0(
      "Nível global de temperatura: ",
      as_text(row$overall_temperature_alert),
      ". Alerta por máxima: ",
      as_text(row$tmax_alert),
      " (limiares ",
      threshold_pair_text(row$tmax_yellow_threshold_c, row$tmax_red_threshold_c),
      "). Alerta por mínima: ",
      as_text(row$tmin_alert),
      " (limiares ",
      threshold_pair_text(row$tmin_yellow_threshold_c, row$tmin_red_threshold_c),
      ")."
    ),
    "",
    temperature_values_text(row),
    ""
  )

  if (missing != "") {
    content <- c(
      content,
      paste0("Dados em falta para a regra automática: ", missing, "."),
      ""
    )
  }

  c(
    content,
    temperature_recommendations(row),
    "<!-- temperatura-dsp:end -->"
  )
}

uv_recommendations <- function(row) {
  level <- as_text(row$uv_level)

  if (level == "Sem dados") {
    return(paste(
      "Comunicação geral: não emitir recomendação automática de UV sem confirmar a previsão; manter referência às medidas gerais de proteção solar quando houver exposição.",
      "Grupos vulneráveis: crianças, pessoas idosas, pessoas com pele clara, antecedentes de cancro cutâneo, doença ocular ou medicação fotossensibilizante devem manter proteção reforçada se houver exposição ao sol.",
      "Estruturas: manter monitorização da previsão UV e garantir disponibilidade de sombra, água e protetor solar quando houver atividades exteriores.",
      sep = "\n\n"
    ))
  }

  general <- switch(
    level,
    "Baixo" = "Comunicação geral: risco UV baixo. A exposição ao ar livre pode decorrer normalmente; pessoas com pele/olhos sensíveis devem manter óculos de sol com filtro UV e proteção básica.",
    "Moderado" = "Comunicação geral: risco UV moderado. Usar óculos de sol com filtro UV, chapéu e protetor solar nas zonas expostas; preferir sombra nas horas centrais se a exposição for prolongada.",
    "Alto" = "Comunicação geral: risco UV alto. Procurar sombra entre o final da manhã e o meio da tarde, usar roupa que cubra a pele, chapéu de abas, óculos com filtro UV e protetor solar em pele exposta.",
    "Muito Alto" = "Comunicação geral: risco UV muito alto. Evitar exposição prolongada nas horas centrais; se for inevitável estar no exterior, combinar sombra, roupa, chapéu, óculos com filtro UV e protetor solar, reaplicando quando necessário.",
    "Extremo" = "Comunicação geral: risco UV extremo. Evitar exposição solar tanto quanto possível, sobretudo nas horas centrais; adiar atividades exteriores não essenciais e usar proteção máxima quando a exposição for inevitável.",
    "Comunicação geral: confirmar manualmente o nível UV antes de comunicar."
  )

  vulnerable <- switch(
    level,
    "Baixo" = "Grupos vulneráveis: manter proteção básica e evitar exposição desnecessária em bebés, pessoas com pele muito clara, antecedentes de cancro cutâneo ou doença ocular.",
    "Moderado" = "Grupos vulneráveis: crianças, grávidas, pessoas idosas, pessoas com pele clara ou medicação fotossensibilizante devem usar chapéu, roupa protetora, óculos UV e protetor solar; bebés devem ficar fora da exposição direta.",
    "Alto" = "Grupos vulneráveis: evitar sol direto nas horas centrais, privilegiar sombra e espaços interiores frescos; reforçar proteção ocular e cutânea e vigiar sinais de queimadura solar.",
    "Muito Alto" = "Grupos vulneráveis: evitar atividades ao sol nas horas centrais; crianças e pessoas muito sensíveis devem permanecer à sombra ou no interior, com proteção completa se tiverem de sair.",
    "Extremo" = "Grupos vulneráveis: não programar exposição solar direta; manter crianças e pessoas de maior risco no interior ou em sombra densa e garantir proteção total em deslocações inevitáveis.",
    "Grupos vulneráveis: aguardar validação manual dos dados."
  )

  structures <- switch(
    level,
    "Baixo" = "Estruturas: manter atividades exteriores previstas, com acesso a água e sombra disponível.",
    "Moderado" = "Estruturas: planear pausas à sombra, disponibilizar protetor solar e incentivar chapéu/óculos em atividades exteriores prolongadas.",
    "Alto" = "Estruturas: ajustar horários de atividades exteriores, privilegiar manhã cedo ou fim do dia, garantir sombra efetiva e controlar proteção de crianças, utentes e trabalhadores.",
    "Muito Alto" = "Estruturas: reduzir ou relocalizar atividades exteriores para espaços sombreados/interiores; reforçar comunicação, pausas, supervisão e disponibilidade de protetor solar.",
    "Extremo" = "Estruturas: suspender ou adiar atividades exteriores não essenciais nas horas centrais; ativar alternativas interiores/sombreadas e supervisionar deslocações inevitáveis.",
    "Estruturas: aguardar validação manual dos dados."
  )

  paste(general, vulnerable, structures, sep = "\n\n")
}

has_uv_index_value <- function(row) {
  as_text(row$uv_index) != ""
}

uv_rows_for_report <- function(uv_index, report_date) {
  uv_dates <- as.Date(uv_index$target_date)
  report_date_value <- as.Date(report_date)
  future_rows <- uv_index[
    !is.na(uv_dates) & uv_dates >= report_date_value,
    ,
    drop = FALSE
  ]

  if (nrow(future_rows) == 0) {
    future_rows <- uv_index
  }

  rows_with_values <- future_rows[
    vapply(seq_len(nrow(future_rows)), function(i) {
      has_uv_index_value(future_rows[i, , drop = FALSE])
    }, logical(1)),
    ,
    drop = FALSE
  ]

  if (nrow(rows_with_values) > 0) {
    return(rows_with_values %>%
      arrange(target_date) %>%
      as.data.frame(stringsAsFactors = FALSE))
  }

  future_rows %>%
    arrange(target_date) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

uv_table_lines <- function(rows) {
  if (nrow(rows) == 0) {
    return("Sem previsões UV preenchidas no último snapshot IPMA.")
  }

  c(
    "| Data | Índice UV | Nível | Proteção |",
    "|---|---:|---|---|",
    vapply(seq_len(nrow(rows)), function(i) {
      row <- rows[i, , drop = FALSE]
      paste0(
        "| ",
        as_text(row$target_date),
        " | ",
        display_temp(row$uv_index),
        " | ",
        as_text(row$uv_level),
        " | ",
        as_text(row$protection_required),
        " |"
      )
    }, character(1))
  )
}

highest_uv_row <- function(rows) {
  rows_with_values <- rows[
    vapply(seq_len(nrow(rows)), function(i) {
      has_uv_index_value(rows[i, , drop = FALSE])
    }, logical(1)),
    ,
    drop = FALSE
  ]

  if (nrow(rows_with_values) == 0) {
    return(rows[1, , drop = FALSE])
  }

  rows_with_values %>%
    mutate(
      uv_level_order_num = to_num(uv_level_order),
      uv_index_num = to_num(uv_index)
    ) %>%
    arrange(desc(uv_level_order_num), desc(uv_index_num), target_date) %>%
    slice(1) %>%
    select(all_of(UV_INDEX_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

build_uv_daily_section <- function(rows, report_date) {
  source_update <- latest_source_update(rows)
  if (source_update == "") {
    source_update <- as_text(rows$source_updated_at)
  }

  rows_with_values <- rows[
    vapply(seq_len(nrow(rows)), function(i) {
      has_uv_index_value(rows[i, , drop = FALSE])
    }, logical(1)),
    ,
    drop = FALSE
  ]
  recommendation_row <- highest_uv_row(rows)

  if (nrow(rows_with_values) > 0) {
    first_date <- min(as.Date(rows_with_values$target_date), na.rm = TRUE)
    last_date <- max(as.Date(rows_with_values$target_date), na.rm = TRUE)
    date_scope <- if (first_date == last_date) {
      as.character(first_date)
    } else {
      paste0(as.character(first_date), " a ", as.character(last_date))
    }
  } else {
    date_scope <- report_date
  }

  c(
    "<!-- uv:start -->",
    paste0("### Índice UV - previsões disponíveis em ", report_date),
    "",
    paste0(
      "Fonte dos valores: IPMA. Atualização IPMA: ",
      source_update,
      " UTC. Período com valor previsto: ",
      date_scope,
      "."
    ),
    "",
    uv_table_lines(rows_with_values),
    "",
    paste0(
      "Nível máximo no período: ",
      as_text(recommendation_row$uv_level),
      " em ",
      as_text(recommendation_row$target_date),
      " (Índice UV ",
      display_temp(recommendation_row$uv_index),
      "). As recomendações abaixo seguem este nível mais exigente."
    ),
    "",
    uv_recommendations(recommendation_row),
    "<!-- uv:end -->"
  )
}

bool_label <- function(value) {
  value <- as_text(value)
  if (value == "TRUE") {
    return("sim")
  }
  if (value == "FALSE") {
    return("não")
  }

  "sem dados"
}

tmax_source_label <- function(value) {
  value <- as_text(value)
  if (value == "observed") {
    return("observada")
  }
  if (value == "forecast") {
    return("prevista")
  }

  "sem dados"
}

heat_wave_rows_for_report <- function(heat_waves, report_date) {
  heat_dates <- as.Date(heat_waves$target_date)
  report_date_value <- as.Date(report_date)
  selected <- heat_waves[
    !is.na(heat_dates) & heat_dates >= report_date_value,
    ,
    drop = FALSE
  ]

  if (nrow(selected) == 0) {
    selected <- heat_waves
  }

  selected %>%
    mutate(heat_wave_level_num = to_num(heat_wave_level)) %>%
    arrange(target_date, desc(heat_wave_level_num)) %>%
    select(all_of(HEAT_WAVE_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

heat_wave_window_text <- function(row) {
  heat_start <- as_text(row$heat_wave_window_start)
  heat_end <- as_text(row$heat_wave_window_end)
  pre_start <- as_text(row$pre_heat_wave_window_start)
  pre_end <- as_text(row$pre_heat_wave_window_end)

  if (heat_start != "" && heat_end != "") {
    return(paste0("6 dias: ", heat_start, " a ", heat_end))
  }

  if (pre_start != "" && pre_end != "") {
    return(paste0("5 dias: ", pre_start, " a ", pre_end))
  }

  paste0(as_text(row$consecutive_exceedance_days), " dia(s)")
}

heat_wave_table_lines <- function(rows) {
  if (nrow(rows) == 0) {
    return("Sem dados de onda de calor no último snapshot.")
  }

  c(
    "| Data | Tmax | Limiar | Excede | Sequência | Estado |",
    "|---|---:|---:|---|---|---|",
    vapply(seq_len(nrow(rows)), function(i) {
      row <- rows[i, , drop = FALSE]
      paste0(
        "| ",
        as_text(row$target_date),
        " | ",
        display_temp(row$tmax_c),
        " ºC (",
        tmax_source_label(row$tmax_source),
        ") | ",
        display_temp(row$threshold_c),
        " ºC | ",
        bool_label(row$exceeds_threshold),
        " | ",
        heat_wave_window_text(row),
        " | ",
        as_text(row$heat_wave_status),
        " |"
      )
    }, character(1))
  )
}

highest_heat_wave_row <- function(rows) {
  rows %>%
    mutate(heat_wave_level_num = to_num(heat_wave_level)) %>%
    arrange(desc(heat_wave_level_num), target_date) %>%
    slice(1) %>%
    select(all_of(HEAT_WAVE_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

heat_wave_recommendations <- function(row) {
  status <- as_text(row$heat_wave_status)

  if (status == "Sem dados") {
    return(paste(
      "Comunicação geral: não emitir mensagem automática de onda de calor sem validação manual; faltam dados para aplicar o critério climatológico.",
      "Grupos vulneráveis: manter vigilância de rotina em pessoas idosas, crianças, grávidas, pessoas com doença crónica, pessoas isoladas e trabalhadores no exterior; confirmar a previsão IPMA antes de escalar medidas.",
      "Estabelecimentos: manter planos de calor disponíveis, mas sem ativação automática por este indicador enquanto os dados estiverem incompletos.",
      sep = "\n\n"
    ))
  }

  if (status == "Sem critério") {
    return(paste(
      "Comunicação geral: sem critério de onda de calor no horizonte disponível. Manter vigilância, hidratação regular e consulta das atualizações IPMA, sobretudo se existirem outros alertas de temperatura.",
      "Grupos vulneráveis: manter cuidados proporcionais à temperatura prevista e atenção a sintomas em pessoas idosas, crianças, grávidas, pessoas com doença crónica ou que vivam isoladas.",
      "Estabelecimentos: manter acesso a água, sombra e espaços frescos; rever horários de atividades exteriores se a previsão de temperatura subir.",
      sep = "\n\n"
    ))
  }

  if (status == "Sinal preventivo de 5 dias") {
    return(paste(
      "Comunicação geral: sinal preventivo de calor persistente. Comunicar de forma prudente que há vários dias previstos acima do limiar, reforçando hidratação, procura de locais frescos e redução de esforço físico nas horas de maior calor.",
      "Grupos vulneráveis: antecipar contacto com pessoas idosas ou isoladas, garantir água disponível, rever medicação sensível ao calor com profissional de saúde quando aplicável e evitar saídas prolongadas entre as 11h e as 17h.",
      "Estabelecimentos: preparar planos de contingência, confirmar zonas de sombra/arrefecimento, ajustar passeios, terapias e atividade física para manhã cedo ou espaços interiores, e acompanhar novas previsões.",
      sep = "\n\n"
    ))
  }

  general <- if (status == "Possível Onda de Calor") {
    "Comunicação geral: possível onda de calor com base em valores observados e previstos. Reforçar mensagem de prevenção: beber água mesmo sem sede, procurar ambientes frescos ou climatizados, evitar sol direto e esforço físico no exterior nas horas de maior calor, e acompanhar atualizações IPMA."
  } else {
    "Comunicação geral: onda de calor em curso/confirmada pelo critério climatológico. Ativar comunicação de alerta: hidratação frequente, refeições leves, permanência em locais frescos, evitar exposição direta ao sol e esforço físico nas horas de maior calor, e procurar ajuda em caso de sintomas."
  }

  vulnerable <- paste(
    "Grupos vulneráveis: crianças, pessoas idosas, grávidas, pessoas com doença cardiovascular, respiratória, renal, diabetes, problemas de saúde mental, pessoas acamadas ou isoladas e trabalhadores no exterior devem ser acompanhados de forma ativa.",
    "Garantir água, ambiente fresco pelo menos 2 a 3 horas por dia, roupa leve, vigilância de sinais de desidratação/exaustão e contacto com SNS 24 (808 24 24 24) ou 112 em sinais graves."
  )

  establishments <- paste(
    "Estabelecimentos: condicionar ou substituir atividades físicas intensas ao ar livre, deslocar atividades inevitáveis para manhã cedo ou fim do dia, assegurar sombra, água, pausas e arrefecimento dos espaços.",
    "Reforçar chamadas/contactos com cuidadores quando aplicável e ter procedimento claro para sintomas de exaustão pelo calor ou agravamento de doença crónica."
  )

  paste(general, vulnerable, establishments, sep = "\n\n")
}

build_heat_wave_daily_section <- function(rows, report_date) {
  source_update <- latest_source_update(rows)
  if (source_update == "") {
    source_update <- as_text(rows$source_updated_at)
  }

  recommendation_row <- highest_heat_wave_row(rows)

  c(
    "<!-- onda-calor:start -->",
    paste0("### Onda de Calor - previsões disponíveis em ", report_date),
    "",
    paste0(
      "Critério IPMA: pelo menos 6 dias consecutivos com temperatura máxima diária superior em 5 ºC à normal mensal. ",
      "Normal usada: ",
      HEAT_WAVE_NORMAL_STATION,
      " (",
      HEAT_WAVE_NORMAL_PERIOD,
      "). Atualização IPMA: ",
      source_update,
      " UTC."
    ),
    "",
    heat_wave_table_lines(rows),
    "",
    paste0(
      "Estado mais exigente no período: ",
      as_text(recommendation_row$heat_wave_status),
      " em ",
      as_text(recommendation_row$target_date),
      ". As recomendações abaixo seguem este estado."
    ),
    "",
    heat_wave_recommendations(recommendation_row),
    "<!-- onda-calor:end -->"
  )
}

thermal_stress_rows_for_report <- function(thermal_stress, report_date) {
  thermal_dates <- as.Date(thermal_stress$target_date)
  report_date_value <- as.Date(report_date)
  selected <- thermal_stress[
    !is.na(thermal_dates) & thermal_dates >= report_date_value,
    ,
    drop = FALSE
  ]

  if (nrow(selected) == 0) {
    selected <- thermal_stress
  }

  selected %>%
    mutate(thermal_level_order_num = to_num(thermal_level_order)) %>%
    arrange(target_date, forecast_datetime_utc, desc(thermal_level_order_num)) %>%
    select(all_of(THERMAL_STRESS_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

thermal_daily_peak_rows <- function(rows) {
  if (nrow(rows) == 0) {
    return(rows)
  }

  rows %>%
    mutate(
      thermal_level_order_num = to_num(thermal_level_order),
      utci_num = to_num(utci_c)
    ) %>%
    group_by(target_date) %>%
    arrange(desc(thermal_level_order_num), desc(abs(utci_num - 17)), forecast_datetime_utc) %>%
    slice(1) %>%
    ungroup() %>%
    arrange(target_date) %>%
    select(all_of(THERMAL_STRESS_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

thermal_stress_table_lines <- function(rows) {
  peak_rows <- thermal_daily_peak_rows(rows)
  if (nrow(peak_rows) == 0) {
    return("Sem previsões UTCI preenchidas no último snapshot IPMA.")
  }

  c(
    "| Data | Hora local | UTCI | Nível | Proteção |",
    "|---|---|---:|---|---|",
    vapply(seq_len(nrow(peak_rows)), function(i) {
      row <- peak_rows[i, , drop = FALSE]
      paste0(
        "| ",
        as_text(row$target_date),
        " | ",
        as_text(row$forecast_datetime_local),
        " | ",
        display_temp(row$utci_c),
        " ºC | ",
        as_text(row$thermal_level),
        " | ",
        as_text(row$protection_required),
        " |"
      )
    }, character(1))
  )
}

highest_thermal_stress_row <- function(rows) {
  peak_rows <- thermal_daily_peak_rows(rows)
  if (nrow(peak_rows) == 0) {
    return(empty_frame(THERMAL_STRESS_COLUMNS))
  }

  peak_rows %>%
    mutate(
      thermal_level_order_num = to_num(thermal_level_order),
      utci_num = to_num(utci_c)
    ) %>%
    arrange(desc(thermal_level_order_num), desc(abs(utci_num - 17)), target_date) %>%
    slice(1) %>%
    select(all_of(THERMAL_STRESS_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

thermal_stress_recommendations <- function(row) {
  level <- as_text(row$thermal_level)
  stress_type <- as_text(row$thermal_stress_type)

  if (level == "Sem dados" || nrow(row) == 0) {
    return(paste(
      "Comunicação geral: não emitir recomendação automática de stress térmico sem confirmar a previsão UTCI.",
      "Grupos vulneráveis: manter vigilância de rotina e confirmar as condições meteorológicas antes de adaptar atividades.",
      "Estabelecimentos: manter monitorização do UTCI/temperatura sentida e preparar medidas de calor ou frio conforme a previsão.",
      sep = "\n\n"
    ))
  }

  if (stress_type == "Sem stress térmico") {
    return(paste(
      "Comunicação geral: sem stress térmico relevante no pico previsto. Manter hidratação, roupa adequada à estação e vigilância habitual.",
      "Grupos vulneráveis: manter cuidados habituais, com atenção a sintomas respiratórios, cardiovasculares ou sinais de desconforto térmico.",
      "Estabelecimentos: manter atividades previstas, garantindo água, sombra quando houver sol e possibilidade de abrigo em caso de mudança meteorológica.",
      sep = "\n\n"
    ))
  }

  if (stress_type == "Calor") {
    high_heat <- level %in% c(
      "Stress por calor elevado",
      "Stress por calor muito elevado",
      "Stress por calor extremo"
    )
    extreme_heat <- level %in% c(
      "Stress por calor muito elevado",
      "Stress por calor extremo"
    )

    general <- if (extreme_heat) {
      "Comunicação geral: stress térmico por calor muito elevado/extremo. Evitar exposição exterior não essencial nas horas de pico, beber água mesmo sem sede, procurar locais frescos ou climatizados e estar atento a sinais de exaustão pelo calor."
    } else if (high_heat) {
      "Comunicação geral: stress térmico por calor elevado. Reduzir exposição solar direta e esforço físico no exterior nas horas de pico; reforçar hidratação, sombra, roupa leve e pausas."
    } else {
      "Comunicação geral: stress térmico por calor moderado. Reforçar hidratação, procurar sombra nas atividades prolongadas e adaptar esforço físico ao ar livre."
    }

    vulnerable <- "Grupos vulneráveis: crianças, pessoas idosas, grávidas, pessoas com doença cardiovascular, respiratória, renal, diabetes, problemas de saúde mental, pessoas acamadas ou isoladas e trabalhadores no exterior devem ter vigilância reforçada, água disponível e acesso a local fresco."
    establishments <- if (extreme_heat) {
      "Estabelecimentos: suspender ou substituir atividades físicas intensas ao ar livre nas horas de pico, reforçar arrefecimento dos espaços, pausas, água e contacto rápido com cuidadores/famílias se surgirem sintomas."
    } else {
      "Estabelecimentos: ajustar horários de atividades exteriores para manhã cedo ou fim do dia, garantir sombra, água, pausas frequentes e observação ativa de utentes/trabalhadores vulneráveis."
    }

    return(paste(general, vulnerable, establishments, sep = "\n\n"))
  }

  high_cold <- level %in% c(
    "Stress por frio elevado",
    "Stress por frio muito elevado",
    "Stress por frio extremo"
  )
  extreme_cold <- level %in% c(
    "Stress por frio muito elevado",
    "Stress por frio extremo"
  )

  general <- if (extreme_cold) {
    "Comunicação geral: stress térmico por frio muito elevado/extremo. Evitar exposição exterior não essencial, usar várias camadas de roupa, proteger cabeça e extremidades e manter hidratação com bebidas quentes sem álcool."
  } else if (high_cold) {
    "Comunicação geral: stress térmico por frio elevado. Limitar exposição prolongada, proteger extremidades, evitar mudanças bruscas de temperatura e aquecer a habitação com segurança."
  } else {
    "Comunicação geral: stress térmico por frio ligeiro/moderado. Usar roupa adequada, proteger extremidades em atividades exteriores e manter atenção a desconforto ou agravamento de sintomas."
  }

  vulnerable <- "Grupos vulneráveis: bebés, pessoas idosas, pessoas com doença cardiovascular, respiratória, diabetes, mobilidade reduzida, isolamento social ou trabalho exterior devem ser acompanhadas de perto; garantir medicação acessível, casa aquecida com ventilação segura e contacto regular."
  establishments <- if (extreme_cold) {
    "Estabelecimentos: condicionar atividades exteriores, reforçar aquecimento seguro, confirmar transporte/abrigo e acompanhar sinais de hipotermia, enregelamento ou agravamento respiratório/cardiovascular."
  } else {
    "Estabelecimentos: adaptar horários e duração de atividades exteriores, garantir abrigo aquecido, roupa adequada, bebidas quentes e vigilância de utentes/trabalhadores vulneráveis."
  }

  paste(general, vulnerable, establishments, sep = "\n\n")
}

build_thermal_stress_daily_section <- function(rows, report_date) {
  source_update <- latest_source_update(rows)
  if (source_update == "") {
    source_update <- as_text(rows$source_updated_at)
  }

  recommendation_row <- highest_thermal_stress_row(rows)

  c(
    "<!-- utci:start -->",
    paste0("### Stress térmico UTCI - previsões disponíveis em ", report_date),
    "",
    paste0(
      "Fonte dos valores: IPMA. Atualização IPMA: ",
      source_update,
      " UTC. O UTCI traduz a temperatura sentida em classes de stress térmico por calor ou frio."
    ),
    "",
    thermal_stress_table_lines(rows),
    "",
    paste0(
      "Nível mais exigente no período: ",
      as_text(recommendation_row$thermal_level),
      " em ",
      as_text(recommendation_row$forecast_datetime_local),
      " (UTCI ",
      display_temp(recommendation_row$utci_c),
      " ºC). As recomendações abaixo seguem este nível."
    ),
    "",
    thermal_stress_recommendations(recommendation_row),
    "<!-- utci:end -->"
  )
}

sns_health_rows_for_report <- function(indices, report_date) {
  report_date_value <- as.Date(report_date)
  index_dates <- as.Date(indices$target_date)
  month_value <- as.integer(format(report_date_value, "%m"))

  icaro_rows <- empty_frame(SNS_HEALTH_INDEX_COLUMNS)
  if (month_value %in% 5:9) {
    icaro_rows <- indices[
      indices$index_name == "ÍCARO" &
        !is.na(index_dates) &
        index_dates >= report_date_value,
      ,
      drop = FALSE
    ]
  }

  if (nrow(icaro_rows) == 0 && month_value %in% 5:9) {
    icaro_rows <- indices[indices$index_name == "ÍCARO", , drop = FALSE] %>%
      mutate(target_date_value = as.Date(target_date)) %>%
      arrange(desc(target_date_value)) %>%
      slice(1) %>%
      select(all_of(SNS_HEALTH_INDEX_COLUMNS)) %>%
      as.data.frame(stringsAsFactors = FALSE)
  }

  friesa_rows <- empty_frame(SNS_HEALTH_INDEX_COLUMNS)
  if (month_value %in% c(1, 2, 3, 11, 12)) {
    friesa_rows <- indices[
      indices$index_name == "FRIESA" &
        !is.na(index_dates) &
        index_dates >= report_date_value,
      ,
      drop = FALSE
    ]
  }

  if (nrow(friesa_rows) == 0 && month_value %in% c(1, 2, 3, 11, 12)) {
    friesa_rows <- indices[indices$index_name == "FRIESA", , drop = FALSE] %>%
      mutate(target_date_value = as.Date(target_date)) %>%
      group_by(index_scope) %>%
      arrange(desc(target_date_value)) %>%
      slice(1) %>%
      ungroup() %>%
      select(all_of(SNS_HEALTH_INDEX_COLUMNS)) %>%
      as.data.frame(stringsAsFactors = FALSE)
  }

  bind_rows(icaro_rows, friesa_rows) %>%
    mutate(
      risk_level_order_num = to_num(risk_level_order),
      target_date_value = as.Date(target_date)
    ) %>%
    arrange(index_name, index_scope, target_date_value) %>%
    select(all_of(SNS_HEALTH_INDEX_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

sns_health_table_lines <- function(rows, report_date) {
  month_value <- as.integer(format(as.Date(report_date), "%m"))
  notes <- character()
  if (!month_value %in% 5:9) {
    notes <- c(
      notes,
      "ÍCARO: fora da época habitual de disponibilização pública (maio a setembro)."
    )
  }
  if (!month_value %in% c(1, 2, 3, 11, 12)) {
    notes <- c(
      notes,
      "FRIESA: fora da época habitual de disponibilização pública (novembro a março)."
    )
  }

  if (nrow(rows) == 0) {
    return(c("Sem dados ÍCARO/FRIESA aplicáveis ao período do boletim.", "", notes))
  }

  table <- c(
    "| Índice | Âmbito | Data | Valor | Interpretação |",
    "|---|---|---|---:|---|",
    vapply(seq_len(nrow(rows)), function(i) {
      row <- rows[i, , drop = FALSE]
      paste0(
        "| ",
        as_text(row$index_name),
        " | ",
        as_text(row$index_scope),
        " | ",
        as_text(row$target_date),
        " | ",
        display_temp(row$index_value),
        " | ",
        as_text(row$risk_label),
        " |"
      )
    }, character(1))
  )

  if (length(notes) > 0) {
    table <- c(table, "", notes)
  }

  table
}

highest_sns_health_row <- function(rows) {
  if (nrow(rows) == 0) {
    return(empty_frame(SNS_HEALTH_INDEX_COLUMNS))
  }

  rows %>%
    mutate(
      risk_level_order_num = to_num(risk_level_order),
      target_date_value = as.Date(target_date)
    ) %>%
    arrange(desc(risk_level_order_num), target_date_value, index_name, index_scope) %>%
    slice(1) %>%
    select(all_of(SNS_HEALTH_INDEX_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

sns_health_recommendations <- function(rows) {
  if (nrow(rows) == 0) {
    return(paste(
      "Comunicação geral: não emitir recomendação automática com base em ÍCARO/FRIESA sem validação manual; faltam dados no último snapshot.",
      "Grupos vulneráveis: manter vigilância de rotina e usar os restantes indicadores meteorológicos e ambientais.",
      "Estabelecimentos: manter planos de contingência de calor/frio disponíveis e aguardar atualização dos índices SNS/INSA.",
      sep = "\n\n"
    ))
  }

  highest <- highest_sns_health_row(rows)
  index_name <- as_text(highest$index_name)
  order <- to_num(highest$risk_level_order)

  if (index_name == "ÍCARO") {
    if (is.na(order) || order <= 0) {
      return(paste(
        "Comunicação geral: ÍCARO sem efeito estimado sobre a mortalidade no período disponível; manter comunicação prudente e articular com os restantes indicadores de calor, ozono e UV.",
        "Grupos vulneráveis: manter cuidados gerais de calor, hidratação e vigilância de sintomas quando houver exposição solar ou esforço ao ar livre.",
        "Estabelecimentos: manter atividades previstas, com água, sombra e possibilidade de adaptação se os indicadores meteorológicos agravarem.",
        sep = "\n\n"
      ))
    }

    if (order < 2) {
      return(paste(
        "Comunicação geral: ÍCARO positivo mas sem efeito significativo estimado. Comunicar vigilância reforçada se coincidirem calor, UV elevado, ozono ou noites quentes.",
        "Grupos vulneráveis: reforçar hidratação, evitar esforço nas horas mais quentes e manter contacto com pessoas idosas, isoladas ou com doença crónica.",
        "Estabelecimentos: preparar adaptação de horários e espaços frescos, sem ativação plena de contingência apenas por este índice.",
        sep = "\n\n"
      ))
    }

    return(paste(
      "Comunicação geral: ÍCARO indica possível/provável impacto do calor na mortalidade. Reforçar comunicação de alerta, hidratação, procura de locais frescos, redução de esforço físico e vigilância de sinais de exaustão/golpe de calor.",
      "Grupos vulneráveis: contacto ativo com pessoas idosas, isoladas, crianças, grávidas, pessoas com doença crónica, acamadas ou medicadas com fármacos sensíveis ao calor; contactar SNS 24 ou 112 perante sinais graves.",
      "Estabelecimentos: ativar medidas de contingência para calor, ajustar atividades exteriores, garantir água, sombra/arrefecimento, pausas e acompanhamento de utentes/trabalhadores vulneráveis.",
      sep = "\n\n"
    ))
  }

  if (is.na(order) || order <= 0) {
    return(paste(
      "Comunicação geral: FRIESA sem aumento relativo estimado por frio no distrito do Porto; manter vigilância sazonal quando aplicável.",
      "Grupos vulneráveis: manter cuidados gerais de frio e atenção a sintomas respiratórios/cardiovasculares em dias frios.",
      "Estabelecimentos: manter planos de abrigo/aquecimento disponíveis durante a época fria.",
      sep = "\n\n"
    ))
  }

  paste(
    "Comunicação geral: FRIESA positivo para o distrito do Porto. Reforçar comunicação sobre frio, evitar exposição prolongada, usar várias camadas de roupa, proteger extremidades e aquecer espaços com segurança.",
    "Grupos vulneráveis: contacto ativo com pessoas idosas, bebés, pessoas com doença cardiovascular/respiratória, mobilidade reduzida, isolamento social ou trabalho exterior; garantir medicação, aquecimento seguro e vigilância de hipotermia/enregelamento.",
    "Estabelecimentos: adaptar atividades exteriores, garantir abrigo aquecido, transporte seguro, bebidas quentes sem álcool e procedimentos para agravamento respiratório/cardiovascular.",
    sep = "\n\n"
  )
}

build_sns_health_daily_section <- function(rows, report_date) {
  source_updates <- unique(rows$source_updated_at[rows$source_updated_at != ""])
  source_update_text <- if (length(source_updates) == 0) {
    FETCHED_AT
  } else {
    paste(sort(source_updates), collapse = "; ")
  }

  c(
    "<!-- sns-health:start -->",
    paste0("### Índices SNS/INSA ÍCARO e FRIESA - ", report_date),
    "",
    paste0(
      "Fonte dos valores: SNS Transparência/INSA. Atualizações de origem consideradas: ",
      source_update_text,
      ". ÍCARO estima excesso relativo de risco por calor; FRIESA estima risco associado a frio extremo nos distritos de Lisboa e Porto."
    ),
    "",
    sns_health_table_lines(rows, report_date),
    "",
    sns_health_recommendations(rows),
    "<!-- sns-health:end -->"
  )
}

clima_extremo_rows_for_report <- function(rows, report_date) {
  report_date_value <- as.Date(report_date)
  risk_dates <- as.Date(rows$target_date)
  selected <- rows[
    !is.na(risk_dates) & risk_dates >= report_date_value,
    ,
    drop = FALSE
  ]

  if (nrow(selected) == 0) {
    selected <- rows
  }

  selected %>%
    mutate(
      risk_level_order_num = to_num(risk_level_order),
      target_date_value = as.Date(target_date)
    ) %>%
    arrange(target_date_value, desc(risk_level_order_num)) %>%
    select(all_of(CLIMA_EXTREMO_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

clima_extremo_table_lines <- function(rows) {
  if (nrow(rows) == 0) {
    return("Sem dados Clima Extremo filtrados para Matosinhos.")
  }

  c(
    "| Data | Índice de risco | Nível | Temperatura interior | Temperatura exterior | Vulnerabilidade |",
    "|---|---:|---|---:|---:|---:|",
    vapply(seq_len(nrow(rows)), function(i) {
      row <- rows[i, , drop = FALSE]
      paste0(
        "| ",
        as_text(row$target_date),
        " | ",
        display_temp(row$risk_index),
        " | ",
        as_text(row$risk_label),
        " | ",
        display_temp(row$indoor_temperature_c),
        " ºC | ",
        display_temp(row$outdoor_temperature_c),
        " ºC | ",
        display_temp(row$vulnerability_index),
        "/24 |"
      )
    }, character(1))
  )
}

highest_clima_extremo_row <- function(rows) {
  if (nrow(rows) == 0) {
    return(empty_frame(CLIMA_EXTREMO_COLUMNS))
  }

  rows %>%
    mutate(
      risk_level_order_num = to_num(risk_level_order),
      target_date_value = as.Date(target_date)
    ) %>%
    arrange(desc(risk_level_order_num), target_date_value) %>%
    slice(1) %>%
    select(all_of(CLIMA_EXTREMO_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

clima_extremo_recommendations <- function(rows) {
  if (nrow(rows) == 0) {
    return(paste(
      "Comunicação geral: não emitir recomendação automática com base no Clima Extremo sem validação manual; faltam dados filtrados para Matosinhos.",
      "Grupos vulneráveis: usar os restantes indicadores meteorológicos e ambientais enquanto se aguarda atualização.",
      "Estabelecimentos: manter planos de contingência de calor/frio disponíveis e confirmar o painel manualmente.",
      sep = "\n\n"
    ))
  }

  highest <- highest_clima_extremo_row(rows)
  order <- to_num(highest$risk_level_order)
  risk_label <- as_text(highest$risk_label)
  context <- clima_extremo_thermal_context(
    highest$indoor_temperature_c,
    highest$outdoor_temperature_c
  )

  if (is.na(order) || order < 0) {
    return(paste(
      paste0(
        "Comunicação geral: o Clima Extremo devolveu um índice bruto fora da escala declarada (",
        display_temp(highest$risk_index),
        "); não emitir recomendação automática baseada neste nível e cruzar a decisão com IPMA/SNS e observação local."
      ),
      "Grupos vulneráveis: manter vigilância proporcional aos restantes indicadores disponíveis; se houver desconforto térmico, doença crónica, isolamento ou habitação vulnerável, reforçar contacto e apoio prático.",
      "Estabelecimentos: manter planos de contingência disponíveis e confirmar conforto térmico, água, abrigo/sombra e canais de comunicação, sem ativar medidas extraordinárias só por este valor bruto.",
      sep = "\n\n"
    ))
  }

  if (order == 0) {
    return(paste(
      "Comunicação geral: risco baixo em edifícios no painel Clima Extremo; manter vigilância habitual do conforto térmico e cruzar com avisos IPMA/SNS.",
      "Grupos vulneráveis: manter rotinas habituais, com atenção a desconforto térmico em casa, hidratação e medicação habitual.",
      "Estabelecimentos: manter atividades previstas, garantindo água, abrigo/sombra quando necessário e canais de comunicação.",
      sep = "\n\n"
    ))
  }

  context_text <- if (context == "calor") {
    "O sinal está associado a contexto de calor; reforçar hidratação, sombra, arrefecimento seguro e redução de esforço nas horas quentes."
  } else if (context == "frio") {
    "O sinal está associado a contexto de frio; reforçar roupa adequada, aquecimento seguro, proteção de extremidades e vigilância respiratória/cardiovascular."
  } else {
    "Não há temperatura interior/exterior extrema no snapshot; interpretar o nível como sinal de vulnerabilidade e vigilância em edifícios."
  }

  if (order == 1) {
    return(paste(
      paste0(
        "Comunicação geral: risco médio em edifícios para Matosinhos no Clima Extremo. ",
        context_text,
        " Comunicar de forma neutra e preventiva."
      ),
      "Grupos vulneráveis: pessoas idosas, crianças, grávidas, pessoas com doença crónica, mobilidade reduzida ou isolamento social devem ter contacto regular, água/medicação acessível e ambiente interior confortável.",
      "Estabelecimentos: confirmar conforto térmico das salas, acesso a água, possibilidade de sombra/abrigo e adaptação de atividades exteriores se outros indicadores agravarem.",
      sep = "\n\n"
    ))
  }

  if (order == 2) {
    return(paste(
      paste0(
        "Comunicação geral: risco alto em edifícios para Matosinhos no Clima Extremo. ",
        context_text,
        " Reforçar comunicação de prevenção e reduzir exposição não essencial."
      ),
      "Grupos vulneráveis: contacto ativo com utentes/pessoas isoladas; verificar sintomas, hidratação/agasalho conforme contexto, medicação e condições de habitação.",
      "Estabelecimentos: ativar medidas de contingência proporcionais, ajustar horários, garantir espaços termicamente confortáveis, pausas e acompanhamento de utentes/trabalhadores vulneráveis.",
      sep = "\n\n"
    ))
  }

  paste(
    paste0(
      "Comunicação geral: risco extremo em edifícios para Matosinhos no Clima Extremo. ",
      context_text,
      " Ativar comunicação de alerta e medidas de contingência."
    ),
    "Grupos vulneráveis: acompanhamento ativo e repetido de pessoas idosas, crianças, pessoas com doença crónica, acamadas, isoladas ou com habitação vulnerável; contactar SNS 24 ou 112 perante sinais graves.",
    "Estabelecimentos: ativar plano de contingência, condicionar atividades exteriores, garantir espaços de abrigo/arrefecimento ou aquecimento seguro e monitorizar utentes/trabalhadores de maior risco.",
    sep = "\n\n"
  )
}

build_clima_extremo_daily_section <- function(rows, report_date) {
  source_update <- latest_source_update(rows)
  if (source_update == "") {
    source_update <- FETCHED_AT
  }

  recommendation_row <- highest_clima_extremo_row(rows)
  recommendation_order <- to_num(recommendation_row$risk_level_order)
  has_out_of_scale <- any(
    to_num(rows$risk_level_order) < 0 &
      vapply(rows$risk_index, function(value) as_text(value) != "", logical(1)),
    na.rm = TRUE
  )
  validation_note <- if (has_out_of_scale) {
    paste0(
      "Nota de validação: a API declara escala própria para o campo icaro, mas devolveu valor bruto ",
      display_temp(recommendation_row$risk_index),
      "; este valor fica documentado, mas não é usado como alerta automático."
    )
  } else {
    character()
  }
  recommendation_followup <- if (is.na(recommendation_order) || recommendation_order < 0) {
    "As recomendações abaixo são prudenciais e não tratam este valor como alerta acionável."
  } else {
    "As recomendações abaixo seguem este nível."
  }

  c(
    "<!-- clima-extremo:start -->",
    paste0("### Clima Extremo - risco em edifícios - previsões disponíveis em ", report_date),
    "",
    paste0(
      "Fonte dos valores: CLIMA EXTREMO. Snapshot recolhido em ",
      source_update,
      ". A API devolve a escala e os valores municipais, mas não devolve recomendações preenchidas; as medidas abaixo cruzam o nível com recomendações DGS/INSA para calor/frio."
    ),
    "",
    clima_extremo_table_lines(rows),
    "",
    validation_note,
    if (length(validation_note) > 0) "" else character(),
    paste0(
      "Nível mais exigente no período: ",
      as_text(recommendation_row$risk_label),
      " em ",
      as_text(recommendation_row$target_date),
      " (índice ",
      display_temp(recommendation_row$risk_index),
      "; temperatura interior ",
      display_temp(recommendation_row$indoor_temperature_c),
      " ºC; temperatura exterior ",
      display_temp(recommendation_row$outdoor_temperature_c),
      " ºC; vulnerabilidade ",
      display_temp(recommendation_row$vulnerability_index),
      "/24). ",
      recommendation_followup
    ),
    "",
    clima_extremo_recommendations(rows),
    "<!-- clima-extremo:end -->"
  )
}

alert_rows_for_report <- function(alerts, report_date) {
  alert_dates <- as.Date(alerts$target_date)
  end_dates <- as.Date(substr(alerts$end_time, 1, 10))
  report_date_value <- as.Date(report_date)
  selected <- alerts[
    (!is.na(end_dates) & end_dates >= report_date_value) |
      (is.na(end_dates) & (is.na(alert_dates) | alert_dates >= report_date_value)),
    ,
    drop = FALSE
  ]

  if (nrow(selected) == 0) {
    selected <- alerts
  }

  selected %>%
    mutate(alert_level_order_num = to_num(alert_level_order)) %>%
    arrange(alert_source, target_date, desc(alert_level_order_num), alert_type) %>%
    select(all_of(IPMA_ALERT_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

alert_period_text <- function(row) {
  start_time <- as_text(row$start_time)
  end_time <- as_text(row$end_time)
  target_date <- as_text(row$target_date)

  if (end_time != "" && start_time != end_time) {
    return(paste0(start_time, " a ", end_time))
  }

  if (start_time != "") {
    return(start_time)
  }

  target_date
}

alert_display_rows <- function(rows) {
  weather_rows <- rows[rows$alert_source == "Avisos meteorológicos", , drop = FALSE]
  fire_rows <- rows[rows$alert_source == "Risco de incêndio rural", , drop = FALSE]
  active_weather_rows <- weather_rows[
    to_num(weather_rows$alert_level_order) > 0,
    ,
    drop = FALSE
  ]

  if (nrow(weather_rows) > 0 && nrow(active_weather_rows) == 0) {
    weather_summary <- weather_rows[1, , drop = FALSE]
    start_values <- weather_rows$start_time[weather_rows$start_time != ""]
    end_values <- weather_rows$end_time[weather_rows$end_time != ""]
    weather_summary$start_time <- if (length(start_values) > 0) min(start_values) else ""
    weather_summary$end_time <- if (length(end_values) > 0) max(end_values) else ""
    weather_summary$alert_type <- "Todos os parâmetros meteorológicos"
    weather_summary$alert_level <- "Verde"
    weather_summary$alert_level_order <- "0"
    weather_summary$alert_color <- "Verde"
    weather_summary$description <- paste0(
      "Sem avisos meteorológicos ativos acima de Verde para ",
      WARNING_AREA_NAME,
      "."
    )
    active_weather_rows <- weather_summary
  }

  bind_rows(active_weather_rows, fire_rows) %>%
    mutate(alert_level_order_num = to_num(alert_level_order)) %>%
    arrange(alert_source, target_date, desc(alert_level_order_num), alert_type) %>%
    select(all_of(IPMA_ALERT_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

alert_table_lines <- function(rows) {
  display_rows <- alert_display_rows(rows)
  if (nrow(display_rows) == 0) {
    return("Sem avisos IPMA disponíveis no último snapshot.")
  }

  c(
    "| Fonte | Período/Data | Tipo | Nível | Nota |",
    "|---|---|---|---|---|",
    vapply(seq_len(nrow(display_rows)), function(i) {
      row <- display_rows[i, , drop = FALSE]
      note <- as_text(row$description)
      if (note == "") {
        note <- as_text(row$recommendation_summary)
      }
      paste0(
        "| ",
        as_text(row$alert_source),
        " | ",
        alert_period_text(row),
        " | ",
        as_text(row$alert_type),
        " | ",
        as_text(row$alert_level),
        " | ",
        note,
        " |"
      )
    }, character(1))
  )
}

highest_alert_row <- function(rows) {
  if (nrow(rows) == 0) {
    return(empty_frame(IPMA_ALERT_COLUMNS))
  }

  rows %>%
    mutate(alert_level_order_num = to_num(alert_level_order)) %>%
    arrange(desc(alert_level_order_num), target_date, alert_source, alert_type) %>%
    slice(1) %>%
    select(all_of(IPMA_ALERT_COLUMNS)) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

alert_specific_measures <- function(rows) {
  active_weather_types <- unique(rows$alert_type[
    rows$alert_source == "Avisos meteorológicos" &
      to_num(rows$alert_level_order) > 0
  ])
  measures <- character()

  if ("Agitação Marítima" %in% active_weather_types) {
    measures <- c(
      measures,
      "Agitação marítima: evitar molhes, praias, arribas e atividades náuticas; reforçar vigilância em passeios junto à frente marítima."
    )
  }
  if ("Precipitação" %in% active_weather_types || "Trovoada" %in% active_weather_types) {
    measures <- c(
      measures,
      "Precipitação/trovoada: desobstruir escoamentos, evitar atravessar zonas inundadas e suspender atividades exteriores durante trovoada."
    )
  }
  if ("Vento" %in% active_weather_types) {
    measures <- c(
      measures,
      "Vento: fixar objetos soltos, evitar zonas arborizadas, andaimes e estruturas temporárias."
    )
  }
  if ("Nevoeiro" %in% active_weather_types) {
    measures <- c(
      measures,
      "Nevoeiro: reduzir deslocações não essenciais e reforçar prudência em transporte de utentes."
    )
  }
  if ("Tempo Quente" %in% active_weather_types) {
    measures <- c(
      measures,
      "Tempo quente: aplicar medidas de calor, com hidratação, sombra, redução de esforço e vigilância de pessoas vulneráveis."
    )
  }
  if ("Tempo Frio" %in% active_weather_types || "Neve" %in% active_weather_types) {
    measures <- c(
      measures,
      "Tempo frio/neve: garantir aquecimento seguro, roupa adequada e condicionar deslocações se houver gelo ou neve."
    )
  }

  fire_rows <- rows[rows$alert_source == "Risco de incêndio rural", , drop = FALSE]
  if (nrow(fire_rows) > 0) {
    max_fire <- max(to_num(fire_rows$alert_level_order), na.rm = TRUE)
    if (!is.na(max_fire) && max_fire >= 3) {
      measures <- c(
        measures,
        "Incêndio rural: em risco muito elevado ou máximo, evitar qualquer atividade com fogo, faíscas ou máquinas no espaço rural e cumprir restrições legais."
      )
    } else if (!is.na(max_fire) && max_fire >= 2) {
      measures <- c(
        measures,
        "Incêndio rural: reforçar prevenção, evitar queimas, fogueiras e trabalhos que produzam faíscas sem validação/autorização."
      )
    } else {
      measures <- c(
        measures,
        "Incêndio rural: manter vigilância, não abandonar resíduos e evitar fontes de ignição no exterior."
      )
    }
  }

  if (length(measures) == 0) {
    return("Sem medidas específicas adicionais para além da vigilância habitual.")
  }

  paste(measures, collapse = "\n\n")
}

ipma_alert_recommendations <- function(rows) {
  if (nrow(rows) == 0) {
    return(paste(
      "Comunicação geral: não emitir recomendação automática de avisos IPMA sem validação manual; faltam dados do último snapshot.",
      "Grupos vulneráveis: manter vigilância de rotina e confirmar avisos IPMA/ANEPC antes de adaptar atividades.",
      "Estabelecimentos: manter planos de contingência disponíveis e aguardar validação manual dos dados.",
      sep = "\n\n"
    ))
  }

  highest <- highest_alert_row(rows)
  highest_level <- as_text(highest$alert_level)
  highest_type <- as_text(highest$alert_type)
  highest_source <- as_text(highest$alert_source)
  highest_order <- to_num(highest$alert_level_order)

  if (is.na(highest_order) || highest_order <= 0) {
    general <- "Comunicação geral: sem avisos meteorológicos ativos acima de Verde e com risco operacional baixo no último snapshot IPMA; manter vigilância e consultar atualizações."
    vulnerable <- "Grupos vulneráveis: manter rotinas habituais, com atenção a alterações meteorológicas locais e a indicações IPMA/ANEPC."
    establishments <- "Estabelecimentos: manter atividades previstas, garantindo canais de comunicação e planos de contingência acessíveis."
  } else {
    general <- paste0(
      "Comunicação geral: existe alerta IPMA relevante no período analisado (",
      highest_source,
      " - ",
      highest_type,
      ": ",
      highest_level,
      "). Comunicar o nível, período e fenómeno, acompanhar atualizações e reduzir exposição em atividades dependentes da meteorologia."
    )
    vulnerable <- "Grupos vulneráveis: antecipar contacto com pessoas idosas, crianças, pessoas com doença crónica, pessoas isoladas e pessoas com mobilidade reduzida; adaptar deslocações e atividades exteriores ao nível de aviso."
    establishments <- "Estabelecimentos: rever planos de contingência, condicionar atividades exteriores quando aplicável, confirmar equipas/contactos e seguir orientações da Proteção Civil, autarquia e forças de segurança."
  }

  paste(
    general,
    vulnerable,
    establishments,
    alert_specific_measures(rows),
    sep = "\n\n"
  )
}

build_ipma_alerts_daily_section <- function(rows, report_date) {
  source_updates <- unique(rows$source_updated_at[rows$source_updated_at != ""])
  source_update_text <- if (length(source_updates) == 0) {
    FETCHED_AT
  } else {
    paste(sort(source_updates), collapse = "; ")
  }

  c(
    "<!-- ipma-alerts:start -->",
    paste0("### Avisos IPMA - ", report_date),
    "",
    paste0(
      "Fonte dos valores: IPMA. Atualizações de origem consideradas: ",
      source_update_text,
      "."
    ),
    "",
    alert_table_lines(rows),
    "",
    ipma_alert_recommendations(rows),
    "<!-- ipma-alerts:end -->"
  )
}

replace_marked_section <- function(existing, section, marker) {
  start_marker <- paste0("<!-- ", marker, ":start -->")
  end_marker <- paste0("<!-- ", marker, ":end -->")
  start <- which(existing == start_marker)
  end <- which(existing == end_marker)

  if (length(start) > 0 && length(end) > 0 && end[1] > start[1]) {
    before <- if (start[1] > 1) existing[seq_len(start[1] - 1)] else character()
    after <- if (end[1] < length(existing)) existing[(end[1] + 1):length(existing)] else character()
    return(c(before, section, after))
  }

  source_header <- grep(SOURCES_HEADER_PATTERN, existing)
  if (length(source_header) > 0) {
    before <- if (source_header[1] > 1) existing[seq_len(source_header[1] - 1)] else character()
    after <- existing[source_header[1]:length(existing)]
    return(c(before, section, "", after))
  }

  c(existing, "", section)
}

replace_marked_section_after <- function(existing, section, marker, anchor_marker) {
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

  replace_marked_section(existing, section, marker)
}

replace_managed_section <- function(existing, section) {
  replace_marked_section(existing, section, "temperatura-dsp")
}

update_daily_temperature_report <- function(alerts) {
  if (nrow(alerts) == 0) {
    return("")
  }

  report_date <- format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ)
  selected <- alerts[alerts$target_date == report_date, , drop = FALSE]
  if (nrow(selected) == 0) {
    selected <- alerts[alerts$target_date >= report_date, , drop = FALSE]
  }
  if (nrow(selected) == 0) {
    selected <- alerts[1, , drop = FALSE]
    report_date <- as_text(selected$target_date)
  }

  dir.create(DAILY_DIR, showWarnings = FALSE, recursive = TRUE)
  report_path <- file.path(DAILY_DIR, paste0(report_date, ".md"))

  if (file.exists(report_path)) {
    existing <- readLines(report_path, warn = FALSE, encoding = "UTF-8")
  } else {
    existing <- c(
      paste0("# Relatório diário - ", LOCATION, ", ", DISTRICT),
      "",
      paste0("Ficheiro diário: ", report_date),
      ""
    )
  }

  section <- build_temperature_daily_section(selected[1, , drop = FALSE])
  updated <- replace_managed_section(existing, section)
  updated <- finalize_daily_report(updated, report_date)
  writeLines(updated, report_path, useBytes = TRUE)
  report_path
}

update_daily_heat_wave_report <- function(heat_waves) {
  if (nrow(heat_waves) == 0) {
    return("")
  }

  report_date <- format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ)
  heat_dates <- as.Date(heat_waves$target_date)
  if (!any(!is.na(heat_dates) & heat_dates >= as.Date(report_date))) {
    report_date <- as_text(heat_waves$target_date[1])
  }
  selected <- heat_wave_rows_for_report(heat_waves, report_date)

  dir.create(DAILY_DIR, showWarnings = FALSE, recursive = TRUE)
  report_path <- file.path(DAILY_DIR, paste0(report_date, ".md"))

  if (file.exists(report_path)) {
    existing <- readLines(report_path, warn = FALSE, encoding = "UTF-8")
  } else {
    existing <- c(
      paste0("# Relatório diário - ", LOCATION, ", ", DISTRICT),
      "",
      paste0("Ficheiro diário: ", report_date),
      ""
    )
  }

  section <- build_heat_wave_daily_section(selected, report_date)
  updated <- replace_marked_section_after(
    existing,
    section,
    "onda-calor",
    "temperatura-dsp"
  )
  updated <- finalize_daily_report(updated, report_date)
  writeLines(updated, report_path, useBytes = TRUE)
  report_path
}

update_daily_thermal_stress_report <- function(thermal_stress) {
  if (nrow(thermal_stress) == 0) {
    return("")
  }

  report_date <- format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ)
  thermal_dates <- as.Date(thermal_stress$target_date)
  if (!any(!is.na(thermal_dates) & thermal_dates >= as.Date(report_date))) {
    report_date <- as_text(thermal_stress$target_date[1])
  }
  selected <- thermal_stress_rows_for_report(thermal_stress, report_date)

  dir.create(DAILY_DIR, showWarnings = FALSE, recursive = TRUE)
  report_path <- file.path(DAILY_DIR, paste0(report_date, ".md"))

  if (file.exists(report_path)) {
    existing <- readLines(report_path, warn = FALSE, encoding = "UTF-8")
  } else {
    existing <- c(
      paste0("# Relatório diário - ", LOCATION, ", ", DISTRICT),
      "",
      paste0("Ficheiro diário: ", report_date),
      ""
    )
  }

  section <- build_thermal_stress_daily_section(selected, report_date)
  updated <- replace_marked_section_after(
    existing,
    section,
    "utci",
    "onda-calor"
  )
  updated <- finalize_daily_report(updated, report_date)
  writeLines(updated, report_path, useBytes = TRUE)
  report_path
}

update_daily_sns_health_report <- function(indices) {
  if (nrow(indices) == 0) {
    return("")
  }

  report_date <- format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ)
  selected <- sns_health_rows_for_report(indices, report_date)

  dir.create(DAILY_DIR, showWarnings = FALSE, recursive = TRUE)
  report_path <- file.path(DAILY_DIR, paste0(report_date, ".md"))

  if (file.exists(report_path)) {
    existing <- readLines(report_path, warn = FALSE, encoding = "UTF-8")
  } else {
    existing <- c(
      paste0("# Relatório diário - ", LOCATION, ", ", DISTRICT),
      "",
      paste0("Ficheiro diário: ", report_date),
      ""
    )
  }

  section <- build_sns_health_daily_section(selected, report_date)
  updated <- replace_marked_section_after(
    existing,
    section,
    "sns-health",
    "utci"
  )
  updated <- finalize_daily_report(updated, report_date)
  writeLines(updated, report_path, useBytes = TRUE)
  report_path
}

update_daily_clima_extremo_report <- function(risk) {
  if (nrow(risk) == 0) {
    return("")
  }

  report_date <- format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ)
  risk_dates <- as.Date(risk$target_date)
  if (!any(!is.na(risk_dates) & risk_dates >= as.Date(report_date))) {
    report_date <- as_text(risk$target_date[1])
  }
  selected <- clima_extremo_rows_for_report(risk, report_date)

  dir.create(DAILY_DIR, showWarnings = FALSE, recursive = TRUE)
  report_path <- file.path(DAILY_DIR, paste0(report_date, ".md"))

  if (file.exists(report_path)) {
    existing <- readLines(report_path, warn = FALSE, encoding = "UTF-8")
  } else {
    existing <- c(
      paste0("# Relatório diário - ", LOCATION, ", ", DISTRICT),
      "",
      paste0("Ficheiro diário: ", report_date),
      ""
    )
  }

  section <- build_clima_extremo_daily_section(selected, report_date)
  updated <- replace_marked_section_after(
    existing,
    section,
    "clima-extremo",
    "sns-health"
  )
  updated <- finalize_daily_report(updated, report_date)
  writeLines(updated, report_path, useBytes = TRUE)
  report_path
}

update_daily_uv_report <- function(uv_index) {
  if (nrow(uv_index) == 0) {
    return("")
  }

  report_date <- format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ)
  uv_dates <- as.Date(uv_index$target_date)
  if (!any(!is.na(uv_dates) & uv_dates >= as.Date(report_date))) {
    report_date <- as_text(uv_index$target_date[1])
  }
  selected <- uv_rows_for_report(uv_index, report_date)

  dir.create(DAILY_DIR, showWarnings = FALSE, recursive = TRUE)
  report_path <- file.path(DAILY_DIR, paste0(report_date, ".md"))

  if (file.exists(report_path)) {
    existing <- readLines(report_path, warn = FALSE, encoding = "UTF-8")
  } else {
    existing <- c(
      paste0("# Relatório diário - ", LOCATION, ", ", DISTRICT),
      "",
      paste0("Ficheiro diário: ", report_date),
      ""
    )
  }

  section <- build_uv_daily_section(selected, report_date)
  updated <- replace_marked_section(existing, section, "uv")
  updated <- finalize_daily_report(updated, report_date)
  writeLines(updated, report_path, useBytes = TRUE)
  report_path
}

update_daily_ipma_alerts_report <- function(alerts) {
  if (nrow(alerts) == 0) {
    return("")
  }

  report_date <- format(Sys.time(), "%Y-%m-%d", tz = LOCAL_TZ)
  alert_dates <- as.Date(alerts$target_date)
  end_dates <- as.Date(substr(alerts$end_time, 1, 10))
  has_relevant_alert <- any(
    (!is.na(end_dates) & end_dates >= as.Date(report_date)) |
      (is.na(end_dates) & (is.na(alert_dates) | alert_dates >= as.Date(report_date)))
  )
  if (!has_relevant_alert) {
    report_date <- as_text(alerts$target_date[1])
  }
  selected <- alert_rows_for_report(alerts, report_date)

  dir.create(DAILY_DIR, showWarnings = FALSE, recursive = TRUE)
  report_path <- file.path(DAILY_DIR, paste0(report_date, ".md"))

  if (file.exists(report_path)) {
    existing <- readLines(report_path, warn = FALSE, encoding = "UTF-8")
  } else {
    existing <- c(
      paste0("# Relatório diário - ", LOCATION, ", ", DISTRICT),
      "",
      paste0("Ficheiro diário: ", report_date),
      ""
    )
  }

  section <- build_ipma_alerts_daily_section(selected, report_date)
  updated <- replace_marked_section(existing, section, "ipma-alerts")
  updated <- finalize_daily_report(updated, report_date)
  writeLines(updated, report_path, useBytes = TRUE)
  report_path
}

ipma_run_mode <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  mode <- if (length(args) > 0) {
    args[[1]]
  } else {
    Sys.getenv("IPMA_RUN_MODE", unset = "full")
  }

  tolower(mode)
}

run_station_fallback_pipeline <- function() {
  station_observations_data <- build_station_observations()
  station_observations_history <- write_station_observations(station_observations_data)

  station_daily_data <- build_station_daily_temperatures(station_observations_history)
  station_daily_history <- write_station_daily_temperatures(station_daily_data)

  list(
    observations_data = station_observations_data,
    observations_history = station_observations_history,
    daily_data = station_daily_data,
    daily_history = station_daily_history
  )
}

run_ipma_alerts_pipeline <- function() {
  ipma_alerts_data <- build_ipma_alerts()
  ipma_alerts_result <- write_ipma_alerts(ipma_alerts_data)
  daily_ipma_alerts_report_path <- update_daily_ipma_alerts_report(ipma_alerts_result$latest)

  list(
    data = ipma_alerts_data,
    result = ipma_alerts_result,
    report_path = daily_ipma_alerts_report_path
  )
}

run_sns_health_pipeline <- function() {
  sns_health_data <- build_sns_health_indices()
  sns_health_result <- write_sns_health_indices(sns_health_data)
  daily_sns_health_report_path <- update_daily_sns_health_report(
    sns_health_result$latest
  )

  list(
    data = sns_health_data,
    result = sns_health_result,
    report_path = daily_sns_health_report_path
  )
}

run_clima_extremo_pipeline <- function() {
  tryCatch(
    {
      clima_extremo_data <- build_clima_extremo_risk()
      clima_extremo_result <- write_clima_extremo_risk(clima_extremo_data)
      daily_clima_extremo_report_path <- update_daily_clima_extremo_report(
        clima_extremo_result$latest
      )

      list(
        data = clima_extremo_data,
        result = clima_extremo_result,
        report_path = daily_clima_extremo_report_path,
        used_cache = FALSE,
        error = ""
      )
    },
    error = function(error) {
      warning(
        "Clima Extremo indisponível; a usar cache se existir: ",
        conditionMessage(error),
        call. = FALSE
      )

      combined <- read_existing(CLIMA_EXTREMO_PATH, CLIMA_EXTREMO_COLUMNS)
      latest <- read_existing(CLIMA_EXTREMO_LATEST_PATH, CLIMA_EXTREMO_COLUMNS)
      if (nrow(latest) == 0 && nrow(combined) > 0) {
        latest_update <- latest_source_update(combined)
        latest <- combined[
          combined$source_updated_at == latest_update,
          ,
          drop = FALSE
        ]
        if (nrow(latest) > 0) {
          write_csv(latest, CLIMA_EXTREMO_LATEST_PATH, na = "")
        }
      }

      daily_clima_extremo_report_path <- tryCatch(
        {
          if (nrow(latest) > 0) {
            update_daily_clima_extremo_report(latest)
          } else {
            ""
          }
        },
        error = function(report_error) {
          warning(
            "Clima Extremo: não foi possível atualizar a secção diária com cache: ",
            conditionMessage(report_error),
            call. = FALSE
          )
          ""
        }
      )

      list(
        data = empty_frame(CLIMA_EXTREMO_COLUMNS),
        result = list(combined = combined, latest = latest),
        report_path = daily_clima_extremo_report_path,
        used_cache = TRUE,
        error = conditionMessage(error)
      )
    }
  )
}

run_full_pipeline <- function() {
  climate_temperature_data <- build_temperature_history()
  station <- run_station_fallback_pipeline()

  temperature_data <- apply_station_temperature_fallback(
    climate_temperature_data,
    station$daily_history
  )
  temperature_history <- write_temperature_history(temperature_data)

  forecast_data <- build_forecasts()
  forecast_result <- write_forecasts(forecast_data)

  temperature_alerts_data <- build_temperature_alerts(
    temperature_history,
    forecast_result$latest
  )
  temperature_alerts_result <- write_temperature_alerts(temperature_alerts_data)
  daily_temperature_report_path <- update_daily_temperature_report(
    temperature_alerts_result$latest
  )

  heat_wave_data <- build_heat_waves(
    temperature_history,
    forecast_result$latest
  )
  heat_wave_result <- write_heat_waves(heat_wave_data)
  daily_heat_wave_report_path <- update_daily_heat_wave_report(heat_wave_result$latest)

  thermal_stress_data <- build_thermal_stress(forecast_result$latest)
  thermal_stress_result <- write_thermal_stress(thermal_stress_data)
  daily_thermal_stress_report_path <- update_daily_thermal_stress_report(
    thermal_stress_result$latest
  )

  uv_index_data <- build_uv_index(forecast_result$latest)
  uv_index_result <- write_uv_index(uv_index_data)
  daily_uv_report_path <- update_daily_uv_report(uv_index_result$latest)

  sns_health <- run_sns_health_pipeline()
  clima_extremo <- run_clima_extremo_pipeline()
  ipma_alerts <- run_ipma_alerts_pipeline()

  message(sprintf(
    paste(
      "OK full - %d climate temperature row(s) fetched; %d station observation row(s) fetched.",
      "Station observation archive has %d row(s); station daily fallback has %d row(s).",
      "%d temperature row(s) prepared; temperature history has %d row(s).",
      "%d forecast row(s) fetched; forecast archive has %d row(s); latest snapshot has %d row(s).",
      "%d temperature alert row(s) calculated; alert archive has %d row(s); temperature report: %s.",
      "%d heat wave row(s) calculated; heat wave archive has %d row(s); heat wave report: %s.",
      "%d UTCI row(s) calculated; UTCI archive has %d row(s); UTCI report: %s.",
      "%d UV row(s) calculated; UV archive has %d row(s); UV report: %s.",
      "%d SNS/INSA health index row(s) collected; SNS/INSA archive has %d row(s); SNS/INSA report: %s.",
      "%d Clima Extremo row(s) collected; Clima Extremo archive has %d row(s); Clima Extremo report: %s.",
      "%d IPMA alert row(s) collected; IPMA alert archive has %d row(s); IPMA alert report: %s."
    ),
    nrow(climate_temperature_data),
    nrow(station$observations_data),
    nrow(station$observations_history),
    nrow(station$daily_history),
    nrow(temperature_data),
    nrow(temperature_history),
    nrow(forecast_data),
    nrow(forecast_result$combined),
    nrow(forecast_result$latest),
    nrow(temperature_alerts_data),
    nrow(temperature_alerts_result$combined),
    daily_temperature_report_path,
    nrow(heat_wave_data),
    nrow(heat_wave_result$combined),
    daily_heat_wave_report_path,
    nrow(thermal_stress_data),
    nrow(thermal_stress_result$combined),
    daily_thermal_stress_report_path,
    nrow(uv_index_data),
    nrow(uv_index_result$combined),
    daily_uv_report_path,
    nrow(sns_health$data),
    nrow(sns_health$result$combined),
    sns_health$report_path,
    nrow(clima_extremo$data),
    nrow(clima_extremo$result$combined),
    clima_extremo$report_path,
    nrow(ipma_alerts$data),
    nrow(ipma_alerts$result$combined),
    ipma_alerts$report_path
  ))
}

run_light_pipeline <- function() {
  station <- run_station_fallback_pipeline()
  sns_health <- run_sns_health_pipeline()
  clima_extremo <- run_clima_extremo_pipeline()
  ipma_alerts <- run_ipma_alerts_pipeline()

  message(sprintf(
    paste(
      "OK light - %d station observation row(s) fetched.",
      "Station observation archive has %d row(s); station daily fallback has %d row(s).",
      "%d SNS/INSA health index row(s) collected; SNS/INSA archive has %d row(s); SNS/INSA report: %s.",
      "%d Clima Extremo row(s) collected; Clima Extremo archive has %d row(s); Clima Extremo report: %s.",
      "%d IPMA alert row(s) collected; IPMA alert archive has %d row(s); IPMA alert report: %s."
    ),
    nrow(station$observations_data),
    nrow(station$observations_history),
    nrow(station$daily_history),
    nrow(sns_health$data),
    nrow(sns_health$result$combined),
    sns_health$report_path,
    nrow(clima_extremo$data),
    nrow(clima_extremo$result$combined),
    clima_extremo$report_path,
    nrow(ipma_alerts$data),
    nrow(ipma_alerts$result$combined),
    ipma_alerts$report_path
  ))
}

run_clima_extremo_only_pipeline <- function() {
  clima_extremo <- run_clima_extremo_pipeline()

  message(sprintf(
    "OK clima-extremo - %d row(s) collected; archive has %d row(s); report: %s.",
    nrow(clima_extremo$data),
    nrow(clima_extremo$result$combined),
    clima_extremo$report_path
  ))
}

run_alerts_pipeline <- function() {
  ipma_alerts <- run_ipma_alerts_pipeline()

  message(sprintf(
    "OK alerts - %d IPMA alert row(s) collected; IPMA alert archive has %d row(s); IPMA alert report: %s.",
    nrow(ipma_alerts$data),
    nrow(ipma_alerts$result$combined),
    ipma_alerts$report_path
  ))
}

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

mode <- ipma_run_mode()
if (mode == "full") {
  run_full_pipeline()
} else if (mode == "light") {
  run_light_pipeline()
} else if (mode %in% c("clima-extremo", "clima_extremo")) {
  run_clima_extremo_only_pipeline()
} else if (mode == "alerts") {
  run_alerts_pipeline()
} else {
  stop("Unknown IPMA run mode: ", mode, ". Use full, light, clima-extremo or alerts.")
}
