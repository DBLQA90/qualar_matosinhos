# Dados IPMA para Matosinhos

Este diretório guarda dados meteorológicos do IPMA separados dos dados QualAr.

## Ficheiros

- `ipma_matosinhos_temperaturas.csv`: histórico diário observado/interpolado por concelho. A primeira execução guarda todos os registos atualmente disponibilizados pelo IPMA; execuções seguintes acrescentam datas novas e atualizam datas revistas.
- `ipma_matosinhos_station_observations.csv`: arquivo horário das temperaturas observadas nas estações Porto, Pedras Rubras (`1200545`) e S. Gens (`1210649`), usado como fallback quando o histórico por concelho não cobre datas recentes.
- `ipma_matosinhos_station_daily_temperatures.csv`: mínimos e máximos diários calculados a partir do arquivo horário das duas estações, usando a média dos extremos disponíveis por estação.
- `ipma_matosinhos_forecasts.csv`: arquivo de todas as previsões recolhidas para Matosinhos (`globalIdLocal` 1130800), mantendo cada atualização IPMA através de `source_updated_at`.
- `ipma_matosinhos_forecast_latest.csv`: apenas a atualização IPMA mais recente, útil para consumo direto por relatórios ou scripts.
- `ipma_matosinhos_temperature_alerts.csv`: arquivo dos alertas de temperatura DSP calculados a partir de temperatura máxima/mínima observada e prevista.
- `ipma_matosinhos_temperature_alert_latest.csv`: alertas de temperatura DSP calculados com a atualização IPMA mais recente.

## Notas

- As temperaturas históricas usam os ficheiros IPMA por concelho para temperatura mínima e máxima. Quando esses ficheiros não cobrem uma data recente, o script usa como fallback a média diária das estações Pedras Rubras/S. Gens. A coluna `tmean_estimated_c` é calculada como `(tmin_c + tmax_c) / 2`.
- As previsões IPMA estão em UTC, de acordo com a documentação da API do IPMA.
- Os alertas de temperatura DSP usam as regras fornecidas para máxima e mínima: para a máxima, 3 dias observados e 2 previstos; para a mínima, 2 dias observados e 2 previstos. Se faltar algum valor necessário, o alerta fica `Sem dados`. O indicador só é aplicado automaticamente entre maio e outubro; fora desse período fica `Fora de época`.
- O workflow `Recolher IPMA Matosinhos` corre às 10:15 UTC, 14:15 UTC e 20:15 UTC, pouco depois das duas disponibilizações diárias indicadas pelo IPMA e com uma verificação intermédia, e atualiza a secção `Temperatura DSP` no ficheiro diário correspondente à primeira data disponível na previsão IPMA.
