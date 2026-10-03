-- Objetivo: Obtener una muestra reproducible de registros de taxis verdes (3.5).
-- Fuente: read_parquet('/workspace/data/raw/green/*/*.parquet').
SELECT lpep_pickup_datetime, lpep_dropoff_datetime, passenger_count, trip_distance,
       PULocationID, DOLocationID, payment_type, trip_type, fare_amount, tip_amount, total_amount,
       ehail_fee
FROM read_parquet('/workspace/data/raw/green/*/*.parquet', union_by_name = true)
USING SAMPLE reservoir(8 ROWS) REPEATABLE (42);
