# Proyecto de Aula: Data Warehouse y Big Data — NYC Taxi 2018

Politécnico Grancolombiano · Facultad de Ingeniería, Diseño e Innovación · 2026
Docente: Cristian Camilo Flórez Novoa

## 1. Descripción del proyecto
Solución analítica basada en un Data Warehouse sobre **9.068.375 viajes de taxi de Nueva York (2018)**. Incluye la carga de datos crudos, su limpieza y transformación, un modelo dimensional en esquema estrella, cubos OLAP bajo el enfoque ROLAP y un dashboard gerencial interactivo.

## 2. Equipo
- Laura Sofía Vásquez Lozano
- Ana Ximena Rosas Medina
- Julian Mateo Salas Soto

## 3. Herramientas y tecnologías
| Herramienta | Uso en el proyecto |
|---|---|
| Google BigQuery | Bodega de datos: staging, transformación, modelo dimensional y cubos OLAP (ROLAP) |
| SQL | Limpieza, dimensiones, tabla de hechos, validaciones y cubos |
| Google Colab | Carga de datos, conexión local a PostgreSQL y dashboard |
| Python (pandas, Plotly, SQLAlchemy) | Inspección del archivo, carga y visualización |
| PostgreSQL | Base local en Colab mediante cadena de conexión `localhost` |
| Killercoda + MySQL | Laboratorio virtual Ubuntu con base local `127.0.0.1` |
| GitHub | Control de versiones y documentación |

## 4. Arquitectura general
1. **Fuente:** `taxi_trip_data.csv` (10.000.000 de registros) y `taxi_zone_geo.csv` (263 zonas).
2. **Staging:** carga cruda en BigQuery, todas las columnas como `STRING`.
3. **Transformación:** 8 reglas de limpieza (duplicados, fechas, distancias, montos, pasajeros) → 9.068.375 registros válidos.
4. **Data Warehouse:** esquema estrella con `FACT_VIAJES` y 6 dimensiones.
5. **OLAP:** vista base y 4 cubos (`cubo_demanda`, `cubo_ingresos`, `cubo_operacion`, `cubo_tiempo`) con GROUPING SETS, CUBE y ROLLUP.
6. **Visualización:** dashboard interactivo en Python (Plotly).

## 5. Estructura del repositorio
| Archivo | Descripción |
|---|---|
| `dw_taxi_nyc_bigquery.sql` | Script completo de la bodega: calidad, limpieza, dimensiones, hechos, validación y cubos OLAP |
| `01_carga_staging.ipynb` | Colab: carga del CSV crudo a BigQuery |
| `02_conexion_local.ipynb` | Colab: PostgreSQL con cadena de conexión local y carga de los cubos |
| `03_dashboard_python.ipynb` | Colab: dashboard interactivo a partir de los cubos |
| `dashboard_nyc_taxi_2018.html` | Dashboard generado (abrir en el navegador) |
| `killercoda_mysql.sh` | Comandos del laboratorio MySQL en Killercoda |

## 6. Orden de ejecución
1. Crear el proyecto `dw-taxi-nyc` y los datasets `staging` y `dw_taxi` (ubicación US).
2. Cargar `taxi_zone_geo.csv` desde la consola de BigQuery.
3. Ejecutar `01_carga_staging.ipynb` (requiere el CSV en la raíz de Google Drive).
4. Ejecutar `dw_taxi_nyc_bigquery.sql`, secciones 2 a 8.
5. Ejecutar `02_conexion_local.ipynb` y `03_dashboard_python.ipynb`.

**Importante:** la carga usa `WRITE_TRUNCATE` y reemplaza la tabla staging al repetirse.

## 7. Cadenas de conexión
| Entorno | Motor | Cadena |
|---|---|---|
| Google Colab | PostgreSQL | `postgresql+psycopg2://postgres:postgres@localhost:5432/dw_taxi` |
| Killercoda | MySQL | `mysql://root:root@127.0.0.1:3306/dw_taxi` |
| Google Cloud | BigQuery | Proyecto `dw-taxi-nyc`, dataset `dw_taxi` |

Las credenciales son de laboratorios locales y temporales. En producción se gestionarían con variables de entorno y no se publicarían.

## 8. Fuente de datos
NYC Taxi & Limousine Commission (TLC), vía Kaggle: *NYC Taxi Trip Data – Google Public Data*.
