-- Pregunta: Como cambia la velocidad promedio de los viajes a lo largo del dia (congestion)?
-- Objetivo: Relacion entre hora del dia y velocidad mediana en dias laborales.
-- Fuente: vista trips_clean, solo lunes a viernes.
SELECT taxi_type,
       hour(pickup_at)                                                  AS hora,
       count(*)                                                         AS viajes,
       round(quantile_cont(trip_distance / (trip_minutes / 60), 0.5), 1) AS velocidad_mediana_mph,
       round(quantile_cont(trip_minutes, 0.5), 1)                       AS duracion_mediana_min
FROM trips_clean
WHERE isodow(pickup_at) <= 5
GROUP BY taxi_type, hora
ORDER BY taxi_type, hora;
