# Ejercicio 5 - Incorporación de los datos de 2024

## 5.1 Cambio al sistema de descarga

Un solo cambio, en una línea de [`scripts/download_data.py`](../scripts/download_data.py):

```diff
-ANIOS_POR_DEFECTO = (2026,)
+ANIOS_POR_DEFECTO = (2024, 2026)
```

No hubo que tocar la lógica. Desde el Ejercicio 2 el año es un parámetro de todas las funciones,
así que también funcionaba sin editar el archivo:

```bash
docker compose exec lab python scripts/download_data.py --years 2024
```

Se cambió el valor por defecto para que `python scripts/download_data.py`, sin argumentos,
reproduzca siempre el conjunto completo con el que trabaja el laboratorio. Los datos se obtienen
de la fuente original (CDN de la TLC, `https://d37ci6vzurychx.cloudfront.net/trip-data/`).

## 5.2 – 5.4 Ejecución: se conserva 2026 y no se re-descarga

```text
=== YELLOW 2024 ===   2024-01 ... 2024-12  descargando... listo
=== GREEN 2024 ===    2024-01 ... 2024-12  descargando... listo
=== YELLOW 2026 ===   2026-01 ... 2026-08  ya existe, se omite
=== GREEN 2026 ===    2026-01 ... 2026-08  ya existe, se omite
RESUMEN
  descargados   : 24
  ya existian   : 16
  no publicados : 8      (2026-09 a 2026-12)
  fallidos      : 0
```

Los 16 archivos de 2026 aparecen como `ya existe, se omite`: no se volvió a pedir ningún byte
de ellos y conservan su fecha de modificación original.

## 5.5 Verificación de los archivos nuevos

`python scripts/download_data.py --verify` → `archivos correctos: 40 | no publicados: 8 |
con problemas: 0 | registros totales: 71,870,407`. Tamaños idénticos byte a byte al servidor y
los 24 Parquet de 2024 son legibles ([manifiesto](manifest_descarga.csv)).

## 5.6 / 5.8 Consultas de validación (2024 + 2026 en conjunto)

Carpeta [`sql/05_validacion/`](../sql/05_validacion/). Resultados completos en
[`resultados/05_validacion.md`](resultados/05_validacion.md).

| Consulta | Objetivo | Resultado |
|---|---|---|
| `01_archivos_por_anio.sql` | Hay 12 archivos de 2024 por tipo y se conservan los de 2026 | 2024: 12 + 12 (2024-01 a 2024-12); 2026: 8 + 8 ✔ |
| `02_registros_por_anio.sql` | Contar ambos años **en una sola consulta** a través de la vista `trips` | 2024: 41,829,938; 2026: 30,040,469; total **71,870,407** = manifiesto ✔ |
| `03_columnas_por_anio.sql` | Columnas que existen en un año y no en el otro | `cbd_congestion_fee` (0 archivos en 2024; la tarifa de congestión empezó en enero 2025) y `request_source` (solo 2026-06+) |
| `04_cobertura_mensual.sql` | Cada mes de 2024 tiene datos; las fechas caen en el año del archivo | 12 meses con 2.96–3.83 M amarillos y 51–61 mil verdes; ≤ 21 registros por mes con fecha de otro año (los excluye `trips_clean`) |
| `05_comparacion_conjunta.sql` | Comparar 2024 y 2026 en el mismo periodo (ene–ago) | ver tabla abajo |
| `06_calidad_por_anio.sql` | Las reglas de limpieza se comportan igual en ambos años | se excluye 3.9 % (2024) y 5.3 % (2026) de amarillos; 7.0 % y 6.7 % de verdes |

Comparación enero–agosto (`05_comparacion_conjunta.sql`):

| tipo | año | viajes | total mediano | pago sin dato | tarjeta (de los informados) | cargo CBD prom. |
|---|---|---:|---:|---:|---:|---:|
| amarillo | 2024 | 25.4 M | 21.00 USD | 9.0 % | 83.6 % | 0.00 |
| amarillo | 2026 | 28.1 M | 23.58 USD | 25.0 % | 87.2 % | 0.54 |
| verde | 2024 | 412 mil | 19.15 USD | 4.1 % | 70.8 % | 0.00 |
| verde | 2026 | 314 mil | 20.50 USD | 13.6 % | 77.1 % | 0.06 |

Lo que ya se ve con dos años: los amarillos **crecen** (+10.7 %) mientras los verdes **caen** (−23.8 %),
el total mediano sube ~12 % y la proporción de viajes sin método de pago informado casi se triplica.

## 5.7 ¿Hay que modificar las consultas anteriores?

**No hubo que modificar ninguna consulta para que funcione.** Se volvieron a ejecutar las 13 de
exploración y las 12 del EDA sin cambios y todas terminaron sin error sobre 71.9 M de registros
([`resultados/03_exploracion_2024_2026.md`](resultados/03_exploracion_2024_2026.md),
[`resultados/04_eda_2024_2026.md`](resultados/04_eda_2024_2026.md)).

Funcionan porque:

- todas leen con el patrón `*/*.parquet` (o a través de las vistas que lo usan), así que los
  archivos de 2024 entran solos;
- `union_by_name = true` alinea los esquemas. A 2024 le falta `cbd_congestion_fee` y DuckDB la
  rellena con `NULL`, en vez de fallar o desalinear las columnas;
- la regla "fecha dentro del mes del archivo" usa `file_year`/`file_month`, que salen del nombre
  del archivo y no de un año fijo.

Lo que **sí cambia es la interpretación** de las consultas que no separan por año:

- las que agregan todo el periodo (`03_caracteristicas_viaje`, `08_componentes_del_cobro`,
  `09_aeropuertos`) mezclan ahora 2024 y 2026. Por ejemplo, el cargo CBD baja de 1.80 % a 0.77 %
  de la facturación solo porque en 2024 no existía. Para comparar entre años se agrega `file_year`
  al `GROUP BY` (como en `05_comparacion_conjunta.sql` y en los indicadores de los Ejercicios 7 y 8);
- `01_viajes_por_mes`, `04_cobertura_mensual` y `12_viajes_por_app` ya agrupaban por año, así que
  separan los periodos sin cambios;
- comparar 2024 completo contra 2026 parcial sesga los totales, así que las comparaciones entre
  años se hacen sobre **el mismo rango de meses**.

Los resultados documentados del Ejercicio 4 (`resultados/04_eda.md`) se mantienen como la foto
de 2026, y la corrida conjunta se guarda aparte con `run_sql.py --salida`.

## 5.9 ¿Qué permite incorporar archivos sin modificar el flujo?

1. **Año como parámetro** del script de descarga: un año nuevo es un argumento, no código nuevo.
2. **Estructura de carpetas predecible** (`data/raw/<tipo>/<anio>/<archivo>`): el año y el tipo
   se pueden derivar de la ruta.
3. **Globs en lugar de listas de archivos**: `read_parquet('.../yellow/*/*.parquet')` descubre los
   archivos que haya en disco en el momento de la consulta.
4. **Una sola capa de acceso** (`sql/00_views.sql`): el esquema unificado y la limpieza se definen
   una vez. Notebooks, scripts, benchmark y Metabase consultan las vistas, no los archivos.
5. **`union_by_name` + casts explícitos** en la vista: absorben los cambios de esquema entre años
   (columnas nuevas o faltantes, tipos distintos).
6. **Periodo derivado del nombre del archivo** (`file_year`, `file_month`) en vez de constantes.
7. **Descarga idempotente y verificable**: volver a ejecutar es seguro y `--verify` comprueba el
   resultado contra la fuente.
