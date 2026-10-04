-- Pregunta: Cambio la composicion de proveedores (VendorID) de los taxis a lo largo de los tres anios?
-- Objetivo: Participacion de cada VendorID por anio y tipo; ayuda a explicar cambios en la calidad del dato (pago sin informar).
-- Fuente: vista trips (sin limpiar, para no ocultar registros incompletos).
SELECT file_year AS anio, taxi_type, vendor_id,
       count(*)                                                                             AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY file_year, taxi_type), 2)  AS pct_del_anio,
       round(100.0 * avg((payment_type IS NULL OR payment_type = 0)::INT), 1)               AS pct_pago_sin_dato
FROM trips
GROUP BY anio, taxi_type, vendor_id
ORDER BY taxi_type, anio, vendor_id;
