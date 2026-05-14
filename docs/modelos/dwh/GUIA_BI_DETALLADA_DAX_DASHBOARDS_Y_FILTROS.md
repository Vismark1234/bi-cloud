# GUIA BI DETALLADA: DAX, DASHBOARDS, GRAFICOS Y FILTROS

## 1. Objetivo

Este documento traduce el modelo DWH actual a una guia practica de implementacion en Power BI.

Su objetivo es definir:

- que tablas importar
- que relaciones crear
- que medidas DAX construir
- que KPIs mostrar por dashboard
- que graficos usar
- que filtros deben ser globales o locales
- que paginas 360 conviene construir

Este documento complementa a:

- [ESPECIFICACION_KPIS_GRAFICOS_FILTROS_BI.md](./ESPECIFICACION_KPIS_GRAFICOS_FILTROS_BI.md)
- [DICCIONARIO_DWH_FINAL_COMPLETO_HECHOS_DIMENSIONES.md](./DICCIONARIO_DWH_FINAL_COMPLETO_HECHOS_DIMENSIONES.md)

## 2. Tablas a importar a Power BI

Importar desde:

- `DATABASE`: `PROYECTO_BI_TRANSPORTE_V2`
- `SCHEMA`: `DWH_DEV`

Importar solo tablas finales del mart:

### Dimensiones

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

### Hechos

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

No usar en Power BI como fuente principal:

- `stg_*`
- `int_*`
- raw de `MYSQL_COMERCIAL`
- raw de `PG_OPS`
- raw de `SQLSERVER_FIN`
- raw de `MONGO_TELEMETRIA`

## 3. Reglas de modelado en Power BI

## 3.1 Regla principal de fechas

Usar una sola `dim_fecha` como calendario corporativo principal.

Cada hecho debe tener:

- `1` relacion activa con su fecha principal
- relaciones secundarias inactivas cuando existan otras fechas

### Relaciones activas recomendadas

- `fact_orden_servicio[id_fecha_creacion_orden] -> dim_fecha[id_fecha]`
- `fact_envio[id_fecha_registro_envio] -> dim_fecha[id_fecha]`
- `fact_viaje[id_fecha_salida] -> dim_fecha[id_fecha]`
- `fact_tracking_evento[id_fecha_evento] -> dim_fecha[id_fecha]`
- `fact_facturacion[id_fecha_emision] -> dim_fecha[id_fecha]`
- `fact_pago[id_fecha_pago] -> dim_fecha[id_fecha]`
- `fact_rrhh_mensual[id_fecha_periodo] -> dim_fecha[id_fecha]`
- `fact_abastecimiento_combustible[id_fecha_abastecimiento] -> dim_fecha[id_fecha]`
- `fact_gasto_fijo_mensual[id_fecha_periodo] -> dim_fecha[id_fecha]`
- `fact_mantenimiento_vehiculo[id_fecha_ingreso] -> dim_fecha[id_fecha]`

### Relaciones inactivas recomendadas

#### `fact_orden_servicio`

- `id_fecha_vigencia_orden`
- `id_fecha_primer_envio`
- `id_fecha_ultimo_envio`
- `id_fecha_primer_compromiso_recojo`
- `id_fecha_ultimo_compromiso_recojo`
- `id_fecha_ultimo_cierre_envio`

#### `fact_envio`

- `id_fecha_creacion_orden`
- `id_fecha_vigencia_orden`
- `id_fecha_compromiso_recojo`
- `id_fecha_cierre_envio`

#### `fact_viaje`

- `id_fecha_llegada`

#### `fact_facturacion`

- `id_fecha_vencimiento`

#### `fact_gasto_fijo_mensual`

- `id_fecha_registro`

#### `fact_mantenimiento_vehiculo`

- `id_fecha_salida`

## 3.2 Regla de hora

Usar `dim_hora` solo para paginas donde tenga sentido el analisis horario.

Relaciones recomendadas:

- `fact_tracking_evento[id_hora_evento] -> dim_hora[id_hora]`
- `fact_abastecimiento_combustible[id_hora_abastecimiento] -> dim_hora[id_hora]`

## 3.3 Regla de direccion de filtros

En general:

- relacion `1:*`
- filtro en direccion simple desde dimension hacia hecho

Evitar bidireccional salvo necesidad muy justificada.

## 3.4 Regla para telemetria historica

La telemetria puede empezar despues que el resto de la operacion.

En el modelo actual:

- los viajes sin telemetria quedaran con metricas en `0`
- eso es valido para BI, pero conviene mostrar un texto aclaratorio en paginas de telemetria y flota

Ejemplo de nota visual:

`La telemetria historica puede no estar disponible para todo el periodo filtrado.`

## 4. Filtros compartidos

## 4.1 Filtros globales

Usar sincronizados entre la mayoria de paginas:

- `Fecha`
- `Sucursal`
- `Ruta`

## 4.2 Filtros por dominio

### Comercial y finanzas

- `Cliente`
- `Segmento`
- `Ciudad`

### Logistica y operaciones

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

- `Metodo pago`
- `Estado cobro`

### Solo operativo

- `Hora`

## 4.3 Matriz de sincronizacion

| Grupo | Filtros | Paginas |
|---|---|---|
| `SYNC_GLOBAL` | Fecha, Sucursal, Ruta | casi todas |
| `SYNC_CLIENTE` | Cliente, Segmento, Ciudad | comercial, finanzas, cliente 360 |
| `SYNC_OPERACION` | Vehiculo, Conductor, Estado envio, Tipo tracking, Nivel alerta | logistica, operaciones, 360 de vehiculo y conductor |
| `SYNC_RRHH` | Empleado, Area, Cargo, Estado laboral | RRHH y empleado 360 |
| `LOCAL_HORA` | Hora | paginas operativas |
| `LOCAL_FINANZAS` | Metodo pago, Estado cobro | finanzas |

## 5. Medidas DAX base

## 5.1 Comerciales

```DAX
Cantidad Ordenes =
SUM(fact_orden_servicio[cantidad_ordenes])

Ordenes Aprobadas =
SUM(fact_orden_servicio[orden_aprobada_flag])

Tasa Aprobacion =
DIVIDE([Ordenes Aprobadas], [Cantidad Ordenes], 0)

Cantidad Envios Generados =
SUM(fact_orden_servicio[cantidad_envios])

Conversion Orden a Envio =
DIVIDE([Cantidad Envios Generados], [Cantidad Ordenes], 0)

Ordenes Precio Manual =
SUM(fact_orden_servicio[precio_manual_flag])

Ordenes Vencidas sin Envio =
SUM(fact_orden_servicio[orden_vencida_sin_envio_flag])

Monto Reservado Credito =
SUM(fact_orden_servicio[monto_reservado_bob])

Credito Disponible Snapshot =
SUM(fact_orden_servicio[credito_disponible_bob_snapshot])
```

## 5.2 Envios y servicio

```DAX
Cantidad Envios =
SUM(fact_envio[cantidad_envios])

Envios Cerrados =
SUM(fact_envio[envio_cerrado_flag])

Envios Abiertos =
[Cantidad Envios] - [Envios Cerrados]

SLA Recojo =
DIVIDE(SUM(fact_envio[cumple_sla_recojo_flag]), [Cantidad Envios], 0)

Envios Devueltos =
SUM(fact_envio[devuelto_flag])

Horas Orden a Envio =
AVERAGE(fact_envio[horas_orden_a_envio])

Tiempo Ciclo Horas =
AVERAGE(fact_envio[tiempo_ciclo_horas])

Desviacion SLA Horas =
AVERAGE(fact_envio[desviacion_sla_horas])

Envios Fuera SLA =
CALCULATE(
    [Cantidad Envios],
    FILTER(fact_envio, fact_envio[desviacion_sla_horas] > 0)
)

Peso Movilizado Kg =
SUM(fact_envio[peso_envio_kg])

Volumen Movilizado M3 =
SUM(fact_envio[volumen_envio_m3])
```

## 5.3 Viajes y operacion

```DAX
Cantidad Viajes =
SUM(fact_viaje[cantidad_viajes])

Viajes Finalizados =
SUM(fact_viaje[viaje_finalizado_flag])

Ocupacion Ponderada =
DIVIDE(
    SUM(fact_viaje[peso_total_asignado_kg]),
    SUM(fact_viaje[capacidad_kg]),
    0
)

Peso Total Asignado Kg =
SUM(fact_viaje[peso_total_asignado_kg])

Capacidad Total Kg =
SUM(fact_viaje[capacidad_kg])

Costo Operativo Total =
SUM(fact_viaje[costo_operativo_total_bob])

Costo Operativo sin Combustible =
SUM(fact_viaje[costo_operativo_no_combustible_bob])

Costo por Km =
DIVIDE(
    SUM(fact_viaje[costo_operativo_total_bob]),
    SUM(fact_viaje[distancia_km]),
    0
)

Sobrecapacidad Casos =
SUM(fact_viaje[sobrecapacidad_flag])

Envios Asignados a Viaje =
SUM(fact_viaje[cantidad_envios_asignados])
```

## 5.4 Telemetria

```DAX
Cantidad Eventos =
SUM(fact_tracking_evento[cantidad_eventos])

Eventos Criticos =
SUM(fact_tracking_evento[evento_critico_flag])

Alertas Criticas =
SUM(fact_tracking_evento[alerta_critica_flag])

Gap Promedio Eventos Min =
AVERAGE(fact_tracking_evento[gap_desde_evento_prev_min])

Velocidad Promedio Evento =
AVERAGE(fact_tracking_evento[velocidad_kmh])

Temperatura Promedio Evento =
AVERAGE(fact_tracking_evento[temperatura_motor_c])

Cobertura Telemetria =
AVERAGE(fact_viaje[cobertura_telemetria_pct])

Interrupciones Senal =
SUM(fact_viaje[interrupciones_senal_count])

Alertas Mecanicas =
SUM(fact_viaje[alertas_mecanicas_count])

Temperatura Max Motor =
MAX(fact_viaje[temp_max_motor_c])
```

## 5.5 Facturacion y cobranza

```DAX
Monto Facturado =
SUM(fact_facturacion[total_linea_bob])

Cantidad Facturas =
DISTINCTCOUNT(fact_facturacion[id_factura])

Ticket Promedio Factura =
DIVIDE([Monto Facturado], [Cantidad Facturas], 0)

Monto Cobrado =
SUM(fact_pago[monto_bob])

Cantidad Pagos =
SUM(fact_pago[cantidad_pagos])

Tasa Cobranza =
DIVIDE([Monto Cobrado], [Monto Facturado], 0)

Dias Promedio Cobro =
AVERAGE(fact_pago[dias_cobro_desde_emision])

Pagos Tardios =
SUM(fact_pago[pago_tardio_flag])

Dias Mora Promedio =
AVERAGE(fact_pago[dias_mora_pago])
```

## 5.6 RRHH

```DAX
Empleados Activos =
DISTINCTCOUNT(fact_rrhh_mensual[id_empleado])

Costo Laboral Total =
SUM(fact_rrhh_mensual[liquido_pagable_bob])

Salario Base Total =
SUM(fact_rrhh_mensual[salario_base_bob])

Horas Trabajadas =
SUM(fact_rrhh_mensual[horas_trabajadas])

Horas Extra =
SUM(fact_rrhh_mensual[horas_extra])

Dias Ausencia =
SUM(fact_rrhh_mensual[dias_ausencia])

FTE Total =
SUM(fact_rrhh_mensual[fte_equivalente])

Tasa Ausentismo Ponderada =
DIVIDE(
    SUMX(
        fact_rrhh_mensual,
        fact_rrhh_mensual[tasa_ausentismo_pct] * fact_rrhh_mensual[fte_equivalente]
    ),
    [FTE Total],
    0
)

Costo Laboral por Empleado =
DIVIDE([Costo Laboral Total], [Empleados Activos], 0)
```

## 5.7 Combustible, gasto fijo y mantenimiento

```DAX
Monto Combustible =
SUM(fact_abastecimiento_combustible[monto_combustible_bob])

Litros Combustible =
SUM(fact_abastecimiento_combustible[litros_combustible])

Precio Promedio Litro =
DIVIDE([Monto Combustible], [Litros Combustible], 0)

Monto Gasto Fijo =
SUM(fact_gasto_fijo_mensual[monto_gasto_bob])

Gastos Corporativos =
SUM(fact_gasto_fijo_mensual[gasto_corporativo_flag])

Costo Mantenimiento =
SUM(fact_mantenimiento_vehiculo[costo_total_bob])

Cantidad Mantenimientos =
SUM(fact_mantenimiento_vehiculo[cantidad_mantenimientos])

Mantenimientos Cerrados =
SUM(fact_mantenimiento_vehiculo[mantenimiento_cerrado_flag])

Duracion Mantenimiento Horas =
AVERAGE(fact_mantenimiento_vehiculo[duracion_mantenimiento_horas])
```

## 5.8 Como leer la seccion de graficos

Cuando en cada dashboard se indique un grafico, debes leerlo asi:

- `Visual`: tipo de grafico de Power BI
- `Eje / Categoria`: campo de dimension que va en el eje o categoria
- `Valores`: medidas DAX que van como metrica
- `Filtro visual`: filtro que se aplica solo a ese grafico, por ejemplo `Top 10`
- `De donde sale`: tabla o medida real del modelo

### Regla rapida para saber de donde sale cada dato

- si el campo es descriptivo o de agrupacion como `anio_mes`, `cliente`, `ciudad`, `segmento`, `ruta`, `placa`, normalmente sale de una `dimension`
- si el campo es una metrica como `ordenes`, `envios`, `facturacion`, `costo`, `litros`, `horas`, normalmente sale de una `medida DAX`
- la medida DAX casi siempre resume una `tabla hecho`
- no arrastres campos desde `stg_*`, `int_*` o raw a Power BI

### Regla practica en Power BI

Para cada visual piensa asi:

1. `Que quiero agrupar`
   Eso define la `dimension`
2. `Que quiero medir`
   Eso define la `medida DAX`
3. `Que hecho alimenta esa medida`
   Eso define la tabla de negocio real
4. `Que relacion necesita`
   Normalmente fecha, cliente, sucursal, ruta, vehiculo o empleado

### Mapa rapido de dimensiones mas usadas

| Si quieres mostrar | Sale de |
|---|---|
| anio, mes, anio_mes, fecha | `dim_fecha` |
| hora, franja horaria | `dim_hora` |
| cliente, segmento, ciudad del cliente | `dim_cliente` |
| sucursal, ciudad de sucursal | `dim_sucursal` |
| ruta, codigo_ruta | `dim_ruta` |
| placa, tipo_servicio, capacidad | `dim_vehiculo` |
| conductor | `dim_conductor` |
| factura, nro_factura | `dim_factura` |
| metodo de pago | `dim_metodo_pago` |
| estado de envio | `dim_estado_envio` |
| empleado, area, cargo | `dim_empleado` |
| tipo de tracking | `dim_tipo_tracking_evento` |
| tipo de combustible | `dim_tipo_combustible` |
| categoria de gasto fijo | `dim_categoria_gasto_fijo` |
| tipo de mantenimiento | `dim_tipo_mantenimiento` |

### Mapa rapido de medidas y hechos

| Medida | Sale de la columna | Tabla hecho |
|---|---|---|
| `[Cantidad Ordenes]` | `cantidad_ordenes` | `fact_orden_servicio` |
| `[Cantidad Envios Generados]` | `cantidad_envios` | `fact_orden_servicio` |
| `[Monto Reservado Credito]` | `monto_reservado_bob` | `fact_orden_servicio` |
| `[Cantidad Envios]` | `cantidad_envios` | `fact_envio` |
| `[SLA Recojo]` | `cumple_sla_recojo_flag` | `fact_envio` |
| `[Envios Devueltos]` | `devuelto_flag` | `fact_envio` |
| `[Tiempo Ciclo Horas]` | `tiempo_ciclo_horas` | `fact_envio` |
| `[Peso Movilizado Kg]` | `peso_envio_kg` | `fact_envio` |
| `[Cantidad Viajes]` | `cantidad_viajes` | `fact_viaje` |
| `[Costo Operativo Total]` | `costo_operativo_total_bob` | `fact_viaje` |
| `[Cobertura Telemetria]` | `cobertura_telemetria_pct` | `fact_viaje` |
| `[Cantidad Eventos]` | `cantidad_eventos` | `fact_tracking_evento` |
| `[Alertas Criticas]` | `alerta_critica_flag` | `fact_tracking_evento` |
| `[Monto Facturado]` | `total_linea_bob` | `fact_facturacion` |
| `[Monto Cobrado]` | `monto_bob` | `fact_pago` |
| `[Costo Laboral Total]` | `liquido_pagable_bob` | `fact_rrhh_mensual` |
| `[Litros Combustible]` | `litros_combustible` | `fact_abastecimiento_combustible` |
| `[Monto Combustible]` | `monto_combustible_bob` | `fact_abastecimiento_combustible` |
| `[Monto Gasto Fijo]` | `monto_gasto_bob` | `fact_gasto_fijo_mensual` |
| `[Costo Mantenimiento]` | `costo_total_bob` | `fact_mantenimiento_vehiculo` |

### Ejemplo

Si el documento dice:

- `linea`: ordenes vs envios por `anio_mes`

Se construye asi:

- `Visual`: grafico de lineas
- `Eje / Categoria`: `dim_fecha[anio_mes]`
- `Valores`: `[Cantidad Ordenes]`, `[Cantidad Envios Generados]`
- `Filtro visual`: ninguno
- `De donde sale`:
  - `dim_fecha[anio_mes]`
  - `[Cantidad Ordenes]` usa `SUM(fact_orden_servicio[cantidad_ordenes])`
  - `[Cantidad Envios Generados]` usa `SUM(fact_orden_servicio[cantidad_envios])`
  - relacion necesaria: `fact_orden_servicio[id_fecha_creacion_orden] -> dim_fecha[id_fecha]`

Si el documento dice:

- `barras`: Top `10` clientes por facturacion

Se construye asi:

- `Visual`: barras horizontales
- `Eje / Categoria`: `dim_cliente[nombre_razon_social]`
- `Valores`: `[Monto Facturado]`
- `Filtro visual`: `Top N = 10`
- `De donde sale`:
  - `dim_cliente[nombre_razon_social]`
  - `[Monto Facturado]` usa `SUM(fact_facturacion[total_linea_bob])`
  - relacion necesaria: `fact_facturacion[id_cliente] -> dim_cliente[id_cliente]`

### Ejemplos resueltos del dashboard comercial

#### 1. Linea: ordenes vs envios por anio_mes

| Elemento del visual | Que poner en Power BI | De donde sale |
|---|---|---|
| visual | grafico de lineas | Power BI |
| eje | `dim_fecha[anio_mes]` | `dim_fecha` |
| valor 1 | `[Cantidad Ordenes]` | `fact_orden_servicio[cantidad_ordenes]` |
| valor 2 | `[Cantidad Envios Generados]` | `fact_orden_servicio[cantidad_envios]` |

Relaciones necesarias:

- `fact_orden_servicio[id_fecha_creacion_orden] -> dim_fecha[id_fecha]`

#### 2. Columnas: facturacion por segmento

| Elemento del visual | Que poner en Power BI | De donde sale |
|---|---|---|
| visual | columnas | Power BI |
| eje | `dim_cliente[segmento]` | `dim_cliente` |
| valor | `[Monto Facturado]` | `fact_facturacion[total_linea_bob]` |

Relaciones necesarias:

- `fact_facturacion[id_cliente] -> dim_cliente[id_cliente]`

#### 3. Barras: Top 10 clientes por facturacion

| Elemento del visual | Que poner en Power BI | De donde sale |
|---|---|---|
| visual | barras horizontales | Power BI |
| eje | `dim_cliente[nombre_razon_social]` | `dim_cliente` |
| valor | `[Monto Facturado]` | `fact_facturacion[total_linea_bob]` |
| filtro visual | `Top N = 10` por `[Monto Facturado]` | filtro del visual |

Relaciones necesarias:

- `fact_facturacion[id_cliente] -> dim_cliente[id_cliente]`

#### 4. Tabla: cliente, ciudad, ordenes, envios, facturacion

| Elemento de la tabla | Que poner en Power BI | De donde sale |
|---|---|---|
| columna 1 | `dim_cliente[nombre_razon_social]` | `dim_cliente` |
| columna 2 | `dim_cliente[ciudad]` | `dim_cliente` |
| medida 1 | `[Cantidad Ordenes]` | `fact_orden_servicio[cantidad_ordenes]` |
| medida 2 | `[Cantidad Envios Generados]` | `fact_orden_servicio[cantidad_envios]` |
| medida 3 | `[Monto Facturado]` | `fact_facturacion[total_linea_bob]` |

Relaciones necesarias:

- `fact_orden_servicio[id_cliente] -> dim_cliente[id_cliente]`
- `fact_facturacion[id_cliente] -> dim_cliente[id_cliente]`

Nota importante:

- esta tabla funciona porque `dim_cliente` filtra a las dos tablas hecho
- por eso en una misma tabla puedes mezclar `ordenes` y `facturacion` siempre que ambas queden conectadas con `dim_cliente`

## 6. Medidas DAX con fechas secundarias

Usar `USERELATIONSHIP` cuando quieras analizar por una fecha secundaria.

### Facturacion por vencimiento

```DAX
Monto Facturado por Vencimiento =
CALCULATE(
    [Monto Facturado],
    USERELATIONSHIP(fact_facturacion[id_fecha_vencimiento], dim_fecha[id_fecha])
)
```

### Envios por fecha de cierre

```DAX
Envios por Fecha Cierre =
CALCULATE(
    [Cantidad Envios],
    USERELATIONSHIP(fact_envio[id_fecha_cierre_envio], dim_fecha[id_fecha])
)
```

### Viajes por fecha de llegada

```DAX
Viajes por Fecha Llegada =
CALCULATE(
    [Cantidad Viajes],
    USERELATIONSHIP(fact_viaje[id_fecha_llegada], dim_fecha[id_fecha])
)
```

### Ordenes por vigencia

```DAX
Ordenes por Vigencia =
CALCULATE(
    [Cantidad Ordenes],
    USERELATIONSHIP(fact_orden_servicio[id_fecha_vigencia_orden], dim_fecha[id_fecha])
)
```

## 7. Dashboards por area

## 7.1 Comercial / Ventas

### Dashboard `CV-E1` Panorama Comercial Ejecutivo

**Que muestra**

La salud comercial consolidada: volumen, conversion y clientes mas importantes.

**Hechos**

- `fact_orden_servicio`
- `fact_envio`
- `fact_facturacion`

**Fecha principal**

- `fact_orden_servicio[id_fecha_creacion_orden]`

**Filtros**

- globales: `Fecha`, `Sucursal`, `Ruta`
- compartidos del area: `Cliente`, `Segmento`, `Ciudad`
- locales: ninguno

**KPIs**

- `[Cantidad Ordenes]`
- `[Ordenes Aprobadas]`
- `[Tasa Aprobacion]`
- `[Cantidad Envios Generados]`
- `[Conversion Orden a Envio]`
- `[Monto Facturado]`

**Graficos recomendados**

- `Visual`: linea
  `Eje / Categoria`: `dim_fecha[anio_mes]`
  `Valores`: `[Cantidad Ordenes]`, `[Cantidad Envios Generados]`
- `Visual`: columnas
  `Eje / Categoria`: `dim_cliente[segmento]`
  `Valores`: `[Monto Facturado]`
- `Visual`: barras
  `Eje / Categoria`: `dim_cliente[nombre_razon_social]`
  `Valores`: `[Monto Facturado]`
  `Filtro visual`: `Top N = 10`
- `Visual`: tabla
  `Columnas`: `dim_cliente[nombre_razon_social]`, `dim_cliente[ciudad]`
  `Valores`: `[Cantidad Ordenes]`, `[Cantidad Envios Generados]`, `[Monto Facturado]`

**Que ayuda a decidir**

- si la demanda esta creciendo
- si el pipeline se convierte en servicio real
- que clientes sostienen el ingreso

### Dashboard `CV-T1` Conversion Comercial y Clientes Clave

**Que muestra**

El detalle del pipeline comercial y uso de credito o precio manual.

**Hechos**

- `fact_orden_servicio`

**Fecha principal**

- `id_fecha_creacion_orden`

**Filtros**

- globales: `Fecha`, `Sucursal`, `Ruta`
- compartidos: `Cliente`, `Segmento`, `Ciudad`
- locales: `Estado cliente`

**KPIs**

- `[Ordenes Precio Manual]`
- `[Ordenes Vencidas sin Envio]`
- `[Monto Reservado Credito]`
- `[Credito Disponible Snapshot]`
- `[Cantidad Ordenes]`

**Graficos**

- `Visual`: funnel
  `Etapas`: `[Cantidad Ordenes]`, `[Ordenes Aprobadas]`, `[Cantidad Envios Generados]`
- `Visual`: barras
  `Eje / Categoria`: `dim_cliente[ciudad]`
  `Valores`: `[Cantidad Ordenes]`
- `Visual`: barras
  `Eje / Categoria`: `dim_cliente[nombre_razon_social]`
  `Valores`: `[Monto Reservado Credito]`
  `Filtro visual`: `Top N = 10`
- `Visual`: tabla
  `Columnas`: `fact_orden_servicio[id_orden_servicio]`, `dim_cliente[nombre_razon_social]`
  `Valores`: `[Cantidad Ordenes]`, `[Ordenes Precio Manual]`, `[Monto Reservado Credito]`, `[Credito Disponible Snapshot]`

**Que ayuda a decidir**

- donde se esta perdiendo conversion
- donde el pricing manual se vuelve recurrente
- que clientes consumen mas credito

### Dashboard `CV-O1` Seguimiento Diario de Ordenes y Conversion

**Que muestra**

El movimiento diario del flujo comercial.

**Hechos**

- `fact_orden_servicio`
- `fact_envio`

**Fecha principal**

- `id_fecha_creacion_orden`

**Filtros**

- globales: `Fecha`, `Sucursal`, `Ruta`
- compartidos: `Cliente`, `Segmento`, `Ciudad`
- locales: `Hora` opcional solo si se usa fecha/envio

**KPIs**

- `[Cantidad Ordenes]`
- `[Ordenes Aprobadas]`
- `[Cantidad Envios Generados]`
- `[Conversion Orden a Envio]`

**Graficos**

- `Visual`: linea
  `Eje / Categoria`: `dim_fecha[fecha]`
  `Valores`: `[Cantidad Ordenes]`, `[Cantidad Envios Generados]`
- `Visual`: columnas
  `Eje / Categoria`: `dim_sucursal[ciudad]`
  `Valores`: `[Cantidad Ordenes]`
- `Visual`: tabla
  `Columnas`: `fact_orden_servicio[id_orden_servicio]`, `dim_cliente[nombre_razon_social]`
  `Valores`: `[Cantidad Ordenes]`, `[Cantidad Envios Generados]`, `[Ordenes Vencidas sin Envio]`

## 7.2 Finanzas

### Dashboard `FI-E1` Panorama Financiero Ejecutivo

**Que muestra**

Ingreso, cobranza y presion de costos estructurales.

**Hechos**

- `fact_facturacion`
- `fact_pago`
- `fact_gasto_fijo_mensual`
- `fact_rrhh_mensual`

**Fecha principal**

- `fact_facturacion[id_fecha_emision]`

**Filtros**

- globales: `Fecha`, `Sucursal`, `Ruta`
- compartidos: `Cliente`, `Segmento`, `Ciudad`
- locales: `Metodo pago`, `Estado cobro`

**KPIs**

- `[Monto Facturado]`
- `[Monto Cobrado]`
- `[Tasa Cobranza]`
- `[Monto Gasto Fijo]`
- `[Costo Laboral Total]`
- `[Pagos Tardios]`

**Graficos**

- `Visual`: linea
  `Eje / Categoria`: `dim_fecha[anio_mes]`
  `Valores`: `[Monto Facturado]`, `[Monto Cobrado]`
- `Visual`: columnas agrupadas
  `Eje / Categoria`: `dim_fecha[anio_mes]`
  `Valores`: `[Monto Gasto Fijo]`, `[Costo Laboral Total]`
- `Visual`: barras
  `Eje / Categoria`: `dim_metodo_pago[metodo_pago]`
  `Valores`: `[Monto Cobrado]`
- `Visual`: tabla
  `Columnas`: `dim_cliente[nombre_razon_social]`
  `Valores`: `[Monto Facturado]`, `[Monto Cobrado]`, `[Dias Mora Promedio]`, `[Pagos Tardios]`

### Dashboard `FI-T1` Facturacion, Cartera y Cobranza

**Que muestra**

La eficiencia de cobro y la estructura de la cartera.

**Hechos**

- `fact_facturacion`
- `fact_pago`

**Fecha principal**

- `id_fecha_emision`

**Filtros**

- globales: `Fecha`, `Sucursal`
- compartidos: `Cliente`, `Segmento`, `Ciudad`
- locales: `Metodo pago`, `Estado cobro`

**KPIs**

- `[Cantidad Facturas]`
- `[Ticket Promedio Factura]`
- `[Dias Promedio Cobro]`
- `[Dias Mora Promedio]`
- `[Pagos Tardios]`

**Graficos**

- `Visual`: columnas
  `Eje / Categoria`: `dim_sucursal[ciudad]`
  `Valores`: `[Monto Facturado]`
- `Visual`: barras
  `Eje / Categoria`: `dim_cliente[nombre_razon_social]`
  `Valores`: `[Monto Facturado]`
  `Filtro visual`: `Top N = 10`
- `Visual`: barras
  `Eje / Categoria`: bucket de mora
  `Valores`: `[Cantidad Facturas]`
- `Visual`: tabla
  `Columnas`: `dim_factura[nro_factura]`, `dim_cliente[nombre_razon_social]`, `dim_factura[fecha_vencimiento]`
  `Valores`: `[Monto Facturado]`, `[Monto Cobrado]`, `[Dias Mora Promedio]`

### Dashboard `FI-O1` Seguimiento Diario de Cobranza

**Que muestra**

La ejecucion diaria del cobro.

**Hechos**

- `fact_pago`

**Fecha principal**

- `id_fecha_pago`

**Filtros**

- globales: `Fecha`, `Sucursal`
- compartidos: `Cliente`
- locales: `Metodo pago`

**KPIs**

- `[Cantidad Pagos]`
- `[Monto Cobrado]`
- `[Pagos Tardios]`
- `[Dias Mora Promedio]`

**Graficos**

- `Visual`: linea
  `Eje / Categoria`: `dim_fecha[fecha]`
  `Valores`: `[Monto Cobrado]`
- `Visual`: columnas
  `Eje / Categoria`: `dim_metodo_pago[metodo_pago]`
  `Valores`: `[Monto Cobrado]`
- `Visual`: tabla
  `Columnas`: `fact_pago[id_pago]`, `dim_factura[nro_factura]`, `dim_cliente[nombre_razon_social]`
  `Valores`: `[Monto Cobrado]`, `[Pagos Tardios]`, `[Dias Mora Promedio]`

## 7.3 Logistica / Envios

### Dashboard `LE-E1` Servicio Logistico y Cumplimiento

**Que muestra**

La calidad del servicio entregado al cliente.

**Hechos**

- `fact_envio`

**Fecha principal**

- `id_fecha_registro_envio`

**Filtros**

- globales: `Fecha`, `Sucursal`, `Ruta`
- compartidos: `Cliente`, `Segmento`, `Ciudad`
- locales: `Estado envio`

**KPIs**

- `[Cantidad Envios]`
- `[Envios Cerrados]`
- `[SLA Recojo]`
- `[Envios Devueltos]`
- `[Tiempo Ciclo Horas]`
- `[Peso Movilizado Kg]`

**Graficos**

- `Visual`: linea
  `Eje / Categoria`: `dim_fecha[anio_mes]`
  `Valores`: `[Cantidad Envios]`, `[SLA Recojo]`
- `Visual`: columnas
  `Eje / Categoria`: `dim_sucursal[ciudad]`
  `Valores`: `[SLA Recojo]`
- `Visual`: barras
  `Eje / Categoria`: `dim_ruta[codigo_ruta]`
  `Valores`: `[Desviacion SLA Horas]`
  `Filtro visual`: `Top N = 10`
- `Visual`: tabla
  `Columnas`: `dim_cliente[nombre_razon_social]`
  `Valores`: `[Cantidad Envios]`, `[Envios Devueltos]`, `[SLA Recojo]`

### Dashboard `LE-T1` Desempeno de Rutas y Sucursales

**Que muestra**

Comparacion de nodos operativos.

**Hechos**

- `fact_envio`
- `fact_viaje`

**Fecha principal**

- `fact_envio[id_fecha_registro_envio]`

**Filtros**

- globales: `Fecha`, `Sucursal`, `Ruta`
- compartidos: `Cliente`
- locales: `Estado envio`

**KPIs**

- `[Cantidad Envios]`
- `[SLA Recojo]`
- `[Desviacion SLA Horas]`
- `[Peso Movilizado Kg]`
- `[Cantidad Viajes]`

**Graficos**

- `Visual`: barras
  `Eje / Categoria`: `dim_sucursal[ciudad]`
  `Valores`: `[Cantidad Envios]`
- `Visual`: barras
  `Eje / Categoria`: `dim_ruta[codigo_ruta]`
  `Valores`: `[SLA Recojo]`
- `Visual`: matriz
  `Filas`: `dim_sucursal[ciudad]`
  `Columnas`: `dim_estado_envio[nombre_estado_envio]`
  `Valores`: `[Cantidad Envios]`
- `Visual`: tabla
  `Columnas`: `dim_ruta[codigo_ruta]`, `dim_sucursal[ciudad]`
  `Valores`: `[Cantidad Envios]`, `[SLA Recojo]`, `[Desviacion SLA Horas]`, `[Cantidad Viajes]`

### Dashboard `LE-O1` Monitoreo Diario de Envios y SLA

**Que muestra**

Seguimiento diario con foco en excepciones.

**Hechos**

- `fact_envio`

**Fecha principal**

- `id_fecha_registro_envio`

**Filtros**

- globales: `Fecha`, `Sucursal`, `Ruta`
- compartidos: `Cliente`
- locales: `Hora`, `Estado envio`

**KPIs**

- `[Cantidad Envios]`
- `[Envios Cerrados]`
- `[Envios Abiertos]`
- `[Envios Devueltos]`
- `[Envios Fuera SLA]`

**Graficos**

- `Visual`: linea
  `Eje / Categoria`: `dim_fecha[fecha]`
  `Valores`: `[Cantidad Envios]`, `[Envios Cerrados]`
- `Visual`: columnas
  `Eje / Categoria`: `dim_hora[franja_horaria]`
  `Valores`: `[Cantidad Envios]`
- `Visual`: tabla
  `Columnas`: `fact_envio[id_envio]`, `dim_cliente[nombre_razon_social]`, `dim_ruta[codigo_ruta]`
  `Valores`: `[Desviacion SLA Horas]`, `[Tiempo Ciclo Horas]`
  `Filtro visual`: `solo envios fuera SLA`
- `Visual`: tabla
  `Columnas`: `fact_envio[id_envio]`, `dim_cliente[nombre_razon_social]`, `dim_ruta[codigo_ruta]`
  `Valores`: `[Envios Devueltos]`
  `Filtro visual`: `devuelto_flag = 1`

## 7.4 RRHH

### Dashboard `RH-E1` Capacidad Laboral y Costo Empresarial

**Que muestra**

La dimension humana del negocio a nivel global.

**Hechos**

- `fact_rrhh_mensual`

**Fecha principal**

- `id_fecha_periodo`

**Filtros**

- globales: `Fecha`, `Sucursal`
- compartidos: `Empleado`, `Area`, `Cargo`, `Estado laboral`
- locales: ninguno

**KPIs**

- `[Empleados Activos]`
- `[FTE Total]`
- `[Costo Laboral Total]`
- `[Horas Extra]`
- `[Dias Ausencia]`

**Graficos**

- `Visual`: linea
  `Eje / Categoria`: `dim_fecha[anio_mes]`
  `Valores`: `[Costo Laboral Total]`
- `Visual`: barras
  `Eje / Categoria`: `dim_empleado[area]`
  `Valores`: `[Empleados Activos]`
- `Visual`: columnas
  `Eje / Categoria`: `dim_sucursal[ciudad]`
  `Valores`: `[Costo Laboral Total]`
- `Visual`: tabla
  `Columnas`: `dim_empleado[cargo]`
  `Valores`: `[Empleados Activos]`, `[Costo Laboral Total]`, `[Horas Extra]`, `[Dias Ausencia]`

### Dashboard `RH-T1` Ausentismo, Horas Extra y Estructura

**Que muestra**

Desbalance operativo y presion laboral.

**Hechos**

- `fact_rrhh_mensual`

**Fecha principal**

- `id_fecha_periodo`

**Filtros**

- globales: `Fecha`, `Sucursal`
- compartidos: `Empleado`, `Area`, `Cargo`, `Estado laboral`
- locales: ninguno

**KPIs**

- `[Tasa Ausentismo Ponderada]`
- `[Horas Extra]`
- `[Costo Laboral por Empleado]`
- `[Dias Ausencia]`

**Graficos**

- `Visual`: barras
  `Eje / Categoria`: `dim_empleado[area]`
  `Valores`: `[Tasa Ausentismo Ponderada]`
- `Visual`: columnas
  `Eje / Categoria`: `dim_empleado[cargo]`
  `Valores`: `[Horas Extra]`
- `Visual`: dispersion
  `Categoria`: `dim_sucursal[ciudad]`
  `Eje X`: `[Horas Extra]`
  `Eje Y`: `[Tasa Ausentismo Ponderada]`
- `Visual`: tabla
  `Columnas`: `dim_empleado[nombre_completo]`, `dim_empleado[cargo]`, `dim_empleado[area]`
  `Valores`: `[Costo Laboral Total]`, `[Horas Extra]`, `[Dias Ausencia]`

## 7.5 Operaciones

### Dashboard `OP-E1` Productividad Operativa y Riesgo de Flota

**Que muestra**

El balance entre capacidad, costo y riesgo operativo.

**Hechos**

- `fact_viaje`

**Fecha principal**

- `id_fecha_salida`

**Filtros**

- globales: `Fecha`, `Sucursal`, `Ruta`
- compartidos: `Vehiculo`, `Conductor`
- locales: `Tipo servicio`

**KPIs**

- `[Cantidad Viajes]`
- `[Viajes Finalizados]`
- `[Ocupacion Ponderada]`
- `[Costo Operativo Total]`
- `[Sobrecapacidad Casos]`
- `[Cobertura Telemetria]`

**Graficos**

- `Visual`: linea
  `Eje / Categoria`: `dim_fecha[anio_mes]`
  `Valores`: `[Cantidad Viajes]`, `[Costo Operativo Total]`
- `Visual`: barras
  `Eje / Categoria`: `dim_vehiculo[tipo_servicio]`
  `Valores`: `[Ocupacion Ponderada]`
- `Visual`: barras
  `Eje / Categoria`: `dim_ruta[codigo_ruta]`
  `Valores`: `[Costo por Km]`
  `Filtro visual`: `Top N = 10`
- `Visual`: tabla
  `Columnas`: `dim_vehiculo[placa]`
  `Valores`: `[Cantidad Viajes]`, `[Sobrecapacidad Casos]`, `[Ocupacion Ponderada]`

### Dashboard `OP-T1` Flota, Combustible y Mantenimiento

**Que muestra**

Consumo y costo tecnico de la flota.

**Hechos**

- `fact_abastecimiento_combustible`
- `fact_mantenimiento_vehiculo`
- `fact_viaje`

**Fecha principal**

- `fact_abastecimiento_combustible[id_fecha_abastecimiento]`

**Filtros**

- globales: `Fecha`, `Sucursal`
- compartidos: `Vehiculo`
- locales: `Tipo combustible`, `Tipo mantenimiento`

**KPIs**

- `[Litros Combustible]`
- `[Monto Combustible]`
- `[Precio Promedio Litro]`
- `[Costo Mantenimiento]`
- `[Cantidad Mantenimientos]`

**Graficos**

- `Visual`: linea
  `Eje / Categoria`: `dim_fecha[anio_mes]`
  `Valores`: `[Litros Combustible]`, `[Monto Combustible]`
- `Visual`: barras
  `Eje / Categoria`: `dim_tipo_combustible[tipo_combustible]`
  `Valores`: `[Monto Combustible]`
- `Visual`: barras
  `Eje / Categoria`: `dim_vehiculo[placa]`
  `Valores`: `[Costo Mantenimiento]`
  `Filtro visual`: `Top N = 10`
- `Visual`: tabla
  `Columnas`: `dim_vehiculo[placa]`, `dim_tipo_mantenimiento[tipo_mantenimiento]`
  `Valores`: `[Cantidad Mantenimientos]`, `[Costo Mantenimiento]`, `[Duracion Mantenimiento Horas]`

### Dashboard `OP-O1` Control Diario de Viajes y Telemetria

**Que muestra**

La ejecucion diaria de viajes y alertas.

**Hechos**

- `fact_viaje`
- `fact_tracking_evento`

**Fecha principal**

- `fact_viaje[id_fecha_salida]`

**Filtros**

- globales: `Fecha`, `Sucursal`, `Ruta`
- compartidos: `Vehiculo`, `Conductor`, `Tipo tracking`, `Nivel alerta`
- locales: `Hora`

**KPIs**

- `[Cantidad Viajes]`
- `[Alertas Criticas]`
- `[Interrupciones Senal]`
- `[Velocidad Promedio Evento]`
- `[Temperatura Max Motor]`

**Graficos**

- `Visual`: linea
  `Eje / Categoria`: `dim_fecha[fecha]`
  `Valores`: `[Cantidad Viajes]`
- `Visual`: heatmap o matriz
  `Filas`: `dim_hora[franja_horaria]`
  `Columnas`: `dim_fecha[fecha]`
  `Valores`: `[Cantidad Eventos]`
- `Visual`: barras
  `Eje / Categoria`: `dim_tipo_tracking_evento[tipo_tracking_evento]`
  `Valores`: `[Cantidad Eventos]`
- `Visual`: tabla
  `Columnas`: `dim_fecha[fecha]`, `dim_hora[franja_horaria]`, `dim_vehiculo[placa]`, `dim_conductor[id_conductor]`
  `Valores`: `[Alertas Criticas]`, `[Velocidad Promedio Evento]`, `[Temperatura Promedio Evento]`
  `Filtro visual`: `solo eventos criticos`

## 8. Reportes 360

## 8.1 Cliente 360

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
- pagos tardios
- devoluciones

**Graficos**

- tendencia mensual
- participacion por ruta
- tabla de facturas
- tabla de envios

## 8.2 Factura y Cobranza 360

**Hechos**

- `fact_facturacion`
- `fact_pago`

**KPIs**

- total facturado
- total cobrado
- saldo pendiente
- dias de cobro
- mora

## 8.3 Envio 360

**Hechos**

- `fact_envio`
- `fact_tracking_evento`
- `fact_facturacion`

**KPIs**

- estado envio
- SLA
- tiempo ciclo
- eventos asociados
- monto facturado

## 8.4 Ruta y Sucursal 360

**Hechos**

- `fact_envio`
- `fact_viaje`
- `fact_facturacion`

**KPIs**

- envios
- viajes
- SLA
- costo
- facturacion

## 8.5 Empleado 360

**Hechos**

- `fact_rrhh_mensual`

**KPIs**

- costo laboral
- horas trabajadas
- horas extra
- ausencias
- FTE

## 8.6 Vehiculo 360

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

## 8.7 Conductor 360

**Hechos**

- `fact_viaje`
- `fact_tracking_evento`

**KPIs**

- viajes
- viajes finalizados
- alertas criticas
- velocidad promedio
- ocupacion asociada

## 9. Layout recomendado por pagina

Para mantener dashboards claros:

### Fila 1

- `4 a 6` tarjetas KPI

### Fila 2

- `1` grafico de tendencia
- `1` grafico comparativo

### Fila 3

- `1` ranking Top N
- `1` tabla detalle

### Panel de filtros

- izquierda o superior
- no mezclar mas de `5` slicers visibles por pagina

## 10. Colores por area

Para mantener identidad visual:

- `Comercial / Ventas`: azul oscuro
- `Finanzas`: rojo
- `Logistica / Envios`: amarillo o naranja
- `RRHH`: turquesa
- `Operaciones`: verde

## 11. Recomendaciones finales

- usar nombres de medidas claros y consistentes
- construir primero medidas base y luego medidas derivadas
- no usar visuales complejos si una barra o una linea resuelve mejor el mensaje
- mantener `Fecha`, `Sucursal` y `Ruta` como ejes compartidos del modelo
- reservar las medidas con `USERELATIONSHIP` para paginas que realmente necesiten otra fecha
- en telemetria, mostrar nota aclaratoria si el historial no cubre todo el periodo del negocio

## 12. Ruta del documento

- `c:\Users\Vismark Choque\INTELIGENCIA DE NEGOCIOS\docs\modelos\dwh\GUIA_BI_DETALLADA_DAX_DASHBOARDS_Y_FILTROS.md`
