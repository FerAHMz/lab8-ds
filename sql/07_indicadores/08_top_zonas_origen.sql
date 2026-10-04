-- Pregunta: Donde se concentra la demanda de taxis?
-- Indicador: 10 zonas con mas recogidas (ambos tipos, todo el periodo) y su % del total.
-- Visualizacion: barras horizontales.
-- Fuente: trips_clean + zones
SELECT z.zone || ' (' || z.borough || ')'                                AS zona,
       count(*)                                                          AS viajes,
       round(100.0 * count(*) / (SELECT count(*) FROM trips_clean), 2)   AS pct_del_total
FROM trips_clean t
JOIN zones z ON z.location_id = t.pu_location_id
GROUP BY zona
ORDER BY viajes DESC
LIMIT 10;
