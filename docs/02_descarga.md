# Ejercicio 2 - Sistema de descarga

## 2.1 Análisis del script proporcionado

`scripts/download_data.py` ya resolvía bien varias cosas:

- consulta al servidor (petición `HEAD`) si un mes está publicado en lugar de suponerlo;
- omite archivos que ya existen localmente con tamaño > 0;
- descarga sobre un archivo `.part` y lo renombra al terminar (una interrupción no deja Parquet a medias);
- reintenta 3 veces cada archivo y devuelve código de salida 1 si algo falla.

Lo que lo hacía **incompleto** para el laboratorio:

| Problema | Dónde | Consecuencia |
|---|---|---|
| El año estaba fijo en una constante global `ANIO = 2026` | inicio del archivo y todas las funciones (`construir_nombre`, `construir_url`, `ruta_destino`, `descargar`) | Para descargar 2024 o 2025 había que editar el código y se perdía la posibilidad de pedir varios años en una sola ejecución. |
| No había forma de verificar la descarga | — | Solo se sabía "qué se intentó", no si lo que hay en disco coincide con lo publicado ni si los archivos son legibles. |

## 2.2 / 2.6 Cambios realizados

1. **Años como parámetro** (`--years`). La constante `ANIO` se reemplazó por
   `ANIOS_POR_DEFECTO` y el año pasa como argumento a `construir_nombre`,
   `construir_url`, `ruta_destino` y `descargar`. `main()` recorre
   `años × tipos`. Así, incorporar un año nuevo no requiere tocar la lógica:
   basta con `--years <anio>` o agregarlo a `ANIOS_POR_DEFECTO`.
2. **Modo `--verify`.** No descarga nada; para cada tipo, año y mes:
   - obtiene el `Content-Length` publicado por la TLC (`HEAD`);
   - compara con el tamaño local **byte a byte**;
   - abre el Parquet con `pyarrow` y lee su metadata (número de filas), lo que
     detecta archivos truncados o corruptos;
   - escribe `docs/manifest_descarga.csv` (este archivo sí se versiona porque
     solo contiene metadatos, no datos) y termina con código 1 si hay
     faltantes, tamaños distintos o archivos ilegibles.

Se mantuvieron sin cambios el `.part` temporal, los reintentos, la omisión de
archivos existentes y la estructura `data/raw/<tipo>/<anio>/<archivo original>`.

## 2.3 Estructura resultante

```text
data/raw/
├── green/2026/green_tripdata_2026-01.parquet ... 2026-08.parquet
└── yellow/2026/yellow_tripdata_2026-01.parquet ... 2026-08.parquet
```

## 2.4 / 2.5 Ejecución

```bash
docker compose exec lab python scripts/download_data.py --years 2026
```

Primera ejecución: `descargados: 16, ya existian: 0, no publicados: 8, fallidos: 0`
(≈ 497 MB; los amarillos pesan ~60 MB/mes y los verdes ~1 MB/mes).

Segunda ejecución (idempotencia, requisito 2.4):
`descargados: 0, ya existian: 16, no publicados: 8, fallidos: 0` y termina en
segundos porque no hace ninguna petición `GET`.

## 2.7 ¿Cómo se determinó que el conjunto está completo?

```bash
docker compose exec lab python scripts/download_data.py --years 2026 --verify
```

Criterios usados:

1. **Cobertura de meses.** Se consultan los 12 meses posibles al servidor. Los
   meses 2026-01 a 2026-08 responden `200` y existen localmente; 2026-09 a
   2026-12 responden `403` en la CDN de la TLC (aún no publicados, la TLC
   publica con ~2 meses de atraso). No hay ningún mes publicado sin descargar.
2. **Integridad byte a byte.** Para los 16 archivos, `bytes_local == bytes_remoto`.
3. **Legibilidad.** `pyarrow` leyó la metadata de los 16 archivos sin error.
4. **Conteo de registros.** El total de filas reportado por la metadata
   (30,040,469) coincide con `SELECT count(*)` hecho con DuckDB sobre los mismos
   archivos (ver Ejercicio 3).

Resultado: `archivos correctos: 16 | no publicados: 8 | con problemas: 0`.
El detalle por archivo está en [`manifest_descarga.csv`](manifest_descarga.csv).
Como el script consulta al servidor en cada ejecución, cuando la TLC publique
septiembre de 2026 bastará con volver a ejecutarlo para completar el año.
