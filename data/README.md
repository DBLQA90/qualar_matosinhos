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
- `ipma_matosinhos_uv_index.csv`: arquivo do Índice UV previsto para Matosinhos, mantendo cada atualização IPMA através de `source_updated_at`.
- `ipma_matosinhos_uv_index_latest.csv`: Índice UV previsto com a atualização IPMA mais recente, com nível de risco e recomendação resumida.
- `ipma_matosinhos_heat_waves.csv`: arquivo do indicador de onda de calor, calculado com temperaturas máximas observadas/previstas e a normal climatológica IPMA 1991-2020 de Porto/Pedras Rubras.
- `ipma_matosinhos_heat_waves_latest.csv`: indicador de onda de calor calculado com a atualização IPMA mais recente.
- `ipma_matosinhos_alerts.csv`: arquivo agregado dos avisos meteorológicos IPMA para a área de aviso do Porto (`PTO`) e do risco de incêndio rural para o concelho de Matosinhos (`DICO` 1308).
- `ipma_matosinhos_alerts_latest.csv`: último snapshot disponível dos avisos meteorológicos e do risco de incêndio rural.

## Notas

- As temperaturas históricas usam os ficheiros IPMA por concelho para temperatura mínima e máxima. Quando esses ficheiros não cobrem uma data recente, o script usa como fallback a média diária das estações Pedras Rubras/S. Gens. A coluna `tmean_estimated_c` é calculada como `(tmin_c + tmax_c) / 2`.
- As previsões IPMA estão em UTC, de acordo com a documentação da API do IPMA.
- Os alertas de temperatura DSP usam as regras fornecidas para máxima e mínima: para a máxima, 3 dias observados e 2 previstos; para a mínima, 2 dias observados e 2 previstos. Se faltar algum valor necessário, o alerta fica `Sem dados`. O indicador só é aplicado automaticamente entre maio e outubro; fora desse período fica `Fora de época`.
- O Índice UV usa o campo diário `iUv` da previsão agregada por local para Matosinhos (`globalIdLocal` 1130800). A escala operacional usa limiares contínuos para lidar com valores decimais: `Baixo` < 3, `Moderado` >= 3 e < 6, `Alto` >= 6 e < 8, `Muito Alto` >= 8 e < 11, `Extremo` >= 11, alinhada com a classificação IPMA/OMS.
- O relatório diário mostra todas as datas do último snapshot IPMA com Índice UV preenchido e usa o nível mais elevado desse período para gerar as recomendações.
- A onda de calor segue a definição IPMA/HWDI: pelo menos 6 dias consecutivos com temperatura máxima diária superior em 5 ºC à normal mensal. Como referência operacional local, usa-se a Normal Climatológica 1991-2020 de Porto/Pedras Rubras (`TX` mensal) e compara-se cada dia com o limiar do respetivo mês. O ficheiro também guarda um `Sinal preventivo de 5 dias`, que não é uma onda de calor formal, mas ajuda a preparar medidas se a sequência se prolongar.
- Os avisos meteorológicos são distritais; para Matosinhos usa-se a área de aviso do Porto (`PTO`). O risco de incêndio rural é recolhido por concelho, usando `DICO` 1308.
- O workflow `Recolher IPMA Matosinhos` corre às 10:15 UTC, 14:15 UTC e 20:15 UTC, pouco depois das duas disponibilizações diárias indicadas pelo IPMA e com uma verificação intermédia, e atualiza as secções `Temperatura DSP`, `Onda de Calor`, `Índice UV` e `Avisos IPMA` no ficheiro diário do dia de execução quando há previsão atual, ou na primeira data disponível quando não há.
