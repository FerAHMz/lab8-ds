# Codebook - NYC TLC Trip Records (amarillos y verdes)

**Fuente:** NYC Taxi & Limousine Commission, Trip Record Data
(<https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page>). Archivos mensuales en Parquet
desde `https://d37ci6vzurychx.cloudfront.net/trip-data/`, y la tabla de zonas
`taxi_zone_lookup.csv` desde `.../misc/`. Cobertura descargada: 2024-01 a 2026-08 para ambos tipos
(64 archivos, 121,184,384 registros).

## Variables originales

| Columna (amarillo / verde) | Tipo | Descripción | Valores / rango observado |
|---|---|---|---|
| `VendorID` | INT32 | Proveedor del registro | 1 = Creative Mobile Tech., 2 = Curb Mobility, 6 = Myle Technologies, 7 = Helix |
| `tpep_pickup_datetime` / `lpep_pickup_datetime` | TIMESTAMP (µs, hora local NY) | Inicio del viaje | hay errores de reloj desde 2001 |
| `tpep_dropoff_datetime` / `lpep_dropoff_datetime` | TIMESTAMP | Fin del viaje | duraciones ≤ 0 en ~1 % de amarillos |
| `passenger_count` | INT64 | Pasajeros (lo ingresa el chofer) | 0–9; nulo en registros sin datos de despacho |
| `trip_distance` | DOUBLE | Distancia en millas (taxímetro) | 0 a 328,522 (errores) |
| `RatecodeID` | INT64 | Tarifa final | 1 estándar, 2 JFK, 3 Newark, 4 Nassau/Westchester, 5 negociada, 6 grupo, 99 desconocido |
| `store_and_fwd_flag` | VARCHAR | Viaje guardado y enviado después (sin conexión) | Y / N |
| `PULocationID`, `DOLocationID` | INT32 | Zona TLC de origen y destino | 1–265 (ver `taxi_zone_lookup.csv`) |
| `payment_type` | INT64 | Método de pago | 0 Flex Fare / no informado, 1 tarjeta, 2 efectivo, 3 sin cargo, 4 disputa, 5 desconocido, 6 anulado |
| `fare_amount` | DOUBLE | Tarifa de tiempo y distancia (USD) | negativos = reversos |
| `extra` | DOUBLE | Recargos varios (hora pico, nocturno) | |
| `mta_tax` | DOUBLE | Impuesto MTA | 0.50 |
| `tip_amount` | DOUBLE | Propina (solo se registra con tarjeta) | |
| `tolls_amount` | DOUBLE | Peajes | |
| `improvement_surcharge` | DOUBLE | Recargo de mejora | 1.00 |
| `congestion_surcharge` | DOUBLE | Recargo de congestión del estado de NY | casi siempre 0 o 2.5 (negativos en reversos) |
| `Airport_fee` (solo amarillo) | DOUBLE | Cargo por recogida en LGA/JFK | 0 / 1.75 / 2.00 (sube en 2026) |
| `cbd_congestion_fee` | DOUBLE | Peaje de congestión de Manhattan (CBD) | **solo desde 2025-01**; 0 / 0.75 |
| `ehail_fee` (solo verde) | DOUBLE | Cargo de e-hail | 100 % nulo |
| `trip_type` (solo verde) | INT64 | 1 = parada en la calle, 2 = despacho | |
| `request_source` | VARCHAR | Canal de solicitud (licencia HVFHS o app) | **solo desde 2026-06**; HV0003 (Uber), HV0005 (Lyft), A, CC, EHxxxx |
| `total_amount` | DOUBLE | Total cobrado (sin propinas en efectivo) | |

## Variables derivadas (vista `trips`, `sql/00_views.sql`)

| Columna | Definición |
|---|---|
| `taxi_type` | `'yellow'` / `'green'` según la carpeta de origen |
| `pickup_at`, `dropoff_at` | `tpep_*` o `lpep_*` según el tipo |
| `airport_fee`, `ehail_fee`, `trip_type` | NULL en el tipo que no tiene esa columna |
| `filename` | ruta del Parquet de origen |
| `file_year`, `file_month` | año y mes extraídos del nombre del archivo (periodo asignado por la TLC) |
| `trip_minutes` | `date_diff('second', pickup_at, dropoff_at) / 60` |
| `payment_label` | etiqueta en español de `payment_type` |

## Reglas de limpieza (vista `trips_clean`)

1. `year/month(pickup_at)` = `file_year/file_month`
2. `trip_minutes` entre 1 y 240
3. `0 < trip_distance < 200`
4. `fare_amount > 0` y `0 < total_amount < 1000`

Excluyen entre 3.9 % y 7 % de los registros según el año y el tipo (ver `sql/05_validacion/06_calidad_por_anio.sql`).

## Tabla de zonas (`zones`)

| Columna | Descripción |
|---|---|
| `location_id` | ID de zona TLC (1–265) |
| `borough` | Manhattan, Queens, Brooklyn, Bronx, Staten Island, EWR, Unknown, N/A |
| `zone` | nombre de la zona |
| `service_zone` | Yellow Zone, Boro Zone, Airports, EWR |
