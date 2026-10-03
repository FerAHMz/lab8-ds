-- Objetivo: Detectar registros cuya fecha de recogida no corresponde al mes del archivo (3.6).
-- Fuente: read_parquet('/workspace/data/raw/*/*/*.parquet'); el periodo esperado se extrae del nombre del archivo.
WITH t AS (
    SELECT split_part(filename, '/', 5)                                   AS taxi_type,
           regexp_extract(filename, '\d{4}-\d{2}')                        AS periodo_archivo,
           coalesce(tpep_pickup_datetime, lpep_pickup_datetime)           AS pickup_at
    FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true)
)
SELECT taxi_type,
       count(*)                                                                  AS registros,
       count(*) FILTER (WHERE strftime(pickup_at, '%Y-%m') <> periodo_archivo)   AS fuera_de_mes,
       round(100.0 * fuera_de_mes / registros, 4)                                AS pct_fuera_de_mes,
       min(pickup_at)                                                            AS pickup_minimo,
       max(pickup_at)                                                            AS pickup_maximo
FROM t
GROUP BY 1
ORDER BY 1;
