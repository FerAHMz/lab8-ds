-- Pregunta: Que tan confiable es el dato del metodo de pago?
-- Indicador: % de viajes sin metodo de pago informado (payment_type nulo o 0) por mes y tipo.
-- Visualizacion: lineas.
-- Fuente: trips_clean
SELECT make_date(file_year, file_month, 1) AS mes,
       taxi_type,
       round(100.0 * count(*) FILTER (WHERE payment_type IS NULL OR payment_type NOT BETWEEN 1 AND 6) / count(*), 2) AS pct_pago_sin_dato
FROM trips_clean
GROUP BY mes, taxi_type
ORDER BY mes, taxi_type;
