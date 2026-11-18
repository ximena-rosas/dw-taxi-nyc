# Proyecto de Aula: Data Warehouse y Big Data — NYC Taxi 2018

Politécnico Grancolombiano · Facultad de Ingeniería, Diseño e Innovación · 2026
Docente: Cristian Camilo Flórez Novoa

## 1. Descripción del proyecto
Solución analítica basada en un Data Warehouse sobre **9.068.375 viajes de taxi de Nueva York (2018)**. Incluye la carga de datos crudos, su limpieza y transformación, un modelo dimensional en esquema estrella, cubos OLAP bajo el enfoque ROLAP y un dashboard gerencial interactivo. En su fase final incorpora **procesamiento distribuido con Hadoop y MapReduce** sobre el archivo original de 10.000.000 de registros, cuyo resultado se integra de vuelta al dashboard.

## 2. Equipo
- Laura Sofía Vásquez Lozano
- Ana Ximena Rosas Medina
- Julian Mateo Salas Soto

## 3. Herramientas y tecnologías
| Herramienta | Uso en el proyecto |
|---|---|
| Google BigQuery | Bodega de datos: staging, transformación, modelo dimensional y cubos OLAP (ROLAP) |
| SQL | Limpieza, dimensiones, tabla de hechos, validaciones y cubos |
| Google Colab | Carga de datos, conexión local a PostgreSQL, dashboard y clúster Hadoop |
| Python (pandas, Plotly, SQLAlchemy) | Inspección del archivo, carga y visualización |
| PostgreSQL | Base local en Colab mediante cadena de conexión `localhost` |
| Killercoda + MySQL | Laboratorio virtual Ubuntu con base local `127.0.0.1` |
| Apache Hadoop 3.3.6 (HDFS + YARN) | Almacenamiento y procesamiento distribuido del archivo crudo |
| Hadoop Streaming | Ejecución del trabajo MapReduce con funciones escritas en Python |
| GitHub | Control de versiones y documentación |

## 4. Arquitectura general
1. **Fuente:** `taxi_trip_data.csv` (10.000.000 de registros) y `taxi_zone_geo.csv` (263 zonas).
2. **Staging:** carga cruda en BigQuery, todas las columnas como `STRING`.
3. **Transformación:** 8 reglas de limpieza (duplicados, fechas, distancias, montos, pasajeros) → 9.068.375 registros válidos.
4. **Data Warehouse:** esquema estrella con `FACT_VIAJES` y 6 dimensiones.
5. **OLAP:** vista base y 4 cubos (`cubo_demanda`, `cubo_ingresos`, `cubo_operacion`, `cubo_tiempo`) con GROUPING SETS, CUBE y ROLLUP.
6. **Visualización:** dashboard interactivo en Python (Plotly).
7. **Procesamiento distribuido:** el archivo crudo se carga en HDFS, donde queda dividido en 11 bloques de 128 MB, y un trabajo MapReduce construye la matriz de flujo origen-destino (**41.958 corredores**) recorriéndolo sin pasar por el ETL.
8. **Integración:** el resultado del MapReduce vuelve al dashboard como quinta sección, "Corredores de movilidad".

## 5. Estructura del repositorio
| Archivo | Descripción |
|---|---|
| `dw_taxi_nyc_bigquery.sql` | Script completo de la bodega: calidad, limpieza, dimensiones, hechos, validación y cubos OLAP |
| `01_carga_staging.ipynb` | Colab: carga del CSV crudo a BigQuery |
| `02_conexion_local.ipynb` | Colab: PostgreSQL con cadena de conexión local y carga de los cubos |
| `03_dashboard_python.ipynb` | Colab: dashboard interactivo a partir de los cubos y de la matriz de corredores |
| `dashboard_nyc_taxi_2018.html` | Dashboard generado, con las cinco secciones (abrir en el navegador) |
| `04_hadoop_mapreduce.ipynb` | Colab: despliegue del clúster Hadoop (HDFS + YARN), carga en HDFS y ejecución del trabajo MapReduce |
| `mapper.py` | Valida cada registro del archivo crudo y emite el par origen-destino como llave |
| `combiner.py` | Suma parcial en el nodo del mapper, antes de la fase de shuffle |
| `reducer.py` | Consolida los totales por par de zonas y calcula las medidas finales |
| `matriz_od.csv` | Salida del trabajo MapReduce: 41.958 corredores con sus medidas promedio |
| `killercoda_mysql.sh` | Comandos del laboratorio MySQL en Killercoda |

## 6. Orden de ejecución
1. Crear el proyecto `dw-taxi-nyc` y los datasets `staging` y `dw_taxi` (ubicación US).
2. Cargar `taxi_zone_geo.csv` desde la consola de BigQuery.
3. Ejecutar `01_carga_staging.ipynb` (requiere el CSV en la raíz de Google Drive).
4. Ejecutar `dw_taxi_nyc_bigquery.sql`, secciones 2 a 8.
5. Ejecutar `02_conexion_local.ipynb`.
6. Ejecutar `04_hadoop_mapreduce.ipynb`, que genera `matriz_od.csv`.
7. Ejecutar `03_dashboard_python.ipynb` con `matriz_od.csv` disponible en el entorno.

**Importante:** la carga usa `WRITE_TRUNCATE` y reemplaza la tabla staging al repetirse. El clúster Hadoop se despliega dentro de la máquina virtual de Colab, por lo que se pierde al reiniciarse el entorno.

## 7. Cadenas de conexión
| Entorno | Motor | Cadena |
|---|---|---|
| Google Colab | PostgreSQL | `postgresql+psycopg2://postgres:postgres@localhost:5432/dw_taxi` |
| Killercoda | MySQL | `mysql://root:root@127.0.0.1:3306/dw_taxi` |
| Google Cloud | BigQuery | Proyecto `dw-taxi-nyc`, dataset `dw_taxi` |
| Google Colab | HDFS | `hdfs://localhost:9000` |

Las credenciales son de laboratorios locales y temporales. En producción se gestionarían con variables de entorno y no se publicarían.

## 8. Fuente de datos
NYC Taxi & Limousine Commission (TLC), vía Kaggle: *NYC Taxi Trip Data – Google Public Data*.
