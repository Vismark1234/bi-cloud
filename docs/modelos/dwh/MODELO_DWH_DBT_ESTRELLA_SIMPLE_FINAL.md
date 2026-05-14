# MODELO DWH ESTRELLA SIMPLE PARA DBT + SNOWFLAKE

## 1) Objetivo

Definir un modelo dimensional **simple, entendible y alineado al OLTP actual**, pensado para construir con `dbt` en un flujo `ELT` sobre Snowflake.

Este modelo busca equilibrio entre:

- simplicidad para explicar,
- consistencia de datos,
- cobertura de requerimientos BI,
- y cercania al OLTP real.

## 2) Principios del modelo

1. El modelo final sera **estrella**, no snowflake complejo.
2. Se usaran **hechos y dimensiones**, no solo tablas anchas.
3. En la documentacion y en los marts finales se priorizan **IDs del negocio** (`id_*`) para que sea facil de entender.
4. Las `surrogate keys` se pueden generar en `dbt` cuando hagan falta tecnicamente, pero **no seran el centro del modelo funcional**.
5. Cada hecho tendra **un solo grano**.
6. En los hechos finales solo habra **IDs/FKs y metricas**.
7. Las tablas finales deben quedar listas para Power BI o cualquier herramienta BI sin rehacer logica.

## 3) Conteo final recomendado

| Elemento | Cantidad |
|---|---:|
| Dimensiones | 12 |
| Hechos | 6 |
| Datamarts | 5 |

## 4) Por que este tamano

No conviene volver al modelo de 13 hechos porque era demasiado fragmentado.

Tampoco conviene bajar artificialmente a 3 o 4 hechos porque eso obligaria a:

- mezclar granos incompatibles,
- duplicar metricas,
- o perder requerimientos de telemetria, cobranza o RRHH.

Por eso, para tu caso, **6 hechos y 12 dimensiones** es una version simple pero todavia correcta.

## 5) Capas dbt recomendadas

### `staging`

Copia y limpieza de tablas fuente:

- `stg_comercial__cliente`
- `stg_comercial__contrato`
- `stg_comercial__tarifa`
- `stg_comercial__orden_servicio`
- `stg_ops__sucursal`
- `stg_ops__ruta`
- `stg_ops__vehiculo`
- `stg_ops__conductor`
- `stg_ops__estado_envio`
- `stg_ops__envio`
- `stg_ops__evento_envio`
- `stg_ops__viaje`
- `stg_ops__envio_viaje_tramo`
- `stg_fin__cuenta_credito`
- `stg_fin__reserva_credito`
- `stg_fin__factura`
- `stg_fin__factura_detalle`
- `stg_fin__pago`
- `stg_rrhh__empleado`
- `stg_rrhh__nomina`
- `stg_rrhh__asistencia`
- `stg_gps__track`
- `stg_gps__alerta`

### `intermediate`

Integracion de procesos:

- `int_servicio`
- `int_servicio_facturacion`
- `int_viaje`
- `int_viaje_costos`
- `int_viaje_telemetria`
- `int_tracking_evento`
- `int_factura`
- `int_pago`
- `int_rrhh_mensual`

### `marts`

- dimensiones finales
- hechos finales
- vistas por datamart si las necesitas

## 6) Dimensiones finales

## 6.1 `dim_fecha`

**Grano:** 1 fila por fecha

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

## 6.2 `dim_hora`

**Grano:** 1 fila por hora/minuto

**Atributos**

- `id_hora`
- `hora`
- `minuto`
- `franja_horaria`

## 6.3 `dim_cliente`

**Fuente:** `cliente` + `entidad`

**Grano:** 1 fila por cliente

**Atributos**

- `id_cliente`
- `id_entidad`
- `nombre_razon_social`
- `numero_documento`
- `segmento`
- `ciudad`
- `estado_cliente`
- `fecha_alta`

**Nota**

Para mantenerlo simple, se recomienda `Type 1`.
Si luego quieres historizar cambios de segmento, puedes volverla `Type 2`.

## 6.4 `dim_tarifa`

**Fuente:** `tarifario` + `tarifario_detalle`

**Grano:** 1 fila por `id_tarifa_detalle`

**Atributos**

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

## 6.5 `dim_sucursal`

**Fuente:** `sucursal`

**Grano:** 1 fila por sucursal

**Atributos**

- `id_sucursal`
- `codigo_sucursal`
- `ciudad`
- `activa_flag`

## 6.6 `dim_ruta`

**Fuente:** `ruta`

**Grano:** 1 fila por ruta

**Atributos**

- `id_ruta`
- `codigo_ruta`
- `id_sucursal_origen`
- `id_sucursal_destino`
- `ciudad_origen`
- `ciudad_destino`
- `distancia_km`

## 6.7 `dim_vehiculo`

**Fuente:** `vehiculo` + `flota`

**Grano:** 1 fila por vehiculo

**Atributos**

- `id_vehiculo`
- `placa`
- `tipo_servicio`
- `capacidad_kg`
- `estado_vehiculo`
- `id_sucursal_base`

## 6.8 `dim_conductor`

**Fuente:** `conductor_operativo`

**Grano:** 1 fila por conductor

**Atributos**

- `id_conductor`
- `id_empleado_rrhh`
- `licencia_nro`
- `id_sucursal_base`
- `estado_conductor`

**Nota**

Para mantener el modelo simple, el analisis se hara con el **conductor principal** del viaje.
Si despues necesitas analisis detallado de relevos, eso se resuelve en una version avanzada con tabla puente.

## 6.9 `dim_factura`

**Fuente:** `factura`

**Grano:** 1 fila por factura

**Atributos**

- `id_factura`
- `nro_factura`
- `id_cliente`
- `fecha_emision`
- `fecha_vencimiento`
- `subtotal_bob`
- `impuesto_bob`
- `total_bob`
- `estado_cobro_actual`

## 6.10 `dim_metodo_pago`

**Fuente:** catalogo derivado de `pago.metodo_pago`

**Grano:** 1 fila por metodo de pago

**Atributos**

- `id_metodo_pago`
- `metodo_pago`

## 6.11 `dim_tipo_tracking_evento`

**Fuente:** `evento_envio`, `gps_alerta`, excepciones derivadas de `gps_track`

**Grano:** 1 fila por tipo de evento/alerta

**Atributos**

- `id_tipo_tracking_evento`
- `origen_evento`
- `tipo_tracking_evento`
- `categoria_tracking`
- `nivel_alerta`

## 6.12 `dim_empleado`

**Fuente:** `empleado`

**Grano:** 1 fila por empleado

**Atributos**

- `id_empleado`
- `ci`
- `nombre_completo`
- `cargo`
- `area`
- `id_sucursal`
- `fecha_ingreso`
- `estado_laboral`

**Nota**

Tambien puede quedarse como `Type 1` para no complicar el modelo.

## 7) Hechos finales

## 7.1 `fact_servicio`

**Tipo:** accumulating snapshot simple

**Grano:** 1 fila por `id_orden_servicio`

**Rol**

Es el hecho principal del negocio.
Une comercial + ejecucion + SLA + exposicion de credito.

**Condicion de validez**

Este hecho es correcto si:

- una `orden_servicio` genera como maximo un `envio`

**Nota tecnica**

Las metricas de credito tipo snapshot:

- `limite_credito_bob_snapshot`
- `saldo_utilizado_bob_snapshot`
- `saldo_vencido_bob_snapshot`
- `credito_disponible_bob_snapshot`

deben salir de un `snapshot` tecnico en `dbt` para no reescribir historia con el saldo actual.

**IDs que guarda**

- `id_orden_servicio`
- `id_envio`
- `id_reserva_credito`
- `id_cuenta_credito`
- `id_cliente`
- `id_contrato`
- `id_tarifa_detalle`
- `id_sucursal_origen`
- `id_sucursal_destino`
- `id_ruta`

**FKs a dimensiones**

- `id_fecha_creacion_orden`
- `id_fecha_vigencia_orden`
- `id_fecha_registro_envio`
- `id_fecha_compromiso_recojo`
- `id_fecha_cierre_envio`

**Metricas**

- `cantidad_ordenes`
- `precio_manual_flag`
- `orden_aprobada_flag`
- `envio_generado_flag`
- `envio_cerrado_flag`
- `orden_vencida_sin_envio_flag`
- `cumple_sla_recojo_flag`
- `devuelto_flag`
- `facturado_flag`
- `total_orden_bob`
- `monto_reservado_bob`
- `limite_credito_bob_snapshot`
- `saldo_utilizado_bob_snapshot`
- `saldo_vencido_bob_snapshot`
- `credito_disponible_bob_snapshot`
- `peso_envio_kg`
- `volumen_envio_m3`
- `valor_declarado_bob`
- `horas_orden_a_envio`
- `tiempo_ciclo_horas`
- `desviacion_sla_horas`
- `monto_facturado_bob`

**Requerimientos que cubre**

- R1-COM
- R2-COM
- R3-COM
- R4-COM
- R5-OPS
- R9-FIN

## 7.2 `fact_viaje`

**Tipo:** transaction fact resumido

**Grano:** 1 fila por `id_viaje`

**Rol**

Resume operacion del viaje, ocupacion, costo y telemetria.

Para simplificar, `id_conductor` representa el **conductor principal** del viaje.

**IDs que guarda**

- `id_viaje`
- `id_ruta`
- `id_vehiculo`
- `id_conductor`
- `id_sucursal_origen`
- `id_sucursal_destino`

**FKs a dimensiones**

- `id_fecha_salida`
- `id_fecha_llegada`

**Metricas**

- `cantidad_viajes`
- `distancia_km`
- `capacidad_kg`
- `peso_total_asignado_kg`
- `ocupacion_pct`
- `cantidad_envios_asignados`
- `costo_operativo_total_bob`
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

**Requerimientos que cubre**

- R6-OPS
- R7-OPS
- R8-OPS
- R13-TEL
- R14-TEL

## 7.3 `fact_tracking_evento`

**Tipo:** transaction fact

**Grano:** 1 fila por evento relevante

**Rol**

Sirve para trazabilidad y alertas.
No guarda el `gps_track` crudo completo, solo eventos utiles para BI.

Cuando el evento se vincule a un viaje con multiples conductores, se usara el **conductor principal** como referencia analitica.

**Fuentes**

- `evento_envio`
- `gps_alerta`
- excepciones relevantes derivadas de `gps_track`

**IDs que guarda**

- `origen_evento`
- `id_tracking_evento`
- `id_envio`
- `id_viaje`
- `id_ruta`
- `id_sucursal`
- `id_vehiculo`
- `id_conductor`
- `id_tipo_tracking_evento`

**FKs a dimensiones**

- `id_fecha_evento`
- `id_hora_evento`

**Metricas**

- `cantidad_eventos`
- `evento_critico_flag`
- `alerta_critica_flag`
- `gap_desde_evento_prev_min`
- `temperatura_motor_c`
- `velocidad_kmh`
- `mantenimiento_correctivo_30d_flag`

**Requerimientos que cubre**

- R8-OPS
- R13-TEL
- R14-TEL

## 7.4 `fact_facturacion`

**Tipo:** transaction fact

**Grano:** 1 fila por `id_factura_detalle`

**Rol**

Representa la linea facturada real.

**IDs que guarda**

- `id_factura_detalle`
- `id_factura`
- `id_cliente`
- `id_orden_servicio`
- `id_envio`
- `id_ruta`

**FKs a dimensiones**

- `id_fecha_emision`
- `id_fecha_vencimiento`

**Metricas**

- `cantidad_lineas`
- `cantidad`
- `precio_unitario_bob`
- `total_linea_bob`

**Requerimientos que cubre**

- R1-COM
- R3-COM
- R9-FIN
- R10-FIN

## 7.5 `fact_pago`

**Tipo:** transaction fact

**Grano:** 1 fila por `id_pago`

**Rol**

Representa el cobro real recibido.

**IDs que guarda**

- `id_pago`
- `id_factura`
- `id_cliente`
- `id_metodo_pago`

**FKs a dimensiones**

- `id_fecha_pago`

**Metricas**

- `cantidad_pagos`
- `pago_tardio_flag`
- `monto_bob`
- `dias_cobro_desde_emision`
- `dias_mora_pago`

**Requerimientos que cubre**

- R10-FIN
- R11-FIN

## 7.6 `fact_rrhh_mensual`

**Tipo:** periodic snapshot

**Grano:** 1 fila por (`id_empleado`, `periodo_mes`)

**Rol**

Resume costo y asistencia del personal por mes.

**IDs que guarda**

- `id_empleado`
- `id_sucursal`
- `periodo_mes`

**FKs a dimensiones**

- `id_fecha_periodo`

**Metricas**

- `cantidad_empleados`
- `salario_base_bob`
- `liquido_pagable_bob`
- `horas_trabajadas`
- `horas_extra`
- `dias_ausencia`
- `tasa_ausentismo_pct`
- `fte_equivalente`

**Requerimientos que cubre**

- R12-RRHH

## 8) Datamarts y que los compone

## 8.1 `DM_COMERCIAL`

**Hechos**

- `fact_servicio`
- `fact_facturacion`

**Dimensiones**

- `dim_fecha`
- `dim_cliente`
- `dim_tarifa`
- `dim_ruta`
- `dim_sucursal`

## 8.2 `DM_OPERACIONES`

**Hechos**

- `fact_servicio`
- `fact_viaje`
- `fact_tracking_evento`

**Dimensiones**

- `dim_fecha`
- `dim_hora`
- `dim_sucursal`
- `dim_ruta`
- `dim_vehiculo`
- `dim_conductor`
- `dim_tipo_tracking_evento`

## 8.3 `DM_FINANZAS_COBRANZA`

**Hechos**

- `fact_facturacion`
- `fact_pago`
- `fact_servicio`

**Dimensiones**

- `dim_fecha`
- `dim_cliente`
- `dim_factura`
- `dim_metodo_pago`

## 8.4 `DM_RRHH_COSTOS`

**Hechos**

- `fact_rrhh_mensual`
- `fact_viaje`
- `fact_facturacion`

**Dimensiones**

- `dim_fecha`
- `dim_empleado`
- `dim_sucursal`
- `dim_vehiculo`

## 8.5 `DM_TELEMETRIA`

**Hechos**

- `fact_tracking_evento`
- `fact_viaje`

**Dimensiones**

- `dim_fecha`
- `dim_hora`
- `dim_ruta`
- `dim_sucursal`
- `dim_vehiculo`
- `dim_conductor`
- `dim_tipo_tracking_evento`

## 9) Uso de surrogate keys en dbt

### Regla simple

En el modelo funcional y en la documentacion:

- usa `id_cliente`, `id_ruta`, `id_vehiculo`, `id_factura`, etc.

En dbt:

- genera surrogate keys solo si son utiles para pruebas, relaciones internas o SCD

Ejemplo:

```sql
{{ dbt_utils.generate_surrogate_key(['id_cliente']) }} as cliente_sk
```

pero esa columna puede quedar como tecnica y no como eje de explicacion del modelo.

## 10) Tests dbt obligatorios

### Unicidad

- `fact_servicio.id_orden_servicio`
- `fact_viaje.id_viaje`
- `fact_tracking_evento (origen_evento, id_tracking_evento)`
- `fact_facturacion.id_factura_detalle`
- `fact_pago.id_pago`
- `fact_rrhh_mensual (id_empleado, periodo_mes)`

### Relaciones

- `fact_servicio.id_cliente` -> `dim_cliente.id_cliente`
- `fact_servicio.id_ruta` -> `dim_ruta.id_ruta`
- `fact_viaje.id_vehiculo` -> `dim_vehiculo.id_vehiculo`
- `fact_facturacion.id_factura` -> `dim_factura.id_factura`
- `fact_pago.id_factura` -> `dim_factura.id_factura`
- `fact_pago.id_metodo_pago` -> `dim_metodo_pago.id_metodo_pago`
- `fact_tracking_evento.id_tipo_tracking_evento` -> `dim_tipo_tracking_evento.id_tipo_tracking_evento`
- `fact_rrhh_mensual.id_empleado` -> `dim_empleado.id_empleado`

### Test de negocio clave

Validar que una orden no genere mas de un envio:

```sql
select id_orden_servicio, count(*) c
from {{ ref('stg_ops__envio') }}
group by 1
having count(*) > 1
```

Si devuelve filas, `fact_servicio` debe dividirse en dos hechos:

- `fact_orden_servicio`
- `fact_envio`

## 11) Veredicto final

Este es el modelo que mejor encaja con lo que pediste:

- simple de entender,
- con hechos y dimensiones reales,
- alineado al OLTP,
- pensado para `dbt` y `ELT`,
- y con hechos que guardan solo **IDs/FKs y metricas**.

## 12) Resumen ejecutivo

Tu modelo final recomendado es:

- **12 dimensiones**
- **6 hechos**
- **5 datamarts**
- **IDs del negocio visibles**
- **surrogate keys solo como soporte tecnico en dbt**
