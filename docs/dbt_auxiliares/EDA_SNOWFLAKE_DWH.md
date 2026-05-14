# EDA Snowflake DWH

Script para conectarse a Snowflake con las mismas variables usadas por `dbt`, extraer KPIs del DWH y generar:

- `eda_output/eda_report.html`
- `eda_output/charts/*.png`
- `eda_output/data/*.csv`

## Uso

Desde la carpeta `dbt_dwh_transportes`:

```powershell
python .\eda_snowflake_dwh.py
```

## Salida

El script genera un EDA inicial con:

- volumen por hecho
- ingreso facturado por mes
- flujo de ordenes vs envios
- SLA y tiempo de ciclo
- top rutas por ingreso
- cobranza por metodo de pago
- eventos de tracking por categoria
- costo laboral y ausentismo por area

## Requisitos

Tener configurado `.env` con:

- `DBT_SNOWFLAKE_ACCOUNT`
- `DBT_SNOWFLAKE_USER`
- `DBT_SNOWFLAKE_PASSWORD`
- `DBT_SNOWFLAKE_ROLE`
- `DBT_SNOWFLAKE_DATABASE`
- `DBT_SNOWFLAKE_WAREHOUSE`
- `DBT_SNOWFLAKE_SCHEMA`
