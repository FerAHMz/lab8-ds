-- Pregunta: Cuanto crecio o cayo la demanda de cada mes respecto al mismo mes del anio anterior?
-- Objetivo: Variacion interanual (YoY) de viajes por mes y tipo usando lag() sobre el anio.
-- Fuente: vista trips_clean.
WITH m AS (
    SELECT taxi_type, file_month AS mes, file_year AS anio, count(*) AS viajes
    FROM trips_clean
    GROUP BY taxi_type, mes, anio
)
SELECT taxi_type, mes, anio, viajes,
       round(100.0 * (viajes - lag(viajes) OVER w) / lag(viajes) OVER w, 1) AS var_pct_vs_anio_anterior
FROM m
WINDOW w AS (PARTITION BY taxi_type, mes ORDER BY anio)
ORDER BY taxi_type, mes, anio;
