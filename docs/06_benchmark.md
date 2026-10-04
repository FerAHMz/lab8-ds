# Ejercicio 6 - Parquet vs. tablas DuckDB

- Materialización: [`scripts/build_duckdb.py`](../scripts/build_duckdb.py) → `data/processed/taxis.duckdb`.
- Benchmark: [`scripts/benchmark.py`](../scripts/benchmark.py) → [`docs/benchmark/`](benchmark/) (CSV + tabla Markdown).
- Gráficas: [`notebooks/06_benchmark.ipynb`](../notebooks/06_benchmark.ipynb).

```bash
docker compose exec lab python scripts/build_duckdb.py     # 6.2
docker compose exec lab python scripts/benchmark.py        # 6.3 - 6.7 (~8 min)
```

## 6.1 Consulta directa a Parquet

Es lo que se hizo en los ejercicios 3 a 5: la vista `trips` es un `read_parquet` sobre
`data/raw/*/*/*.parquet`. Por ejemplo, contar viajes y total promedio por año y tipo sobre los 71.9 M
de registros tarda **0.19 s** sin haber cargado nada antes.

## 6.2 Tabla materializada

`build_duckdb.py` crea `data/processed/taxis.duckdb` con:

| objeto | tipo | contenido |
|---|---|---|
| `trips_tbl` | tabla | `SELECT * FROM trips ORDER BY pickup_at` (todos los años en disco) |
| `zones_tbl` | tabla | tabla de zonas |
| `trips_clean_tbl` | vista | **las mismas reglas** de `trips_clean`, pero leyendo `trips_tbl` |
| `trips`, `trips_clean`, `zones`, `*_raw` | vistas | siguen apuntando a los Parquet |

Con 2024 + 2026: 71,870,407 filas, **57–59 s** de construcción y **2.31 GiB** en disco, contra
1.14 GiB de los Parquet de origen. La tabla se ordena por `pickup_at` para que las zonemaps
(mín/máx por bloque) sirvan para filtros de fecha. La base se escribe en un archivo temporal y se
renombra al final, para que Metabase nunca vea una base a medio construir.

Se tuvo que fijar `memory_limit = 3GB` y un `temp_directory` en
[`scripts/lab_db.py`](../scripts/lab_db.py). Con el límite por defecto (80 % de la RAM de la VM
de Docker) el `CREATE TABLE ... ORDER BY` hacía que el kernel matara el proceso, porque Metabase
corre en la misma VM. Con el límite, DuckDB derrama a disco y termina.

## 6.3 / 6.8 Consultas del benchmark

Son **los mismos archivos .sql** del análisis; el script no tiene una versión aparte de ninguna consulta:

| consulta | qué representa |
|---|---|
| `06_benchmark/b01_conteo_total.sql` | conteo puro (Parquet lo puede responder desde la metadata) |
| `06_benchmark/b02_filtro_un_dia.sql` | consulta muy selectiva: un día dentro de todo el periodo |
| `04_eda/01_viajes_por_mes.sql` | agregación por mes + función de ventana |
| `04_eda/02_hora_y_dia.sql` | agregación con extracción de fecha (336 grupos) |
| `04_eda/03_caracteristicas_viaje.sql` | 7 cuantiles exactos: la consulta más costosa en CPU |
| `04_eda/06_metodo_de_pago.sql` | agregación + cuantil + ventana |
| `04_eda/08_componentes_del_cobro.sql` | 9 sumas: lee muchas columnas |
| `04_eda/09_aeropuertos.sql` | dos JOIN con la tabla de zonas |

**Cómo se garantiza que la comparación es válida:** en los dos modos se ejecuta el mismo
`00_views.sql`, restringido a los mismos archivos del escenario. En el modo tabla, `trips` y `zones`
se reemplazan por vistas sobre `trips_mat` y `zones_mat`. Así `trips_clean` y las consultas son
idénticas carácter por carácter y solo cambia de dónde vienen las filas. Cada consulta se ejecuta
una vez "en frío" y luego 5 veces; se reporta la **mediana**. Equipo: Docker Desktop en macOS,
14 CPU y 8 GB de RAM en la VM, datos en un *bind mount*.

## 6.6 Escenarios (cantidades de datos)

| escenario | registros | Parquet | DuckDB | tiempo de materializar |
|---|---:|---:|---:|---:|
| 1 mes (2026-08) | 3.4 M | 57 MB | 115 MB | 1.1 s |
| 2026 (8 meses) | 30.0 M | 496 MB | 1,008 MB | 19.5 s |
| 2024 + 2026 (20 meses) | 71.9 M | 1,172 MB | 2,369 MB | 57.5 s |

(El escenario 2024+2025+2026 se agrega automáticamente cuando existen los archivos de 2025; ver Ejercicio 8.)

## 6.7 Resultados (mediana en segundos)

| consulta | 1 mes P | 1 mes T | 2026 P | 2026 T | 2024+2026 P | 2024+2026 T | P/T (mayor) |
|---|---:|---:|---:|---:|---:|---:|---:|
| b01 conteo | 0.006 | 0.002 | 0.014 | 0.011 | 0.026 | 0.034 | 0.8× |
| b02 filtro un día | 0.056 | 0.008 | 0.064 | 0.009 | 0.118 | **0.006** | **19.0×** |
| 01 viajes por mes | 0.087 | 0.019 | 0.256 | 0.116 | 0.601 | 0.362 | 1.7× |
| 02 hora y día | 0.108 | 0.035 | 0.303 | 0.268 | 0.771 | 0.715 | 1.1× |
| 03 características (cuantiles) | 0.461 | 0.382 | 4.160 | 3.899 | 10.678 | 10.216 | 1.05× |
| 06 método de pago | 0.170 | 0.076 | 0.865 | 0.723 | 2.211 | 1.804 | 1.2× |
| 08 componentes del cobro | 0.133 | 0.028 | 0.439 | 0.210 | 0.926 | 0.507 | 1.8× |
| 09 aeropuertos (JOIN) | 0.253 | 0.154 | 1.506 | 1.295 | 3.932 | 3.338 | 1.2× |

P = Parquet directo, T = tabla DuckDB. Tabla completa con primera ejecución, mínimo y máximo:
[`benchmark/resultados.csv`](benchmark/resultados.csv).

## 6.9 Análisis

1. **La tabla es más rápida casi siempre, pero la ventaja es pequeña en las consultas pesadas.**
   En agregaciones que recorren todo el conjunto, la tabla gana entre 1.05× y 1.8×. En Parquet,
   DuckDB tiene que descomprimir (Snappy/ZSTD) y decodificar las páginas en cada consulta; la tabla
   usa su propio formato, más ligero de leer, y queda en el *buffer manager* después de la primera
   lectura.
2. **Cuando la consulta es costosa en CPU, el formato de almacenamiento casi no importa.** La consulta
   de 7 cuantiles exactos (`03`) tarda ~10 s en ambos modos: el tiempo se va en ordenar 68 M de
   valores, no en leerlos. Lo mismo pasa, en menor medida, con los JOIN (`09`).
3. **El filtro selectivo es donde más se nota (hasta 19×).** La tabla está ordenada por
   `pickup_at`, así que sus zonemaps descartan casi todos los bloques y el tiempo **no crece con el
   volumen** (≈ 6–9 ms en los tres escenarios). En Parquet, cada archivo mensual también tiene
   estadísticas, pero DuckDB igual abre los 40 archivos y lee sus footers, así que el tiempo crece
   con la cantidad de archivos (56 → 118 ms).
4. **Con pocos datos, la ventaja relativa de la tabla es mayor (2–7×) pero sin importancia práctica:**
   todo tarda menos de medio segundo y lo que domina en Parquet es el costo fijo de abrir archivos
   y leer metadata.
5. **El conteo es la excepción.** Parquet lo responde con la metadata de cada row group y es
   igual o más rápido que la tabla.
6. **La primera ejecución penaliza a la tabla.** En el escenario mayor la primera ejecución de
   `08` tarda 1.83 s en la tabla contra 1.04 s en Parquet, porque tiene que traer bloques de un
   archivo de 2.3 GB a memoria. En el notebook, la primera consulta sobre `trips_tbl` tardó 0.92 s
   contra 0.19 s sobre Parquet.
7. **La materialización tiene un costo:** 57 s y el doble de espacio en disco. Con el ahorro
   promedio medido (0.29 s por consulta en el escenario mayor), se recupera después de **~200
   consultas**. El notebook calcula este punto de equilibrio para cada escenario.

## 6.10 ¿Cuándo usar cada estrategia?

**Consultar Parquet directamente** conviene cuando:

- los datos cambian o crecen seguido (llegan archivos nuevos cada mes): no hay que recargar nada
  y las consultas ven los datos nuevos de inmediato;
- el análisis es exploratorio o de una sola vez (pocas consultas, el costo de materializar no se recupera);
- importa el espacio en disco o se quiere una única copia de los datos (fuente de verdad);
- los archivos están en almacenamiento compartido u objeto (S3/HTTP) y los leen varias herramientas;
- las consultas son de conteo o muy pesadas en CPU, donde el formato casi no importa.

**Materializar una tabla DuckDB** conviene cuando:

- las mismas consultas se repiten muchas veces sobre datos estables (tableros, reportes recurrentes):
  en Metabase cada vista del tablero ejecuta las consultas;
- hay filtros selectivos por una columna (fecha, zona) sobre la que se puede ordenar la tabla;
- se necesita una latencia baja y predecible para usuarios interactivos;
- se quieren aplicar las transformaciones una sola vez (limpieza, joins, columnas derivadas) en
  lugar de en cada consulta;
- se necesitan índices, restricciones o actualizaciones (`UPDATE`/`DELETE`), que Parquet no permite.

En este laboratorio se usan las dos: **Parquet como fuente de verdad y para la exploración**, y
la **tabla materializada como capa de consumo del tablero**, que se reconstruye con un solo
comando cuando llegan datos nuevos.
