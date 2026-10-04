-- Objetivo: Comparar el esquema entre anios: columnas que no existen en todos los anios descargados (5.7 / 8.3).
-- Fuente: parquet_schema('/workspace/data/raw/*/*/*.parquet').
-- Nota: version generica (antes tenia columnas fijas para 2024 y 2026); lista en que anios aparece cada columna.
WITH presencia AS (
    SELECT name AS columna, split_part(file_name, '/', 6) AS anio, count(*) AS archivos
    FROM parquet_schema('/workspace/data/raw/*/*/*.parquet')
    WHERE name <> 'schema'
    GROUP BY ALL
)
SELECT columna,
       string_agg(anio || ' (' || archivos || ')', ', ' ORDER BY anio) AS anios_con_la_columna,
       count(*)                                                       AS anios
FROM presencia
GROUP BY columna
HAVING count(*) < (SELECT count(DISTINCT split_part(file, '/', 6)) FROM glob('/workspace/data/raw/*/*/*.parquet'))
ORDER BY columna;
