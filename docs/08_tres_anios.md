# Ejercicio 8 - Incorporación de 2025 y análisis completo

## 8.1 Cambio al sistema de descarga

Igual que con 2024, se cambió una línea:

```diff
-ANIOS_POR_DEFECTO = (2024, 2026)
+ANIOS_POR_DEFECTO = (2024, 2025, 2026)
```

`docker compose exec lab python scripts/download_data.py` reproduce ahora el conjunto completo:
taxis amarillos y verdes de 2024, 2025 y 2026.

## 8.2 No se re-descargan archivos existentes

| ejecución | descargados | ya existían | no publicados | fallidos |
|---|---:|---:|---:|---:|
| primera con 2025 | 24 (2025-01 a 2025-12, ambos tipos) | 40 (2024 y 2026) | 8 | 0 |
| segunda (idempotencia) | 0 | 64 | 8 | 0 |

`--verify`: **64 archivos correctos, 0 con problemas, 121,184,384 registros**
([manifiesto](manifest_descarga.csv)). Por año: 2024 = 41.8 M, 2025 = 49.3 M, 2026 (ene–ago) = 30.0 M.

## 8.3 ¿Las consultas siguen funcionando?

Se volvieron a ejecutar **todas** las carpetas de consultas sobre los tres años:

| carpeta | consultas | resultado |
|---|---:|---|
| `sql/03_exploracion` | 13 | sin cambios ✔ — [resultados](resultados/03_exploracion_2024_2025_2026.md) |
| `sql/04_eda` | 12 | sin cambios ✔ — [resultados](resultados/04_eda_2024_2025_2026.md) |
| `sql/05_validacion` | 6 | 1 modificada (ver abajo) — [resultados](resultados/05_validacion_2024_2025_2026.md) |
| `sql/07_indicadores` | 12 | sin cambios ✔ — [resultados](resultados/07_indicadores_2024_2025_2026.md) |

Cambios que sí fueron necesarios:

1. **`05_validacion/03_columnas_por_anio.sql`** tenía columnas fijas `archivos_2024` y `archivos_2026`, así
   que con un tercer año quedaba incompleta. Se reescribió de forma genérica: agrupa por el año
   que aparece en la ruta y lista en qué años existe cada columna. Ahora sirve para cualquier
   cantidad de años. Fue la única consulta con un año fijo en el código.
2. **Materialización** (`build_duckdb.py`, `benchmark.py`): con 121 M de filas el
   `CREATE TABLE ... ORDER BY pickup_at` agotaba la memoria de la VM de Docker y el proceso moría.
   Se cambió por `materializar_trips()` ([`scripts/lab_db.py`](../scripts/lab_db.py)), que inserta
   mes por mes ordenando cada mes. El resultado sigue ordenado por periodo y además es más rápido
   (51.6 s para 121 M de filas, contra 57 s para 72 M antes).
3. **Recursos, no código:** las consultas con cuantiles **exactos** (`quantile_cont`) necesitan tener
   todos los valores en memoria y no pueden derramar a disco. Con 116 M de viajes, `04_eda/03` llegó
   a ~4–5 GB y, con Metabase ocupando 2.9 GB en la misma VM de 8 GB, el contenedor fue terminado. Para
   las corridas pesadas se detiene Metabase (`docker compose stop metabase`). La alternativa
   escalable es `approx_quantile`, que usa memoria acotada (ver Ejercicio 9).

Ninguna consulta de análisis ni indicador tuvo que cambiar para incluir 2025, porque todo lee los
Parquet por glob y el año sale de la ruta del archivo.

## 8.4 Indicadores y tablero actualizados

```bash
docker compose exec lab python scripts/build_duckdb.py         # 121 M filas, 3.96 GiB
docker compose exec lab python scripts/metabase_dashboard.py   # mismo script, sin cambios
bash scripts/capturar_tablero.sh docs/dashboard/tablero_2024_2025_2026.png
```

El tablero se actualizó **sin modificar ninguna consulta ni el script**: basta con reconstruir la
base materializada y volver a crear las tarjetas. Captura:
[`dashboard/tablero_2024_2025_2026.png`](dashboard/tablero_2024_2025_2026.png). El hueco que
había en 2025 en las series mensuales ahora está completo.

## 8.5 / 8.7 Evolución de los indicadores

Consultas en [`sql/08_evolucion/`](../sql/08_evolucion/), resultados en
[`resultados/08_evolucion.md`](resultados/08_evolucion.md), gráficas en
[`notebooks/08_evolucion_3_anios.ipynb`](../notebooks/08_evolucion_3_anios.ipynb).

Para comparar años se usa **el mismo periodo, enero–agosto**, porque 2026 solo tiene esos meses
(`01_resumen_anual.sql`):

| indicador (ene–ago) | 2024 | 2025 | 2026 |
|---|---:|---:|---:|
| viajes amarillos | 25.42 M | **28.60 M (+12.5 %)** | 28.13 M (−1.6 %) |
| viajes verdes | 412 mil | 369 mil (−10.6 %) | 314 mil (−14.7 %) |
| ticket mediano amarillo | 21.00 | 21.61 (+2.9 %) | **23.58 (+9.1 %)** |
| distancia mediana amarillo (mi) | 1.80 | 1.88 | 1.94 |
| % efectivo (de informados) amarillo | 15.1 % | 12.4 % | 12.0 % |
| % efectivo (de informados) verde | 28.9 % | 24.8 % | 22.7 % |
| % sin método de pago amarillo | 9.0 % | 19.7 % | **25.0 %** |
| propina mediana con tarjeta amarillo | 25.9 % | 26.7 % | 26.4 % |
| cargo CBD promedio por viaje amarillo | 0.00 | 0.55 | 0.54 |

Otros indicadores del tablero:

- **Aeropuertos (amarillos):** 10.1 % de los viajes y 27.8 % de la facturación en 2024; 8.8 % y 24.1 %
  en 2025; 8.1 % y 20.9 % en 2026 (2026 solo tiene ene–ago).
- **Cargos de congestión:** el recargo de congestión baja de ~7.3 % de la facturación (2024) a ~6 %
  (2025) y ~5.6 % (2026), mientras el cargo CBD se mantiene en ~1.9 % desde enero de 2025.
- **Participación de verdes:** 1.8 % (ene-2024) → 1.36 % (ene-2025) → 1.07 % (ene-2026).

## 8.6 Cambios y patrones visibles al ver los tres años juntos

1. **Los amarillos crecieron en 2025 y se estancaron en 2026; los verdes caen sin pausa.**
   Todos los meses de 2025 superan al mismo mes de 2024 (+3.8 % a +17.6 %), y en 2026 la mayoría
   de los meses queda por debajo de 2025 (−5.8 % a +0.1 %; solo enero crece, +8.1 %). Los verdes
   pierden 10–15 % por año. Con solo 2024 y 2026 (Ej. 5) se veía un "+10.7 %" para los amarillos y
   no se notaba que todo el crecimiento ocurrió en 2025.
2. **El peaje de congestión de Manhattan (5 de enero de 2025) se ve en los cobros, no en la
   velocidad.** Desde enero de 2025, entre 66 % y 80 % de los viajes amarillos dentro de Manhattan
   pagan el cargo CBD, y el recargo de congestión pierde peso relativo. Pero la velocidad mediana de
   esos viajes (lunes a viernes, 7–19 h) promedia **7.89 mph en ene–ago 2024, 7.88 en 2025 y 7.45 en
   2026**: no hay mejora visible en los taxis y en 2026 es incluso menor. El precio sube (+9 % de
   ticket en 2026) sin que el viaje sea más rápido.
3. **La calidad del dato de pago se deteriora año tras año y tiene un origen identificable.** Los
   viajes amarillos sin método de pago pasan de 9 % a 20 % y a 25 %. `04_canales_y_proveedores.sql`
   muestra que el aumento viene del **VendorID 2** (10 % → 26 % → 28 % sin dato), que tiene ~80 % de
   los viajes. En los verdes, el **VendorID 6** (100 % sin dato) pasa de 0 % a 4.6 % y a 10.3 % de los
   viajes. Sin separar por año y proveedor, esto parecería un cambio de comportamiento de los
   pasajeros cuando en realidad es un cambio en cómo reportan los proveedores.
4. **El efectivo sigue bajando** en ambos tipos, también cuando se mide solo sobre los pagos
   informados, así que no se explica por el aumento de "sin dato".
5. **La dependencia de los aeropuertos baja de forma sostenida** (27.8 % → 24.1 % → 20.9 % de la
   facturación), mientras los viajes totales crecen: el crecimiento de 2025 vino de viajes urbanos.
