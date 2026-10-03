#!/usr/bin/env python3
"""Ejecuta las consultas .sql de una carpeta y documenta sus resultados.

Uso (dentro del contenedor `lab`):
    python scripts/run_sql.py sql/03_exploracion
    python scripts/run_sql.py sql/04_eda --db data/processed/taxis.duckdb

Por cada archivo escribe en docs/resultados/<carpeta>.md:
el encabezado de la consulta (objetivo, fuente, ...), el SQL, el tiempo de
ejecucion y la tabla de resultados. Asi la documentacion de resultados se
regenera siempre a partir del mismo codigo.
"""

import argparse
import sys
from pathlib import Path

import pandas as pd

from lab_db import RAIZ, a_markdown, connect, leer_consulta, run_query_file

DIR_RESULTADOS = RAIZ / "docs" / "resultados"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("carpeta", type=Path, help="carpeta con archivos .sql")
    parser.add_argument("--db", default=":memory:",
                        help="base DuckDB a usar (por defecto: en memoria + vistas sobre Parquet)")
    parser.add_argument("--max-filas", type=int, default=40)
    args = parser.parse_args()

    carpeta = args.carpeta if args.carpeta.is_absolute() else RAIZ / args.carpeta
    archivos = sorted(carpeta.glob("*.sql"))
    if not archivos:
        print(f"no hay archivos .sql en {carpeta}")
        return 1

    pd.set_option("display.width", 160)
    con = connect(args.db)
    salida = [f"# Resultados de `{carpeta.relative_to(RAIZ)}`",
              "",
              "Generado por `scripts/run_sql.py` (no editar a mano).",
              ""]

    for ruta in archivos:
        consulta = leer_consulta(ruta)
        df, segundos = run_query_file(con, ruta)
        print(f"\n### {ruta.name}  ({segundos:.2f} s, {len(df)} filas)")
        print(df.head(args.max_filas).to_string(index=False))

        salida += [f"## {ruta.name}", ""]
        for clave, valor in consulta["meta"].items():
            salida.append(f"- **{clave.capitalize()}:** {valor}")
        salida += ["", "```sql", consulta["sql"], "```", "",
                   f"Tiempo: {segundos:.2f} s · filas devueltas: {len(df)}", "",
                   a_markdown(df, args.max_filas), ""]

    DIR_RESULTADOS.mkdir(parents=True, exist_ok=True)
    destino = DIR_RESULTADOS / f"{carpeta.name}.md"
    destino.write_text("\n".join(salida))
    print(f"\nresultados documentados en {destino.relative_to(RAIZ)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
