-- Pregunta: Quedan valores atipicos dentro de los datos ya limpios (velocidades imposibles, tarifas por milla extremas)?
-- Objetivo: Detectar outliers con la regla de Tukey (fuera de Q1 - 3*IQR / Q3 + 3*IQR) y con limites fisicos.
-- Fuente: vista trips_clean.
WITH base AS (
    SELECT taxi_type,
           trip_distance / (trip_minutes / 60) AS mph,
           fare_amount / trip_distance          AS usd_por_milla
    FROM trips_clean
), limites AS (
    SELECT taxi_type,
           quantile_cont(usd_por_milla, 0.25) AS q1,
           quantile_cont(usd_por_milla, 0.75) AS q3
    FROM base GROUP BY taxi_type
)
SELECT b.taxi_type,
       count(*)                                                                       AS viajes,
       count(*) FILTER (WHERE mph > 65)                                               AS velocidad_mayor_65mph,
       round(100.0 * count(*) FILTER (WHERE mph > 65) / count(*), 3)                  AS pct_velocidad_imposible,
       round(l.q1, 2) AS q1_usd_milla, round(l.q3, 2) AS q3_usd_milla,
       round(l.q3 + 3 * (l.q3 - l.q1), 2)                                             AS limite_sup_usd_milla,
       count(*) FILTER (WHERE usd_por_milla > l.q3 + 3 * (l.q3 - l.q1))               AS atipicos_usd_milla,
       round(100.0 * count(*) FILTER (WHERE usd_por_milla > l.q3 + 3 * (l.q3 - l.q1)) / count(*), 2) AS pct_atipicos_usd_milla
FROM base b JOIN limites l USING (taxi_type)
GROUP BY b.taxi_type, l.q1, l.q3
ORDER BY b.taxi_type;
