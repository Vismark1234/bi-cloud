# DOCUMENTACION BI ACTUALIZADA (BASE DWH ACTUAL)

## 1) Alcance y base tecnica

Este documento actualiza la documentacion de BI para que quede alineada al Data Warehouse actual.

Base de referencia:
- Proyecto: `dbt_dwh_transportes`
- Capa de consumo: `models/marts`
- Fecha de actualizacion: `2026-04-07`

Hechos vigentes:
- `fact_orden_servicio`
- `fact_envio`
- `fact_viaje`
- `fact_tracking_evento`
- `fact_facturacion`
- `fact_pago`
- `fact_rrhh_mensual`

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

## 2) Reemplazos obligatorios (modelo anterior -> modelo actual)

- `fact_envio_sla` -> `fact_envio`
- `fact_envio_tramo` -> `fact_viaje` + `fact_tracking_evento` (y `fact_envio` segun KPI)
- `fact_costo_total` -> `fact_viaje` (costos operativos) + `fact_rrhh_mensual` (costos laborales)
- `fact_factura_detalle` -> `fact_facturacion`
- `fact_evento_envio` -> `fact_tracking_evento`
- `dim_tipo_costo` -> no existe en marts actuales
- `dim_estado_envio` -> no existe en marts actuales
- `dim_estado_cobro` -> se usa `dim_factura.estado_cobro`

---

## 6.3 Requerimientos de Inteligencia de Negocios (BI)

### 6.3.1 Area Comercial

#### R1-COM - Analisis de ingresos y volumen por segmento
Pregunta clave:
- Como identificar con claridad que segmentos, rutas y periodos generan mayor ingreso en BOB y mayor volumen de carga.

Requerimiento:
- Analizar `fact_orden_servicio` y `fact_envio` por segmento, ruta y periodo.

Preguntas de dashboard:
- Que segmento genera mayor ingreso mensual y trimestral.
- Que rutas origen-destino concentran mayor facturacion y mayor peso.
- Como evoluciona el ticket promedio por segmento.

#### R2-COM - Conversion de ordenes a envios
Pregunta clave:
- Como medir cuantas ordenes aprobadas se convierten en envios reales y cuantas vencen sin ejecucion.

Requerimiento:
- Medir conversion `fact_orden_servicio` -> `fact_envio` por estado y vigencia.

Preguntas de dashboard:
- Que porcentaje de ordenes aprobadas termina en envio.
- Cuantas ordenes vencen sin ejecucion.
- Cual es el tiempo promedio entre creacion de orden y registro de envio.

#### R3-COM - Rendimiento de tarifarios y rangos de peso
Pregunta clave:
- Que combinaciones de tipo tarifario, tipo de carga y rango de peso aportan mas ingresos y rotacion.

Requerimiento:
- Evaluar `dim_tarifa` contra ingresos reales de `fact_orden_servicio` y `fact_facturacion`.

Preguntas de dashboard:
- Que tipo de tarifario (VENTANILLA/CONTRATO) genera mas ingresos.
- Que rangos de peso son los mas vendidos.
- Que rutas tienen mayor rendimiento por regla tarifaria.

#### R4-COM - Riesgo de credito comercial B2B
Pregunta clave:
- Como monitorear uso de lineas de credito y reservas para vender mas sin elevar riesgo.

Requerimiento:
- Monitorear campos snapshot de credito en `fact_orden_servicio`.

Preguntas de dashboard:
- Que clientes consumen mas del 80 por ciento de su credito.
- Que monto esta reservado y aun no convertido en ingreso.
- Que clientes concentran mayor saldo vencido.

### 6.3.2 Area Operaciones Logisticas

#### R5-OPS - Cumplimiento de SLA de recojo en oficina
Pregunta clave:
- Como medir cumplimiento real de SLA por sucursal y ruta.

Requerimiento:
- Medir SLA usando `fact_envio.cumple_sla_recojo_flag` y tiempos de `fact_envio`.

Preguntas de dashboard:
- Cual es el porcentaje de cumplimiento de SLA por sucursal destino.
- Que rutas tienen mayor desviacion de tiempo.
- Que tipo de carga incumple mas el tiempo prometido.

#### R6-OPS - Eficiencia de capacidad de flota
Pregunta clave:
- Como identificar viajes con subutilizacion o sobrecapacidad.

Requerimiento:
- Comparar capacidad vs peso usando `fact_viaje` (`capacidad_kg`, `peso_total_asignado_kg`, `ocupacion_pct`, `sobrecapacidad_flag`).

Preguntas de dashboard:
- Cual es la ocupacion promedio por ruta y por vehiculo.
- En que viajes hubo sobrecapacidad.
- Que rutas operan de forma recurrente por debajo de capacidad optima.

#### R7-OPS - Costos operativos por viaje y ruta
Pregunta clave:
- Como detectar rutas, viajes y vehiculos de mayor costo operativo.

Requerimiento:
- Consolidar costos con `fact_viaje` (`costo_operativo_total_bob`, `costo_operativo_km_bob`).

Preguntas de dashboard:
- Que rutas tienen mayor costo operativo total.
- Cual es el costo promedio por viaje y por kilometro.
- Que vehiculos presentan mayor gasto recurrente.

#### R8-OPS - Trazabilidad y riesgos con telemetria
Pregunta clave:
- Como integrar trazabilidad y telemetria para detectar riesgos operativos.

Requerimiento:
- Integrar `fact_tracking_evento` con `fact_viaje` y `fact_envio`.

Preguntas de dashboard:
- Que sucursales tienen mas tiempo entre eventos criticos.
- Que alertas son mas frecuentes por ruta.
- Que conductores concentran mayor incidencia de alertas criticas.

### 6.3.3 Area Financiera, Cobranza y RRHH

#### R9-FIN - Cobertura de facturacion sobre operacion cerrada
Pregunta clave:
- Como controlar la brecha entre envios cerrados y lineas facturadas.

Requerimiento:
- Comparar `fact_envio` (cerrados) vs `fact_facturacion` (lineas facturadas).

Preguntas de dashboard:
- Cuantos envios cerrados no tienen linea de factura.
- Cual es el monto pendiente de facturar por mes.
- Que clientes concentran mayor pendiente de facturacion.

#### R10-FIN - Antiguedad de cartera y riesgo de mora
Pregunta clave:
- Como clasificar cartera por antiguedad para priorizar cobranza.

Requerimiento:
- Usar `fact_facturacion`, `fact_pago` y `dim_factura` (estado y vencimiento).

Preguntas de dashboard:
- Cual es el saldo vencido total y su tendencia.
- Que clientes concentran mora mayor a 30, 60 y 90 dias.
- Que porcentaje de la facturacion esta en estado vencido.

#### R11-FIN - Eficiencia de cobranza (DSO y metodos de pago)
Pregunta clave:
- Como medir DSO y desempeno por metodo de pago.

Requerimiento:
- Medir cobro con `fact_pago` y relacionarlo con `fact_facturacion`/`dim_factura`.

Preguntas de dashboard:
- Cual es el DSO promedio por mes.
- Que metodo de pago tiene menor tiempo de cobro.
- Que clientes presentan mayor proporcion de pagos tardios.

#### R12-RRHH - Costo laboral, asistencia y productividad
Pregunta clave:
- Como evaluar relacion entre nomina, asistencia, horas extra y resultados.

Requerimiento:
- Usar `fact_rrhh_mensual` y cruzar con `fact_viaje` y `fact_facturacion`.

Preguntas de dashboard:
- Que sucursales tienen mayor costo laboral mensual.
- Como evolucionan ausentismo y horas extra por area.
- Como se relaciona costo laboral con resultados operativos y de facturacion.

### 6.3.4 Area Telemetria GPS

#### R13-TEL - Calidad e integridad de datos telemetricos
Pregunta clave:
- Como controlar cobertura, frecuencia y continuidad de telemetria por vehiculo y ruta.

Requerimiento:
- Monitorear `fact_viaje` (`cobertura_telemetria_pct`, `interrupciones_senal_count`) y eventos en `fact_tracking_evento`.

Preguntas de dashboard:
- Que porcentaje de viajes tiene telemetria completa vs incompleta.
- Que vehiculos presentan mas interrupciones de senal por semana.
- En que rutas/sucursales se concentra mayor perdida de datos.

#### R14-TEL - Riesgo mecanico temprano por temperatura y alertas
Pregunta clave:
- Como detectar patrones de riesgo mecanico para mantenimiento preventivo.

Requerimiento:
- Integrar `fact_tracking_evento` (temperatura/alertas) y `fact_viaje` (indicadores de mantenimiento).

Preguntas de dashboard:
- Que vehiculos superan con mayor frecuencia umbrales criticos de temperatura.
- Que tipo de alerta antecede mas a mantenimiento correctivo.
- Que rutas presentan mayor incidencia de alertas mecanicas.

---

## 7) KPIs y Graficos por Area (actualizados al DWH actual)

### 7.1 Area Comercial

#### KPIs

| KPI | Requerimiento(s) | Tablas relacionadas |
|---|---|---|
| Ingreso total comercial (BOB) | R1-COM, R3-COM | `fact_orden_servicio`, `dim_fecha`, `dim_cliente`, `dim_tarifa`, `dim_ruta` |
| Ingreso facturado comercial (BOB) | R1-COM, R3-COM | `fact_facturacion`, `dim_fecha`, `dim_cliente`, `dim_ruta` |
| Ingreso por segmento (%) | R1-COM | `fact_orden_servicio`, `dim_cliente`, `dim_fecha` |
| Peso transportado por segmento (kg y %) | R1-COM | `fact_envio`, `dim_cliente`, `dim_fecha` |
| Ticket promedio por orden (BOB) | R1-COM | `fact_orden_servicio`, `dim_cliente`, `dim_fecha` |
| Conversion orden aprobada a envio (%) | R2-COM | `fact_orden_servicio`, `dim_fecha`, `dim_cliente` |
| Ordenes vencidas sin envio (conteo) | R2-COM | `fact_orden_servicio`, `dim_fecha`, `dim_cliente` |
| Tiempo promedio orden a envio (horas) | R2-COM | `fact_envio`, `dim_fecha`, `dim_cliente`, `dim_ruta` |
| Participacion de ingresos por tipo tarifario (%) | R3-COM | `fact_orden_servicio`, `dim_tarifa`, `dim_fecha` |
| Clientes con alta exposicion crediticia (conteo y %) | R4-COM | `fact_orden_servicio`, `dim_cliente`, `dim_fecha` |
#### Graficos

| Grafico | Requerimiento(s) | Tablas relacionadas |
|---|---|---|
| Linea de ingreso mensual | R1-COM | `fact_orden_servicio`, `dim_fecha` |
| Barras de ingreso por segmento | R1-COM | `fact_orden_servicio`, `dim_cliente` |
| Barras 100% de peso por segmento | R1-COM | `fact_envio`, `dim_cliente` |
| Mapa de calor ruta vs ingreso | R1-COM, R3-COM | `fact_orden_servicio`, `dim_ruta`, `dim_tarifa` |
| Funnel orden -> envio | R2-COM | `fact_orden_servicio`, `fact_envio` |
| Barras de ordenes vencidas por cliente | R2-COM | `fact_orden_servicio`, `dim_cliente` |
| Dona VENTANILLA vs CONTRATO | R3-COM | `fact_orden_servicio`, `dim_tarifa` |
| Heatmap tipo carga vs rango de peso | R3-COM | `fact_orden_servicio`, `dim_tarifa` |
| Ranking clientes con mayor riesgo de credito | R4-COM | `fact_orden_servicio`, `dim_cliente` |
### 7.2 Area Operaciones Logisticas

#### KPIs

| KPI | Requerimiento(s) | Tablas relacionadas |
|---|---|---|
| Cumplimiento SLA de recojo (%) | R5-OPS | `fact_envio`, `dim_sucursal`, `dim_fecha`, `dim_ruta` |
| Tiempo de ciclo logistico promedio (horas) | R5-OPS | `fact_envio`, `dim_fecha`, `dim_sucursal`, `dim_ruta` |
| Desviacion promedio de SLA (horas) | R5-OPS | `fact_envio`, `dim_ruta`, `dim_fecha` |
| Ocupacion promedio de flota (%) | R6-OPS | `fact_viaje`, `dim_vehiculo`, `dim_ruta`, `dim_fecha` |
| Tasa de sobrecapacidad (%) | R6-OPS | `fact_viaje`, `dim_vehiculo`, `dim_fecha`, `dim_ruta` |
| Costo operativo promedio por viaje (BOB) | R7-OPS | `fact_viaje`, `dim_ruta`, `dim_vehiculo`, `dim_fecha` |
| Costo operativo por km (BOB/km) | R7-OPS | `fact_viaje`, `dim_ruta`, `dim_fecha` |
| Alertas criticas por 100 viajes | R8-OPS | `fact_viaje`, `dim_ruta`, `dim_conductor`, `dim_fecha` |
| Gap promedio entre eventos criticos (min) | R8-OPS | `fact_tracking_evento`, `dim_sucursal`, `dim_ruta`, `dim_fecha` |
#### Graficos

| Grafico | Requerimiento(s) | Tablas relacionadas |
|---|---|---|
| Medidor de cumplimiento de recojo | R5-OPS | `fact_envio` |
| Linea de cumplimiento mensual | R5-OPS | `fact_envio`, `dim_fecha` |
| Barras de cumplimiento por sucursal destino | R5-OPS | `fact_envio`, `dim_sucursal` |
| Caja de tiempo de ciclo por ruta | R5-OPS | `fact_envio`, `dim_ruta` |
| Barras de ocupacion por vehiculo | R6-OPS | `fact_viaje`, `dim_vehiculo` |
| Mapa de calor de sobrecapacidad por ruta | R6-OPS | `fact_viaje`, `dim_ruta` |
| Ranking de costo por ruta | R7-OPS | `fact_viaje`, `dim_ruta` |
| Dispersion costo vs ocupacion | R6-OPS, R7-OPS | `fact_viaje`, `dim_ruta`, `dim_vehiculo` |
| Heatmap de alertas por conductor y ruta | R8-OPS | `fact_tracking_evento`, `dim_conductor`, `dim_ruta` |
### 7.3 Area Finanzas y Cobranzas

#### KPIs

| KPI | Requerimiento(s) | Tablas relacionadas |
|---|---|---|
| Facturacion total del periodo (BOB) | R9-FIN | `fact_facturacion`, `dim_fecha`, `dim_cliente`, `dim_factura` |
| Cobranza total del periodo (BOB) | R11-FIN | `fact_pago`, `dim_fecha`, `dim_cliente`, `dim_metodo_pago` |
| Cobertura de facturacion sobre envios cerrados (%) | R9-FIN | `fact_envio`, `fact_facturacion`, `dim_fecha` |
| Envios cerrados no facturados (conteo) | R9-FIN | `fact_envio`, `fact_facturacion`, `dim_cliente`, `dim_fecha` |
| Monto pendiente de facturar (BOB estimado) | R9-FIN | `fact_envio`, `fact_facturacion`, `dim_fecha`, `dim_cliente` |
| Cartera vencida total (BOB) | R10-FIN | `fact_facturacion`, `dim_factura`, `dim_fecha`, `dim_cliente` |
| Indice de cartera vencida (%) | R10-FIN | `fact_facturacion`, `dim_factura`, `dim_fecha` |
| DSO promedio (dias) | R11-FIN | `fact_pago`, `dim_fecha`, `dim_cliente` |
| Proporcion de pagos tardios (%) | R11-FIN | `fact_pago`, `dim_metodo_pago`, `dim_cliente`, `dim_fecha` |
#### Graficos

| Grafico | Requerimiento(s) | Tablas relacionadas |
|---|---|---|
| Linea facturacion vs cobranza mensual | R9-FIN, R11-FIN | `fact_facturacion`, `fact_pago`, `dim_fecha` |
| Embudo envio cerrado -> envio facturado | R9-FIN | `fact_envio`, `fact_facturacion` |
| Barras de no facturados por cliente | R9-FIN | `fact_envio`, `fact_facturacion`, `dim_cliente` |
| Barras apiladas de antiguedad de cartera | R10-FIN | `fact_facturacion`, `dim_factura`, `dim_fecha` |
| Pareto de clientes morosos | R10-FIN | `fact_facturacion`, `dim_factura`, `dim_cliente` |
| Linea mensual de DSO | R11-FIN | `fact_pago`, `dim_fecha` |
| Barras de dias de cobro por metodo de pago | R11-FIN | `fact_pago`, `dim_metodo_pago` |
| Heatmap pagos tardios por cliente y mes | R11-FIN | `fact_pago`, `dim_cliente`, `dim_fecha` |
| Medidor indice de cartera vencida | R10-FIN | `fact_facturacion`, `dim_factura` |
### 7.4 Area Costos y Recursos Humanos

#### KPIs

| KPI | Requerimiento(s) | Tablas relacionadas |
|---|---|---|
| Costo laboral total (BOB) | R12-RRHH | `fact_rrhh_mensual`, `dim_fecha` |
| Costo laboral por sucursal (BOB) | R12-RRHH | `fact_rrhh_mensual`, `dim_sucursal`, `dim_fecha` |
| Tasa de ausentismo promedio (%) | R12-RRHH | `fact_rrhh_mensual`, `dim_empleado`, `dim_fecha` |
| Proporcion horas extra / horas trabajadas (%) | R12-RRHH | `fact_rrhh_mensual`, `dim_empleado`, `dim_fecha` |
| Fuerza laboral equivalente (FTE) | R12-RRHH | `fact_rrhh_mensual`, `dim_fecha`, `dim_sucursal` |
| Costo operativo total de viajes (BOB) | R7-OPS, R12-RRHH | `fact_viaje`, `dim_fecha`, `dim_ruta`, `dim_vehiculo` |
| Costo laboral sobre ingresos (%) | R12-RRHH | `fact_rrhh_mensual`, `fact_facturacion`, `dim_fecha` |
| Productividad facturada por empleado (BOB/FTE) | R12-RRHH | `fact_facturacion`, `fact_rrhh_mensual`, `dim_fecha` |
#### Graficos

| Grafico | Requerimiento(s) | Tablas relacionadas |
|---|---|---|
| Linea de costo laboral mensual | R12-RRHH | `fact_rrhh_mensual`, `dim_fecha` |
| Barras de costo laboral por sucursal | R12-RRHH | `fact_rrhh_mensual`, `dim_sucursal` |
| Heatmap de ausentismo por area y mes | R12-RRHH | `fact_rrhh_mensual`, `dim_empleado`, `dim_fecha` |
| Barras de horas extra por area | R12-RRHH | `fact_rrhh_mensual`, `dim_empleado` |
| Doble eje costo laboral vs ingresos | R12-RRHH | `fact_rrhh_mensual`, `fact_facturacion`, `dim_fecha` |
| Barras de FTE por sucursal | R12-RRHH | `fact_rrhh_mensual`, `dim_sucursal` |
| Dispersion ausentismo vs costo laboral | R12-RRHH | `fact_rrhh_mensual`, `dim_sucursal`, `dim_fecha` |
| Ranking sucursales por costo operativo de viajes | R7-OPS, R12-RRHH | `fact_viaje`, `dim_sucursal`, `dim_fecha` |
### 7.5 Area Telemetria

#### KPIs

| KPI | Requerimiento(s) | Tablas relacionadas |
|---|---|---|
| Cobertura de telemetria por viaje (%) | R13-TEL | `fact_viaje`, `dim_vehiculo`, `dim_ruta`, `dim_fecha` |
| Interrupciones de senal por vehiculo | R13-TEL | `fact_viaje`, `dim_vehiculo`, `dim_fecha` |
| Alertas totales por cada 100 viajes | R13-TEL, R14-TEL | `fact_viaje`, `dim_ruta`, `dim_fecha` |
| Alertas criticas por cada 100 viajes | R14-TEL | `fact_viaje`, `dim_ruta`, `dim_conductor`, `dim_fecha` |
| Indice de temperatura critica de motor (%) | R14-TEL | `fact_viaje`, `dim_vehiculo`, `dim_ruta`, `dim_fecha` |
| Velocidad promedio operativa (km/h) | R13-TEL | `fact_viaje`, `dim_ruta`, `dim_fecha` |
| Vehiculos con riesgo mecanico recurrente (conteo) | R14-TEL | `fact_viaje`, `dim_vehiculo`, `dim_fecha` |
| Alertas criticas asociadas a mantenimiento correctivo (%) | R14-TEL | `fact_tracking_evento`, `dim_vehiculo`, `dim_fecha`, `dim_tipo_tracking_evento` |
#### Graficos

| Grafico | Requerimiento(s) | Tablas relacionadas |
|---|---|---|
| Medidor de cobertura telemetrica | R13-TEL | `fact_viaje` |
| Linea de cobertura semanal | R13-TEL | `fact_viaje`, `dim_fecha` |
| Barras de interrupciones por vehiculo | R13-TEL | `fact_viaje`, `dim_vehiculo` |
| Heatmap de alertas por ruta y hora | R13-TEL, R14-TEL | `fact_tracking_evento`, `dim_ruta`, `dim_hora`, `dim_fecha` |
| Barras de alertas por conductor | R14-TEL | `fact_tracking_evento`, `dim_conductor` |
| Caja de temperatura maxima por vehiculo | R14-TEL | `fact_tracking_evento`, `dim_vehiculo` |
| Ranking de rutas con mas alertas criticas | R14-TEL | `fact_viaje`, `dim_ruta` |
| Flujo alerta critica -> mantenimiento | R14-TEL | `fact_tracking_evento`, `dim_tipo_tracking_evento`, `dim_vehiculo` |
| Dispersion temperatura maxima vs costo de mantenimiento | R14-TEL | `fact_viaje`, `dim_vehiculo`, `dim_fecha` |
---

## 8) Checklist de consistencia (sin duplicados ni tablas obsoletas)

- No se usan tablas obsoletas (`fact_envio_sla`, `fact_envio_tramo`, `fact_costo_total`, `fact_factura_detalle`).
- No se usan dimensiones obsoletas (`dim_tipo_costo`, `dim_estado_envio`, `dim_estado_cobro`).
- Todos los KPIs y graficos usan tablas vigentes del DWH actual.
- Nombres de KPI y graficos sin duplicados por area.


