-- Objetivo: Contar registros por anio y tipo leyendo 2024 y 2026 en la misma consulta (5.6); debe coincidir con el manifiesto de descarga.
-- Fuente: vista trips (read_parquet sobre data/raw/*/*/*.parquet).
WITH conteo AS (
    SELECT file_year, taxi_type,
           count(DISTINCT filename) AS archivos,
           count(*)                 AS registros
    FROM trips
    GROUP BY ROLLUP (file_year, taxi_type)
)
SELECT coalesce(file_year::VARCHAR, 'TOTAL') AS anio,
       coalesce(taxi_type, 'ambos')          AS taxi_type,
       archivos, registros
FROM conteo
ORDER BY file_year IS NULL, file_year, taxi_type IS NULL, taxi_type;
