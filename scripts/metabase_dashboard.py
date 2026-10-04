#!/usr/bin/env python3
"""Construye el tablero de indicadores en Metabase a partir de sql/07_indicadores.

Uso (dentro del contenedor `lab`, con Metabase levantado y la base
materializada creada con scripts/build_duckdb.py):
    python scripts/metabase_dashboard.py

Pasos (todos por la API REST de Metabase, de forma idempotente):
  1. Si Metabase no esta inicializado, crea el usuario administrador.
  2. Registra la base DuckDB /workspace/data/processed/taxis.duckdb en modo
     solo lectura (read_only) para no bloquear al resto de procesos.
  3. Crea una pregunta (card) SQL nativa por cada archivo de
     sql/07_indicadores. Las consultas se escriben contra las vistas sobre
     Parquet (trips_clean, zones); aqui se reemplazan por sus equivalentes
     materializados (trips_clean_tbl, zones_tbl) para que el tablero sea rapido.
  4. Crea (o reemplaza) el tablero y acomoda las tarjetas.
  5. Habilita un enlace publico de solo lectura del tablero (para capturarlo
     como evidencia con scripts/capturar_tablero.sh) y lo guarda en
     docs/dashboard/enlace_publico.txt.

Credenciales: variables METABASE_EMAIL y METABASE_PASSWORD (por defecto las de
abajo; la instancia solo escucha en 127.0.0.1).
"""

import os
import re
import sys
import time

import requests

from lab_db import DIR_SQL, RAIZ, leer_consulta

URL = os.environ.get("METABASE_URL", "http://metabase:3000")
EMAIL = os.environ.get("METABASE_EMAIL", "admin@lab8.local")
PASSWORD = os.environ.get("METABASE_PASSWORD", "Lab8-DuckDB-2026")
NOMBRE_DB = "Taxis NYC (DuckDB)"
NOMBRE_TABLERO = "Taxis NYC - Indicadores"
RUTA_DB = "/workspace/data/processed/taxis.duckdb"
DIR_EVIDENCIA = RAIZ / "docs" / "dashboard"

AMARILLO, VERDE = "#EDA100", "#008300"
ANIOS = {"2024": "#2A78D6", "2025": "#EB6834", "2026": "#1BAF7A"}
SERIES_TAXI = {"yellow": {"color": AMARILLO, "title": "Amarillos"},
               "green": {"color": VERDE, "title": "Verdes"}}
SERIES_ANIO = {a: {"color": c} for a, c in ANIOS.items()}

# archivo -> (display, visualization_settings, (col, fila, ancho, alto))
TARJETAS = {
    "00a_kpi_viajes.sql": ("scalar", {"scalar.suffix": " M"}, (0, 0, 12, 3)),
    "00b_kpi_facturacion.sql": ("scalar", {"scalar.prefix": "$", "scalar.suffix": " M"}, (12, 0, 12, 3)),
    "01_viajes_mensuales.sql": ("line", {"graph.dimensions": ["mes", "taxi_type"], "graph.metrics": ["viajes"],
                                         "series_settings": SERIES_TAXI}, (0, 3, 12, 6)),
    "09_participacion_verdes.sql": ("line", {"graph.dimensions": ["mes"], "graph.metrics": ["pct_verdes"],
                                             "series_settings": {"pct_verdes": {"color": VERDE}}}, (12, 3, 12, 6)),
    "02_ticket_mediano.sql": ("line", {"graph.dimensions": ["mes", "taxi_type"], "graph.metrics": ["ticket_mediano_usd"],
                                       "series_settings": SERIES_TAXI}, (0, 9, 12, 6)),
    "06_cargos_congestion.sql": ("area", {"graph.dimensions": ["mes"],
                                          "graph.metrics": ["pct_recargo_congestion", "pct_cargo_cbd"],
                                          "stackable.stack_type": "stacked",
                                          "series_settings": {"pct_recargo_congestion": {"color": "#2A78D6", "title": "Recargo de congestion"},
                                                              "pct_cargo_cbd": {"color": "#EB6834", "title": "Cargo CBD"}}}, (12, 9, 12, 6)),
    "03_uso_efectivo.sql": ("line", {"graph.dimensions": ["mes", "taxi_type"], "graph.metrics": ["pct_efectivo"],
                                     "series_settings": SERIES_TAXI}, (0, 15, 12, 6)),
    "10_pago_sin_dato.sql": ("line", {"graph.dimensions": ["mes", "taxi_type"], "graph.metrics": ["pct_pago_sin_dato"],
                                      "series_settings": SERIES_TAXI}, (12, 15, 12, 6)),
    "05_velocidad_por_hora.sql": ("line", {"graph.dimensions": ["hora", "anio"], "graph.metrics": ["velocidad_mediana_mph"],
                                           "series_settings": SERIES_ANIO}, (0, 21, 12, 6)),
    "04_propina_tarjeta.sql": ("bar", {"graph.dimensions": ["anio", "taxi_type"], "graph.metrics": ["propina_mediana_pct"],
                                       "series_settings": SERIES_TAXI, "graph.show_values": True}, (12, 21, 12, 6)),
    "07_aeropuertos.sql": ("bar", {"graph.dimensions": ["anio"], "graph.metrics": ["pct_viajes", "pct_facturacion"],
                                   "graph.show_values": True,
                                   "series_settings": {"pct_viajes": {"color": "#2A78D6", "title": "% de viajes"},
                                                       "pct_facturacion": {"color": "#EB6834", "title": "% de facturacion"}}}, (0, 27, 12, 7)),
    "08_top_zonas_origen.sql": ("row", {"graph.dimensions": ["zona"], "graph.metrics": ["viajes"],
                                        "series_settings": {"viajes": {"color": "#2A78D6"}}}, (12, 27, 12, 7)),
}


class Metabase:
    def __init__(self, url: str):
        self.url = url
        self.s = requests.Session()

    def api(self, metodo: str, ruta: str, **kw):
        r = self.s.request(metodo, f"{self.url}/api/{ruta}", timeout=300, **kw)
        if not r.ok:
            raise RuntimeError(f"{metodo} {ruta} -> {r.status_code}: {r.text[:500]}")
        return r.json() if r.content and "json" in r.headers.get("Content-Type", "") else r.content

    def esperar(self):
        for _ in range(60):
            try:
                if self.s.get(f"{self.url}/api/health", timeout=5).json().get("status") == "ok":
                    return
            except requests.RequestException:
                pass
            time.sleep(5)
        raise RuntimeError("Metabase no respondio")

    def iniciar_sesion(self):
        props = self.api("GET", "session/properties")
        if not props.get("has-user-setup"):
            print("inicializando Metabase (usuario administrador)")
            self.api("POST", "setup", json={
                "token": props["setup-token"],
                "user": {"email": EMAIL, "password": PASSWORD, "first_name": "Lab8", "last_name": "Admin",
                         "site_name": "Lab 8 DuckDB"},
                "prefs": {"site_name": "Lab 8 DuckDB", "allow_tracking": False},
            })
        sesion = self.api("POST", "session", json={"username": EMAIL, "password": PASSWORD})
        self.s.headers["X-Metabase-Session"] = sesion["id"]


def main() -> int:
    mb = Metabase(URL)
    mb.esperar()
    mb.iniciar_sesion()

    # 2. base de datos DuckDB (solo lectura)
    bases = mb.api("GET", "database")["data"]
    base = next((b for b in bases if b["name"] == NOMBRE_DB), None)
    detalles = {"database_file": RUTA_DB, "read_only": True, "old_implicit_casting": True}
    if base is None:
        base = mb.api("POST", "database", json={"engine": "duckdb", "name": NOMBRE_DB, "details": detalles})
        print(f"base registrada: {NOMBRE_DB} (id {base['id']})")
    else:
        mb.api("PUT", f"database/{base['id']}", json={"details": detalles})
    db_id = base["id"]

    # 4a. tablero: se elimina el anterior (y sus tarjetas) para reconstruirlo
    for d in mb.api("GET", "dashboard/"):
        if d["name"] == NOMBRE_TABLERO:
            for dc in mb.api("GET", f"dashboard/{d['id']}")["dashcards"]:
                if dc.get("card_id"):
                    mb.api("DELETE", f"card/{dc['card_id']}")
            mb.api("DELETE", f"dashboard/{d['id']}")
    tablero = mb.api("POST", "dashboard", json={
        "name": NOMBRE_TABLERO,
        "description": "Indicadores de viajes de taxis amarillos y verdes de NYC (TLC). "
                       "Fuente: data/processed/taxis.duckdb. Consultas en sql/07_indicadores.",
    })

    # 3. una tarjeta por indicador
    dashcards = []
    for i, (archivo, (display, ajustes, (col, fila, ancho, alto))) in enumerate(TARJETAS.items(), start=1):
        consulta = leer_consulta(DIR_SQL / "07_indicadores" / archivo)
        sql = re.sub(r"\btrips_clean\b", "trips_clean_tbl", consulta["sql"])
        sql = re.sub(r"\bzones\b", "zones_tbl", sql)
        nombre = consulta["meta"].get("indicador", archivo).rstrip(".")
        card = mb.api("POST", "card", json={
            "name": nombre,
            "description": consulta["meta"].get("pregunta"),
            "display": display,
            "visualization_settings": ajustes,
            "dataset_query": {"type": "native", "database": db_id, "native": {"query": sql}},
        })
        dashcards.append({"id": -i, "card_id": card["id"], "col": col, "row": fila,
                          "size_x": ancho, "size_y": alto})
        print(f"  tarjeta {card['id']:>3}: {nombre}")

    mb.api("PUT", f"dashboard/{tablero['id']}", json={"dashcards": dashcards})
    print(f"tablero: {URL.replace('metabase', '127.0.0.1')}/dashboard/{tablero['id']}")

    # 5. enlace publico de solo lectura (evidencia / captura)
    mb.api("PUT", "setting/enable-public-sharing", json={"value": True})
    uuid = mb.api("POST", f"dashboard/{tablero['id']}/public_link")["uuid"]
    enlace = f"http://127.0.0.1:3000/public/dashboard/{uuid}"
    DIR_EVIDENCIA.mkdir(parents=True, exist_ok=True)
    (DIR_EVIDENCIA / "enlace_publico.txt").write_text(enlace + "\n")
    print(f"enlace publico: {enlace}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
