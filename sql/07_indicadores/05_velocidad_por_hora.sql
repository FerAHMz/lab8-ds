-- Pregunta: A que hora es mas lenta la ciudad y cambio la congestion entre anios?
-- Indicador: Velocidad mediana (mph) de taxis amarillos por hora del dia, lunes a viernes, por anio.
-- Visualizacion: lineas (x = hora, series = anio).
-- Fuente: trips_clean (taxi_type = 'yellow', isodow <= 5)
SELECT hour(pickup_at)                                                   AS hora,
       file_year::VARCHAR                                                AS anio,
       round(quantile_cont(trip_distance / (trip_minutes / 60), 0.5), 2) AS velocidad_mediana_mph
FROM trips_clean
WHERE taxi_type = 'yellow' AND isodow(pickup_at) <= 5
GROUP BY hora, anio
ORDER BY hora, anio;
