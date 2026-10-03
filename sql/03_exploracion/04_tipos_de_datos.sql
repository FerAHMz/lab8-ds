-- Objetivo: Determinar el tipo de dato de cada columna y si cambia entre archivos (3.4).
-- Fuente: parquet_schema('/workspace/data/raw/*/*/*.parquet').
-- Nota: tipo fisico Parquet + tipo logico; los timestamps son INT64 con anotacion TIMESTAMP.
SELECT name                                     AS columna,
       string_agg(DISTINCT type, ', ')          AS tipo_fisico,
       string_agg(DISTINCT coalesce(logical_type::VARCHAR, converted_type, '-'), ', ') AS tipo_logico,
       count(DISTINCT type)                     AS tipos_distintos
FROM parquet_schema('/workspace/data/raw/*/*/*.parquet')
WHERE name <> 'schema'
GROUP BY name
ORDER BY name;
