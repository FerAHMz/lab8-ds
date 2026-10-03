-- Pregunta: Que metodos de pago usan los pasajeros de cada tipo de taxi?
-- Objetivo: Participacion de cada payment_type; incluye los registros sin informacion (Flex Fare / no informado).
-- Fuente: vista trips_clean.
SELECT taxi_type,
       payment_label                                                            AS metodo_pago,
       count(*)                                                                 AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2) AS pct_del_tipo,
       round(quantile_cont(total_amount, 0.5), 2)                               AS total_mediano_usd
FROM trips_clean
GROUP BY taxi_type, metodo_pago
ORDER BY taxi_type, viajes DESC;
