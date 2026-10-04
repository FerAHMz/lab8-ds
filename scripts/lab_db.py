"""Utilidades compartidas para trabajar con DuckDB en el laboratorio.

    from lab_db import connect, run_query_file

`connect()` abre una conexion (en memoria por defecto) y crea las vistas de
sql/00_views.sql, de modo que todas las consultas leen los Parquet de la misma
forma desde notebooks, scripts y benchmark.
"""

import os
import re
import time
from pathlib import Path

import duckdb

RAIZ = Path(__file__).resolve().parents[1]
DIR_SQL = RAIZ / "sql"
VISTAS = DIR_SQL / "00_views.sql"
BASE_MATERIALIZADA = RAIZ / "data" / "processed" / "taxis.duckdb"
DIR_TEMPORAL = RAIZ / "data" / "processed" / ".duckdb_tmp"

# La VM de Docker comparte la RAM con Metabase; un limite explicito evita que el
# contenedor sea terminado por falta de memoria y obliga a DuckDB a derramar a
# disco (DIR_TEMPORAL) en operaciones grandes como ORDER BY o CREATE TABLE.
LIMITE_MEMORIA = os.environ.get("LAB_MEMORY_LIMIT", "3GB")


def connect(database: str | Path = ":memory:", read_only: bool = False,
            vistas: bool = True) -> duckdb.DuckDBPyConnection:
    """Conexion DuckDB con las vistas del laboratorio ya creadas."""
    con = duckdb.connect(str(database), read_only=read_only)
    con.execute(f"SET memory_limit = '{LIMITE_MEMORIA}'")
    con.execute(f"SET temp_directory = '{DIR_TEMPORAL}'")
    con.execute("SET preserve_insertion_order = false")
    if vistas and not read_only:
        con.execute(VISTAS.read_text())
    return con


def leer_consulta(ruta: Path) -> dict:
    """Separa un archivo .sql en su encabezado (comentarios `-- Clave: valor`) y el SQL."""
    texto = Path(ruta).read_text()
    meta = {}
    for clave, valor in re.findall(r"^--\s*([A-Za-zÁÉÍÓÚáéíóúñ ]+):\s*(.+)$", texto, re.M):
        meta[clave.strip().lower()] = valor.strip()
    sql = "\n".join(l for l in texto.splitlines() if not l.lstrip().startswith("--")).strip()
    return {"archivo": Path(ruta).name, "meta": meta, "sql": sql, "texto": texto}


def run_query_file(con: duckdb.DuckDBPyConnection, ruta: Path):
    """Ejecuta una consulta de un archivo y devuelve (DataFrame, segundos)."""
    consulta = leer_consulta(ruta)
    inicio = time.perf_counter()
    df = con.sql(consulta["sql"]).df()
    return df, time.perf_counter() - inicio


def a_markdown(df, max_filas: int = 40) -> str:
    """Tabla Markdown sin dependencias externas."""
    df = df.head(max_filas)

    def fmt(v):
        if isinstance(v, float):
            return f"{v:,.2f}"
        if isinstance(v, int):
            return f"{v:,}"
        return str(v).replace("|", "\\|")

    columnas = [str(c) for c in df.columns]
    lineas = ["| " + " | ".join(columnas) + " |",
              "|" + "---|" * len(columnas)]
    for fila in df.itertuples(index=False):
        lineas.append("| " + " | ".join(fmt(v) for v in fila) + " |")
    return "\n".join(lineas)


def materializar_trips(con: duckdb.DuckDBPyConnection, destino: str, origen: str = "trips") -> None:
    """Crea `destino` como tabla con el contenido de `origen`, ordenada por pickup_at.

    En lugar de un ORDER BY sobre todo el conjunto (que con 100+ M de filas
    agota la memoria de la VM de Docker), inserta mes por mes ordenando cada
    mes. Como los meses se insertan en orden, la tabla queda ordenada por
    periodo y las zonemaps de pickup_at siguen siendo efectivas.
    """
    con.execute(f"CREATE OR REPLACE TABLE {destino} AS SELECT * FROM {origen} LIMIT 0")
    periodos = con.sql(f"SELECT DISTINCT file_year, file_month FROM {origen} ORDER BY ALL").fetchall()
    for anio, mes in periodos:
        con.execute(f"INSERT INTO {destino} SELECT * FROM {origen} "
                    f"WHERE file_year = {anio} AND file_month = {mes} ORDER BY pickup_at")
