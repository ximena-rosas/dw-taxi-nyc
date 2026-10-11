-- =====================================================================
-- PROYECTO DE AULA · DATA WAREHOUSE Y BIG DATA · 2026
-- Politécnico Grancolombiano
-- Dataset: NYC Taxi Trip Data (Kaggle / Google Public Data) · año 2018
-- Plataforma: Google BigQuery (Sandbox) · Proyecto: dw-taxi-nyc
--
-- Orden de ejecución: secciones 0 a 9, de arriba hacia abajo.
-- Cada sección se puede ejecutar completa en una pestaña de BigQuery.
--
-- IMPORTANTE (Sandbox):
--   * Las tablas se borran automáticamente a los 60 días.
--     Con este script se recrea toda la bodega.
--   * No se permiten UPDATE / INSERT / DELETE: todo se hace con
--     CREATE OR REPLACE.
-- =====================================================================


-- =====================================================================
-- SECCIÓN 0 · PREPARACIÓN (se hace desde la interfaz, no con SQL)
-- =====================================================================
-- 1. Crear el proyecto `dw-taxi-nyc` en console.cloud.google.com.
-- 2. Crear dos datasets con ubicación US (multirregión):
--      staging  -> datos crudos y tabla limpia
--      dw_taxi  -> bodega de datos (dimensiones, hechos, cubos)
-- 3. Cargar taxi_zone_geo.csv desde la consola:
--      staging > Crear tabla > Subir > CSV > tabla: taxi_zone_geo
--      Esquema: detección automática
--      Opciones avanzadas: "Permitir saltos de línea entre comillas"
-- 4. Cargar taxi_trip_data.csv desde Google Colab (supera los 100 MB
--    que permite la consola). Notebook: 01_carga_staging.ipynb
--      - Monta Drive y autentica la cuenta de Google Cloud.
--      - Carga el CSV a staging.taxi_trip_data con todas las
--        columnas como STRING (dato crudo, sin transformar).
-- Resultado esperado: taxi_zone_geo = 263 filas,
--                     taxi_trip_data = 10.000.000 filas.


-- =====================================================================
-- SECCIÓN 1 · ANÁLISIS DE CALIDAD (exploración, no crea nada)
-- Ejecutar cada consulta por separado.
-- =====================================================================

-- 1.1 Perfil de calidad
WITH t AS (
  SELECT
    SAFE_CAST(pickup_datetime  AS TIMESTAMP) AS pickup,
    SAFE_CAST(dropoff_datetime AS TIMESTAMP) AS dropoff,
    SAFE_CAST(passenger_count  AS FLOAT64)   AS pasajeros,
    SAFE_CAST(trip_distance    AS FLOAT64)   AS distancia,
    SAFE_CAST(fare_amount      AS FLOAT64)   AS tarifa,
    SAFE_CAST(total_amount     AS FLOAT64)   AS total,
    pickup_location_id,
    dropoff_location_id
  FROM `dw-taxi-nyc.staging.taxi_trip_data`
)
SELECT
  COUNT(*)                                               AS total_registros,
  MIN(pickup)                                            AS fecha_min,
  MAX(pickup)                                            AS fecha_max,
  COUNTIF(pickup IS NULL OR dropoff IS NULL)             AS fecha_invalida,
  COUNTIF(EXTRACT(YEAR FROM pickup) <> 2018)             AS fuera_de_2018,
  COUNTIF(dropoff <= pickup)                             AS dropoff_antes_pickup,
  COUNTIF(TIMESTAMP_DIFF(dropoff, pickup, MINUTE) > 180) AS duracion_mayor_3h,
  COUNTIF(distancia <= 0)                                AS distancia_cero_o_neg,
  COUNTIF(distancia > 100)                               AS distancia_mayor_100,
  COUNTIF(pasajeros IS NULL OR pasajeros <= 0)           AS pasajeros_cero_o_nulo,
  COUNTIF(pasajeros > 6)                                 AS pasajeros_mayor_6,
  COUNTIF(tarifa < 0 OR total < 0)                       AS montos_negativos,
  COUNTIF(total > 500)                                   AS montos_mayores_500,
  COUNTIF(pickup_location_id IS NULL
       OR dropoff_location_id IS NULL)                   AS zona_nula
FROM t;

-- 1.2 Duplicados exactos (resultado: 607.571)
SELECT COUNT(*) - COUNT(DISTINCT TO_JSON_STRING(t)) AS registros_duplicados
FROM `dw-taxi-nyc.staging.taxi_trip_data` t;

-- 1.3 Distribución por año (resultado: 9.999.824 viajes en 2018)
SELECT
  EXTRACT(YEAR FROM SAFE_CAST(pickup_datetime AS TIMESTAMP)) AS anio,
  COUNT(*) AS viajes
FROM `dw-taxi-nyc.staging.taxi_trip_data`
GROUP BY anio
ORDER BY anio;


-- =====================================================================
-- SECCIÓN 2 · TRANSFORMACIÓN: TABLA LIMPIA
-- Reglas aplicadas:
--   R1 Duplicados exactos           -> se conserva una copia
--   R2 Viajes fuera de 2018         -> se excluyen
--   R3 Fin anterior/igual al inicio -> se excluyen
--   R4 Duración > 180 minutos       -> se excluyen
--   R5 Distancia <= 0 o > 100 mi    -> se excluyen
--   R6 Montos negativos             -> se excluyen
--   R7 Pasajeros = 0 o > 6          -> se conservan con NULL
--   R8 Monto total > USD 500        -> se excluyen
-- Resultado esperado: 9.068.375 filas
-- =====================================================================
CREATE OR REPLACE TABLE `dw-taxi-nyc.staging.viajes_limpio` AS
WITH sin_duplicados AS (
  SELECT DISTINCT *
  FROM `dw-taxi-nyc.staging.taxi_trip_data`
),
tipado AS (
  SELECT
    SAFE_CAST(vendor_id AS INT64)                                 AS vendor_id,
    DATETIME(SAFE_CAST(pickup_datetime  AS TIMESTAMP), 'UTC')     AS pickup_datetime,
    DATETIME(SAFE_CAST(dropoff_datetime AS TIMESTAMP), 'UTC')     AS dropoff_datetime,
    SAFE_CAST(SAFE_CAST(passenger_count AS FLOAT64) AS INT64)     AS passenger_count,
    SAFE_CAST(trip_distance AS FLOAT64)                           AS trip_distance,
    SAFE_CAST(SAFE_CAST(rate_code AS FLOAT64) AS INT64)           AS rate_code,
    store_and_fwd_flag,
    SAFE_CAST(SAFE_CAST(payment_type AS FLOAT64) AS INT64)        AS payment_type,
    SAFE_CAST(fare_amount   AS FLOAT64)                           AS fare_amount,
    SAFE_CAST(extra         AS FLOAT64)                           AS extra,
    SAFE_CAST(mta_tax       AS FLOAT64)                           AS mta_tax,
    SAFE_CAST(tip_amount    AS FLOAT64)                           AS tip_amount,
    SAFE_CAST(tolls_amount  AS FLOAT64)                           AS tolls_amount,
    SAFE_CAST(imp_surcharge AS FLOAT64)                           AS imp_surcharge,
    SAFE_CAST(total_amount  AS FLOAT64)                           AS total_amount,
    SAFE_CAST(SAFE_CAST(pickup_location_id  AS FLOAT64) AS INT64) AS pickup_location_id,
    SAFE_CAST(SAFE_CAST(dropoff_location_id AS FLOAT64) AS INT64) AS dropoff_location_id
  FROM sin_duplicados
)
SELECT
  * EXCEPT (passenger_count),
  IF(passenger_count BETWEEN 1 AND 6, passenger_count, NULL)              AS passenger_count,
  ROUND(DATETIME_DIFF(dropoff_datetime, pickup_datetime, SECOND) / 60, 2) AS trip_duration_min
FROM tipado
WHERE EXTRACT(YEAR FROM pickup_datetime) = 2018
  AND dropoff_datetime > pickup_datetime
  AND DATETIME_DIFF(dropoff_datetime, pickup_datetime, MINUTE) <= 180
  AND trip_distance > 0 AND trip_distance <= 100
  AND fare_amount  >= 0
  AND total_amount BETWEEN 0 AND 500;


-- =====================================================================
-- SECCIÓN 3 · DIMENSIONES DE CATÁLOGO
-- Llave sustituta con ROW_NUMBER(); códigos vacíos -> -1 'No informado'.
-- OJO: si se recrean estas tres, hay que recrear FACT_VIAJES (sección 5)
-- porque las llaves _key pueden cambiar.
-- =====================================================================
CREATE OR REPLACE TABLE `dw-taxi-nyc.dw_taxi.DIM_PROVEEDOR` AS
SELECT
  ROW_NUMBER() OVER (ORDER BY vendor_id) AS vendor_key,
  vendor_id,
  CASE vendor_id
    WHEN 1 THEN 'Creative Mobile Technologies'
    WHEN 2 THEN 'VeriFone Inc.'
    ELSE 'No informado'
  END AS vendor_name
FROM (
  SELECT DISTINCT COALESCE(vendor_id, -1) AS vendor_id
  FROM `dw-taxi-nyc.staging.viajes_limpio`
);

CREATE OR REPLACE TABLE `dw-taxi-nyc.dw_taxi.DIM_TARIFA` AS
SELECT
  ROW_NUMBER() OVER (ORDER BY rate_code) AS rate_code_key,
  rate_code,
  CASE rate_code
    WHEN 1 THEN 'Tarifa estándar'
    WHEN 2 THEN 'Aeropuerto JFK'
    WHEN 3 THEN 'Aeropuerto Newark'
    WHEN 4 THEN 'Nassau o Westchester'
    WHEN 5 THEN 'Tarifa negociada'
    WHEN 6 THEN 'Viaje grupal'
    ELSE 'No informado'
  END AS rate_code_desc
FROM (
  SELECT DISTINCT COALESCE(rate_code, -1) AS rate_code
  FROM `dw-taxi-nyc.staging.viajes_limpio`
);

CREATE OR REPLACE TABLE `dw-taxi-nyc.dw_taxi.DIM_PAGO` AS
SELECT
  ROW_NUMBER() OVER (ORDER BY payment_type) AS payment_type_key,
  payment_type,
  CASE payment_type
    WHEN 1 THEN 'Tarjeta de crédito'
    WHEN 2 THEN 'Efectivo'
    WHEN 3 THEN 'Sin cargo'
    WHEN 4 THEN 'Disputa'
    WHEN 5 THEN 'Desconocido'
    WHEN 6 THEN 'Viaje anulado'
    ELSE 'No informado'
  END AS payment_type_desc
FROM (
  SELECT DISTINCT COALESCE(payment_type, -1) AS payment_type
  FROM `dw-taxi-nyc.staging.viajes_limpio`
);


-- =====================================================================
-- SECCIÓN 4 · DIMENSIONES DE UBICACIÓN, FECHA Y HORA
-- Resultado esperado: UBICACION 264 · FECHA 366 · HORA 24
-- =====================================================================

-- Una fila por zona: se consolidan los polígonos repetidos del archivo
-- geográfico con ST_UNION_AGG. Las zonas que aparecen en los viajes y
-- no en el archivo se agregan como 'Zona desconocida'.
CREATE OR REPLACE TABLE `dw-taxi-nyc.dw_taxi.DIM_UBICACION` AS
WITH zonas AS (
  SELECT
    SAFE_CAST(zone_id AS INT64) AS zone_id,
    ANY_VALUE(zone_name)        AS zone_name,
    ANY_VALUE(borough)          AS borough,
    ST_UNION_AGG(SAFE.ST_GEOGFROMTEXT(zone_geom, make_valid => TRUE)) AS zone_geom
  FROM `dw-taxi-nyc.staging.taxi_zone_geo`
  GROUP BY zone_id
)
SELECT * FROM zonas
UNION ALL
SELECT id, 'Zona desconocida', 'Desconocido', CAST(NULL AS GEOGRAPHY)
FROM (
  SELECT pickup_location_id AS id FROM `dw-taxi-nyc.staging.viajes_limpio`
  UNION DISTINCT
  SELECT dropoff_location_id FROM `dw-taxi-nyc.staging.viajes_limpio`
)
WHERE id NOT IN (SELECT zone_id FROM zonas);

-- Calendario 2018 + 1 de enero de 2019 (viajes que terminan
-- después de la medianoche del 31 de diciembre).
CREATE OR REPLACE TABLE `dw-taxi-nyc.dw_taxi.DIM_FECHA` AS
SELECT
  CAST(FORMAT_DATE('%Y%m%d', f) AS INT64)   AS fecha_id,
  f                                         AS fecha_completa,
  EXTRACT(YEAR    FROM f)                   AS anio,
  EXTRACT(QUARTER FROM f)                   AS trimestre,
  EXTRACT(MONTH   FROM f)                   AS mes,
  ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio',
   'Agosto','Septiembre','Octubre','Noviembre','Diciembre']
   [OFFSET(EXTRACT(MONTH FROM f) - 1)]      AS nombre_mes,
  EXTRACT(DAY FROM f)                       AS dia,
  MOD(EXTRACT(DAYOFWEEK FROM f) + 5, 7) + 1 AS dia_semana,   -- 1 = lunes
  ['Domingo','Lunes','Martes','Miércoles','Jueves','Viernes','Sábado']
   [OFFSET(EXTRACT(DAYOFWEEK FROM f) - 1)]  AS nombre_dia_semana,
  EXTRACT(DAYOFWEEK FROM f) IN (1, 7)       AS es_fin_de_semana
FROM UNNEST(GENERATE_DATE_ARRAY('2018-01-01', '2019-01-01')) AS f;

CREATE OR REPLACE TABLE `dw-taxi-nyc.dw_taxi.DIM_HORA` AS
SELECT
  h AS hora_id,
  h AS hora,
  CASE
    WHEN h BETWEEN 0  AND 5  THEN 'Madrugada'
    WHEN h BETWEEN 6  AND 11 THEN 'Mañana'
    WHEN h BETWEEN 12 AND 17 THEN 'Tarde'
    ELSE 'Noche'
  END AS franja_horaria,
  h BETWEEN 7 AND 9 OR h BETWEEN 16 AND 19 AS es_hora_pico
FROM UNNEST(GENERATE_ARRAY(0, 23)) AS h;


-- =====================================================================
-- SECCIÓN 5 · TABLA DE HECHOS
-- Grano: 1 fila = 1 viaje. Resultado esperado: 9.068.375 filas.
-- =====================================================================
CREATE OR REPLACE TABLE `dw-taxi-nyc.dw_taxi.FACT_VIAJES`
CLUSTER BY fecha_pickup_id, pickup_zone_id
AS
SELECT
  FARM_FINGERPRINT(TO_JSON_STRING(v))                            AS id_viaje,
  CAST(FORMAT_DATE('%Y%m%d', DATE(v.pickup_datetime))  AS INT64) AS fecha_pickup_id,
  CAST(FORMAT_DATE('%Y%m%d', DATE(v.dropoff_datetime)) AS INT64) AS fecha_dropoff_id,
  EXTRACT(HOUR FROM v.pickup_datetime)                           AS hora_pickup_id,
  EXTRACT(HOUR FROM v.dropoff_datetime)                          AS hora_dropoff_id,
  v.pickup_location_id                                           AS pickup_zone_id,
  v.dropoff_location_id                                          AS dropoff_zone_id,
  p.vendor_key,
  t.rate_code_key,
  pg.payment_type_key,
  v.passenger_count,
  v.trip_distance,
  v.fare_amount,
  v.extra,
  v.mta_tax,
  v.tip_amount,
  v.tolls_amount,
  v.imp_surcharge,
  v.total_amount,
  v.trip_duration_min,
  v.store_and_fwd_flag                                           -- dimensión degenerada
FROM `dw-taxi-nyc.staging.viajes_limpio` v
JOIN `dw-taxi-nyc.dw_taxi.DIM_PROVEEDOR` p  ON COALESCE(v.vendor_id, -1)    = p.vendor_id
JOIN `dw-taxi-nyc.dw_taxi.DIM_TARIFA`    t  ON COALESCE(v.rate_code, -1)    = t.rate_code
JOIN `dw-taxi-nyc.dw_taxi.DIM_PAGO`      pg ON COALESCE(v.payment_type, -1) = pg.payment_type;


-- =====================================================================
-- SECCIÓN 6 · VALIDACIÓN POSTERIOR A LA CARGA
-- Esperado: filas_fact = ids_unicos = 9.068.375 y todas las sin_* = 0
-- =====================================================================
SELECT
  COUNT(*)                     AS filas_fact,
  COUNT(DISTINCT f.id_viaje)   AS ids_unicos,
  COUNTIF(df.fecha_id IS NULL) AS sin_fecha_pickup,
  COUNTIF(dd.fecha_id IS NULL) AS sin_fecha_dropoff,
  COUNTIF(uo.zone_id IS NULL)  AS sin_zona_pickup,
  COUNTIF(ud.zone_id IS NULL)  AS sin_zona_dropoff,
  MAX(f.total_amount)          AS monto_maximo
FROM `dw-taxi-nyc.dw_taxi.FACT_VIAJES` f
LEFT JOIN `dw-taxi-nyc.dw_taxi.DIM_FECHA`     df ON f.fecha_pickup_id  = df.fecha_id
LEFT JOIN `dw-taxi-nyc.dw_taxi.DIM_FECHA`     dd ON f.fecha_dropoff_id = dd.fecha_id
LEFT JOIN `dw-taxi-nyc.dw_taxi.DIM_UBICACION` uo ON f.pickup_zone_id   = uo.zone_id
LEFT JOIN `dw-taxi-nyc.dw_taxi.DIM_UBICACION` ud ON f.dropoff_zone_id  = ud.zone_id;


-- =====================================================================
-- SECCIÓN 7 · CAPA OLAP (ROLAP): VISTA BASE
-- Une hechos y dimensiones. Fecha y hora por rol pickup;
-- ubicación por rol pickup (origen) y dropoff (destino).
-- =====================================================================
CREATE OR REPLACE VIEW `dw-taxi-nyc.dw_taxi.vw_viajes_base` AS
SELECT
  f.id_viaje,
  df.fecha_completa, df.anio, df.trimestre, df.mes, df.nombre_mes,
  df.dia, df.dia_semana, df.nombre_dia_semana, df.es_fin_de_semana,
  dh.hora, dh.franja_horaria, dh.es_hora_pico,
  uo.borough   AS borough_origen,
  uo.zone_name AS zona_origen,
  ud.borough   AS borough_destino,
  ud.zone_name AS zona_destino,
  p.vendor_name,
  t.rate_code_desc,
  pg.payment_type_desc,
  f.passenger_count, f.trip_distance, f.fare_amount, f.tip_amount,
  f.tolls_amount, f.total_amount, f.trip_duration_min
FROM `dw-taxi-nyc.dw_taxi.FACT_VIAJES` f
JOIN `dw-taxi-nyc.dw_taxi.DIM_FECHA`     df ON f.fecha_pickup_id  = df.fecha_id
JOIN `dw-taxi-nyc.dw_taxi.DIM_HORA`      dh ON f.hora_pickup_id   = dh.hora_id
JOIN `dw-taxi-nyc.dw_taxi.DIM_UBICACION` uo ON f.pickup_zone_id   = uo.zone_id
JOIN `dw-taxi-nyc.dw_taxi.DIM_UBICACION` ud ON f.dropoff_zone_id  = ud.zone_id
JOIN `dw-taxi-nyc.dw_taxi.DIM_PROVEEDOR` p  ON f.vendor_key       = p.vendor_key
JOIN `dw-taxi-nyc.dw_taxi.DIM_TARIFA`    t  ON f.rate_code_key    = t.rate_code_key
JOIN `dw-taxi-nyc.dw_taxi.DIM_PAGO`      pg ON f.payment_type_key = pg.payment_type_key;


-- =====================================================================
-- SECCIÓN 8 · CUBOS OLAP
-- Los subtotales se marcan como 'TOTAL' / 'TODAS' / 'TODOS'.
-- En el dashboard hay que filtrar el nivel deseado para no sumar doble.
-- =====================================================================

-- Cubo 1 · Demanda (Pregunta BI 1) · GROUPING SETS, 6 niveles
CREATE OR REPLACE VIEW `dw-taxi-nyc.dw_taxi.cubo_demanda` AS
SELECT
  IF(GROUPING(borough_origen) = 1, 'TOTAL', borough_origen) AS borough,
  IF(GROUPING(zona_origen)    = 1, 'TODAS', zona_origen)    AS zona,
  IF(GROUPING(franja_horaria) = 1, 'TODAS', franja_horaria) AS franja,
  COUNT(*)                       AS total_viajes,
  SUM(passenger_count)           AS total_pasajeros,
  ROUND(AVG(passenger_count), 2) AS pasajeros_promedio
FROM `dw-taxi-nyc.dw_taxi.vw_viajes_base`
GROUP BY GROUPING SETS (
  (borough_origen, zona_origen, franja_horaria),
  (borough_origen, zona_origen),
  (borough_origen, franja_horaria),
  (borough_origen),
  (franja_horaria),
  ()
);

-- Cubo 2 · Ingresos (Pregunta BI 2) · CUBE, 8 niveles
CREATE OR REPLACE VIEW `dw-taxi-nyc.dw_taxi.cubo_ingresos` AS
SELECT
  IF(GROUPING(borough_origen)    = 1, 'TOTAL', borough_origen)    AS borough,
  IF(GROUPING(nombre_dia_semana) = 1, 'TODOS', nombre_dia_semana) AS dia,
  IF(GROUPING(nombre_dia_semana) = 1, NULL, MIN(dia_semana))      AS orden_dia,
  IF(GROUPING(franja_horaria)    = 1, 'TODAS', franja_horaria)    AS franja,
  COUNT(*)                    AS total_viajes,
  ROUND(SUM(total_amount), 2) AS ingresos_totales,
  ROUND(AVG(total_amount), 2) AS ticket_promedio,
  ROUND(SUM(tip_amount), 2)   AS propinas_totales,
  ROUND(SAFE_DIVIDE(SUM(tip_amount), SUM(fare_amount)) * 100, 2) AS pct_propina
FROM `dw-taxi-nyc.dw_taxi.vw_viajes_base`
GROUP BY CUBE (borough_origen, nombre_dia_semana, franja_horaria);

-- Cubo 3 · Operación (Pregunta BI 3) · ROLLUP, 4 niveles
CREATE OR REPLACE VIEW `dw-taxi-nyc.dw_taxi.cubo_operacion` AS
SELECT
  IF(GROUPING(borough_origen) = 1, 'TOTAL', borough_origen) AS borough,
  IF(GROUPING(zona_origen)    = 1, 'TODAS', zona_origen)    AS zona,
  IF(GROUPING(franja_horaria) = 1, 'TODAS', franja_horaria) AS franja,
  COUNT(*)                         AS total_viajes,
  ROUND(AVG(trip_distance), 2)     AS distancia_promedio_millas,
  ROUND(AVG(trip_duration_min), 2) AS duracion_promedio_min,
  ROUND(AVG(total_amount), 2)      AS costo_promedio,
  ROUND(SAFE_DIVIDE(SUM(total_amount), SUM(trip_distance)), 2)           AS costo_por_milla,
  ROUND(SAFE_DIVIDE(SUM(trip_distance), SUM(trip_duration_min) / 60), 2) AS velocidad_promedio_mph
FROM `dw-taxi-nyc.dw_taxi.vw_viajes_base`
GROUP BY ROLLUP (borough_origen, zona_origen, franja_horaria);

-- Cubo 4 · Tendencia temporal (Pregunta BI 4) · ROLLUP, 5 niveles
CREATE OR REPLACE VIEW `dw-taxi-nyc.dw_taxi.cubo_tiempo` AS
SELECT
  anio,
  trimestre,
  mes,
  IF(GROUPING(mes) = 1, NULL, ANY_VALUE(nombre_mes))     AS nombre_mes,
  dia,
  IF(GROUPING(dia) = 1, NULL, ANY_VALUE(fecha_completa)) AS fecha,
  CASE
    WHEN GROUPING(anio)      = 1 THEN 'Gran total'
    WHEN GROUPING(trimestre) = 1 THEN 'Total año'
    WHEN GROUPING(mes)       = 1 THEN 'Total trimestre'
    WHEN GROUPING(dia)       = 1 THEN 'Total mes'
    ELSE 'Día'
  END AS nivel,
  COUNT(*)                    AS total_viajes,
  ROUND(SUM(total_amount), 2) AS ingresos_totales,
  ROUND(AVG(total_amount), 2) AS ticket_promedio
FROM `dw-taxi-nyc.dw_taxi.vw_viajes_base`
GROUP BY ROLLUP (anio, trimestre, mes, dia);


-- =====================================================================
-- SECCIÓN 9 · OPERACIONES OLAP (evidencia)
-- Ejecutar cada una por separado.
-- =====================================================================

-- 9.1 ROLL-UP: de zona a borough
SELECT borough, total_viajes
FROM `dw-taxi-nyc.dw_taxi.cubo_demanda`
WHERE zona = 'TODAS' AND franja = 'TODAS' AND borough <> 'TOTAL'
ORDER BY total_viajes DESC;

-- 9.2 DRILL-DOWN: de Manhattan a sus zonas
SELECT zona, total_viajes
FROM `dw-taxi-nyc.dw_taxi.cubo_demanda`
WHERE borough = 'Manhattan' AND zona <> 'TODAS' AND franja = 'TODAS'
ORDER BY total_viajes DESC
LIMIT 10;

-- 9.3 SLICE: una dimensión fija (franja = Noche)
SELECT borough, total_viajes
FROM `dw-taxi-nyc.dw_taxi.cubo_demanda`
WHERE franja = 'Noche' AND zona = 'TODAS' AND borough <> 'TOTAL'
ORDER BY total_viajes DESC;

-- 9.4 DICE: varias dimensiones filtradas
SELECT borough_origen, franja_horaria, payment_type_desc,
       COUNT(*)                    AS total_viajes,
       ROUND(AVG(total_amount), 2) AS ticket_promedio
FROM `dw-taxi-nyc.dw_taxi.vw_viajes_base`
WHERE borough_origen    IN ('Manhattan', 'Queens')
  AND franja_horaria    IN ('Mañana', 'Noche')
  AND payment_type_desc = 'Tarjeta de crédito'
GROUP BY borough_origen, franja_horaria, payment_type_desc
ORDER BY borough_origen, franja_horaria;

-- 9.5 PIVOT: boroughs en filas, días en columnas
SELECT *
FROM (
  SELECT borough, dia, ingresos_totales
  FROM `dw-taxi-nyc.dw_taxi.cubo_ingresos`
  WHERE franja = 'TODAS' AND borough <> 'TOTAL' AND dia <> 'TODOS'
)
PIVOT (
  SUM(ingresos_totales)
  FOR dia IN ('Lunes', 'Martes', 'Miércoles', 'Jueves',
              'Viernes', 'Sábado', 'Domingo')
)
ORDER BY borough;
