# Ejercicio 9 - Discusión

## 9.1 ¿Qué características de DuckDB resultaron más útiles?

- **`read_parquet` con globs** (`data/raw/*/*/*.parquet`): se consulta un directorio completo como
  si fuera una tabla, y los archivos nuevos entran solos en la siguiente consulta. Fue la base de
  todo el diseño incremental (Ejercicios 5 y 8).
- **`union_by_name = true`**: absorbió los cambios de esquema reales del dataset (`request_source`
  desde 2026-06, `cbd_congestion_fee` desde 2025-01, columnas distintas entre amarillos y verdes)
  sin tener que escribir código por archivo.
- **`filename = true` y `parquet_schema()` / `glob()`**: permitieron validar la descarga
  (archivos, meses, columnas por año) desde SQL y derivar el periodo de cada registro de la ruta del
  archivo para detectar fechas fuera de rango.
- **Vistas**: una sola definición (`sql/00_views.sql`) del esquema unificado y la limpieza, que
  reutilizan notebooks, scripts, benchmark y Metabase.
- **SQL analítico completo**: `quantile_cont`, `FILTER`, funciones de ventana (`lag`, `first`,
  `sum() OVER`), `ROLLUP`, `USING SAMPLE ... REPEATABLE`, `SUMMARIZE`, `isodow`/`date_diff`. Todos
  los indicadores salen de una consulta, sin postprocesar en pandas.
- **Ejecución en paralelo y fuera de memoria**: agregaciones sobre 121 M de filas en 1–3 s con
  14 hilos; los `CREATE TABLE`/`ORDER BY` grandes pueden derramar a disco con `temp_directory`.
- **Base embebida en un archivo**: la tabla materializada es un archivo que Metabase abre en modo
  `read_only`; no hizo falta ningún servidor de base de datos.

## 9.2 Ventajas y limitaciones de consultar directamente Parquet

**Ventajas observadas**

- Cero tiempo de carga: los datos se consultan apenas termina la descarga.
- Una sola copia de los datos: 1.9 GiB de Parquet para 121 M de viajes, contra 3.96 GiB de la base
  materializada.
- `count(*)` y la metadata se resuelven sin leer datos (0.03 s para 72 M de filas).
- Lectura columnar: las consultas solo leen las columnas que usan.
- El sistema crece agregando archivos; no hay que mantener tablas sincronizadas con la fuente.

**Limitaciones observadas**

- Cada consulta descomprime y decodifica de nuevo: en agregaciones completas fue entre 1.1× y
  1.8× más lenta que la tabla.
- Los filtros selectivos dependen de cómo están escritos los archivos. El filtro de un día tardó
  0.12 s en Parquet contra 0.006 s en la tabla ordenada (19×) y el tiempo crece con la cantidad
  de archivos.
- Los esquemas cambian entre archivos y hay que acordarse siempre de `union_by_name`. Sin él,
  DuckDB toma el esquema del primer archivo y las columnas nuevas desaparecen sin aviso.
- No se pueden corregir datos en el lugar (`UPDATE`/`DELETE`): la limpieza tiene que ser una vista
  que se recalcula en cada consulta.
- Los errores de calidad (fechas de 2001, distancias de 328 mil millas) llegan tal cual a cada consulta.

## 9.3 Ventajas y limitaciones de las tablas materializadas

**Ventajas**

- Más rápidas en consultas repetidas (hasta 4–7× con datos pequeños y 1.1–1.8× en agregaciones
  grandes) y mucho más en filtros por la columna de ordenamiento (zonemaps: ~6 ms sin importar el
  volumen).
- Latencia más predecible para el tablero, que vuelve a ejecutar 12 consultas cada vez que se abre.
- Permiten índices, restricciones y modificaciones de datos.

**Limitaciones**

- Costo de construcción (51–58 s) y **el doble de espacio** que los Parquet.
- Hay que reconstruirlas cada vez que llegan datos nuevos; mientras tanto, pueden quedar
  desactualizadas respecto de la fuente.
- La construcción fue lo más exigente en memoria de todo el laboratorio: un `ORDER BY` global de
  121 M de filas mató el proceso y hubo que materializar mes por mes.
- La primera consulta después de abrir la base es más lenta (tiene que leer bloques del archivo de
  4 GB).
- Concurrencia: un archivo `.duckdb` admite un solo escritor; Metabase tiene que usar `read_only`.
- Para consultas costosas en CPU (cuantiles exactos, JOIN) la ventaja casi desaparece (≈1.05×).
- **Cuando la tabla supera la memoria disponible pierde su ventaja de caché**: con tres años (tabla de
  4 GB, límite de 3 GB) empató con Parquet en la mitad de las consultas, y la de cuantiles exactos
  sobre la tabla ni siquiera cupo en la VM, mientras que sobre Parquet terminó en 17 s.

## 9.4 Ventajas frente a cargar todo con pandas

- **Memoria:** 121 M de filas × 25 columnas en un DataFrame de pandas ocuparían varias decenas de GB,
  muy por encima de los 8 GB de la VM. DuckDB lee por bloques y solo trae a Python el resultado
  agregado (decenas o cientos de filas).
- **Velocidad:** el motor es vectorizado y multihilo, y solo lee las columnas necesarias. pandas lee
  el archivo completo y opera en un solo hilo.
- **Sin paso de carga:** con pandas habría que leer 64 archivos y concatenarlos (alineando a mano los
  esquemas que cambian) antes de la primera consulta.
- **SQL declarativo y versionable:** cada indicador es un archivo `.sql` legible, reutilizable desde
  Metabase y documentable. En pandas la lógica queda dispersa en celdas.
- **Una sola lógica para todas las herramientas:** las mismas consultas alimentan el notebook, el
  benchmark y el tablero.
- pandas sigue siendo útil al final, para graficar resultados ya agregados (`.df()`).

## 9.5 ¿Qué permite incorporar datos nuevos con cambios mínimos?

- El año es un **parámetro** del script de descarga; incorporar 2024 y 2025 fue cambiar una tupla.
- **Estructura de carpetas `data/raw/<tipo>/<año>/`** y nombres originales de la TLC: el tipo y el
  periodo se derivan de la ruta.
- **Globs en todas las lecturas** y una **capa de vistas** única: ninguna consulta lista archivos ni años.
- `union_by_name` + casts explícitos absorben cambios de esquema.
- `file_year` / `file_month` derivados del nombre del archivo en lugar de constantes.
- Descarga **idempotente y verificable** (`--verify` + manifiesto).
- Base materializada y tablero que se **reconstruyen con un comando** cada uno.

El único cambio de código fuera de la tupla de años fue una consulta de validación con años fijos
(reescrita de forma genérica) y la forma de materializar cuando el volumen creció.

## 9.6 ¿Qué automatizar en un sistema de producción?

1. **Descarga programada** (por ejemplo, un cron mensual o un orquestador como Airflow o Dagster)
   que consulte la TLC, descargue solo lo nuevo y ejecute `--verify`. Si un archivo publicado no
   coincide o no se puede leer, debe fallar y avisar.
2. **Detección de cambios de esquema**: comparar `parquet_schema()` de cada archivo nuevo con el
   esquema esperado y alertar ante columnas nuevas, faltantes o con otro tipo (como `request_source`).
3. **Pruebas de calidad de datos** automáticas (las consultas del Ej. 3 convertidas en controles
   con umbrales): fechas fuera de periodo, % sin método de pago (que pasó de 9 % a 25 %), montos negativos.
4. **Materialización incremental**: insertar solo los meses nuevos (`materializar_trips` ya trabaja
   por mes) en lugar de reconstruir todo, y cambiar la base de forma atómica.
5. **Actualización del tablero** y de la caché de Metabase después de cada carga.
6. **CI** que ejecute las carpetas de SQL (`run_sql.py`) sobre una muestra para detectar consultas rotas.
7. **Benchmark periódico** para decidir con datos cuándo conviene particionar o reordenar tablas.

## 9.7 Decisiones de diseño importantes para la reproducibilidad

- **Docker con versiones fijas** (Python, DuckDB 1.5.5 = driver de Metabase 1.5.5.0, Metabase 0.63.19).
- **Los datos no están en Git**, pero sí el código que los genera y un **manifiesto versionado**
  (archivo, bytes y filas) que permite verificar que otra persona obtuvo exactamente los mismos datos.
- **Todo el SQL en archivos** con encabezado (pregunta, objetivo, fuente). Los notebooks y scripts
  solo los ejecutan.
- **Resultados regenerables** (`run_sql.py` escribe `docs/resultados/*.md`; `benchmark.py` escribe
  CSV), en lugar de copiar números a mano.
- **Transformaciones explícitas** en una sola vista documentada; `data/raw` nunca se modifica.
- **Rutas dentro del contenedor** (`/workspace/data`) iguales para `lab` y `metabase`.
- **Muestras con semilla** (`REPEATABLE (42)`), comparaciones sobre el mismo periodo y medianas de
  5 repeticiones en el benchmark.
- **Tablero creado por código** (API de Metabase) en lugar de clics, para poder recrearlo.
- **Límite de memoria explícito** (`LAB_MEMORY_LIMIT`), para que los resultados no dependan de la
  RAM disponible en cada máquina.

## 9.8 ¿Qué se aprende que no sería evidente con datos pequeños?

- **La memoria es un recurso de diseño.** Con un mes todo funcionaba. Con 121 M de filas, un
  `ORDER BY` global y los cuantiles exactos mataron el proceso. Hubo que materializar por partes,
  fijar `memory_limit` y `temp_directory` y entender qué operaciones pueden derramar a disco (sort,
  join, group by) y cuáles no (`quantile_cont` exacto). Con datos pequeños nunca se habría notado.
- **Los problemas de calidad de datos "raros" aparecen en cantidad.** Una fecha de 2001 o un viaje de
  328 mil millas son casos aislados en una muestra, pero en 121 M de filas hay cientos de miles de
  duraciones negativas y millones de registros sin método de pago. Las reglas de limpieza tienen que
  ser explícitas y medibles.
- **El esquema cambia con el tiempo.** Una muestra de un mes no muestra que `request_source` aparece
  a mitad de año ni que `cbd_congestion_fee` no existe en 2024.
- **Las tendencias solo se ven con varios periodos.** Con 2024 y 2026 parecía un crecimiento
  sostenido; con 2025 se vio que fue un salto en 2025 y luego estancamiento. Comparar periodos
  distintos (12 meses contra 8) también sesga los resultados.
- **El rendimiento depende de la forma de la consulta, no solo del volumen.** El conteo de Parquet
  no crece con los datos, el filtro sobre la tabla ordenada tampoco, y los cuantiles crecen más que
  linealmente. Con datos pequeños, todas las estrategias "tardan cero".
- **El costo fijo importa con pocos datos y el variable con muchos.** En 1 mes, Parquet era 3–7×
  más lento por abrir archivos; en 3 años, la diferencia en agregaciones se reduce a 1.1–1.8×.
- **Los promedios engañan a escala.** Con colas tan largas (montos de −2,555 a 7,045 USD), la media
  se mueve por unos pocos errores, mientras la mediana y los percentiles se mantienen estables.
