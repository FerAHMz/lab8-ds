# Resultados de `sql/07_indicadores`

Generado por `scripts/run_sql.py` (no editar a mano).

## 00a_kpi_viajes.sql

- **Pregunta:** Cuantos viajes validos hay en el periodo analizado?
- **Indicador:** KPI - total de viajes validos (millones).
- **Fuente:** trips_clean

```sql
SELECT round(count(*) / 1e6, 1) AS viajes_millones
FROM trips_clean;
```

Tiempo: 1.90 s · filas devueltas: 1

| viajes_millones |
|---|
| 68.60 |

## 00b_kpi_facturacion.sql

- **Pregunta:** Cuanto se facturo en total en el periodo analizado?
- **Indicador:** KPI - facturacion total (millones de USD).
- **Fuente:** trips_clean

```sql
SELECT round(sum(total_amount) / 1e6, 1) AS facturacion_millones_usd
FROM trips_clean;
```

Tiempo: 0.68 s · filas devueltas: 1

| facturacion_millones_usd |
|---|
| 2,003.30 |

## 01_viajes_mensuales.sql

- **Pregunta:** Como evoluciona la demanda de taxis mes a mes y por tipo?
- **Indicador:** Viajes validos por mes y tipo de taxi.
- **Visualizacion:** lineas (x = mes, series = tipo).
- **Fuente:** trips_clean

```sql
SELECT make_date(file_year, file_month, 1) AS mes,
       taxi_type,
       count(*)                            AS viajes
FROM trips_clean
GROUP BY mes, taxi_type
ORDER BY mes, taxi_type;
```

Tiempo: 0.58 s · filas devueltas: 40

| mes | taxi_type | viajes |
|---|---|---|
| 2024-01-01 00:00:00 | green | 52,735 |
| 2024-01-01 00:00:00 | yellow | 2,859,076 |
| 2024-02-01 00:00:00 | green | 49,908 |
| 2024-02-01 00:00:00 | yellow | 2,891,284 |
| 2024-03-01 00:00:00 | green | 53,581 |
| 2024-03-01 00:00:00 | yellow | 3,427,645 |
| 2024-04-01 00:00:00 | green | 52,347 |
| 2024-04-01 00:00:00 | yellow | 3,402,039 |
| 2024-05-01 00:00:00 | green | 56,818 |
| 2024-05-01 00:00:00 | yellow | 3,603,557 |
| 2024-06-01 00:00:00 | green | 51,099 |
| 2024-06-01 00:00:00 | yellow | 3,415,640 |
| 2024-07-01 00:00:00 | green | 47,964 |
| 2024-07-01 00:00:00 | yellow | 2,961,864 |
| 2024-08-01 00:00:00 | green | 48,023 |
| 2024-08-01 00:00:00 | yellow | 2,855,227 |
| 2024-09-01 00:00:00 | green | 50,624 |
| 2024-09-01 00:00:00 | yellow | 3,470,643 |
| 2024-10-01 00:00:00 | green | 52,585 |
| 2024-10-01 00:00:00 | yellow | 3,668,453 |
| 2024-11-01 00:00:00 | green | 48,560 |
| 2024-11-01 00:00:00 | yellow | 3,496,967 |
| 2024-12-01 00:00:00 | green | 50,046 |
| 2024-12-01 00:00:00 | yellow | 3,505,036 |
| 2026-01-01 00:00:00 | green | 37,755 |
| 2026-01-01 00:00:00 | yellow | 3,504,830 |
| 2026-02-01 00:00:00 | green | 34,829 |
| 2026-02-01 00:00:00 | yellow | 3,199,918 |
| 2026-03-01 00:00:00 | green | 41,350 |
| 2026-03-01 00:00:00 | yellow | 3,749,789 |
| 2026-04-01 00:00:00 | green | 41,279 |
| 2026-04-01 00:00:00 | yellow | 3,661,836 |
| 2026-05-01 00:00:00 | green | 42,023 |
| 2026-05-01 00:00:00 | yellow | 3,898,999 |
| 2026-06-01 00:00:00 | green | 41,231 |
| 2026-06-01 00:00:00 | yellow | 3,632,801 |
| 2026-07-01 00:00:00 | green | 38,241 |
| 2026-07-01 00:00:00 | yellow | 3,333,998 |
| 2026-08-01 00:00:00 | green | 37,754 |
| 2026-08-01 00:00:00 | yellow | 3,152,409 |

## 02_ticket_mediano.sql

- **Pregunta:** Cuanto paga un pasajero en un viaje tipico y como cambia en el tiempo?
- **Indicador:** Total cobrado mediano por viaje (USD), por mes y tipo.
- **Visualizacion:** lineas.
- **Fuente:** trips_clean

```sql
SELECT make_date(file_year, file_month, 1)        AS mes,
       taxi_type,
       round(quantile_cont(total_amount, 0.5), 2) AS ticket_mediano_usd
FROM trips_clean
GROUP BY mes, taxi_type
ORDER BY mes, taxi_type;
```

Tiempo: 1.05 s · filas devueltas: 40

| mes | taxi_type | ticket_mediano_usd |
|---|---|---|
| 2024-01-01 00:00:00 | green | 18.36 |
| 2024-01-01 00:00:00 | yellow | 20.16 |
| 2024-02-01 00:00:00 | green | 18.45 |
| 2024-02-01 00:00:00 | yellow | 20.46 |
| 2024-03-01 00:00:00 | green | 18.50 |
| 2024-03-01 00:00:00 | yellow | 20.65 |
| 2024-04-01 00:00:00 | green | 18.90 |
| 2024-04-01 00:00:00 | yellow | 21.00 |
| 2024-05-01 00:00:00 | green | 19.85 |
| 2024-05-01 00:00:00 | yellow | 21.60 |
| 2024-06-01 00:00:00 | green | 19.68 |
| 2024-06-01 00:00:00 | yellow | 21.35 |
| 2024-07-01 00:00:00 | green | 19.56 |
| 2024-07-01 00:00:00 | yellow | 21.00 |
| 2024-08-01 00:00:00 | green | 19.90 |
| 2024-08-01 00:00:00 | yellow | 21.00 |
| 2024-09-01 00:00:00 | green | 20.40 |
| 2024-09-01 00:00:00 | yellow | 21.84 |
| 2024-10-01 00:00:00 | green | 19.85 |
| 2024-10-01 00:00:00 | yellow | 21.84 |
| 2024-11-01 00:00:00 | green | 19.35 |
| 2024-11-01 00:00:00 | yellow | 21.36 |
| 2024-12-01 00:00:00 | green | 19.20 |
| 2024-12-01 00:00:00 | yellow | 21.85 |
| 2026-01-01 00:00:00 | green | 20.04 |
| 2026-01-01 00:00:00 | yellow | 23.10 |
| 2026-02-01 00:00:00 | green | 20.10 |
| 2026-02-01 00:00:00 | yellow | 24.00 |
| 2026-03-01 00:00:00 | green | 20.41 |
| 2026-03-01 00:00:00 | yellow | 23.35 |
| 2026-04-01 00:00:00 | green | 20.45 |
| 2026-04-01 00:00:00 | yellow | 23.58 |
| 2026-05-01 00:00:00 | green | 20.80 |
| 2026-05-01 00:00:00 | yellow | 23.92 |
| 2026-06-01 00:00:00 | green | 20.90 |
| 2026-06-01 00:00:00 | yellow | 23.83 |
| 2026-07-01 00:00:00 | green | 20.60 |
| 2026-07-01 00:00:00 | yellow | 23.56 |
| 2026-08-01 00:00:00 | green | 20.88 |
| 2026-08-01 00:00:00 | yellow | 23.55 |

## 03_uso_efectivo.sql

- **Pregunta:** Se esta dejando de usar el efectivo?
- **Indicador:** % de viajes pagados en efectivo, sobre los viajes con metodo de pago informado (codigos 1-6).
- **Visualizacion:** lineas.
- **Fuente:** trips_clean

```sql
SELECT make_date(file_year, file_month, 1) AS mes,
       taxi_type,
       round(100.0 * count(*) FILTER (WHERE payment_type = 2)
                   / count(*) FILTER (WHERE payment_type BETWEEN 1 AND 6), 2) AS pct_efectivo
FROM trips_clean
GROUP BY mes, taxi_type
ORDER BY mes, taxi_type;
```

Tiempo: 0.64 s · filas devueltas: 40

| mes | taxi_type | pct_efectivo |
|---|---|---|
| 2024-01-01 00:00:00 | green | 30.43 |
| 2024-01-01 00:00:00 | yellow | 15.28 |
| 2024-02-01 00:00:00 | green | 29.63 |
| 2024-02-01 00:00:00 | yellow | 14.34 |
| 2024-03-01 00:00:00 | green | 30.73 |
| 2024-03-01 00:00:00 | yellow | 14.82 |
| 2024-04-01 00:00:00 | green | 28.04 |
| 2024-04-01 00:00:00 | yellow | 14.82 |
| 2024-05-01 00:00:00 | green | 28.03 |
| 2024-05-01 00:00:00 | yellow | 14.82 |
| 2024-06-01 00:00:00 | green | 27.91 |
| 2024-06-01 00:00:00 | yellow | 14.69 |
| 2024-07-01 00:00:00 | green | 28.13 |
| 2024-07-01 00:00:00 | yellow | 15.92 |
| 2024-08-01 00:00:00 | green | 27.85 |
| 2024-08-01 00:00:00 | yellow | 16.20 |
| 2024-09-01 00:00:00 | green | 26.70 |
| 2024-09-01 00:00:00 | yellow | 13.77 |
| 2024-10-01 00:00:00 | green | 26.37 |
| 2024-10-01 00:00:00 | yellow | 13.52 |
| 2024-11-01 00:00:00 | green | 25.93 |
| 2024-11-01 00:00:00 | yellow | 13.35 |
| 2024-12-01 00:00:00 | green | 26.45 |
| 2024-12-01 00:00:00 | yellow | 14.27 |
| 2026-01-01 00:00:00 | green | 23.82 |
| 2026-01-01 00:00:00 | yellow | 11.53 |
| 2026-02-01 00:00:00 | green | 23.39 |
| 2026-02-01 00:00:00 | yellow | 11.12 |
| 2026-03-01 00:00:00 | green | 22.67 |
| 2026-03-01 00:00:00 | yellow | 11.41 |
| 2026-04-01 00:00:00 | green | 22.15 |
| 2026-04-01 00:00:00 | yellow | 11.60 |
| 2026-05-01 00:00:00 | green | 22.57 |
| 2026-05-01 00:00:00 | yellow | 11.56 |
| 2026-06-01 00:00:00 | green | 22.29 |
| 2026-06-01 00:00:00 | yellow | 12.34 |
| 2026-07-01 00:00:00 | green | 21.38 |
| 2026-07-01 00:00:00 | yellow | 13.20 |
| 2026-08-01 00:00:00 | green | 23.08 |
| 2026-08-01 00:00:00 | yellow | 13.37 |

## 04_propina_tarjeta.sql

- **Pregunta:** Que tan generosos son los pasajeros que pagan con tarjeta?
- **Indicador:** Propina mediana como % de la tarifa base en pagos con tarjeta, por anio y tipo.
- **Visualizacion:** barras agrupadas.
- **Fuente:** trips_clean (payment_type = 1)

```sql
SELECT file_year::VARCHAR                                            AS anio,
       taxi_type,
       round(100 * quantile_cont(tip_amount / fare_amount, 0.5), 2)  AS propina_mediana_pct
FROM trips_clean
WHERE payment_type = 1
GROUP BY anio, taxi_type
ORDER BY anio, taxi_type;
```

Tiempo: 1.32 s · filas devueltas: 4

| anio | taxi_type | propina_mediana_pct |
|---|---|---|
| 2024 | green | 23.49 |
| 2024 | yellow | 25.88 |
| 2026 | green | 23.64 |
| 2026 | yellow | 26.41 |

## 05_velocidad_por_hora.sql

- **Pregunta:** A que hora es mas lenta la ciudad y cambio la congestion entre anios?
- **Indicador:** Velocidad mediana (mph) de taxis amarillos por hora del dia, lunes a viernes, por anio.
- **Visualizacion:** lineas (x = hora, series = anio).
- **Fuente:** trips_clean (taxi_type = 'yellow', isodow <= 5)

```sql
SELECT hour(pickup_at)                                                   AS hora,
       file_year::VARCHAR                                                AS anio,
       round(quantile_cont(trip_distance / (trip_minutes / 60), 0.5), 2) AS velocidad_mediana_mph
FROM trips_clean
WHERE taxi_type = 'yellow' AND isodow(pickup_at) <= 5
GROUP BY hora, anio
ORDER BY hora, anio;
```

Tiempo: 0.75 s · filas devueltas: 48

| hora | anio | velocidad_mediana_mph |
|---|---|---|
| 0 | 2024 | 13.42 |
| 0 | 2026 | 13.40 |
| 1 | 2024 | 14.11 |
| 1 | 2026 | 14.35 |
| 2 | 2024 | 14.29 |
| 2 | 2026 | 14.86 |
| 3 | 2024 | 15.08 |
| 3 | 2026 | 15.52 |
| 4 | 2024 | 17.30 |
| 4 | 2026 | 16.79 |
| 5 | 2024 | 16.15 |
| 5 | 2026 | 15.76 |
| 6 | 2024 | 13.54 |
| 6 | 2026 | 13.33 |
| 7 | 2024 | 10.72 |
| 7 | 2026 | 10.62 |
| 8 | 2024 | 8.75 |
| 8 | 2026 | 8.81 |
| 9 | 2024 | 8.19 |
| 9 | 2026 | 8.10 |
| 10 | 2024 | 7.88 |
| 10 | 2026 | 7.68 |
| 11 | 2024 | 7.49 |
| 11 | 2026 | 7.32 |
| 12 | 2024 | 7.56 |
| 12 | 2026 | 7.40 |
| 13 | 2024 | 7.79 |
| 13 | 2026 | 7.57 |
| 14 | 2024 | 7.71 |
| 14 | 2026 | 7.56 |
| 15 | 2024 | 7.67 |
| 15 | 2026 | 7.41 |
| 16 | 2024 | 7.97 |
| 16 | 2026 | 7.63 |
| 17 | 2024 | 7.98 |
| 17 | 2026 | 7.72 |
| 18 | 2024 | 8.36 |
| 18 | 2026 | 8.11 |
| 19 | 2024 | 9.18 |
| 19 | 2026 | 8.82 |
| 20 | 2024 | 9.93 |
| 20 | 2026 | 9.73 |
| 21 | 2024 | 10.38 |
| 21 | 2026 | 10.05 |
| 22 | 2024 | 10.79 |
| 22 | 2026 | 10.49 |
| 23 | 2024 | 11.53 |
| 23 | 2026 | 11.32 |

## 06_cargos_congestion.sql

- **Pregunta:** Cuanto pesan los cargos por congestion en lo que paga el pasajero?
- **Indicador:** % de la facturacion de taxis amarillos que corresponde al recargo de congestion y al cargo CBD, por mes.
- **Visualizacion:** area apilada.
- **Fuente:** trips_clean (taxi_type = 'yellow')

```sql
SELECT make_date(file_year, file_month, 1)                                          AS mes,
       round(100 * sum(coalesce(congestion_surcharge, 0)) / sum(total_amount), 2)   AS pct_recargo_congestion,
       round(100 * sum(coalesce(cbd_congestion_fee, 0)) / sum(total_amount), 2)     AS pct_cargo_cbd
FROM trips_clean
WHERE taxi_type = 'yellow'
GROUP BY mes
ORDER BY mes;
```

Tiempo: 0.61 s · filas devueltas: 20

| mes | pct_recargo_congestion | pct_cargo_cbd |
|---|---|---|
| 2024-01-01 00:00:00 | 8.18 | 0.00 |
| 2024-02-01 00:00:00 | 8.15 | 0.00 |
| 2024-03-01 00:00:00 | 7.48 | 0.00 |
| 2024-04-01 00:00:00 | 7.31 | 0.00 |
| 2024-05-01 00:00:00 | 7.16 | 0.00 |
| 2024-06-01 00:00:00 | 7.19 | 0.00 |
| 2024-07-01 00:00:00 | 7.21 | 0.00 |
| 2024-08-01 00:00:00 | 7.15 | 0.00 |
| 2024-09-01 00:00:00 | 6.88 | 0.00 |
| 2024-10-01 00:00:00 | 7.18 | 0.00 |
| 2024-11-01 00:00:00 | 7.42 | 0.00 |
| 2024-12-01 00:00:00 | 7.29 | 0.00 |
| 2026-01-01 00:00:00 | 5.39 | 1.80 |
| 2026-02-01 00:00:00 | 5.21 | 1.75 |
| 2026-03-01 00:00:00 | 5.69 | 1.78 |
| 2026-04-01 00:00:00 | 5.92 | 1.79 |
| 2026-05-01 00:00:00 | 5.68 | 1.64 |
| 2026-06-01 00:00:00 | 5.71 | 1.83 |
| 2026-07-01 00:00:00 | 5.67 | 1.93 |
| 2026-08-01 00:00:00 | 5.61 | 1.93 |

## 07_aeropuertos.sql

- **Pregunta:** Que tan dependientes son los taxis amarillos de los viajes de aeropuerto?
- **Indicador:** % de viajes y % de facturacion de taxis amarillos con origen o destino en JFK, LaGuardia o Newark, por anio.
- **Visualizacion:** barras agrupadas.
- **Fuente:** trips_clean + zones

```sql
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
```

Tiempo: 0.81 s · filas devueltas: 2

| anio | pct_viajes | pct_facturacion |
|---|---|---|
| 2024 | 10.07 | 27.80 |
| 2026 | 8.11 | 20.94 |

## 08_top_zonas_origen.sql

- **Pregunta:** Donde se concentra la demanda de taxis?
- **Indicador:** 10 zonas con mas recogidas (ambos tipos, todo el periodo) y su % del total.
- **Visualizacion:** barras horizontales.
- **Fuente:** trips_clean + zones

```sql
SELECT z.zone || ' (' || z.borough || ')'                                AS zona,
       count(*)                                                          AS viajes,
       round(100.0 * count(*) / (SELECT count(*) FROM trips_clean), 2)   AS pct_del_total
FROM trips_clean t
JOIN zones z ON z.location_id = t.pu_location_id
GROUP BY zona
ORDER BY viajes DESC
LIMIT 10;
```

Tiempo: 1.42 s · filas devueltas: 10

| zona | viajes | pct_del_total |
|---|---|---|
| Upper East Side South (Manhattan) | 3,118,696 | 4.54 |
| Midtown Center (Manhattan) | 3,027,360 | 4.41 |
| JFK Airport (Queens) | 2,961,000 | 4.32 |
| Upper East Side North (Manhattan) | 2,804,357 | 4.09 |
| Midtown East (Manhattan) | 2,241,856 | 3.27 |
| Penn Station/Madison Sq West (Manhattan) | 2,189,484 | 3.19 |
| Times Sq/Theatre District (Manhattan) | 2,149,868 | 3.13 |
| Lincoln Square East (Manhattan) | 2,089,278 | 3.04 |
| LaGuardia Airport (Queens) | 1,969,166 | 2.87 |
| Murray Hill (Manhattan) | 1,873,253 | 2.73 |

## 09_participacion_verdes.sql

- **Pregunta:** Que peso tienen los taxis verdes dentro del total de viajes y esta cambiando?
- **Indicador:** % de los viajes de cada mes que hacen los taxis verdes.
- **Visualizacion:** linea.
- **Fuente:** trips_clean

```sql
SELECT make_date(file_year, file_month, 1)                                  AS mes,
       round(100.0 * count(*) FILTER (WHERE taxi_type = 'green') / count(*), 3) AS pct_verdes
FROM trips_clean
GROUP BY mes
ORDER BY mes;
```

Tiempo: 0.60 s · filas devueltas: 20

| mes | pct_verdes |
|---|---|
| 2024-01-01 00:00:00 | 1.81 |
| 2024-02-01 00:00:00 | 1.70 |
| 2024-03-01 00:00:00 | 1.54 |
| 2024-04-01 00:00:00 | 1.51 |
| 2024-05-01 00:00:00 | 1.55 |
| 2024-06-01 00:00:00 | 1.47 |
| 2024-07-01 00:00:00 | 1.59 |
| 2024-08-01 00:00:00 | 1.65 |
| 2024-09-01 00:00:00 | 1.44 |
| 2024-10-01 00:00:00 | 1.41 |
| 2024-11-01 00:00:00 | 1.37 |
| 2024-12-01 00:00:00 | 1.41 |
| 2026-01-01 00:00:00 | 1.07 |
| 2026-02-01 00:00:00 | 1.08 |
| 2026-03-01 00:00:00 | 1.09 |
| 2026-04-01 00:00:00 | 1.11 |
| 2026-05-01 00:00:00 | 1.07 |
| 2026-06-01 00:00:00 | 1.12 |
| 2026-07-01 00:00:00 | 1.13 |
| 2026-08-01 00:00:00 | 1.18 |

## 10_pago_sin_dato.sql

- **Pregunta:** Que tan confiable es el dato del metodo de pago?
- **Indicador:** % de viajes sin metodo de pago informado (payment_type nulo o 0) por mes y tipo.
- **Visualizacion:** lineas.
- **Fuente:** trips_clean

```sql
SELECT make_date(file_year, file_month, 1) AS mes,
       taxi_type,
       round(100.0 * count(*) FILTER (WHERE payment_type IS NULL OR payment_type NOT BETWEEN 1 AND 6) / count(*), 2) AS pct_pago_sin_dato
FROM trips_clean
GROUP BY mes, taxi_type
ORDER BY mes, taxi_type;
```

Tiempo: 0.57 s · filas devueltas: 40

| mes | taxi_type | pct_pago_sin_dato |
|---|---|---|
| 2024-01-01 00:00:00 | green | 6.20 |
| 2024-01-01 00:00:00 | yellow | 4.02 |
| 2024-02-01 00:00:00 | green | 5.67 |
| 2024-02-01 00:00:00 | yellow | 5.14 |
| 2024-03-01 00:00:00 | green | 3.81 |
| 2024-03-01 00:00:00 | yellow | 10.64 |
| 2024-04-01 00:00:00 | green | 3.69 |
| 2024-04-01 00:00:00 | yellow | 11.40 |
| 2024-05-01 00:00:00 | green | 3.24 |
| 2024-05-01 00:00:00 | yellow | 10.69 |
| 2024-06-01 00:00:00 | green | 3.57 |
| 2024-06-01 00:00:00 | yellow | 11.33 |
| 2024-07-01 00:00:00 | green | 3.21 |
| 2024-07-01 00:00:00 | yellow | 8.87 |
| 2024-08-01 00:00:00 | green | 3.19 |
| 2024-08-01 00:00:00 | yellow | 8.34 |
| 2024-09-01 00:00:00 | green | 3.24 |
| 2024-09-01 00:00:00 | yellow | 12.39 |
| 2024-10-01 00:00:00 | green | 3.00 |
| 2024-10-01 00:00:00 | yellow | 9.40 |
| 2024-11-01 00:00:00 | green | 3.12 |
| 2024-11-01 00:00:00 | yellow | 9.59 |
| 2024-12-01 00:00:00 | green | 3.80 |
| 2024-12-01 00:00:00 | yellow | 8.24 |
| 2026-01-01 00:00:00 | green | 12.72 |
| 2026-01-01 00:00:00 | yellow | 28.35 |
| 2026-02-01 00:00:00 | green | 13.67 |
| 2026-02-01 00:00:00 | yellow | 28.98 |
| 2026-03-01 00:00:00 | green | 14.23 |
| 2026-03-01 00:00:00 | yellow | 22.88 |
| 2026-04-01 00:00:00 | green | 13.51 |
| 2026-04-01 00:00:00 | yellow | 20.17 |
| 2026-05-01 00:00:00 | green | 11.92 |
| 2026-05-01 00:00:00 | yellow | 22.50 |
| 2026-06-01 00:00:00 | green | 13.62 |
| 2026-06-01 00:00:00 | yellow | 25.35 |
| 2026-07-01 00:00:00 | green | 14.45 |
| 2026-07-01 00:00:00 | yellow | 26.29 |
| 2026-08-01 00:00:00 | green | 14.50 |
| 2026-08-01 00:00:00 | yellow | 26.58 |
