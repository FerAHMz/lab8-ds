-- Pregunta: Cuantos viajes validos hay en el periodo analizado?
-- Indicador: KPI - total de viajes validos (millones).
-- Fuente: trips_clean
SELECT round(count(*) / 1e6, 1) AS viajes_millones
FROM trips_clean;
