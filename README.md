# Lab 8 - DuckDB

Repositorio base del laboratorio 8 del curso **CC3084 - Data Science**
(Universidad del Valle de Guatemala, Ciclo 2, 2026).

Este es el repositorio **proporcionado por el docente**. Contiene la estructura
del proyecto, el ambiente de ejecucion basado en Docker y un script que descarga
los datos de **2026**. Todo lo demas debe ser construido por cada equipo.

## Trabajo con fork

El laboratorio se desarrolla y se entrega sobre un **fork** de este repositorio.
No se trabaja directamente sobre el repositorio del docente.

1. Realice un fork de este repositorio:
   <https://github.com/menene/duckdb>

2. Clone **su propio fork** (no el del docente):

   ```bash
   git clone https://github.com/<su-usuario>/duckdb.git
   cd duckdb
   ```

3. Opcional, para recibir correcciones publicadas por el docente:

   ```bash
   git remote add upstream https://github.com/menene/duckdb.git
   git fetch upstream
   ```

Realice commits frecuentes y descriptivos: el historial del repositorio es parte
de la evaluacion. **La entrega del laboratorio es la URL de su fork.**

## Estructura

```text
duckdb/
|
+-- data/
|   +-- raw/
|   +-- processed/
|
+-- notebooks/
|
+-- scripts/
|
+-- sql/
|
+-- docs/
|
+-- Dockerfile
+-- metabase.Dockerfile
+-- docker-compose.yml
+-- README.md
```

## Requisitos

- Docker, con Docker Compose
- Git

La primera construccion del ambiente descarga varios cientos de MB y puede
tardar algunos minutos.

Considere el espacio en disco: las imagenes de Docker ocupan unos 3 GB y los
datos de los tres anios del laboratorio superan 1.5 GB, a los que se suma la
base materializada del Ejercicio 6. Se recomienda tener al menos 10 GB libres.

## Datos

El repositorio incluye `scripts/download_data.py`, que descarga los archivos de
2026 publicados por la TLC (`--help` muestra las opciones disponibles). Los
archivos se guardan en `data/raw/<tipo>/<anio>/`.

La TLC publica cada mes con varias semanas de atraso, por lo que los ultimos
meses de 2026 todavia no existen. El script consulta al servidor que meses estan
publicados, de modo que vuelve a ejecutarse sin problema conforme aparezcan
nuevos archivos.

Los datos descargados **no deben incluirse en el repositorio Git**. El archivo
`.gitignore` ya esta configurado para evitarlo.

Fuente de datos: NYC TLC Trip Record Data
<https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page>

Dentro de los contenedores, la carpeta `data/` del proyecto esta montada en
`/workspace/data`. Esa es la ruta que deben usar las herramientas que corren
dentro del ambiente, no la ruta de su computadora.

> **Nota sobre DuckDB:** un archivo `.duckdb` admite un solo proceso con permiso
> de escritura a la vez. Si conecta una herramienta externa a su base de datos,
> use el modo de solo lectura (`read_only`) en esa conexion; de lo contrario los
> demas procesos no podran abrir el archivo.

## Material a entregar

Al finalizar, su fork debe contener:

- el codigo fuente modificado y los scripts de descarga;
- las consultas SQL desarrolladas;
- el notebook o notebooks utilizados;
- la documentacion de las consultas;
- los scripts utilizados para los benchmarks;
- el codigo de los indicadores y visualizaciones;
- el tablero o la evidencia del tablero desarrollado;
- este `README.md`, completado segun la siguiente seccion.

Los archivos de datos descargados **no** deben incluirse.

---

# Documentacion del equipo

Las siguientes secciones deben ser completadas por cada equipo. El README final
debe permitir que una persona que no participo en el desarrollo pueda levantar el
ambiente, descargar los datos, ejecutar el analisis, reproducir los benchmarks y
generar los resultados principales.

## Como levantar el ambiente

Requisitos: Docker con Docker Compose, Git y al menos 10 GB libres.

```bash
git clone https://github.com/FerAHMz/lab8-ds.git
cd lab8-ds
docker compose up --build -d
docker compose ps            # lab8-lab y lab8-metabase deben estar "Up"
```

| Servicio | URL | Comprobacion |
|---|---|---|
| JupyterLab (`lab`) | <http://127.0.0.1:8888> | `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8888/lab` devuelve `200` |
| Metabase (`metabase`) | <http://127.0.0.1:3000> | `curl -s http://127.0.0.1:3000/api/health` devuelve `{"status":"ok"}` |

Todos los comandos de Python del laboratorio se ejecutan **dentro** del
contenedor `lab`, por ejemplo `docker compose exec lab python scripts/download_data.py`.
Para detener el ambiente: `docker compose down` (los datos en `data/` se conservan).

Detalle de la estructura, herramientas disponibles y justificacion del ambiente
reproducible: [docs/01_ambiente.md](docs/01_ambiente.md).

## Como descargar los datos

```bash
# descarga los anios por defecto (ANIOS_POR_DEFECTO) y omite lo que ya existe
docker compose exec lab python scripts/download_data.py

# opciones
docker compose exec lab python scripts/download_data.py --years 2024            # un anio
docker compose exec lab python scripts/download_data.py --taxi green --years 2026

# verificar completitud contra el servidor de la TLC (no descarga nada)
docker compose exec lab python scripts/download_data.py --verify
```

Por defecto se descargan taxis amarillos y verdes de **2024, 2025 y 2026** (64 archivos,
~2 GB, 121 M de registros) mas la tabla de zonas de la TLC.
Los archivos quedan en `data/raw/<tipo>/<anio>/` y el modo `--verify` escribe
[docs/manifest_descarga.csv](docs/manifest_descarga.csv). Cambios al script y
criterios de completitud: [docs/02_descarga.md](docs/02_descarga.md).

## Como ejecutar el analisis

Todas las consultas estan en `sql/`, un archivo por consulta con su pregunta,
objetivo y fuente en el encabezado. `sql/00_views.sql` define las vistas sobre
los Parquet (`trips`, `trips_clean`, `zones`) y se carga automaticamente con
`scripts/lab_db.connect()`.

**Opcion A - notebooks** (JupyterLab en <http://127.0.0.1:8888>, carpeta `notebooks/`):

| Notebook | Ejercicio |
|---|---|
| `03_exploracion_parquet.ipynb` | 3 - consultas directas sobre Parquet y calidad de datos |
| `04_eda.ipynb` | 4 - analisis exploratorio (12 preguntas, graficas, hallazgos) |
| `06_benchmark.ipynb` | 6 - Parquet vs. tabla DuckDB (lee los CSV del benchmark) |
| `07_indicadores.ipynb` | 7 - tablas de los indicadores del tablero |
| `08_evolucion_3_anios.ipynb` | 8 - evolucion 2024-2025-2026 |

Para re-ejecutar uno sin abrir el navegador:

```bash
docker compose exec lab sh -c 'cd notebooks && jupyter nbconvert --to notebook --execute --inplace 04_eda.ipynb'
```

**Opcion B - por carpeta de consultas**, documentando los resultados en `docs/resultados/`:

```bash
docker compose exec lab python scripts/run_sql.py sql/03_exploracion
docker compose exec lab python scripts/run_sql.py sql/04_eda
docker compose exec lab python scripts/run_sql.py sql/05_validacion
docker compose exec lab python scripts/run_sql.py sql/07_indicadores
docker compose exec lab python scripts/run_sql.py sql/08_evolucion
# --salida <nombre> guarda el resultado con otro nombre (p. ej. para comparar anios)
```

> **Memoria:** la VM de Docker Desktop suele tener 8 GB y Metabase usa ~3 GB.
> Las consultas con cuantiles exactos sobre los tres anios (`04_eda/03`,
> `08_evolucion/01`) necesitan ~4-5 GB: detenga Metabase mientras se ejecutan
> (`docker compose stop metabase` / `docker compose start metabase`) o asigne mas
> memoria a Docker. El limite de DuckDB se ajusta con `LAB_MEMORY_LIMIT` (por defecto `3GB`).

## Como reproducir los benchmarks

```bash
docker compose stop metabase                                  # libera memoria para medir
docker compose exec lab python scripts/benchmark.py           # escenarios 1 mes, 2026, 2024+2026 (+3 anios si existe 2025)
docker compose exec lab python scripts/benchmark.py --escenarios 2024+2025+2026 \
    --omitir tabla:03_caracteristicas_viaje.sql               # escenario de 3 anios en una VM de 8 GB
docker compose start metabase
```

Salidas en `docs/benchmark/` (`resultados*.csv`, `materializacion*.csv`,
`resultados*.md`); el notebook `06_benchmark.ipynb` las grafica. Analisis en
[docs/06_benchmark.md](docs/06_benchmark.md).

## Como generar los resultados principales

Secuencia completa desde cero (con el ambiente levantado):

```bash
docker compose exec lab python scripts/download_data.py            # 1. datos 2024-2026
docker compose exec lab python scripts/download_data.py --verify   # 2. completitud
docker compose exec lab python scripts/build_duckdb.py             # 3. base materializada (~1 min, ~4 GB)
docker compose exec lab python scripts/metabase_dashboard.py       # 4. tablero en Metabase
bash scripts/capturar_tablero.sh                                   # 5. (host) captura PNG del tablero
```

El tablero queda en <http://127.0.0.1:3000> -> "Taxis NYC - Indicadores"
(usuario `admin@lab8.local`, contrasena `Lab8-DuckDB-2026`, configurables con
`METABASE_EMAIL` / `METABASE_PASSWORD`; la instancia solo escucha en 127.0.0.1).

## Documentacion por ejercicio

| Ejercicio | Documento |
|---|---|
| 1 - Ambiente | [docs/01_ambiente.md](docs/01_ambiente.md) |
| 2 - Descarga | [docs/02_descarga.md](docs/02_descarga.md) |
| 3 - Consultas directas sobre Parquet | [docs/03_exploracion.md](docs/03_exploracion.md) |
| 4 - Analisis exploratorio | [docs/04_eda.md](docs/04_eda.md) |
| 5 - Incorporacion de 2024 | [docs/05_incorporacion_2024.md](docs/05_incorporacion_2024.md) |
| 6 - Parquet vs. tablas DuckDB | [docs/06_benchmark.md](docs/06_benchmark.md) |
| 7 - Indicadores y tablero | [docs/07_indicadores.md](docs/07_indicadores.md) |
| 8 - 2025 y analisis completo | [docs/08_tres_anios.md](docs/08_tres_anios.md) |
| 9 - Discusion | [docs/09_discusion.md](docs/09_discusion.md) |
| Diccionario de datos | [docs/codebook.md](docs/codebook.md) |

## Organizacion del codigo

```text
scripts/
  download_data.py        descarga + verificacion (--years, --taxi, --verify)
  lab_db.py               conexion DuckDB con vistas, limites de memoria, utilidades
  run_sql.py              ejecuta una carpeta de .sql y documenta resultados
  build_duckdb.py         materializa data/processed/taxis.duckdb
  benchmark.py            Parquet directo vs. tabla, por escenario
  metabase_dashboard.py   crea el tablero en Metabase por API
  capturar_tablero.sh     captura PNG del tablero (host)
sql/
  00_views.sql            vistas: yellow_raw, green_raw, trips, trips_clean, zones
  03_exploracion/  04_eda/  05_validacion/  06_benchmark/  07_indicadores/  08_evolucion/
docs/
  NN_*.md                 documentacion por ejercicio
  resultados/             salidas de run_sql.py (SQL + tabla de resultados)
  benchmark/              CSV y tabla del benchmark
  dashboard/              capturas del tablero
  manifest_descarga.csv   archivos, bytes y registros descargados
```

## Equipo

- Fernando Rueda
- Fernando Hernandez
