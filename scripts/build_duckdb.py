#!/usr/bin/env python3
"""Materializa los datos descargados en una base DuckDB (Ejercicio 6.2).

Uso (dentro del contenedor `lab`):
    python scripts/build_duckdb.py

Crea data/processed/taxis.duckdb con:
  - las vistas de sql/00_views.sql (siguen leyendo los Parquet: yellow_raw,
    green_raw, trips, trips_clean, zones);
  - trips_tbl: tabla con el contenido de la vista `trips` (todos los anios en
    disco), cargada mes por mes y ordenada por fecha de recogida;
  - zones_tbl: copia de la tabla de zonas;
  - trips_clean_tbl: las mismas reglas de limpieza que trips_clean, pero sobre
    la tabla materializada.

La base se reconstruye desde cero en cada ejecucion (se escribe en un archivo
temporal y se renombra al final), de modo que siempre refleja lo que hay en
data/raw. Metabase la abre en modo solo lectura.
"""

import sys
import time

from lab_db import BASE_MATERIALIZADA, VISTAS, connect, materializar_trips

REGLAS_LIMPIEZA = VISTAS.read_text().split("CREATE OR REPLACE VIEW trips_clean AS")[1].split(";")[0]


def main() -> int:
    BASE_MATERIALIZADA.parent.mkdir(parents=True, exist_ok=True)
    temporal = BASE_MATERIALIZADA.with_suffix(".duckdb.tmp")
    temporal.unlink(missing_ok=True)

    con = connect(temporal)
    inicio = time.perf_counter()
    materializar_trips(con, "trips_tbl")
    con.execute("CREATE TABLE zones_tbl AS SELECT * FROM zones")
    # trips_clean_tbl = mismas reglas que trips_clean, leyendo la tabla
    con.execute("CREATE OR REPLACE VIEW trips_clean_tbl AS"
                + REGLAS_LIMPIEZA.replace("FROM trips", "FROM trips_tbl"))
    con.execute("CHECKPOINT")
    segundos = time.perf_counter() - inicio

    filas = con.sql("SELECT count(*) FROM trips_tbl").fetchone()[0]
    por_anio = con.sql("SELECT file_year, count(*) FROM trips_tbl GROUP BY 1 ORDER BY 1").fetchall()
    con.close()
    temporal.replace(BASE_MATERIALIZADA)

    tamanio = BASE_MATERIALIZADA.stat().st_size / 1024**3
    print(f"base materializada: {BASE_MATERIALIZADA}")
    print(f"  filas en trips_tbl : {filas:,}")
    for anio, n in por_anio:
        print(f"    {anio}: {n:,}")
    print(f"  tiempo             : {segundos:.1f} s")
    print(f"  tamanio            : {tamanio:.2f} GiB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
