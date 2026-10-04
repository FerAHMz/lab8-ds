# Resultados de `sql/08_evolucion`

Generado por `scripts/run_sql.py` (no editar a mano).

## 01_resumen_anual.sql

- **Pregunta:** Como cambiaron los indicadores principales entre 2024, 2025 y 2026 en el mismo periodo del anio?
- **Objetivo:** Comparacion anual con periodo comparable (enero-agosto, los meses disponibles de 2026).
- **Fuente:** vista trips_clean.

```sql
SELECT file_year AS anio, taxi_type,
       count(*)                                                       AS viajes_ene_ago,
       round(quantile_cont(total_amount, 0.5), 2)                     AS ticket_mediano_usd,
       round(quantile_cont(trip_distance, 0.5), 2)                    AS distancia_mediana_mi,
       round(100.0 * count(*) FILTER (WHERE payment_type = 2)
                   / count(*) FILTER (WHERE payment_type BETWEEN 1 AND 6), 2) AS pct_efectivo_informados,
       round(100.0 * count(*) FILTER (WHERE payment_type IS NULL OR payment_type NOT BETWEEN 1 AND 6) / count(*), 2) AS pct_pago_sin_dato,
       round(100 * quantile_cont(tip_amount / fare_amount, 0.5) FILTER (WHERE payment_type = 1), 2) AS propina_mediana_pct,
       round(avg(coalesce(cbd_congestion_fee, 0)), 3)                 AS cargo_cbd_promedio_usd
FROM trips_clean
WHERE file_month BETWEEN 1 AND 8
GROUP BY anio, taxi_type
ORDER BY taxi_type, anio;
```

Tiempo: 3.74 s · filas devueltas: 6

| anio | taxi_type | viajes_ene_ago | ticket_mediano_usd | distancia_mediana_mi | pct_efectivo_informados | pct_pago_sin_dato | propina_mediana_pct | cargo_cbd_promedio_usd |
|---|---|---|---|---|---|---|---|---|
| 2,024 | green | 412,475 | 19.15 | 1.98 | 28.85 | 4.07 | 23.49 | 0.00 |
| 2,025 | green | 368,823 | 19.85 | 2.04 | 24.75 | 6.46 | 23.49 | 0.07 |
| 2,026 | green | 314,462 | 20.50 | 2.14 | 22.65 | 13.56 | 23.64 | 0.06 |
| 2,024 | yellow | 25,416,332 | 21.00 | 1.80 | 15.09 | 9.01 | 25.93 | 0.00 |
| 2,025 | yellow | 28,595,784 | 21.61 | 1.88 | 12.38 | 19.65 | 26.69 | 0.55 |
| 2,026 | yellow | 28,134,580 | 23.58 | 1.94 | 11.99 | 24.99 | 26.41 | 0.54 |

## 02_variacion_interanual.sql

- **Pregunta:** Cuanto crecio o cayo la demanda de cada mes respecto al mismo mes del anio anterior?
- **Objetivo:** Variacion interanual (YoY) de viajes por mes y tipo usando lag() sobre el anio.
- **Fuente:** vista trips_clean.

```sql
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
```

Tiempo: 0.90 s · filas devueltas: 64

| taxi_type | mes | anio | viajes | var_pct_vs_anio_anterior |
|---|---|---|---|---|
| green | 1 | 2,024 | 52,735 | nan |
| green | 1 | 2,025 | 44,756 | -15.10 |
| green | 1 | 2,026 | 37,755 | -15.60 |
| green | 2 | 2,024 | 49,908 | nan |
| green | 2 | 2,025 | 42,954 | -13.90 |
| green | 2 | 2,026 | 34,829 | -18.90 |
| green | 3 | 2,024 | 53,581 | nan |
| green | 3 | 2,025 | 47,153 | -12.00 |
| green | 3 | 2,026 | 41,350 | -12.30 |
| green | 4 | 2,024 | 52,347 | nan |
| green | 4 | 2,025 | 47,658 | -9.00 |
| green | 4 | 2,026 | 41,279 | -13.40 |
| green | 5 | 2,024 | 56,818 | nan |
| green | 5 | 2,025 | 51,042 | -10.20 |
| green | 5 | 2,026 | 42,023 | -17.70 |
| green | 6 | 2,024 | 51,099 | nan |
| green | 6 | 2,025 | 46,079 | -9.80 |
| green | 6 | 2,026 | 41,231 | -10.50 |
| green | 7 | 2,024 | 47,964 | nan |
| green | 7 | 2,025 | 45,546 | -5.00 |
| green | 7 | 2,026 | 38,241 | -16.00 |
| green | 8 | 2,024 | 48,023 | nan |
| green | 8 | 2,025 | 43,635 | -9.10 |
| green | 8 | 2,026 | 37,754 | -13.50 |
| green | 9 | 2,024 | 50,624 | nan |
| green | 9 | 2,025 | 46,324 | -8.50 |
| green | 10 | 2,024 | 52,585 | nan |
| green | 10 | 2,025 | 46,643 | -11.30 |
| green | 11 | 2,024 | 48,560 | nan |
| green | 11 | 2,025 | 44,137 | -9.10 |
| green | 12 | 2,024 | 50,046 | nan |
| green | 12 | 2,025 | 45,243 | -9.60 |
| yellow | 1 | 2,024 | 2,859,076 | nan |
| yellow | 1 | 2,025 | 3,241,785 | 13.40 |
| yellow | 1 | 2,026 | 3,504,830 | 8.10 |
| yellow | 2 | 2,024 | 2,891,284 | nan |
| yellow | 2 | 2,025 | 3,296,157 | 14.00 |
| yellow | 2 | 2,026 | 3,199,918 | -2.90 |
| yellow | 3 | 2,024 | 3,427,645 | nan |
| yellow | 3 | 2,025 | 3,814,287 | 11.30 |
| yellow | 3 | 2,026 | 3,749,789 | -1.70 |
| yellow | 4 | 2,024 | 3,402,039 | nan |
| yellow | 4 | 2,025 | 3,659,303 | 7.60 |
| yellow | 4 | 2,026 | 3,661,836 | 0.10 |
| yellow | 5 | 2,024 | 3,603,557 | nan |
| yellow | 5 | 2,025 | 4,078,019 | 13.20 |
| yellow | 5 | 2,026 | 3,898,999 | -4.40 |
| yellow | 6 | 2,024 | 3,415,640 | nan |
| yellow | 6 | 2,025 | 3,855,741 | 12.90 |
| yellow | 6 | 2,026 | 3,632,801 | -5.80 |
| yellow | 7 | 2,024 | 2,961,864 | nan |
| yellow | 7 | 2,025 | 3,482,331 | 17.60 |
| yellow | 7 | 2,026 | 3,333,998 | -4.30 |
| yellow | 8 | 2,024 | 2,855,227 | nan |
| yellow | 8 | 2,025 | 3,168,161 | 11.00 |
| yellow | 8 | 2,026 | 3,152,409 | -0.50 |
| yellow | 9 | 2,024 | 3,470,643 | nan |
| yellow | 9 | 2,025 | 3,824,055 | 10.20 |
| yellow | 10 | 2,024 | 3,668,453 | nan |
| yellow | 10 | 2,025 | 3,929,408 | 7.10 |
| yellow | 11 | 2,024 | 3,496,967 | nan |
| yellow | 11 | 2,025 | 3,630,080 | 3.80 |
| yellow | 12 | 2,024 | 3,505,036 | nan |
| yellow | 12 | 2,025 | 4,035,004 | 15.10 |

## 03_velocidad_manhattan.sql

- **Pregunta:** Cambio la velocidad de los viajes dentro de Manhattan con el peaje de congestion (vigente desde enero de 2025)?
- **Objetivo:** Velocidad mediana de taxis amarillos con origen y destino en Manhattan, lunes a viernes de 7 a 19 h, por mes.
- **Fuente:** vista trips_clean + vista zones.

```sql
SELECT make_date(t.file_year, t.file_month, 1)                              AS mes,
       count(*)                                                             AS viajes,
       round(quantile_cont(t.trip_distance / (t.trip_minutes / 60), 0.5), 2) AS velocidad_mediana_mph,
       round(quantile_cont(t.trip_minutes, 0.5), 1)                         AS duracion_mediana_min,
       round(100.0 * avg((t.cbd_congestion_fee > 0)::INT), 1)               AS pct_con_cargo_cbd
FROM trips_clean t
JOIN zones zo ON zo.location_id = t.pu_location_id
JOIN zones zd ON zd.location_id = t.do_location_id
WHERE t.taxi_type = 'yellow'
  AND zo.borough = 'Manhattan' AND zd.borough = 'Manhattan'
  AND isodow(t.pickup_at) <= 5 AND hour(t.pickup_at) BETWEEN 7 AND 19
GROUP BY mes
ORDER BY mes;
```

Tiempo: 1.68 s · filas devueltas: 32

| mes | viajes | velocidad_mediana_mph | duracion_mediana_min | pct_con_cargo_cbd |
|---|---|---|---|---|
| 2024-01-01 00:00:00 | 1,354,660 | 8.23 | 11.00 | nan |
| 2024-02-01 00:00:00 | 1,333,600 | 7.96 | 11.40 | nan |
| 2024-03-01 00:00:00 | 1,434,057 | 7.95 | 11.80 | nan |
| 2024-04-01 00:00:00 | 1,515,350 | 7.80 | 12.10 | nan |
| 2024-05-01 00:00:00 | 1,641,092 | 7.43 | 12.70 | nan |
| 2024-06-01 00:00:00 | 1,423,522 | 7.68 | 12.20 | nan |
| 2024-07-01 00:00:00 | 1,375,162 | 8.00 | 11.80 | nan |
| 2024-08-01 00:00:00 | 1,247,368 | 8.07 | 11.60 | nan |
| 2024-09-01 00:00:00 | 1,432,461 | 7.25 | 13.00 | nan |
| 2024-10-01 00:00:00 | 1,630,392 | 7.18 | 12.90 | nan |
| 2024-11-01 00:00:00 | 1,476,202 | 7.27 | 12.60 | nan |
| 2024-12-01 00:00:00 | 1,505,288 | 7.08 | 12.90 | nan |
| 2025-01-01 00:00:00 | 1,508,951 | 8.18 | 10.90 | 66.70 |
| 2025-02-01 00:00:00 | 1,412,775 | 7.98 | 11.40 | 74.60 |
| 2025-03-01 00:00:00 | 1,473,130 | 8.00 | 11.60 | 76.40 |
| 2025-04-01 00:00:00 | 1,594,291 | 7.74 | 12.10 | 76.00 |
| 2025-05-01 00:00:00 | 1,675,781 | 7.34 | 13.00 | 75.80 |
| 2025-06-01 00:00:00 | 1,544,347 | 7.73 | 12.40 | 77.30 |
| 2025-07-01 00:00:00 | 1,502,244 | 7.83 | 12.30 | 79.60 |
| 2025-08-01 00:00:00 | 1,213,380 | 8.22 | 11.80 | 79.50 |
| 2025-09-01 00:00:00 | 1,560,913 | 7.29 | 13.20 | 76.10 |
| 2025-10-01 00:00:00 | 1,697,283 | 7.14 | 13.20 | 75.40 |
| 2025-11-01 00:00:00 | 1,420,326 | 7.05 | 13.40 | 74.70 |
| 2025-12-01 00:00:00 | 1,665,817 | 7.16 | 13.40 | 74.00 |
| 2026-01-01 00:00:00 | 1,421,095 | 7.71 | 12.20 | 73.30 |
| 2026-02-01 00:00:00 | 1,259,319 | 7.03 | 13.20 | 73.00 |
| 2026-03-01 00:00:00 | 1,527,501 | 7.65 | 12.20 | 74.30 |
| 2026-04-01 00:00:00 | 1,523,299 | 7.42 | 12.80 | 74.40 |
| 2026-05-01 00:00:00 | 1,517,044 | 7.08 | 13.50 | 70.20 |
| 2026-06-01 00:00:00 | 1,546,087 | 7.29 | 13.20 | 74.60 |
| 2026-07-01 00:00:00 | 1,441,538 | 7.60 | 12.90 | 78.80 |
| 2026-08-01 00:00:00 | 1,214,095 | 7.84 | 12.40 | 78.90 |

## 04_canales_y_proveedores.sql

- **Pregunta:** Cambio la composicion de proveedores (VendorID) de los taxis a lo largo de los tres anios?
- **Objetivo:** Participacion de cada VendorID por anio y tipo; ayuda a explicar cambios en la calidad del dato (pago sin informar).
- **Fuente:** vista trips (sin limpiar, para no ocultar registros incompletos).

```sql
SELECT file_year AS anio, taxi_type, vendor_id,
       count(*)                                                                             AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY file_year, taxi_type), 2)  AS pct_del_anio,
       round(100.0 * avg((payment_type IS NULL OR payment_type = 0)::INT), 1)               AS pct_pago_sin_dato
FROM trips
GROUP BY anio, taxi_type, vendor_id
ORDER BY taxi_type, anio, vendor_id;
```

Tiempo: 0.31 s · filas devueltas: 20

| anio | taxi_type | vendor_id | viajes | pct_del_anio | pct_pago_sin_dato |
|---|---|---|---|---|---|
| 2,024 | green | 1 | 80,450 | 12.19 | 1.40 |
| 2,024 | green | 2 | 579,768 | 87.81 | 4.00 |
| 2,025 | green | 1 | 65,489 | 11.07 | 1.50 |
| 2,025 | green | 2 | 498,801 | 84.35 | 4.40 |
| 2,025 | green | 6 | 27,085 | 4.58 | 100.00 |
| 2,026 | green | 1 | 28,696 | 8.51 | 1.80 |
| 2,026 | green | 2 | 273,571 | 81.15 | 4.90 |
| 2,026 | green | 6 | 34,847 | 10.34 | 100.00 |
| 2,024 | yellow | 1 | 9,715,918 | 23.60 | 8.90 |
| 2,024 | yellow | 2 | 31,451,503 | 76.39 | 10.30 |
| 2,024 | yellow | 6 | 2,069 | 0.01 | 100.00 |
| 2,024 | yellow | 7 | 230 | 0.00 | 0.00 |
| 2,025 | yellow | 1 | 9,586,873 | 19.68 | 16.50 |
| 2,025 | yellow | 2 | 38,575,846 | 79.17 | 25.90 |
| 2,025 | yellow | 6 | 23,982 | 0.05 | 100.00 |
| 2,025 | yellow | 7 | 535,901 | 1.10 | 0.00 |
| 2,026 | yellow | 1 | 5,467,071 | 18.41 | 16.40 |
| 2,026 | yellow | 2 | 23,809,774 | 80.16 | 28.40 |
| 2,026 | yellow | 6 | 59,390 | 0.20 | 100.00 |
| 2,026 | yellow | 7 | 367,120 | 1.24 | 0.00 |
