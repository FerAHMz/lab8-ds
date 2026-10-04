# Resultados de `sql/03_exploracion`

Generado por `scripts/run_sql.py` (no editar a mano).

## 01_cantidad_archivos.sql

- **Objetivo:** Determinar cuantos archivos Parquet hay disponibles por tipo de taxi y anio (3.1).
- **Fuente:** glob('/workspace/data/raw/*/*/*.parquet') - solo lista archivos, no los lee.

```sql
SELECT split_part(file, '/', 5)           AS taxi_type,
       split_part(file, '/', 6)           AS anio,
       count(*)                           AS archivos,
       min(regexp_extract(file, '\d{4}-\d{2}')) AS primer_mes,
       max(regexp_extract(file, '\d{4}-\d{2}')) AS ultimo_mes
FROM glob('/workspace/data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY anio, taxi_type;
```

Tiempo: 0.00 s · filas devueltas: 4

| taxi_type | anio | archivos | primer_mes | ultimo_mes |
|---|---|---|---|---|
| green | 2024 | 12 | 2024-01 | 2024-12 |
| yellow | 2024 | 12 | 2024-01 | 2024-12 |
| green | 2026 | 8 | 2026-01 | 2026-08 |
| yellow | 2026 | 8 | 2026-01 | 2026-08 |

## 02_cantidad_registros.sql

- **Objetivo:** Determinar la cantidad de registros disponibles por tipo de taxi y anio (3.2).
- **Fuente:** read_parquet('/workspace/data/raw/*/*/*.parquet') con filename=true.
- **Nota:** count(*) sobre Parquet se responde con la metadata de cada row group, sin leer columnas.

```sql
WITH conteo AS (
    SELECT split_part(filename, '/', 5) AS taxi_type,
           split_part(filename, '/', 6) AS anio,
           count(*)                     AS registros
    FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true)
    GROUP BY ROLLUP (taxi_type, anio)
)
SELECT coalesce(taxi_type, 'TOTAL') AS taxi_type,
       coalesce(anio, 'todos')      AS anio,
       registros
FROM conteo
ORDER BY taxi_type IS NULL, taxi_type, anio IS NULL, anio;
```

Tiempo: 0.91 s · filas devueltas: 7

| taxi_type | anio | registros |
|---|---|---|
| green | 2024 | 660,218 |
| green | 2026 | 337,114 |
| green | todos | 997,332 |
| yellow | 2024 | 41,169,720 |
| yellow | 2026 | 29,703,355 |
| yellow | todos | 70,873,075 |
| TOTAL | todos | 71,870,407 |

## 03_columnas.sql

- **Objetivo:** Identificar las columnas presentes y en cuantos archivos aparece cada una (3.3); detecta cambios de esquema entre meses.
- **Fuente:** parquet_schema('/workspace/data/raw/*/*/*.parquet') - lee solo el footer de cada archivo.

```sql
SELECT name                                                        AS columna,
       count(*) FILTER (WHERE file_name LIKE '%/yellow/%')         AS archivos_yellow,
       count(*) FILTER (WHERE file_name LIKE '%/green/%')          AS archivos_green,
       min(regexp_extract(file_name, '\d{4}-\d{2}'))               AS primer_mes,
       max(regexp_extract(file_name, '\d{4}-\d{2}'))               AS ultimo_mes
FROM parquet_schema('/workspace/data/raw/*/*/*.parquet')
WHERE name <> 'schema'
GROUP BY name
ORDER BY archivos_yellow + archivos_green, columna;
```

Tiempo: 0.01 s · filas devueltas: 25

| columna | archivos_yellow | archivos_green | primer_mes | ultimo_mes |
|---|---|---|---|---|
| request_source | 3 | 3 | 2026-06 | 2026-08 |
| cbd_congestion_fee | 8 | 8 | 2026-01 | 2026-08 |
| Airport_fee | 20 | 0 | 2024-01 | 2026-08 |
| ehail_fee | 0 | 20 | 2024-01 | 2026-08 |
| lpep_dropoff_datetime | 0 | 20 | 2024-01 | 2026-08 |
| lpep_pickup_datetime | 0 | 20 | 2024-01 | 2026-08 |
| tpep_dropoff_datetime | 20 | 0 | 2024-01 | 2026-08 |
| tpep_pickup_datetime | 20 | 0 | 2024-01 | 2026-08 |
| trip_type | 0 | 20 | 2024-01 | 2026-08 |
| DOLocationID | 20 | 20 | 2024-01 | 2026-08 |
| PULocationID | 20 | 20 | 2024-01 | 2026-08 |
| RatecodeID | 20 | 20 | 2024-01 | 2026-08 |
| VendorID | 20 | 20 | 2024-01 | 2026-08 |
| congestion_surcharge | 20 | 20 | 2024-01 | 2026-08 |
| extra | 20 | 20 | 2024-01 | 2026-08 |
| fare_amount | 20 | 20 | 2024-01 | 2026-08 |
| improvement_surcharge | 20 | 20 | 2024-01 | 2026-08 |
| mta_tax | 20 | 20 | 2024-01 | 2026-08 |
| passenger_count | 20 | 20 | 2024-01 | 2026-08 |
| payment_type | 20 | 20 | 2024-01 | 2026-08 |
| store_and_fwd_flag | 20 | 20 | 2024-01 | 2026-08 |
| tip_amount | 20 | 20 | 2024-01 | 2026-08 |
| tolls_amount | 20 | 20 | 2024-01 | 2026-08 |
| total_amount | 20 | 20 | 2024-01 | 2026-08 |
| trip_distance | 20 | 20 | 2024-01 | 2026-08 |

## 04_tipos_de_datos.sql

- **Objetivo:** Determinar el tipo de dato de cada columna y si cambia entre archivos (3.4).
- **Fuente:** parquet_schema('/workspace/data/raw/*/*/*.parquet').
- **Nota:** tipo fisico Parquet + tipo logico; los timestamps son INT64 con anotacion TIMESTAMP.

```sql
SELECT name                                     AS columna,
       string_agg(DISTINCT type, ', ')          AS tipo_fisico,
       string_agg(DISTINCT coalesce(logical_type::VARCHAR, converted_type, '-'), ', ') AS tipo_logico,
       count(DISTINCT type)                     AS tipos_distintos
FROM parquet_schema('/workspace/data/raw/*/*/*.parquet')
WHERE name <> 'schema'
GROUP BY name
ORDER BY name;
```

Tiempo: 0.01 s · filas devueltas: 25

| columna | tipo_fisico | tipo_logico | tipos_distintos |
|---|---|---|---|
| Airport_fee | DOUBLE | - | 1 |
| DOLocationID | INT32 | - | 1 |
| PULocationID | INT32 | - | 1 |
| RatecodeID | INT64 | - | 1 |
| VendorID | INT32 | - | 1 |
| cbd_congestion_fee | DOUBLE | - | 1 |
| congestion_surcharge | DOUBLE | - | 1 |
| ehail_fee | DOUBLE | - | 1 |
| extra | DOUBLE | - | 1 |
| fare_amount | DOUBLE | - | 1 |
| improvement_surcharge | DOUBLE | - | 1 |
| lpep_dropoff_datetime | INT64 | TimestampType(isAdjustedToUTC=0, unit=TimeUnit(MILLIS=<null>, MICROS=MicroSeconds(), NANOS=<null>)) | 1 |
| lpep_pickup_datetime | INT64 | TimestampType(isAdjustedToUTC=0, unit=TimeUnit(MILLIS=<null>, MICROS=MicroSeconds(), NANOS=<null>)) | 1 |
| mta_tax | DOUBLE | - | 1 |
| passenger_count | INT64 | - | 1 |
| payment_type | INT64 | - | 1 |
| request_source | BYTE_ARRAY | StringType() | 1 |
| store_and_fwd_flag | BYTE_ARRAY | StringType() | 1 |
| tip_amount | DOUBLE | - | 1 |
| tolls_amount | DOUBLE | - | 1 |
| total_amount | DOUBLE | - | 1 |
| tpep_dropoff_datetime | INT64 | TimestampType(isAdjustedToUTC=0, unit=TimeUnit(MILLIS=<null>, MICROS=MicroSeconds(), NANOS=<null>)) | 1 |
| tpep_pickup_datetime | INT64 | TimestampType(isAdjustedToUTC=0, unit=TimeUnit(MILLIS=<null>, MICROS=MicroSeconds(), NANOS=<null>)) | 1 |
| trip_distance | DOUBLE | - | 1 |
| trip_type | INT64 | - | 1 |

## 05_muestra_amarillos.sql

- **Objetivo:** Obtener una muestra reproducible de registros de taxis amarillos (3.5).
- **Fuente:** read_parquet('/workspace/data/raw/yellow/*/*.parquet').

```sql
SELECT tpep_pickup_datetime, tpep_dropoff_datetime, passenger_count, trip_distance,
       PULocationID, DOLocationID, payment_type, fare_amount, tip_amount, total_amount,
       congestion_surcharge, cbd_congestion_fee
FROM read_parquet('/workspace/data/raw/yellow/*/*.parquet', union_by_name = true)
USING SAMPLE reservoir(8 ROWS) REPEATABLE (42);
```

Tiempo: 0.09 s · filas devueltas: 8

| tpep_pickup_datetime | tpep_dropoff_datetime | passenger_count | trip_distance | PULocationID | DOLocationID | payment_type | fare_amount | tip_amount | total_amount | congestion_surcharge | cbd_congestion_fee |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 2024-01-01 00:21:18 | 2024-01-01 00:28:37 | 2 | 0.93 | 114 | 234 | 1 | 8.60 | 0.00 | 13.60 | 2.50 | nan |
| 2024-01-01 02:41:59 | 2024-01-01 02:56:19 | 1 | 2.30 | 90 | 233 | 1 | 14.90 | 3.00 | 22.90 | 2.50 | nan |
| 2024-01-01 02:24:26 | 2024-01-01 02:30:49 | 0 | 1.00 | 233 | 264 | 2 | 8.60 | 0.00 | 13.60 | 2.50 | nan |
| 2024-01-01 03:52:42 | 2024-01-01 04:11:32 | 1 | 5.11 | 186 | 151 | 1 | 24.70 | 5.94 | 35.64 | 2.50 | nan |
| 2024-01-01 04:26:01 | 2024-01-01 04:34:31 | 1 | 2.40 | 249 | 48 | 1 | 12.10 | 3.42 | 20.52 | 2.50 | nan |
| 2024-01-01 07:31:23 | 2024-01-01 07:46:58 | 2 | 11.70 | 132 | 138 | 1 | 44.30 | 11.45 | 59.00 | 0.00 | nan |
| 2024-01-01 09:50:41 | 2024-01-01 10:13:04 | 1 | 4.84 | 100 | 88 | 1 | 26.10 | 6.02 | 36.12 | 2.50 | nan |
| 2024-01-01 11:44:16 | 2024-01-01 11:58:40 | 6 | 6.20 | 209 | 141 | 1 | 26.10 | 6.02 | 36.12 | 2.50 | nan |

## 06_muestra_verdes.sql

- **Objetivo:** Obtener una muestra reproducible de registros de taxis verdes (3.5).
- **Fuente:** read_parquet('/workspace/data/raw/green/*/*.parquet').

```sql
SELECT lpep_pickup_datetime, lpep_dropoff_datetime, passenger_count, trip_distance,
       PULocationID, DOLocationID, payment_type, trip_type, fare_amount, tip_amount, total_amount,
       ehail_fee
FROM read_parquet('/workspace/data/raw/green/*/*.parquet', union_by_name = true)
USING SAMPLE reservoir(8 ROWS) REPEATABLE (42);
```

Tiempo: 0.02 s · filas devueltas: 8

| lpep_pickup_datetime | lpep_dropoff_datetime | passenger_count | trip_distance | PULocationID | DOLocationID | payment_type | trip_type | fare_amount | tip_amount | total_amount | ehail_fee |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 2024-01-02 19:19:54 | 2024-01-02 19:20:53 | 1 | 0.00 | 75 | 75 | 2 | 1 | 3.00 | 0.00 | 7.00 | nan |
| 2024-01-08 11:30:12 | 2024-01-08 11:31:26 | 2 | 0.10 | 166 | 166 | 1 | 2 | 70.00 | 0.00 | 70.00 | nan |
| 2024-01-09 15:34:56 | 2024-01-09 15:35:11 | 1 | 0.00 | 74 | 74 | 3 | 1 | -3.00 | 0.00 | -4.50 | nan |
| 2024-01-11 14:09:59 | 2024-01-11 14:18:57 | 1 | 0.91 | 75 | 74 | 2 | 1 | 9.30 | 0.00 | 10.80 | nan |
| 2024-01-13 18:39:53 | 2024-01-13 18:58:25 | 1 | 2.58 | 74 | 238 | 1 | 1 | 19.10 | 2.00 | 22.60 | nan |
| 2024-01-16 11:39:25 | 2024-01-16 11:49:14 | 2 | 1.54 | 74 | 166 | 1 | 1 | 10.70 | 2.44 | 14.64 | nan |
| 2024-01-17 10:07:09 | 2024-01-17 10:11:36 | 1 | 0.70 | 75 | 75 | 2 | 1 | 6.50 | 0.00 | 8.00 | nan |
| 2024-01-20 03:16:12 | 2024-01-20 03:24:26 | 2 | 1.19 | 129 | 7 | 2 | 1 | 10.00 | 0.00 | 12.50 | nan |

## 07_nulos.sql

- **Objetivo:** Medir el porcentaje de valores nulos por columna y tipo de taxi (3.6).
- **Fuente:** read_parquet('/workspace/data/raw/*/*/*.parquet') con union_by_name.

```sql
SELECT split_part(filename, '/', 5)                              AS taxi_type,
       count(*)                                                  AS registros,
       round(100 * avg((passenger_count IS NULL)::INT), 2)       AS pct_null_passenger_count,
       round(100 * avg((RatecodeID IS NULL)::INT), 2)            AS pct_null_ratecode,
       round(100 * avg((store_and_fwd_flag IS NULL)::INT), 2)    AS pct_null_store_fwd,
       round(100 * avg((congestion_surcharge IS NULL)::INT), 2)  AS pct_null_congestion,
       round(100 * avg((payment_type IS NULL)::INT), 2)          AS pct_null_payment_type,
       round(100 * avg((ehail_fee IS NULL)::INT), 2)             AS pct_null_ehail_fee,
       round(100 * avg((trip_type IS NULL)::INT), 2)             AS pct_null_trip_type
FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true)
GROUP BY 1
ORDER BY 1;
```

Tiempo: 0.60 s · filas devueltas: 2

| taxi_type | registros | pct_null_passenger_count | pct_null_ratecode | pct_null_store_fwd | pct_null_congestion | pct_null_payment_type | pct_null_ehail_fee | pct_null_trip_type |
|---|---|---|---|---|---|---|---|---|
| green | 997,332 | 7.33 | 7.33 | 7.33 | 7.33 | 7.33 | 100.00 | 7.34 |
| yellow | 70,873,075 | 16.66 | 16.66 | 16.66 | 16.66 | 0.00 | 100.00 | 100.00 |

## 08_fechas_fuera_de_rango.sql

- **Objetivo:** Detectar registros cuya fecha de recogida no corresponde al mes del archivo (3.6).
- **Fuente:** read_parquet('/workspace/data/raw/*/*/*.parquet'); el periodo esperado se extrae del nombre del archivo.

```sql
WITH t AS (
    SELECT split_part(filename, '/', 5)                                   AS taxi_type,
           regexp_extract(filename, '\d{4}-\d{2}')                        AS periodo_archivo,
           coalesce(tpep_pickup_datetime, lpep_pickup_datetime)           AS pickup_at
    FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true)
)
SELECT taxi_type,
       count(*)                                                                  AS registros,
       count(*) FILTER (WHERE strftime(pickup_at, '%Y-%m') <> periodo_archivo)   AS fuera_de_mes,
       round(100.0 * fuera_de_mes / registros, 4)                                AS pct_fuera_de_mes,
       min(pickup_at)                                                            AS pickup_minimo,
       max(pickup_at)                                                            AS pickup_maximo
FROM t
GROUP BY 1
ORDER BY 1;
```

Tiempo: 0.79 s · filas devueltas: 2

| taxi_type | registros | fuera_de_mes | pct_fuera_de_mes | pickup_minimo | pickup_maximo |
|---|---|---|---|---|---|
| green | 997,332 | 262 | 0.03 | 2008-12-31 00:00:00 | 2026-08-31 23:58:28 |
| yellow | 70,873,075 | 566 | 0.00 | 2001-01-01 09:23:58 | 2026-08-31 23:59:59 |

## 09_valores_invalidos.sql

- **Objetivo:** Cuantificar valores imposibles o sospechosos en distancias, duraciones, montos y pasajeros (3.6).
- **Fuente:** read_parquet('/workspace/data/raw/*/*/*.parquet').

```sql
WITH t AS (
    SELECT split_part(filename, '/', 5) AS taxi_type,
           date_diff('second', coalesce(tpep_pickup_datetime, lpep_pickup_datetime),
                               coalesce(tpep_dropoff_datetime, lpep_dropoff_datetime)) / 60.0 AS minutos,
           trip_distance, fare_amount, total_amount, tip_amount, passenger_count
    FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true)
)
SELECT taxi_type,
       count(*)                                                AS registros,
       count(*) FILTER (WHERE minutos <= 0)                    AS duracion_cero_o_negativa,
       count(*) FILTER (WHERE minutos > 240)                   AS duracion_mayor_4h,
       count(*) FILTER (WHERE trip_distance = 0)               AS distancia_cero,
       count(*) FILTER (WHERE trip_distance >= 200)            AS distancia_200mi_o_mas,
       count(*) FILTER (WHERE fare_amount < 0)                 AS tarifa_negativa,
       count(*) FILTER (WHERE total_amount <= 0)               AS total_cero_o_negativo,
       count(*) FILTER (WHERE total_amount >= 1000)            AS total_1000_o_mas,
       count(*) FILTER (WHERE tip_amount < 0)                  AS propina_negativa,
       count(*) FILTER (WHERE passenger_count = 0)             AS pasajeros_cero,
       count(*) FILTER (WHERE passenger_count > 6)             AS pasajeros_mas_de_6
FROM t
GROUP BY 1
ORDER BY 1;
```

Tiempo: 1.06 s · filas devueltas: 2

| taxi_type | registros | duracion_cero_o_negativa | duracion_mayor_4h | distancia_cero | distancia_200mi_o_mas | tarifa_negativa | total_cero_o_negativo | total_1000_o_mas | propina_negativa | pasajeros_cero | pasajeros_mas_de_6 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| green | 997,332 | 896 | 4,038 | 46,786 | 302 | 3,143 | 4,140 | 2 | 128 | 11,320 | 247 |
| yellow | 70,873,075 | 385,193 | 31,959 | 1,728,536 | 1,846 | 888,388 | 781,499 | 106 | 2,214 | 492,713 | 312 |

## 10_resumen_numerico.sql

- **Objetivo:** Ver la distribucion (min, max, cuartiles, media, nulos) de las variables numericas clave de los taxis amarillos (3.6).
- **Fuente:** read_parquet('/workspace/data/raw/yellow/*/*.parquet'); SUMMARIZE calcula todas las estadisticas en una pasada.

```sql
SELECT column_name, min, max, round(avg::DOUBLE, 2) AS avg, round(std::DOUBLE, 2) AS std,
       round(q25::DOUBLE, 2) AS q25, round(q50::DOUBLE, 2) AS q50, round(q75::DOUBLE, 2) AS q75, null_percentage
FROM (SUMMARIZE SELECT passenger_count, trip_distance, fare_amount, tip_amount,
                       tolls_amount, total_amount, congestion_surcharge, cbd_congestion_fee
                FROM read_parquet('/workspace/data/raw/yellow/*/*.parquet', union_by_name = true));
```

Tiempo: 5.49 s · filas devueltas: 8

| column_name | min | max | avg | std | q25 | q50 | q75 | null_percentage |
|---|---|---|---|---|---|---|---|---|
| passenger_count | 0 | 9 | 1.30 | 0.76 | 1.00 | 1.00 | 1.00 | 16.66 |
| trip_distance | 0.0 | 398608.62 | 5.22 | 478.72 | 1.02 | 1.79 | 3.54 | 0.00 |
| fare_amount | -2555.2 | 335544.44 | 20.10 | 59.76 | 9.35 | 14.56 | 24.14 | 0.00 |
| tip_amount | -300.0 | 999.99 | 3.11 | 4.05 | 0.00 | 2.43 | 4.11 | 0.00 |
| tolls_amount | -140.63 | 1702.88 | 0.55 | 2.23 | 0.00 | 0.00 | 0.00 | 0.00 |
| total_amount | -2560.2 | 335550.94 | 28.77 | 61.30 | 16.38 | 22.04 | 32.34 | 0.00 |
| congestion_surcharge | -2.5 | 2.75 | 2.23 | 0.86 | 2.50 | 2.50 | 2.50 | 16.66 |
| cbd_congestion_fee | -0.75 | 0.75 | 0.54 | 0.34 | 0.00 | 0.75 | 0.75 | 58.09 |

## 11_codigos_categoricos.sql

- **Objetivo:** Revisar si los codigos categoricos (VendorID, RatecodeID, payment_type) respetan el diccionario de datos de la TLC (3.6).
- **Fuente:** read_parquet('/workspace/data/raw/*/*/*.parquet').
- **Nota:** diccionario TLC: RatecodeID 1-6 y 99 (desconocido); payment_type 0-6; VendorID 1, 2, 6, 7.

```sql
SELECT 'VendorID' AS columna, coalesce(VendorID::VARCHAR, '(nulo)') AS codigo, split_part(filename, '/', 5) AS taxi_type, count(*) AS registros
FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true) GROUP BY ALL
UNION ALL
SELECT 'RatecodeID', coalesce(RatecodeID::VARCHAR, '(nulo)'), split_part(filename, '/', 5), count(*)
FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true) GROUP BY ALL
UNION ALL
SELECT 'payment_type', coalesce(payment_type::VARCHAR, '(nulo)'), split_part(filename, '/', 5), count(*)
FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true) GROUP BY ALL
ORDER BY columna, taxi_type, registros DESC;
```

Tiempo: 1.68 s · filas devueltas: 35

| columna | codigo | taxi_type | registros |
|---|---|---|---|
| RatecodeID | 1 | green | 871,065 |
| RatecodeID | (nulo) | green | 73,103 |
| RatecodeID | 5 | green | 48,641 |
| RatecodeID | 2 | green | 2,728 |
| RatecodeID | 4 | green | 1,085 |
| RatecodeID | 3 | green | 620 |
| RatecodeID | 99 | green | 84 |
| RatecodeID | 6 | green | 6 |
| RatecodeID | 1 | yellow | 54,753,099 |
| RatecodeID | (nulo) | yellow | 11,807,920 |
| RatecodeID | 2 | yellow | 2,101,806 |
| RatecodeID | 99 | yellow | 1,236,667 |
| RatecodeID | 5 | yellow | 584,562 |
| RatecodeID | 3 | yellow | 220,003 |
| RatecodeID | 4 | yellow | 168,927 |
| RatecodeID | 6 | yellow | 91 |
| VendorID | 2 | green | 853,339 |
| VendorID | 1 | green | 109,146 |
| VendorID | 6 | green | 34,847 |
| VendorID | 2 | yellow | 55,261,277 |
| VendorID | 1 | yellow | 15,182,989 |
| VendorID | 7 | yellow | 367,350 |
| VendorID | 6 | yellow | 61,459 |
| payment_type | 1 | green | 674,667 |
| payment_type | 2 | green | 240,934 |
| payment_type | (nulo) | green | 73,103 |
| payment_type | 3 | green | 6,288 |
| payment_type | 4 | green | 2,311 |
| payment_type | 5 | green | 29 |
| payment_type | 1 | yellow | 49,393,167 |
| payment_type | 0 | yellow | 11,807,920 |
| payment_type | 2 | yellow | 8,248,119 |
| payment_type | 4 | yellow | 1,033,982 |
| payment_type | 3 | yellow | 389,881 |
| payment_type | 5 | yellow | 6 |

## 12_request_source.sql

- **Objetivo:** Explorar la columna request_source, que aparece solo en los archivos mas recientes (3.3 / 3.6).
- **Fuente:** read_parquet('/workspace/data/raw/*/*/*.parquet').
- **Nota:** HV0003 y HV0005 son licencias de plataformas de alto volumen (HVFHS); A/CC/EHxxxx son otros canales de solicitud.

```sql
SELECT regexp_extract(filename, '\d{4}-\d{2}') AS periodo,
       split_part(filename, '/', 5)            AS taxi_type,
       coalesce(request_source, '(nulo)')      AS request_source,
       count(*)                                AS registros
FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true)
WHERE regexp_extract(filename, '\d{4}-\d{2}') >= '2026-05'
GROUP BY ALL
ORDER BY periodo, taxi_type, registros DESC;
```

Tiempo: 0.15 s · filas devueltas: 29

| periodo | taxi_type | request_source | registros |
|---|---|---|---|
| 2026-05 | green | (nulo) | 44,921 |
| 2026-05 | yellow | (nulo) | 4,090,836 |
| 2026-06 | green | (nulo) | 37,692 |
| 2026-06 | green | A | 6,471 |
| 2026-06 | yellow | (nulo) | 2,824,068 |
| 2026-06 | yellow | HV0003 | 927,698 |
| 2026-06 | yellow | A | 76,711 |
| 2026-06 | yellow | EH0004 | 8,107 |
| 2026-06 | yellow | CC | 664 |
| 2026-07 | green | (nulo) | 34,822 |
| 2026-07 | green | A | 6,428 |
| 2026-07 | green | CC | 2 |
| 2026-07 | yellow | (nulo) | 2,560,692 |
| 2026-07 | yellow | HV0003 | 739,048 |
| 2026-07 | yellow | A | 223,309 |
| 2026-07 | yellow | EH0004 | 6,409 |
| 2026-07 | yellow | CC | 642 |
| 2026-07 | yellow | EH0010 | 9 |
| 2026-08 | green | (nulo) | 34,377 |
| 2026-08 | green | A | 5,130 |
| 2026-08 | green | HV0005 | 1,179 |
| 2026-08 | green | CC | 1 |
| 2026-08 | yellow | (nulo) | 2,415,867 |
| 2026-08 | yellow | HV0003 | 628,774 |
| 2026-08 | yellow | HV0005 | 181,233 |
| 2026-08 | yellow | A | 103,753 |
| 2026-08 | yellow | EH0004 | 6,253 |
| 2026-08 | yellow | CC | 573 |
| 2026-08 | yellow | EH0010 | 263 |

## 13_duplicados.sql

- **Objetivo:** Detectar registros duplicados (mismo vendor, horas, zonas, distancia y total) (3.6).
- **Fuente:** read_parquet('/workspace/data/raw/*/*/*.parquet').

```sql
WITH t AS (
    SELECT split_part(filename, '/', 5) AS taxi_type, VendorID,
           coalesce(tpep_pickup_datetime, lpep_pickup_datetime)   AS pickup_at,
           coalesce(tpep_dropoff_datetime, lpep_dropoff_datetime) AS dropoff_at,
           PULocationID, DOLocationID, trip_distance, total_amount
    FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true)
), grupos AS (
    SELECT taxi_type, count(*) AS repeticiones
    FROM t
    GROUP BY taxi_type, VendorID, pickup_at, dropoff_at, PULocationID, DOLocationID,
             trip_distance, total_amount
    HAVING count(*) > 1
)
SELECT taxi_type,
       count(*)                    AS combinaciones_repetidas,
       sum(repeticiones - 1)::BIGINT AS registros_sobrantes,
       max(repeticiones)           AS max_repeticiones
FROM grupos
GROUP BY 1
ORDER BY 1;
```

Tiempo: 5.46 s · filas devueltas: 1

| taxi_type | combinaciones_repetidas | registros_sobrantes | max_repeticiones |
|---|---|---|---|
| yellow | 32,795 | 32,795 | 2 |
