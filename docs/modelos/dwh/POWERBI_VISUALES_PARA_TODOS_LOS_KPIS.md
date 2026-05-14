# Guia Power BI: Visual y Campos (para todos los KPIs y graficos)

Esta guia usa el DWH actual (marts) y reemplaza tablas obsoletas:
- `fact_envio_sla` -> `fact_envio`
- `fact_envio_tramo` -> `fact_viaje` o `fact_tracking_evento`
- `fact_costo_total` -> `fact_viaje` (costos) y `fact_rrhh_mensual` (RRHH)
- `fact_factura_detalle` -> `fact_facturacion`
- `fact_evento_envio` / `gps_track` / `gps_alerta` -> `fact_tracking_evento`

Nota:
- En KPIs de porcentaje o conversion, se recomienda medida DAX.
- Donde se indica "No disponible", falta dimension en el DWH actual.

## Relaciones de fecha recomendadas (activas)

- `fact_orden_servicio.id_fecha_creacion_orden` -> `dim_fecha.id_fecha`
- `fact_envio.id_fecha_registro_envio` -> `dim_fecha.id_fecha`
- `fact_viaje.id_fecha_salida` -> `dim_fecha.id_fecha`
- `fact_tracking_evento.id_fecha_evento` -> `dim_fecha.id_fecha`
- `fact_facturacion.id_fecha_emision` -> `dim_fecha.id_fecha`
- `fact_pago.id_fecha_pago` -> `dim_fecha.id_fecha`

Cuando un KPI o grafico necesita otra fecha, se usa DAX con `USERELATIONSHIP`.

---

## 1) Area Comercial - KPIs

1. Ingreso total comercial (BOB)
- Visual: Tarjeta
- Campos: Valores = `Ingreso Total BOB` (medida)
- Fecha: usa relacion activa `fact_orden_servicio.id_fecha_creacion_orden`

2. Ingreso por segmento (%)
- Visual: Barras 100% apiladas
- Campos: Eje = `dim_cliente[segmento]`, Valores = `Ingreso Segmento %` (medida)
- Fecha: usa relacion activa `fact_orden_servicio.id_fecha_creacion_orden`

3. Conversion orden aprobada -> envio (%)
- Visual: KPI / Tarjeta
- Campos: Valor = `Conversion Orden->Envio %` (medida)
- Fecha: usa relacion activa `fact_orden_servicio.id_fecha_creacion_orden`

4. Participacion de ingresos por tipo tarifario (%)
- Visual: Dona (o barras 100% apiladas)
- Campos: Leyenda = `dim_tarifa[tipo_tarifario]`, Valores = `Ingreso por Tipo Tarifario %` (medida)
- Fecha: usa relacion activa `fact_orden_servicio.id_fecha_creacion_orden`

5. Clientes con alta exposicion crediticia (%)
- Visual: Tarjeta
- Campos: Valores = `Clientes Alta Exposicion %` (medida)
- Fecha: usa relacion activa `fact_orden_servicio.id_fecha_creacion_orden`

6. Ingreso facturado vs ingreso ordenado (%)
- Visual: Tarjeta / KPI
- Campos: Valor = `Facturado vs Ordenado %` (medida)
- Fecha: ordenado usa `fact_orden_servicio.id_fecha_creacion_orden`. Facturado usa `fact_facturacion.id_fecha_emision`. Se recomienda DAX con `TREATAS` para alinear por orden del periodo si se requiere.

7. Tasa de devolucion (%)
- Visual: Tarjeta / KPI
- Campos: Valor = `Tasa Devolucion %` (medida)
- Fecha: usa relacion activa `fact_orden_servicio.id_fecha_creacion_orden`

8. Ingreso por ruta (Top 10)
- Visual: Barras (Top N)
- Campos: Eje = `dim_ruta[codigo_ruta]`, Valores = `Ingreso Total BOB`
- Fecha: usa relacion activa `fact_orden_servicio.id_fecha_creacion_orden`

**DAX (medidas)**
```DAX
Ingreso Total BOB =
SUM(fact_orden_servicio[total_orden_bob])

Ingreso Segmento % =
DIVIDE(
    [Ingreso Total BOB],
    CALCULATE([Ingreso Total BOB], ALL(dim_cliente[segmento]))
)

Ordenes Aprobadas =
SUM(fact_orden_servicio[orden_aprobada_flag])

Ordenes con Envio =
SUM(fact_orden_servicio[envio_generado_flag])

Conversion Orden-Envio % =
DIVIDE([Ordenes con Envio], [Ordenes Aprobadas])

Ingreso por Tipo Tarifario % =
DIVIDE(
    [Ingreso Total BOB],
    CALCULATE([Ingreso Total BOB], ALL(dim_tarifa[tipo_tarifario]))
)

Credito Utilizado % =
DIVIDE(
    SUM(fact_orden_servicio[saldo_utilizado_bob_snapshot]),
    SUM(fact_orden_servicio[limite_credito_bob_snapshot])
)

Clientes Alta Exposicion =
CALCULATE(
    DISTINCTCOUNT(fact_orden_servicio[id_cliente]),
    FILTER(fact_orden_servicio, [Credito Utilizado %] >= 0.8)
)

Clientes Totales =
DISTINCTCOUNT(fact_orden_servicio[id_cliente])

Clientes Alta Exposicion % =
DIVIDE([Clientes Alta Exposicion], [Clientes Totales])

Ingreso Ordenado BOB =
[Ingreso Total BOB]

Ingreso Facturado BOB =
SUM(fact_facturacion[total_linea_bob])

Facturado vs Ordenado % =
DIVIDE([Ingreso Facturado BOB], [Ingreso Ordenado BOB])

Tasa Devolucion % =
DIVIDE(
    SUM(fact_orden_servicio[devuelto_flag]),
    SUM(fact_orden_servicio[cantidad_ordenes])
)
```

**DAX (graficos especificos)**
```DAX
-- Para el embudo, crear una tabla desconectada:
-- FunnelEtapas = DATATABLE("Etapa", STRING, {{"Ordenes Aprobadas"},{"Ordenes con Envio"}})

Funnel Valor =
SWITCH(
    SELECTEDVALUE(FunnelEtapas[Etapa]),
    "Ordenes Aprobadas", [Ordenes Aprobadas],
    "Ordenes con Envio", [Ordenes con Envio]
)
```

## 1) Area Comercial - Graficos

1. Linea de ingreso mensual
- Visual: Linea
- Campos: Eje = `dim_fecha[mes]`, Valores = `Ingreso Total BOB`
- Fecha: usa relacion activa `fact_orden_servicio.id_fecha_creacion_orden`

2. Mapa de calor ruta vs ingreso
- Visual: Matriz con formato condicional (heatmap)
- Campos: Filas = `dim_ruta[ciudad_origen]`, Columnas = `dim_ruta[ciudad_destino]`, Valores = `Ingreso Total BOB`
- Fecha: usa relacion activa `fact_orden_servicio.id_fecha_creacion_orden`

3. Funnel orden -> envio
- Visual: Embudo
- Campos: Categoria = {`Ordenes Aprobadas`, `Ordenes con Envio`}, Valores = medidas
- Fecha: usa relacion activa `fact_orden_servicio.id_fecha_creacion_orden`

4. Ranking clientes con mayor riesgo
- Visual: Barras (Top N)
- Campos: Eje = `dim_cliente[nombre_razon_social]`, Valores = `Credito Utilizado %` o `Clientes Alta Exposicion` (medida)
- Fecha: usa relacion activa `fact_orden_servicio.id_fecha_creacion_orden`

---

## 2) Area Operaciones Logisticas - KPIs

1. Cumplimiento SLA de recojo (%)
- Visual: KPI / Tarjeta
- Campos: Valor = `SLA Recojo %` (medida), Tabla base `fact_envio`
- Fecha: por defecto `fact_envio.id_fecha_registro_envio`. Si se requiere por compromiso, usar `USERELATIONSHIP(fact_envio[id_fecha_compromiso_recojo], dim_fecha[id_fecha])`.

2. Tiempo de ciclo logistico promedio (hrs)
- Visual: Tarjeta
- Campos: Valor = `Tiempo Ciclo Promedio` (medida), Tabla base `fact_envio`
- Fecha: usa relacion activa `fact_envio.id_fecha_registro_envio`

3. Ocupacion promedio de flota (%)
- Visual: Tarjeta
- Campos: Valor = `Ocupacion Promedio %` (medida), Tabla base `fact_viaje`
- Fecha: usa relacion activa `fact_viaje.id_fecha_salida`

4. Costo operativo por km (BOB/km)
- Visual: Tarjeta
- Campos: Valor = `Costo por KM` (medida), Tabla base `fact_viaje`
- Fecha: usa relacion activa `fact_viaje.id_fecha_salida`

5. Alertas criticas por 100 tramos
- Visual: Tarjeta
- Campos: Valor = `Alertas Criticas x100` (medida), Tabla base `fact_tracking_evento` o `fact_viaje`
- Fecha: si usa `fact_tracking_evento`, relacion activa `id_fecha_evento`. Si usa `fact_viaje`, relacion activa `id_fecha_salida`.

**DAX (medidas)**
```DAX
SLA Recojo % =
DIVIDE(
    SUM(fact_envio[cumple_sla_recojo_flag]),
    SUM(fact_envio[envio_cerrado_flag])
)

Tiempo Ciclo Promedio =
AVERAGE(fact_envio[tiempo_ciclo_horas])

Ocupacion Promedio % =
AVERAGE(fact_viaje[ocupacion_pct])

Costo Operativo Total =
SUM(fact_viaje[costo_operativo_total_bob])

Costo por KM =
DIVIDE(
    SUM(fact_viaje[costo_operativo_total_bob]),
    SUM(fact_viaje[distancia_km])
)

Alertas Criticas (Viaje) =
SUM(fact_viaje[alertas_criticas_count])

Alertas Criticas x100 =
DIVIDE([Alertas Criticas (Viaje)] * 100, SUM(fact_viaje[cantidad_viajes]))

Alertas Criticas (Evento) =
SUM(fact_tracking_evento[alerta_critica_flag])
```

## 2) Area Operaciones Logisticas - Graficos

1. Linea de cumplimiento mensual (SLA)
- Visual: Linea
- Campos: Eje = `dim_fecha[mes]`, Valores = `SLA Recojo %`
- Fecha: por defecto `fact_envio.id_fecha_registro_envio`. Si se quiere por cierre, usar `USERELATIONSHIP(fact_envio[id_fecha_cierre_envio], dim_fecha[id_fecha])`.

2. Dispersion costo vs ocupacion
- Visual: Scatter
- Campos: Eje X = `Ocupacion %`, Eje Y = `Costo por KM`, Detalle = `dim_ruta[codigo_ruta]` (base `fact_viaje`)
- Fecha: usa relacion activa `fact_viaje.id_fecha_salida`

3. Ranking de costo por ruta
- Visual: Barras
- Campos: Eje = `dim_ruta[codigo_ruta]`, Valores = `Costo Operativo Total`
- Fecha: usa relacion activa `fact_viaje.id_fecha_salida`

4. Mapa de calor de alertas por conductor y ruta
- Visual: Matriz con formato condicional
- Campos: Filas = `dim_conductor[nombre]`, Columnas = `dim_ruta[codigo_ruta]`, Valores = `Alertas Criticas` (base `fact_tracking_evento`)
- Fecha: usa relacion activa `fact_tracking_evento.id_fecha_evento`

---

## 3) Area Finanzas y Cobranzas - KPIs

1. Facturacion total del periodo (BOB)
- Visual: Tarjeta
- Campos: Valor = `Facturacion Total` (medida), base `fact_facturacion`
- Fecha: usa relacion activa `fact_facturacion.id_fecha_emision`

2. Cobranza total del periodo (BOB)
- Visual: Tarjeta
- Campos: Valor = `Cobranza Total` (medida), base `fact_pago`
- Fecha: usa relacion activa `fact_pago.id_fecha_pago`

3. Cobertura de facturacion sobre envios cerrados (%)
- Visual: KPI / Tarjeta
- Campos: Valor = `Cobertura Facturacion %` (medida), base `fact_envio` + `fact_facturacion`
- Fecha: envios cerrados deben usar `USERELATIONSHIP(fact_envio[id_fecha_cierre_envio], dim_fecha[id_fecha])`. Facturacion usa `id_fecha_emision`.

4. Indice de cartera vencida (%)
- Visual: KPI / Tarjeta
- Campos: Valor = `Cartera Vencida %` (medida), base `fact_facturacion` + `dim_factura`
- Fecha: usa relacion activa `fact_facturacion.id_fecha_emision`

5. Dias promedio pendientes de cobro (DSO)
- Visual: Tarjeta
- Campos: Valor = `DSO Promedio` (medida), base `fact_pago`
- Fecha: usa relacion activa `fact_pago.id_fecha_pago`

**DAX (medidas)**
```DAX
Facturacion Total =
SUM(fact_facturacion[total_linea_bob])

Cobranza Total =
SUM(fact_pago[monto_bob])

Envios Cerrados =
CALCULATE(
    DISTINCTCOUNT(fact_envio[id_envio]),
    fact_envio[envio_cerrado_flag] = 1
)

Envios Facturados =
DISTINCTCOUNT(fact_facturacion[id_envio])

Cobertura Facturacion % =
DIVIDE([Envios Facturados], [Envios Cerrados])

Cartera Vencida =
CALCULATE(
    [Facturacion Total],
    dim_factura[estado_cobro] = "VENCIDO"
)

Cartera Vencida % =
DIVIDE([Cartera Vencida], [Facturacion Total])

DSO Promedio =
AVERAGE(fact_pago[dias_cobro_desde_emision])
```

**DAX (graficos especificos)**
```DAX
-- Para antiguedad de cartera, crear columnas en dim_factura:
-- Dias Mora = DATEDIFF(dim_factura[fecha_vencimiento], TODAY(), DAY)
-- Rango Mora = SWITCH(TRUE(), [Dias Mora] <= 30, "0-30", [Dias Mora] <= 60, "31-60", [Dias Mora] <= 90, "61-90", "90+")
```

## 3) Area Finanzas y Cobranzas - Graficos

1. Linea facturacion vs cobranza mensual
- Visual: Linea (2 series)
- Campos: Eje = `dim_fecha[mes]`, Valores = `Facturacion Total`, `Cobranza Total`
- Fecha: usa relaciones activas de `fact_facturacion.id_fecha_emision` y `fact_pago.id_fecha_pago`. Si hay conflicto, duplicar `dim_fecha`.

2. Embudo envio cerrado -> facturado
- Visual: Embudo
- Campos: Categoria = {`Envios Cerrados`, `Envios Facturados`}, Valores = medidas
- Fecha: envios cerrados con `USERELATIONSHIP(fact_envio[id_fecha_cierre_envio], dim_fecha[id_fecha])`. Facturados con `fact_facturacion.id_fecha_emision`.

3. Barras apiladas de antiguedad de cartera
- Visual: Barras apiladas
- Campos: Eje = `dim_fecha[mes]`, Leyenda = `Rango Mora`, Valores = `Monto Vencido`
- Fecha: usa `fact_facturacion.id_fecha_emision` y la columna `Rango Mora` calculada en `dim_factura`.

4. Pareto de clientes morosos
- Visual: Barras + linea acumulada
- Campos: Eje = `dim_cliente[nombre_razon_social]`, Valores = `Monto Vencido`
- Fecha: usa relacion activa `fact_facturacion.id_fecha_emision`

---

## 4) Area Costos y RRHH - KPIs

1. Costo laboral sobre ingresos (%)
- Visual: KPI / Tarjeta
- Campos: Valor = `Costo Laboral sobre Ingresos %` (medida), base `fact_rrhh_mensual` + `fact_facturacion`
- Fecha: `fact_rrhh_mensual.id_fecha_periodo` activa. Facturacion usa `id_fecha_emision`. Si se requiere mismo periodo, usar `TREATAS`.

2. Tasa de ausentismo (%)
- Visual: Tarjeta
- Campos: Valor = `Tasa Ausentismo %` (medida), base `fact_rrhh_mensual`
- Fecha: usa relacion activa `fact_rrhh_mensual.id_fecha_periodo`

3. Proporcion de horas extra (%)
- Visual: Tarjeta
- Campos: Valor = `Horas Extra %` (medida), base `fact_rrhh_mensual`
- Fecha: usa relacion activa `fact_rrhh_mensual.id_fecha_periodo`

4. Participacion de nomina en costo total (%)
- Visual: No disponible (no existe `dim_tipo_costo`)

5. Costo laboral total (BOB)
- Visual: Tarjeta
- Campos: Valor = `Costo Laboral Total` (medida), base `fact_rrhh_mensual`
- Fecha: usa relacion activa `fact_rrhh_mensual.id_fecha_periodo`

**DAX (medidas)**
```DAX
Costo Laboral Total =
SUM(fact_rrhh_mensual[liquido_pagable_bob])

Tasa Ausentismo % =
AVERAGE(fact_rrhh_mensual[tasa_ausentismo_pct])

Horas Extra =
SUM(fact_rrhh_mensual[horas_extra])

Horas Extra % =
DIVIDE(
    SUM(fact_rrhh_mensual[horas_extra]),
    SUM(fact_rrhh_mensual[horas_trabajadas])
)

FTE Total =
SUM(fact_rrhh_mensual[fte_equivalente])

Costo Laboral sobre Ingresos % =
DIVIDE([Costo Laboral Total], [Facturacion Total])
```

## 4) Area Costos y RRHH - Graficos

1. Doble eje: costo laboral vs ingresos
- Visual: Linea con eje secundario
- Campos: Eje = `dim_fecha[mes]`, Valores = `Costo Laboral Total` y `Facturacion Total`
- Fecha: si se requiere mismo periodo, usar `TREATAS` para facturacion con `dim_fecha` de RRHH.

2. Mapa de calor de ausentismo por area/mes
- Visual: Matriz con formato condicional
- Campos: Filas = `dim_empleado[area]`, Columnas = `dim_fecha[mes]`, Valores = `Tasa Ausentismo %`
- Fecha: usa relacion activa `fact_rrhh_mensual.id_fecha_periodo`

3. Barras de horas extra por area
- Visual: Barras
- Campos: Eje = `dim_empleado[area]`, Valores = `Horas Extra`
- Fecha: usa relacion activa `fact_rrhh_mensual.id_fecha_periodo`

4. Dona de composicion de costos
- Visual: No disponible (no existe `dim_tipo_costo`)

---

## 5) Area Telemetria - KPIs

1. Alertas criticas por cada 100 tramos
- Visual: Tarjeta
- Campos: Valor = `Alertas Criticas x100` (medida), base `fact_viaje` o `fact_tracking_evento`
- Fecha: si usa `fact_tracking_evento`, relacion activa `id_fecha_evento`. Si usa `fact_viaje`, relacion activa `id_fecha_salida`.

2. Alertas criticas asociadas a mantenimiento correctivo (%)
- Visual: Tarjeta
- Campos: Valor = `Alertas Criticas con Mantenimiento %` (medida), base `fact_tracking_evento`
- Fecha: usa relacion activa `fact_tracking_evento.id_fecha_evento`

3. Indice de temperatura critica de motor
- Visual: Tarjeta
- Campos: Valor = `Indice Temp Critica %` (medida), base `fact_viaje` o `fact_tracking_evento`
- Fecha: si usa `fact_viaje`, relacion activa `id_fecha_salida`. Si usa `fact_tracking_evento`, `id_fecha_evento`.

4. Velocidad promedio operativa (km/h)
- Visual: Tarjeta
- Campos: Valor = `Velocidad Promedio` (medida), base `fact_viaje`
- Fecha: usa relacion activa `fact_viaje.id_fecha_salida`

5. Cobertura de telemetria por viaje (%)
- Visual: Tarjeta
- Campos: Valor = `Cobertura Telemetria %` (medida), base `fact_viaje`
- Fecha: usa relacion activa `fact_viaje.id_fecha_salida`

**DAX (medidas)**
```DAX
Cobertura Telemetria % =
AVERAGE(fact_viaje[cobertura_telemetria_pct])

Interrupciones Senal =
SUM(fact_viaje[interrupciones_senal_count])

Velocidad Promedio =
AVERAGE(fact_viaje[velocidad_promedio_kmh])

Alertas Criticas (Viaje) =
SUM(fact_viaje[alertas_criticas_count])

Alertas Criticas x100 =
DIVIDE([Alertas Criticas (Viaje)] * 100, SUM(fact_viaje[cantidad_viajes]))

Alertas Criticas (Evento) =
SUM(fact_tracking_evento[alerta_critica_flag])

Alertas Criticas con Mant % =
DIVIDE(
    CALCULATE([Alertas Criticas (Evento)], fact_tracking_evento[mantenimiento_correctivo_30d_flag] = 1),
    [Alertas Criticas (Evento)]
)

Viajes Temp Critica =
CALCULATE(
    SUM(fact_viaje[cantidad_viajes]),
    fact_viaje[temp_max_motor_c] >= 95
)

Indice Temp Critica % =
DIVIDE([Viajes Temp Critica], SUM(fact_viaje[cantidad_viajes]))
```

## 5) Area Telemetria - Graficos

1. Medidor de cobertura telemetrica
- Visual: Medidor / KPI
- Campos: Valor = `Cobertura Telemetria %`
- Fecha: usa relacion activa `fact_viaje.id_fecha_salida`

2. Linea de cobertura semanal
- Visual: Linea
- Campos: Eje = `dim_fecha[semana]`, Valores = `Cobertura Telemetria %`
- Fecha: usa relacion activa `fact_viaje.id_fecha_salida`

3. Barras de interrupciones por vehiculo
- Visual: Barras
- Campos: Eje = `dim_vehiculo[placa]`, Valores = `Interrupciones Senal`
- Fecha: usa relacion activa `fact_viaje.id_fecha_salida`

4. Mapa de calor de alertas por ruta y hora
- Visual: Matriz con formato condicional
- Campos: Filas = `dim_ruta[codigo_ruta]`, Columnas = `dim_hora[hora]`, Valores = `Alertas Criticas`
- Fecha: usa relacion activa `fact_tracking_evento.id_fecha_evento`
