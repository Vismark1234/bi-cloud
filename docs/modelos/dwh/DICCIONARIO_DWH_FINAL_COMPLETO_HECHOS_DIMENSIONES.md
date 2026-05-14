# DICCIONARIO DWH FINAL CORREGIDO: 10 HECHOS, DIMENSIONES, COLUMNAS Y USO

## 1. Objetivo

Este documento describe un **modelo dimensional corregido bajo criterio Kimball** para la version de `10 hechos`.

La correccion sigue estas reglas:

- los hechos contienen `IDs/FKs`, metricas, montos, cantidades, tiempos y banderas
- las dimensiones contienen descripciones, categorias, estados, tipos y contexto descriptivo
- las dimensiones **no se relacionan entre si**
- cuando un mismo contexto se usa varias veces, se resuelve por `role playing dimensions` desde el hecho

Por tanto:

- `dim_sucursal` no depende de `dim_ruta`
- `dim_ruta` no depende de `dim_sucursal`
- `dim_vehiculo` no depende de `dim_sucursal`
- `dim_conductor` no de<!--  -->pende de `dim_empleado`
- `dim_factura` no depende de `dim_cliente`

Todo el cruce se hace desde los hechos.

## 2. Resumen general

### Cantidad de hechos

- `10` hechos

### Cantidad de dimensiones

- `16` dimensiones

### Hechos del modelo

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

### Dimensiones del modelo

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
- `dim_tipo_combustible`
- `dim_categoria_gasto_fijo`
- `dim_tipo_mantenimiento`

## 3. Regla de modelado

### Reglas de derivacion desde el OLTP final

Para que el modelo dimensional pueda construirse **sin inventar datos** a partir del OLTP final, se fijan estas reglas:

- solo se documentan atributos que existen fisicamente en el OLTP final o que son derivables de forma deterministica
- `dim_factura` no incluye `subtotal_bob` ni `impuesto_bob`, porque el OLTP final de facturacion conserva `total_bob`
- `dim_estado_envio` se deriva del **ultimo registro** de `evento_envio`, porque en el OLTP final el estado del envio se obtiene de ese ultimo evento
- `envio_cerrado_flag` e `id_fecha_cierre_envio` solo deben activarse cuando exista un evento terminal de cierre, como `ENTREGADO` o `DEVUELTO`
- cada fila de `abastecimiento_combustible` pertenece siempre a `fact_abastecimiento_combustible` y solo puede aportar a **un** viaje consolidado en `fact_viaje`
- `fact_facturacion` es la fuente de verdad para el ingreso detallado; cualquier monto facturado resumido en `fact_envio` o `fact_orden_servicio` debe derivarse desde ahi sin doble conteo

### En dimensiones

Se guardan:

- nombres
- codigos descriptivos
- ciudades
- estados
- tipos
- categorias
- clasificaciones

### En hechos

Se guardan:

- claves de negocio
- claves dimensionales
- metricas
- montos
- cantidades
- tiempos
- porcentajes
- banderas

## 4. Dimensiones

### `dim_fecha`

**Que guarda**

Calendario analitico.

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

**Que guarda**

Calendario horario.

**Grano**

Una fila por minuto del dia.

**Atributos**

- `id_hora`
- `hora`
- `minuto`
- `franja_horaria`

### `dim_cliente`

**Que guarda**

Vista maestra del cliente comercial.

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

**Que guarda**

Detalle tarifario.

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

**Que guarda**

La sucursal operativa.

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

**Que guarda**

La ruta operativa ya desnormalizada.

**Grano**

Una fila por ruta.

**Importante**

No referencia a `dim_sucursal`. Solo guarda atributos descriptivos de origen y destino.

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

**Que guarda**

La vista maestra del vehiculo.

**Grano**

Una fila por vehiculo.

**Importante**

No referencia a `dim_sucursal`. La informacion de la base operativa del vehiculo queda desnormalizada.

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

**Que guarda**

La vista maestra del conductor operativo.

**Grano**

Una fila por conductor.

**Importante**

No referencia a `dim_empleado` ni a `dim_sucursal`. Todo el contexto descriptivo queda dentro de la propia dimension.

**Atributos**

- `id_conductor`
- `id_conductor_origen`
- `ci_conductor`
- `licencia_nro`
- `estado_conductor`
- `codigo_sucursal_base`
- `ciudad_sucursal_base`

### `dim_factura`

**Que guarda**

La cabecera analitica de la factura.

**Grano**

Una fila por factura.

**Importante**

No referencia a `dim_cliente`. La relacion cliente-factura vive en los hechos.

Ademas, esta dimension solo conserva atributos que existen en la cabecera de factura del OLTP final.

**Atributos**

- `id_factura`
- `id_factura_origen`
- `nro_factura`
- `fecha_emision`
- `fecha_vencimiento`
- `total_bob`
- `estado_cobro`

### `dim_metodo_pago`

**Que guarda**

Catalogo de metodos de pago.

**Grano**

Una fila por metodo de pago.

**Atributos**

- `id_metodo_pago`
- `metodo_pago`

### `dim_tipo_tracking_evento`

**Que guarda**

Catalogo conformado de eventos de tracking.

**Grano**

Una fila por tipo de evento.

**Atributos**

- `id_tipo_tracking_evento`
- `origen_evento`
- `tipo_tracking_evento`
- `categoria_tracking`
- `nivel_alerta`

### `dim_estado_envio`

**Que guarda**

 Catalogo dimensional del estado del envio derivado del ultimo registro en `evento_envio`.

**Grano**

Una fila por estado.

**Atributos**

- `id_estado_envio`
- `codigo_estado_envio`
- `nombre_estado_envio`
- `categoria_estado_envio`
- `es_entrega_flag`
- `es_devolucion_flag`
- `es_cierre_flag`

### `dim_empleado`

**Que guarda**

Vista maestra del empleado.

**Grano**

Una fila por empleado.

**Importante**

No referencia a `dim_sucursal`; la informacion de sucursal se desnormaliza en la dimension.

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

### `dim_tipo_combustible`

**Que guarda**

Catalogo de tipos de combustible.

**Grano**

Una fila por tipo.

**Atributos**

- `id_tipo_combustible`
- `tipo_combustible`
- `categoria_energia`
- `es_fosil_flag`

### `dim_categoria_gasto_fijo`

**Que guarda**

Catalogo de categorias de gasto fijo.

**Grano**

Una fila por categoria.

**Atributos**

- `id_categoria_gasto_fijo`
- `categoria_gasto_fijo`
- `grupo_gasto_fijo`
- `es_gasto_estructural_flag`
- `requiere_sucursal_flag`

### `dim_tipo_mantenimiento`

**Que guarda**

Catalogo de tipos de mantenimiento.

**Grano**

Una fila por tipo de mantenimiento.

**Atributos**

- `id_tipo_mantenimiento`
- `tipo_mantenimiento`
- `categoria_mantenimiento`
- `es_programado_flag`
- `es_correctivo_flag`

## 5. Hechos

### `fact_orden_servicio`

**Grano**

Una fila por orden de servicio.

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

**Importante**

- `id_estado_envio` representa el estado vigente del envio segun el ultimo evento disponible
- `id_fecha_cierre_envio` solo debe poblarse cuando el envio tenga un evento terminal de cierre
- `monto_facturado_bob` debe derivarse desde `fact_facturacion`, no desde una suma libre que pueda duplicar refacturaciones

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

**Importante**

- cada abastecimiento de combustible puede asignarse como maximo a un viaje
- los costos resumidos del viaje no deben duplicar los eventos de `fact_abastecimiento_combustible`

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

**Grano**

Una fila por evento de tracking.

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

**Importante**

Esta tabla es la fuente de verdad del ingreso facturado a nivel detalle.

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

Una fila por empleado y por mes.

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

### `fact_abastecimiento_combustible`

**Grano**

Una fila por abastecimiento.

**Claves e IDs**

- `id_abastecimiento`
- `id_vehiculo`
- `id_sucursal`
- `id_tipo_combustible`
- `id_fecha_abastecimiento`
- `id_hora_abastecimiento`

**Metricas**

- `cantidad_abastecimientos`
- `litros_combustible`
- `monto_combustible_bob`
- `precio_unitario_bob`

### `fact_gasto_fijo_mensual`

**Grano**

Una fila por gasto fijo.

**Claves e IDs**

- `id_gasto_fijo`
- `id_sucursal`
- `id_categoria_gasto_fijo`
- `id_fecha_periodo`
- `id_fecha_registro`

**Metricas y banderas**

- `cantidad_gastos`
- `monto_gasto_bob`
- `gasto_corporativo_flag`

### `fact_mantenimiento_vehiculo`

**Grano**

Una fila por mantenimiento.

**Claves e IDs**

- `id_mantenimiento`
- `id_vehiculo`
- `id_sucursal`
- `id_tipo_mantenimiento`
- `id_fecha_ingreso`
- `id_fecha_salida`

**Metricas y banderas**

- `cantidad_mantenimientos`
- `costo_repuestos_bob`
- `costo_mano_obra_bob`
- `costo_total_bob`
- `mantenimiento_cerrado_flag`
- `duracion_mantenimiento_horas`

## 6. Que permite mostrar este modelo

Con esta version de `10 hechos` se puede construir:

- `Cliente 360`
- `Empleado 360`
- `Vehiculo 360`
- `Sucursal 360`
- `Ruta 360`
- `Facturacion y cobranza 360`
- `Tracking y telemetria 360`
- `Costos detallados 360`

## 7. Ventaja frente al modelo de 8 hechos

La principal ventaja de esta version es que conserva detalle propio para:

- abastecimiento
- mantenimiento
- gasto fijo

Por tanto, esta version sirve mejor para:

- auditoria de costos
- control tecnico de flota
- analisis operativo detallado

## 8. Documento maestro

Ruta del archivo:

- `c:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\docs\modelos\dwh\DICCIONARIO_DWH_FINAL_COMPLETO_HECHOS_DIMENSIONES.md`
