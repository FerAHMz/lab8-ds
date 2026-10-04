-- Pregunta: Cambio la velocidad de los viajes dentro de Manhattan con el peaje de congestion (vigente desde enero de 2025)?
-- Objetivo: Velocidad mediana de taxis amarillos con origen y destino en Manhattan, lunes a viernes de 7 a 19 h, por mes.
-- Fuente: vista trips_clean + vista zones.
SELECT make_date(t.file_year, t.file_month, 1)                              AS mes,
       count(*)                                                             AS viajes,
       round(quantile_cont(t.trip_distance / (t.trip_minutes / 60), 0.5), 2) AS velocidad_mediana_mph,
       round(quantile_cont(t.trip_minutes, 0.5), 1)                         AS duracion_mediana_min,
       round(100.0 * avg((t.cbd_congestion_fee > 0)::INT), 1)               AS pct_con_cargo_cbd
FROM trips_clean t
JOIN zones zo ON zo.location_id = t.pu_location_id
JOIN zones zd ON zd.location_id = t.do_location_id
WHERE t.taxi_type = 'yellow'
  AND zo.borough = 'Manhattan' AND zd.borough = 'Manhattan'
  AND isodow(t.pickup_at) <= 5 AND hour(t.pickup_at) BETWEEN 7 AND 19
GROUP BY mes
ORDER BY mes;
