# Ejercicio 1 - Preparación del ambiente

## 1.1 / 1.2 Fork y clonación

Se realizó el fork de `menene/duckdb` con el nombre `lab8-ds`
(<https://github.com/FerAHMz/lab8-ds>) y se clonó localmente. Se agregó el
repositorio del docente como `upstream` para poder recibir correcciones:

```bash
git clone https://github.com/FerAHMz/lab8-ds.git
cd lab8-ds
git remote add upstream https://github.com/menene/duckdb.git
```

## Estructura del proyecto y propósito de cada directorio

| Directorio / archivo | Propósito |
|---|---|
| `data/raw/` | Archivos Parquet tal como los publica la TLC, organizados como `data/raw/<tipo>/<anio>/`. Es la fuente de verdad: nunca se modifican a mano y no se versionan (se regeneran con el script de descarga). |
| `data/processed/` | Artefactos derivados de los datos crudos: la base materializada `taxis.duckdb` (Ejercicio 6) y cualquier salida intermedia. Tampoco se versiona, porque se puede regenerar. |
| `scripts/` | Código ejecutable del flujo: descarga (`download_data.py`), materialización y benchmark, generación de indicadores. Permite reproducir el proceso sin pasos manuales. |
| `sql/` | Consultas SQL documentadas, una por archivo y agrupadas por ejercicio. Son la "lógica" del análisis y se reutilizan desde notebooks, scripts y Metabase. |
| `notebooks/` | Notebooks de Jupyter donde se ejecutan las consultas, se muestran resultados y se interpretan (exploración, EDA, indicadores). |
| `docs/` | Documentación de cada ejercicio: decisiones, resultados, benchmark, tablero y discusión. |
| `Dockerfile` | Imagen del servicio `lab`: Python 3.11 + DuckDB, JupyterLab, pandas, pyarrow, matplotlib y requests en versiones fijas. |
| `metabase.Dockerfile` | Imagen de Metabase con el driver de DuckDB (sobre Debian, porque el driver requiere glibc). |
| `docker-compose.yml` | Orquesta los dos servicios y monta las carpetas del proyecto dentro de los contenedores. |
| `requirements.txt` | Versiones exactas de las librerías de Python. `duckdb` debe coincidir con el driver de Metabase. |

## 1.2 Levantar el ambiente

Requisitos: Docker con Docker Compose y unos 10 GB libres.

```bash
docker compose up --build -d     # construye las imágenes y levanta los servicios
docker compose ps                # ambos servicios deben aparecer "Up"
```

La primera construcción descarga varios cientos de MB (≈3 GB de imágenes).

## 1.3 Verificación de los servicios

| Servicio | URL | Verificación | Resultado |
|---|---|---|---|
| `lab` (JupyterLab) | <http://127.0.0.1:8888> | `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8888/lab` | `200` |
| `metabase` | <http://127.0.0.1:3000> | `curl -s http://127.0.0.1:3000/api/health` | `{"status":"ok"}` |

Metabase tarda alrededor de un minuto en responder la primera vez mientras
inicializa su base interna.

## 1.4 Herramientas disponibles dentro del ambiente

Obtenidas con `docker compose exec lab sh -c 'python --version; pip list'`:

| Herramienta | Versión | Uso en el laboratorio |
|---|---|---|
| Python | 3.11.14 | Lenguaje de los scripts y notebooks |
| duckdb | 1.5.5 | Motor analítico; consultas sobre Parquet y base materializada |
| JupyterLab | 4.6.4 | Notebooks de exploración y análisis |
| pandas | 3.0.6 | Solo para mostrar resultados ya agregados (`.df()`) |
| pyarrow | 25.0.1 | Lectura de metadatos Parquet y conversión de resultados |
| matplotlib | 3.11.2 | Gráficas en los notebooks |
| requests | 2.34.2 | Descarga de los archivos desde la TLC |
| curl | sistema | Verificaciones HTTP |
| Metabase | v0.63.19 + driver DuckDB 1.5.5.0 | Tablero de indicadores (Ejercicio 7) |

Dentro de los contenedores la carpeta `data/` está montada en `/workspace/data`,
y `scripts/`, `sql/`, `notebooks/` y `docs/` en `/workspace/<carpeta>`.
El contenedor `lab` dispone de 14 núcleos en el equipo donde se hizo el
laboratorio (dato relevante para el benchmark).

## 1.6 ¿Por qué un ambiente reproducible?

- **Mismos resultados en cualquier máquina.** Las versiones de Python, DuckDB,
  pandas, Metabase y el driver están fijadas. Una consulta o un benchmark da el
  mismo resultado (y comparables tiempos) en la computadora de cualquier
  integrante o del catedrático.
- **Compatibilidad entre componentes.** El archivo `.duckdb` que se escribe con
  Python lo lee Metabase; si las versiones no coinciden, el formato de
  almacenamiento puede ser incompatible. Docker garantiza que siempre coinciden.
- **Sin "en mi máquina sí funciona".** Las dependencias del sistema (glibc para
  el driver, certificados, Java 21) vienen en la imagen y no dependen del sistema
  operativo del usuario.
- **Separar código de datos.** Como el ambiente y los scripts están versionados,
  los datos (1.5 GB+) no necesitan estar en Git: se regeneran ejecutando el mismo
  código en el mismo ambiente.
- **Auditabilidad.** Cualquier resultado del reporte puede rastrearse hasta una
  consulta SQL, un script y una versión de herramienta concretos.
