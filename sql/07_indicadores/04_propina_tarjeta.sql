-- Pregunta: Que tan generosos son los pasajeros que pagan con tarjeta?
-- Indicador: Propina mediana como % de la tarifa base en pagos con tarjeta, por anio y tipo.
-- Visualizacion: barras agrupadas.
-- Fuente: trips_clean (payment_type = 1)
SELECT file_year::VARCHAR                                            AS anio,
       taxi_type,
       round(100 * quantile_cont(tip_amount / fare_amount, 0.5), 2)  AS propina_mediana_pct
FROM trips_clean
WHERE payment_type = 1
GROUP BY anio, taxi_type
ORDER BY anio, taxi_type;
