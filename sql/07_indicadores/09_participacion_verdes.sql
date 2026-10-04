-- Pregunta: Que peso tienen los taxis verdes dentro del total de viajes y esta cambiando?
-- Indicador: % de los viajes de cada mes que hacen los taxis verdes.
-- Visualizacion: linea.
-- Fuente: trips_clean
SELECT make_date(file_year, file_month, 1)                                  AS mes,
       round(100.0 * count(*) FILTER (WHERE taxi_type = 'green') / count(*), 3) AS pct_verdes
FROM trips_clean
GROUP BY mes
ORDER BY mes;
