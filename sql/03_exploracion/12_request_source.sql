-- Objetivo: Explorar la columna request_source, que aparece solo en los archivos mas recientes (3.3 / 3.6).
-- Fuente: read_parquet('/workspace/data/raw/*/*/*.parquet').
-- Nota: HV0003 y HV0005 son licencias de plataformas de alto volumen (HVFHS); A/CC/EHxxxx son otros canales de solicitud.
SELECT regexp_extract(filename, '\d{4}-\d{2}') AS periodo,
       split_part(filename, '/', 5)            AS taxi_type,
       coalesce(request_source, '(nulo)')      AS request_source,
       count(*)                                AS registros
FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true)
WHERE regexp_extract(filename, '\d{4}-\d{2}') >= '2026-05'
GROUP BY ALL
ORDER BY periodo, taxi_type, registros DESC;
