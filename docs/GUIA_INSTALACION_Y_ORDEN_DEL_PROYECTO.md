# Guia de instalacion y orden del proyecto

## 1. Objetivo

Esta guia resume:

- que debes instalar
- por que se instala
- en que orden hacerlo
- en que orden ejecutar el flujo completo
- desde que ruta ejecutar cada comando

Aplica al proyecto ubicado en:

- `SIMULADOR_CARGA_DE_DATOS/`
- `dbt_dwh_transportes/`

Rutas base reales en esta maquina:

- raiz del proyecto: `C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS`
- simuladores: `C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\SIMULADOR_CARGA_DE_DATOS`
- dbt y EDA: `C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\dbt_dwh_transportes`
- documentacion: `C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\docs`

---

## 2. Arquitectura del proyecto

El flujo real de este proyecto es:

1. Generar y poblar datos OLTP en:
   - MySQL
   - PostgreSQL
   - SQL Server
   - MongoDB
2. Llevar esas fuentes a Snowflake con Airbyte.
3. Transformar y probar el DWH con dbt.
4. Analizar el DWH con scripts EDA.

---

## 3. Que instalar primero

## 3.1 Base minima obligatoria

### 1. Git

Para clonar y versionar el proyecto.

### 2. Python

Necesario para:

- el simulador OLTP
- el simulador de Mongo Atlas
- los scripts EDA de Snowflake

Recomendacion:

- Python 3.11+  
- En esta maquina se uso Python 3.14

### 3. Docker Desktop

Necesario si vas a levantar SQL Server en contenedor.

### 4. Motores OLTP

Debes tener disponibles estas bases:

- MySQL
- PostgreSQL
- SQL Server
- MongoDB local o Mongo Atlas

En este proyecto se usan estos nombres:

- MySQL: `gestion_comercial_db`
- PostgreSQL: `PROYECTO_BI`
- SQL Server: `finanzas_rrhh_db`
- MongoDB: `telemetria_gps_db_v2`

### 5. ODBC Driver para SQL Server en Windows

Necesario para `pyodbc` y conexiones desde Python.

Recomendado:

- `ODBC Driver 17 for SQL Server`
- o `ODBC Driver 18 for SQL Server`

Nota:

- el simulador ya tiene un fallback por PowerShell/.NET si `pyodbc` falla
- aun asi conviene tener el driver ODBC instalado

### 6. dbt + adapter Snowflake

Necesario para construir el DWH en Snowflake.

Paquete recomendado:

- `dbt-snowflake`

### 7. Snowflake

No es algo que instales como programa local.
Necesitas:

- cuenta
- usuario
- role
- warehouse
- database
- schema destino

En este proyecto se usa por defecto:

- account: `TU_ACCOUNT_SNOWFLAKE`
- user: `TU_USUARIO_SNOWFLAKE`
- role: `TU_ROLE_SNOWFLAKE`
- warehouse: `TU_WAREHOUSE_SNOWFLAKE`
- database: `TU_DATABASE_SNOWFLAKE`
- schema dbt: `DWH_DEV`

### 8. Airbyte

Necesario para mover datos desde OLTP hacia Snowflake.

Puede ser:

- Airbyte Cloud
- o Airbyte local

### 9. Opcionales utiles

- DBeaver: para revisar MySQL, PostgreSQL, SQL Server y Snowflake
- `bore` o `ngrok`: solo si Airbyte no puede llegar directamente a tus bases locales

---

## 4. Paquetes Python a instalar

Desde PowerShell:

```powershell
cd "C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS"
python -m pip install numpy pandas sqlalchemy faker pymongo pyodbc pymysql psycopg2-binary openpyxl matplotlib snowflake-connector-python dbt-snowflake
```

### Por que se usa cada uno

- `numpy`: generacion estadistica y distribuciones
- `pandas`: armado y transformacion de datasets
- `sqlalchemy`: conexiones y escritura a MySQL/PostgreSQL/SQL Server
- `faker`: datos sinteticos realistas
- `pymongo`: carga a MongoDB / Atlas
- `pyodbc`: conexion SQL Server
- `pymysql`: conexion MySQL
- `psycopg2-binary`: conexion PostgreSQL
- `openpyxl`: exportes Excel de contingencia
- `matplotlib`: graficos EDA
- `snowflake-connector-python`: consultas a Snowflake desde Python
- `dbt-snowflake`: transformacion del DWH en Snowflake

---

## 5. Orden recomendado de instalacion

Sigue este orden:

1. Instala `Git`.
2. Instala `Python`.
3. Instala `Docker Desktop`.
4. Instala el `ODBC Driver` de SQL Server.
5. Instala los paquetes Python del proyecto.
6. Deja operativos MySQL y PostgreSQL.
7. Levanta SQL Server en Docker.
8. Define si Mongo sera local o Atlas.
9. Configura Snowflake.
10. Configura Airbyte.
11. Recién despues ejecuta simuladores y dbt.

---

## 5.1 Regla general de rutas

Para evitar errores de archivo no encontrado:

- ejecuta el simulador OLTP desde la raiz del proyecto
- ejecuta el simulador de Mongo desde la raiz del proyecto
- ejecuta `dbt` y los EDA desde `dbt_dwh_transportes`
- si no quieres depender de la carpeta actual, usa rutas absolutas

Regla practica recomendada:

### Para simuladores

```powershell
cd "C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS"
```

### Para dbt y EDA

```powershell
cd "C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\dbt_dwh_transportes"
```

No mezcles rutas.
Ejemplo de error comun:

- estar dentro de `dbt_dwh_transportes`
- y tratar de correr `.\SIMULADOR_CARGA_DE_DATOS\...`

En ese caso la ruta relativa falla.

---

## 6. Infraestructura que debe quedar viva

Antes de poblar datos, deberias tener esto:

- MySQL escuchando en `localhost:3306`
- PostgreSQL escuchando en `localhost:5432`
- SQL Server escuchando en `localhost:14330`
- MongoDB local en `localhost:27017` o Mongo Atlas por URI

Para SQL Server en este proyecto:

- host: `localhost`
- port: `14330`
- user: `sa`
- password: la del contenedor activo

---

## 7. Configuracion de Snowflake para dbt

La carpeta de trabajo es:

- [dbt_dwh_transportes](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes)

Archivos importantes:

- [profiles.yml](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/profiles.yml)
- [profiles.example.yml](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/profiles.example.yml)
- [.env.example](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/.env.example)
- [cargar_env_y_dbt.ps1](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/cargar_env_y_dbt.ps1)

Debes completar tu `.env` real con:

```env
DBT_SNOWFLAKE_ACCOUNT=TU_ACCOUNT_SNOWFLAKE
DBT_SNOWFLAKE_USER=TU_USUARIO_SNOWFLAKE
DBT_SNOWFLAKE_PASSWORD=TU_PASSWORD_REAL
DBT_SNOWFLAKE_ROLE=TU_ROLE_SNOWFLAKE
DBT_SNOWFLAKE_DATABASE=TU_DATABASE_SNOWFLAKE
DBT_SNOWFLAKE_WAREHOUSE=TU_WAREHOUSE_SNOWFLAKE
DBT_SNOWFLAKE_SCHEMA=DWH_DEV
DBT_THREADS=4
```

Ruta donde debe vivir el archivo `.env`:

- `C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\dbt_dwh_transportes\.env`

No lo pongas en la raiz del proyecto.

---

## 8. Que schemas raw espera dbt en Snowflake

`dbt` espera estas fuentes raw:

- `MYSQL_COMERCIAL`
- `PG_OPS`
- `SQLSERVER_FIN`
- `MONGO_TELEMETRIA`

Eso sale de:

- [sources.yml](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/models/sources.yml)

Tablas esperadas:

### MySQL -> `MYSQL_COMERCIAL`

- `entidad`
- `cliente`
- `contrato_cliente`
- `tarifario`
- `tarifario_detalle`
- `orden_servicio`

### PostgreSQL -> `PG_OPS`

- `sucursal`
- `flota`
- `vehiculo`
- `conductor_operativo`
- `ruta`
- `viaje`
- `viaje_carga_resumen`
- `envio`
- `estado_envio`
- `evento_envio`
- `envio_viaje_tramo`
- `viaje_gasto_operativo`
- `viaje_liquidacion`

### SQL Server -> `SQLSERVER_FIN`

- `cuenta_credito_cliente`
- `reserva_credito`
- `factura`
- `factura_detalle`
- `pago`
- `mantenimiento_vehiculo`
- `empleado`
- `nomina`
- `asistencia_empleado`

### Mongo -> `MONGO_TELEMETRIA`

- `gps_track`
- `gps_alerta`

---

## 9. Reglas importantes para Airbyte

## 9.1 SQL Server

El simulador principal borra y regenera tablas completas.
Por eso, en Airbyte para `SQL Server -> Snowflake` conviene usar:

- `Full refresh | Overwrite`

Como minimo para:

- `factura`
- `factura_detalle`
- `pago`

Lo mas seguro:

- usar `Full refresh | Overwrite` para todo el source `SQLSERVER_FIN`

## 9.2 MySQL con bore/ngrok

Si Airbyte no puede ver tu MySQL local, usa:

- `bore`
- o `ngrok`

Y en Airbyte:

- `SSH Tunnel Method = No Tunnel`

Guia relacionada:

- [GUIA_AIRBYTE_MYSQL_BORE_NGROK.md](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/GUIA_AIRBYTE_MYSQL_BORE_NGROK.md)

## 9.3 Mongo

Si cargaste telemetria nueva en Mongo Atlas o Mongo local, luego debes sincronizar:

- `Mongo -> Snowflake`

Si no haces esa sync, `dbt` no encontrara:

- `MONGO_TELEMETRIA.GPS_TRACK`
- `MONGO_TELEMETRIA.GPS_ALERTA`

---

## 10. Orden correcto de ejecucion del proyecto

Este es el orden recomendado de trabajo:

### Paso 1. Levantar infraestructura

Deben estar operativos:

- MySQL
- PostgreSQL
- SQL Server
- Mongo local o Mongo Atlas
- Snowflake
- Airbyte

### Paso 2. Poblar OLTP relacional

Script principal:

- [simulador_carga_oltp_v4_todo_en_uno.py](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/SIMULADOR_CARGA_DE_DATOS/simulador_carga_oltp_v4_todo_en_uno.py)

Ejemplo:

```powershell
cd "C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS"
python ".\SIMULADOR_CARGA_DE_DATOS\simulador_carga_oltp_v4_todo_en_uno.py" --scale medium --skip-mongo
```

Ruta correcta del script:

- `C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\SIMULADOR_CARGA_DE_DATOS\simulador_carga_oltp_v4_todo_en_uno.py`

Notas:

- por defecto limpia las tablas relacionales antes de cargar
- si no quieres limpiar, usa `--skip-reset`
- si omites `cd` a la raiz, usa la ruta absoluta completa del script

### Paso 3. Poblar Mongo por separado

Si quieres telemetria basada en tus viajes reales de PostgreSQL:

```powershell
cd "C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS"
python ".\SIMULADOR_CARGA_DE_DATOS\simular_mongo_atlas_telemetria.py" --uri "TU_URI" --database telemetria_gps_db_v2 --source-mode postgres --pg-host localhost --pg-port 5432 --pg-user postgres --pg-password "TU_PASSWORD" --pg-db PROYECTO_BI
```

Script:

- [simular_mongo_atlas_telemetria.py](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/SIMULADOR_CARGA_DE_DATOS/simular_mongo_atlas_telemetria.py)

Ruta correcta del script:

- `C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\SIMULADOR_CARGA_DE_DATOS\simular_mongo_atlas_telemetria.py`

Si ya estas dentro de `dbt_dwh_transportes`, el comando correcto cambia a:

```powershell
python "..\SIMULADOR_CARGA_DE_DATOS\simular_mongo_atlas_telemetria.py" --uri "TU_URI" --database telemetria_gps_db_v2 --source-mode postgres --pg-host localhost --pg-port 5432 --pg-user postgres --pg-password "TU_PASSWORD" --pg-db PROYECTO_BI
```

### Paso 4. Sincronizar con Airbyte hacia Snowflake

Haz las syncs de:

- MySQL -> Snowflake
- PostgreSQL -> Snowflake
- SQL Server -> Snowflake
- Mongo -> Snowflake

### Paso 5. Construir el DWH con dbt

Desde:

- [dbt_dwh_transportes](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes)

Ruta de trabajo obligatoria recomendada:

```powershell
cd "C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\dbt_dwh_transportes"
```

Comandos:

```powershell
cd "C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\dbt_dwh_transportes"
.\cargar_env_y_dbt.ps1 -Accion debug
.\cargar_env_y_dbt.ps1 -Accion build
```

O manual:

```powershell
cd "C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\dbt_dwh_transportes"
dbt snapshot --profiles-dir .
dbt build --profiles-dir .
```

Ruta correcta del script auxiliar:

- `C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\dbt_dwh_transportes\cargar_env_y_dbt.ps1`

### Paso 6. Ejecutar los EDA

EDA base:

```powershell
cd "C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\dbt_dwh_transportes"
python ".\eda_snowflake_dwh.py"
```

EDA ejecutivo:

```powershell
cd "C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\dbt_dwh_transportes"
python ".\eda_snowflake_dwh_ejecutivo.py"
```

Scripts:

- [eda_snowflake_dwh.py](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/eda_snowflake_dwh.py)
- [eda_snowflake_dwh_ejecutivo.py](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/eda_snowflake_dwh_ejecutivo.py)

No ejecutes los EDA desde la raiz del proyecto usando `.\eda_snowflake...` porque ahi no existen.

---

## 11. Orden correcto si quieres recargar todo desde cero

Usa este orden:

1. Limpiar Mongo si corresponde.
2. Ejecutar el simulador relacional.
3. Ejecutar el simulador de Mongo.
4. En Airbyte, lanzar syncs fresh hacia Snowflake.
5. Ejecutar `dbt snapshot`.
6. Ejecutar `dbt build`.
7. Ejecutar los EDA.

Para SQL Server, si Airbyte venia con incremental y tu regeneraste datos:

- cambia a `Full refresh | Overwrite`
- vuelve a sincronizar

---

## 12. Instalaciones opcionales pero recomendadas

### DBeaver

Sirve para revisar manualmente:

- MySQL
- PostgreSQL
- SQL Server
- Snowflake

### bore / ngrok

Solo necesarios si Airbyte no puede conectarse directamente a tus motores locales.

### Docker Compose

Opcional si luego quieres empaquetar mejor la infraestructura local.

---

## 13. Resumen corto del orden

### Instalacion

1. Git
2. Python
3. Docker Desktop
4. ODBC Driver SQL Server
5. Paquetes Python
6. Motores OLTP
7. Snowflake
8. Airbyte
9. Opcionales: DBeaver, bore, ngrok

### Ejecucion

1. Simulador OLTP
2. Simulador Mongo
3. Airbyte -> Snowflake
4. dbt snapshot/build
5. EDA

---

## 13.1 Checklist de rutas antes de ejecutar

Antes de cada bloque, verifica esto:

### Si vas a correr el simulador OLTP

- Terminal ubicada en: `C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS`
- Comando correcto: `python ".\SIMULADOR_CARGA_DE_DATOS\simulador_carga_oltp_v4_todo_en_uno.py" ...`

### Si vas a correr el simulador Mongo

- Terminal ubicada en: `C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS`
- Comando correcto: `python ".\SIMULADOR_CARGA_DE_DATOS\simular_mongo_atlas_telemetria.py" ...`

### Si vas a correr dbt

- Terminal ubicada en: `C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\dbt_dwh_transportes`
- Debe existir ahi: `.env`
- Comando correcto: `.\cargar_env_y_dbt.ps1 -Accion build`

### Si vas a correr los EDA

- Terminal ubicada en: `C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\dbt_dwh_transportes`
- Comandos correctos:
  - `python ".\eda_snowflake_dwh.py"`
  - `python ".\eda_snowflake_dwh_ejecutivo.py"`

---

## 14. Archivos clave del proyecto

### Simulacion

- [simulador_carga_oltp_v4_todo_en_uno.py](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/SIMULADOR_CARGA_DE_DATOS/simulador_carga_oltp_v4_todo_en_uno.py)
- [simular_mongo_atlas_telemetria.py](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/SIMULADOR_CARGA_DE_DATOS/simular_mongo_atlas_telemetria.py)
- [sqlserver_sqlclient_bridge.ps1](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/SIMULADOR_CARGA_DE_DATOS/sqlserver_sqlclient_bridge.ps1)

### DWH

- [dbt_project.yml](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/dbt_project.yml)
- [sources.yml](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/models/sources.yml)
- [profiles.yml](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/profiles.yml)
- [cargar_env_y_dbt.ps1](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/cargar_env_y_dbt.ps1)

### Documentacion

- [README.md](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/README.md)
- [GUIA_CONFIGURACION_SNOWFLAKE_DBT.md](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/GUIA_CONFIGURACION_SNOWFLAKE_DBT.md)
- [GUIA_AIRBYTE_MYSQL_BORE_NGROK.md](C:/Users/Vismark%20Choque/INTELIGENCIA%20DE%20NEGOCIOS/dbt_dwh_transportes/GUIA_AIRBYTE_MYSQL_BORE_NGROK.md)
