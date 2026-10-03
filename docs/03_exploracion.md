# Ejercicio 3 - Consultas directas sobre archivos Parquet

- Consultas: [`sql/03_exploracion/`](../sql/03_exploracion/) (un archivo por consulta, con su objetivo y fuente en el encabezado).
- Ejecución: [`notebooks/03_exploracion_parquet.ipynb`](../notebooks/03_exploracion_parquet.ipynb)
  o `docker compose exec lab python scripts/run_sql.py sql/03_exploracion`.
- SQL completo + tabla de resultados + tiempo de cada consulta, generados automáticamente:
  [`docs/resultados/03_exploracion.md`](resultados/03_exploracion.md).

Ninguna consulta de este ejercicio usa tablas ni vistas: todas leen los archivos con
`read_parquet`, `parquet_schema` o `glob`. Los datos analizados son los de **2026
(enero–agosto)**, que eran los disponibles en este punto del laboratorio.

## 3.8 Documentación por consulta

### 01 · Cantidad de archivos (3.1) — `01_cantidad_archivos.sql`

```sql
SELECT split_part(file, '/', 5) AS taxi_type, split_part(file, '/', 6) AS anio, count(*) AS archivos, ...
FROM glob('/workspace/data/raw/*/*/*.parquet') GROUP BY ALL;
```

- **Objetivo:** saber cuántos archivos hay por tipo y año y qué meses cubren.
- **Fuente:** el listado de `data/raw/*/*/*.parquet` (`glob` no abre los archivos).
- **Resultado:** 16 archivos: 8 amarillos y 8 verdes, de 2026-01 a 2026-08.
- **Decisión:** coincide con el manifiesto de descarga (16 `ok`), así que no falta ningún mes publicado.

### 02 · Cantidad de registros (3.2) — `02_cantidad_registros.sql`

- **Objetivo:** conocer el volumen por tipo de taxi.
- **Fuente:** `read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name=true, filename=true)`.
- **Resultado:**

  | taxi_type | registros |
  |---|---:|
  | yellow | 29,703,355 |
  | green | 337,114 |
  | **total** | **30,040,469** |

- **Decisión:** los amarillos son el 98.9 % de los viajes. Cualquier métrica "global" está dominada
  por ellos, por eso **toda comparación se hace separando por `taxi_type`**. El total coincide
  con la suma de `num_rows` de la metadata del manifiesto, lo que confirma la completitud.
  La consulta tarda ~0.4 s porque `count(*)` se resuelve con la metadata de los row groups.

### 03 · Columnas presentes (3.3) — `03_columnas.sql`

- **Objetivo:** identificar las columnas y en cuántos archivos aparece cada una.
- **Fuente:** `parquet_schema('/workspace/data/raw/*/*/*.parquet')` (solo lee el footer).
- **Resultado:** 20 columnas en amarillos y 21 en verdes, con diferencias:
  - fechas: `tpep_pickup/dropoff_datetime` (amarillo) vs `lpep_pickup/dropoff_datetime` (verde);
  - solo amarillos: `Airport_fee`; solo verdes: `ehail_fee`, `trip_type`;
  - **`request_source` aparece solo desde 2026-06** (3 archivos de cada tipo): el esquema
    cambia de un mes a otro dentro del mismo año.
- **Decisión:** leer siempre con `union_by_name = true` (si no, DuckDB toma el esquema del primer
  archivo y descarta o desalinea columnas) y crear una vista unificada `trips` que renombra las
  fechas a `pickup_at` / `dropoff_at` y rellena con `NULL` las columnas exclusivas de cada tipo
  ([`sql/00_views.sql`](../sql/00_views.sql)).

### 04 · Tipos de datos (3.4) — `04_tipos_de_datos.sql`

- **Objetivo:** ver el tipo de cada columna y si cambia entre archivos.
- **Fuente:** `parquet_schema(...)`.
- **Resultado:** cada columna tiene **un solo tipo** en los 16 archivos de 2026:
  - fechas: `INT64` con anotación `TIMESTAMP(MICROS)`, sin zona horaria (hora local de NY);
  - `VendorID`, `PULocationID`, `DOLocationID`: `INT32`;
  - `passenger_count`, `RatecodeID`, `payment_type`, `trip_type`: `INT64`;
  - montos y `trip_distance`: `DOUBLE`;
  - `store_and_fwd_flag` y `request_source`: texto (`BYTE_ARRAY` + `String`).
- **Decisión:** en la vista se castean `passenger_count`, `RatecodeID`, `payment_type` y `trip_type`
  a `BIGINT` de forma explícita, para que la vista no dependa del tipo que traigan años anteriores.

### 05 / 06 · Muestras (3.5) — `05_muestra_amarillos.sql`, `06_muestra_verdes.sql`

- **Objetivo:** ver registros reales de cada tipo.
- **Fuente:** `read_parquet('.../yellow/*/*.parquet')` y `read_parquet('.../green/*/*.parquet')`.
- **Resultado:** 8 filas de cada tipo con `USING SAMPLE reservoir(8 ROWS) REPEATABLE (42)`: la
  semilla hace que la muestra sea la misma en cada ejecución. Se ve que `total_amount` ≈
  tarifa + recargos + propina, que los pagos en efectivo (`payment_type = 2`) tienen propina 0
  y que `ehail_fee` siempre está vacío.
- **Decisión:** la propina **solo se analiza en pagos con tarjeta**, porque en efectivo no se registra.

### 07 · Nulos (3.6) — `07_nulos.sql`

- **Objetivo:** medir el porcentaje de nulos por columna y tipo.
- **Resultado:**

  | taxi_type | passenger_count / RatecodeID / store_and_fwd / congestion | payment_type | ehail_fee | trip_type |
  |---|---:|---:|---:|---:|
  | yellow | 25.98 % | 0 % | 100 % | 100 % (no existe) |
  | green | 14.47 % | 14.47 % | 100 % | 14.47 % |

  Los nulos aparecen **en las mismas filas**: 7,716,688 amarillos (exactamente los que tienen
  `payment_type = 0`, "Flex Fare / no informado" en el diccionario de la TLC) y 48,775 verdes.
- **Decisión:** son viajes sin información de despacho (típicamente proveedores que no reportan
  esos campos). Se **conservan** para conteos de viajes y montos, pero se excluyen al analizar
  pasajeros y tipo de pago. `ehail_fee` se descarta del análisis (100 % nula).

### 08 · Fechas fuera del periodo del archivo (3.6) — `08_fechas_fuera_de_rango.sql`

- **Objetivo:** detectar viajes cuya fecha de recogida no corresponde al mes del archivo.
- **Resultado:** 146 amarillos y 98 verdes. La fecha mínima es **2001-01-01** (amarillo) y
  2008-12-31 (verde), lo que solo puede ser un error de reloj del taxímetro.
- **Decisión:** la regla 1 de `trips_clean` exige que `year/month(pickup_at)` coincida con el
  periodo del nombre del archivo. Así un viaje solo puede caer en el mes que la TLC le asignó.

### 09 · Valores imposibles o sospechosos (3.6) — `09_valores_invalidos.sql`

| problema | yellow | green |
|---|---:|---:|
| duración ≤ 0 min | 371,683 | 234 |
| duración > 4 h | 8,585 | 1,219 |
| distancia = 0 | 952,231 | 12,212 |
| distancia ≥ 200 mi | 704 | 69 |
| tarifa negativa | 157,364 | 999 |
| total ≤ 0 | 167,093 | 1,566 |
| total ≥ 1,000 USD | 54 | 1 |
| propina negativa | 883 | 69 |
| pasajeros = 0 | 91,359 | 4,527 |

- **Decisión:** reglas de `trips_clean`: duración entre 1 y 240 min, distancia entre 0 y 200
  millas, tarifa y total positivos y total menor a 1,000 USD. Los montos negativos se concentran en
  `payment_type` 4 (disputa) y 2 (efectivo): son reversos contables del viaje original, no
  viajes. Como restan solo 0.5 % de la facturación, excluirlos no sesga los promedios.

### 10 · Resumen numérico (3.6) — `10_resumen_numerico.sql`

- **Objetivo:** distribución de las variables numéricas de amarillos en una sola pasada (`SUMMARIZE`).
- **Resultado (amarillos):** mediana de distancia 1.86 mi (q75 = 3.80) pero **máximo 328,522 mi**;
  tarifa mediana 15.8 USD con rango −2,555 a 7,045; `congestion_surcharge` toma valores −2.5 a 2.75
  y `cbd_congestion_fee` −0.75 a 0.75 (el peaje de congestión de Manhattan).
- **Decisión:** las distribuciones tienen colas extremas, así que se reportan **medianas y
  percentiles** en lugar de promedios simples. El histograma logarítmico del notebook muestra que
  el corte en 200 millas deja fuera solo la cola de errores.

### 11 · Códigos categóricos (3.6) — `11_codigos_categoricos.sql`

- **Objetivo:** comprobar que los códigos respetan el diccionario de la TLC.
- **Resultado:** `RatecodeID = 99` ("desconocido") en 769,693 amarillos; `VendorID` 6 y 7 (proveedores
  nuevos) aparecen además de 1 y 2; `payment_type = 0` en 26 % de los amarillos.
- **Decisión:** en la vista se traducen los códigos de pago a etiquetas (`payment_label`) y los
  códigos 99 y nulos se tratan como "desconocido" en el análisis.

### 12 · `request_source` (3.3 / 3.6) — `12_request_source.sql`

- **Objetivo:** entender la columna nueva.
- **Resultado:** desde 2026-06, 25 % de los amarillos tienen `HV0003` (licencia HVFHS de Uber) y
  en agosto aparece `HV0005` (Lyft): **viajes de taxi amarillo solicitados por apps de alto volumen**.
- **Decisión:** se incorpora a la vista y se usa como indicador. No se puede comparar con meses
  anteriores porque antes de junio la columna no existía, no porque el valor fuera cero.

### 13 · Duplicados (3.6) — `13_duplicados.sql`

- **Objetivo:** detectar registros repetidos (mismo vendor, horas, zonas, distancia y total).
- **Resultado:** 32,790 registros amarillos sobrantes (0.11 %), siempre pares; ninguno en verdes.
- **Decisión:** se documentan pero **no se eliminan**: su impacto en los agregados es despreciable y
  no se puede distinguir un duplicado de dos viajes reales idénticos.

## Transformaciones registradas

Todas están en [`sql/00_views.sql`](../sql/00_views.sql), que se ejecuta automáticamente con
`scripts/lab_db.connect()`:

| Vista | Qué hace |
|---|---|
| `yellow_raw`, `green_raw` | `read_parquet` de todos los años con `union_by_name` y `filename` |
| `trips` | Unifica ambos tipos con nombres homogéneos, agrega `taxi_type`, `file_year`, `file_month`, `trip_minutes` y `payment_label` |
| `trips_clean` | `trips` + las 4 reglas de calidad descritas arriba |

Con los datos de 2026, `trips_clean` conserva **28,449,042 de 30,040,469** registros (94.7 %).

## 3.9 ¿Qué significa consultar directamente un Parquet y por qué conviene?

Consultar directamente significa que DuckDB usa el archivo Parquet **como si fuera una tabla**,
sin importarlo antes a una base de datos: `SELECT ... FROM read_parquet('ruta/*.parquet')`. El
archivo sigue siendo la única copia de los datos y DuckDB lee de él solo lo que la consulta
necesita.

Ventajas con volúmenes grandes:

- **Formato columnar.** Solo se leen las columnas de la consulta. Calcular `avg(tip_amount)`
  no lee las otras 19 columnas.
- **Metadata y estadísticas.** Cada archivo guarda el número de filas y el mínimo/máximo por
  columna en cada *row group*. `count(*)` se responde sin leer datos (0.4 s para 30 millones de
  filas) y los filtros pueden saltarse bloques completos (*predicate/filter pushdown*).
- **Compresión.** Los 30 millones de viajes ocupan ~500 MB en Parquet; en CSV serían varios GB.
- **Sin paso de carga ni copia duplicada.** No hay que esperar un `INSERT` ni guardar dos copias
  de los datos. Un archivo nuevo en `data/raw` entra en la siguiente consulta gracias al glob `*`.
- **Paralelismo y ejecución fuera de memoria.** DuckDB reparte los archivos y row groups entre
  los núcleos y no necesita cargar todo en RAM.
