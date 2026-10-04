-- Pregunta: Cuanto paga un pasajero en un viaje tipico y como cambia en el tiempo?
-- Indicador: Total cobrado mediano por viaje (USD), por mes y tipo.
-- Visualizacion: lineas.
-- Fuente: trips_clean
SELECT make_date(file_year, file_month, 1)        AS mes,
       taxi_type,
       round(quantile_cont(total_amount, 0.5), 2) AS ticket_mediano_usd
FROM trips_clean
GROUP BY mes, taxi_type
ORDER BY mes, taxi_type;
