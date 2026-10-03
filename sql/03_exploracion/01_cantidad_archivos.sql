-- Objetivo: Determinar cuantos archivos Parquet hay disponibles por tipo de taxi y anio (3.1).
-- Fuente: glob('/workspace/data/raw/*/*/*.parquet') - solo lista archivos, no los lee.
SELECT split_part(file, '/', 5)           AS taxi_type,
       split_part(file, '/', 6)           AS anio,
       count(*)                           AS archivos,
       min(regexp_extract(file, '\d{4}-\d{2}')) AS primer_mes,
       max(regexp_extract(file, '\d{4}-\d{2}')) AS ultimo_mes
FROM glob('/workspace/data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY anio, taxi_type;
