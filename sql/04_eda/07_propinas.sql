-- Pregunta: Cuanto dejan de propina los pasajeros que pagan con tarjeta y cambia segun la hora o el tipo de taxi?
-- Objetivo: Porcentaje de propina sobre la tarifa en pagos con tarjeta (en efectivo la propina no se registra).
-- Fuente: vista trips_clean, payment_type = 1 (tarjeta).
SELECT taxi_type,
       CASE WHEN hour(pickup_at) BETWEEN 6 AND 9   THEN '1 manana (6-9)'
            WHEN hour(pickup_at) BETWEEN 10 AND 15 THEN '2 dia (10-15)'
            WHEN hour(pickup_at) BETWEEN 16 AND 19 THEN '3 tarde (16-19)'
            WHEN hour(pickup_at) BETWEEN 20 AND 23 THEN '4 noche (20-23)'
            ELSE '5 madrugada (0-5)' END                                AS franja,
       count(*)                                                         AS viajes_tarjeta,
       round(100 * avg(tip_amount / fare_amount), 2)                    AS propina_pct_promedio,
       round(100 * quantile_cont(tip_amount / fare_amount, 0.5), 2)     AS propina_pct_mediana,
       round(100.0 * avg((tip_amount = 0)::INT), 2)                     AS pct_sin_propina
FROM trips_clean
WHERE payment_type = 1
GROUP BY taxi_type, franja
ORDER BY taxi_type, franja;
