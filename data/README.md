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
- `ipma_matosinhos_thermal_stress.csv`: arquivo horário do UTCI/temperatura sentida previsto para Matosinhos, classificado em stress térmico por calor/frio.
- `ipma_matosinhos_thermal_stress_latest.csv`: último snapshot UTCI previsto, útil para o boletim diário.
- `sns_matosinhos_temperature_health_indices.csv`: arquivo dos índices SNS/INSA ÍCARO e FRIESA relevantes para Matosinhos. O ÍCARO é nacional; o FRIESA usa o distrito do Porto, incluindo população geral e 65+ anos.
- `sns_matosinhos_temperature_health_indices_latest.csv`: linhas recentes dos índices SNS/INSA para consumo direto pelo boletim.
- `clima_extremo_matosinhos_risk.csv`: arquivo dos valores municipais do painel CLIMA EXTREMO filtrados por `region = matosinhos`, incluindo índice de risco em edifícios, temperatura interior/exterior e vulnerabilidade.
- `clima_extremo_matosinhos_risk_latest.csv`: último snapshot CLIMA EXTREMO para consumo direto pelo boletim.
- `ipma_matosinhos_alerts.csv`: arquivo agregado dos avisos meteorológicos IPMA para a área de aviso do Porto (`PTO`) e do risco de incêndio rural para o concelho de Matosinhos (`DICO` 1308).
- `ipma_matosinhos_alerts_latest.csv`: último snapshot disponível dos avisos meteorológicos e do risco de incêndio rural.

## Notas

- As temperaturas históricas usam os ficheiros IPMA por concelho para temperatura mínima e máxima. Quando esses ficheiros não cobrem uma data recente, o script usa como fallback a média diária das estações Pedras Rubras/S. Gens. A coluna `tmean_estimated_c` é calculada como `(tmin_c + tmax_c) / 2`.
- As previsões IPMA estão em UTC, de acordo com a documentação da API do IPMA.
- Os alertas de temperatura DSP usam as regras fornecidas para máxima e mínima: para a máxima, 3 dias observados e 2 previstos; para a mínima, 2 dias observados e 2 previstos. Se faltar algum valor necessário, o alerta fica `Sem dados`. O indicador só é aplicado automaticamente entre maio e outubro; fora desse período fica `Fora de época`.
- O Índice UV usa o campo diário `iUv` da previsão agregada por local para Matosinhos (`globalIdLocal` 1130800). A escala operacional usa limiares contínuos para lidar com valores decimais: `Baixo` < 3, `Moderado` >= 3 e < 6, `Alto` >= 6 e < 8, `Muito Alto` >= 8 e < 11, `Extremo` >= 11, alinhada com a classificação IPMA/OMS.
- O relatório diário mostra todas as datas do último snapshot IPMA com Índice UV preenchido e usa o nível mais elevado desse período para gerar as recomendações.
- A onda de calor segue a definição IPMA/HWDI: pelo menos 6 dias consecutivos com temperatura máxima diária superior em 5 ºC à normal mensal. Como referência operacional local, usa-se a Normal Climatológica 1991-2020 de Porto/Pedras Rubras (`TX` mensal) e compara-se cada dia com o limiar do respetivo mês. O ficheiro também guarda um `Sinal preventivo de 5 dias`, que não é uma onda de calor formal, mas ajuda a preparar medidas se a sequência se prolongar.
- O UTCI usa o campo `utci` das previsões agregadas do IPMA, quando preenchido, e segue a escala IPMA/COST Action 730 para stress por calor e por frio. O boletim diário apresenta o pico de stress térmico por data e usa o nível mais exigente para as recomendações.
- O ÍCARO estima excesso relativo de risco por calor e é disponibilizado em dias úteis entre maio e setembro; os últimos 3 dias podem ser provisórios. O FRIESA estima risco por frio extremo nos distritos de Lisboa e Porto e é disponibilizado em dias úteis entre novembro e março; os últimos 9 dias podem ser provisórios. O boletim diário só apresenta cada índice na respetiva época operacional, deixando nota quando estiver fora de época. Para FRIESA, a API pública disponibiliza o índice, mas não os limiares operacionais dos níveis de alerta.
- O CLIMA EXTREMO é recolhido pela API pública usada no painel `http://climaextremo.vps.tecnico.ulisboa.pt/`. A camada geográfica inclui um registo municipal `matosinhos`; o boletim usa o índice principal de risco em edifícios (`icaro` na API do painel) e a escala devolvida nos metadados: Baixo, Médio, Alto e Extremo. A API não inclui timestamp de atualização nem recomendações preenchidas, por isso `source_updated_at` corresponde ao momento de recolha e as medidas usam o nível do painel com apoio das recomendações DGS/INSA para calor/frio.
- Os avisos meteorológicos são distritais; para Matosinhos usa-se a área de aviso do Porto (`PTO`). O risco de incêndio rural é recolhido por concelho, usando `DICO` 1308.
- O topo do boletim diário é consolidado por `report_summary.R`: primeiro apresenta a síntese operacional, a proposta de nível local com os indicadores atualmente disponíveis, a recomendação para hoje, os próximos dias e o quadro rápido de risco; os blocos por indicador ficam abaixo como detalhe. A proposta de nível local é apoio à decisão e ainda não integra automaticamente indicadores assistenciais internos da ULSM, SINAVE/surtos locais, escalas, camas ou stocks. As fontes e notas metodológicas ficam concentradas no fim, agrupadas por indicador.
- O workflow `Recolher IPMA Matosinhos` corre em modo completo às 10:15 UTC e 20:15 UTC, pouco depois das duas disponibilizações diárias indicadas pelo IPMA. Às 14:15 UTC corre em modo leve, atualizando observações de estações, índices SNS/INSA, Clima Extremo e avisos IPMA. O modo completo atualiza as secções `Temperatura DSP`, `Onda de Calor`, `Stress térmico UTCI`, `Índices SNS/INSA`, `Clima Extremo`, `Índice UV` e `Avisos IPMA` no ficheiro diário do dia de execução quando há previsão atual, ou na primeira data disponível quando não há.
