-- Pregunta: Que proporcion de los viajes de taxi se solicitan a traves de plataformas de alto volumen (Uber/Lyft) desde que existe el dato?
-- Objetivo: Participacion de request_source en los meses en que la columna existe.
-- Fuente: vista trips_clean, meses con request_source informado.
SELECT taxi_type, file_year AS anio, file_month AS mes,
       count(*)                                                                    AS viajes,
       round(100.0 * count(*) FILTER (WHERE request_source = 'HV0003') / count(*), 2) AS pct_uber_hv0003,
       round(100.0 * count(*) FILTER (WHERE request_source = 'HV0005') / count(*), 2) AS pct_lyft_hv0005,
       round(100.0 * count(*) FILTER (WHERE request_source IN ('A', 'CC') OR request_source LIKE 'EH%') / count(*), 2) AS pct_otras_apps,
       round(100.0 * count(*) FILTER (WHERE request_source IS NULL) / count(*), 2)   AS pct_sin_dato
FROM trips_clean
WHERE (file_year, file_month) IN (SELECT DISTINCT (file_year, file_month) FROM trips WHERE request_source IS NOT NULL)
GROUP BY taxi_type, anio, mes
ORDER BY taxi_type, anio, mes;
