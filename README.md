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
- Si tus datos ya estan cargados en Snowflake, deja `AIRBYTE_CONNECTION_IDS=` vacio.
- En ese caso Dagster correra solo `dbt build` contra Snowflake.
- El target por defecto de este repo ya es `DWH_DEV_CLOUD`.
- Ejecuta antes el script [scripts/bootstrap_dwh_dev_cloud.sql](<C:/Users/Vismark Choque/INTELIGENCIA DE NEGOCIOS/bi_transportes_dagster_dbt_cloud/scripts/bootstrap_dwh_dev_cloud.sql>) para crear schemas y permisos.

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
- `workspace.yaml` queda solo para desarrollo local OSS.
- El `manifest.json` de dbt no se versiona; Dagster lo regenera con `dbt parse` cuando hace falta.
- El schedule `orquestacion_diaria_0700_schedule` queda en estado detenido por defecto para evitar ejecuciones antes de configurar secretos.

## Antes de subir a GitHub

1. Revisa que `.env` no aparezca en `git status`.
2. Revisa que `dbt_project/target/` y `dbt_project/logs/` no aparezcan en `git status`.
3. Si alguna vez subiste credenciales reales antes, rota esas credenciales.
