-- Objetivo: Obtener una muestra reproducible de registros de taxis amarillos (3.5).
-- Fuente: read_parquet('/workspace/data/raw/yellow/*/*.parquet').
SELECT tpep_pickup_datetime, tpep_dropoff_datetime, passenger_count, trip_distance,
       PULocationID, DOLocationID, payment_type, fare_amount, tip_amount, total_amount,
       congestion_surcharge, cbd_congestion_fee
FROM read_parquet('/workspace/data/raw/yellow/*/*.parquet', union_by_name = true)
USING SAMPLE reservoir(8 ROWS) REPEATABLE (42);
