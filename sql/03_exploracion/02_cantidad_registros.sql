-- Objetivo: Determinar la cantidad de registros disponibles por tipo de taxi y anio (3.2).
-- Fuente: read_parquet('/workspace/data/raw/*/*/*.parquet') con filename=true.
-- Nota: count(*) sobre Parquet se responde con la metadata de cada row group, sin leer columnas.
WITH conteo AS (
    SELECT split_part(filename, '/', 5) AS taxi_type,
           split_part(filename, '/', 6) AS anio,
           count(*)                     AS registros
    FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true)
    GROUP BY ROLLUP (taxi_type, anio)
)
SELECT coalesce(taxi_type, 'TOTAL') AS taxi_type,
       coalesce(anio, 'todos')      AS anio,
       registros
FROM conteo
ORDER BY taxi_type IS NULL, taxi_type, anio IS NULL, anio;
