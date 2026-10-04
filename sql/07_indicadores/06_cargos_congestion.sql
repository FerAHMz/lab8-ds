-- Pregunta: Cuanto pesan los cargos por congestion en lo que paga el pasajero?
-- Indicador: % de la facturacion de taxis amarillos que corresponde al recargo de congestion y al cargo CBD, por mes.
-- Visualizacion: area apilada.
-- Fuente: trips_clean (taxi_type = 'yellow')
SELECT make_date(file_year, file_month, 1)                                          AS mes,
       round(100 * sum(coalesce(congestion_surcharge, 0)) / sum(total_amount), 2)   AS pct_recargo_congestion,
       round(100 * sum(coalesce(cbd_congestion_fee, 0)) / sum(total_amount), 2)     AS pct_cargo_cbd
FROM trips_clean
WHERE taxi_type = 'yellow'
GROUP BY mes
ORDER BY mes;
