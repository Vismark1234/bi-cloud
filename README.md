# BI Transportes - Repo limpio para Dagster + dbt

Este directorio es una version ordenada del proyecto para subir a Git y preparar despliegue en Dagster Cloud sin arrastrar archivos locales, logs ni credenciales reales.

## Como trabaja con Snowflake

Este repo no descarga tablas de Snowflake para transformarlas localmente.

- `dbt_project/profiles.yml` usa el adapter `dbt-snowflake`.
- `dbt_project/models/sources.yml` apunta a schemas raw que ya existen en Snowflake.
- `dagster_project/definitions.py` ejecuta `dbt build`, por lo que las consultas y materializaciones corren dentro de Snowflake.

En otras palabras: Dagster solo orquesta y dbt ejecuta SQL en Snowflake para leer las fuentes raw y escribir las tablas/vistas transformadas ahi mismo.

## Esquema de salida nuevo

Este repo mantiene intacto tu esquema actual `DWH_DEV` y escribe la nueva corrida en:

- `PROYECTO_BI_TRANSPORTE_V2.DWH_DEV_CLOUD`
- `PROYECTO_BI_TRANSPORTE_V2.SNAPSHOTS_DWH_CLOUD`

Asi puedes probar y validar cambios sin sobrescribir tu DWH actual.

## Estructura

- `dagster_project/`: definiciones de Dagster y `workspace.yaml` para desarrollo local.
- `dbt_project/`: proyecto dbt con modelos, macros, snapshots y tests.
- `scripts/`: utilitarios para cargar `.env`, ejecutar dbt y arrancar Dagster local.
- `docs/`: documentacion funcional y tecnica copiada del proyecto original.
- `dagster_cloud.yaml`: entrada requerida por Dagster+ para registrar la code location.

Guia operativa principal:

- [docs/CONFIG_AIRBYTE_DAGSTER_DBT_CLOUD.md](docs/CONFIG_AIRBYTE_DAGSTER_DBT_CLOUD.md)

## Archivos sensibles que no se suben

- `.env`
- `dbt_project/target/`
- `dbt_project/logs/`
- `.dagster_home/`
- caches y archivos temporales

## Primer uso local

1. Instala dependencias:

```powershell
python -m pip install -r requirements.txt
```

2. Crea tu archivo local:

```powershell
Copy-Item .env.example .env
```

3. Completa `.env` con tus credenciales reales de Snowflake y, si aplica, Airbyte.

Importante:
- Para orquestar la ingesta completa, carga `AIRBYTE_CLIENT_ID`, `AIRBYTE_CLIENT_SECRET`
  y los connection IDs de Airbyte ya definidos en `.env.example`.
- Dagster ejecutara Airbyte primero y despues `dbt build` contra Snowflake.
- El target por defecto de este repo ya es `DWH_DEV_CLOUD`.
- Ejecuta antes el script [scripts/bootstrap_dwh_dev_cloud.sql](scripts/bootstrap_dwh_dev_cloud.sql) para crear schemas y permisos.
- Ejecuta [scripts/check_raw_sources.sql](scripts/check_raw_sources.sql) en Snowflake para confirmar que Airbyte ya cargo todas las fuentes esperadas por dbt.

4. Verifica dbt:

```powershell
.\scripts\run_dbt.ps1 -Accion debug
```

5. Arranca Dagster local:

```powershell
.\scripts\start_dagster_local.ps1
```

## Listo para Dagster Cloud

- El repositorio ya incluye `dagster_cloud.yaml` en la raiz, como pide la documentacion oficial de Dagster+.
- El repositorio ya incluye `pyproject.toml`, que es la estructura moderna que usa la guia oficial de Dagster+ Serverless.
- `workspace.yaml` queda solo para desarrollo local OSS.
- El `manifest.json` de dbt no se versiona; Dagster lo regenera con `dbt parse` cuando hace falta.
- El schedule `orquestacion_diaria_0700_schedule` queda en estado detenido por defecto para evitar ejecuciones antes de configurar secretos.

## Dagster+ Serverless

Segun la guia oficial de Dagster+ Serverless, el proyecto debe poder instalarse como paquete Python y exponer un unico modulo raiz para Dagster. Este repositorio ya queda preparado con:

- `pyproject.toml`
- `dagster_project` como modulo raiz
- `dagster_cloud.yaml` para compatibilidad con configuraciones heredadas

Antes del primer run en la nube, aun debes cargar en Dagster+ los secretos de Snowflake:

- `DBT_TARGET`
- `DBT_SNOWFLAKE_ACCOUNT`
- `DBT_SNOWFLAKE_USER`
- `DBT_SNOWFLAKE_PASSWORD`
- `DBT_SNOWFLAKE_ROLE`
- `DBT_SNOWFLAKE_DATABASE`
- `DBT_SNOWFLAKE_WAREHOUSE`
- `DBT_SNOWFLAKE_SCHEMA`
- `DBT_SNOWFLAKE_SNAPSHOT_SCHEMA`
- `DBT_THREADS`
- `AIRBYTE_API_BASE_URL`
- `AIRBYTE_CLIENT_ID`
- `AIRBYTE_CLIENT_SECRET`
- `AIRBYTE_CONNECTION_ID_SQLSERVER`
- `AIRBYTE_CONNECTION_ID_MYSQL`
- `AIRBYTE_CONNECTION_ID_POSTGRES`
- `AIRBYTE_CONNECTION_ID_MONGO`
- `AIRBYTE_CONNECTION_IDS`
- `AIRBYTE_POLL_INTERVAL_SECONDS`
- `AIRBYTE_TIMEOUT_SECONDS`

Connection IDs configurados para este proyecto:

| Origen | Airbyte connection ID | Schema raw esperado en Snowflake |
|---|---|---|
| SQL Server | `d84d864f-bc99-4988-aa53-4bb1c3bc600c` | `SQLSERVER_FIN` |
| MySQL | `dc6f0dc4-8471-4934-b73d-fb5c8e0dd254` | `MYSQL_COMERCIAL` |
| PostgreSQL | `9b1a5173-1025-4d88-a710-4db8e31b2024` | `PG_OPS` |
| MongoDB | `2452d3c9-d8e0-4465-9f5e-5e4fa370bc21` | `MONGO_TELEMETRIA` |

dbt espera que esos schemas contengan todas las tablas declaradas en `dbt_project/models/sources.yml`.
Si falta alguna fuente, no se debe borrar el modelo a ciegas: primero corrige la conexion/sync en Airbyte o confirma el cambio funcional.

## Antes de subir a GitHub

1. Revisa que `.env` no aparezca en `git status`.
2. Revisa que `dbt_project/target/` y `dbt_project/logs/` no aparezcan en `git status`.
3. Si alguna vez subiste credenciales reales antes, rota esas credenciales.
