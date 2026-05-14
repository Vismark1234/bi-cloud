# ESPECIFICACION DE KPIS, GRAFICOS, FILTROS Y REPORTES BI

## 1. Objetivo

Este documento define una propuesta BI **mas simple, clara y accionable** para el modelo DWH actual.

La idea no es llenar la solucion con indicadores complejos, sino construir dashboards que:

- sean faciles de leer
- ayuden a tomar decisiones
- se apoyen en los hechos y dimensiones que **si existen hoy**
- respeten que la data es simulada, pero consistente

Este documento se alinea con:

- [DICCIONARIO_DWH_FINAL_COMPLETO_HECHOS_DIMENSIONES.md](./DICCIONARIO_DWH_FINAL_COMPLETO_HECHOS_DIMENSIONES.md)

## 2. Base actual del modelo

### 2.1 Hechos disponibles del DWH

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

### 2.2 Dimensiones mas utiles para BI

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

### 2.3 Consideraciones importantes de la simulacion

- La data comercial, operativa, financiera y RRHH puede cubrir todo el periodo historico cargado.
- La telemetria de Mongo puede comenzar mas tarde que el resto de la operacion.
- Si la telemetria empieza recien desde una fecha como `2022-03-01`, los viajes anteriores seguiran existiendo en el DWH.
- En esos viajes anteriores, los indicadores telemetricos quedaran en `0` segun la logica actual del modelo.
- RRHH tiene grano mensual, por eso **no se recomienda un nivel operativo diario** para esa area.
- La telemetria y las rutas son simuladas, por lo que sirven para analisis gerencial y operativo, pero no para control GIS de precision.

## 3. Principios de diseno BI

### 3.1 Enfoque visual

Cada dashboard debe priorizar:

- `4 a 6` tarjetas KPI maximo
- `1` grafico de tendencia
- `1` grafico comparativo por categoria
- `1` ranking Top N
- `1` tabla detalle o boton de drill-through

### 3.2 Visuales recomendados

- tarjetas KPI con semaforo
- lineas para tendencia mensual o diaria
- columnas o barras para comparacion
- dona solo para composiciones pequenas
- dispersion solo cuando ayude a comparar dos metricas de verdad
- matrices y tablas para detalle

### 3.3 Visuales a evitar

- sankey
- radar
- arboles muy profundos
- mapas complejos de rutas
- demasiados indicadores en una sola pagina

## 4. Fuente oficial por dominio

| Dominio | Hecho oficial | Uso principal |
|---|---|---|
| Comercial | `fact_orden_servicio` | pipeline comercial, conversion y credito |
| Servicio / envios | `fact_envio` | SLA, devoluciones, tiempos y volumen |
| Operacion / viajes | `fact_viaje` | viajes, ocupacion, costo y productividad |
| Telemetria | `fact_tracking_evento` | eventos, alertas y gaps |
| Facturacion | `fact_facturacion` | ingreso facturado |
| Cobranza | `fact_pago` | dinero cobrado, mora y dias de cobro |
| RRHH | `fact_rrhh_mensual` | costo laboral, horas, ausentismo y FTE |
| Combustible | `fact_abastecimiento_combustible` | litros, monto y precio por abastecimiento |
| Gasto fijo | `fact_gasto_fijo_mensual` | gasto estructural por sucursal o corporativo |
| Mantenimiento | `fact_mantenimiento_vehiculo` | costo y tipo de mantenimiento |

## 5. Filtros compartidos

## 5.1 Filtros globales

Estos filtros deben vivir sincronizados en la mayoria de paginas:

- `Fecha`
- `Sucursal`
- `Ruta`

## 5.2 Filtros por dominio

### Comercial y finanzas

- `Cliente`
- `Segmento`
- `Ciudad`

### Operaciones y logistica

- `Vehiculo`
- `Conductor`
- `Estado envio`
- `Tipo tracking`
- `Nivel alerta`

### RRHH

- `Empleado`
- `Area`
- `Cargo`
- `Estado laboral`

### Finanzas

- `Estado cobro`
- `Metodo pago`

### Solo paginas operativas

- `Hora`

## 5.3 Grupos de sincronizacion sugeridos

| Grupo | Filtros | Uso |
|---|---|---|
| `SYNC_GLOBAL` | Fecha, Sucursal, Ruta | paginas ejecutivas y tacticas |
| `SYNC_CLIENTE` | Cliente, Segmento, Ciudad | comercial, finanzas y reportes cliente |
| `SYNC_OPERACION` | Vehiculo, Conductor, Estado envio, Tipo tracking, Nivel alerta | logistica y operaciones |
| `SYNC_RRHH` | Empleado, Area, Cargo, Estado laboral | RRHH y empleado 360 |
| `LOCAL_HORA` | Hora | solo monitoreo operativo |
| `LOCAL_FINANZAS` | Estado cobro, Metodo pago | solo finanzas |

## 6. Cartera de dashboards por area

## 6.1 Resumen general

Se trabajaran `5 areas`:

- `Comercial / Ventas`
- `Finanzas`
- `Logistica / Envios`
- `RRHH`
- `Operaciones`

No todas las areas necesitan los 3 niveles. Se propone solo lo que **si tiene sentido con el DWH actual**.

| Area | Estrategico | Tactico | Operativo | Reportes y 360 |
|---|---|---|---|---|
| Comercial / Ventas | Si | Si | Si | Si |
| Finanzas | Si | Si | Si | Si |
| Logistica / Envios | Si | Si | Si | Si |
| RRHH | Si | Si | No recomendable | Si |
| Operaciones | Si | Si | Si | Si |

## 7. Especificacion por area

## 7.1 Comercial / Ventas

### Datos principales

- `fact_orden_servicio`
- `fact_envio`
- `fact_facturacion`
- `dim_cliente`
- `dim_tarifa`
- `dim_ruta`
- `dim_sucursal`

### Dashboard `CV-E1`: Panorama Comercial Ejecutivo

**Nivel**

Estrategico

**Objetivo**

Mostrar si la cartera comercial esta creciendo y si las ordenes realmente se convierten en servicio e ingreso.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_CLIENTE`

**KPIs**

- `Cantidad de ordenes`
- `Ordenes aprobadas`
- `Tasa de aprobacion`
- `Cantidad de envios generados`
- `Tasa de conversion orden -> envio`
- `Monto facturado`

**Graficos**

- linea mensual de `ordenes` vs `envios`
- columnas por `segmento`
- Top `10` clientes por facturacion
- tabla resumen por cliente y ruta

### Dashboard `CV-T1`: Conversion Comercial y Clientes Clave

**Nivel**

Tactico

**Objetivo**

Ayudar a jefaturas a ver donde se pierde conversion, donde hay mas uso de precio manual y que clientes concentran el negocio.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_CLIENTE`

**KPIs**

- `Ordenes con precio manual`
- `Ordenes vencidas sin envio`
- `Monto reservado de credito`
- `Credito disponible`
- `Clientes activos`

**Graficos**

- funnel simple de `orden creada -> aprobada -> envio generado -> facturada`
- barras por `ciudad`
- ranking de clientes por `monto reservado`
- tabla de ordenes con foco comercial

### Dashboard `CV-O1`: Seguimiento Diario de Ordenes y Conversion

**Nivel**

Operativo

**Objetivo**

Dar visibilidad diaria al equipo comercial sobre ordenes creadas, aprobadas y convertidas a envio.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_CLIENTE`

**KPIs**

- `Ordenes del periodo`
- `Ordenes aprobadas del periodo`
- `Envios generados del periodo`
- `Horas promedio de orden a envio`

**Graficos**

- linea diaria de ordenes y envios
- columnas por sucursal
- tabla detalle de ordenes pendientes, vencidas o no convertidas

### Reporte `CV-R1`: Cliente 360

**Objetivo**

Concentrar toda la vista del cliente en una sola pagina.

**Hechos**

- `fact_orden_servicio`
- `fact_envio`
- `fact_facturacion`
- `fact_pago`

**KPIs**

- ordenes
- envios
- facturacion
- cobranza
- dias promedio de cobro
- devoluciones

**Visuales**

- tarjetas principales
- tendencia mensual
- tabla de facturas
- tabla de envios
- ranking de rutas del cliente

## 7.2 Finanzas

### Datos principales

- `fact_facturacion`
- `fact_pago`
- `fact_gasto_fijo_mensual`
- `fact_rrhh_mensual`
- `dim_factura`
- `dim_metodo_pago`
- `dim_cliente`
- `dim_sucursal`

### Dashboard `FI-E1`: Panorama Financiero Ejecutivo

**Nivel**

Estrategico

**Objetivo**

Mostrar la fotografia financiera principal del negocio sin sobrecargarla.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_CLIENTE`
- `LOCAL_FINANZAS`

**KPIs**

- `Monto facturado`
- `Monto cobrado`
- `Tasa de cobranza`
- `Gasto fijo total`
- `Costo laboral total`
- `Pagos tardios`

**Graficos**

- linea mensual de `facturado` vs `cobrado`
- columnas de `gasto fijo` y `costo laboral`
- barras por `metodo de pago`
- tabla de clientes con mayor mora

### Dashboard `FI-T1`: Facturacion, Cartera y Cobranza

**Nivel**

Tactico

**Objetivo**

Controlar facturas emitidas, vencimientos, mora y concentracion de cartera.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_CLIENTE`
- `LOCAL_FINANZAS`

**KPIs**

- `Cantidad de facturas`
- `Ticket promedio por factura`
- `Dias promedio de cobro`
- `Dias de mora promedio`
- `Facturas con pago tardio`

**Graficos**

- aging simple por buckets `0-30`, `31-60`, `61-90`, `90+`
- Top `10` clientes por saldo cobrado lento
- columnas de facturacion por sucursal
- tabla de factura, vencimiento y pago

### Dashboard `FI-O1`: Seguimiento Diario de Cobranza

**Nivel**

Operativo

**Objetivo**

Dar seguimiento diario al cobro efectivo y a los vencimientos.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_CLIENTE`
- `LOCAL_FINANZAS`

**KPIs**

- `Pagos del dia`
- `Monto cobrado del dia`
- `Pagos tardios del dia`
- `Facturas vencidas del periodo`

**Graficos**

- linea diaria de cobros
- barras por metodo de pago
- tabla de facturas vencidas y clientes pendientes

### Reporte `FI-R1`: Factura y Cobranza 360

**Objetivo**

Analizar una factura o un cliente desde emision hasta pago.

**Hechos**

- `fact_facturacion`
- `fact_pago`

**KPIs**

- total facturado
- monto cobrado
- saldo pendiente
- dias de cobro
- dias de mora

**Visuales**

- cabecera de factura
- linea de tiempo emision-vencimiento-pago
- tabla de pagos
- detalle de lineas facturadas

## 7.3 Logistica / Envios

### Datos principales

- `fact_envio`
- `fact_orden_servicio`
- `dim_estado_envio`
- `dim_cliente`
- `dim_sucursal`
- `dim_ruta`

### Dashboard `LE-E1`: Servicio Logistico y Cumplimiento

**Nivel**

Estrategico

**Objetivo**

Medir si la empresa esta cumpliendo el servicio prometido al cliente.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_CLIENTE`

**KPIs**

- `Cantidad de envios`
- `Envios cerrados`
- `Cumplimiento SLA de recojo`
- `Envios devueltos`
- `Tiempo de ciclo promedio`
- `Peso movilizado`

**Graficos**

- linea mensual de `envios` y `SLA`
- columnas por sucursal
- Top `10` rutas con mayor desviacion SLA
- tabla de clientes con devoluciones

### Dashboard `LE-T1`: Desempeno de Rutas y Sucursales

**Nivel**

Tactico

**Objetivo**

Comparar nodos operativos para detectar donde se concentra retraso, devolucion o mayor volumen.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_CLIENTE`

**KPIs**

- `Envios por sucursal`
- `SLA por sucursal`
- `Desviacion SLA promedio`
- `Rutas con excepciones`

**Graficos**

- barras por sucursal
- barras por ruta
- matriz sucursal x estado envio
- tabla comparativa de rutas

### Dashboard `LE-O1`: Monitoreo Diario de Envios y SLA

**Nivel**

Operativo

**Objetivo**

Ver la ejecucion diaria de envios y casos que requieren atencion inmediata.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_CLIENTE`
- `LOCAL_HORA`

**KPIs**

- `Envios registrados`
- `Envios cerrados`
- `Envios abiertos`
- `Envios devueltos`
- `Desviacion SLA promedio`

**Graficos**

- linea diaria de envios registrados y cerrados
- columnas por hora o franja
- tabla de envios fuera de SLA
- tabla de envios devueltos

### Reporte `LE-R1`: Envio 360

**Objetivo**

Tener la ficha completa del envio para seguimiento y analisis de excepciones.

**Hechos**

- `fact_envio`
- `fact_facturacion`
- `fact_tracking_evento`

**KPIs**

- estado actual
- SLA
- tiempo de ciclo
- monto facturado
- eventos asociados

**Visuales**

- cabecera del envio
- linea de tiempo de eventos
- tabla de eventos
- resumen de facturacion asociada

### Reporte `LE-R2`: Ruta y Sucursal 360

**Objetivo**

Analizar servicio, volumen y desempeno de una ruta o sucursal.

**Hechos**

- `fact_envio`
- `fact_viaje`
- `fact_facturacion`

**KPIs**

- envios
- viajes
- SLA
- peso movilizado
- costo operativo
- facturacion

## 7.4 RRHH

### Datos principales

- `fact_rrhh_mensual`
- `dim_empleado`
- `dim_sucursal`

### Nota de nivel

No se propone dashboard operativo diario para RRHH porque el hecho esta a nivel `empleado-mes`.

### Dashboard `RH-E1`: Capacidad Laboral y Costo Empresarial

**Nivel**

Estrategico

**Objetivo**

Mostrar si la empresa tiene la capacidad humana necesaria y cuanto cuesta sostenerla.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_RRHH`

**KPIs**

- `Empleados activos`
- `FTE total`
- `Costo laboral total`
- `Horas extra`
- `Dias de ausencia`

**Graficos**

- linea mensual de costo laboral
- barras por area
- columnas por sucursal
- tabla resumen por cargo

### Dashboard `RH-T1`: Ausentismo, Horas Extra y Estructura

**Nivel**

Tactico

**Objetivo**

Ayudar a RRHH a detectar areas, cargos o sucursales con mas presion operativa.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_RRHH`

**KPIs**

- `Tasa de ausentismo ponderada`
- `Horas extra`
- `Costo laboral por empleado`
- `Dias de ausencia`

**Graficos**

- barras por area
- columnas por cargo
- dispersion `horas extra` vs `ausentismo`
- tabla por empleado

### Reporte `RH-R1`: Empleado 360

**Objetivo**

Ver el historial mensual del empleado en costo, horas y ausencias.

**Hechos**

- `fact_rrhh_mensual`

**KPIs**

- salario base
- liquido pagable
- horas trabajadas
- horas extra
- ausencias
- FTE

## 7.5 Operaciones

### Datos principales

- `fact_viaje`
- `fact_tracking_evento`
- `fact_abastecimiento_combustible`
- `fact_mantenimiento_vehiculo`
- `dim_vehiculo`
- `dim_conductor`
- `dim_ruta`
- `dim_tipo_tracking_evento`
- `dim_tipo_combustible`
- `dim_tipo_mantenimiento`

### Dashboard `OP-E1`: Productividad Operativa y Riesgo de Flota

**Nivel**

Estrategico

**Objetivo**

Resumir la salud operativa de la flota y el costo de mover la operacion.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_OPERACION`

**KPIs**

- `Cantidad de viajes`
- `Viajes finalizados`
- `Ocupacion ponderada`
- `Costo operativo total`
- `Sobrecapacidad`
- `Cobertura de telemetria`

**Graficos**

- linea mensual de viajes y costo
- barras por vehiculo o tipo de servicio
- ranking de rutas por costo por km
- tabla de vehiculos con mas sobrecapacidad

### Dashboard `OP-T1`: Flota, Combustible y Mantenimiento

**Nivel**

Tactico

**Objetivo**

Dar visibilidad a coordinacion sobre consumo, precio de combustible y costo tecnico de la flota.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_OPERACION`

**KPIs**

- `Litros de combustible`
- `Monto de combustible`
- `Precio promedio por litro`
- `Costo total de mantenimiento`
- `Vehiculos con mantenimiento correctivo`

**Graficos**

- linea mensual de litros y costo
- barras por tipo de combustible
- Top `10` vehiculos por costo de mantenimiento
- tabla de mantenimientos por tipo

### Dashboard `OP-O1`: Control Diario de Viajes y Telemetria

**Nivel**

Operativo

**Objetivo**

Monitorear ejecucion diaria de viajes, alertas y problemas de telemetria.

**Filtros**

- `SYNC_GLOBAL`
- `SYNC_OPERACION`
- `LOCAL_HORA`

**KPIs**

- `Viajes del periodo`
- `Alertas criticas`
- `Interrupciones de senal`
- `Velocidad promedio`
- `Temperatura maxima de motor`

**Graficos**

- linea diaria de viajes
- barras por tipo de tracking
- heatmap fecha x hora de eventos
- tabla de eventos criticos

### Reporte `OP-R1`: Vehiculo 360

**Objetivo**

Ver uso, costo, telemetria, combustible y mantenimiento por vehiculo.

**Hechos**

- `fact_viaje`
- `fact_abastecimiento_combustible`
- `fact_mantenimiento_vehiculo`
- `fact_tracking_evento`

**KPIs**

- viajes
- ocupacion
- costo operativo
- litros
- costo mantenimiento
- alertas

### Reporte `OP-R2`: Conductor 360

**Objetivo**

Relacionar viajes, alertas y desempeno operativo por conductor.

**Hechos**

- `fact_viaje`
- `fact_tracking_evento`

**KPIs**

- viajes
- viajes finalizados
- alertas criticas
- velocidad promedio
- ocupacion asociada

## 8. Paginas recomendadas

## 8.1 Dashboards principales

- `CV-E1 Panorama Comercial Ejecutivo`
- `CV-T1 Conversion Comercial y Clientes Clave`
- `CV-O1 Seguimiento Diario de Ordenes y Conversion`
- `FI-E1 Panorama Financiero Ejecutivo`
- `FI-T1 Facturacion, Cartera y Cobranza`
- `FI-O1 Seguimiento Diario de Cobranza`
- `LE-E1 Servicio Logistico y Cumplimiento`
- `LE-T1 Desempeno de Rutas y Sucursales`
- `LE-O1 Monitoreo Diario de Envios y SLA`
- `RH-E1 Capacidad Laboral y Costo Empresarial`
- `RH-T1 Ausentismo, Horas Extra y Estructura`
- `OP-E1 Productividad Operativa y Riesgo de Flota`
- `OP-T1 Flota, Combustible y Mantenimiento`
- `OP-O1 Control Diario de Viajes y Telemetria`

## 8.2 Reportes y drill-through

- `CV-R1 Cliente 360`
- `FI-R1 Factura y Cobranza 360`
- `LE-R1 Envio 360`
- `LE-R2 Ruta y Sucursal 360`
- `RH-R1 Empleado 360`
- `OP-R1 Vehiculo 360`
- `OP-R2 Conductor 360`

## 9. Medidas base sugeridas

Estas medidas conviene construir una sola vez y reutilizarlas.

```DAX
Monto_Facturado = SUM(fact_facturacion[total_linea_bob])
Monto_Cobrado = SUM(fact_pago[monto_bob])
Tasa_Cobranza = DIVIDE([Monto_Cobrado], [Monto_Facturado], 0)

Cantidad_Ordenes = SUM(fact_orden_servicio[cantidad_ordenes])
Ordenes_Aprobadas = SUM(fact_orden_servicio[orden_aprobada_flag])
Tasa_Aprobacion = DIVIDE([Ordenes_Aprobadas], [Cantidad_Ordenes], 0)
Cantidad_Envios_Generados = SUM(fact_orden_servicio[cantidad_envios])
Conversion_Orden_Envio = DIVIDE([Cantidad_Envios_Generados], [Cantidad_Ordenes], 0)

Cantidad_Envios = SUM(fact_envio[cantidad_envios])
Envios_Cerrados = SUM(fact_envio[envio_cerrado_flag])
Envios_Abiertos = [Cantidad_Envios] - [Envios_Cerrados]
SLA_Recojo = DIVIDE(SUM(fact_envio[cumple_sla_recojo_flag]), [Cantidad_Envios], 0)
Envios_Devueltos = SUM(fact_envio[devuelto_flag])
Peso_Movilizado_Kg = SUM(fact_envio[peso_envio_kg])

Cantidad_Viajes = SUM(fact_viaje[cantidad_viajes])
Viajes_Finalizados = SUM(fact_viaje[viaje_finalizado_flag])
Ocupacion_Ponderada = DIVIDE(SUM(fact_viaje[peso_total_asignado_kg]), SUM(fact_viaje[capacidad_kg]), 0)
Costo_Operativo_Total = SUM(fact_viaje[costo_operativo_total_bob])
Costo_Por_Km = DIVIDE(SUM(fact_viaje[costo_operativo_total_bob]), SUM(fact_viaje[distancia_km]), 0)
Cobertura_Telemetria = AVERAGE(fact_viaje[cobertura_telemetria_pct])

Cantidad_Eventos = SUM(fact_tracking_evento[cantidad_eventos])
Eventos_Criticos = SUM(fact_tracking_evento[evento_critico_flag])
Alertas_Criticas = SUM(fact_tracking_evento[alerta_critica_flag])

Costo_Laboral_Total = SUM(fact_rrhh_mensual[liquido_pagable_bob])
Empleados_Activos = DISTINCTCOUNT(fact_rrhh_mensual[id_empleado])
FTE_Total = SUM(fact_rrhh_mensual[fte_equivalente])
Horas_Extra = SUM(fact_rrhh_mensual[horas_extra])
Dias_Ausencia = SUM(fact_rrhh_mensual[dias_ausencia])

Monto_Gasto_Fijo = SUM(fact_gasto_fijo_mensual[monto_gasto_bob])
Monto_Combustible = SUM(fact_abastecimiento_combustible[monto_combustible_bob])
Litros_Combustible = SUM(fact_abastecimiento_combustible[litros_combustible])
Costo_Mantenimiento = SUM(fact_mantenimiento_vehiculo[costo_total_bob])
```

## 10. Recomendaciones finales

- Construir primero los dashboards estrategicos.
- Despues bajar a tacticos.
- Dejar operativos y 360 para drill-through y seguimiento.
- Mantener `Fecha`, `Sucursal` y `Ruta` como ejes comunes del modelo.
- No mezclar demasiados hechos en una sola pagina si el mensaje se vuelve confuso.
- En telemetria, mostrar una nota visible si la carga historica empieza despues que el resto del negocio.
- Usar el color del area como identidad visual del dashboard para hacerlo mas llamativo y facil de recordar.

## 11. Ruta del documento

- `c:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\docs\modelos\dwh\ESPECIFICACION_KPIS_GRAFICOS_FILTROS_BI.md`
