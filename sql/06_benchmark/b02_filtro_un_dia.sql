-- Pregunta: Como fue la actividad hora a hora en un dia concreto?
-- Objetivo: Consulta muy selectiva (un dia de todo el periodo); mide cuanto aprovecha cada estrategia el filtrado por rango de fechas.
-- Fuente: vista trips_clean (Parquet o tabla segun el modo del benchmark).
SELECT hour(pickup_at) AS hora, taxi_type, count(*) AS viajes, round(avg(total_amount), 2) AS total_promedio
FROM trips_clean
WHERE pickup_at >= TIMESTAMP '2026-08-14' AND pickup_at < TIMESTAMP '2026-08-15'
GROUP BY ALL
ORDER BY hora, taxi_type;
