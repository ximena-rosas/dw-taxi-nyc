# Proyecto de Aula: Data Warehouse y Big Data — NYC Taxi 2018

## 1. Descripción del proyecto

Este proyecto tiene como objetivo diseñar e implementar una solución analítica basada en un Data Warehouse utilizando datos de viajes de taxis de Nueva York correspondientes a 2018.

La solución contempla la carga de datos, su preparación y transformación, la construcción de un modelo dimensional, la generación de estructuras analíticas y la visualización de indicadores mediante un dashboard interactivo.

## 2. Objetivos

- Implementar un proceso de carga de datos desde un archivo CSV hacia Google BigQuery.
- Utilizar una capa de staging para conservar los datos originales antes de su transformación.
- Diseñar e implementar un modelo dimensional para el análisis de los viajes.
- Construir consultas y estructuras analíticas para estudiar la demanda, los ingresos, la operación y el comportamiento temporal.
- Desarrollar un dashboard interactivo para consultar indicadores relevantes.
- Documentar el proceso de ejecución y organizar los componentes del proyecto mediante GitHub.

## 3. Herramientas y tecnologías

| Herramienta | Uso en el proyecto |
|---|---|
| Google Colab | Ejecución del notebook de carga de datos con Python. |
| Python y pandas | Inspección del archivo fuente y preparación para su carga. |
| Google Drive | Almacenamiento y acceso al archivo CSV. |
| Google BigQuery | Almacenamiento, transformación y procesamiento analítico de los datos. |
| SQL | Construcción de tablas, transformaciones y consultas analíticas. |
| GitHub | Control de versiones y documentación de los archivos del proyecto. |
| Looker Studio | Construcción del dashboard interactivo. |

## 4. Arquitectura general

El flujo de procesamiento de datos se organiza en las siguientes etapas:

1. **Fuente de datos:** archivo `taxi_trip_data.csv`.
2. **Extracción y carga:** ejecución del notebook de Google Colab para acceder al archivo y cargarlo en BigQuery.
3. **Staging:** almacenamiento inicial de los registros en la tabla `staging.taxi_trip_data`.
4. **Transformación:** limpieza, conversión de tipos y preparación de los datos mediante SQL en BigQuery.
5. **Data Warehouse:** organización de los datos mediante un modelo dimensional.
6. **Análisis OLAP:** generación de estructuras analíticas para estudiar diferentes dimensiones del negocio.
7. **Visualización:** presentación de indicadores mediante un dashboard interactivo en Looker Studio.

## 5. Estructura del repositorio

- `01_carga_staging.ipynb`: notebook de Google Colab utilizado para inspeccionar el archivo fuente y cargar los datos en la capa staging.
- `dw_taxi_nyc_bigquery.sql`: archivo SQL con los scripts del proyecto para la implementación y el procesamiento de los datos.
- `README.md`: documentación general del proyecto, las herramientas y el procedimiento de ejecución.

## 6. Proceso de carga de datos

El notebook `01_carga_staging.ipynb` utiliza Python, pandas y la biblioteca de Google Cloud para BigQuery.

El procedimiento contempla:

1. Autenticación de la cuenta de Google.
2. Montaje de Google Drive.
3. Inspección del archivo CSV.
4. Identificación de las columnas del archivo fuente.
5. Definición del esquema inicial con columnas de tipo `STRING`.
6. Carga del archivo en la tabla `staging.taxi_trip_data` del proyecto `dw-taxi-nyc`.
7. Validación del número de registros cargados.

La carga utiliza `WRITE_TRUNCATE`, por lo que el contenido de la tabla se reemplaza al repetir la ejecución.

**Resultado documentado:** el notebook reportó una carga de 10.000.000 de registros en BigQuery.

## 7. Requisitos para ejecutar el notebook

- Tener una cuenta de Google con acceso a Google Colab y Google Drive.
- Disponer del archivo `taxi_trip_data.csv` en la ubicación indicada por el notebook.
- Contar con acceso al proyecto de Google Cloud `dw-taxi-nyc`.
- Tener permisos para crear o reemplazar la tabla de destino en BigQuery.
- Completar el proceso de autenticación cuando el notebook lo solicite.

## 8. Procedimiento de ejecución

1. Abrir el notebook `01_carga_staging.ipynb` en Google Colab.
2. Verificar que el archivo CSV se encuentre en la ruta esperada de Google Drive.
3. Ejecutar las celdas en orden.
4. Autorizar el acceso a Google Drive y Google Cloud cuando sea solicitado.
5. Esperar a que finalice el proceso de carga.
6. Verificar el mensaje de resultado y el número de filas cargadas en BigQuery.

**Importante:** antes de volver a ejecutar la carga, verificar que se desea reemplazar el contenido de la tabla staging, dado que la configuración `WRITE_TRUNCATE` sobrescribe los datos existentes.

## 9. Seguridad y gestión de credenciales

El repositorio no debe contener contraseñas, claves privadas, archivos de credenciales ni tokens de acceso. La autenticación debe realizarse mediante los mecanismos de Google Colab y Google Cloud, respetando los permisos asignados a la cuenta.

## 10. Evidencias y recursos

- **Repositorio GitHub:** https://github.com/ximena-rosas/dw-taxi-nyc
- **Notebook de carga:** https://github.com/ximena-rosas/dw-taxi-nyc/blob/main/01_carga_staging.ipynb
- **Script SQL:** https://github.com/ximena-rosas/dw-taxi-nyc/blob/main/dw_taxi_nyc_bigquery.sql
- **Notebook en Google Colab:** https://colab.research.google.com/drive/1quvHGhOXSrPhF4Y84KqZiOkBlmBiFyuz?usp=sharing
- **Dashboard en Looker Studio:** [Agregar aquí el enlace compartible del dashboard].

Las evidencias de ejecución deben permitir verificar la autenticación, la carga de datos y el resultado obtenido en BigQuery.

## 11. Control de versiones

GitHub se utiliza como repositorio central para almacenar el código SQL, el notebook y la documentación del proyecto. Los cambios se deben registrar mediante commits descriptivos para facilitar el seguimiento de las modificaciones y la trazabilidad del desarrollo.
