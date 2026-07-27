# Catálogo de indicadores do PNPRSS Matosinhos

Última revisão: 2026-07-26

## Objetivo

Este ficheiro é o catálogo de metainformação dos indicadores usados ou considerados pelo projeto. Documenta o significado de cada indicador, a origem dos dados, a resolução espacial e temporal, as regras de cálculo, a utilização no boletim, as limitações e a resposta a falhas.

O catálogo distingue:

- **Operacional automatizado**: entra automaticamente no boletim e nas recomendações.
- **Complementar automatizado**: é calculado e apresentado, mas não determina isoladamente o nível operacional.
- **Analítico**: serve para validação, comparação ou desenvolvimento e não entra na decisão diária.
- **Pendente interno**: está previsto nos planos, mas exige uma fonte institucional ou introdução manual validada.
- **Não iniciado**: foi identificado, mas não está em desenvolvimento nesta fase.

## Regras transversais

| Elemento | Regra |
|---|---|
| Âmbito principal | Concelho de Matosinhos; quando a fonte não tem nível municipal, a aproximação geográfica é explicitada. |
| Fuso horário | `Europe/Lisbon` para datas operacionais; timestamps de extração são guardados em UTC. |
| Dados em falta | Nunca equivalem a Verde ou ausência de risco. São apresentados como `Sem dados`, `Sem previsão`, `Fora de época` ou erro de extração. |
| Atualização | Fontes externas às 09:30 e 15:30; boletins às 10:00 e 16:00, hora de Lisboa. |
| Redundância | A falha de uma fonte não interrompe as restantes. O estado fica em `pipeline_source_status*.csv`. |
| Horizonte | Só é descrito quando existem datas consecutivas que suportem a interpretação. Não se infere duração para além dos dados. |
| Nível local | É apoio à decisão. Não substitui avisos oficiais nem a ativação formal do Plano da ULSM. |
| Recomendações | São consolidadas por audiência: comunicação geral, grupos vulneráveis e estabelecimentos/equipamentos. |
| Privacidade | O repositório não deve conter dados pessoais, clínicos individuais ou informação operacional sensível. |
| Proveniência | Cada ficheiro conserva a fonte, o timestamp de recolha e, quando disponível, o timestamp da própria fonte. |

## Indicadores operacionais automatizados

### AIR-QUALAR - Qualidade do ar

| Campo | Metainformação |
|---|---|
| Estado | Operacional automatizado |
| Finalidade | Identificar risco diário por poluentes e apoiar recomendações de redução da exposição. |
| Fonte primária | API da aplicação QualAr/APA. |
| Geografia | Coordenadas de Matosinhos; a fonte pode identificar a previsão como CAMS ou outra origem indicada no registo. |
| Frequência da fonte | Dependente da atualização QualAr; recolha local duas vezes por dia. |
| Horizonte | Hoje e amanhã quando disponibilizados. |
| Variáveis | NO2, O3, PM10 e PM2.5, em µg/m³. |
| Limiar O3 | Verde 0-99; Amarelo 100-179; Laranja 180-239; Vermelho >=240. |
| Limiar NO2 | Verde 0-139; Amarelo 140-199; Laranja 200-399; Vermelho >=400. |
| Limiar PM10 | Verde 0-34; Amarelo 35-49; Laranja 50-119; Vermelho >=120. |
| Limiar PM2.5 | Verde 0-14; Amarelo 15-24; Laranja 25-49; Vermelho >=50. |
| Agregação | Nível global igual ao nível mais elevado entre os poluentes com valor. |
| Ficheiro | `qualar_matosinhos.csv`. |
| Chave | Local, latitude, longitude e data prevista. |
| Dados em falta | Poluente sem valor não é classificado; se todos faltarem, o nível fica sem dados. |
| Limitações | Previsão modelada; não equivale a medição local nem deve repetir automaticamente os valores de hoje para amanhã. |
| Papel na decisão | Pode contribuir para o nível de apoio à decisão e para preparação futura. |
| Implementação | `fetch_qualar.R`; resumo em `report_summary.R`. |

### TEMP-DSP - Temperatura DSP máxima e mínima

| Campo | Metainformação |
|---|---|
| Estado | Operacional automatizado |
| Finalidade | Reproduzir os dois sinais DSP fornecidos pela ULSM para temperatura máxima e mínima persistentes. |
| Fonte | Observações IPMA partilhadas; previsões IPMA e Open-Meteo avaliadas separadamente. |
| Geografia | Concelho de Matosinhos; previsão `globalIdLocal=1130800`. |
| Época de aplicação | Maio a outubro. |
| Regra sazonal | Julho a outubro usa os limiares de verão; maio e junho usam os restantes limiares. |
| Máxima, julho ou posterior | Amarelo: D, D+1 e D-1 >=33 ºC. Vermelho: D, D+1 e D-1/D-2/D-3 >=35 ºC. |
| Máxima, antes de julho | Amarelo: D, D+1 e D-1 >=32 ºC. Vermelho: D, D+1 e D-1/D-2/D-3 >=34 ºC. |
| Mínima, julho ou posterior | Amarelo: D, D+1 e D-1/D-2 >=22 ºC. Vermelho: D, D+1 e D-1/D-2 >=25 ºC. |
| Mínima, antes de julho | Amarelo: D, D+1 e D-1/D-2 >=21 ºC. Vermelho: D, D+1 e D-1/D-2 >=24 ºC. |
| Agregação | Nível global igual ao mais elevado entre máxima e mínima. |
| Ficheiros | `data/ipma_matosinhos_temperature_alerts.csv` e `data/ipma_matosinhos_temperature_alert_latest.csv`. |
| Dados em falta | Se faltar um valor obrigatório, a respetiva regra fica `Sem dados`; fora de maio-outubro fica `Fora de época`. |
| Limitações | Regra técnica local; depende da qualidade dos observados recentes e da revisão das previsões. O Open-Meteo é complementar e não constitui aviso oficial. |
| Papel na decisão | O resultado IPMA mantém-se oficial; qualquer resultado mais exigente do Open-Meteo funciona como pré-alerta técnico. |
| Implementação | Cálculo IPMA em `fetch_ipma.R`; comparação no boletim em `temperature_source_comparison.R` e `report_summary.R`. |

### TEMP-TROPICAL - Noites tropicais

| Campo | Metainformação |
|---|---|
| Estado | Complementar automatizado |
| Finalidade | Detetar ausência de arrefecimento noturno e sequências observadas/previstas. |
| Fonte | Observações IPMA; previsões IPMA e Open-Meteo mantidas separadas. |
| Definição | Noite tropical quando a temperatura mínima diária é igual ou superior a 20 ºC. |
| Unidade | ºC. |
| Horizonte | Histórico observado disponível e horizonte comum das últimas previsões IPMA/Open-Meteo no quadro comparado. |
| Sequência | Dias consecutivos com `Tmin >=20 ºC`; o ficheiro discrimina noites observadas e previstas. |
| Classificação | Sem sinal: abaixo de 20 ºC. Vigilância: pelo menos uma noite tropical. Sem dados: Tmin ausente. |
| Ficheiros | `data/ipma_matosinhos_tropical_nights_observed.csv`, `data/ipma_matosinhos_tropical_nights_forecasts.csv` e `data/ipma_matosinhos_tropical_nights_latest.csv`. |
| Chaves | Observado: data. Previsão: atualização IPMA e data-alvo. |
| Dados em falta | Uma fonte não preenche a outra; não se infere continuidade através de datas em falta. |
| Limitações | O plano local reconhece noites tropicais como risco, mas não define um limiar autónomo de ativação por número de noites. |
| Papel na decisão | Produz sinal e recomendações, mas não sobe isoladamente o nível operacional sugerido. |
| Implementação | Base IPMA em `derive_tropical_nights.R`; comparação no boletim em `temperature_source_comparison.R` e `report_summary.R`. |

### TEMP-HEATWAVE - Onda de calor

| Campo | Metainformação |
|---|---|
| Estado | Operacional automatizado |
| Finalidade | Detetar uma onda de calor climatológica e antecipar sequências próximas do critério. |
| Fonte | Tmax observada IPMA; previsões IPMA/Open-Meteo separadas; normal climatológica IPMA 1991-2020 de Porto/Pedras Rubras. |
| Definição formal | Pelo menos seis dias consecutivos com Tmax diária superior em 5 ºC à normal mensal. |
| Sinal preventivo | Cinco dias consecutivos acima do limiar; não é uma onda de calor formal. |
| Estado | Sem critério; sinal preventivo de 5 dias; possível onda de calor; onda de calor; sem dados. |
| Ficheiros | `data/ipma_matosinhos_heat_waves.csv` e `data/ipma_matosinhos_heat_waves_latest.csv`. |
| Dados em falta | A sequência só é formada por datas consecutivas com valor. |
| Limitações | A normal mensal produz transições em degrau e usa Porto/Pedras Rubras como referência local. O Open-Meteo não substitui a definição ou os avisos IPMA. |
| Papel na decisão | Sinal preventivo e operacional de calor persistente. |
| Implementação | Base IPMA em `fetch_ipma.R`; comparação no boletim em `temperature_source_comparison.R` e `report_summary.R`. |

### TEMP-UTCI - Stress térmico UTCI

| Campo | Metainformação |
|---|---|
| Estado | Operacional automatizado quando o campo IPMA está preenchido |
| Finalidade | Avaliar a carga térmica combinada sentida pelo organismo. |
| Fonte | Campo `utci` da previsão agregada IPMA. |
| Geografia | Matosinhos, `globalIdLocal=1130800`. |
| Resolução | Horária; o boletim usa o nível mais exigente de cada dia. |
| Classes | Sem stress; stress ligeiro/moderado/elevado/muito elevado/extremo por frio ou calor, segundo a escala UTCI. |
| Ficheiros | `data/ipma_matosinhos_thermal_stress.csv` e `data/ipma_matosinhos_thermal_stress_latest.csv`. |
| Dados em falta | Horas sem UTCI são excluídas; ausência diária fica `Sem dados`. |
| Limitações | É previsão bioclimática exterior e não mede temperatura interior nem exposição individual. |
| Papel na decisão | Contribui para medidas de exposição ao calor/frio e preparação futura. |
| Implementação | `fetch_ipma.R`. |

### UV-IPMA - Índice ultravioleta

| Campo | Metainformação |
|---|---|
| Estado | Operacional automatizado |
| Finalidade | Definir a intensidade necessária de fotoproteção. |
| Fonte | IPMA, preferencialmente Matosinhos; Porto apenas como proxy explicitamente identificado se necessário. |
| Horizonte | Todas as datas do último snapshot que tenham `iUv` preenchido. |
| Classes | Baixo <3; Moderado 3-<6; Alto 6-<8; Muito Alto 8-<11; Extremo >=11. |
| Unidade | Índice sem unidade. |
| Ficheiros | `data/ipma_matosinhos_uv_index.csv` e `data/ipma_matosinhos_uv_index_latest.csv`. |
| Dados em falta | Não se replica o último valor para datas sem previsão. |
| Limitações | Previsão diária; exposição real depende de hora, nebulosidade, altitude, sombra, pele e comportamento. |
| Papel na decisão | Recomendações de proteção e adaptação de atividades exteriores. |
| Implementação | `fetch_ipma.R`. |

### HEALTH-ICARO - Índice ÍCARO

| Campo | Metainformação |
|---|---|
| Estado | Operacional automatizado na época aplicável |
| Finalidade | Estimar o efeito do calor sobre a mortalidade. |
| Fonte | SNS Transparência/INSA. |
| Geografia | Nacional; usado como contexto para Matosinhos, não como estimativa municipal. |
| Época | Maio a setembro, em dias úteis. |
| Provisionalidade | Os últimos três dias podem ser provisórios. |
| Ficheiros | `data/sns_matosinhos_temperature_health_indices.csv` e `data/sns_matosinhos_temperature_health_indices_latest.csv`. |
| Dados em falta | Fora de época é explicitado; atrasos não são convertidos em efeito nulo. |
| Limitações | Não mede mortalidade observada local e não tem granularidade ULS/concelho. |
| Papel na decisão | Contexto epidemiológico oficial de impacto do calor. |
| Implementação | `fetch_ipma.R`. |

### HEALTH-FRIESA - Índice FRIESA

| Campo | Metainformação |
|---|---|
| Estado | Operacional automatizado na época aplicável |
| Finalidade | Estimar risco de mortalidade associado ao frio extremo. |
| Fonte | SNS Transparência/INSA. |
| Geografia | Distrito do Porto; população geral e 65+ anos. |
| Época | Novembro a março, em dias úteis. |
| Provisionalidade | Os últimos nove dias podem ser provisórios. |
| Ficheiros | Partilhados com ÍCARO em `data/sns_matosinhos_temperature_health_indices*.csv`. |
| Dados em falta | Fora de época é explicitado; não se atribuem classes que a fonte pública não documente. |
| Limitações | A API disponibiliza o índice, mas não todos os limiares operacionais de alerta. |
| Papel na decisão | Contexto distrital de impacto do frio. |
| Implementação | `fetch_ipma.R`. |

### BUILDING-CLIMATE - Clima Extremo em edifícios

| Campo | Metainformação |
|---|---|
| Estado | Operacional automatizado como sinal complementar |
| Finalidade | Identificar risco térmico em edifícios e vulnerabilidade estrutural/local. |
| Fonte | API pública do painel CLIMA EXTREMO. |
| Geografia | Registo municipal `matosinhos`. |
| Variáveis | Índice de risco, temperatura interior, temperatura exterior e vulnerabilidade. |
| Classes | Baixo, Médio, Alto e Extremo, conforme metadados do painel. |
| Ficheiros | `data/clima_extremo_matosinhos_risk.csv` e `data/clima_extremo_matosinhos_risk_latest.csv`. |
| Timestamp | A API não fornece atualização; é guardada a hora de recolha. |
| Dados em falta | Valores fora da escala são assinalados, não classificados. Pode usar cache, mantendo a falha visível. |
| Limitações | Sinal modelado; não mede diretamente cada edifício ou equipamento da ULSM. |
| Papel na decisão | Apoio à preparação de edifícios e proteção de pessoas vulneráveis. |
| Implementação | `fetch_ipma.R`. |

### WEATHER-WARNINGS - Avisos meteorológicos

| Campo | Metainformação |
|---|---|
| Estado | Operacional automatizado |
| Finalidade | Incorporar avisos oficiais para fenómenos meteorológicos adversos. |
| Fonte | IPMA `warnings_www.json`. |
| Geografia | Área de aviso do Porto (`PTO`), não exclusivamente Matosinhos. |
| Variáveis | Fenómeno, nível, início, fim e descrição. |
| Classes | Verde, Amarelo, Laranja e Vermelho. |
| Ficheiros | `data/ipma_matosinhos_alerts.csv` e `data/ipma_matosinhos_alerts_latest.csv`. |
| Dados em falta | Ausência da fonte é `Sem dados`; um registo Verde explícito é distinguido de falha. |
| Limitações | Escala distrital; condições locais podem diferir. |
| Papel na decisão | Aviso oficial com preparação e recomendações por fenómeno. |
| Implementação | `fetch_ipma.R`. |

### FIRE-RISK - Perigo de incêndio rural

| Campo | Metainformação |
|---|---|
| Estado | Operacional automatizado |
| Finalidade | Antecipar restrições e medidas de prevenção de incêndio rural. |
| Fonte | IPMA, RCM diário. |
| Geografia | Concelho de Matosinhos (`DICO=1308`). |
| Horizonte | D0 e D1 disponibilizados pelo endpoint usado. |
| Classes | Reduzido, Moderado, Elevado, Muito Elevado e Máximo, conforme IPMA. |
| Ficheiros | Integrado em `data/ipma_matosinhos_alerts*.csv`. |
| Dados em falta | Não se prolonga um risco para datas sem previsão. |
| Limitações | Perigo meteorológico, não ocorrência ativa de incêndio. |
| Papel na decisão | Preparação de atividades exteriores e cumprimento de restrições legais. |
| Implementação | `fetch_ipma.R`. |

### WATER-BATHING - Águas balneares

| Campo | Metainformação |
|---|---|
| Estado | Operacional automatizado |
| Finalidade | Identificar praias/águas balneares com banho desaconselhado ou interdito. |
| Fonte | APA/SNIAmb, camada ArcGIS oficial `Praia` e ligações InfoÁgua/SNIRH. |
| Geografia | Todas as praias cujo campo `concelho` é Matosinhos. |
| Resolução | Praia e água balnear; várias praias podem corresponder à mesma água balnear. |
| Frequência | Estado corrente consultado duas vezes por dia; arquivo consolidado num snapshot por praia e dia. |
| Época | Datas oficiais de início e fim devolvidas por praia. |
| Estado corrente | Campo `qualidade_agua_balnear_dsc` e motivo de desaconselhamento/interdição. |
| Classificação operacional | Sem restrição 0; desaconselhamento/restrição 2; interdição 3; sem dados -1. |
| Autoridade | Desaconselhamento pela APA; interdição pela Autoridade de Saúde. |
| Ficheiros | `data/apa_matosinhos_bathing_water.csv` e `data/apa_matosinhos_bathing_water_latest.csv`. |
| Chave | Data do snapshot e código da praia. |
| Timestamp | A camada não expõe hora própria de atualização; `source_updated_at` é a hora de recolha e `source_timestamp_available=FALSE`. |
| Campos auxiliares | Código/nome da praia e água, época, estado, motivo, coordenadas, vigilância, posto de socorros, acessibilidade, bandeira azul, obras, risco de derrocada e ligações oficiais. |
| Dados em falta | Estado ausente fica `Sem dados`; fora da época não se infere monitorização ativa. |
| Limitações | A classificação anual não é o mesmo que o estado corrente. O fim de uma restrição só é assumido quando o estado oficial é atualizado. |
| Papel na decisão | Medidas imediatas para comunicação, grupos vulneráveis e atividades aquáticas organizadas. |
| Implementação | `fetch_bathing_water.R`; resumo em `report_summary.R`. |

## Dados meteorológicos de base

### DATA-IPMA-OBS - Temperaturas observadas

- **Estado:** base automatizada.
- **Fonte:** séries IPMA por concelho para Tmin/Tmax.
- **Fallback:** média dos extremos diários das estações Pedras Rubras e S. Gens quando a série municipal recente ainda não cobre a data.
- **Transparência no boletim:** os extremos e a contagem de horas de cada estação são mostrados separadamente nos dias usados pela regra DSP.
- **Decisão pendente:** não se escolhe automaticamente o maior extremo no verão ou o menor no inverno; essa regra criaria uma série sazonal artificial. A eventual adoção de S. Gens como referência principal e Pedras Rubras como redundância exige primeiro avaliar cobertura, continuidade e diferenças sistemáticas.
- **Média diária:** estimada por `(Tmin + Tmax) / 2`.
- **Ficheiros:** `data/ipma_matosinhos_temperaturas.csv`, `data/ipma_matosinhos_station_observations.csv` e `data/ipma_matosinhos_station_daily_temperatures.csv`.
- **Limitação:** o fallback é uma média de duas estações e fica identificado na coluna `source`.

### DATA-IPMA-FCST - Previsões meteorológicas

- **Estado:** base automatizada.
- **Fonte:** previsão agregada IPMA de Matosinhos, `globalIdLocal=1130800`.
- **Resolução:** diária e horária, conforme `idPeriodo`.
- **Arquivo:** preserva cada `source_updated_at`.
- **Ficheiros:** `data/ipma_matosinhos_forecasts.csv` e `data/ipma_matosinhos_forecast_latest.csv`.
- **Uso:** DSP, noites tropicais, onda de calor, UTCI, UV e validação de erro.
- **Limitação:** os campos disponíveis e o horizonte variam entre atualizações.

## Indicadores analíticos e de validação

### QA-IPMA-ERROR - Erro das previsões IPMA

- **Estado:** analítico.
- **Finalidade:** comparar Tmin/Tmax previstas com observações, por atualização e horizonte.
- **Erro:** previsão menos observação.
- **Métricas:** viés, MAE, RMSE e percentis do erro.
- **Horizonte:** D+0 a D+9 quando disponível.
- **Referência:** observado municipal; fallback Pedras Rubras/S. Gens quando necessário e identificado.
- **Ficheiros:** `data/ipma_matosinhos_forecast_errors.csv` e `data/ipma_matosinhos_forecast_error_summary.csv`.
- **Papel no boletim:** nenhum, até ser aprovada uma regra de correção/uso operacional.

### QA-OPENMETEO - Camada independente Open-Meteo

- **Estado:** analítico, redundante e complementar no boletim.
- **Produtos:** ERA5-Land histórico, previsão corrente, Historical Forecast API e Previous Runs D+0 a D+7.
- **Finalidade:** comparar fontes, estudar viés e preservar previsões passadas.
- **Ficheiros:** `data/openmeteo_matosinhos_history_daily.csv`, `data/openmeteo_matosinhos_forecasts.csv`, `data/openmeteo_matosinhos_forecast_latest.csv`, `data/openmeteo_matosinhos_historical_forecasts.csv`, `data/openmeteo_matosinhos_previous_runs_daily.csv`, `data/openmeteo_matosinhos_forecast_errors.csv` e respetivos resumos/estado.
- **Limitação:** reanálise não equivale a observação de estação; erros são calculados contra a própria ERA5-Land para manter independência metodológica.
- **Papel no boletim:** aparece em paralelo no DSP, noites tropicais e onda de calor. Um sinal mais exigente gera pré-alerta técnico, sem substituir o IPMA nem corrigir automaticamente valores.

### QA-TEMP-COMPARISON - Comparação pareada IPMA/Open-Meteo

- **Estado:** analítico automatizado; não entra no boletim operacional.
- **Finalidade:** medir, numa amostra comum, o viés e a qualidade relativa das previsões IPMA e Open-Meteo.
- **Unidade de comparação:** mesmo ciclo de recolha (`morning`/`afternoon`), data válida, horizonte e referência observada.
- **Horizonte:** todos os horizontes simultaneamente disponíveis nas duas fontes.
- **Referência principal:** média das estações IPMA com pelo menos 20 observações horárias no dia.
- **Análises de sensibilidade:** média estrita de Pedras Rubras/S. Gens quando ambas estão completas, cada estação isolada, grelha municipal IPMA e fallback operacional incluindo dias incompletos.
- **Métricas:** viés com intervalo de confiança de 95%, MAE, RMSE, P90 do erro absoluto, correlação, fonte mais próxima por dia e diferença de MAE entre fontes.
- **Empate:** diferenças até 0,05 ºC entre os erros absolutos das fontes são classificadas como empate.
- **Tamanho da amostra:** `insufficient` para `n<10`, `limited` para `10-29`, `preliminary` para `30-59` e `more_stable` para `n>=60`.
- **Estratificação:** por ciclo/horizonte, mês da data prevista e patamar da temperatura máxima observada (`<25`, `25-29,9`, `>=30 ºC`).
- **Ficheiros:** `data/temperature_observation_references.csv`, `data/temperature_forecast_comparison_paired.csv` e `data/temperature_forecast_comparison_summary.csv`.
- **Dados em falta:** só são comparadas linhas com as duas previsões e uma observação válida; não se imputam valores.
- **Limitações:** a cobertura observada recente é curta e desigual entre estações; a localização das estações e o ponto/grelha de cada previsão não são equivalentes; a recolha Open-Meteo não expõe aqui a hora exata da corrida do modelo.
- **Regra de utilização:** não aplicar correções automáticas antes de existir amostra suficiente, estabilidade sazonal e validação fora da amostra.
- **Implementação:** `evaluate_temperature_forecasts.R`; teste em `tests/test_temperature_forecast_comparison.R`.

### CLIMATE-PERCENTILES - Percentis térmicos ERA5-Land

- **Estado:** analítico, integração operacional pendente.
- **Base:** ERA5-Land 1991-2020 no ponto de grelha mais próximo de Matosinhos.
- **Curva:** percentis diários suavizados com janela móvel de 31 dias.
- **Percentis altos disponíveis:** P90, P95 e P98 para Tmin/Tmax.
- **Ficheiros:** `data/era5_matosinhos_daily_temperature_1991_2020.csv`, `data/era5_matosinhos_temperature_percentiles.csv` e ficheiros de alertas.
- **Extração:** workflow manual, pesado, dependente de credenciais Copernicus/CDS.
- **Limitação:** reanálise num ponto de grelha e não observação municipal.
- **Papel no boletim:** ainda nenhum; requer validação dos limiares e disponibilidade efetiva do baseline.

### QA-PIPELINE - Qualidade e frescura das fontes

- **Estado:** operacional de qualidade, não é risco de saúde.
- **Variáveis:** fonte, fase, estado, timestamps, código de saída, mensagem, correspondência ao ciclo da manhã/tarde e cobertura horária das estações.
- **Ficheiros:** `data/pipeline_source_status.csv`, `data/pipeline_source_status_latest.csv` e `data/daily_report_signal_snapshots.csv`.
- **Regra:** uma fonte com erro não bloqueia as outras; falha do relatório devolve erro para permitir recuperação.
- **Frescura:** no boletim da manhã, a recolha deve corresponder ao ciclo iniciado às 09:30; no da tarde, ao ciclo iniciado às 15:30. Uma execução anterior fica `Desatualizada`.
- **Comparação entre edições:** guarda os sinais estruturados de cada boletim e compara apenas edições da mesma data, evitando tratar a passagem de um dia para o seguinte como mudança equivalente.
- **Uso:** linha compacta junto ao título, secção `Qualidade e atualização das fontes`, bloco `Alterações desde o boletim anterior` e prevenção de falsos Verdes.

## Indicadores dos planos pendentes de dados internos

Estes indicadores não são calculados automaticamente. Devem entrar apenas através de fonte institucional aprovada ou formulário agregado validado.

| ID | Indicador | Dados mínimos | Periodicidade desejável | Razão da indisponibilidade |
|---|---|---|---|---|
| PLAN-NATIONAL | Nível nacional DGS/DE-SNS | Nível, data/hora, período e mensagem | Sempre que alterado | O nível formal pode estar num circuito/dashboard não público. |
| SU-DEMAND | Procura do Serviço de Urgência | Episódios 24h, basal e variação percentual | Diária/intradiária | Dados da ULSM. |
| SU-WAIT | Espera urgente/muito urgente | Média por prioridade e basal | Diária/intradiária | Portal público instantâneo não substitui a métrica média definida no plano. |
| SU-BOARDING | Boarding | Métrica, numerador, denominador/basal e duração | Diária | A definição operacional do plano precisa de clarificação. |
| BED-OCCUPANCY | Ocupação de internamento | Ocupação global e Medicina | Diária | Dados internos de camas/internamento. |
| SU-CAPACITY | Capacidade física livre do SU | Estado e validação do responsável | Intradiária | Critério crítico qualitativo interno. |
| CSP-DEMAND | Procura de consulta aberta | Pedidos, vagas, variação e hora de esgotamento | Diária | Dados dos CSP/SAC; limiares horários devem ser harmonizados com o plano nacional. |
| UHD-CAPACITY | Hospitalização domiciliária | Capacidade, ocupação e constrangimentos | Diária | Dados internos. |
| OUTBREAKS | Surtos locais/SINAVE | Evento, população/instituição, início, gravidade e estado | Por evento | Informação epidemiológica potencialmente sensível. |
| RESP-LAB | Gripe, COVID-19 e VSR locais | Testes, positividade, internamentos e tendência | Semanal/diária | Dados laboratoriais/assistenciais internos. |
| STAFFING | Escalas e recursos humanos | Falhas críticas por área e turno | Diária | Informação operacional sensível. |
| STOCKS | Stocks críticos | EPI, medicamentos, fluidos e dias de cobertura | Diária/semanal | Informação logística interna. |
| BEDS | Camas adicionais/indisponíveis | Número e motivo | Diária | Informação operacional interna. |
| VACCINATION | Cobertura vacinal sazonal local | Elegíveis e vacinados por grupo | Semanal | Acesso VACINAS/ULSM; dados públicos são sobretudo nacionais. |
| VULNERABLE-LISTS | Pessoas vulneráveis acompanhadas | Apenas contagens e estado agregado | Semanal/por alerta | As listas nominais nunca devem ser publicadas no GitHub. |

## Indicadores identificados mas não iniciados

| Indicador | Fonte potencial | Estado/decisão |
|---|---|---|
| Pólenes | Rede Portuguesa de Aerobiologia, região do Porto | Não iniciado nesta fase; proxy regional e atualização semanal. |
| Atividade respiratória regional | SNS Transparência e relatório semanal DGS | Não iniciado nesta fase; útil como contexto, não substitui dados ULSM. |
| Água de consumo/abastecimento | APA, ERSAR, município e entidade gestora | Não iniciado; preferível por evento oficial. |
| Inundações/ocorrências locais | Proteção Civil Municipal/ANEPC | Não iniciado; falta endpoint oficial estável e municipal validado. |
| Ocorrências de incêndio | ANEPC/Proteção Civil | Não iniciado; o projeto só integra perigo previsto. |
| Vetores/REVIVE | DGS/INSA e vigilância local | Não iniciado; dados tendem a ser periódicos e não diários. |
| Afogamentos, queimaduras e acidentes sazonais | INEM, hospital, Proteção Civil e autoridades locais | Não iniciado; requer dados internos ou eventos validados. |
| Doença transmitida por alimentos/água | SINAVE, saúde pública e laboratório | Não iniciado; requer dados internos e proteção de informação. |

## Governação a validar

Antes de ativar automaticamente o nível formal do Plano, devem ser aprovados:

1. A definição e o período do `SU basal`.
2. A definição diária de boarding e o respetivo denominador.
3. Os limiares horários de esgotamento da consulta aberta.
4. Se dois sinais da mesma família, por exemplo DSP e noites tropicais, contam como um ou dois indicadores relevantes.
5. A implementação da desativação após 48 horas de regressão sustentada.
6. Os responsáveis por introdução, validação e correção de cada indicador interno.
7. A separação entre relatório público e relatório interno com informação operacional.
