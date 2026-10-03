-- Pregunta: Como se distribuye el total cobrado por viaje y que tan pesada es la cola de viajes caros?
-- Objetivo: Histograma del total cobrado en intervalos de 5 USD (hasta 150) por tipo de taxi.
-- Fuente: vista trips_clean.
SELECT taxi_type,
       least(floor(total_amount / 5) * 5, 150)                                   AS desde_usd,
       count(*)                                                                  AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 3)  AS pct_del_tipo
FROM trips_clean
GROUP BY taxi_type, desde_usd
ORDER BY taxi_type, desde_usd;
