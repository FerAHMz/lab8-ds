-- Objetivo: Ver la distribucion (min, max, cuartiles, media, nulos) de las variables numericas clave de los taxis amarillos (3.6).
-- Fuente: read_parquet('/workspace/data/raw/yellow/*/*.parquet'); SUMMARIZE calcula todas las estadisticas en una pasada.
SELECT column_name, min, max, round(avg::DOUBLE, 2) AS avg, round(std::DOUBLE, 2) AS std,
       round(q25::DOUBLE, 2) AS q25, round(q50::DOUBLE, 2) AS q50, round(q75::DOUBLE, 2) AS q75, null_percentage
FROM (SUMMARIZE SELECT passenger_count, trip_distance, fare_amount, tip_amount,
                       tolls_amount, total_amount, congestion_surcharge, cbd_congestion_fee
                FROM read_parquet('/workspace/data/raw/yellow/*/*.parquet', union_by_name = true));
