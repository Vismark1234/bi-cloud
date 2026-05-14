# Configuracion de Snowflake para este proyecto dbt

## Ruta correcta del proyecto

`C:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\dbt_dwh_transportes`

## Archivos dejados en esta misma carpeta

- `profiles.yml`
- `.env`
- `.env.example`
- `.gitignore`
- `cargar_env_y_dbt.ps1`

## Que hace cada archivo

### `profiles.yml`

Es el perfil real que dbt usara cuando ejecutes:

```powershell
dbt ... --profiles-dir .
```

Lee todas las credenciales desde variables de entorno.

### `.env`

Contiene las variables necesarias para conectarte a Snowflake:

- `DBT_SNOWFLAKE_ACCOUNT`
- `DBT_SNOWFLAKE_USER`
- `DBT_SNOWFLAKE_PASSWORD`
- `DBT_SNOWFLAKE_ROLE`
- `DBT_SNOWFLAKE_DATABASE`
- `DBT_SNOWFLAKE_WAREHOUSE`
- `DBT_SNOWFLAKE_SCHEMA`
- `DBT_THREADS`

### `.env.example`

Es una plantilla de referencia.

### `.gitignore`

Impide subir `.env` al repositorio.

### `cargar_env_y_dbt.ps1`

Carga `.env` y corre dbt desde esta misma carpeta.

## Valor que debes editar

En `.env`, reemplaza:

```env
DBT_SNOWFLAKE_PASSWORD=CAMBIAR_POR_PASSWORD_REAL
```

por tu password real.

Actualmente el proyecto esta apuntando a:

```env
DBT_SNOWFLAKE_ACCOUNT=TU_ACCOUNT_SNOWFLAKE
DBT_SNOWFLAKE_USER=TU_USUARIO_SNOWFLAKE
DBT_SNOWFLAKE_ROLE=TU_ROLE_SNOWFLAKE
DBT_SNOWFLAKE_DATABASE=TU_DATABASE_SNOWFLAKE
DBT_SNOWFLAKE_WAREHOUSE=TU_WAREHOUSE_SNOWFLAKE
DBT_SNOWFLAKE_SCHEMA=DWH_DEV
```

## Comandos de uso desde esta carpeta

### Probar conexion

```powershell
.\cargar_env_y_dbt.ps1 -Accion debug
```

### Validar parseo

```powershell
.\cargar_env_y_dbt.ps1 -Accion parse
```

### Ejecutar transformaciones

```powershell
.\cargar_env_y_dbt.ps1 -Accion run
```

### Ejecutar todo con tests

```powershell
.\cargar_env_y_dbt.ps1 -Accion build
```

### Ejecutar solo staging e intermediate

```powershell
dbt run --profiles-dir . --select staging intermediate
```

### Ejecutar solo marts

```powershell
dbt run --profiles-dir . --select marts
```

### Ejecutar marts sin telemetria

```powershell
dbt run --profiles-dir . --select marts --exclude fact_tracking_evento int_viaje_telemetria stg_tel__gps_track stg_tel__gps_alerta dim_tipo_tracking_evento
```

## Conexion configurada

Esta configuracion apunta a:

- account: `TU_ACCOUNT_SNOWFLAKE`
- user: `TU_USUARIO_SNOWFLAKE`
- role: `TU_ROLE_SNOWFLAKE`
- database: `TU_DATABASE_SNOWFLAKE`
- warehouse: `TU_WAREHOUSE_SNOWFLAKE`
- schema objetivo de transformacion: `DWH_DEV`

## Nota importante

Este proyecto ya contiene modelos de telemetria:

- `models/staging/stg_tel__gps_track.sql`
- `models/staging/stg_tel__gps_alerta.sql`
- `models/intermediate/int_viaje_telemetria.sql`
- `models/marts/dimensions/dim_tipo_tracking_evento.sql`
- `models/marts/facts/fact_tracking_evento.sql`

dbt **no se conecta directo a MongoDB**. La telemetria debe llegar primero a Snowflake por Airbyte dentro del schema:

- `PROYECTO_BI_TRANSPORTE_V2.MONGO_TELEMETRIA`

La fuente Mongo recomendada en Airbyte debe leer:

- database: `telemetria_gps_db_v2`
- collections: `gps_track`, `gps_alerta`

Si por el momento no usaras telemetria, antes de ejecutar `dbt build` conviene excluir esos modelos o deshabilitarlos.
