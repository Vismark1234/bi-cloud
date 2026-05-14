# MODELO DWH POR DATAMART Y USO

## 1) Alcance

Este documento separa el modelo por area (datamart logico) y explica para que sirve cada uno en analisis BI.

Nota:
- Los datamarts son logicos. En dbt no existen tablas fisicas `DM_*`.
- Se consumen las mismas tablas de `marts/facts` y `marts/dimensions`.

## 2) Vista rapida

| Datamart | Area | Uso principal |
|---|---|---|
| `DM_COMERCIAL` | Comercial | Conversion de orden a envio y facturacion de servicio |
| `DM_OPERACIONES` | Operaciones | Eficiencia operativa de envios y viajes |
| `DM_FINANZAS_COBRANZA` | Finanzas/Cobranza | Ingreso facturado, cobranza y mora |
| `DM_RRHH_COSTOS` | RRHH/Control de costos | Productividad laboral y costo operativo |
| `DM_TELEMETRIA` | Telemetria/Monitoreo | Eventos, alertas y salud de flota |

## 3) Datamarts por area

### `DM_COMERCIAL`

Uso BI:
- Medir demanda y conversion comercial.
- Controlar ordenes aprobadas, envios generados y monto facturado.
- Analizar tarifa, ruta, cliente y sucursal.

Hechos:
- `fact_orden_servicio`
- `fact_envio`
- `fact_facturacion`

Dimensiones:
- `dim_fecha`
- `dim_cliente`
- `dim_tarifa`
- `dim_ruta`
- `dim_sucursal`

KPIs tipicos:
- `cantidad_ordenes`
- `cantidad_envios`
- `% conversion orden->envio`
- `monto_facturado_bob`
- `ticket promedio por orden/envio`
- `% devoluciones`

Preguntas que responde:
- Que clientes/rutas generan mas ingreso.
- Donde se cae la conversion del proceso comercial.
- Que sucursales venden mas y con mejor cumplimiento.

### `DM_OPERACIONES`

Uso BI:
- Medir desempeno de despacho y transporte.
- Evaluar uso de capacidad, tiempos de ciclo y cumplimiento SLA.
- Monitorear viajes y eventos operativos.

Hechos:
- `fact_envio`
- `fact_viaje`
- `fact_tracking_evento`

Dimensiones:
- `dim_fecha`
- `dim_hora`
- `dim_sucursal`
- `dim_ruta`
- `dim_vehiculo`
- `dim_conductor`
- `dim_tipo_tracking_evento`

KPIs tipicos:
- `cumple_sla_recojo_flag`
- `tiempo_ciclo_horas`
- `ocupacion_pct`
- `cantidad_envios_asignados`
- `viaje_finalizado_flag`
- `alertas_criticas_count`

Preguntas que responde:
- Que rutas o vehiculos tienen menor eficiencia.
- Donde hay mayor desviacion de SLA.
- Que conductores/unidades concentran mas alertas.

### `DM_FINANZAS_COBRANZA`

Uso BI:
- Medir facturacion y recuperacion de cartera.
- Analizar mora, oportunidad de pago y metodos de pago.
- Integrar vista comercial con flujo financiero.

Hechos:
- `fact_facturacion`
- `fact_pago`
- `fact_orden_servicio`
- `fact_envio`

Dimensiones:
- `dim_fecha`
- `dim_cliente`
- `dim_factura`
- `dim_metodo_pago`

KPIs tipicos:
- `total_linea_bob` (facturado)
- `monto_bob` (cobrado)
- `% cobranza sobre facturado`
- `dias_cobro_desde_emision`
- `dias_mora_pago`
- `% pago_tardio_flag`

Preguntas que responde:
- Cuanto se factura vs cuanto se cobra.
- Que clientes/metodos de pago presentan mayor mora.
- Que parte del ingreso comercial ya se convirtio en efectivo.

### `DM_RRHH_COSTOS`

Uso BI:
- Relacionar costo de personal con productividad y costo operativo.
- Monitorear ausentismo, horas extra y costo total por area/sucursal.
- Apoyar analisis de eficiencia financiera-operativa.

Hechos:
- `fact_rrhh_mensual`
- `fact_viaje`
- `fact_facturacion`

Dimensiones:
- `dim_fecha`
- `dim_empleado`
- `dim_sucursal`
- `dim_vehiculo`

KPIs tipicos:
- `salario_base_bob`
- `liquido_pagable_bob`
- `tasa_ausentismo_pct`
- `horas_extra`
- `costo_operativo_total_bob`
- `ingreso/costo por sucursal`

Preguntas que responde:
- Cuanto cuesta operar por sucursal y periodo.
- Si el ausentismo impacta productividad o costo.
- Si el ingreso cubre los costos laborales y operativos.

### `DM_TELEMETRIA`

Uso BI:
- Monitorear salud operativa de viajes y flota con datos de eventos.
- Detectar alertas criticas y riesgos mecanicos.
- Analizar continuidad de senal y cobertura de telemetria.

Hechos:
- `fact_tracking_evento`
- `fact_viaje`

Dimensiones:
- `dim_fecha`
- `dim_hora`
- `dim_ruta`
- `dim_sucursal`
- `dim_vehiculo`
- `dim_conductor`
- `dim_tipo_tracking_evento`

KPIs tipicos:
- `cantidad_eventos`
- `alerta_critica_flag`
- `temperatura_motor_c`
- `velocidad_kmh`
- `cobertura_telemetria_pct`
- `interrupciones_senal_count`

Preguntas que responde:
- Que rutas/unidades tienen mas eventos criticos.
- Donde se pierde cobertura de telemetria.
- Que patrones anteceden fallas o sobrecostos.

## 4) Como se conectan entre areas

Claves de referencia analitica entre hechos:
- `fact_envio.id_orden_servicio` <-> `fact_orden_servicio.id_orden_servicio`
- `fact_facturacion.id_orden_servicio` <-> `fact_orden_servicio.id_orden_servicio`
- `fact_facturacion.id_envio` <-> `fact_envio.id_envio`
- `fact_pago.id_factura` <-> `fact_facturacion.id_factura`
- `fact_tracking_evento.id_envio` <-> `fact_envio.id_envio`
- `fact_tracking_evento.id_viaje` <-> `fact_viaje.id_viaje`

Uso recomendado:
- Para tableros estandar, priorizar modelo estrella (`fact -> dim`).
- Para analisis punta a punta del proceso, usar estas claves de referencia con cuidado de grano.

## 5) Recomendacion para Power BI

- Mantener activas primero relaciones `fact -> dim`.
- Evitar activar muchas relaciones `fact <-> fact` al mismo tiempo.
- Si se requiere proceso completo, usar medidas DAX controladas o tablas puente.

