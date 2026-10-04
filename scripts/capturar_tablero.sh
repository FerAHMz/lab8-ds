#!/usr/bin/env bash
# Captura el tablero publico de Metabase como PNG (evidencia del Ejercicio 7).
# Se ejecuta en el HOST (no en el contenedor), despues de
# `docker compose exec lab python scripts/metabase_dashboard.py`.
#
#   bash scripts/capturar_tablero.sh [archivo_salida.png]
set -euo pipefail
cd "$(dirname "$0")/.."
SALIDA="${1:-docs/dashboard/tablero.png}"
ENLACE="$(cat docs/dashboard/enlace_publico.txt)"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
[ -x "$CHROME" ] || CHROME="$(command -v google-chrome || command -v chromium)"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --window-size=1600,1900 \
  --virtual-time-budget=60000 --screenshot="$PWD/$SALIDA" "$ENLACE" >/dev/null 2>&1
echo "captura guardada en $SALIDA"
