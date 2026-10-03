-- Objetivo: Detectar registros duplicados (mismo vendor, horas, zonas, distancia y total) (3.6).
-- Fuente: read_parquet('/workspace/data/raw/*/*/*.parquet').
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
