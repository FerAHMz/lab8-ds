-- Objetivo: Identificar las columnas presentes y en cuantos archivos aparece cada una (3.3); detecta cambios de esquema entre meses.
-- Fuente: parquet_schema('/workspace/data/raw/*/*/*.parquet') - lee solo el footer de cada archivo.
SELECT name                                                        AS columna,
       count(*) FILTER (WHERE file_name LIKE '%/yellow/%')         AS archivos_yellow,
       count(*) FILTER (WHERE file_name LIKE '%/green/%')          AS archivos_green,
       min(regexp_extract(file_name, '\d{4}-\d{2}'))               AS primer_mes,
       max(regexp_extract(file_name, '\d{4}-\d{2}'))               AS ultimo_mes
FROM parquet_schema('/workspace/data/raw/*/*/*.parquet')
WHERE name <> 'schema'
GROUP BY name
ORDER BY archivos_yellow + archivos_green, columna;
