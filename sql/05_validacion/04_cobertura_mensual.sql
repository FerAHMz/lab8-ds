-- Objetivo: Verificar que cada mes de 2024 tiene datos y que las fechas de recogida caen en el anio correcto (5.5).
-- Fuente: vista trips.
SELECT file_year AS anio, file_month AS mes,
       count(*) FILTER (WHERE taxi_type = 'yellow')                         AS viajes_yellow,
       count(*) FILTER (WHERE taxi_type = 'green')                          AS viajes_green,
       count(*) FILTER (WHERE year(pickup_at) <> file_year)                 AS pickup_otro_anio
FROM trips
GROUP BY file_year, file_month
ORDER BY anio, mes;
