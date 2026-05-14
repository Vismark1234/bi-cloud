# 6. Modelo Dimensional - Galaxy Schema (Kimball)

## 6.1 Tabla de Hechos

El modelo dimensional implementado sigue el enfoque **Galaxy Schema** (constelacion de hechos), permitiendo integrar multiples procesos del negocio logistico mediante dimensiones compartidas.

A diferencia del modelo anterior, este diseno incorpora procesos adicionales como trazabilidad de envios, facturacion y pagos, lo que proporciona una vision analitica integral del negocio.

### Hechos

`fact_orden_servicio`  
`id_orden_servicio, id_reserva_credito, id_cuenta_credito, id_cliente, id_contrato, id_tarifa_detalle, id_sucursal_origen, id_sucursal_destino, id_ruta, id_fecha_creacion_orden, id_fecha_vigencia_orden, id_fecha_primer_envio, id_fecha_ultimo_envio, id_fecha_primer_compromiso_recojo, id_fecha_ultimo_compromiso_recojo, id_fecha_ultimo_cierre_envio, cantidad_ordenes, cantidad_envios, precio_manual_flag, orden_aprobada_flag, envio_generado_flag, envio_cerrado_flag, orden_vencida_sin_envio_flag, devuelto_flag, facturado_flag, total_orden_bob, monto_reservado_bob, limite_credito_bob_snapshot, saldo_utilizado_bob_snapshot, saldo_vencido_bob_snapshot, credito_disponible_bob_snapshot, monto_facturado_bob, cantidad_lineas_facturadas`

`fact_envio`  
`id_envio, id_orden_servicio, id_reserva_credito, id_cuenta_credito, id_cliente, id_contrato, id_tarifa_detalle, id_sucursal_origen, id_sucursal_destino, id_ruta, id_fecha_creacion_orden, id_fecha_vigencia_orden, id_fecha_registro_envio, id_fecha_compromiso_recojo, id_fecha_cierre_envio, cantidad_envios, orden_aprobada_flag, envio_generado_flag, envio_cerrado_flag, cumple_sla_recojo_flag, devuelto_flag, facturado_flag, peso_envio_kg, volumen_envio_m3, valor_declarado_bob, horas_orden_a_envio, tiempo_ciclo_horas, desviacion_sla_horas, monto_facturado_bob, cantidad_lineas_facturadas`

`fact_viaje`  
`id_viaje, id_ruta, id_vehiculo, id_conductor, id_sucursal_origen, id_sucursal_destino, id_fecha_salida, id_fecha_llegada, cantidad_viajes, distancia_km, capacidad_kg, peso_total_asignado_kg, ocupacion_pct, cantidad_envios_asignados, costo_operativo_total_bob, costo_operativo_km_bob, viaje_finalizado_flag, sobrecapacidad_flag, mantenimiento_correctivo_flag_30d, cobertura_telemetria_pct, interrupciones_senal_count, alertas_totales_count, alertas_criticas_count, alertas_mecanicas_count, temp_max_motor_c, velocidad_promedio_kmh, costo_mantenimiento_30d_bob`

`fact_tracking_evento`  
`origen_evento, id_tracking_evento, id_envio, id_viaje, id_ruta, id_sucursal, id_vehiculo, id_conductor, id_tipo_tracking_evento, id_fecha_evento, id_hora_evento, cantidad_eventos, evento_critico_flag, alerta_critica_flag, gap_desde_evento_prev_min, temperatura_motor_c, velocidad_kmh, mantenimiento_correctivo_30d_flag`

`fact_facturacion`  
`id_factura_detalle, id_factura, id_cliente, id_orden_servicio, id_envio, id_ruta, id_fecha_emision, id_fecha_vencimiento, cantidad_lineas, cantidad, precio_unitario_bob, total_linea_bob`

`fact_pago`  
`id_pago, id_factura, id_cliente, id_metodo_pago, id_fecha_pago, cantidad_pagos, pago_tardio_flag, monto_bob, dias_cobro_desde_emision, dias_mora_pago`

`fact_rrhh_mensual`  
`id_empleado, id_sucursal, periodo_mes, id_fecha_periodo, cantidad_empleados, salario_base_bob, liquido_pagable_bob, horas_trabajadas, horas_extra, dias_ausencia, tasa_ausentismo_pct, fte_equivalente`

## 6.2 Tabla de Dimensiones

`DIM_FECHA`  
`id_fecha, fecha, anio, trimestre, mes, nombre_mes, semana_iso, dia_mes, dia_semana, fin_semana_flag`

`DIM_HORA`  
`id_hora, hora, minuto, franja_horaria`

`DIM_CLIENTE`  
`id_cliente, id_entidad, nombre_razon_social, numero_documento, segmento, ciudad, estado_cliente, fecha_alta`

`DIM_TARIFA`  
`id_tarifa_detalle, id_tarifario, tipo_tarifario, tipo_carga, origen_ciudad, destino_ciudad, peso_desde_kg, peso_hasta_kg, precio_unitario_bob, vigente_desde, vigente_hasta`

`DIM_SUCURSAL`  
`id_sucursal, codigo_sucursal, ciudad, activa_flag`

`DIM_RUTA`  
`id_ruta, codigo_ruta, id_sucursal_origen, id_sucursal_destino, ciudad_origen, ciudad_destino, distancia_km`

`DIM_VEHICULO`  
`id_vehiculo, placa, tipo_servicio, capacidad_kg, estado_vehiculo, id_sucursal_base`

`DIM_CONDUCTOR`  
`id_conductor, id_empleado_rrhh, licencia_nro, id_sucursal_base, estado_conductor`

`DIM_FACTURA`  
`id_factura, nro_factura, id_cliente, fecha_emision, fecha_vencimiento, subtotal_bob, impuesto_bob, total_bob, estado_cobro`

`DIM_METODO_PAGO`  
`id_metodo_pago, metodo_pago`

`DIM_TIPO_TRACKING_EVENTO`  
`id_tipo_tracking_evento, origen_evento, tipo_tracking_evento, categoria_tracking, nivel_alerta`

`DIM_EMPLEADO`  
`id_empleado, ci, nombre_completo, cargo, area, id_sucursal, fecha_ingreso, estado_laboral`

## 6.3 Aclaracion de cambios

Para esta version actual:
- `fact_evento_envio` pasa a `fact_tracking_evento`.
- Se agregan `fact_orden_servicio` y `fact_rrhh_mensual`.
- Ya no se listan como dimensiones actuales: `DIM_CONTRATO`, `DIM_ESTADO_ENVIO`, `DIM_TIPO_COSTO`.
