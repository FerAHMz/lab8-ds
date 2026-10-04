-- Pregunta: Se esta dejando de usar el efectivo?
-- Indicador: % de viajes pagados en efectivo, sobre los viajes con metodo de pago informado (codigos 1-6).
-- Visualizacion: lineas.
-- Fuente: trips_clean
SELECT make_date(file_year, file_month, 1) AS mes,
       taxi_type,
       round(100.0 * count(*) FILTER (WHERE payment_type = 2)
                   / count(*) FILTER (WHERE payment_type BETWEEN 1 AND 6), 2) AS pct_efectivo
FROM trips_clean
GROUP BY mes, taxi_type
ORDER BY mes, taxi_type;
