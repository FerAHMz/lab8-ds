-- Objetivo: Medir el porcentaje de valores nulos por columna y tipo de taxi (3.6).
-- Fuente: read_parquet('/workspace/data/raw/*/*/*.parquet') con union_by_name.
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
