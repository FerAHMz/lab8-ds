-- Pregunta: Como cambiaron los indicadores principales entre 2024, 2025 y 2026 en el mismo periodo del anio?
-- Objetivo: Comparacion anual con periodo comparable (enero-agosto, los meses disponibles de 2026).
-- Fuente: vista trips_clean.
SELECT file_year AS anio, taxi_type,
       count(*)                                                       AS viajes_ene_ago,
       round(quantile_cont(total_amount, 0.5), 2)                     AS ticket_mediano_usd,
       round(quantile_cont(trip_distance, 0.5), 2)                    AS distancia_mediana_mi,
       round(100.0 * count(*) FILTER (WHERE payment_type = 2)
                   / count(*) FILTER (WHERE payment_type BETWEEN 1 AND 6), 2) AS pct_efectivo_informados,
       round(100.0 * count(*) FILTER (WHERE payment_type IS NULL OR payment_type NOT BETWEEN 1 AND 6) / count(*), 2) AS pct_pago_sin_dato,
       round(100 * quantile_cont(tip_amount / fare_amount, 0.5) FILTER (WHERE payment_type = 1), 2) AS propina_mediana_pct,
       round(avg(coalesce(cbd_congestion_fee, 0)), 3)                 AS cargo_cbd_promedio_usd
FROM trips_clean
WHERE file_month BETWEEN 1 AND 8
GROUP BY anio, taxi_type
ORDER BY taxi_type, anio;
