# MODELO DWH FINAL: HECHOS, DIMENSIONES Y USO

## 1. Alcance

Este documento describe el modelo dimensional final actualmente implementado en `dbt_dwh_transportes` para Snowflake.

Se enfoca en responder:

- cuantas tablas de hechos existen
- cuantas dimensiones existen
- que guarda cada una
- para que se usa cada una
- que columnas tiene cada una

Base tecnica:

- Proyecto dbt: `dbt_dwh_transportes`
- Base raw en Snowflake: `PROYECTO_BI_TRANSPORTE`
- Schema de consumo principal: `DWH_DEV`

## 2. Resumen general

### Cantidad de dimensiones

- `12` dimensiones

### Cantidad de hechos

- `10` hechos

### Dimensiones vigentes

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

### Hechos vigentes

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

Que guarda:
- El calendario analitico del modelo.

Grano:
- Una fila por fecha.

Para que se usa:
- Analisis temporal diario, mensual, trimestral y anual.
- Series de tiempo para todos los hechos.

Columnas:
- `id_fecha`: clave surrogate de fecha en formato `YYYYMMDD`.
- `fecha`: fecha calendario.
- `anio`: anio numerico.
- `trimestre`: trimestre del anio.
- `mes`: numero de mes.
- `nombre_mes`: nombre corto del mes.
- `semana_iso`: semana ISO.
- `dia_mes`: dia del mes.
- `dia_semana`: dia ISO de la semana.
- `fin_semana_flag`: marca si la fecha cae en fin de semana.

### `dim_hora`

Que guarda:
- La dimension horaria del dia.

Grano:
- Una fila por minuto del dia.

Para que se usa:
- Analisis horario de eventos, telemetria y abastecimientos.

Columnas:
- `id_hora`: clave de hora en formato `HHMM`.
- `hora`: hora del dia.
- `minuto`: minuto.
- `franja_horaria`: agrupacion de hora (`MADRUGADA`, `MANANA`, `TARDE`, `NOCHE`).

### `dim_cliente`

Que guarda:
- La vista conformada del cliente comercial.

Grano:
- Una fila por cliente.

Para que se usa:
- Cliente 360.
- Segmentacion comercial.
- Analisis de ingresos, facturacion y cobranza.

Columnas:
- `id_cliente`: identificador del cliente.
- `id_entidad`: entidad base asociada.
- `nombre_razon_social`: nombre de la persona, empresa o institucion.
- `numero_documento`: CI, NIT u otro documento.
- `segmento`: clasificacion comercial.
- `ciudad`: ciudad del cliente.
- `estado_cliente`: estado de la entidad/cliente.
- `fecha_alta`: fecha de alta del cliente.

### `dim_tarifa`

Que guarda:
- La dimension de detalle tarifario usada por ordenes y envios.

Grano:
- Una fila por detalle de tarifa.

Para que se usa:
- Analisis por tipo tarifario.
- Analisis por tipo de carga.
- Analisis por rango de peso.
- Analisis de precio unitario por corredor.

Nota:
- Incluye una fila tecnica manual con `id_tarifa_detalle = 0`.

Columnas:
- `id_tarifa_detalle`: identificador del detalle de tarifa.
- `id_tarifario`: identificador del tarifario padre.
- `tipo_tarifario`: categoria del tarifario (`VENTANILLA`, `CONTRATO`, etc.).
- `tipo_carga`: tipo de carga tarifada.
- `origen_ciudad`: ciudad origen.
- `destino_ciudad`: ciudad destino.
- `peso_desde_kg`: peso minimo del rango.
- `peso_hasta_kg`: peso maximo del rango.
- `precio_unitario_bob`: precio unitario.
- `vigente_desde`: inicio de vigencia.
- `vigente_hasta`: fin de vigencia.

### `dim_sucursal`

Que guarda:
- La sucursal operativa y sus caracteristicas inmobiliarias.

Grano:
- Una fila por sucursal.

Para que se usa:
- Sucursal 360.
- Analisis por ciudad.
- Analisis de gastos fijos.
- Analisis de tenencia `PROPIA` vs `ALQUILADA`.

Columnas:
- `id_sucursal`: identificador de la sucursal.
- `codigo_sucursal`: codigo operacional.
- `ciudad`: ciudad de la sucursal.
- `activa_flag`: marca si la sucursal esta activa.
- `tipo_tenencia_inmueble`: `PROPIA` o `ALQUILADA`.
- `monto_alquiler_mensual_bob`: monto base de alquiler mensual.

### `dim_ruta`

Que guarda:
- La ruta operacional entre sucursal origen y destino.

Grano:
- Una fila por ruta.

Para que se usa:
- Analisis de corredores.
- Costo por ruta.
- SLA por ruta.
- Rendimiento logistica origen-destino.

Columnas:
- `id_ruta`: identificador de la ruta.
- `codigo_ruta`: codigo de la ruta.
- `id_sucursal_origen`: sucursal de origen.
- `id_sucursal_destino`: sucursal de destino.
- `ciudad_origen`: ciudad origen.
- `ciudad_destino`: ciudad destino.
- `distancia_km`: distancia de la ruta en kilometros.

### `dim_vehiculo`

Que guarda:
- La informacion maestra del vehiculo y su base operacional.

Grano:
- Una fila por vehiculo.

Para que se usa:
- Vehiculo 360.
- Analisis de flota.
- Capacidad y ocupacion.
- Compra y estado del activo.
- Cruce con combustible y mantenimiento.

Columnas:
- `id_vehiculo`: identificador del vehiculo.
- `placa`: placa del vehiculo.
- `tipo_servicio`: tipo de flota/servicio.
- `capacidad_kg`: capacidad de carga.
- `fecha_compra`: fecha de compra del vehiculo.
- `monto_compra_bob`: monto de compra.
- `estado_vehiculo`: `ACTIVO`, `MANTENIMIENTO` o equivalente cargado al DWH.
- `id_sucursal_base`: sucursal base del vehiculo.

### `dim_conductor`

Que guarda:
- La vista maestra del conductor operativo.

Grano:
- Una fila por conductor.

Para que se usa:
- Analisis de viajes por conductor.
- Riesgo y alertas por conductor.
- Desempeno operativo asociado.

Columnas:
- `id_conductor`: identificador del conductor.
- `id_empleado_rrhh`: referencia al empleado de RRHH.
- `licencia_nro`: numero de licencia.
- `id_sucursal_base`: sucursal base del conductor.
- `estado_conductor`: estado operativo del conductor.

### `dim_factura`

Que guarda:
- La cabecera analitica de factura.

Grano:
- Una fila por factura.

Para que se usa:
- Analisis de cartera.
- Vencimientos.
- Estado de cobro.
- Cruce con pagos y facturacion.

Columnas:
- `id_factura`: identificador de la factura.
- `nro_factura`: numero de factura.
- `id_cliente`: cliente facturado.
- `fecha_emision`: fecha de emision.
- `fecha_vencimiento`: fecha de vencimiento.
- `subtotal_bob`: subtotal facturado.
- `impuesto_bob`: impuesto facturado.
- `total_bob`: total facturado.
- `estado_cobro`: estado de cobro.

### `dim_metodo_pago`

Que guarda:
- El catalogo de metodos de pago observados en pagos.

Grano:
- Una fila por metodo de pago.

Para que se usa:
- Analisis de cobranza por metodo.
- Medicion de mora y velocidad de cobro por canal.

Columnas:
- `id_metodo_pago`: identificador del metodo de pago.
- `metodo_pago`: nombre del metodo.

### `dim_tipo_tracking_evento`

Que guarda:
- El catalogo unificado de eventos de tracking.

Grano:
- Una fila por tipo de evento.

Para que se usa:
- Analisis de trazabilidad operativa.
- Alertas GPS.
- Telemetria y eventos criticos.

Columnas:
- `id_tipo_tracking_evento`: identificador del tipo de evento.
- `origen_evento`: fuente del evento (`EVENTO_ENVIO`, `GPS_ALERTA`, `GPS_TRACK`).
- `tipo_tracking_evento`: nombre del evento.
- `categoria_tracking`: categoria analitica.
- `nivel_alerta`: nivel de alerta cuando aplica.

### `dim_empleado`

Que guarda:
- La vista maestra del empleado.

Grano:
- Una fila por empleado.

Para que se usa:
- Empleado 360.
- Analisis de RRHH.
- Costos laborales.
- Ausentismo y productividad.

Columnas:
- `id_empleado`: identificador del empleado.
- `ci`: documento del empleado.
- `nombre_completo`: nombre del empleado.
- `cargo`: cargo actual.
- `area`: area organizacional.
- `id_sucursal`: sucursal del empleado.
- `fecha_ingreso`: fecha de ingreso.
- `estado_laboral`: estado laboral.

## 4. Hechos

### `fact_orden_servicio`

Que guarda:
- La orden comercial como hecho base del proceso de venta.

Grano:
- Una fila por orden de servicio.

Para que se usa:
- Comercial 360.
- Conversion orden a envio.
- Analisis de credito comercial.
- Seguimiento de ordenes vencidas o no ejecutadas.

Columnas:
- `id_orden_servicio`: identificador de la orden.
- `id_reserva_credito`: reserva de credito asociada.
- `id_cuenta_credito`: cuenta de credito del cliente.
- `id_cliente`: cliente de la orden.
- `id_contrato`: contrato comercial asociado.
- `id_tarifa_detalle`: tarifa aplicada.
- `id_sucursal_origen`: sucursal origen.
- `id_sucursal_destino`: sucursal destino.
- `id_ruta`: ruta analitica asociada.
- `id_fecha_creacion_orden`: fecha de creacion.
- `id_fecha_vigencia_orden`: fecha de vigencia.
- `id_fecha_primer_envio`: fecha del primer envio asociado.
- `id_fecha_ultimo_envio`: fecha del ultimo envio asociado.
- `id_fecha_primer_compromiso_recojo`: primera promesa de recojo.
- `id_fecha_ultimo_compromiso_recojo`: ultima promesa de recojo.
- `id_fecha_ultimo_cierre_envio`: fecha del ultimo cierre de envio.
- `cantidad_ordenes`: contador tecnico de ordenes.
- `cantidad_envios`: cantidad de envios asociados.
- `precio_manual_flag`: marca si no hubo detalle de tarifa.
- `orden_aprobada_flag`: indica si la orden fue aprobada.
- `envio_generado_flag`: indica si la orden genero al menos un envio.
- `envio_cerrado_flag`: indica si existe envio cerrado.
- `orden_vencida_sin_envio_flag`: indica orden vencida sin envio.
- `devuelto_flag`: indica si alguna ejecucion termino devuelta.
- `facturado_flag`: indica si la orden ya tiene facturacion.
- `total_orden_bob`: total comercial de la orden.
- `monto_reservado_bob`: monto reservado de credito.
- `limite_credito_bob_snapshot`: limite snapshot.
- `saldo_utilizado_bob_snapshot`: saldo utilizado snapshot.
- `saldo_vencido_bob_snapshot`: saldo vencido snapshot.
- `credito_disponible_bob_snapshot`: credito disponible snapshot.
- `monto_facturado_bob`: monto facturado asociado.
- `cantidad_lineas_facturadas`: cantidad de lineas facturadas.

### `fact_envio`

Que guarda:
- El envio como unidad operativa y comercial del servicio prestado.

Grano:
- Una fila por envio.

Para que se usa:
- Envio 360.
- SLA.
- Tiempos de ciclo.
- Devoluciones.
- Facturacion por envio.

Columnas:
- `id_envio`: identificador del envio.
- `id_orden_servicio`: orden asociada.
- `id_reserva_credito`: reserva de credito asociada.
- `id_cuenta_credito`: cuenta de credito asociada.
- `id_cliente`: cliente del envio.
- `id_contrato`: contrato asociado.
- `id_tarifa_detalle`: tarifa aplicada.
- `id_sucursal_origen`: sucursal origen.
- `id_sucursal_destino`: sucursal destino.
- `id_ruta`: ruta asociada.
- `id_fecha_creacion_orden`: fecha de creacion de la orden.
- `id_fecha_vigencia_orden`: fecha de vigencia de la orden.
- `id_fecha_registro_envio`: fecha de registro del envio.
- `id_fecha_compromiso_recojo`: fecha compromiso de recojo.
- `id_fecha_cierre_envio`: fecha de cierre del envio.
- `cantidad_envios`: contador tecnico de envios.
- `orden_aprobada_flag`: si la orden estuvo aprobada.
- `envio_generado_flag`: marca tecnica de envio generado.
- `envio_cerrado_flag`: si el envio se cerro.
- `cumple_sla_recojo_flag`: si cumple SLA de recojo.
- `devuelto_flag`: si el envio termino devuelto.
- `estado_final_codigo`: codigo del ultimo estado/evento final.
- `facturado_flag`: si el envio fue facturado.
- `peso_envio_kg`: peso del envio.
- `volumen_envio_m3`: volumen del envio.
- `valor_declarado_bob`: valor declarado.
- `horas_orden_a_envio`: horas desde orden hasta registro.
- `tiempo_ciclo_horas`: tiempo total del ciclo.
- `desviacion_sla_horas`: desviacion contra SLA.
- `monto_facturado_bob`: monto facturado asociado.
- `cantidad_lineas_facturadas`: lineas facturadas asociadas.

### `fact_viaje`

Que guarda:
- El viaje operacional de la flota.

Grano:
- Una fila por viaje.

Para que se usa:
- Operacion 360.
- Analisis de capacidad.
- Costos operativos.
- Combustible.
- Telemetria.
- Riesgo operacional.

Columnas:
- `id_viaje`: identificador del viaje.
- `id_ruta`: ruta del viaje.
- `id_vehiculo`: vehiculo asignado.
- `id_conductor`: conductor principal.
- `id_sucursal_origen`: sucursal origen.
- `id_sucursal_destino`: sucursal destino.
- `id_fecha_salida`: fecha de salida.
- `id_fecha_llegada`: fecha de llegada.
- `cantidad_viajes`: contador tecnico de viajes.
- `distancia_km`: distancia recorrida.
- `capacidad_kg`: capacidad del vehiculo/viaje.
- `peso_total_asignado_kg`: peso total asignado.
- `ocupacion_pct`: porcentaje de ocupacion.
- `cantidad_envios_asignados`: cantidad de envios asociados.
- `costo_operativo_total_bob`: costo operativo total.
- `costo_operativo_no_combustible_bob`: costo operativo sin combustible.
- `gasto_peaje_bob`: gasto de peaje.
- `gasto_viatico_bob`: gasto de viatico.
- `gasto_otro_bob`: otros gastos operativos.
- `cantidad_abastecimientos`: abastecimientos vinculados al viaje.
- `litros_combustible_total`: litros consumidos/registrados.
- `costo_combustible_total_bob`: costo total de combustible.
- `precio_combustible_promedio_bob_litro`: precio promedio por litro.
- `costo_operativo_km_bob`: costo operativo por kilometro.
- `viaje_finalizado_flag`: si el viaje termino.
- `sobrecapacidad_flag`: si excedio capacidad.
- `mantenimiento_correctivo_flag_30d`: si tuvo correctivo cercano.
- `cobertura_telemetria_pct`: cobertura de telemetria.
- `interrupciones_senal_count`: interrupciones de senal.
- `alertas_totales_count`: alertas totales.
- `alertas_criticas_count`: alertas criticas.
- `alertas_mecanicas_count`: alertas mecanicas.
- `temp_max_motor_c`: temperatura maxima.
- `velocidad_promedio_kmh`: velocidad promedio.
- `costo_mantenimiento_30d_bob`: costo de mantenimiento cercano.

### `fact_tracking_evento`

Que guarda:
- El evento de tracking unificado entre operacion y telemetria.

Grano:
- Una fila por evento de tracking.

Para que se usa:
- Trazabilidad.
- Alertas criticas.
- Analisis de eventos por hora.
- Riesgo operacional.

Columnas:
- `origen_evento`: fuente del evento.
- `id_tracking_evento`: identificador tecnico del evento.
- `id_envio`: envio relacionado si aplica.
- `id_viaje`: viaje relacionado si aplica.
- `id_ruta`: ruta relacionada si aplica.
- `id_sucursal`: sucursal relacionada.
- `id_vehiculo`: vehiculo relacionado.
- `id_conductor`: conductor relacionado.
- `id_tipo_tracking_evento`: tipo de evento conformado.
- `id_fecha_evento`: fecha del evento.
- `id_hora_evento`: hora del evento.
- `cantidad_eventos`: contador tecnico.
- `evento_critico_flag`: marca de criticidad del evento.
- `alerta_critica_flag`: marca de alerta critica.
- `gap_desde_evento_prev_min`: minutos desde el evento anterior.
- `temperatura_motor_c`: temperatura si aplica.
- `velocidad_kmh`: velocidad si aplica.
- `mantenimiento_correctivo_30d_flag`: si luego hubo mantenimiento correctivo.

### `fact_facturacion`

Que guarda:
- La facturacion a nivel de detalle de linea.

Grano:
- Una fila por detalle de factura.

Para que se usa:
- Analisis de ingresos facturados.
- Cruce con clientes, envios, ordenes y rutas.

Columnas:
- `id_factura_detalle`: identificador del detalle.
- `id_factura`: factura asociada.
- `id_cliente`: cliente facturado.
- `id_orden_servicio`: orden asociada.
- `id_envio`: envio asociado.
- `id_ruta`: ruta asociada.
- `id_fecha_emision`: fecha de emision.
- `id_fecha_vencimiento`: fecha de vencimiento.
- `cantidad_lineas`: contador tecnico.
- `cantidad`: cantidad facturada.
- `precio_unitario_bob`: precio unitario.
- `total_linea_bob`: total de la linea.

### `fact_pago`

Que guarda:
- El pago efectivo registrado sobre factura.

Grano:
- Una fila por pago.

Para que se usa:
- Cobranza 360.
- Analisis de mora.
- Tiempo de cobro.
- Analisis por metodo de pago.

Columnas:
- `id_pago`: identificador del pago.
- `id_factura`: factura pagada.
- `id_cliente`: cliente.
- `id_metodo_pago`: metodo de pago.
- `id_fecha_pago`: fecha del pago.
- `cantidad_pagos`: contador tecnico.
- `pago_tardio_flag`: si fue tardio.
- `monto_bob`: monto pagado.
- `dias_cobro_desde_emision`: dias desde emision hasta pago.
- `dias_mora_pago`: dias de mora.

### `fact_rrhh_mensual`

Que guarda:
- El consolidado mensual de RRHH por empleado.

Grano:
- Una fila por empleado y mes.

Para que se usa:
- Empleado 360 en RRHH.
- Analisis de costo laboral.
- Ausentismo.
- Horas extra.
- Productividad.

Columnas:
- `id_empleado`: empleado.
- `id_sucursal`: sucursal del empleado.
- `periodo_mes`: mes del registro.
- `id_fecha_periodo`: clave de fecha del periodo.
- `cantidad_empleados`: contador tecnico.
- `salario_base_bob`: salario base.
- `horas_extra_monto_bob`: monto pagado por horas extra.
- `descuentos_bob`: descuentos.
- `liquido_pagable_bob`: liquido pagable.
- `horas_trabajadas`: horas trabajadas.
- `horas_extra`: horas extra.
- `dias_ausencia`: dias de ausencia.
- `tasa_ausentismo_pct`: tasa de ausentismo.
- `fte_equivalente`: FTE equivalente.

### `fact_abastecimiento_combustible`

Que guarda:
- El abastecimiento de combustible por evento.

Grano:
- Una fila por abastecimiento.

Para que se usa:
- Vehiculo 360.
- Control de litros y gasto en combustible.
- Analisis por tipo de combustible.
- Precio unitario por vehiculo o sucursal.

Columnas:
- `id_abastecimiento`: identificador del abastecimiento.
- `id_vehiculo`: vehiculo abastecido.
- `id_sucursal`: sucursal base analitica del vehiculo.
- `id_fecha_abastecimiento`: fecha del abastecimiento.
- `id_hora_abastecimiento`: hora del abastecimiento.
- `tipo_combustible`: tipo de combustible.
- `cantidad_abastecimientos`: contador tecnico.
- `litros_combustible`: litros cargados.
- `monto_combustible_bob`: monto pagado.
- `precio_unitario_bob`: precio unitario por litro.

### `fact_gasto_fijo_mensual`

Que guarda:
- El gasto fijo mensual administrativo/estructural.

Grano:
- Una fila por gasto fijo registrado.

Para que se usa:
- Sucursal 360.
- Analisis de alquiler.
- Servicios basicos.
- Gasto administrativo.
- Costo estructural por sucursal o corporativo.

Columnas:
- `id_gasto_fijo`: identificador del gasto fijo.
- `id_sucursal`: sucursal si aplica.
- `id_fecha_periodo`: periodo mensual.
- `id_fecha_registro`: fecha de registro.
- `categoria_gasto_fijo`: categoria (`ALQUILER`, `SERVICIOS_BASICOS`, etc.).
- `tipo_tenencia_inmueble`: `PROPIA` o `ALQUILADA`.
- `gasto_corporativo_flag`: marca si no pertenece a una sucursal puntual.
- `alquiler_flag`: marca si es alquiler.
- `servicios_basicos_flag`: marca si es servicios basicos.
- `cantidad_gastos`: contador tecnico.
- `monto_gasto_bob`: monto del gasto.

### `fact_mantenimiento_vehiculo`

Que guarda:
- El mantenimiento del vehiculo como hecho de costo y tiempo.

Grano:
- Una fila por mantenimiento.

Para que se usa:
- Vehiculo 360.
- Analisis de correctivos y preventivos.
- Costos de repuestos y mano de obra.
- Tiempos de parada del vehiculo.

Columnas:
- `id_mantenimiento`: identificador del mantenimiento.
- `id_vehiculo`: vehiculo intervenido.
- `id_sucursal`: sucursal base analitica del vehiculo.
- `id_fecha_ingreso`: fecha de ingreso al mantenimiento.
- `id_fecha_salida`: fecha de salida del mantenimiento.
- `tipo_mantenimiento`: tipo de mantenimiento.
- `cantidad_mantenimientos`: contador tecnico.
- `costo_repuestos_bob`: costo de repuestos.
- `costo_mano_obra_bob`: costo de mano de obra.
- `costo_total_bob`: costo total.
- `mantenimiento_cerrado_flag`: indica si el mantenimiento ya cerro.
- `duracion_mantenimiento_horas`: duracion en horas.

## 5. Para que sirve el modelo completo

Con este modelo se pueden construir dashboards y reportes 360 de:

- clientes
- empleados
- vehiculos
- sucursales
- rutas
- viajes
- facturacion
- cobranza
- costos laborales
- combustible
- mantenimiento
- gastos fijos
- telemetria y trazabilidad

## 6. Niveles de analisis que soporta

### Nivel estrategico

Uso:
- series de tiempo mensuales y anuales
- crecimiento del negocio
- costos estructurales
- rentabilidad operativa
- productividad general

### Nivel tactico

Uso:
- comparacion por sucursal
- comparacion por ruta
- comparacion por segmento
- comparacion por vehiculo o conductor
- control mensual de RRHH y costos

### Nivel operativo

Uso:
- seguimiento de envio
- seguimiento de viaje
- abastecimientos
- mantenimientos
- eventos de tracking
- alertas GPS

## 7. Documento maestro recomendado

Si se quiere un unico documento maestro del modelo dimensional final, este archivo debe usarse como referencia principal:

- `c:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\docs\modelos\dwh\MODELO_DWH_FINAL_HECHOS_DIMENSIONES_Y_USO.md`
