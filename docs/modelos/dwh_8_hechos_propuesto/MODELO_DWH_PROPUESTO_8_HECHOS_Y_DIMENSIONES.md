# MODELO DWH PROPUESTO CORREGIDO: 8 HECHOS, DIMENSIONES, ATRIBUTOS Y USO

## 1. Objetivo

Este documento describe una **propuesta dimensional simplificada** de `8 hechos`, corregida bajo criterio Kimball.

Las reglas aplicadas son:

- los hechos guardan `IDs/FKs`, metricas, montos, cantidades, tiempos y banderas
- las dimensiones guardan nombres, codigos, categorias, estados y clasificaciones
- las dimensiones **no se relacionan entre si**
- la simplificacion se hace consolidando costos, no mezclando procesos de distinto grano

## 2. Resumen general

### Cantidad de hechos

- `8` hechos

### Cantidad de dimensiones

- `14` dimensiones

### Hechos propuestos

- `fact_orden_servicio`
- `fact_envio`
- `fact_viaje`
- `fact_tracking_evento`
- `fact_facturacion`
- `fact_pago`
- `fact_rrhh_mensual`
- `fact_costo_mensual`

### Dimensiones propuestas

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
- `dim_estado_envio`
- `dim_empleado`
- `dim_tipo_costo`

## 3. Logica de simplificacion

### Que se mantiene como hecho

Se mantienen separados los procesos con identidad analitica propia:

- orden
- envio
- viaje
- tracking
- facturacion
- pago
- RRHH mensual

### Que se consolida en un solo hecho

Se consolidan en `fact_costo_mensual` los procesos de costo que, para BI gerencial, pueden verse juntos:

- combustible
- mantenimiento
- gasto fijo
- costos operativos resumidos

Esto reduce la cantidad de hechos sin destruir la capacidad de analisis 360.

## 4. Regla de modelado

### En dimensiones

Se guardan:

- descripciones
- estados
- tipos
- categorias
- ciudades
- codigos

### En hechos

Se guardan:

- claves
- IDs dimensionales
- cantidades
- montos
- tiempos
- porcentajes
- flags

## 5. Dimensiones propuestas

### `dim_fecha`

**Grano**

Una fila por fecha.

**Atributos**

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

**Grano**

Una fila por minuto del dia.

**Atributos**

- `id_hora`
- `hora`
- `minuto`
- `franja_horaria`

### `dim_cliente`

**Grano**

Una fila por cliente.

**Atributos**

- `id_cliente`
- `id_cliente_origen`
- `id_entidad_origen`
- `nombre_razon_social`
- `numero_documento`
- `segmento`
- `ciudad`
- `estado_cliente`
- `fecha_alta`

### `dim_tarifa`

**Grano**

Una fila por detalle de tarifa.

**Atributos**

- `id_tarifa_detalle`
- `id_tarifario_origen`
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

**Grano**

Una fila por sucursal.

**Atributos**

- `id_sucursal`
- `id_sucursal_origen`
- `codigo_sucursal`
- `ciudad`
- `activa_flag`
- `tipo_tenencia_inmueble`
- `monto_alquiler_mensual_bob`

### `dim_ruta`

**Grano**

Una fila por ruta.

**Importante**

No referencia a `dim_sucursal`. La ruta queda desnormalizada.

**Atributos**

- `id_ruta`
- `id_ruta_origen`
- `codigo_ruta`
- `codigo_sucursal_origen`
- `ciudad_origen`
- `codigo_sucursal_destino`
- `ciudad_destino`
- `distancia_km`

### `dim_vehiculo`

**Grano**

Una fila por vehiculo.

**Importante**

No referencia a `dim_sucursal`.

**Atributos**

- `id_vehiculo`
- `id_vehiculo_origen`
- `placa`
- `tipo_servicio`
- `capacidad_kg`
- `fecha_compra`
- `monto_compra_bob`
- `estado_vehiculo`
- `codigo_sucursal_base`
- `ciudad_sucursal_base`

### `dim_conductor`

**Grano**

Una fila por conductor.

**Importante**

No referencia a `dim_empleado` ni a `dim_sucursal`.

**Atributos**

- `id_conductor`
- `id_conductor_origen`
- `ci_conductor`
- `licencia_nro`
- `estado_conductor`
- `codigo_sucursal_base`
- `ciudad_sucursal_base`

### `dim_factura`

**Grano**

Una fila por factura.

**Importante**

No referencia a `dim_cliente`.

**Atributos**

- `id_factura`
- `id_factura_origen`
- `nro_factura`
- `fecha_emision`
- `fecha_vencimiento`
- `subtotal_bob`
- `impuesto_bob`
- `total_bob`
- `estado_cobro`

### `dim_metodo_pago`

**Grano**

Una fila por metodo de pago.

**Atributos**

- `id_metodo_pago`
- `metodo_pago`

### `dim_tipo_tracking_evento`

**Grano**

Una fila por tipo de evento.

**Atributos**

- `id_tipo_tracking_evento`
- `origen_evento`
- `tipo_tracking_evento`
- `categoria_tracking`
- `nivel_alerta`

### `dim_estado_envio`

**Grano**

Una fila por estado del envio.

**Atributos**

- `id_estado_envio`
- `codigo_estado_envio`
- `nombre_estado_envio`
- `categoria_estado_envio`
- `es_entrega_flag`
- `es_devolucion_flag`
- `es_cierre_flag`

### `dim_empleado`

**Grano**

Una fila por empleado.

**Importante**

No referencia a `dim_sucursal`.

**Atributos**

- `id_empleado`
- `id_empleado_origen`
- `ci`
- `nombre_completo`
- `cargo`
- `area`
- `fecha_ingreso`
- `estado_laboral`
- `codigo_sucursal_trabajo`
- `ciudad_sucursal_trabajo`

### `dim_tipo_costo`

**Grano**

Una fila por tipo de costo.

**Atributos**

- `id_tipo_costo`
- `tipo_costo`
- `categoria_costo`
- `subcategoria_costo`
- `origen_costo`
- `afecta_vehiculo_flag`
- `afecta_ruta_flag`
- `afecta_sucursal_flag`
- `es_costo_operativo_flag`
- `es_costo_estructural_flag`

## 6. Hechos propuestos

### `fact_orden_servicio`

**Grano**

Una fila por orden.

**Claves e IDs**

- `id_orden_servicio`
- `id_reserva_credito`
- `id_cuenta_credito`
- `id_cliente`
- `id_tarifa_detalle`
- `id_sucursal_origen`
- `id_sucursal_destino`
- `id_ruta`
- `id_fecha_creacion_orden`
- `id_fecha_vigencia_orden`
- `id_fecha_primer_envio`
- `id_fecha_ultimo_envio`

**Metricas y banderas**

- `cantidad_ordenes`
- `cantidad_envios`
- `orden_aprobada_flag`
- `envio_generado_flag`
- `envio_cerrado_flag`
- `orden_vencida_sin_envio_flag`
- `devuelto_flag`
- `facturado_flag`
- `precio_manual_flag`
- `total_orden_bob`
- `monto_reservado_bob`
- `limite_credito_bob_snapshot`
- `saldo_utilizado_bob_snapshot`
- `saldo_vencido_bob_snapshot`
- `credito_disponible_bob_snapshot`
- `monto_facturado_bob`
- `cantidad_lineas_facturadas`

### `fact_envio`

**Grano**

Una fila por envio.

**Claves e IDs**

- `id_envio`
- `id_orden_servicio`
- `id_reserva_credito`
- `id_cuenta_credito`
- `id_cliente`
- `id_tarifa_detalle`
- `id_sucursal_origen`
- `id_sucursal_destino`
- `id_ruta`
- `id_estado_envio`
- `id_fecha_creacion_orden`
- `id_fecha_vigencia_orden`
- `id_fecha_registro_envio`
- `id_fecha_compromiso_recojo`
- `id_fecha_cierre_envio`

**Metricas y banderas**

- `cantidad_envios`
- `orden_aprobada_flag`
- `envio_generado_flag`
- `envio_cerrado_flag`
- `cumple_sla_recojo_flag`
- `devuelto_flag`
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

**Grano**

Una fila por viaje.

**Claves e IDs**

- `id_viaje`
- `id_ruta`
- `id_vehiculo`
- `id_conductor`
- `id_sucursal_origen`
- `id_sucursal_destino`
- `id_fecha_salida`
- `id_fecha_llegada`

**Metricas y banderas**

- `cantidad_viajes`
- `distancia_km`
- `capacidad_kg`
- `peso_total_asignado_kg`
- `ocupacion_pct`
- `cantidad_envios_asignados`
- `costo_operativo_total_bob`
- `costo_operativo_no_combustible_bob`
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

### `fact_tracking_evento`

**Grano**

Una fila por evento.

**Claves e IDs**

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

**Metricas y banderas**

- `cantidad_eventos`
- `evento_critico_flag`
- `alerta_critica_flag`
- `gap_desde_evento_prev_min`
- `temperatura_motor_c`
- `velocidad_kmh`
- `mantenimiento_correctivo_30d_flag`

### `fact_facturacion`

**Grano**

Una fila por detalle de factura.

**Claves e IDs**

- `id_factura_detalle`
- `id_factura`
- `id_cliente`
- `id_orden_servicio`
- `id_envio`
- `id_ruta`
- `id_fecha_emision`
- `id_fecha_vencimiento`

**Metricas**

- `cantidad_lineas`
- `cantidad`
- `precio_unitario_bob`
- `total_linea_bob`

### `fact_pago`

**Grano**

Una fila por pago.

**Claves e IDs**

- `id_pago`
- `id_factura`
- `id_cliente`
- `id_metodo_pago`
- `id_fecha_pago`

**Metricas y banderas**

- `cantidad_pagos`
- `pago_tardio_flag`
- `monto_bob`
- `dias_cobro_desde_emision`
- `dias_mora_pago`

### `fact_rrhh_mensual`

**Grano**

Una fila por empleado y por periodo.

**Claves e IDs**

- `id_empleado`
- `id_sucursal`
- `id_fecha_periodo`

**Metricas**

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

### `fact_costo_mensual`

**Grano**

Una fila por combinacion de:

- `id_fecha_periodo`
- `id_tipo_costo`
- `id_sucursal`
- `id_vehiculo` cuando aplica
- `id_ruta` cuando aplica

**Claves e IDs**

- `id_costo_mensual`
- `id_fecha_periodo`
- `id_sucursal`
- `id_vehiculo`
- `id_ruta`
- `id_tipo_costo`

**Metricas y banderas**

- `cantidad_registros_origen`
- `cantidad_eventos_costo`
- `cantidad_abastecimientos`
- `cantidad_mantenimientos`
- `litros_combustible`
- `horas_parada_mantenimiento`
- `gasto_corporativo_flag`
- `costo_operativo_flag`
- `costo_estructural_flag`
- `monto_bob`

## 7. Que puede mostrar este modelo

Con esta version de `8 hechos` si se puede construir:

- `Cliente 360`
- `Empleado 360`
- `Vehiculo 360`
- `Sucursal 360`
- `Ruta 360`
- `Facturacion y cobranza 360`
- `Tracking y telemetria 360`
- `Costos consolidados 360`

## 8. Que se pierde frente al modelo de 10 hechos

Se pierde detalle evento a evento en:

- abastecimiento
- mantenimiento
- gasto fijo

Eso significa:

- para dashboard y gestion es suficiente
- para auditoria tecnica detallada es menos fuerte que el modelo de `10 hechos`

## 9. Conclusiones

Este modelo de `8 hechos` queda dimensionalmente correcto porque:

- los hechos contienen IDs y metricas
- las categorias viven en dimensiones
- las dimensiones no se relacionan entre si

## 10. Ruta del documento

- `c:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\docs\modelos\dwh_8_hechos_propuesto\MODELO_DWH_PROPUESTO_8_HECHOS_Y_DIMENSIONES.md`
