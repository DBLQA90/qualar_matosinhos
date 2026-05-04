library(httr)
library(jsonlite)
library(dplyr)
library(readr)

CSV_PATH <- "qualar_matosinhos.csv"

url <- paste0(
  "https://sniambgeoogc.apambiente.pt/getogc/rest/services/Visualizador/QAR/MapServer/5/query",
  "?f=json",
  "&where=concelho%3D%27MATOSINHOS%27",
  "&outFields=*",
  "&returnGeometry=false"
)

res <- GET(
  url,
  add_headers(
    `User-Agent` = "Mozilla/5.0",
    `Origin` = "https://qualar.apambiente.pt",
    `Referer` = "https://qualar.apambiente.pt/"
  ),
  timeout(30)
)
stop_for_status(res)

raw <- content(res, as = "text", encoding = "UTF-8")
parsed <- fromJSON(raw, simplifyVector = TRUE)

if (length(parsed$features) == 0) {
  message("Sem features. Parar.")
  quit(status = 0)
}

new_data <- parsed$features$attributes

# Converter timestamp e preservar raw
if ("data" %in% names(new_data) && is.numeric(new_data$data)) {
  new_data$data_raw_ms <- new_data$data
  new_data$data <- format(
    as.POSIXct(new_data$data / 1000, origin = "1970-01-01", tz = "UTC"),
    "%Y-%m-%d"
  )
}

# Sinalizar registos N/D — guardar mas marcar
new_data$nd <- ifelse(
  trimws(new_data$classe) %in% c("N/D", "N,D", "ND", ""),
  TRUE, FALSE
)

new_data$fetched_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

# Tudo como character para estabilidade de schema
new_data[] <- lapply(new_data, as.character)

# Unir com histórico preservando colunas
if (file.exists(CSV_PATH)) {
  existing <- read_csv(CSV_PATH, show_col_types = FALSE,
                       col_types = cols(.default = "c"))
  old_cols   <- names(existing)
  added_cols <- setdiff(names(new_data), old_cols)
  final_order <- c(old_cols, added_cols)
  combined <- bind_rows(existing, new_data)
  combined <- combined[, intersect(final_order, names(combined))]
} else {
  combined <- new_data
}

write_csv(combined, CSV_PATH, na = "")

n_nd <- sum(new_data$nd == "TRUE")
message(sprintf("OK — %d linha(s) adicionadas, %d com N/D. CSV total: %d linhas.",
                nrow(new_data), n_nd, nrow(combined)))
