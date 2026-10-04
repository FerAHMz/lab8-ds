# Ejercicio 4 - Análisis exploratorio con DuckDB

- Consultas: [`sql/04_eda/`](../sql/04_eda/), una por pregunta. El encabezado de cada archivo trae la pregunta, el objetivo y la fuente.
- Notebook con las gráficas: [`notebooks/04_eda.ipynb`](../notebooks/04_eda.ipynb).
- SQL completo, tiempos y tablas de resultados: [`docs/resultados/04_eda.md`](resultados/04_eda.md)
  (se regeneran con `docker compose exec lab python scripts/run_sql.py sql/04_eda`).

Todas las consultas usan la vista `trips_clean` ([`sql/00_views.sql`](../sql/00_views.sql)), que
lee directamente los Parquet y aplica las reglas de calidad definidas en el Ejercicio 3. Los
borough y zonas vienen de la tabla oficial de zonas de la TLC (`taxi_zone_lookup.csv`), que
descarga el mismo script de descarga. Periodo analizado: **enero–agosto 2026**
(28,449,042 viajes válidos).

## 4.1 Preguntas y su justificación

| # | Pregunta | Por qué se plantea a partir de los datos |
|---|---|---|
| 1 | ¿Cómo evoluciona la cantidad de viajes mes a mes, y igual para ambos tipos? | Los datos llegan como archivos mensuales; hay que conocer la estacionalidad antes de comparar periodos. |
| 2 | ¿En qué horas y días se concentran los viajes? | Cada viaje tiene `pickup_at` con precisión de segundos. |
| 3 | ¿Qué tan largos y caros son los viajes típicos? | `trip_distance`, duración y `total_amount` tienen colas extremas (Ej. 3), por eso se usan medianas. |
| 4 | ¿Cómo cambia la velocidad a lo largo del día? | Distancia ÷ duración es un indicador directo de congestión. |
| 5 | ¿Dónde recogen pasajeros amarillos y verdes? | Los verdes (Boro Taxis) tienen restricción geográfica legal; `PULocationID` permite verificarlo. |
| 6 | ¿Qué métodos de pago se usan? | `payment_type` tiene 26 % de "0 / no informado" en amarillos (Ej. 3). |
| 7 | ¿Cuánta propina se deja con tarjeta y cuándo? | La propina solo se registra con tarjeta (muestras del Ej. 3). |
| 8 | ¿De qué se compone el cobro? | El total suma 8 componentes, incluido el nuevo `cbd_congestion_fee`. |
| 9 | ¿Qué peso tienen los viajes de aeropuerto? | Tienen tarifa plana y recargos propios (`Airport_fee`, `RatecodeID = 2`). |
| 10 | ¿Cómo se distribuye el total por viaje? | Para elegir umbrales y saber si promedio o mediana describen bien al viaje típico. |
| 11 | ¿Quedan atípicos en los datos limpios? | Las reglas del Ej. 3 son amplias; hace falta comprobar qué queda dentro. |
| 12 | ¿Qué proporción de viajes se pide por apps de alto volumen? | `request_source` es una columna nueva (desde 2026-06). |

## 4.2 – 4.4 Consultas y resultados

### P1 · Viajes por mes — `01_viajes_por_mes.sql`

Calcula los viajes por mes y un índice con enero = 100 (función de ventana `first() OVER`), lo
que permite comparar en la misma escala dos series que difieren 90 veces en volumen.

| mes | amarillos | índice | verdes | índice |
|---|---:|---:|---:|---:|
| ene | 3,504,830 | 100.0 | 37,755 | 100.0 |
| feb | 3,199,918 | 91.3 | 34,829 | 92.3 |
| may | 3,898,999 | **111.2** | 42,023 | **111.3** |
| ago | 3,152,409 | **89.9** | 37,754 | 100.0 |

**Interpretación:** ambos tipos suben hasta mayo, que es el pico. Febrero es bajo sobre todo por
tener 28 días: en viajes por día es similar a enero. En el verano (julio–agosto) los amarillos
caen 10 % por debajo de enero y los verdes no. La demanda de amarillos está más ligada a
oficinas y turismo en Manhattan, que bajan en verano.

### P2 · Hora y día de la semana — `02_hora_y_dia.sql`

Porcentaje de los viajes de cada tipo que cae en cada combinación día × hora (heatmap del notebook).

**Interpretación:** los verdes son un servicio **diurno de días laborales**. Se concentran de
7:00 a 19:00 de lunes a viernes, con el máximo el jueves a las 17:00, y casi no tienen actividad
de madrugada. Los amarillos tienen además un patrón **nocturno y de fin de semana**: el máximo
es el sábado a las 18:00 y entre semana a las 21:00–22:00, y el sábado y domingo de 0:00 a 2:00
tienen tanto volumen como una mañana laboral.

### P3 · Características del viaje — `03_caracteristicas_viaje.sql`

| tipo | distancia mediana | p90 distancia | duración mediana | velocidad mediana | total mediano | pasajeros prom. |
|---|---:|---:|---:|---:|---:|---:|
| amarillo | 1.94 mi | 8.70 mi | 14.1 min | 9.3 mph | 23.58 USD | 1.25 |
| verde | 2.14 mi | 7.36 mi | 13.3 min | 10.0 mph | 20.50 USD | 1.30 |

**Interpretación:** el viaje típico es corto (≈2 millas, ≈14 minutos) y con un pasajero. Los
amarillos tienen una cola más larga (p90 de 8.7 mi) por los aeropuertos, mientras que los verdes
son un poco más largos en la mediana pero más baratos.

### P4 · Velocidad por hora (días laborales) — `04_velocidad_por_hora.sql`

**Interpretación:** la velocidad mediana de los amarillos va de **16.8 mph a las 4:00** a
**7.3 mph a las 11:00** y se mantiene cerca de 7.5 mph hasta las 15:00. A esa hora los viajes son
más cortos pero duran más (15.9 min contra 13.1 min a la 1:00). En los verdes, que operan fuera
del centro de Manhattan, el patrón es el mismo (18.4 mph a las 4:00 contra 8.6 mph a las 15:00), pero la velocidad de día es mayor que la de los amarillos.

### P5 · Borough de origen — `05_zonas_por_tipo.sql`

| borough | amarillos | verdes |
|---|---:|---:|
| Manhattan | 86.75 % | 60.21 % |
| Queens | 8.75 % | 21.90 % |
| Brooklyn | 3.60 % | 15.50 % |
| Bronx | 0.77 % | 2.24 % |

**Interpretación:** confirma la segmentación del servicio. Los verdes tienen prohibido recoger en
el sur de Manhattan y en los aeropuertos, por eso el 40 % de sus viajes empieza en Queens,
Brooklyn y Bronx. El 60 % que empieza en Manhattan corresponde al norte (Harlem, Washington
Heights), donde sí pueden operar. Solo East Harlem North y South suman 128 mil viajes, el 41 % de todos los verdes.

### P6 · Método de pago — `06_metodo_de_pago.sql`

| método | amarillos | verdes |
|---|---:|---:|
| Tarjeta | 65.4 % | 66.6 % |
| Flex Fare / sin dato | 25.0 % | 13.6 % (nulo) |
| Efectivo | 9.0 % | 19.6 % |

**Interpretación:** el efectivo es el doble de frecuente en verdes (19.6 % contra 9.0 %), en
línea con su clientela fuera de Manhattan. Los viajes en efectivo son más baratos (mediana de
18.55 USD contra 22.35 USD con tarjeta en amarillos).

### P7 · Propinas con tarjeta — `07_propinas.sql`

| franja | amarillo mediana | amarillo sin propina | verde mediana |
|---|---:|---:|---:|
| mañana 6–9 | 25.4 % | 13.1 % | 23.0 % |
| tarde 16–19 | **27.9 %** | 7.2 % | 25.5 % |
| madrugada 0–5 | 26.2 % | 13.7 % | 22.2 % |

**Interpretación:** con tarjeta la propina mediana es alrededor de una cuarta parte de la tarifa.
La propina se mide aquí sobre la tarifa base, sin recargos; es probable que el pasajero la
calcule sobre un total mayor (por ejemplo, con las opciones sugeridas por la terminal), y por eso
el porcentaje sobre la tarifa supera el 25 %. Es más alta por la tarde y
más baja de madrugada, cuando el porcentaje de viajes sin propina casi se duplica.

### P8 · Componentes del cobro — `08_componentes_del_cobro.sql`

Amarillos (849 millones USD facturados en 8 meses): tarifa 70.4 %, propina 9.5 %,
recargo de congestión 5.6 %, peajes 1.8 %, **cargo CBD 1.8 %**, aeropuerto 0.4 %, otros 8.7 %.

**Interpretación:** casi un tercio de lo que paga el pasajero no es la tarifa del taxímetro. El
`cbd_congestion_fee` (peaje de congestión de Manhattan, vigente desde 2025) ya representa
tanto como los peajes de puentes y túneles.

### P9 · Aeropuertos — `09_aeropuertos.sql`

| tipo | segmento | % viajes | % facturación | distancia mediana | total mediano |
|---|---|---:|---:|---:|---:|
| amarillo | aeropuerto | 8.1 % | **20.9 %** | 11.6 mi | 78.33 USD |
| amarillo | resto | 91.9 % | 79.1 % | 1.8 mi | 22.45 USD |
| verde | aeropuerto | 3.4 % | 6.5 % | 6.5 mi | 40.00 USD |

### P10 · Distribución del total — `10_distribucion_tarifa.sql`

**Interpretación:** distribución asimétrica a la derecha con la moda entre 15 y 20 USD. En los amarillos
hay un segundo pico local en 95–105 USD (217 mil viajes en el intervalo de 100 USD, más que en
los de 85–95). Corresponde a la tarifa plana de JFK–Manhattan más recargos, peajes y propina. El intervalo
"150 o más" concentra la cola. Por esto se reportan medianas y no promedios.

### P11 · Atípicos dentro de `trips_clean` — `11_atipicos.sql`

- Velocidad > 65 mph (imposible en la ciudad): 5,890 amarillos (0.02 %) y 111 verdes (0.04 %).
  Son errores de distancia o de reloj que sobreviven a la limpieza.
- Tarifa por milla fuera de Q3 + 3·IQR: 2.4 % de amarillos (> 22.47 USD/mi) y 1.9 % de verdes
  (> 16.42 USD/mi). Son sobre todo viajes muy cortos con la tarifa mínima, más que errores.
- **Decisión:** no se agregan más filtros. Su peso es mínimo y las medianas son robustas a ellos.

### P12 · Viajes pedidos por apps — `12_viajes_por_app.sql`

| mes | amarillos vía Uber (HV0003) | vía Lyft (HV0005) | otras apps |
|---|---:|---:|---:|
| 2026-06 | 23.2 % | 0 % | 2.1 % |
| 2026-07 | 20.2 % | 0 % | 6.1 % |
| 2026-08 | 18.3 % | 5.2 % | 3.2 % |

## 4.5 Hallazgos relevantes

1. **Los aeropuertos generan una quinta parte de la facturación de los amarillos con solo 8 % de
   los viajes.** Un viaje de aeropuerto cuesta 3.5 veces más que uno urbano (78 contra 22 USD de
   mediana). Cualquier cambio en la demanda aérea afecta mucho a los ingresos de los taxis amarillos.
2. **La congestión reduce la velocidad a menos de la mitad.** En días laborales la velocidad
   mediana pasa de 16.8 mph (4:00) a 7.3 mph (11:00). Un viaje de mediodía es más corto y aun así
   dura más, lo que explica también el peso de los recargos de congestión (5.6 %) y del cargo CBD
   (1.8 %) en lo que se cobra.
3. **Amarillos y verdes son mercados distintos, no el mismo servicio en dos colores.** Los verdes
   son diurnos, de días laborales y fuera del centro (40 % fuera de Manhattan, 20 % en efectivo).
   Los amarillos están concentrados en Manhattan, con fuerte actividad nocturna y de fin de semana.
4. **Una cuarta parte de los viajes amarillos no informa el método de pago** (`payment_type = 0`,
   con pasajeros y tarifa nulos). Es un problema de calidad que cualquier indicador de pagos debe
   tratar explícitamente.
5. **Las apps de alto volumen ya despachan taxis amarillos.** Desde que existe el dato (junio de
   2026), 18–23 % de los viajes amarillos se pidieron por Uber, y en agosto Lyft aparece con 5 %.
