# Ejercicio 7 - Indicadores y tablero

- Consultas: [`sql/07_indicadores/`](../sql/07_indicadores/), una por indicador; el encabezado trae la pregunta, el indicador y la visualización.
- Tablero: Metabase (la herramienta del ambiente), construido por
  [`scripts/metabase_dashboard.py`](../scripts/metabase_dashboard.py).
- Evidencia: [`docs/dashboard/tablero.png`](dashboard/tablero.png) (captura con
  [`scripts/capturar_tablero.sh`](../scripts/capturar_tablero.sh)).
- Tablas de cada indicador: [`notebooks/07_indicadores.ipynb`](../notebooks/07_indicadores.ipynb) y
  [`resultados/07_indicadores.md`](resultados/07_indicadores.md).

```bash
docker compose exec lab python scripts/build_duckdb.py          # base que lee Metabase
docker compose exec lab python scripts/metabase_dashboard.py    # crea el tablero
bash scripts/capturar_tablero.sh                                # (host) captura PNG
```

Tablero: <http://127.0.0.1:3000> → "Taxis NYC - Indicadores" (usuario `admin@lab8.local`, contraseña
`Lab8-DuckDB-2026`; se pueden cambiar con `METABASE_EMAIL` y `METABASE_PASSWORD`).

## Cómo están conectados los datos con el tablero

1. Las consultas se escriben **una sola vez** contra las vistas lógicas (`trips_clean`, `zones`).
2. En el notebook se ejecutan sobre los Parquet. En Metabase, el script cambia `trips_clean` →
   `trips_clean_tbl` y `zones` → `zones_tbl` (las mismas reglas, sobre la tabla materializada) y
   crea cada tarjeta como **pregunta SQL nativa**.
3. Metabase abre `taxis.duckdb` con `read_only = true`. Así no bloquea el archivo y
   `build_duckdb.py` puede reconstruirlo (escribe un temporal y lo renombra).
4. El script es idempotente: si se ejecuta otra vez, reemplaza el tablero y sus tarjetas.

Se materializa porque el tablero repite las mismas 12 consultas cada vez que alguien lo abre:
es justo el escenario de "consultas repetidas sobre datos estables" del Ejercicio 6.

## 7.1 Preguntas

1. ¿Cómo evoluciona la demanda de taxis mes a mes y por tipo?
2. ¿Cuánto paga un pasajero en un viaje típico y cómo cambia en el tiempo?
3. ¿Se está dejando de usar el efectivo?
4. ¿Qué tan generosos son con la propina los pasajeros que pagan con tarjeta?
5. ¿A qué hora es más lenta la ciudad y cambió la congestión entre años?
6. ¿Cuánto pesan los cargos por congestión en lo que paga el pasajero?
7. ¿Qué tan dependientes son los taxis amarillos de los viajes de aeropuerto?
8. ¿Dónde se concentra la demanda?
9. ¿Qué peso tienen los taxis verdes en el total de viajes y está cambiando?
10. ¿Qué tan confiable es el dato del método de pago?
11. ¿Cuántos viajes válidos y cuánta facturación hay en el periodo? (contexto, KPI)

## 7.2 / 7.6 Indicadores, visualización y justificación

| # | Indicador (archivo) | Visualización | Por qué se eligió |
|---|---|---|---|
| K1 | Total de viajes válidos (`00a_kpi_viajes`) | número | Da la escala del periodo; un solo valor se lee mejor como cifra que como gráfica. |
| K2 | Facturación total (`00b_kpi_facturacion`) | número | Ídem en dinero. |
| 1 | Viajes por mes y tipo (`01_viajes_mensuales`) | líneas | Medida básica de demanda; las líneas muestran la estacionalidad y la tendencia. |
| 2 | Ticket mediano por mes y tipo (`02_ticket_mediano`) | líneas | Precio real del viaje típico; se usa mediana porque el total tiene colas extremas (Ej. 3). |
| 3 | % efectivo sobre pagos informados (`03_uso_efectivo`) | líneas | Mide la digitalización del pago; se calcula **sobre los informados** para que el aumento de "sin dato" no lo distorsione. |
| 4 | Propina mediana % con tarjeta (`04_propina_tarjeta`) | barras agrupadas | Compara pocas categorías (año × tipo); la propina solo se registra con tarjeta. |
| 5 | Velocidad mediana por hora, días laborales (`05_velocidad_por_hora`) | líneas por año | Indicador directo de congestión; con una línea por año se ve si el patrón diario cambió. |
| 6 | % de la facturación por recargo de congestión y cargo CBD (`06_cargos_congestion`) | área apilada | Son partes de un todo (cargos de congestión) y el área apilada muestra cómo uno sustituye al otro. |
| 7 | % viajes y % facturación de aeropuertos (`07_aeropuertos`) | barras agrupadas | Poner juntas las dos medidas muestra el desbalance entre volumen e ingreso. |
| 8 | Top 10 zonas de origen (`08_top_zonas_origen`) | barras horizontales | Ranking con nombres largos: las barras horizontales se leen mejor. |
| 9 | % de viajes hechos por verdes (`09_participacion_verdes`) | línea | Al ser 90 veces menor que los amarillos, en el indicador 1 los verdes quedan aplastados; aquí se ve su tendencia. |
| 10 | % de viajes sin método de pago (`10_pago_sin_dato`) | líneas | Indicador de calidad de datos que condiciona la lectura de los indicadores 3 y 4. |

El tablero se organiza de arriba hacia abajo: escala (KPI), demanda (1, 9), precio y cargos
(2, 6), pagos (3, 10), operación (5, 4) y geografía (7, 8). Los amarillos y verdes usan siempre
su color (amarillo/verde; paleta validada para daltonismo con ΔE 16) y cada gráfica tiene leyenda.

## 7.8 Interpretación (con 2024 y 2026; ver Ejercicio 8 para los tres años)

- **K1/K2:** 68.6 M viajes válidos y 2,003 M USD facturados en 20 meses.
- **Demanda (1, 9):** los amarillos se mueven entre 2.9 y 4.0 M de viajes al mes, con una caída
  en julio–agosto. Los verdes bajan de **1.8 % a ~1.1 %** del total entre 2024 y 2026; se reduce
  su volumen, no solo su proporción.
- **Precio (2):** el ticket mediano de los amarillos pasa de ~20 USD (2024-01) a ~23.6 USD en 2026.
  Parte de la subida es el cargo CBD de 0.75 USD por viaje en Manhattan.
- **Cargos de congestión (6):** en 2024 el recargo de congestión era ~7–8 % de la facturación. En
  2026 aparece el cargo CBD (~1.8 %) y el recargo baja a ~5.5 %. El total de cargos queda parecido
  (~7.5 %), pero cambia su composición.
- **Efectivo (3):** baja de forma sostenida en ambos tipos. En verdes pasa de 30 % a ~23 % de los
  pagos informados y en amarillos de 15 % a ~13 %.
- **Calidad del dato (10):** el porcentaje de viajes amarillos sin método de pago sube de 4 % (2024-01) a
  **28 %** (2026-01). Es el cambio más grande del tablero y obliga a leer los indicadores de pago
  solo sobre los viajes informados.
- **Velocidad (5):** el perfil diario es casi idéntico en 2024 y 2026: ~17 mph a las 4:00 y ~7.5 mph
  entre 11:00 y 16:00. Con estos dos años no se ve un efecto del peaje de congestión sobre la
  velocidad mediana de los taxis.
- **Propinas (4):** estables. Amarillos ~26 % y verdes ~23.5 % de la tarifa en ambos años.
- **Aeropuertos (7):** su peso cae de 10.1 % de los viajes y 27.8 % de la facturación (2024) a
  8.1 % y 20.9 % (2026). Los amarillos dependen menos de los aeropuertos.
- **Zonas (8):** la demanda se concentra en Midtown y el Upper East Side; JFK y LaGuardia son las
  únicas zonas fuera de Manhattan en el top 10.
