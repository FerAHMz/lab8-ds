-- Pregunta: Como evoluciona la cantidad de viajes mes a mes y es igual la tendencia para amarillos y verdes?
-- Objetivo: Comportamiento temporal mensual por tipo de taxi; indice relativo a enero para comparar escalas muy distintas.
-- Fuente: vista trips_clean (Parquet de data/raw/*/*).
WITH m AS (
    SELECT taxi_type, file_year AS anio, file_month AS mes, count(*) AS viajes
    FROM trips_clean
    GROUP BY taxi_type, anio, mes
)
SELECT taxi_type, anio, mes, viajes,
       round(100.0 * viajes / first(viajes) OVER (PARTITION BY taxi_type, anio ORDER BY mes), 1) AS indice_vs_enero,
       round(viajes / day(last_day(make_date(anio, mes, 1))), 0)                                AS viajes_por_dia
FROM m
ORDER BY taxi_type, anio, mes;
