#!/usr/bin/env python3
"""Benchmark: consultar Parquet directamente vs. tabla materializada en DuckDB.

Uso (dentro del contenedor `lab`):
    python scripts/benchmark.py                 # todos los escenarios disponibles
    python scripts/benchmark.py --repeticiones 3 --escenarios 1_mes 2026

Para cada escenario (cantidad de datos):
  1. modo `parquet`: conexion en memoria con las vistas de sql/00_views.sql
     apuntando solo a los archivos del escenario;
  2. modo `tabla`: base DuckDB nueva (data/processed/bench/<escenario>.duckdb)
     donde `trips` y `zones` se materializan como tablas; las vistas
     trips_clean y las consultas son exactamente las mismas.
  3. cada consulta se ejecuta una vez "en frio" (primera) y luego N veces;
     se reporta la mediana de las N.

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

import pandas as pd

from lab_db import DIR_SQL, RAIZ, VISTAS, a_markdown, connect, leer_consulta

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

        # modo parquet: vistas sobre los archivos
        con_parquet = connect(vistas=False)
        con_parquet.execute(texto_vistas)
        registros = con_parquet.sql("SELECT count(*) FROM trips").fetchone()[0]
        bytes_parquet = sum(f.stat().st_size for t in ("yellow", "green")
                            for p in ESCENARIOS[escenario] for f in (RAIZ / "data/raw" / t).glob(p))

        # modo tabla: misma definicion, pero trips/zones materializadas
        ruta_db = DIR_BENCH / f"{escenario}.duckdb"
        ruta_db.unlink(missing_ok=True)
        con_tabla = connect(ruta_db, vistas=False)
        con_tabla.execute(texto_vistas)
        t0 = time.perf_counter()
        con_tabla.execute("CREATE TABLE trips_mat AS SELECT * FROM trips ORDER BY pickup_at")
        con_tabla.execute("CREATE TABLE zones_mat AS SELECT * FROM zones")
        con_tabla.execute("CREATE OR REPLACE VIEW trips AS SELECT * FROM trips_mat")
        con_tabla.execute("CREATE OR REPLACE VIEW zones AS SELECT * FROM zones_mat")
        con_tabla.execute("CHECKPOINT")
        seg_materializar = time.perf_counter() - t0
        materializacion.append({
            "escenario": escenario, "registros": registros,
            "mb_parquet": round(bytes_parquet / 1024**2, 1),
            "mb_duckdb": round(ruta_db.stat().st_size / 1024**2, 1),
            "segundos_materializar": round(seg_materializar, 2),
        })
        print(f"  {registros:,} registros | materializar: {seg_materializar:.1f} s")

        for consulta in consultas:
            for modo, con in (("parquet", con_parquet), ("tabla", con_tabla)):
                r = medir(con, consulta["sql"], args.repeticiones)
                filas.append({"escenario": escenario, "registros": registros,
                              "consulta": consulta["archivo"], "modo": modo,
                              **{k: round(v, 4) for k, v in r.items()}})
                print(f"  {consulta['archivo']:<32} {modo:<8} primera {r['primera_s']:7.3f} s"
                      f" | mediana {r['mediana_s']:7.3f} s")

        con_parquet.close()
        con_tabla.close()
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
