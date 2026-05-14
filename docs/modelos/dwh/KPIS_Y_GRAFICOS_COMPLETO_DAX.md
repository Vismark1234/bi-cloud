# KPIs y Graficos (con formulas, DAX y detalle claro)

Este documento lista KPIs y graficos por area usando el DWH actual.

---

## 1) Area Comercial

### KPIs

| KPI | Que mide (claro y directo) | Ejemplo corto | Por que importa para la empresa | Granularidad recomendada | Formula / DAX | Tablas |
|---|---|---|---|---|---|---|
| Ingreso total comercial (BOB) | Suma de ingresos por orden en el periodo (ventas generadas). | Ej: 120.000 BOB en marzo. | Mide crecimiento comercial y base de ingresos. | Mes, trimestre, anio. | `Ingreso Total BOB = SUM(fact_orden_servicio[total_orden_bob])` | `fact_orden_servicio`, `dim_fecha` |
| Ingreso facturado comercial (BOB) | Ingresos efectivamente facturados en el periodo. | Ej: 95.000 BOB facturados en marzo. | Indica liquidez real y ejecucion administrativa. | Mes, trimestre, anio. | `Ingreso Facturado BOB = SUM(fact_facturacion[total_linea_bob])` | `fact_facturacion`, `dim_fecha` |
| Ingreso por segmento (%) | Participacion de cada segmento en el total de ingresos. | Ej: Corporativo 65%, Ventanilla 35%. | Permite enfocar estrategias y precios por segmento. | Segmento x mes. | `Ingreso Segmento % = DIVIDE([Ingreso Total BOB], CALCULATE([Ingreso Total BOB], ALL(dim_cliente[segmento])))` | `fact_orden_servicio`, `dim_cliente`, `dim_fecha` |
| Peso transportado por segmento (kg y %) | Peso total movido por segmento y su participacion. | Ej: Corporativo 48.000 kg (70%). | Muestra demanda fisica y uso operativo por segmento. | Segmento x mes. | `Peso Segmento KG = SUM(fact_envio[peso_envio_kg])` y `% = DIVIDE([Peso Segmento KG], CALCULATE([Peso Segmento KG], ALL(dim_cliente[segmento])))` | `fact_envio`, `dim_cliente`, `dim_fecha` |
| Ticket promedio por orden (BOB) | Ingreso promedio por orden (valor medio de orden). | Ej: 520 BOB por orden. | Ayuda a evaluar rentabilidad y calidad de ventas. | Mes, segmento, ruta. | `Ticket Promedio = DIVIDE(SUM(fact_orden_servicio[total_orden_bob]), SUM(fact_orden_servicio[cantidad_ordenes]))` | `fact_orden_servicio`, `dim_fecha` |
| Conversion orden aprobada -> envio (%) | Porcentaje de ordenes aprobadas que llegan a envio real. | Ej: 82% de ordenes aprobadas se ejecutan. | Detecta fuga comercial y problemas operativos. | Mes, sucursal, ruta. | `Conversion % = DIVIDE(SUM(fact_orden_servicio[envio_generado_flag]), SUM(fact_orden_servicio[orden_aprobada_flag]))` | `fact_orden_servicio`, `dim_fecha` |
| Ordenes vencidas sin envio (conteo) | Cantidad de ordenes que vencieron sin ejecucion logistica. | Ej: 34 ordenes vencidas en abril. | Indica perdida de ingresos y atencion a clientes. | Mes, cliente. | `Ordenes Vencidas = SUM(fact_orden_servicio[orden_vencida_sin_envio_flag])` | `fact_orden_servicio`, `dim_fecha` |
| Participacion ingresos por tipo tarifario (%) | Cuanto aporta cada tipo tarifario al ingreso total. | Ej: Contrato 72%, Ventanilla 28%. | Ayuda a ajustar mix comercial y politicas tarifarias. | Tipo tarifario x mes. | `Ingreso Tipo % = DIVIDE([Ingreso Total BOB], CALCULATE([Ingreso Total BOB], ALL(dim_tarifa[tipo_tarifario])))` | `fact_orden_servicio`, `dim_tarifa`, `dim_fecha` |
| Ingreso por ruta (Top 10) | Rutas con mayor ingreso (ranking). | Ej: LPZ-SCZ 18.000 BOB. | Prioriza rutas rentables y planificacion comercial. | Ruta x mes. | `Ingreso Total BOB` (usar Top N en visual) | `fact_orden_servicio`, `dim_ruta`, `dim_fecha` |

### Graficos

| Grafico | Tipo de grafico (Power BI) | Que mide (explicacion clara) | Ejemplo corto | Por que importa para la empresa | Granularidad (detalle) | Campos (Power BI) | DAX usado |
|---|---|---|---|---|---|---|---|
| Linea de ingreso mensual | Linea | Tendencia de ingresos en el tiempo. | Ej: pico en diciembre. | Permite ver crecimiento o caida sostenida. | Mes o semana. | Eje: `dim_fecha[mes]`, Valores: `Ingreso Total BOB` | `Ingreso Total BOB` |
| Barras ingreso por segmento | Barras agrupadas | Comparacion del aporte de ingresos por segmento. | Ej: Corporativo supera a Ventanilla. | Apoya decisiones de foco comercial. | Segmento. | Eje: `dim_cliente[segmento]`, Valores: `Ingreso Total BOB` | `Ingreso Total BOB` |
| Barras 100% de peso por segmento | Barras 100% apiladas | Proporcion del peso transportado por segmento. | Ej: 70% corporativo. | Alinea capacidad operativa con demanda real. | Segmento. | Eje: `dim_cliente[segmento]`, Valores: `Peso Segmento KG` | `Peso Segmento KG` |
| Mapa de calor ruta vs ingreso | Matriz con formato condicional | Identifica rutas origen-destino con mayor ingreso. | Ej: LPZ-SCZ en rojo intenso. | Revela rutas mas rentables. | Origen x destino. | Filas: `dim_ruta[ciudad_origen]`, Columnas: `dim_ruta[ciudad_destino]`, Valores: `Ingreso Total BOB` | `Ingreso Total BOB` |
| Funnel orden -> envio | Embudo | Mide la fuga comercial entre orden aprobada y envio real. | Ej: 1.000 aprobadas, 820 envios. | Detecta donde se pierden ventas. | Total o por periodo. | Categoria: `Ordenes Aprobadas` / `Ordenes con Envio` | ver DAX Funnel |
| Barras ordenes vencidas por cliente | Barras horizontales | Clientes con mas ordenes vencidas sin envio. | Ej: Cliente A con 12 vencidas. | Ayuda a priorizar recuperacion. | Cliente. | Eje: `dim_cliente[nombre_razon_social]`, Valores: `Ordenes Vencidas` | `Ordenes Vencidas` |
| Dona VENTANILLA vs CONTRATO | Dona | Distribucion de ingresos por tipo tarifario. | Ej: 72% Contrato. | Clarifica mix comercial y dependencia. | Tipo tarifario. | Leyenda: `dim_tarifa[tipo_tarifario]`, Valores: `Ingreso Total BOB` | `Ingreso Total BOB` |

**DAX Funnel**
```DAX
-- Tabla desconectada
-- FunnelEtapas = DATATABLE("Etapa", STRING, {{"Ordenes Aprobadas"},{"Ordenes con Envio"}})

Ordenes Aprobadas =
SUM(fact_orden_servicio[orden_aprobada_flag])

Ordenes con Envio =
SUM(fact_orden_servicio[envio_generado_flag])

Funnel Valor =
SWITCH(
    SELECTEDVALUE(FunnelEtapas[Etapa]),
    "Ordenes Aprobadas", [Ordenes Aprobadas],
    "Ordenes con Envio", [Ordenes con Envio]
)
```

---

## 2) Area Operaciones Logisticas

### KPIs

| KPI | Que mide (claro y directo) | Ejemplo corto | Por que importa para la empresa | Granularidad recomendada | Formula / DAX | Tablas |
|---|---|---|---|---|---|---|
| Cumplimiento SLA de recojo (%) | Porcentaje de envios cerrados que cumplieron el SLA de recojo. | Ej: 88% en abril. | Impacta satisfaccion y penalidades. | Sucursal, ruta, mes. | `SLA Recojo % = DIVIDE(SUM(fact_envio[cumple_sla_recojo_flag]), SUM(fact_envio[envio_cerrado_flag]))` | `fact_envio`, `dim_fecha` |
| Tiempo de ciclo logistico promedio (hrs) | Promedio de horas desde orden a cierre de envio. | Ej: 36 horas promedio. | Mide velocidad del servicio. | Ruta, sucursal, mes. | `Tiempo Ciclo Promedio = AVERAGE(fact_envio[tiempo_ciclo_horas])` | `fact_envio`, `dim_fecha` |
| Desviacion promedio de SLA (hrs) | Cuantas horas se excede o se adelanta el SLA. | Ej: +4.2 horas de demora. | Identifica cuellos de botella. | Ruta, sucursal, mes. | `Desviacion SLA = AVERAGE(fact_envio[desviacion_sla_horas])` | `fact_envio`, `dim_fecha` |
| Ocupacion promedio de flota (%) | Uso promedio de capacidad vs capacidad total. | Ej: 74% ocupacion. | Reduce costos y mejora eficiencia. | Vehiculo, ruta, mes. | `Ocupacion Promedio % = AVERAGE(fact_viaje[ocupacion_pct])` | `fact_viaje`, `dim_fecha` |
| Tasa de sobrecapacidad (%) | Porcentaje de viajes que superan la capacidad. | Ej: 6% viajes sobrecarga. | Reduce riesgo operativo y multas. | Vehiculo, ruta, mes. | `Sobrecapacidad % = DIVIDE(SUM(fact_viaje[sobrecapacidad_flag]), SUM(fact_viaje[cantidad_viajes]))` | `fact_viaje`, `dim_fecha` |
| Costo operativo por km (BOB/km) | Costo operativo promedio por kilometro recorrido. | Ej: 8.5 BOB/km. | Controla rentabilidad de rutas. | Ruta, mes. | `Costo por KM = DIVIDE(SUM(fact_viaje[costo_operativo_total_bob]), SUM(fact_viaje[distancia_km]))` | `fact_viaje`, `dim_fecha` |
| Alertas criticas por 100 viajes | Intensidad de alertas criticas normalizada. | Ej: 14 alertas por 100 viajes. | Indica riesgo de seguridad y calidad. | Ruta, conductor, mes. | `Alertas x100 = DIVIDE(SUM(fact_viaje[alertas_criticas_count]) * 100, SUM(fact_viaje[cantidad_viajes]))` | `fact_viaje`, `dim_fecha` |

### Graficos

| Grafico | Tipo de grafico (Power BI) | Que mide (explicacion clara) | Ejemplo corto | Por que importa para la empresa | Granularidad (detalle) | Campos (Power BI) | DAX usado |
|---|---|---|---|---|---|---|---|
| Linea de cumplimiento mensual (SLA) | Linea | Evolucion mensual del cumplimiento SLA. | Ej: baja de 92% a 84%. | Permite actuar antes de reclamos. | Mes. | Eje: `dim_fecha[mes]`, Valores: `SLA Recojo %` | `SLA Recojo %` |
| Dispersion costo vs ocupacion | Dispersión | Relacion entre eficiencia (ocupacion) y costo por km. | Ej: rutas con baja ocupacion y alto costo. | Detecta ineficiencias claras. | Ruta o vehiculo. | X: `Ocupacion Promedio %`, Y: `Costo por KM`, Detalle: `dim_ruta[codigo_ruta]` | `Ocupacion Promedio %`, `Costo por KM` |
| Ranking costo por ruta | Barras horizontales | Rutas mas caras para priorizar optimizacion. | Ej: ruta A con mayor costo. | Prioriza mejoras y renegociaciones. | Ruta. | Eje: `dim_ruta[codigo_ruta]`, Valores: `Costo Operativo Total` | `Costo Operativo Total = SUM(fact_viaje[costo_operativo_total_bob])` |
| Heatmap alertas por conductor y ruta | Matriz con formato condicional | Conductores y rutas con mayor riesgo (alertas). | Ej: Conductor X en ruta Y. | Reduce incidentes y mejora seguridad. | Conductor x ruta. | Filas: `dim_conductor[licencia_nro]`, Columnas: `dim_ruta[codigo_ruta]`, Valores: `Alertas Criticas` | `Alertas Criticas = SUM(fact_tracking_evento[alerta_critica_flag])` |

---

## 3) Area Finanzas y Cobranzas

### KPIs

| KPI | Que mide (claro y directo) | Ejemplo corto | Por que importa para la empresa | Granularidad recomendada | Formula / DAX | Tablas |
|---|---|---|---|---|---|---|
| Facturacion total del periodo (BOB) | Monto total facturado en el periodo. | Ej: 140.000 BOB en abril. | Indica ingresos formalizados. | Mes, cliente. | `Facturacion Total = SUM(fact_facturacion[total_linea_bob])` | `fact_facturacion`, `dim_fecha` |
| Cobranza total del periodo (BOB) | Monto efectivamente cobrado en el periodo. | Ej: 110.000 BOB cobrados. | Mide liquidez y flujo de caja. | Mes, cliente. | `Cobranza Total = SUM(fact_pago[monto_bob])` | `fact_pago`, `dim_fecha` |
| Cobertura facturacion sobre envios cerrados (%) | Proporcion de envios cerrados que ya tienen facturacion. | Ej: 78% cubierto. | Evita ventas no facturadas. | Mes, cliente. | `Cobertura % = DIVIDE([Envios Facturados],[Envios Cerrados])` | `fact_envio`, `fact_facturacion`, `dim_fecha` |
| Indice de cartera vencida (%) | Porcentaje de facturacion vencida respecto al total. | Ej: 12% vencido. | Controla riesgo financiero. | Mes, cliente. | `Cartera Vencida % = DIVIDE([Cartera Vencida],[Facturacion Total])` | `fact_facturacion`, `dim_factura`, `dim_fecha` |
| DSO promedio (dias) | Dias promedio entre emision y pago. | Ej: 42 dias. | Evalua eficiencia de cobranza. | Mes, cliente. | `DSO Promedio = AVERAGE(fact_pago[dias_cobro_desde_emision])` | `fact_pago`, `dim_fecha` |

**DAX soporte**
```DAX
Envios Cerrados =
CALCULATE(
    DISTINCTCOUNT(fact_envio[id_envio]),
    fact_envio[envio_cerrado_flag] = 1
)

Envios Facturados =
DISTINCTCOUNT(fact_facturacion[id_envio])

Cartera Vencida =
CALCULATE(
    [Facturacion Total],
    dim_factura[estado_cobro] = "VENCIDO"
)

-- Columna calculada sugerida en dim_factura (si no existe en el modelo)
Dias Mora =
DATEDIFF(dim_factura[fecha_vencimiento], TODAY(), DAY)

Rango Mora =
SWITCH(
    TRUE(),
    [Dias Mora] <= 30, "0-30",
    [Dias Mora] <= 60, "31-60",
    [Dias Mora] <= 90, "61-90",
    "90+"
)
```

### Graficos

| Grafico | Tipo de grafico (Power BI) | Que mide (explicacion clara) | Ejemplo corto | Por que importa para la empresa | Granularidad (detalle) | Campos (Power BI) | DAX usado |
|---|---|---|---|---|---|---|---|
| Linea facturacion vs cobranza mensual | Linea doble | Brecha de caja: facturado vs cobrado mes a mes. | Ej: facturo 140k, cobro 110k. | Muestra riesgo de liquidez. | Mes. | Eje: `dim_fecha[mes]`, Valores: `Facturacion Total` y `Cobranza Total` | `Facturacion Total`, `Cobranza Total` |
| Embudo envio cerrado -> facturado | Embudo | Cuello de botella entre operacion cerrada y facturacion. | Ej: 900 cerrados, 700 facturados. | Evita perdida de ingresos. | Total o por mes. | Categoria: `Envios Cerrados`, `Envios Facturados` | `Envios Cerrados`, `Envios Facturados` |
| Barras apiladas antiguedad cartera | Barras apiladas | Distribucion de deuda por rango de mora. | Ej: 30-60 dias domina. | Prioriza cobranza. | Mes o cliente. | Eje: `dim_fecha[mes]`, Leyenda: `Rango Mora`, Valores: `Monto Vencido` | `Cartera Vencida` |
| Pareto clientes morosos | Pareto (barras + linea) | Clientes que concentran la mora. | Ej: top 5 = 80% deuda. | Enfoca esfuerzo en mayor impacto. | Cliente. | Eje: `dim_cliente[nombre_razon_social]`, Valores: `Cartera Vencida` | `Cartera Vencida` |

---

## 4) Area Costos y RRHH

### KPIs

| KPI | Que mide (claro y directo) | Ejemplo corto | Por que importa para la empresa | Granularidad recomendada | Formula / DAX | Tablas |
|---|---|---|---|---|---|---|
| Costo laboral sobre ingresos (%) | Porcentaje de ingresos consumido por sueldos. | Ej: 22% del ingreso. | Controla rentabilidad y estructura de costos. | Mes, sucursal. | `Costo Laboral % = DIVIDE([Costo Laboral Total],[Facturacion Total])` | `fact_rrhh_mensual`, `fact_facturacion`, `dim_fecha` |
| Tasa de ausentismo (%) | Promedio de ausencias en el personal. | Ej: 4.5% mensual. | Afecta productividad y calidad operativa. | Mes, area. | `Tasa Ausentismo % = AVERAGE(fact_rrhh_mensual[tasa_ausentismo_pct])` | `fact_rrhh_mensual`, `dim_fecha` |
| Proporcion horas extra (%) | Peso de horas extra vs horas trabajadas. | Ej: 12% horas extra. | Indica sobrecarga y costo adicional. | Mes, area. | `Horas Extra % = DIVIDE(SUM(fact_rrhh_mensual[horas_extra]), SUM(fact_rrhh_mensual[horas_trabajadas]))` | `fact_rrhh_mensual`, `dim_fecha` |
| Costo laboral total (BOB) | Monto total de sueldos pagados. | Ej: 75.000 BOB. | Base para presupuesto y control financiero. | Mes, sucursal. | `Costo Laboral Total = SUM(fact_rrhh_mensual[liquido_pagable_bob])` | `fact_rrhh_mensual`, `dim_fecha` |

### Graficos

| Grafico | Tipo de grafico (Power BI) | Que mide (explicacion clara) | Ejemplo corto | Por que importa para la empresa | Granularidad (detalle) | Campos (Power BI) | DAX usado |
|---|---|---|---|---|---|---|---|
| Doble eje costo laboral vs ingresos | Linea doble (eje secundario) | Relacion entre gasto salarial y facturacion. | Ej: costo sube, ingresos no. | Muestra si la planilla es sostenible. | Mes. | Eje: `dim_fecha[mes]`, Valores: `Costo Laboral Total` y `Facturacion Total` | `Costo Laboral Total`, `Facturacion Total` |
| Heatmap ausentismo por area/mes | Matriz con formato condicional | Areas con picos de ausentismo por mes. | Ej: area X alta en julio. | Permite acciones correctivas tempranas. | Area x mes. | Filas: `dim_empleado[area]`, Columnas: `dim_fecha[mes]`, Valores: `Tasa Ausentismo %` | `Tasa Ausentismo %` |
| Barras horas extra por area | Barras | Areas con mayor carga de horas extra. | Ej: operaciones 2x otras areas. | Ayuda a equilibrar carga y costos. | Area. | Eje: `dim_empleado[area]`, Valores: `Horas Extra` | `Horas Extra = SUM(fact_rrhh_mensual[horas_extra])` |

---

## 5) Area Telemetria

### KPIs

| KPI | Que mide (claro y directo) | Ejemplo corto | Por que importa para la empresa | Granularidad recomendada | Formula / DAX | Tablas |
|---|---|---|---|---|---|---|
| Alertas criticas por cada 100 viajes | Intensidad de alertas criticas por volumen de viajes. | Ej: 10 alertas por 100 viajes. | Indica riesgo operativo y seguridad. | Ruta, conductor, mes. | `Alertas x100 = DIVIDE(SUM(fact_viaje[alertas_criticas_count]) * 100, SUM(fact_viaje[cantidad_viajes]))` | `fact_viaje`, `dim_fecha` |
| Alertas criticas asociadas a mantenimiento correctivo (%) | Porcentaje de alertas criticas ligadas a mantenimiento correctivo. | Ej: 25% con mantenimiento. | Conecta telemetria con costos de mantenimiento. | Vehiculo, mes. | `Alertas con Mant % = DIVIDE(CALCULATE(SUM(fact_tracking_evento[alerta_critica_flag]), fact_tracking_evento[mantenimiento_correctivo_30d_flag]=1), SUM(fact_tracking_evento[alerta_critica_flag]))` | `fact_tracking_evento`, `dim_fecha` |
| Indice de temperatura critica de motor (%) | Proporcion de viajes con temperatura maxima critica. | Ej: 7% supera 95C. | Anticipa fallas y paradas. | Vehiculo, ruta, mes. | `Indice Temp % = DIVIDE(CALCULATE(SUM(fact_viaje[cantidad_viajes]), fact_viaje[temp_max_motor_c] >= 95), SUM(fact_viaje[cantidad_viajes]))` | `fact_viaje`, `dim_fecha` |
| Velocidad promedio operativa (km/h) | Promedio de velocidad operativa de los viajes. | Ej: 62 km/h. | Mide eficiencia de ruta y tiempos. | Ruta, mes. | `Velocidad Promedio = AVERAGE(fact_viaje[velocidad_promedio_kmh])` | `fact_viaje`, `dim_fecha` |
| Cobertura de telemetria por viaje (%) | Calidad de telemetria medida como % de cobertura. | Ej: 90% cobertura. | Garantiza confiabilidad de analitica. | Vehiculo, ruta, mes. | `Cobertura Telemetria % = AVERAGE(fact_viaje[cobertura_telemetria_pct])` | `fact_viaje`, `dim_fecha` |

### Graficos

| Grafico | Tipo de grafico (Power BI) | Que mide (explicacion clara) | Ejemplo corto | Por que importa para la empresa | Granularidad (detalle) | Campos (Power BI) | DAX usado |
|---|---|---|---|---|---|---|---|
| Medidor de cobertura telemetrica | Medidor (gauge) | Nivel actual de cobertura de telemetria. | Ej: 88% hoy. | Muestra calidad de datos en tiempo real. | Total o por mes. | Valores: `Cobertura Telemetria %` | `Cobertura Telemetria %` |
| Linea de cobertura semanal | Linea | Cambios semanales de cobertura telemetrica. | Ej: caida en semana 14. | Detecta fallas de dispositivos. | Semana. | Eje: `dim_fecha[semana_iso]`, Valores: `Cobertura Telemetria %` | `Cobertura Telemetria %` |
| Barras interrupciones por vehiculo | Barras | Vehiculos con mas cortes de señal. | Ej: Vehiculo ABC con 12 cortes. | Prioriza mantenimiento y reemplazo. | Vehiculo. | Eje: `dim_vehiculo[placa]`, Valores: `Interrupciones Senal` | `Interrupciones Senal = SUM(fact_viaje[interrupciones_senal_count])` |
| Mapa de calor alertas por ruta y hora | Matriz con formato condicional | Rutas y horas con mayor concentracion de alertas criticas. | Ej: ruta X a las 22:00. | Reduce riesgos en puntos criticos. | Ruta x hora. | Filas: `dim_ruta[codigo_ruta]`, Columnas: `dim_hora[hora]`, Valores: `Alertas Criticas` | `Alertas Criticas = SUM(fact_tracking_evento[alerta_critica_flag])` |
