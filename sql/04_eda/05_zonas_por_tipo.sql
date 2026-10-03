-- Pregunta: Donde recogen pasajeros los taxis amarillos y los verdes (borough de origen)?
-- Objetivo: Comparar la cobertura geografica de cada tipo; los verdes (Boro Taxis) no pueden recoger en el sur de Manhattan ni aeropuertos.
-- Fuente: vista trips_clean + vista zones (taxi_zone_lookup.csv).
SELECT t.taxi_type,
       coalesce(z.borough, 'Desconocido')                                        AS borough_origen,
       count(*)                                                                  AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY t.taxi_type), 2) AS pct_del_tipo
FROM trips_clean t
LEFT JOIN zones z ON z.location_id = t.pu_location_id
GROUP BY t.taxi_type, borough_origen
ORDER BY t.taxi_type, viajes DESC;
