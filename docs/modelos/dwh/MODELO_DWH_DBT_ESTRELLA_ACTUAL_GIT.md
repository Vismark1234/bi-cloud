# MODELO DWH DBT ESTRELLA ACTUAL (SNOWFLAKE)

## 1. Estado y alcance

Este documento describe el modelo dimensional vigente del proyecto `dbt_dwh_transportes`, alineado con el modelo OLTP final actualmente simulado y cargado hacia Snowflake.

- Fecha de actualizacion: `2026-04-08`
- Proyecto dbt: `dbt_dwh_transportes`
- Base raw en Snowflake: `PROYECTO_BI_TRANSPORTE`
- Schemas raw:
  - `MYSQL_COMERCIAL`
  - `PG_OPS`
  - `SQLSERVER_FIN`
  - `MONGO_TELEMETRIA`

Capas del modelo:

- `staging`: limpieza y tipado de fuentes
- `intermediate`: integracion y reglas analiticas
- `marts/dimensions`: dimensiones conformadas
- `marts/facts`: hechos de consumo BI

## 2. Conteo actual del modelo

- Dimensiones: `12`
- Hechos: `10`

Dimensiones vigentes:

- `dim_fecha`
- `dim_hora`
- `dim_cliente`
- `dim_tarifa`
- `dim_sucursal`
- `dim_ruta`
- `dim_vehiculo`
- `dim_conductor`
- `dim_factura`
- `dim_metodo_pago`
- `dim_tipo_tracking_evento`
- `dim_empleado`

Hechos vigentes:

- `fact_orden_servicio`
- `fact_envio`
- `fact_viaje`
- `fact_tracking_evento`
- `fact_facturacion`
- `fact_pago`
- `fact_rrhh_mensual`
- `fact_abastecimiento_combustible`
- `fact_gasto_fijo_mensual`
- `fact_mantenimiento_vehiculo`

## 3. Dimensiones

### `dim_fecha`

Grano:
- Una fila por fecha calendario.

Uso:
- Analisis temporal comun para todos los hechos.

Atributos:
- `id_fecha`
- `fecha`
- `anio`
- `trimestre`
- `mes`
- `nombre_mes`
- `semana_iso`
- `dia_mes`
- `dia_semana`
- `fin_semana_flag`

### `dim_hora`

Grano:
- Una fila por minuto del dia.

Uso:
- Analisis horario de telemetria, abastecimientos y eventos.

Atributos:
- `id_hora`
- `hora`
- `minuto`
- `franja_horaria`

### `dim_cliente`

Grano:
- Una fila por cliente comercial.

Uso:
- Segmentacion comercial, analisis de ingresos, facturacion y cobranza.

Atributos:
- `id_cliente`
- `id_entidad`
- `nombre_razon_social`
- `numero_documento`
- `segmento`
- `ciudad`
- `estado_cliente`
- `fecha_alta`

### `dim_tarifa`

Grano:
- Una fila por detalle tarifario.

Uso:
- Analisis de precio, rango de peso, tipo de carga y vigencia de tarifarios.

Nota:
- Incluye una fila tecnica manual con `id_tarifa_detalle = 0`.

Atributos:
- `id_tarifa_detalle`
- `id_tarifario`
- `tipo_tarifario`
- `tipo_carga`
- `origen_ciudad`
- `destino_ciudad`
- `peso_desde_kg`
- `peso_hasta_kg`
- `precio_unitario_bob`
- `vigente_desde`
- `vigente_hasta`

### `dim_sucursal`

Grano:
- Una fila por sucursal operativa.

Uso:
- Analisis por ciudad, sucursal, tenencia de inmueble y costos asociados.

Atributos:
- `id_sucursal`
- `codigo_sucursal`
- `ciudad`
- `activa_flag`
- `tipo_tenencia_inmueble`
- `monto_alquiler_mensual_bob`

### `dim_ruta`

Grano:
- Una fila por ruta operacional.

Uso:
- Analisis de origen-destino, distancia, viajes, SLA y costo por corredor.

Atributos:
- `id_ruta`
- `codigo_ruta`
- `id_sucursal_origen`
- `id_sucursal_destino`
- `ciudad_origen`
- `ciudad_destino`
- `distancia_km`

### `dim_vehiculo`

Grano:
- Una fila por vehiculo.

Uso:
- Analisis de flota, capacidad, compra, estado y costos por unidad.

Atributos:
- `id_vehiculo`
- `placa`
- `tipo_servicio`
- `capacidad_kg`
- `fecha_compra`
- `monto_compra_bob`
- `estado_vehiculo`
- `id_sucursal_base`

### `dim_conductor`

Grano:
- Una fila por conductor operativo.

Uso:
- Analisis de viajes, eventos y alertas por conductor.

Atributos:
- `id_conductor`
- `id_empleado_rrhh`
- `licencia_nro`
- `id_sucursal_base`
- `estado_conductor`

### `dim_factura`

Grano:
- Una fila por factura.

Uso:
- Analisis de facturacion, vencimiento y estado de cobro.

Atributos:
- `id_factura`
- `nro_factura`
- `id_cliente`
- `fecha_emision`
- `fecha_vencimiento`
- `subtotal_bob`
- `impuesto_bob`
- `total_bob`
- `estado_cobro`

### `dim_metodo_pago`

Grano:
- Una fila por metodo de pago.

Uso:
- Analisis de cobranza por canal de pago.

Nota:
- Incluye valor tecnico `NO_DEFINIDO`.

Atributos:
- `id_metodo_pago`
- `metodo_pago`

### `dim_tipo_tracking_evento`

Grano:
- Una fila por tipo de evento de tracking.

Uso:
- Catalogar eventos operativos, alertas GPS y eventos derivados de telemetria.

Atributos:
- `id_tipo_tracking_evento`
- `origen_evento`
- `tipo_tracking_evento`
- `categoria_tracking`
- `nivel_alerta`

### `dim_empleado`

Grano:
- Una fila por empleado.

Uso:
- Analisis de RRHH, productividad, ausentismo y costo laboral.

Atributos:
- `id_empleado`
- `ci`
- `nombre_completo`
- `cargo`
- `area`
- `id_sucursal`
- `fecha_ingreso`
- `estado_laboral`

## 4. Hechos

### `fact_orden_servicio`

Grano:
- Una fila por orden de servicio.

Uso:
- Analisis comercial de ordenes, conversion a envio, credito y monto ordenado.

Columnas:
- `id_orden_servicio`
- `id_reserva_credito`
- `id_cuenta_credito`
- `id_cliente`
- `id_contrato`
- `id_tarifa_detalle`
- `id_sucursal_origen`
- `id_sucursal_destino`
- `id_ruta`
- `id_fecha_creacion_orden`
- `id_fecha_vigencia_orden`
- `id_fecha_primer_envio`
- `id_fecha_ultimo_envio`
- `id_fecha_primer_compromiso_recojo`
- `id_fecha_ultimo_compromiso_recojo`
- `id_fecha_ultimo_cierre_envio`
- `cantidad_ordenes`
- `cantidad_envios`
- `precio_manual_flag`
- `orden_aprobada_flag`
- `envio_generado_flag`
- `envio_cerrado_flag`
- `orden_vencida_sin_envio_flag`
- `devuelto_flag`
- `facturado_flag`
- `total_orden_bob`
- `monto_reservado_bob`
- `limite_credito_bob_snapshot`
- `saldo_utilizado_bob_snapshot`
- `saldo_vencido_bob_snapshot`
- `credito_disponible_bob_snapshot`
- `monto_facturado_bob`
- `cantidad_lineas_facturadas`

### `fact_envio`

Grano:
- Una fila por envio.

Uso:
- Analisis logistico y comercial del envio, SLA, devoluciones y facturacion.

Columnas:
- `id_envio`
- `id_orden_servicio`
- `id_reserva_credito`
- `id_cuenta_credito`
- `id_cliente`
- `id_contrato`
- `id_tarifa_detalle`
- `id_sucursal_origen`
- `id_sucursal_destino`
- `id_ruta`
- `id_fecha_creacion_orden`
- `id_fecha_vigencia_orden`
- `id_fecha_registro_envio`
- `id_fecha_compromiso_recojo`
- `id_fecha_cierre_envio`
- `cantidad_envios`
- `orden_aprobada_flag`
- `envio_generado_flag`
- `envio_cerrado_flag`
- `cumple_sla_recojo_flag`
- `devuelto_flag`
- `estado_final_codigo`
- `facturado_flag`
- `peso_envio_kg`
- `volumen_envio_m3`
- `valor_declarado_bob`
- `horas_orden_a_envio`
- `tiempo_ciclo_horas`
- `desviacion_sla_horas`
- `monto_facturado_bob`
- `cantidad_lineas_facturadas`

### `fact_viaje`

Grano:
- Una fila por viaje.

Uso:
- Analisis de operacion de flota, ocupacion, costos operativos, combustible y telemetria.

Columnas:
- `id_viaje`
- `id_ruta`
- `id_vehiculo`
- `id_conductor`
- `id_sucursal_origen`
- `id_sucursal_destino`
- `id_fecha_salida`
- `id_fecha_llegada`
- `cantidad_viajes`
- `distancia_km`
- `capacidad_kg`
- `peso_total_asignado_kg`
- `ocupacion_pct`
- `cantidad_envios_asignados`
- `costo_operativo_total_bob`
- `costo_operativo_no_combustible_bob`
- `gasto_peaje_bob`
- `gasto_viatico_bob`
- `gasto_otro_bob`
- `cantidad_abastecimientos`
- `litros_combustible_total`
- `costo_combustible_total_bob`
- `precio_combustible_promedio_bob_litro`
- `costo_operativo_km_bob`
- `viaje_finalizado_flag`
- `sobrecapacidad_flag`
- `mantenimiento_correctivo_flag_30d`
- `cobertura_telemetria_pct`
- `interrupciones_senal_count`
- `alertas_totales_count`
- `alertas_criticas_count`
- `alertas_mecanicas_count`
- `temp_max_motor_c`
- `velocidad_promedio_kmh`
- `costo_mantenimiento_30d_bob`

### `fact_tracking_evento`

Grano:
- Una fila por evento de tracking normalizado.

Uso:
- Analisis de trazabilidad operativa, alertas y telemetria unificada.

Columnas:
- `origen_evento`
- `id_tracking_evento`
- `id_envio`
- `id_viaje`
- `id_ruta`
- `id_sucursal`
- `id_vehiculo`
- `id_conductor`
- `id_tipo_tracking_evento`
- `id_fecha_evento`
- `id_hora_evento`
- `cantidad_eventos`
- `evento_critico_flag`
- `alerta_critica_flag`
- `gap_desde_evento_prev_min`
- `temperatura_motor_c`
- `velocidad_kmh`
- `mantenimiento_correctivo_30d_flag`

### `fact_facturacion`

Grano:
- Una fila por detalle de factura.

Uso:
- Analisis de ingreso facturado a nivel de linea, envio, orden y ruta.

Columnas:
- `id_factura_detalle`
- `id_factura`
- `id_cliente`
- `id_orden_servicio`
- `id_envio`
- `id_ruta`
- `id_fecha_emision`
- `id_fecha_vencimiento`
- `cantidad_lineas`
- `cantidad`
- `precio_unitario_bob`
- `total_linea_bob`

### `fact_pago`

Grano:
- Una fila por pago registrado.

Uso:
- Analisis de cobranza, mora y oportunidad de pago.

Columnas:
- `id_pago`
- `id_factura`
- `id_cliente`
- `id_metodo_pago`
- `id_fecha_pago`
- `cantidad_pagos`
- `pago_tardio_flag`
- `monto_bob`
- `dias_cobro_desde_emision`
- `dias_mora_pago`

### `fact_rrhh_mensual`

Grano:
- Una fila por empleado y periodo mensual.

Uso:
- Analisis de costo laboral, ausentismo, horas extra y FTE.

Columnas:
- `id_empleado`
- `id_sucursal`
- `periodo_mes`
- `id_fecha_periodo`
- `cantidad_empleados`
- `salario_base_bob`
- `horas_extra_monto_bob`
- `descuentos_bob`
- `liquido_pagable_bob`
- `horas_trabajadas`
- `horas_extra`
- `dias_ausencia`
- `tasa_ausentismo_pct`
- `fte_equivalente`

### `fact_abastecimiento_combustible`

Grano:
- Una fila por abastecimiento de combustible.

Uso:
- Analisis de litros, monto pagado y precio unitario por vehiculo, sucursal y tipo de combustible.

Columnas:
- `id_abastecimiento`
- `id_vehiculo`
- `id_sucursal`
- `id_fecha_abastecimiento`
- `id_hora_abastecimiento`
- `tipo_combustible`
- `cantidad_abastecimientos`
- `litros_combustible`
- `monto_combustible_bob`
- `precio_unitario_bob`

### `fact_gasto_fijo_mensual`

Grano:
- Una fila por gasto fijo mensual registrado.

Uso:
- Analisis de alquiler, servicios basicos y otros gastos estructurales por sucursal y periodo.

Columnas:
- `id_gasto_fijo`
- `id_sucursal`
- `id_fecha_periodo`
- `id_fecha_registro`
- `categoria_gasto_fijo`
- `tipo_tenencia_inmueble`
- `gasto_corporativo_flag`
- `alquiler_flag`
- `servicios_basicos_flag`
- `cantidad_gastos`
- `monto_gasto_bob`

### `fact_mantenimiento_vehiculo`

Grano:
- Una fila por mantenimiento de vehiculo.

Uso:
- Analisis de costo de repuestos, mano de obra, tiempo de mantenimiento y tipo de intervencion.

Columnas:
- `id_mantenimiento`
- `id_vehiculo`
- `id_sucursal`
- `id_fecha_ingreso`
- `id_fecha_salida`
- `tipo_mantenimiento`
- `cantidad_mantenimientos`
- `costo_repuestos_bob`
- `costo_mano_obra_bob`
- `costo_total_bob`
- `mantenimiento_cerrado_flag`
- `duracion_mantenimiento_horas`

## 5. Datamarts logicos y uso BI

### `DM_COMERCIAL`

Hechos principales:
- `fact_orden_servicio`
- `fact_envio`
- `fact_facturacion`

Dimensiones principales:
- `dim_fecha`
- `dim_cliente`
- `dim_tarifa`
- `dim_ruta`
- `dim_sucursal`

Uso:
- ingresos, conversion, ticket, rutas, segmentos y uso de credito

### `DM_OPERACIONES`

Hechos principales:
- `fact_envio`
- `fact_viaje`
- `fact_tracking_evento`
- `fact_abastecimiento_combustible`
- `fact_mantenimiento_vehiculo`

Dimensiones principales:
- `dim_fecha`
- `dim_hora`
- `dim_sucursal`
- `dim_ruta`
- `dim_vehiculo`
- `dim_conductor`
- `dim_tipo_tracking_evento`

Uso:
- SLA, ocupacion, combustible, trazabilidad, mantenimiento y salud operativa

### `DM_FINANZAS_COBRANZA`

Hechos principales:
- `fact_facturacion`
- `fact_pago`
- `fact_gasto_fijo_mensual`

Dimensiones principales:
- `dim_fecha`
- `dim_cliente`
- `dim_factura`
- `dim_metodo_pago`
- `dim_sucursal`

Uso:
- facturacion, cobranza, mora, gastos fijos y estructura de costos

### `DM_RRHH_COSTOS`

Hechos principales:
- `fact_rrhh_mensual`
- `fact_viaje`
- `fact_gasto_fijo_mensual`
- `fact_mantenimiento_vehiculo`

Dimensiones principales:
- `dim_fecha`
- `dim_empleado`
- `dim_sucursal`
- `dim_vehiculo`

Uso:
- costo laboral, ausentismo, horas extra y cruce con costos operativos

### `DM_TELEMETRIA_CONTROL`

Hechos principales:
- `fact_tracking_evento`
- `fact_viaje`

Dimensiones principales:
- `dim_fecha`
- `dim_hora`
- `dim_ruta`
- `dim_sucursal`
- `dim_vehiculo`
- `dim_conductor`
- `dim_tipo_tracking_evento`

Uso:
- alertas, continuidad de senal, temperatura critica y riesgo operacional

## 6. Cambios clave respecto al modelo anterior

- `estado_envio` deja de ser dependencia analitica; el estado se obtiene desde `evento_envio.codigo_evento`
- `dim_sucursal` incorpora `tipo_tenencia_inmueble` y `monto_alquiler_mensual_bob`
- `dim_vehiculo` incorpora `fecha_compra` y `monto_compra_bob`
- `fact_viaje` ahora incorpora combustible y desglose de costo operativo
- `fact_rrhh_mensual` incorpora `horas_extra_monto_bob` y `descuentos_bob`
- se agregan `fact_abastecimiento_combustible`, `fact_gasto_fijo_mensual` y `fact_mantenimiento_vehiculo`

## 7. Archivo maestro recomendado

Si se quiere un unico documento para describir el modelo dimensional actual de Snowflake, este archivo debe tomarse como el documento maestro:

- `c:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\docs\modelos\dwh\MODELO_DWH_DBT_ESTRELLA_ACTUAL_GIT.md`
