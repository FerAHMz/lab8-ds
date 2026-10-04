-- Objetivo: Comparar el esquema de 2024 y 2026: columnas que existen en un anio y no en el otro (5.7).
-- Fuente: parquet_schema('/workspace/data/raw/*/*/*.parquet').
SELECT name                                                                        AS columna,
       count(*) FILTER (WHERE file_name LIKE '%/2024/%')                            AS archivos_2024,
       count(*) FILTER (WHERE file_name LIKE '%/2026/%')                            AS archivos_2026
FROM parquet_schema('/workspace/data/raw/*/*/*.parquet')
WHERE name <> 'schema'
GROUP BY name
HAVING archivos_2024 = 0 OR archivos_2026 = 0
ORDER BY columna;
