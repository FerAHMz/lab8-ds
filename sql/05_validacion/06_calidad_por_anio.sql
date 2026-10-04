-- Objetivo: Comprobar que las reglas de limpieza se comportan de forma similar en 2024 y 2026 (5.7).
-- Fuente: vistas trips y trips_clean.
WITH total AS (SELECT file_year, taxi_type, count(*) AS registros FROM trips GROUP BY ALL),
     limpio AS (SELECT file_year, taxi_type, count(*) AS validos FROM trips_clean GROUP BY ALL)
SELECT t.file_year AS anio, t.taxi_type, t.registros, l.validos,
       round(100.0 * (t.registros - l.validos) / t.registros, 2) AS pct_excluido
FROM total t JOIN limpio l USING (file_year, taxi_type)
ORDER BY anio, t.taxi_type;
