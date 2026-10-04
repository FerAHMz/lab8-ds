-- Pregunta: Que tan dependientes son los taxis amarillos de los viajes de aeropuerto?
-- Indicador: % de viajes y % de facturacion de taxis amarillos con origen o destino en JFK, LaGuardia o Newark, por anio.
-- Visualizacion: barras agrupadas.
-- Fuente: trips_clean + zones
WITH t AS (
    SELECT tc.file_year, tc.total_amount,
           (zo.zone IN ('JFK Airport', 'LaGuardia Airport', 'Newark Airport')
            OR zd.zone IN ('JFK Airport', 'LaGuardia Airport', 'Newark Airport')) AS es_aeropuerto
    FROM trips_clean tc
    LEFT JOIN zones zo ON zo.location_id = tc.pu_location_id
    LEFT JOIN zones zd ON zd.location_id = tc.do_location_id
    WHERE tc.taxi_type = 'yellow'
)
SELECT file_year::VARCHAR                                                         AS anio,
       round(100.0 * count(*) FILTER (WHERE es_aeropuerto) / count(*), 2)         AS pct_viajes,
       round(100 * sum(total_amount) FILTER (WHERE es_aeropuerto) / sum(total_amount), 2) AS pct_facturacion
FROM t
GROUP BY anio
ORDER BY anio;
