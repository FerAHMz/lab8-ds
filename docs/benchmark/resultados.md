# Resultados del benchmark

Generado por `scripts/benchmark.py` (5 repeticiones, mediana en segundos).

## Materializacion

| escenario | registros | mb_parquet | mb_duckdb | segundos_materializar |
|---|---|---|---|---|
| 1_mes | 3,377,403 | 57.30 | 115.00 | 1.11 |
| 2026 | 30,040,469 | 495.70 | 1,008.30 | 19.54 |
| 2024+2026 | 71,870,407 | 1,171.70 | 2,368.80 | 57.46 |

## Tiempo mediano por consulta

| consulta | escenario | parquet | tabla | parquet/tabla |
|---|---|---|---|---|
| b01_conteo_total.sql | 1_mes | 0.01 | 0.00 | 3.00 |
| b01_conteo_total.sql | 2026 | 0.01 | 0.01 | 1.25 |
| b01_conteo_total.sql | 2024+2026 | 0.03 | 0.03 | 0.77 |
| b02_filtro_un_dia.sql | 1_mes | 0.06 | 0.01 | 7.36 |
| b02_filtro_un_dia.sql | 2026 | 0.06 | 0.01 | 6.96 |
| b02_filtro_un_dia.sql | 2024+2026 | 0.12 | 0.01 | 19.02 |
| 01_viajes_por_mes.sql | 1_mes | 0.09 | 0.02 | 4.68 |
| 01_viajes_por_mes.sql | 2026 | 0.26 | 0.12 | 2.21 |
| 01_viajes_por_mes.sql | 2024+2026 | 0.60 | 0.36 | 1.66 |
| 02_hora_y_dia.sql | 1_mes | 0.11 | 0.04 | 3.05 |
| 02_hora_y_dia.sql | 2026 | 0.30 | 0.27 | 1.13 |
| 02_hora_y_dia.sql | 2024+2026 | 0.77 | 0.72 | 1.08 |
| 03_caracteristicas_viaje.sql | 1_mes | 0.46 | 0.38 | 1.21 |
| 03_caracteristicas_viaje.sql | 2026 | 4.16 | 3.90 | 1.07 |
| 03_caracteristicas_viaje.sql | 2024+2026 | 10.68 | 10.22 | 1.05 |
| 06_metodo_de_pago.sql | 1_mes | 0.17 | 0.08 | 2.23 |
| 06_metodo_de_pago.sql | 2026 | 0.86 | 0.72 | 1.20 |
| 06_metodo_de_pago.sql | 2024+2026 | 2.21 | 1.80 | 1.23 |
| 08_componentes_del_cobro.sql | 1_mes | 0.13 | 0.03 | 4.79 |
| 08_componentes_del_cobro.sql | 2026 | 0.44 | 0.21 | 2.10 |
| 08_componentes_del_cobro.sql | 2024+2026 | 0.93 | 0.51 | 1.83 |
| 09_aeropuertos.sql | 1_mes | 0.25 | 0.15 | 1.65 |
| 09_aeropuertos.sql | 2026 | 1.51 | 1.30 | 1.16 |
| 09_aeropuertos.sql | 2024+2026 | 3.93 | 3.34 | 1.18 |
