-- Objetivo: Consultar conjuntamente 2024 y 2026 con la misma consulta y periodo comparable (enero-agosto) (5.6).
-- Fuente: vista trips_clean.
SELECT taxi_type, file_year AS anio,
       count(*)                                                       AS viajes_ene_ago,
       round(quantile_cont(trip_distance, 0.5), 2)                    AS distancia_mediana_mi,
       round(quantile_cont(total_amount, 0.5), 2)                     AS total_mediano_usd,
       round(100.0 * count(*) FILTER (WHERE payment_type NOT BETWEEN 1 AND 6 OR payment_type IS NULL) / count(*), 2) AS pct_pago_sin_dato,
       round(100.0 * count(*) FILTER (WHERE payment_type = 1) / count(*) FILTER (WHERE payment_type BETWEEN 1 AND 6), 2) AS pct_tarjeta_informados,
       round(100.0 * count(*) FILTER (WHERE payment_type = 2) / count(*) FILTER (WHERE payment_type BETWEEN 1 AND 6), 2) AS pct_efectivo_informados,
       round(avg(coalesce(cbd_congestion_fee, 0)), 3)                 AS cargo_cbd_promedio
FROM trips_clean
WHERE file_month BETWEEN 1 AND 8
GROUP BY taxi_type, file_year
ORDER BY taxi_type, anio;
