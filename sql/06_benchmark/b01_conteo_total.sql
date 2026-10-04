-- Pregunta: Cuantos viajes hay en total por tipo de taxi?
-- Objetivo: Consulta minima (conteo); en Parquet puede resolverse con la metadata de los row groups.
-- Fuente: vista trips (Parquet o tabla segun el modo del benchmark).
SELECT taxi_type, count(*) AS viajes
FROM trips
GROUP BY taxi_type
ORDER BY taxi_type;
