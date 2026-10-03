# Resultados de `sql/03_exploracion`

Generado por `scripts/run_sql.py` el 2026-10-04 21:39.

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

Tiempo: 0.01 s · filas devueltas: 2

| taxi_type | anio | archivos | primer_mes | ultimo_mes |
|---|---|---|---|---|
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

Tiempo: 0.46 s · filas devueltas: 5

| taxi_type | anio | registros |
|---|---|---|
| green | 2026 | 337,114 |
| green | todos | 337,114 |
| yellow | 2026 | 29,703,355 |
| yellow | todos | 29,703,355 |
| TOTAL | todos | 30,040,469 |

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
| Airport_fee | 8 | 0 | 2026-01 | 2026-08 |
| ehail_fee | 0 | 8 | 2026-01 | 2026-08 |
| lpep_dropoff_datetime | 0 | 8 | 2026-01 | 2026-08 |
| lpep_pickup_datetime | 0 | 8 | 2026-01 | 2026-08 |
| tpep_dropoff_datetime | 8 | 0 | 2026-01 | 2026-08 |
| tpep_pickup_datetime | 8 | 0 | 2026-01 | 2026-08 |
| trip_type | 0 | 8 | 2026-01 | 2026-08 |
| DOLocationID | 8 | 8 | 2026-01 | 2026-08 |
| PULocationID | 8 | 8 | 2026-01 | 2026-08 |
| RatecodeID | 8 | 8 | 2026-01 | 2026-08 |
| VendorID | 8 | 8 | 2026-01 | 2026-08 |
| cbd_congestion_fee | 8 | 8 | 2026-01 | 2026-08 |
| congestion_surcharge | 8 | 8 | 2026-01 | 2026-08 |
| extra | 8 | 8 | 2026-01 | 2026-08 |
| fare_amount | 8 | 8 | 2026-01 | 2026-08 |
| improvement_surcharge | 8 | 8 | 2026-01 | 2026-08 |
| mta_tax | 8 | 8 | 2026-01 | 2026-08 |
| passenger_count | 8 | 8 | 2026-01 | 2026-08 |
| payment_type | 8 | 8 | 2026-01 | 2026-08 |
| store_and_fwd_flag | 8 | 8 | 2026-01 | 2026-08 |
| tip_amount | 8 | 8 | 2026-01 | 2026-08 |
| tolls_amount | 8 | 8 | 2026-01 | 2026-08 |
| total_amount | 8 | 8 | 2026-01 | 2026-08 |
| trip_distance | 8 | 8 | 2026-01 | 2026-08 |

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

Tiempo: 0.11 s · filas devueltas: 8

| tpep_pickup_datetime | tpep_dropoff_datetime | passenger_count | trip_distance | PULocationID | DOLocationID | payment_type | fare_amount | tip_amount | total_amount | congestion_surcharge | cbd_congestion_fee |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-01-01 00:24:41 | 2026-01-01 00:36:23 | 1 | 4.80 | 87 | 162 | 2 | 21.20 | 0.00 | 26.95 | 2.50 | 0.75 |
| 2026-01-01 02:08:35 | 2026-01-01 02:21:22 | 2 | 2.30 | 90 | 229 | 1 | 14.20 | 1.40 | 21.35 | 2.50 | 0.75 |
| 2026-01-01 02:01:56 | 2026-01-01 02:17:20 | 1 | 5.69 | 80 | 95 | 2 | 26.10 | 0.00 | 28.60 | 0.00 | 0.00 |
| 2026-01-01 04:36:54 | 2026-01-01 04:48:35 | 1 | 2.56 | 68 | 79 | 1 | 14.20 | 3.99 | 23.94 | 2.50 | 0.75 |
| 2026-01-01 09:37:17 | 2026-01-01 09:42:10 | 1 | 0.80 | 239 | 142 | 1 | 6.50 | 2.10 | 12.60 | 2.50 | 0.00 |
| 2026-01-01 11:29:34 | 2026-01-01 11:36:19 | 1 | 0.74 | 161 | 163 | 1 | 7.90 | 3.16 | 15.81 | 2.50 | 0.75 |
| 2026-01-01 11:42:55 | 2026-01-01 11:49:37 | 1 | 1.03 | 163 | 186 | 2 | 7.90 | 0.00 | 12.65 | 2.50 | 0.75 |
| 2026-01-01 13:36:51 | 2026-01-01 13:45:33 | 1 | 0.80 | 186 | 48 | 2 | 8.60 | 0.00 | 13.35 | 2.50 | 0.75 |

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
| 2026-01-03 17:06:05 | 2026-01-03 17:11:27 | 1 | 1.15 | 74 | 41 | 1 | 1 | 7.20 | 4.00 | 12.70 | nan |
| 2026-01-11 22:28:43 | 2026-01-11 22:32:53 | 2 | 0.00 | 74 | 42 | 1 | 1 | 5.80 | 1.66 | 9.96 | nan |
| 2026-01-13 18:36:59 | 2026-01-13 18:41:12 | 1 | 1.08 | 43 | 238 | 1 | 1 | 7.20 | 3.49 | 17.44 | nan |
| 2026-01-16 15:15:45 | 2026-01-16 15:43:34 | 1 | 9.39 | 244 | 233 | 2 | 1 | 38.00 | 0.00 | 43.00 | nan |
| 2026-01-20 15:12:55 | 2026-01-20 15:24:05 | 1 | 1.40 | 82 | 82 | 2 | 1 | 11.40 | 0.00 | 12.90 | nan |
| 2026-01-23 10:19:05 | 2026-01-23 10:37:24 | 1 | 3.02 | 74 | 238 | 1 | 1 | 18.40 | 4.53 | 27.18 | nan |
| 2026-01-24 15:40:48 | 2026-01-24 15:52:07 | 1 | 1.05 | 65 | 40 | 1 | 1 | 10.70 | 1.59 | 13.79 | nan |
| 2026-01-30 00:16:28 | 2026-01-30 00:23:47 | 1 | 1.36 | 75 | 238 | 1 | 1 | 9.30 | 1.77 | 13.57 | nan |

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

Tiempo: 0.31 s · filas devueltas: 2

| taxi_type | registros | pct_null_passenger_count | pct_null_ratecode | pct_null_store_fwd | pct_null_congestion | pct_null_payment_type | pct_null_ehail_fee | pct_null_trip_type |
|---|---|---|---|---|---|---|---|---|
| green | 337,114 | 14.47 | 14.47 | 14.47 | 14.47 | 14.47 | 100.00 | 14.47 |
| yellow | 29,703,355 | 25.98 | 25.98 | 25.98 | 25.98 | 0.00 | 100.00 | 100.00 |

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

Tiempo: 0.39 s · filas devueltas: 2

| taxi_type | registros | fuera_de_mes | pct_fuera_de_mes | pickup_minimo | pickup_maximo |
|---|---|---|---|---|---|
| green | 337,114 | 98 | 0.03 | 2008-12-31 17:35:31 | 2026-08-31 23:58:28 |
| yellow | 29,703,355 | 146 | 0.00 | 2001-01-01 09:23:58 | 2026-08-31 23:59:59 |

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

Tiempo: 0.59 s · filas devueltas: 2

| taxi_type | registros | duracion_cero_o_negativa | duracion_mayor_4h | distancia_cero | distancia_200mi_o_mas | tarifa_negativa | total_cero_o_negativo | total_1000_o_mas | propina_negativa | pasajeros_cero | pasajeros_mas_de_6 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| green | 337,114 | 234 | 1,219 | 12,212 | 69 | 999 | 1,566 | 1 | 69 | 4,527 | 99 |
| yellow | 29,703,355 | 371,683 | 8,585 | 952,231 | 704 | 157,364 | 167,093 | 54 | 883 | 91,359 | 28 |

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

Tiempo: 2.55 s · filas devueltas: 8

| column_name | min | max | avg | std | q25 | q50 | q75 | null_percentage |
|---|---|---|---|---|---|---|---|---|
| passenger_count | 0 | 9 | 1.25 | 0.65 | 1.00 | 1.00 | 1.00 | 25.98 |
| trip_distance | 0.0 | 328522.2 | 5.55 | 550.65 | 1.02 | 1.86 | 3.81 | 0.00 |
| fare_amount | -2555.2 | 7045.0 | 21.26 | 18.96 | 10.01 | 15.79 | 26.43 | 0.00 |
| tip_amount | -222.0 | 766.0 | 2.83 | 3.97 | 0.00 | 2.05 | 3.97 | 0.00 |
| tolls_amount | -129.48 | 1400.0 | 0.54 | 2.23 | 0.00 | 0.00 | 0.00 | 0.00 |
| total_amount | -2560.2 | 7053.5 | 30.07 | 22.75 | 17.38 | 23.60 | 34.63 | 0.00 |
| congestion_surcharge | -2.5 | 2.75 | 2.22 | 0.84 | 2.50 | 2.50 | 2.50 | 25.98 |
| cbd_congestion_fee | -0.75 | 0.75 | 0.54 | 0.34 | 0.00 | 0.75 | 0.75 | 0.00 |

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

Tiempo: 0.77 s · filas devueltas: 34

| columna | codigo | taxi_type | registros |
|---|---|---|---|
| RatecodeID | 1 | green | 269,152 |
| RatecodeID | (nulo) | green | 48,775 |
| RatecodeID | 5 | green | 17,739 |
| RatecodeID | 2 | green | 887 |
| RatecodeID | 4 | green | 354 |
| RatecodeID | 3 | green | 203 |
| RatecodeID | 6 | green | 2 |
| RatecodeID | 99 | green | 2 |
| RatecodeID | 1 | yellow | 20,102,072 |
| RatecodeID | (nulo) | yellow | 7,716,688 |
| RatecodeID | 99 | yellow | 769,693 |
| RatecodeID | 2 | yellow | 694,936 |
| RatecodeID | 5 | yellow | 262,614 |
| RatecodeID | 3 | yellow | 90,052 |
| RatecodeID | 4 | yellow | 67,285 |
| RatecodeID | 6 | yellow | 15 |
| VendorID | 2 | green | 273,571 |
| VendorID | 6 | green | 34,847 |
| VendorID | 1 | green | 28,696 |
| VendorID | 2 | yellow | 23,809,774 |
| VendorID | 1 | yellow | 5,467,071 |
| VendorID | 7 | yellow | 367,120 |
| VendorID | 6 | yellow | 59,390 |
| payment_type | 1 | green | 219,980 |
| payment_type | 2 | green | 65,921 |
| payment_type | (nulo) | green | 48,775 |
| payment_type | 3 | green | 1,688 |
| payment_type | 4 | green | 750 |
| payment_type | 1 | yellow | 18,941,008 |
| payment_type | 0 | yellow | 7,716,688 |
| payment_type | 2 | yellow | 2,708,031 |
| payment_type | 4 | yellow | 239,488 |
| payment_type | 3 | yellow | 98,138 |
| payment_type | 5 | yellow | 2 |

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

Tiempo: 0.16 s · filas devueltas: 29

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

Tiempo: 0.92 s · filas devueltas: 1

| taxi_type | combinaciones_repetidas | registros_sobrantes | max_repeticiones |
|---|---|---|---|
| yellow | 32,790 | 32,790 | 2 |
