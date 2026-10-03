-- Pregunta: Que peso tienen los viajes a/desde aeropuertos y en que se diferencian del resto?
-- Objetivo: Comparar volumen, distancia y cobro de viajes de aeropuerto (zona JFK, LaGuardia o Newark en origen o destino).
-- Fuente: vista trips_clean + vista zones.
WITH t AS (
    SELECT tc.taxi_type, tc.trip_distance, tc.trip_minutes, tc.total_amount, tc.tip_amount,
           CASE WHEN zo.zone IN ('JFK Airport', 'LaGuardia Airport', 'Newark Airport')
                  OR zd.zone IN ('JFK Airport', 'LaGuardia Airport', 'Newark Airport')
                THEN 'aeropuerto' ELSE 'resto' END AS segmento
    FROM trips_clean tc
    LEFT JOIN zones zo ON zo.location_id = tc.pu_location_id
    LEFT JOIN zones zd ON zd.location_id = tc.do_location_id
)
SELECT taxi_type, segmento,
       count(*)                                                                 AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2) AS pct_viajes,
       round(100 * sum(total_amount) / sum(sum(total_amount)) OVER (PARTITION BY taxi_type), 2) AS pct_facturacion,
       round(quantile_cont(trip_distance, 0.5), 2)                              AS distancia_mediana_mi,
       round(quantile_cont(total_amount, 0.5), 2)                               AS total_mediano_usd
FROM t
GROUP BY taxi_type, segmento
ORDER BY taxi_type, segmento;
