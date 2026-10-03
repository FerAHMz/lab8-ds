-- =============================================================================
-- 00_views.sql - Capa de acceso a los datos (se ejecuta antes de cualquier
-- consulta del laboratorio).
--
-- Define VISTAS sobre los archivos Parquet: no copia datos, cada consulta lee
-- directamente data/raw. Los patrones glob (*/*.parquet) incluyen cualquier
-- anio que exista en disco, por lo que incorporar 2024 o 2025 no requiere
-- modificar estas vistas ni las consultas que las usan.
--
-- Rutas: /workspace/data es la carpeta data/ montada en los contenedores
-- `lab` y `metabase` (ver docker-compose.yml).
-- =============================================================================

-- Taxis amarillos tal como vienen. union_by_name=true alinea las columnas por
-- nombre: los archivos no tienen exactamente las mismas columnas (p. ej.
-- request_source aparece desde 2026-06 y cbd_congestion_fee desde 2025-01).
CREATE OR REPLACE VIEW yellow_raw AS
SELECT *
FROM read_parquet('/workspace/data/raw/yellow/*/*.parquet',
                  union_by_name = true, filename = true);

-- Taxis verdes tal como vienen.
CREATE OR REPLACE VIEW green_raw AS
SELECT *
FROM read_parquet('/workspace/data/raw/green/*/*.parquet',
                  union_by_name = true, filename = true);

-- Vista unificada amarillo + verde con nombres homogeneos.
-- Transformaciones:
--   * tpep_* (amarillo) y lpep_* (verde) -> pickup_at / dropoff_at
--   * columnas exclusivas de un tipo se rellenan con NULL en el otro
--     (airport_fee solo amarillo; ehail_fee y trip_type solo verde)
--   * file_year / file_month se extraen del nombre del archivo: es el periodo
--     al que la TLC asigno el registro (sirve para detectar fechas fuera de rango)
--   * trip_minutes = duracion del viaje en minutos
CREATE OR REPLACE VIEW trips AS
WITH unificado AS (
    SELECT 'yellow'                     AS taxi_type,
           filename,
           VendorID                     AS vendor_id,
           tpep_pickup_datetime         AS pickup_at,
           tpep_dropoff_datetime        AS dropoff_at,
           passenger_count::BIGINT      AS passenger_count,
           trip_distance,
           RatecodeID::BIGINT           AS ratecode_id,
           store_and_fwd_flag,
           PULocationID                 AS pu_location_id,
           DOLocationID                 AS do_location_id,
           payment_type::BIGINT         AS payment_type,
           fare_amount, extra, mta_tax, tip_amount, tolls_amount,
           improvement_surcharge, congestion_surcharge,
           Airport_fee                  AS airport_fee,
           cbd_congestion_fee,
           NULL::DOUBLE                 AS ehail_fee,
           NULL::BIGINT                 AS trip_type,
           request_source,
           total_amount
    FROM yellow_raw
    UNION ALL
    SELECT 'green',
           filename,
           VendorID,
           lpep_pickup_datetime,
           lpep_dropoff_datetime,
           passenger_count::BIGINT,
           trip_distance,
           RatecodeID::BIGINT,
           store_and_fwd_flag,
           PULocationID,
           DOLocationID,
           payment_type::BIGINT,
           fare_amount, extra, mta_tax, tip_amount, tolls_amount,
           improvement_surcharge, congestion_surcharge,
           NULL::DOUBLE,
           cbd_congestion_fee,
           ehail_fee,
           trip_type::BIGINT,
           request_source,
           total_amount
    FROM green_raw
)
SELECT *,
       CAST(regexp_extract(filename, '(\d{4})-(\d{2})\.parquet$', 1) AS INTEGER) AS file_year,
       CAST(regexp_extract(filename, '(\d{4})-(\d{2})\.parquet$', 2) AS INTEGER) AS file_month,
       date_diff('second', pickup_at, dropoff_at) / 60.0                       AS trip_minutes,
       CASE payment_type
            WHEN 0 THEN 'Flex Fare'
            WHEN 1 THEN 'Tarjeta'
            WHEN 2 THEN 'Efectivo'
            WHEN 3 THEN 'Sin cargo'
            WHEN 4 THEN 'Disputa'
            WHEN 5 THEN 'Desconocido'
            WHEN 6 THEN 'Anulado'
            ELSE 'Nulo'
       END                                                                     AS payment_label
FROM unificado;

-- Vista "limpia" usada por el analisis exploratorio y los indicadores.
-- Reglas (justificadas en docs/03_exploracion.md):
--   1. la fecha de recogida pertenece al mes del archivo
--   2. duracion entre 1 y 240 minutos
--   3. distancia mayor a 0 y menor a 200 millas
--   4. tarifa base y total positivos, total menor a 1,000 USD
CREATE OR REPLACE VIEW trips_clean AS
SELECT *
FROM trips
WHERE year(pickup_at) = file_year
  AND month(pickup_at) = file_month
  AND trip_minutes BETWEEN 1 AND 240
  AND trip_distance > 0 AND trip_distance < 200
  AND fare_amount > 0
  AND total_amount > 0 AND total_amount < 1000;

-- Tabla de zonas de la TLC (LocationID -> Borough, Zone). La descarga
-- scripts/download_data.py junto con los Parquet.
CREATE OR REPLACE VIEW zones AS
SELECT LocationID AS location_id, Borough AS borough, Zone AS zone, service_zone
FROM read_csv('/workspace/data/raw/reference/taxi_zone_lookup.csv', header = true);
