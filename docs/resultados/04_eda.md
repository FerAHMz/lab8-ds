# Resultados de `sql/04_eda`

Generado por `scripts/run_sql.py` (no editar a mano).

## 01_viajes_por_mes.sql

- **Pregunta:** Como evoluciona la cantidad de viajes mes a mes y es igual la tendencia para amarillos y verdes?
- **Objetivo:** Comportamiento temporal mensual por tipo de taxi; indice relativo a enero para comparar escalas muy distintas.
- **Fuente:** vista trips_clean (Parquet de data/raw/*/*).

```sql
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
```

Tiempo: 0.33 s · filas devueltas: 16

| taxi_type | anio | mes | viajes | indice_vs_enero | viajes_por_dia |
|---|---|---|---|---|---|
| green | 2,026 | 1 | 37,755 | 100.00 | 1,218.00 |
| green | 2,026 | 2 | 34,829 | 92.30 | 1,244.00 |
| green | 2,026 | 3 | 41,350 | 109.50 | 1,334.00 |
| green | 2,026 | 4 | 41,279 | 109.30 | 1,376.00 |
| green | 2,026 | 5 | 42,023 | 111.30 | 1,356.00 |
| green | 2,026 | 6 | 41,231 | 109.20 | 1,374.00 |
| green | 2,026 | 7 | 38,241 | 101.30 | 1,234.00 |
| green | 2,026 | 8 | 37,754 | 100.00 | 1,218.00 |
| yellow | 2,026 | 1 | 3,504,830 | 100.00 | 113,059.00 |
| yellow | 2,026 | 2 | 3,199,918 | 91.30 | 114,283.00 |
| yellow | 2,026 | 3 | 3,749,789 | 107.00 | 120,961.00 |
| yellow | 2,026 | 4 | 3,661,836 | 104.50 | 122,061.00 |
| yellow | 2,026 | 5 | 3,898,999 | 111.20 | 125,774.00 |
| yellow | 2,026 | 6 | 3,632,801 | 103.70 | 121,093.00 |
| yellow | 2,026 | 7 | 3,333,998 | 95.10 | 107,548.00 |
| yellow | 2,026 | 8 | 3,152,409 | 89.90 | 101,691.00 |

## 02_hora_y_dia.sql

- **Pregunta:** En que horas y dias de la semana se concentran los viajes de cada tipo de taxi?
- **Objetivo:** Patron intradiario/semanal; porcentaje de los viajes de cada tipo que cae en cada combinacion dia-hora.
- **Fuente:** vista trips_clean.

```sql
SELECT taxi_type,
       isodow(pickup_at)                     AS dia_semana,   -- 1 = lunes ... 7 = domingo
       hour(pickup_at)                       AS hora,
       count(*)                              AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 3) AS pct_del_tipo
FROM trips_clean
GROUP BY taxi_type, dia_semana, hora
ORDER BY taxi_type, dia_semana, hora;
```

Tiempo: 0.33 s · filas devueltas: 336

| taxi_type | dia_semana | hora | viajes | pct_del_tipo |
|---|---|---|---|---|
| green | 1 | 0 | 466 | 0.15 |
| green | 1 | 1 | 221 | 0.07 |
| green | 1 | 2 | 130 | 0.04 |
| green | 1 | 3 | 94 | 0.03 |
| green | 1 | 4 | 168 | 0.05 |
| green | 1 | 5 | 365 | 0.12 |
| green | 1 | 6 | 1,163 | 0.37 |
| green | 1 | 7 | 2,420 | 0.77 |
| green | 1 | 8 | 3,003 | 0.95 |
| green | 1 | 9 | 2,851 | 0.91 |
| green | 1 | 10 | 2,701 | 0.86 |
| green | 1 | 11 | 2,424 | 0.77 |
| green | 1 | 12 | 2,634 | 0.84 |
| green | 1 | 13 | 2,463 | 0.78 |
| green | 1 | 14 | 2,849 | 0.91 |
| green | 1 | 15 | 3,074 | 0.98 |
| green | 1 | 16 | 3,390 | 1.08 |
| green | 1 | 17 | 3,587 | 1.14 |
| green | 1 | 18 | 3,244 | 1.03 |
| green | 1 | 19 | 2,361 | 0.75 |
| green | 1 | 20 | 1,796 | 0.57 |
| green | 1 | 21 | 1,505 | 0.48 |
| green | 1 | 22 | 1,183 | 0.38 |
| green | 1 | 23 | 736 | 0.23 |
| green | 2 | 0 | 363 | 0.12 |
| green | 2 | 1 | 193 | 0.06 |
| green | 2 | 2 | 119 | 0.04 |
| green | 2 | 3 | 76 | 0.02 |
| green | 2 | 4 | 127 | 0.04 |
| green | 2 | 5 | 335 | 0.11 |
| green | 2 | 6 | 1,158 | 0.37 |
| green | 2 | 7 | 2,525 | 0.80 |
| green | 2 | 8 | 3,213 | 1.02 |
| green | 2 | 9 | 3,167 | 1.01 |
| green | 2 | 10 | 2,873 | 0.91 |
| green | 2 | 11 | 2,650 | 0.84 |
| green | 2 | 12 | 2,746 | 0.87 |
| green | 2 | 13 | 2,756 | 0.88 |
| green | 2 | 14 | 2,966 | 0.94 |
| green | 2 | 15 | 3,286 | 1.04 |

## 03_caracteristicas_viaje.sql

- **Pregunta:** Que tan largos (distancia, duracion) y que tan caros son los viajes tipicos de cada tipo de taxi?
- **Objetivo:** Caracteristicas de los viajes con medianas y percentiles (robustos a valores extremos).
- **Fuente:** vista trips_clean.

```sql
SELECT taxi_type,
       count(*)                                              AS viajes,
       round(quantile_cont(trip_distance, 0.5), 2)           AS distancia_mediana_mi,
       round(quantile_cont(trip_distance, 0.9), 2)           AS distancia_p90_mi,
       round(quantile_cont(trip_minutes, 0.5), 1)            AS duracion_mediana_min,
       round(quantile_cont(trip_minutes, 0.9), 1)            AS duracion_p90_min,
       round(quantile_cont(trip_distance / (trip_minutes / 60), 0.5), 1) AS velocidad_mediana_mph,
       round(quantile_cont(total_amount, 0.5), 2)            AS total_mediano_usd,
       round(avg(passenger_count), 2)                        AS pasajeros_promedio
FROM trips_clean
GROUP BY taxi_type
ORDER BY taxi_type;
```

Tiempo: 4.28 s · filas devueltas: 2

| taxi_type | viajes | distancia_mediana_mi | distancia_p90_mi | duracion_mediana_min | duracion_p90_min | velocidad_mediana_mph | total_mediano_usd | pasajeros_promedio |
|---|---|---|---|---|---|---|---|---|
| green | 314,462 | 2.14 | 7.36 | 13.30 | 32.00 | 10.00 | 20.50 | 1.30 |
| yellow | 28,134,580 | 1.94 | 8.70 | 14.10 | 33.50 | 9.30 | 23.58 | 1.25 |

## 04_velocidad_por_hora.sql

- **Pregunta:** Como cambia la velocidad promedio de los viajes a lo largo del dia (congestion)?
- **Objetivo:** Relacion entre hora del dia y velocidad mediana en dias laborales.
- **Fuente:** vista trips_clean, solo lunes a viernes.

```sql
SELECT taxi_type,
       hour(pickup_at)                                                  AS hora,
       count(*)                                                         AS viajes,
       round(quantile_cont(trip_distance / (trip_minutes / 60), 0.5), 1) AS velocidad_mediana_mph,
       round(quantile_cont(trip_minutes, 0.5), 1)                       AS duracion_mediana_min
FROM trips_clean
WHERE isodow(pickup_at) <= 5
GROUP BY taxi_type, hora
ORDER BY taxi_type, hora;
```

Tiempo: 0.47 s · filas devueltas: 48

| taxi_type | hora | viajes | velocidad_mediana_mph | duracion_mediana_min |
|---|---|---|---|---|
| green | 0 | 2,469 | 12.60 | 10.90 |
| green | 1 | 1,270 | 12.60 | 10.50 |
| green | 2 | 723 | 14.40 | 11.60 |
| green | 3 | 493 | 14.70 | 11.20 |
| green | 4 | 763 | 18.40 | 16.40 |
| green | 5 | 1,787 | 16.00 | 14.90 |
| green | 6 | 5,730 | 12.60 | 10.90 |
| green | 7 | 12,289 | 10.20 | 12.80 |
| green | 8 | 15,271 | 9.10 | 14.40 |
| green | 9 | 15,092 | 9.40 | 14.30 |
| green | 10 | 13,900 | 9.70 | 14.50 |
| green | 11 | 13,069 | 9.40 | 15.10 |
| green | 12 | 13,660 | 9.50 | 15.00 |
| green | 13 | 13,410 | 9.30 | 14.60 |
| green | 14 | 15,220 | 8.70 | 15.00 |
| green | 15 | 16,713 | 8.60 | 14.40 |
| green | 16 | 18,391 | 8.90 | 13.80 |
| green | 17 | 19,465 | 9.10 | 13.30 |
| green | 18 | 17,890 | 9.50 | 12.40 |
| green | 19 | 12,966 | 10.40 | 11.40 |
| green | 20 | 9,659 | 10.70 | 11.60 |
| green | 21 | 8,545 | 11.40 | 11.90 |
| green | 22 | 7,219 | 12.10 | 12.00 |
| green | 23 | 4,830 | 12.20 | 11.80 |
| yellow | 0 | 423,626 | 13.40 | 13.80 |
| yellow | 1 | 222,458 | 14.40 | 13.10 |
| yellow | 2 | 126,418 | 14.90 | 12.80 |
| yellow | 3 | 88,086 | 15.50 | 13.40 |
| yellow | 4 | 102,252 | 16.80 | 14.70 |
| yellow | 5 | 191,284 | 15.80 | 13.50 |
| yellow | 6 | 401,718 | 13.30 | 12.80 |
| yellow | 7 | 742,356 | 10.60 | 13.20 |
| yellow | 8 | 984,543 | 8.80 | 14.60 |
| yellow | 9 | 953,204 | 8.10 | 15.00 |
| yellow | 10 | 900,595 | 7.70 | 15.40 |
| yellow | 11 | 937,421 | 7.30 | 15.90 |
| yellow | 12 | 997,975 | 7.40 | 15.60 |
| yellow | 13 | 1,034,762 | 7.60 | 15.50 |
| yellow | 14 | 1,150,519 | 7.60 | 15.70 |
| yellow | 15 | 1,208,429 | 7.40 | 15.60 |

## 05_zonas_por_tipo.sql

- **Pregunta:** Donde recogen pasajeros los taxis amarillos y los verdes (borough de origen)?
- **Objetivo:** Comparar la cobertura geografica de cada tipo; los verdes (Boro Taxis) no pueden recoger en el sur de Manhattan ni aeropuertos.
- **Fuente:** vista trips_clean + vista zones (taxi_zone_lookup.csv).

```sql
SELECT t.taxi_type,
       coalesce(z.borough, 'Desconocido')                                        AS borough_origen,
       count(*)                                                                  AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY t.taxi_type), 2) AS pct_del_tipo
FROM trips_clean t
LEFT JOIN zones z ON z.location_id = t.pu_location_id
GROUP BY t.taxi_type, borough_origen
ORDER BY t.taxi_type, viajes DESC;
```

Tiempo: 0.34 s · filas devueltas: 15

| taxi_type | borough_origen | viajes | pct_del_tipo |
|---|---|---|---|
| green | Manhattan | 189,325 | 60.21 |
| green | Queens | 68,859 | 21.90 |
| green | Brooklyn | 48,756 | 15.50 |
| green | Bronx | 7,038 | 2.24 |
| green | Unknown | 286 | 0.09 |
| green | N/A | 153 | 0.05 |
| green | Staten Island | 45 | 0.01 |
| yellow | Manhattan | 24,407,187 | 86.75 |
| yellow | Queens | 2,461,388 | 8.75 |
| yellow | Brooklyn | 1,012,402 | 3.60 |
| yellow | Bronx | 217,457 | 0.77 |
| yellow | Unknown | 29,185 | 0.10 |
| yellow | N/A | 4,266 | 0.02 |
| yellow | Staten Island | 2,528 | 0.01 |
| yellow | EWR | 167 | 0.00 |

## 06_metodo_de_pago.sql

- **Pregunta:** Que metodos de pago usan los pasajeros de cada tipo de taxi?
- **Objetivo:** Participacion de cada payment_type; incluye los registros sin informacion (Flex Fare / no informado).
- **Fuente:** vista trips_clean.

```sql
SELECT taxi_type,
       payment_label                                                            AS metodo_pago,
       count(*)                                                                 AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2) AS pct_del_tipo,
       round(quantile_cont(total_amount, 0.5), 2)                               AS total_mediano_usd
FROM trips_clean
GROUP BY taxi_type, metodo_pago
ORDER BY taxi_type, viajes DESC;
```

Tiempo: 0.81 s · filas devueltas: 10

| taxi_type | metodo_pago | viajes | pct_del_tipo | total_mediano_usd |
|---|---|---|---|---|
| green | Tarjeta | 209,572 | 66.64 | 20.94 |
| green | Efectivo | 61,562 | 19.58 | 16.10 |
| green | Nulo | 42,652 | 13.56 | 26.61 |
| green | Sin cargo | 478 | 0.15 | 12.90 |
| green | Disputa | 198 | 0.06 | 11.20 |
| yellow | Tarjeta | 18,408,818 | 65.43 | 22.35 |
| yellow | Flex Fare | 7,030,490 | 24.99 | 28.99 |
| yellow | Efectivo | 2,529,366 | 8.99 | 18.55 |
| yellow | Disputa | 112,572 | 0.40 | 18.95 |
| yellow | Sin cargo | 53,334 | 0.19 | 16.85 |

## 07_propinas.sql

- **Pregunta:** Cuanto dejan de propina los pasajeros que pagan con tarjeta y cambia segun la hora o el tipo de taxi?
- **Objetivo:** Porcentaje de propina sobre la tarifa en pagos con tarjeta (en efectivo la propina no se registra).
- **Fuente:** vista trips_clean, payment_type = 1 (tarjeta).

```sql
SELECT taxi_type,
       CASE WHEN hour(pickup_at) BETWEEN 6 AND 9   THEN '1 manana (6-9)'
            WHEN hour(pickup_at) BETWEEN 10 AND 15 THEN '2 dia (10-15)'
            WHEN hour(pickup_at) BETWEEN 16 AND 19 THEN '3 tarde (16-19)'
            WHEN hour(pickup_at) BETWEEN 20 AND 23 THEN '4 noche (20-23)'
            ELSE '5 madrugada (0-5)' END                                AS franja,
       count(*)                                                         AS viajes_tarjeta,
       round(100 * avg(tip_amount / fare_amount), 2)                    AS propina_pct_promedio,
       round(100 * quantile_cont(tip_amount / fare_amount, 0.5), 2)     AS propina_pct_mediana,
       round(100.0 * avg((tip_amount = 0)::INT), 2)                     AS pct_sin_propina
FROM trips_clean
WHERE payment_type = 1
GROUP BY taxi_type, franja
ORDER BY taxi_type, franja;
```

Tiempo: 0.48 s · filas devueltas: 10

| taxi_type | franja | viajes_tarjeta | propina_pct_promedio | propina_pct_mediana | pct_sin_propina |
|---|---|---|---|---|---|
| green | 1 manana (6-9) | 35,470 | 22.10 | 22.96 | 7.98 |
| green | 2 dia (10-15) | 68,650 | 22.57 | 23.23 | 7.43 |
| green | 3 tarde (16-19) | 64,504 | 24.07 | 25.45 | 7.64 |
| green | 4 noche (20-23) | 32,144 | 22.73 | 23.91 | 9.73 |
| green | 5 madrugada (0-5) | 8,804 | 21.35 | 22.21 | 16.03 |
| yellow | 1 manana (6-9) | 2,203,384 | 23.00 | 25.44 | 13.08 |
| yellow | 2 dia (10-15) | 6,076,623 | 24.41 | 25.70 | 9.00 |
| yellow | 3 tarde (16-19) | 5,057,498 | 26.60 | 27.85 | 7.21 |
| yellow | 4 noche (20-23) | 3,802,212 | 25.69 | 26.99 | 6.73 |
| yellow | 5 madrugada (0-5) | 1,269,101 | 24.03 | 26.24 | 13.68 |

## 08_componentes_del_cobro.sql

- **Pregunta:** De que se compone lo que paga un pasajero (tarifa, propina, recargos, peajes, cargo de congestion)?
- **Objetivo:** Participacion de cada componente en la facturacion total por tipo de taxi.
- **Fuente:** vista trips_clean.

```sql
SELECT taxi_type,
       round(sum(total_amount) / 1e6, 2)                                       AS facturacion_millones_usd,
       round(100 * sum(fare_amount) / sum(total_amount), 2)                    AS pct_tarifa,
       round(100 * sum(tip_amount) / sum(total_amount), 2)                     AS pct_propina,
       round(100 * sum(tolls_amount) / sum(total_amount), 2)                   AS pct_peajes,
       round(100 * sum(coalesce(congestion_surcharge, 0)) / sum(total_amount), 2) AS pct_recargo_congestion,
       round(100 * sum(coalesce(cbd_congestion_fee, 0)) / sum(total_amount), 2)  AS pct_cargo_cbd,
       round(100 * sum(coalesce(airport_fee, 0)) / sum(total_amount), 2)         AS pct_aeropuerto,
       round(100 * sum(extra + mta_tax + improvement_surcharge) / sum(total_amount), 2) AS pct_otros
FROM trips_clean
GROUP BY taxi_type
ORDER BY taxi_type;
```

Tiempo: 0.38 s · filas devueltas: 2

| taxi_type | facturacion_millones_usd | pct_tarifa | pct_propina | pct_peajes | pct_recargo_congestion | pct_cargo_cbd | pct_aeropuerto | pct_otros |
|---|---|---|---|---|---|---|---|---|
| green | 7.96 | 66.89 | 10.44 | 1.17 | 3.15 | 0.25 | 0.00 | 9.26 |
| yellow | 849.28 | 70.37 | 9.53 | 1.83 | 5.62 | 1.80 | 0.42 | 8.74 |

## 09_aeropuertos.sql

- **Pregunta:** Que peso tienen los viajes a/desde aeropuertos y en que se diferencian del resto?
- **Objetivo:** Comparar volumen, distancia y cobro de viajes de aeropuerto (zona JFK, LaGuardia o Newark en origen o destino).
- **Fuente:** vista trips_clean + vista zones.

```sql
WITH t AS (
    SELECT tc.taxi_type, tc.trip_distance, tc.trip_minutes, tc.total_amount, tc.tip_amount,
           CASE WHEN zo.zone IN ('JFK Airport', 'LaGuardia Airport', 'Newark Airport')
                  OR zd.zone IN ('JFK Airport', 'LaGuardia Airport', 'Newark Airport')
                THEN 'aeropuerto' ELSE 'resto' END AS segmento
    FROM trips_clean tc
    LEFT JOIN zones zo ON zo.location_id = tc.pu_location_id
    LEFT JOIN zones zd ON zd.location_id = tc.do_location_id
)
SELECT taxi_type, segmento,
       count(*)                                                                 AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2) AS pct_viajes,
       round(100 * sum(total_amount) / sum(sum(total_amount)) OVER (PARTITION BY taxi_type), 2) AS pct_facturacion,
       round(quantile_cont(trip_distance, 0.5), 2)                              AS distancia_mediana_mi,
       round(quantile_cont(total_amount, 0.5), 2)                               AS total_mediano_usd
FROM t
GROUP BY taxi_type, segmento
ORDER BY taxi_type, segmento;
```

Tiempo: 1.49 s · filas devueltas: 4

| taxi_type | segmento | viajes | pct_viajes | pct_facturacion | distancia_mediana_mi | total_mediano_usd |
|---|---|---|---|---|---|---|
| green | aeropuerto | 10,734 | 3.41 | 6.53 | 6.47 | 40.00 |
| green | resto | 303,728 | 96.59 | 93.47 | 2.07 | 20.07 |
| yellow | aeropuerto | 2,280,751 | 8.11 | 20.94 | 11.57 | 78.33 |
| yellow | resto | 25,853,829 | 91.89 | 79.06 | 1.78 | 22.45 |

## 10_distribucion_tarifa.sql

- **Pregunta:** Como se distribuye el total cobrado por viaje y que tan pesada es la cola de viajes caros?
- **Objetivo:** Histograma del total cobrado en intervalos de 5 USD (hasta 150) por tipo de taxi.
- **Fuente:** vista trips_clean.

```sql
SELECT taxi_type,
       least(floor(total_amount / 5) * 5, 150)                                   AS desde_usd,
       count(*)                                                                  AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 3)  AS pct_del_tipo
FROM trips_clean
GROUP BY taxi_type, desde_usd
ORDER BY taxi_type, desde_usd;
```

Tiempo: 0.31 s · filas devueltas: 62

| taxi_type | desde_usd | viajes | pct_del_tipo |
|---|---|---|---|
| green | 0.00 | 44 | 0.01 |
| green | 5.00 | 15,361 | 4.88 |
| green | 10.00 | 60,486 | 19.23 |
| green | 15.00 | 74,827 | 23.80 |
| green | 20.00 | 52,045 | 16.55 |
| green | 25.00 | 35,777 | 11.38 |
| green | 30.00 | 22,272 | 7.08 |
| green | 35.00 | 13,317 | 4.24 |
| green | 40.00 | 9,886 | 3.14 |
| green | 45.00 | 7,846 | 2.50 |
| green | 50.00 | 5,854 | 1.86 |
| green | 55.00 | 3,670 | 1.17 |
| green | 60.00 | 2,820 | 0.90 |
| green | 65.00 | 1,971 | 0.63 |
| green | 70.00 | 1,520 | 0.48 |
| green | 75.00 | 1,217 | 0.39 |
| green | 80.00 | 941 | 0.30 |
| green | 85.00 | 794 | 0.25 |
| green | 90.00 | 777 | 0.25 |
| green | 95.00 | 538 | 0.17 |
| green | 100.00 | 577 | 0.18 |
| green | 105.00 | 342 | 0.11 |
| green | 110.00 | 240 | 0.08 |
| green | 115.00 | 162 | 0.05 |
| green | 120.00 | 209 | 0.07 |
| green | 125.00 | 130 | 0.04 |
| green | 130.00 | 111 | 0.04 |
| green | 135.00 | 78 | 0.03 |
| green | 140.00 | 82 | 0.03 |
| green | 145.00 | 73 | 0.02 |
| green | 150.00 | 495 | 0.16 |
| yellow | 0.00 | 355 | 0.00 |
| yellow | 5.00 | 295,244 | 1.05 |
| yellow | 10.00 | 3,596,581 | 12.78 |
| yellow | 15.00 | 6,313,669 | 22.44 |
| yellow | 20.00 | 5,203,925 | 18.50 |
| yellow | 25.00 | 3,572,989 | 12.70 |
| yellow | 30.00 | 2,381,004 | 8.46 |
| yellow | 35.00 | 1,649,435 | 5.86 |
| yellow | 40.00 | 1,106,771 | 3.93 |

## 11_atipicos.sql

- **Pregunta:** Quedan valores atipicos dentro de los datos ya limpios (velocidades imposibles, tarifas por milla extremas)?
- **Objetivo:** Detectar outliers con la regla de Tukey (fuera de Q1 - 3*IQR / Q3 + 3*IQR) y con limites fisicos.
- **Fuente:** vista trips_clean.

```sql
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
```

Tiempo: 1.94 s · filas devueltas: 2

| taxi_type | viajes | velocidad_mayor_65mph | pct_velocidad_imposible | q1_usd_milla | q3_usd_milla | limite_sup_usd_milla | atipicos_usd_milla | pct_atipicos_usd_milla |
|---|---|---|---|---|---|---|---|---|
| green | 314,462 | 111 | 0.04 | 5.42 | 8.17 | 16.42 | 6,076 | 1.93 |
| yellow | 28,134,580 | 5,890 | 0.02 | 5.73 | 9.91 | 22.47 | 678,972 | 2.41 |

## 12_viajes_por_app.sql

- **Pregunta:** Que proporcion de los viajes de taxi se solicitan a traves de plataformas de alto volumen (Uber/Lyft) desde que existe el dato?
- **Objetivo:** Participacion de request_source en los meses en que la columna existe.
- **Fuente:** vista trips_clean, meses con request_source informado.

```sql
SELECT taxi_type, file_year AS anio, file_month AS mes,
       count(*)                                                                    AS viajes,
       round(100.0 * count(*) FILTER (WHERE request_source = 'HV0003') / count(*), 2) AS pct_uber_hv0003,
       round(100.0 * count(*) FILTER (WHERE request_source = 'HV0005') / count(*), 2) AS pct_lyft_hv0005,
       round(100.0 * count(*) FILTER (WHERE request_source IN ('A', 'CC') OR request_source LIKE 'EH%') / count(*), 2) AS pct_otras_apps,
       round(100.0 * count(*) FILTER (WHERE request_source IS NULL) / count(*), 2)   AS pct_sin_dato
FROM trips_clean
WHERE (file_year, file_month) IN (SELECT DISTINCT (file_year, file_month) FROM trips WHERE request_source IS NOT NULL)
GROUP BY taxi_type, anio, mes
ORDER BY taxi_type, anio, mes;
```

Tiempo: 0.30 s · filas devueltas: 6

| taxi_type | anio | mes | viajes | pct_uber_hv0003 | pct_lyft_hv0005 | pct_otras_apps | pct_sin_dato |
|---|---|---|---|---|---|---|---|
| green | 2,026 | 6 | 41,231 | 0.00 | 0.00 | 13.62 | 86.38 |
| green | 2,026 | 7 | 38,241 | 0.00 | 0.00 | 14.44 | 85.56 |
| green | 2,026 | 8 | 37,754 | 0.00 | 2.70 | 11.79 | 85.51 |
| yellow | 2,026 | 6 | 3,632,801 | 23.21 | 0.00 | 2.13 | 74.66 |
| yellow | 2,026 | 7 | 3,333,998 | 20.15 | 0.00 | 6.13 | 73.72 |
| yellow | 2,026 | 8 | 3,152,409 | 18.27 | 5.15 | 3.15 | 73.43 |
