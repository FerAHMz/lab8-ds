-- Pregunta: Como evoluciona la demanda de taxis mes a mes y por tipo?
-- Indicador: Viajes validos por mes y tipo de taxi.
-- Visualizacion: lineas (x = mes, series = tipo).
-- Fuente: trips_clean
SELECT make_date(file_year, file_month, 1) AS mes,
       taxi_type,
       count(*)                            AS viajes
FROM trips_clean
GROUP BY mes, taxi_type
ORDER BY mes, taxi_type;
