-- Pregunta: En que horas y dias de la semana se concentran los viajes de cada tipo de taxi?
-- Objetivo: Patron intradiario/semanal; porcentaje de los viajes de cada tipo que cae en cada combinacion dia-hora.
-- Fuente: vista trips_clean.
SELECT taxi_type,
       isodow(pickup_at)                     AS dia_semana,   -- 1 = lunes ... 7 = domingo
       hour(pickup_at)                       AS hora,
       count(*)                              AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 3) AS pct_del_tipo
FROM trips_clean
GROUP BY taxi_type, dia_semana, hora
ORDER BY taxi_type, dia_semana, hora;
