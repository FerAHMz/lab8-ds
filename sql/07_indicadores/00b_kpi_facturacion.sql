-- Pregunta: Cuanto se facturo en total en el periodo analizado?
-- Indicador: KPI - facturacion total (millones de USD).
-- Fuente: trips_clean
SELECT round(sum(total_amount) / 1e6, 1) AS facturacion_millones_usd
FROM trips_clean;
