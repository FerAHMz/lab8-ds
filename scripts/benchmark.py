#!/usr/bin/env python3
"""Benchmark: consultar Parquet directamente vs. tabla materializada en DuckDB.

Uso (dentro del contenedor `lab`):
    python scripts/benchmark.py                 # todos los escenarios disponibles
    python scripts/benchmark.py --repeticiones 3 --escenarios 1_mes 2026
    python scripts/benchmark.py --escenarios 2024+2025+2026 --omitir tabla:03_caracteristicas_viaje.sql

--omitir modo:consulta registra esa combinacion como no ejecutada (NaN). Se usa
cuando el proceso no cabe en la RAM de la VM de Docker: los cuantiles exactos
(quantile_cont) no respetan memory_limit y el kernel termina el proceso, por lo
que no se puede capturar como excepcion.

Para cada escenario (cantidad de datos):
  1. modo `tabla`: base DuckDB nueva (data/processed/bench/<escenario>.duckdb)
     donde `trips` y `zones` se materializan como tablas; las vistas
     trips_clean y las consultas son exactamente las mismas;
  2. modo `parquet`: conexion en memoria con las vistas de sql/00_views.sql
     apuntando solo a los archivos del escenario;
  3. cada consulta se ejecuta una vez "en frio" (primera) y luego N veces;
     se reporta la mediana de las N. Solo hay una conexion abierta a la vez.

Las consultas son archivos .sql del laboratorio (ver CONSULTAS); el texto es
identico en ambos modos, solo cambia a que objeto apunta la vista `trips`.

Salidas en docs/benchmark/: resultados.csv, materializacion.csv y resultados.md
"""

import argparse
import csv
import statistics
import sys
import time
from pathlib import Path

import duckdb
import pandas as pd

from lab_db import DIR_SQL, RAIZ, VISTAS, a_markdown, connect, leer_consulta, materializar_trips

DIR_RAW = "/workspace/data/raw"
DIR_BENCH = RAIZ / "data" / "processed" / "bench"
DIR_SALIDA = RAIZ / "docs" / "benchmark"

# escenario -> patrones relativos a data/raw/<tipo>/ (tamanios crecientes)
ESCENARIOS = {
    "1_mes": ["2026/*2026-08.parquet"],
    "2026": ["2026/*.parquet"],
    "2024+2026": ["2024/*.parquet", "2026/*.parquet"],
    "2024+2025+2026": ["2024/*.parquet", "2025/*.parquet", "2026/*.parquet"],
}

CONSULTAS = [
    DIR_SQL / "06_benchmark" / "b01_conteo_total.sql",
    DIR_SQL / "06_benchmark" / "b02_filtro_un_dia.sql",
    DIR_SQL / "04_eda" / "01_viajes_por_mes.sql",
    DIR_SQL / "04_eda" / "02_hora_y_dia.sql",
    DIR_SQL / "04_eda" / "03_caracteristicas_viaje.sql",
    DIR_SQL / "04_eda" / "06_metodo_de_pago.sql",
    DIR_SQL / "04_eda" / "08_componentes_del_cobro.sql",
    DIR_SQL / "04_eda" / "09_aeropuertos.sql",
]


def escenario_disponible(patrones: list) -> bool:
    raiz = RAIZ / "data" / "raw"
    return all(any((raiz / t).glob(p)) for t in ("yellow", "green") for p in patrones)


def vistas_para(patrones: list) -> str:
    """Texto de 00_views.sql con los globs restringidos a los archivos del escenario."""
    texto = VISTAS.read_text()
    for tipo in ("yellow", "green"):
        lista = ", ".join(f"'{DIR_RAW}/{tipo}/{p}'" for p in patrones)
        original = f"'{DIR_RAW}/{tipo}/*/*.parquet'"
        assert original in texto
        texto = texto.replace(original, f"[{lista}]")
    return texto


def medir(con, sql: str, repeticiones: int) -> dict:
    t0 = time.perf_counter()
    con.sql(sql).fetchall()
    primera = time.perf_counter() - t0
    tiempos = []
    for _ in range(repeticiones):
        t0 = time.perf_counter()
        con.sql(sql).fetchall()
        tiempos.append(time.perf_counter() - t0)
    return {"primera_s": primera, "mediana_s": statistics.median(tiempos),
            "min_s": min(tiempos), "max_s": max(tiempos)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--repeticiones", type=int, default=5)
    parser.add_argument("--escenarios", nargs="+", choices=list(ESCENARIOS))
    parser.add_argument("--omitir", nargs="*", default=[], metavar="MODO:CONSULTA",
                        help="combinaciones a no ejecutar, p. ej. tabla:03_caracteristicas_viaje.sql")
    parser.add_argument("--conservar", action="store_true",
                        help="no borrar las bases de cada escenario al terminar")
    args = parser.parse_args()

    nombres = args.escenarios or [e for e, p in ESCENARIOS.items() if escenario_disponible(p)]
    DIR_BENCH.mkdir(parents=True, exist_ok=True)
    DIR_SALIDA.mkdir(parents=True, exist_ok=True)
    consultas = [leer_consulta(c) for c in CONSULTAS]
    filas, materializacion = [], []

    for escenario in nombres:
        texto_vistas = vistas_para(ESCENARIOS[escenario])
        print(f"\n=== escenario {escenario} ===")

        # modo tabla: misma definicion, pero trips/zones materializadas
        ruta_db = DIR_BENCH / f"{escenario}.duckdb"
        ruta_db.unlink(missing_ok=True)
        con = connect(ruta_db, vistas=False)
        con.execute(texto_vistas)
        registros = con.sql("SELECT count(*) FROM trips").fetchone()[0]
        t0 = time.perf_counter()
        materializar_trips(con, "trips_mat")
        con.execute("CREATE TABLE zones_mat AS SELECT * FROM zones")
        con.execute("CREATE OR REPLACE VIEW trips AS SELECT * FROM trips_mat")
        con.execute("CREATE OR REPLACE VIEW zones AS SELECT * FROM zones_mat")
        con.execute("CHECKPOINT")
        seg_materializar = time.perf_counter() - t0
        con.close()
        bytes_parquet = sum(f.stat().st_size for t in ("yellow", "green")
                            for p in ESCENARIOS[escenario] for f in (RAIZ / "data/raw" / t).glob(p))
        materializacion.append({
            "escenario": escenario, "registros": registros,
            "mb_parquet": round(bytes_parquet / 1024**2, 1),
            "mb_duckdb": round(ruta_db.stat().st_size / 1024**2, 1),
            "segundos_materializar": round(seg_materializar, 2),
        })
        print(f"  {registros:,} registros | materializar: {seg_materializar:.1f} s")

        # Los modos se miden por separado (una sola conexion abierta a la vez):
        # con 100+ M de filas, dos conexiones con cuantiles exactos superan la RAM de la VM.
        for modo in ("parquet", "tabla"):
            if modo == "parquet":
                con = connect(vistas=False)
                con.execute(texto_vistas)
            else:
                con = connect(ruta_db, vistas=False)
            for consulta in consultas:
                if f"{modo}:{consulta['archivo']}" in args.omitir:
                    print(f"  {consulta['archivo']:<32} {modo:<8} OMITIDA (no cabe en memoria)")
                    filas.append({"escenario": escenario, "registros": registros,
                                  "consulta": consulta["archivo"], "modo": modo,
                                  **{k: float("nan") for k in ("primera_s", "mediana_s", "min_s", "max_s")}})
                    continue
                try:
                    r = medir(con, consulta["sql"], args.repeticiones)
                except duckdb.OutOfMemoryException:
                    # se registra como resultado: la consulta no cabe en memoria en este modo
                    r = {k: float("nan") for k in ("primera_s", "mediana_s", "min_s", "max_s")}
                    print(f"  {consulta['archivo']:<32} {modo:<8} SIN MEMORIA")
                    filas.append({"escenario": escenario, "registros": registros,
                                  "consulta": consulta["archivo"], "modo": modo, **r})
                    continue
                filas.append({"escenario": escenario, "registros": registros,
                              "consulta": consulta["archivo"], "modo": modo,
                              **{k: round(v, 4) for k, v in r.items()}})
                print(f"  {consulta['archivo']:<32} {modo:<8} primera {r['primera_s']:7.3f} s"
                      f" | mediana {r['mediana_s']:7.3f} s")
            con.close()

        if not args.conservar:
            ruta_db.unlink(missing_ok=True)

    sufijo = "" if args.escenarios is None else "_" + "_".join(nombres)
    with open(DIR_SALIDA / f"resultados{sufijo}.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(filas[0]))
        w.writeheader(); w.writerows(filas)
    with open(DIR_SALIDA / f"materializacion{sufijo}.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(materializacion[0]))
        w.writeheader(); w.writerows(materializacion)

    df = pd.DataFrame(filas)
    tabla = df.pivot_table(index=["consulta", "escenario"], columns="modo",
                           values="mediana_s", sort=False).reset_index()
    tabla["parquet/tabla"] = (tabla["parquet"] / tabla["tabla"]).round(2)
    md = ["# Resultados del benchmark", "",
          f"Generado por `scripts/benchmark.py` ({args.repeticiones} repeticiones, mediana en segundos).", "",
          "## Materializacion", "", a_markdown(pd.DataFrame(materializacion)), "",
          "## Tiempo mediano por consulta", "", a_markdown(tabla, 200), ""]
    (DIR_SALIDA / f"resultados{sufijo}.md").write_text("\n".join(md))
    print(f"\nresultados en {DIR_SALIDA.relative_to(RAIZ)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
