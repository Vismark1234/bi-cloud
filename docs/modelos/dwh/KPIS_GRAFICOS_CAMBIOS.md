# KPIs y Graficos: Cambios Requeridos (Modelo Anterior -> DWH Actual)

Este documento lista **solo lo que debes modificar** en tus KPIs y graficos para que queden alineados al DWH actual.

## 1) Cambios globales

- `fact_envio_sla` -> `fact_envio`
- `fact_envio_tramo` -> `fact_viaje` (ocupacion, sobrecapacidad, costos) o `fact_tracking_evento` (alertas/eventos)
- `fact_costo_total` -> `fact_viaje` (costos operativos) y `fact_rrhh_mensual` (costos laborales)
- `fact_factura_detalle` -> `fact_facturacion`
- `evento_envio`, `gps_track`, `gps_alerta` -> `fact_tracking_evento`
- `dim_tipo_costo`, `dim_estado_envio`, `dim_estado_cobro` -> no existen en marts actuales

---

## 2) KPIs a modificar

### Area Comercial

- **Peso transportado por segmento (kg y %)**  
`fact_envio_tramo` -> `fact_envio`

- **Conversion orden aprobada -> envio (%)**  
`fact_envio_sla` -> `fact_envio` (usar `fact_orden_servicio` + `fact_envio`)

### Area Operaciones Logisticas

- **Cumplimiento SLA de recojo (%)**  
`fact_envio_sla` -> `fact_envio`

- **Tiempo de ciclo logistico promedio (horas)**  
`fact_envio_sla` -> `fact_envio`

- **Desviacion promedio de SLA (horas)**  
`fact_envio_sla` -> `fact_envio`

- **Ocupacion promedio de flota (%)**  
`fact_envio_tramo` -> `fact_viaje`

- **Tasa de sobrecapacidad (%)**  
`fact_envio_tramo` -> `fact_viaje`

- **Costo operativo promedio por viaje (BOB)**  
`fact_costo_total` + `fact_envio_tramo` -> `fact_viaje`

- **Costo operativo por km (BOB/km)**  
`fact_costo_total` + `fact_envio_tramo` -> `fact_viaje`

- **Alertas criticas por 100 tramos**  
`fact_envio_tramo` -> `fact_viaje` (alertas_criticas_count) o `fact_tracking_evento` (evento_critico_flag)

### Area Finanzas y Cobranzas

- **Facturacion total del periodo (BOB)**  
`fact_factura_detalle` -> `fact_facturacion`

- **Cobertura de facturacion sobre envios cerrados**  
`fact_envio_sla` + `fact_factura_detalle` -> `fact_envio` + `fact_facturacion`

- **Envios cerrados no facturados**  
`fact_envio_sla` + `fact_factura_detalle` -> `fact_envio` + `fact_facturacion`

- **Cartera vencida total (BOB)**  
`fact_factura_detalle` -> `fact_facturacion` (filtrar con `dim_factura.estado_cobro`)

- **Indice de cartera vencida**  
`fact_factura_detalle` -> `fact_facturacion`

### Area Costos y RRHH

- **Costo laboral total**  
`fact_costo_total` -> `fact_rrhh_mensual`

- **Costo laboral por sucursal**  
`fact_costo_total` -> `fact_rrhh_mensual`

- **Tasa de ausentismo**  
`fact_costo_total` -> `fact_rrhh_mensual`

- **Proporcion horas extra / horas trabajadas**  
`fact_costo_total` -> `fact_rrhh_mensual`

- **Fuerza laboral equivalente (FTE)**  
`fact_costo_total` -> `fact_rrhh_mensual`

- **Costo total por tipo de costo**  
`dim_tipo_costo` no existe -> **eliminar o redefinir** (no hay dimension equivalente en marts)

- **Participacion de nomina en costo total**  
`fact_costo_total` -> `fact_rrhh_mensual` (si se necesita costo total, cruzar con `fact_viaje`/`fact_facturacion`)

- **Costo laboral sobre ingresos**  
`fact_costo_total` + `fact_factura_detalle` -> `fact_rrhh_mensual` + `fact_facturacion`

### Area Telemetria

- **Cobertura de telemetria por viaje**  
`fact_envio_tramo` -> `fact_viaje` (cobertura_telemetria_pct)

- **Interrupciones de senal por vehiculo**  
`fact_envio_tramo` -> `fact_viaje` (interrupciones_senal_count)

- **Alertas totales/criticas por 100 tramos**  
`fact_envio_tramo` -> `fact_viaje` (alertas_totales_count, alertas_criticas_count) o `fact_tracking_evento`

- **Indice de temperatura critica de motor**  
`fact_envio_tramo` -> `fact_viaje` (temp_max_motor_c)

- **Velocidad promedio operativa**  
`fact_envio_tramo` -> `fact_viaje` (velocidad_promedio_kmh)

- **Vehiculos con riesgo mecanico recurrente**  
`fact_envio_tramo` -> `fact_viaje` (mantenimiento_correctivo_flag_30d)

- **Alertas criticas asociadas a mantenimiento correctivo**  
`fact_envio_tramo` + `fact_costo_total` -> `fact_tracking_evento` (mantenimiento_correctivo_30d_flag)

---

## 3) Graficos a modificar

### Area Comercial

- **Barras 100% de peso por segmento**  
`fact_envio_tramo` -> `fact_envio`

- **Funnel orden -> envio**  
`fact_envio_sla` -> `fact_envio`

### Area Operaciones Logisticas

- **Medidor de cumplimiento de recojo**  
`fact_envio_sla` -> `fact_envio`

- **Linea de cumplimiento mensual**  
`fact_envio_sla` -> `fact_envio`

- **Barras de cumplimiento por sucursal destino**  
`fact_envio_sla` -> `fact_envio`

- **Caja de distribucion de tiempo de ciclo por ruta**  
`fact_envio_sla` -> `fact_envio`

- **Barras de ocupacion por vehiculo**  
`fact_envio_tramo` -> `fact_viaje`

- **Mapa de calor de sobrecapacidad por ruta**  
`fact_envio_tramo` -> `fact_viaje`

- **Ranking de costo por ruta**  
`fact_costo_total` -> `fact_viaje`

- **Dispersion de costo vs ocupacion**  
`fact_costo_total` + `fact_envio_tramo` -> `fact_viaje`

- **Mapa de calor de alertas por conductor y ruta**  
`fact_envio_tramo` -> `fact_tracking_evento`

### Area Finanzas y Cobranzas

- **Linea de facturacion contra cobranza mensual**  
`fact_factura_detalle` -> `fact_facturacion`

- **Embudo envio cerrado -> envio facturado**  
`fact_envio_sla` + `fact_factura_detalle` -> `fact_envio` + `fact_facturacion`

- **Barras de no facturados por cliente**  
`fact_envio_sla` + `fact_factura_detalle` -> `fact_envio` + `fact_facturacion`

- **Barras apiladas de antiguedad de cartera**  
`fact_factura_detalle` -> `fact_facturacion`

- **Pareto de clientes morosos**  
`fact_factura_detalle` -> `fact_facturacion`

- **Medidor del indice de cartera vencida**  
`fact_factura_detalle` -> `fact_facturacion`

### Area Costos y RRHH

- **Linea de costo laboral mensual**  
`fact_costo_total` -> `fact_rrhh_mensual`

- **Barras de costo laboral por sucursal**  
`fact_costo_total` -> `fact_rrhh_mensual`

- **Mapa de calor de ausentismo por area y mes**  
`fact_costo_total` -> `fact_rrhh_mensual`

- **Barras de horas extra por area**  
`fact_costo_total` -> `fact_rrhh_mensual`

- **Grafico circular de composicion de costos**  
`dim_tipo_costo` no existe -> **eliminar o redefinir**

- **Mapa de arbol de costo por tipo y sucursal**  
`dim_tipo_costo` no existe -> **eliminar o redefinir**

- **Doble eje costo laboral vs ingresos**  
`fact_costo_total` + `fact_factura_detalle` -> `fact_rrhh_mensual` + `fact_facturacion`

- **Barras de fuerza laboral equivalente por sucursal**  
`fact_costo_total` -> `fact_rrhh_mensual`

- **Dispersion de ausentismo contra costo laboral**  
`fact_costo_total` -> `fact_rrhh_mensual`

### Area Telemetria

- **Medidor de cobertura telemetrica**  
`fact_envio_tramo` -> `fact_viaje`

- **Linea de cobertura semanal**  
`fact_envio_tramo` -> `fact_viaje`

- **Barras de interrupciones por vehiculo**  
`fact_envio_tramo` -> `fact_viaje`

- **Mapa de calor de alertas por ruta y hora**  
`fact_envio_tramo` -> `fact_tracking_evento` (con `dim_hora`)

- **Barras de alertas por conductor**  
`fact_envio_tramo` -> `fact_tracking_evento`

- **Caja de temperatura maxima por vehiculo**  
`fact_envio_tramo` -> `fact_tracking_evento`

- **Ranking de rutas con mas alertas criticas**  
`fact_envio_tramo` -> `fact_viaje`

- **Flujo de alerta critica a mantenimiento**  
`fact_envio_tramo` + `fact_costo_total` -> `fact_tracking_evento`

- **Dispersion temperatura maxima vs costo de mantenimiento**  
`fact_envio_tramo` + `fact_costo_total` -> `fact_viaje`

