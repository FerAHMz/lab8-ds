-- Objetivo: Validar que existen los 12 archivos mensuales de 2024 para cada tipo y que se conservan los de 2026 (5.5).
-- Fuente: glob('/workspace/data/raw/*/*/*.parquet').
SELECT split_part(file, '/', 6)                    AS anio,
       split_part(file, '/', 5)                    AS taxi_type,
       count(*)                                    AS archivos,
       min(regexp_extract(file, '\d{4}-\d{2}'))    AS primer_mes,
       max(regexp_extract(file, '\d{4}-\d{2}'))    AS ultimo_mes
FROM glob('/workspace/data/raw/*/*/*.parquet')
GROUP BY anio, taxi_type
ORDER BY anio, taxi_type;
