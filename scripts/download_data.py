#!/usr/bin/env python3
"""Descarga los archivos Parquet del NYC TLC Trip Record Data.

Descarga los registros de viajes de taxis amarillos (yellow) y verdes (green)
para uno o varios anios. Los anios se reciben como parametro (--years); si no
se indican se usan los de ANIOS_POR_DEFECTO.

Fuente oficial de los datos:
    https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

Uso:
    python scripts/download_data.py                       # anios por defecto, ambos tipos
    python scripts/download_data.py --years 2026          # un solo anio
    python scripts/download_data.py --years 2024 2026     # varios anios
    python scripts/download_data.py --taxi green --years 2026

Los archivos se guardan en:
    data/raw/<tipo>/<anio>/<nombre-original>.parquet

Comportamiento:
  - La TLC publica cada mes con varias semanas de atraso, por lo que no todos
    los meses del anio en curso existen todavia. El script consulta al servidor que
    meses estan publicados en lugar de suponerlos.
  - Un archivo que ya existe localmente no se vuelve a descargar.
  - La descarga se hace sobre un nombre temporal y solo se renombra al
    terminar, de modo que una interrupcion no deja archivos .parquet a medias.
  - Con --verify no se descarga nada: se compara cada archivo local contra el
    servidor (publicado / tamanio en bytes) y se valida que el Parquet sea
    legible leyendo su metadata. El resultado se guarda en un manifiesto CSV
    (docs/manifest_descarga.csv) que si se versiona.
  - Ademas descarga la tabla de referencia de zonas de taxi de la TLC
    (data/raw/reference/taxi_zone_lookup.csv), necesaria para traducir
    PULocationID / DOLocationID a borough y zona.
"""

import argparse
import csv
import sys
from pathlib import Path

import pyarrow.parquet as pq
import requests

# Anios que se descargan cuando no se pasa --years.
ANIOS_POR_DEFECTO = (2026,)
TIPOS_TAXI = ("yellow", "green")
URL_BASE = "https://d37ci6vzurychx.cloudfront.net/trip-data"
DIR_DESTINO = Path("data/raw")

TIEMPO_ESPERA = 60          # segundos por peticion
INTENTOS = 3                # intentos por archivo antes de darse por vencido
BLOQUE = 1024 * 1024        # 1 MiB por bloque de descarga
SUFIJO_TEMPORAL = ".part"
MANIFIESTO = Path("docs/manifest_descarga.csv")
URL_ZONAS = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"
DESTINO_ZONAS = DIR_DESTINO / "reference" / "taxi_zone_lookup.csv"


def construir_nombre(tipo: str, anio: int, mes: int) -> str:
    """Nombre del archivo publicado por la TLC, p. ej. yellow_tripdata_2026-01.parquet."""
    return f"{tipo}_tripdata_{anio}-{mes:02d}.parquet"


def construir_url(tipo: str, anio: int, mes: int) -> str:
    """URL completa del archivo Parquet mensual."""
    return f"{URL_BASE}/{construir_nombre(tipo, anio, mes)}"


def ruta_destino(tipo: str, anio: int, mes: int) -> Path:
    """Ruta local donde se guarda el archivo."""
    return DIR_DESTINO / tipo / str(anio) / construir_nombre(tipo, anio, mes)


def esta_publicado(url: str) -> bool:
    """Indica si el archivo existe en el servidor (sin descargarlo)."""
    return tamanio_remoto(url) is not None


def tamanio_remoto(url: str) -> int | None:
    """Tamanio en bytes publicado por el servidor, o None si no esta publicado."""
    try:
        respuesta = requests.head(url, timeout=TIEMPO_ESPERA, allow_redirects=True)
    except requests.RequestException:
        return None
    if not respuesta.ok:
        return None
    return int(respuesta.headers.get("Content-Length", -1))


def formato_tamanio(n: float) -> str:
    for unidad in ("B", "KiB", "MiB", "GiB"):
        if n < 1024 or unidad == "GiB":
            return f"{n:.1f} {unidad}"
        n /= 1024
    return f"{n:.1f} GiB"


def descargar_archivo(url: str, destino: Path) -> int:
    """Descarga `url` en `destino`. Devuelve la cantidad de bytes escritos."""
    destino.parent.mkdir(parents=True, exist_ok=True)
    temporal = destino.with_name(destino.name + SUFIJO_TEMPORAL)

    ultimo_error = None
    for intento in range(1, INTENTOS + 1):
        try:
            with requests.get(url, stream=True, timeout=TIEMPO_ESPERA) as respuesta:
                respuesta.raise_for_status()
                escritos = 0
                with temporal.open("wb") as archivo:
                    for bloque in respuesta.iter_content(chunk_size=BLOQUE):
                        if bloque:
                            archivo.write(bloque)
                            escritos += len(bloque)
            if escritos == 0:
                raise requests.RequestException("el servidor devolvio un archivo vacio")
            temporal.replace(destino)
            return escritos
        except requests.RequestException as error:
            ultimo_error = error
            temporal.unlink(missing_ok=True)
            if intento < INTENTOS:
                print(f"      intento {intento}/{INTENTOS} fallido ({error}); reintentando")

    raise requests.RequestException(f"no se pudo descargar {url}: {ultimo_error}")


def descargar(tipo: str, anio: int) -> dict:
    """Descarga todos los meses publicados de un tipo de taxi para un anio."""
    print(f"\n=== {tipo.upper()} {anio} ===")
    resumen = {"descargados": 0, "omitidos": 0, "no_publicados": [], "fallidos": []}

    for mes in range(1, 13):
        etiqueta = f"{anio}-{mes:02d}"
        destino = ruta_destino(tipo, anio, mes)

        if destino.exists() and destino.stat().st_size > 0:
            print(f"  {etiqueta}  ya existe, se omite")
            resumen["omitidos"] += 1
            continue

        url = construir_url(tipo, anio, mes)
        if not esta_publicado(url):
            print(f"  {etiqueta}  aun no publicado por la TLC")
            resumen["no_publicados"].append(etiqueta)
            continue

        print(f"  {etiqueta}  descargando...")
        try:
            escritos = descargar_archivo(url, destino)
        except requests.RequestException as error:
            print(f"  {etiqueta}  ERROR: {error}")
            resumen["fallidos"].append(etiqueta)
        else:
            print(f"  {etiqueta}  listo ({formato_tamanio(escritos)}) -> {destino}")
            resumen["descargados"] += 1

    return resumen


def descargar_referencias() -> None:
    """Descarga la tabla de zonas de la TLC si no existe localmente."""
    if DESTINO_ZONAS.exists() and DESTINO_ZONAS.stat().st_size > 0:
        print(f"\nzonas: ya existe {DESTINO_ZONAS}")
        return
    escritos = descargar_archivo(URL_ZONAS, DESTINO_ZONAS)
    print(f"\nzonas: listo ({formato_tamanio(escritos)}) -> {DESTINO_ZONAS}")


def verificar(tipos: tuple, anios: list) -> int:
    """Compara los archivos locales con los publicados y escribe el manifiesto.

    Un archivo se considera correcto si esta publicado, existe localmente, su
    tamanio coincide byte a byte con el Content-Length del servidor y pyarrow
    puede leer su metadata (numero de filas y de row groups).
    """
    filas = []
    problemas = 0
    for anio in anios:
        for tipo in tipos:
            print(f"\n=== VERIFICAR {tipo.upper()} {anio} ===")
            for mes in range(1, 13):
                url = construir_url(tipo, anio, mes)
                destino = ruta_destino(tipo, anio, mes)
                remoto = tamanio_remoto(url)
                local = destino.stat().st_size if destino.exists() else None
                registros = None

                if remoto is None and local is None:
                    estado = "no_publicado"
                elif remoto is not None and local is None:
                    estado = "FALTANTE"
                elif remoto is not None and local != remoto:
                    estado = "TAMANIO_DISTINTO"
                else:
                    try:
                        registros = pq.ParquetFile(destino).metadata.num_rows
                        estado = "ok"
                    except Exception as error:  # archivo corrupto o truncado
                        estado = f"ILEGIBLE ({error})"

                if estado not in ("ok", "no_publicado"):
                    problemas += 1
                print(f"  {anio}-{mes:02d}  {estado:<16} local={local} remoto={remoto} filas={registros}")
                filas.append({
                    "tipo": tipo, "anio": anio, "mes": mes,
                    "archivo": construir_nombre(tipo, anio, mes),
                    "estado": estado, "bytes_local": local, "bytes_remoto": remoto,
                    "registros": registros,
                })

    MANIFIESTO.parent.mkdir(parents=True, exist_ok=True)
    with MANIFIESTO.open("w", newline="") as archivo:
        escritor = csv.DictWriter(archivo, fieldnames=list(filas[0]))
        escritor.writeheader()
        escritor.writerows(filas)

    correctos = sum(f["estado"] == "ok" for f in filas)
    print("\n" + "=" * 60)
    print(f"  archivos correctos : {correctos}")
    print(f"  no publicados      : {sum(f['estado'] == 'no_publicado' for f in filas)}")
    print(f"  con problemas      : {problemas}")
    print(f"  registros totales  : {sum(f['registros'] or 0 for f in filas):,}")
    print(f"  manifiesto         : {MANIFIESTO}")
    print("=" * 60)
    return 1 if problemas else 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Descarga los datos de taxis amarillos y verdes del NYC TLC."
    )
    parser.add_argument(
        "--taxi", choices=(*TIPOS_TAXI, "all"), default="all",
        help="tipo de taxi a descargar (por defecto: all)",
    )
    parser.add_argument(
        "--years", type=int, nargs="+", default=list(ANIOS_POR_DEFECTO),
        metavar="ANIO",
        help=f"anios a descargar (por defecto: {' '.join(map(str, ANIOS_POR_DEFECTO))})",
    )
    parser.add_argument(
        "--verify", action="store_true",
        help="no descarga: verifica los archivos locales contra el servidor",
    )
    argumentos = parser.parse_args()

    tipos = TIPOS_TAXI if argumentos.taxi == "all" else (argumentos.taxi,)
    if argumentos.verify:
        return verificar(tipos, sorted(set(argumentos.years)))

    descargar_referencias()

    total = {"descargados": 0, "omitidos": 0, "no_publicados": [], "fallidos": []}
    for anio in sorted(set(argumentos.years)):
        for tipo in tipos:
            resumen = descargar(tipo, anio)
            total["descargados"] += resumen["descargados"]
            total["omitidos"] += resumen["omitidos"]
            total["no_publicados"] += [f"{tipo} {m}" for m in resumen["no_publicados"]]
            total["fallidos"] += [f"{tipo} {m}" for m in resumen["fallidos"]]

    print("\n" + "=" * 60)
    print("RESUMEN")
    print("=" * 60)
    print(f"  descargados   : {total['descargados']}")
    print(f"  ya existian   : {total['omitidos']}")
    print(f"  no publicados : {len(total['no_publicados'])}")
    if total["no_publicados"]:
        print(f"      {', '.join(total['no_publicados'])}")
    print(f"  fallidos      : {len(total['fallidos'])}")
    if total["fallidos"]:
        print(f"      {', '.join(total['fallidos'])}")
    print("=" * 60)

    return 1 if total["fallidos"] else 0


if __name__ == "__main__":
    sys.exit(main())
