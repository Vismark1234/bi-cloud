USE ROLE ROLE_DBT_PROYECTO_BI_TRANSPORTE_V2;
USE WAREHOUSE WH_PROYECTO_BI_TRANSPORTE_V2;
USE DATABASE PROYECTO_BI_TRANSPORTE_V2;

WITH expected_sources AS (
    SELECT * FROM VALUES
      ('MYSQL_COMERCIAL', 'ENTIDAD'),
      ('MYSQL_COMERCIAL', 'CLIENTE'),
      ('MYSQL_COMERCIAL', 'CONTRATO_CLIENTE'),
      ('MYSQL_COMERCIAL', 'TARIFARIO'),
      ('MYSQL_COMERCIAL', 'TARIFARIO_DETALLE'),
      ('MYSQL_COMERCIAL', 'ORDEN_SERVICIO'),
      ('PG_OPS', 'SUCURSAL'),
      ('PG_OPS', 'FLOTA'),
      ('PG_OPS', 'VEHICULO'),
      ('PG_OPS', 'CONDUCTOR_OPERATIVO'),
      ('PG_OPS', 'RUTA'),
      ('PG_OPS', 'VIAJE'),
      ('PG_OPS', 'VIAJE_CARGA_RESUMEN'),
      ('PG_OPS', 'ENVIO'),
      ('PG_OPS', 'EVENTO_ENVIO'),
      ('PG_OPS', 'ENVIO_VIAJE_TRAMO'),
      ('PG_OPS', 'ABASTECIMIENTO_COMBUSTIBLE'),
      ('PG_OPS', 'VIAJE_GASTO_OPERATIVO'),
      ('PG_OPS', 'VIAJE_LIQUIDACION'),
      ('SQLSERVER_FIN', 'CUENTA_CREDITO_CLIENTE'),
      ('SQLSERVER_FIN', 'RESERVA_CREDITO'),
      ('SQLSERVER_FIN', 'FACTURA'),
      ('SQLSERVER_FIN', 'FACTURA_DETALLE'),
      ('SQLSERVER_FIN', 'PAGO'),
      ('SQLSERVER_FIN', 'MANTENIMIENTO_VEHICULO'),
      ('SQLSERVER_FIN', 'GASTO_FIJO_MENSUAL'),
      ('SQLSERVER_FIN', 'EMPLEADO'),
      ('SQLSERVER_FIN', 'NOMINA'),
      ('SQLSERVER_FIN', 'ASISTENCIA_EMPLEADO'),
      ('MONGO_TELEMETRIA', 'GPS_TRACK'),
      ('MONGO_TELEMETRIA', 'GPS_ALERTA')
    AS t(schema_name, table_name)
),
existing_tables AS (
    SELECT
      table_schema AS schema_name,
      table_name
    FROM information_schema.tables
    WHERE table_catalog = 'PROYECTO_BI_TRANSPORTE_V2'
      AND table_schema IN ('MYSQL_COMERCIAL', 'PG_OPS', 'SQLSERVER_FIN', 'MONGO_TELEMETRIA')
)
SELECT
  e.schema_name,
  e.table_name,
  CASE WHEN x.table_name IS NULL THEN 'MISSING' ELSE 'OK' END AS status
FROM expected_sources e
LEFT JOIN existing_tables x
  ON e.schema_name = x.schema_name
 AND e.table_name = x.table_name
ORDER BY e.schema_name, e.table_name;
