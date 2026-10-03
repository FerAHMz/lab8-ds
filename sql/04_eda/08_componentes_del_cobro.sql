-- Pregunta: De que se compone lo que paga un pasajero (tarifa, propina, recargos, peajes, cargo de congestion)?
-- Objetivo: Participacion de cada componente en la facturacion total por tipo de taxi.
-- Fuente: vista trips_clean.
SELECT taxi_type,
       round(sum(total_amount) / 1e6, 2)                                       AS facturacion_millones_usd,
       round(100 * sum(fare_amount) / sum(total_amount), 2)                    AS pct_tarifa,
       round(100 * sum(tip_amount) / sum(total_amount), 2)                     AS pct_propina,
       round(100 * sum(tolls_amount) / sum(total_amount), 2)                   AS pct_peajes,
       round(100 * sum(coalesce(congestion_surcharge, 0)) / sum(total_amount), 2) AS pct_recargo_congestion,
       round(100 * sum(coalesce(cbd_congestion_fee, 0)) / sum(total_amount), 2)  AS pct_cargo_cbd,
       round(100 * sum(coalesce(airport_fee, 0)) / sum(total_amount), 2)         AS pct_aeropuerto,
       round(100 * sum(extra + mta_tax + improvement_surcharge) / sum(total_amount), 2) AS pct_otros
FROM trips_clean
GROUP BY taxi_type
ORDER BY taxi_type;
