USE ROLE ROLE_DBT_PROYECTO_BI_TRANSPORTE_V2;
USE WAREHOUSE WH_PROYECTO_BI_TRANSPORTE_V2;
USE DATABASE PROYECTO_BI_TRANSPORTE_V2;
USE SCHEMA DWH_DEV_CLOUD;

-- A) Conteos base en el nuevo esquema
SELECT 'fact_facturacion' t, COUNT(*) n FROM FACT_FACTURACION
UNION ALL
SELECT 'dim_cliente' t, COUNT(*) n FROM DIM_CLIENTE
UNION ALL
SELECT 'raw_cliente' t, COUNT(*) n FROM PROYECTO_BI_TRANSPORTE_V2.MYSQL_COMERCIAL.CLIENTE
UNION ALL
SELECT 'raw_entidad' t, COUNT(*) n FROM PROYECTO_BI_TRANSPORTE_V2.MYSQL_COMERCIAL.ENTIDAD
UNION ALL
SELECT 'raw_factura' t, COUNT(*) n FROM PROYECTO_BI_TRANSPORTE_V2.SQLSERVER_FIN.FACTURA
UNION ALL
SELECT 'raw_factura_detalle' t, COUNT(*) n FROM PROYECTO_BI_TRANSPORTE_V2.SQLSERVER_FIN.FACTURA_DETALLE;

-- B) Confirmar mismatch actual
SELECT
  COUNT(*) AS total_fact,
  COUNT_IF(d.id_cliente IS NULL) AS sin_match_dim
FROM PROYECTO_BI_TRANSPORTE_V2.DWH_DEV_CLOUD.FACT_FACTURACION f
LEFT JOIN PROYECTO_BI_TRANSPORTE_V2.DWH_DEV_CLOUD.DIM_CLIENTE d
  ON f.id_cliente = d.id_cliente;

-- C) Ver si cambiar prioridad de llave arreglaria
WITH b AS (
  SELECT
    fd.id_factura_detalle,
    f.id_cliente AS id_cliente_factura,
    os.id_cliente AS id_cliente_orden
  FROM PROYECTO_BI_TRANSPORTE_V2.DWH_DEV_CLOUD.STG_FIN__FACTURA_DETALLE fd
  LEFT JOIN PROYECTO_BI_TRANSPORTE_V2.DWH_DEV_CLOUD.STG_FIN__FACTURA f
    ON fd.id_factura = f.id_factura
  LEFT JOIN PROYECTO_BI_TRANSPORTE_V2.DWH_DEV_CLOUD.STG_COMERCIAL__ORDEN_SERVICIO os
    ON fd.id_orden_servicio = os.id_orden_servicio
)
SELECT
  COUNT(*) AS total,
  COUNT_IF(d_actual.id_cliente IS NULL AND COALESCE(b.id_cliente_factura, b.id_cliente_orden) IS NOT NULL) AS sin_match_logica_actual,
  COUNT_IF(d_alt.id_cliente IS NULL AND COALESCE(b.id_cliente_orden, b.id_cliente_factura) IS NOT NULL) AS sin_match_si_priorizo_orden
FROM b
LEFT JOIN PROYECTO_BI_TRANSPORTE_V2.DWH_DEV_CLOUD.DIM_CLIENTE d_actual
  ON COALESCE(b.id_cliente_factura, b.id_cliente_orden) = d_actual.id_cliente
LEFT JOIN PROYECTO_BI_TRANSPORTE_V2.DWH_DEV_CLOUD.DIM_CLIENTE d_alt
  ON COALESCE(b.id_cliente_orden, b.id_cliente_factura) = d_alt.id_cliente;

-- D) Ver si la dimension cliente se recorta por falta de entidad
SELECT
  COUNT(*) AS clientes_raw,
  COUNT_IF(e.id_entidad IS NULL) AS clientes_sin_entidad
FROM PROYECTO_BI_TRANSPORTE_V2.MYSQL_COMERCIAL.CLIENTE c
LEFT JOIN PROYECTO_BI_TRANSPORTE_V2.MYSQL_COMERCIAL.ENTIDAD e
  ON c.id_entidad = e.id_entidad;
