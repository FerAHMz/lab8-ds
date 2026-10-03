-- Objetivo: Cuantificar valores imposibles o sospechosos en distancias, duraciones, montos y pasajeros (3.6).
-- Fuente: read_parquet('/workspace/data/raw/*/*/*.parquet').
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
