# Configuracion Airbyte + Dagster + dbt Cloud/Core

Este repositorio transforma datos que Airbyte ya deja en Snowflake. No extrae datos desde Azure directamente con dbt.

## Flujo esperado

1. Airbyte sincroniza las conexiones hacia Snowflake.
2. Snowflake recibe datos raw en:
   - `PROYECTO_BI_TRANSPORTE_V2.MYSQL_COMERCIAL`
   - `PROYECTO_BI_TRANSPORTE_V2.PG_OPS`
   - `PROYECTO_BI_TRANSPORTE_V2.SQLSERVER_FIN`
   - `PROYECTO_BI_TRANSPORTE_V2.MONGO_TELEMETRIA`
3. Dagster dispara las sincronizaciones de Airbyte.
4. Cuando Airbyte termina, Dagster ejecuta `dbt build`.
5. dbt materializa dimensiones, hechos, intermedios y snapshots en:
   - `PROYECTO_BI_TRANSPORTE_V2.DWH_DEV_CLOUD`
   - `PROYECTO_BI_TRANSPORTE_V2.SNAPSHOTS_DWH_CLOUD`

## Connection IDs de Airbyte

| Origen | Connection ID | Schema raw |
|---|---|---|
| SQL Server | `d84d864f-bc99-4988-aa53-4bb1c3bc600c` | `SQLSERVER_FIN` |
| MySQL | `dc6f0dc4-8471-4934-b73d-fb5c8e0dd254` | `MYSQL_COMERCIAL` |
| PostgreSQL | `9b1a5173-1025-4d88-a710-4db8e31b2024` | `PG_OPS` |
| MongoDB | `2452d3c9-d8e0-4465-9f5e-5e4fa370bc21` | `MONGO_TELEMETRIA` |

## Variables requeridas en Dagster Cloud

Snowflake:

```text
DBT_TARGET=dev
DBT_SNOWFLAKE_ACCOUNT=YPVPKVZ-OG27302
DBT_SNOWFLAKE_USER=USR_DBT_PROYECTO_BI_TRANSPORTE_V2
DBT_SNOWFLAKE_PASSWORD=<password_activa>
DBT_SNOWFLAKE_ROLE=ROLE_DBT_PROYECTO_BI_TRANSPORTE_V2
DBT_SNOWFLAKE_DATABASE=PROYECTO_BI_TRANSPORTE_V2
DBT_SNOWFLAKE_WAREHOUSE=WH_PROYECTO_BI_TRANSPORTE_V2
DBT_SNOWFLAKE_SCHEMA=DWH_DEV_CLOUD
DBT_SNOWFLAKE_SNAPSHOT_SCHEMA=SNAPSHOTS_DWH_CLOUD
DBT_THREADS=4
```

Airbyte:

```text
AIRBYTE_API_BASE_URL=https://api.airbyte.com/v1
AIRBYTE_CLIENT_ID=<client_id_airbyte>
AIRBYTE_CLIENT_SECRET=<client_secret_airbyte>
AIRBYTE_CONNECTION_ID_SQLSERVER=d84d864f-bc99-4988-aa53-4bb1c3bc600c
AIRBYTE_CONNECTION_ID_MYSQL=dc6f0dc4-8471-4934-b73d-fb5c8e0dd254
AIRBYTE_CONNECTION_ID_POSTGRES=9b1a5173-1025-4d88-a710-4db8e31b2024
AIRBYTE_CONNECTION_ID_MONGO=2452d3c9-d8e0-4465-9f5e-5e4fa370bc21
AIRBYTE_CONNECTION_IDS=d84d864f-bc99-4988-aa53-4bb1c3bc600c,dc6f0dc4-8471-4934-b73d-fb5c8e0dd254,9b1a5173-1025-4d88-a710-4db8e31b2024,2452d3c9-d8e0-4465-9f5e-5e4fa370bc21
AIRBYTE_POLL_INTERVAL_SECONDS=10
AIRBYTE_TIMEOUT_SECONDS=3600
```

## Fuentes obligatorias

El modelo completo del repo espera todas las fuentes declaradas en `dbt_project/models/sources.yml`.
Antes de ejecutar `dbt build`, corre `scripts/check_raw_sources.sql` en Snowflake.

Si alguna tabla sale como `MISSING`, no se debe borrar el modelo sin confirmar el cambio funcional. Primero revisa si Airbyte no la cargo, si quedo en otro schema, o si el origen no tiene esa tabla.

Tablas especialmente importantes para hechos completos:

- `PG_OPS.ABASTECIMIENTO_COMBUSTIBLE` alimenta `fact_abastecimiento_combustible` y costos de `fact_viaje`.
- `MONGO_TELEMETRIA.GPS_TRACK` y `MONGO_TELEMETRIA.GPS_ALERTA` alimentan telemetria y `fact_tracking_evento`.
- `SQLSERVER_FIN.FACTURA_DETALLE` alimenta `fact_facturacion`.
- `PG_OPS.EVENTO_ENVIO` alimenta cierre/estado de envios y tracking operativo.

## Validacion local sin ejecutar datos

```powershell
cd "D:\INTELIGENCIA DE NEGOCIOS\bi-cloud\dbt_project"
dbt parse --profiles-dir . --target dev
```

## Ejecucion local completa

Requiere `.env` con secretos reales.

```powershell
cd "D:\INTELIGENCIA DE NEGOCIOS\bi-cloud"
.\scripts\run_dbt.ps1 -Accion debug
.\scripts\run_dbt.ps1 -Accion build
.\scripts\start_dagster_local.ps1
```

