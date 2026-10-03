-- Pregunta: Que tan largos (distancia, duracion) y que tan caros son los viajes tipicos de cada tipo de taxi?
-- Objetivo: Caracteristicas de los viajes con medianas y percentiles (robustos a valores extremos).
-- Fuente: vista trips_clean.
SELECT taxi_type,
       count(*)                                              AS viajes,
       round(quantile_cont(trip_distance, 0.5), 2)           AS distancia_mediana_mi,
       round(quantile_cont(trip_distance, 0.9), 2)           AS distancia_p90_mi,
       round(quantile_cont(trip_minutes, 0.5), 1)            AS duracion_mediana_min,
       round(quantile_cont(trip_minutes, 0.9), 1)            AS duracion_p90_min,
       round(quantile_cont(trip_distance / (trip_minutes / 60), 0.5), 1) AS velocidad_mediana_mph,
       round(quantile_cont(total_amount, 0.5), 2)            AS total_mediano_usd,
       round(avg(passenger_count), 2)                        AS pasajeros_promedio
FROM trips_clean
GROUP BY taxi_type
ORDER BY taxi_type;
