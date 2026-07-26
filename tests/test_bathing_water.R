source("fetch_bathing_water.R", encoding = "UTF-8")

expect_bw <- function(actual, expected, label) {
  if (!identical(actual, expected)) {
    stop(
      sprintf("%s\nExpected: %s\nActual: %s", label, expected, actual),
      call. = FALSE
    )
  }
}

epoch_ms <- function(value) {
  as.numeric(as.POSIXct(value, tz = "UTC")) * 1000
}

feature <- function(status, code, reason = "") {
  list(
    attributes = list(
      codigo_praia = 1,
      nome_praia = "Praia de teste",
      codigo_agua_balnear = "PTTEST",
      nome_agua_balnear = "ÁGUA DE TESTE",
      arh = "ARH-NORTE",
      data_inicio_epoca_balnear = epoch_ms("2026-06-01"),
      data_fim_epoca_balnear = epoch_ms("2026-09-30"),
      categoria_agua_balnear = 1,
      classificacao_agua_balnear = 1,
      qualidade_agua_balnear_dsc = status,
      motivo_desacons_interdicao = code,
      motivo_desacons_interdicao_dsc = reason,
      vigilancia = 1,
      posto_socorros = 1,
      acessivel = 1,
      bandeira_azul = 1,
      obras_em_curso = 0,
      risco_derrocada = 0,
      ondas_especial_valor = 0,
      url_infopraia = "https://example.test/info",
      url_snirh = "https://example.test/snirh"
    ),
    geometry = list(x = -8.7, y = 41.2)
  )
}

discouraged <- bw_flatten_feature(
  feature("Água desaconselhada a banhos", 1, "Contaminação microbiológica"),
  snapshot_date = "2026-07-26",
  fetched_at = "2026-07-26T10:00:00Z"
)
interdicted <- bw_flatten_feature(
  feature("Água interdita a banhos", 2, "Contaminação microbiológica"),
  snapshot_date = "2026-07-26",
  fetched_at = "2026-07-26T10:00:00Z"
)
outside_season <- bw_flatten_feature(
  feature("Água adequada a banhos", 0),
  snapshot_date = "2026-11-01",
  fetched_at = "2026-11-01T10:00:00Z"
)

expect_bw(
  discouraged$risk_level_order,
  "2",
  "A bathing discouragement must map to operational order 2."
)
expect_bw(
  interdicted$risk_level_order,
  "3",
  "A bathing prohibition must map to operational order 3."
)
expect_bw(
  outside_season$risk_label,
  "Fora da época balnear",
  "An adequate status outside the bathing season must not imply active monitoring."
)
expect_bw(
  discouraged$in_bathing_season,
  "TRUE",
  "The bathing-season dates must be interpreted from ArcGIS epoch milliseconds."
)

cat("OK bathing-water classification tests\n")
