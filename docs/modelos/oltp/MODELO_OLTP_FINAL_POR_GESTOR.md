# Modelo OLTP Final Por Gestor

## 1. Objetivo

Este documento describe el **modelo OLTP final propuesto** para la empresa de transporte y logistica, organizado por **gestor de base de datos**.

El modelo consolida:

- lo que ya existe y se genera en `simulador_carga_oltp_v4_todo_en_uno`
- los ajustes aprobados al modelo operativo
- la nueva estructura para combustible, alquiler y atributos patrimoniales del vehiculo

La moneda operativa unica del modelo es **BOB**.

---

## 2. Resumen Por Gestor

| Gestor | Base de datos | Rol principal |
|---|---|---|
| MySQL | `gestion_comercial_db` | Maestro comercial, clientes, contratos, tarifarios y ordenes de servicio |
| PostgreSQL | `ops_logistica_db` | Operacion fisica: sucursales, flota, vehiculos, viajes, envios, eventos y combustible |
| SQL Server | `finanzas_rrhh_db` | Credito, facturacion, pagos, mantenimiento, gastos fijos y RRHH |
| MongoDB | `telemetria_gps_db` | Telemetria GPS y alertas operativas |

---

## 3. Reglas Globales Del Modelo

- `orden_servicio` es la **fuente unica del precio**.
- No se crea `envio` sin `orden_servicio` aprobada.
- Si el cliente trabaja a credito, la orden debe tener `reserva_credito` valida.
- Todo monto monetario se registra en **BOB**.
- El combustible se registra en `abastecimiento_combustible`.
- `viaje_gasto_operativo` ya no guarda combustible; solo guarda `PEAJE`, `VIATICO` y `OTRO`.
- Si una sucursal es `PROPIA`, entonces `monto_alquiler_mensual_bob = 0`.
- Si una sucursal es `ALQUILADA`, el gasto real del periodo se registra en `gasto_fijo_mensual` con categoria `ALQUILER`.
- `SERVICIOS_BASICOS` representa el gasto conjunto de luz, agua, internet, telefonia u otros servicios basicos, expresado en `BOB`.
- El estado del vehiculo queda normalizado a `ACTIVO`, `MANTENIMIENTO` o `VENDIDO`.

---

## 4. MySQL - `gestion_comercial_db`

### 4.1. Que Guarda

Este gestor guarda la parte **comercial** del negocio:

- quienes son los actores del negocio
- quienes son clientes
- que contratos tienen
- que tarifas aplican
- cuanto cuesta formalmente un servicio

### 4.2. Tablas

#### `entidad`

**Que guarda**  
Guarda el maestro unico de personas, empresas o instituciones. Evita duplicar datos de clientes, remitentes y destinatarios.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_entidad` | Identificador unico |
| `tipo_entidad` | PERSONA, EMPRESA, INSTITUCION, GUBERNAMENTAL |
| `nombre_o_razon_social` | Nombre de la persona, empresa o institucion |
| `tipo_documento` | CI, NIT, PASAPORTE |
| `numero_documento` | Documento principal |
| `telefono` | Contacto principal |
| `correo` | Correo electronico |
| `ciudad` | Ciudad base |
| `estado` | ACTIVO, INACTIVO |

**Ejemplo**

```text
id_entidad: 1045
tipo_entidad: EMPRESA
nombre_o_razon_social: Transportes Andinos SRL
tipo_documento: NIT
numero_documento: 1029384011
ciudad: La Paz
estado: ACTIVO
```

**Relaciones**

- `entidad` 1:N `cliente`
- `entidad` es referenciada logicamente desde `PostgreSQL.envio` como remitente y destinatario

#### `cliente`

**Que guarda**  
Guarda la version comercial de una entidad que compra servicios de transporte de productos a la empresa.

El nombre del cliente **no se duplica** aqui. Se obtiene desde `entidad.nombre_o_razon_social`, donde puede almacenarse el nombre de la empresa, institucion o persona cliente.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_cliente` | Identificador del cliente |
| `id_entidad` | Referencia a la entidad base |
| `segmento` | INDUSTRIA, DISTRIBUIDOR, IMPORTADOR, MAYORISTA, INSTITUCION, GUBERNAMENTAL, CORPORATIVO |
| `fecha_alta` | Fecha de alta comercial |

**Ejemplo**

```text
id_cliente: 302
id_entidad: 1045
segmento: DISTRIBUIDOR
fecha_alta: 2025-03-10
```

**Relaciones**

- `cliente` N:1 `entidad`
- `cliente` 1:N `contrato_cliente`
- `cliente` 1:N `orden_servicio`

#### `contrato_cliente`

**Que guarda**  
Guarda los acuerdos comerciales formales del cliente.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_contrato` | Identificador del contrato |
| `id_cliente` | Cliente contratante |
| `nro_contrato` | Numero formal del contrato |
| `fecha_inicio` | Inicio de vigencia |
| `fecha_fin` | Fin de vigencia |
| `forma_pago` | CONTADO, CREDITO_30, CREDITO_60 |
| `estado` | VIGENTE, SUSPENDIDO, CERRADO |

**Ejemplo**

```text
id_contrato: 77
nro_contrato: CTR-2025-0012
forma_pago: CREDITO_30
estado: VIGENTE
```

**Relaciones**

- `contrato_cliente` N:1 `cliente`
- `contrato_cliente` 1:N `orden_servicio`

#### `tarifario`

**Que guarda**  
Guarda la cabecera de las politicas de precio.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_tarifario` | Identificador del tarifario |
| `nombre` | Nombre comercial del tarifario |
| `tipo_tarifario` | VENTANILLA, CONTRATO |
| `vigente_desde` | Inicio de vigencia |
| `vigente_hasta` | Fin de vigencia |
| `activo` | Bandera de vigencia operativa |

**Ejemplo**

```text
id_tarifario: 12
nombre: VENTANILLA 2025
tipo_tarifario: VENTANILLA
activo: 1
```

**Relaciones**

- `tarifario` 1:N `tarifario_detalle`

#### `tarifario_detalle`

**Que guarda**  
Guarda la regla exacta de precio por ruta, tipo de carga y rango de peso.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_tarifa_detalle` | Identificador del detalle |
| `id_tarifario` | Cabecera del tarifario |
| `id_sucursal_origen_ref` | Sucursal origen normalizada |
| `id_sucursal_destino_ref` | Sucursal destino normalizada |
| `origen_ciudad` | Texto del origen |
| `destino_ciudad` | Texto del destino |
| `tipo_carga` | GENERAL, FRAGIL, REFRIGERADO, etc. |
| `peso_desde_kg` | Inicio del tramo de peso |
| `peso_hasta_kg` | Fin del tramo de peso |
| `precio_unitario_bob` | Precio definido en BOB |

**Ejemplo**

```text
id_tarifa_detalle: 551
origen_ciudad: La Paz
destino_ciudad: Santa Cruz
tipo_carga: GENERAL
peso_desde_kg: 0
peso_hasta_kg: 50
precio_unitario_bob: 145.50
```

**Relaciones**

- `tarifario_detalle` N:1 `tarifario`
- referencia logica a `PostgreSQL.sucursal`
- `tarifario_detalle` 1:N `orden_servicio`

#### `orden_servicio`

**Que guarda**  
Guarda la orden comercial aprobada y el precio oficial del servicio.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_orden_servicio` | Identificador de la orden |
| `id_cliente` | Cliente solicitante |
| `id_contrato` | Contrato aplicado, si existe |
| `id_tarifa_detalle` | Regla de precio usada |
| `total_bob` | Total final en BOB |
| `id_reserva_credito` | Reserva de credito asociada |
| `estado` | PENDIENTE, APROBADA, RECHAZADA, VENCIDA |
| `fecha_creacion` | Fecha de creacion |
| `vigencia_hasta` | Limite de vigencia del precio |

**Ejemplo**

```text
id_orden_servicio: 18025
id_cliente: 302
id_tarifa_detalle: 551
total_bob: 520.00
id_reserva_credito: 8021
estado: APROBADA
```

**Relaciones**

- `orden_servicio` N:1 `cliente`
- `orden_servicio` N:1 `contrato_cliente`
- `orden_servicio` N:1 `tarifario_detalle`
- `orden_servicio` 1:0..1 `SQLServer.reserva_credito`
- `orden_servicio` 1:N `PostgreSQL.envio`
- `orden_servicio` 1:N `SQLServer.factura_detalle`

---

## 5. PostgreSQL - `ops_logistica_db`

### 5.1. Que Guarda

Este gestor guarda la **ejecucion operativa real**:

- sucursales y estructura operativa
- vehiculos y conductores
- rutas y viajes
- envios y eventos
- tramos de transbordo
- abastecimiento de combustible
- gastos operativos del viaje

### 5.2. Tablas

#### `sucursal`

**Que guarda**  
Guarda las agencias operativas y su condicion de infraestructura.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_sucursal` | Identificador de la sucursal |
| `codigo` | Codigo unico |
| `ciudad` | Ciudad de la sucursal |
| `activa` | Estado operativo |
| `tipo_tenencia_inmueble` | PROPIA, ALQUILADA |
| `monto_alquiler_mensual_bob` | Monto base mensual; en sucursal propia vale `0` |

**Ejemplo**

```text
id_sucursal: 5
codigo: SCZ-CEN
ciudad: Santa Cruz
tipo_tenencia_inmueble: ALQUILADA
monto_alquiler_mensual_bob: 12500.00
```

**Relaciones**

- `sucursal` 1:N `flota`
- `sucursal` 1:N `ruta` como origen
- `sucursal` 1:N `ruta` como destino
- `sucursal` 1:N `envio`
- `sucursal` 1:N `evento_envio`
- `sucursal` 1:N `SQLServer.gasto_fijo_mensual` por referencia logica

#### `flota`

**Que guarda**  
Guarda agrupaciones de vehiculos por tipo de servicio y sucursal base.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_flota` | Identificador de la flota |
| `nombre` | Nombre operativo de la flota |
| `tipo_servicio` | PESADA, EXPRESS, REFRIGERADA |
| `id_sucursal_base` | Sucursal base de la flota |

**Ejemplo**

```text
id_flota: 9
nombre: FLOTA-EXPRESS-LPZ-CEN
tipo_servicio: EXPRESS
id_sucursal_base: 1
```

**Relaciones**

- `flota` N:1 `sucursal`
- `flota` 1:N `vehiculo`

#### `vehiculo`

**Que guarda**  
Guarda el activo vehicular disponible para la operacion.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_vehiculo` | Identificador del vehiculo |
| `id_flota` | Flota a la que pertenece |
| `placa` | Placa unica |
| `capacidad_kg` | Capacidad maxima |
| `fecha_compra` | Fecha de compra |
| `monto_compra_bob` | Monto de compra |
| `estado` | ACTIVO, MANTENIMIENTO, VENDIDO |

**Ejemplo**

```text
id_vehiculo: 145
placa: 2854-KGF
capacidad_kg: 3500.00
fecha_compra: 2023-06-12
monto_compra_bob: 185000.00
estado: ACTIVO
```

**Relaciones**

- `vehiculo` N:1 `flota`
- `vehiculo` 1:N `viaje`
- `vehiculo` 1:N `abastecimiento_combustible`
- `vehiculo` 1:N `SQLServer.mantenimiento_vehiculo` por referencia logica

#### `conductor_operativo`

**Que guarda**  
Guarda la asignacion operativa del conductor, vinculada logicamente con RRHH.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_conductor` | Identificador operativo del conductor |
| `id_empleado_rrhh` | Referencia al empleado de RRHH |
| `id_sucursal_base` | Sucursal base |
| `ci` | Documento snapshot |
| `licencia_nro` | Numero de licencia |
| `estado` | ACTIVO, SUSPENDIDO |

**Ejemplo**

```text
id_conductor: 88
id_empleado_rrhh: 420
id_sucursal_base: 4
licencia_nro: LIC-2024-582331
estado: ACTIVO
```

**Relaciones**

- `conductor_operativo` N:1 `sucursal`
- `conductor_operativo` 1:N `viaje`
- `conductor_operativo` 1:N `viaje_conductor_asignado`
- referencia logica a `SQLServer.empleado`

#### `ruta`

**Que guarda**  
Guarda las rutas definidas entre sucursales.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_ruta` | Identificador de la ruta |
| `codigo_ruta` | Codigo unico |
| `id_origen_sucursal` | Sucursal origen |
| `id_destino_sucursal` | Sucursal destino |
| `distancia_km` | Distancia estimada |

**Ejemplo**

```text
id_ruta: 31
codigo_ruta: R-001-005
origen: LPZ-CEN
destino: SCZ-CEN
distancia_km: 852.40
```

**Relaciones**

- `ruta` N:1 `sucursal` como origen
- `ruta` N:1 `sucursal` como destino
- `ruta` 1:N `viaje`
- `ruta` 1:N `envio`

#### `viaje`

**Que guarda**  
Guarda la ejecucion real de una salida operativa.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_viaje` | Identificador del viaje |
| `id_ruta` | Ruta base |
| `id_vehiculo` | Vehiculo usado |
| `id_conductor` | Conductor principal |
| `fecha_salida_real` | Fecha y hora de salida |
| `fecha_llegada_real` | Fecha y hora de llegada |
| `estado_viaje` | PROGRAMADO, EN_RUTA, FINALIZADO |

**Ejemplo**

```text
id_viaje: 845
id_ruta: 31
id_vehiculo: 145
id_conductor: 88
estado_viaje: FINALIZADO
```

**Relaciones**

- `viaje` N:1 `ruta`
- `viaje` N:1 `vehiculo`
- `viaje` N:1 `conductor_operativo`
- `viaje` 1:N `viaje_conductor_asignado`
- `viaje` 1:1 `viaje_carga_resumen`
- `viaje` 1:N `envio_viaje_tramo`
- `viaje` 1:N `viaje_gasto_operativo`
- `viaje` 1:0..1 `viaje_liquidacion`

#### `viaje_conductor_asignado`

**Que guarda**  
Guarda el detalle de conductor principal y relevos del viaje.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_viaje` | Viaje asociado |
| `id_conductor` | Conductor asignado |
| `rol` | PRINCIPAL, RELEVO |
| `orden_relevo` | Orden de participacion |
| `fecha_asignacion` | Momento de asignacion |

**Ejemplo**

```text
id_viaje: 845
id_conductor: 88
rol: PRINCIPAL
orden_relevo: 1
```

**Relaciones**

- tabla puente entre `viaje` y `conductor_operativo`

#### `viaje_carga_resumen`

**Que guarda**  
Guarda el resumen de ocupacion del viaje.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_viaje` | Viaje asociado |
| `capacidad_kg` | Capacidad del vehiculo |
| `peso_asignado_kg` | Peso total cargado |
| `capacidad_disponible_kg` | Capacidad restante |
| `sobrecapacidad_flag` | Indicador de exceso |

**Ejemplo**

```text
id_viaje: 845
capacidad_kg: 3500.00
peso_asignado_kg: 3100.00
capacidad_disponible_kg: 400.00
sobrecapacidad_flag: false
```

**Relaciones**

- `viaje_carga_resumen` 1:1 `viaje`

#### `envio`

**Que guarda**  
Guarda el envio fisico ya aceptado por la operacion.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_envio` | Identificador del envio |
| `codigo_guia` | Guia unica |
| `id_orden_servicio` | Orden comercial de referencia |
| `id_remitente_entidad` | Remitente |
| `id_destinatario_entidad` | Destinatario |
| `id_sucursal_origen` | Sucursal origen |
| `id_sucursal_destino` | Sucursal destino |
| `id_ruta_referencia` | Ruta principal |
| `fecha_registro` | Inicio de custodia |
| `fecha_compromiso_listo_recojo` | Compromiso SLA |
| `tipo_carga` | Tipo de carga |
| `peso_kg` | Peso del envio |
| `volumen_m3` | Volumen del envio |
| `valor_declarado_bob` | Valor declarado |

**Ejemplo**

```text
id_envio: 22011
codigo_guia: GUIA-20250710-582311
id_orden_servicio: 18025
origen: LPZ-CEN
destino: SCZ-CEN
peso_kg: 42.50
```

**Relaciones**

- referencia logica a `MySQL.orden_servicio`
- referencia logica a `MySQL.entidad`
- `envio` N:1 `sucursal`
- `envio` 1:N `evento_envio`
- `envio` 1:N `envio_viaje_tramo`

#### `evento_envio`

**Que guarda**  
Guarda la trazabilidad cronologica del envio. Tambien define su estado operativo actual segun el ultimo evento registrado.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_evento` | Identificador del evento |
| `id_envio` | Envio afectado |
| `codigo_evento` | RECIBIDO, CLASIFICADO, EN_TRANSITO, EN_SUCURSAL, LISTO_RECOJO, ENTREGADO, DEVUELTO |
| `fecha_hora_evento` | Momento exacto |
| `id_sucursal` | Lugar donde ocurre |
| `id_empleado_rrhh` | Quien registra |
| `observacion` | Nota operativa |

**Ejemplo**

```text
id_evento: 980004
id_envio: 22011
codigo_evento: RECIBIDO
id_sucursal: 1
observacion: Recepcion de envio en ventanilla
```

**Relaciones**

- `evento_envio` N:1 `envio`
- `evento_envio` N:1 `sucursal`
- referencia logica a `SQLServer.empleado`

#### `envio_viaje_tramo`

**Que guarda**  
Guarda el detalle de como un envio se mueve en uno o varios viajes.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_envio_viaje_tramo` | Identificador del tramo |
| `id_envio` | Envio asociado |
| `id_viaje` | Viaje asociado |
| `secuencia_tramo` | Orden del tramo |
| `id_sucursal_carga` | Donde carga |
| `id_sucursal_descarga` | Donde descarga |
| `fecha_hora_carga` | Momento de carga |
| `fecha_hora_descarga` | Momento de descarga |
| `peso_asignado_kg` | Peso de ese tramo |

**Ejemplo**

```text
id_envio: 22011
id_viaje: 845
secuencia_tramo: 1
id_sucursal_carga: 1
id_sucursal_descarga: 4
peso_asignado_kg: 18.20
```

**Relaciones**

- tabla puente entre `envio` y `viaje`
- referencia a `sucursal` como punto de carga y descarga

#### `abastecimiento_combustible`

**Que guarda**  
Guarda la compra de combustible por vehiculo.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_abastecimiento` | Identificador del abastecimiento |
| `id_vehiculo` | Vehiculo abastecido |
| `fecha_hora_abastecimiento` | Fecha y hora |
| `litros` | Litros comprados |
| `monto_pagado_bob` | Importe pagado en BOB |
| `tipo_combustible` | DIESEL, GASOLINA, GNV |

**Ejemplo**

```text
id_abastecimiento: 44021
id_vehiculo: 145
fecha_hora_abastecimiento: 2025-07-10 07:12
litros: 95.400
monto_pagado_bob: 355.20
tipo_combustible: DIESEL
```

**Relaciones**

- `abastecimiento_combustible` N:1 `vehiculo`

#### `viaje_gasto_operativo`

**Que guarda**  
Guarda los gastos operativos complementarios del viaje, excluyendo combustible.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_gasto` | Identificador del gasto |
| `id_viaje` | Viaje asociado |
| `tipo_gasto` | PEAJE, VIATICO, OTRO |
| `monto_bob` | Monto del gasto |
| `fecha_hora_gasto` | Fecha y hora |
| `comprobante_ref` | Referencia del comprobante |

**Ejemplo**

```text
id_gasto: 18852
id_viaje: 845
tipo_gasto: PEAJE
monto_bob: 48.00
comprobante_ref: CP-3AF55C88
```

**Relaciones**

- `viaje_gasto_operativo` N:1 `viaje`

#### `viaje_liquidacion`

**Que guarda**  
Guarda el cierre economico del viaje al finalizar.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_liquidacion` | Identificador de la liquidacion |
| `id_viaje` | Viaje liquidado |
| `adelanto_entregado_bob` | Dinero adelantado |
| `gasto_total_bob` | Total gastado |
| `saldo_a_rendir_bob` | Saldo por devolver o justificar |
| `fecha_liquidacion` | Fecha de cierre |

**Ejemplo**

```text
id_liquidacion: 845
id_viaje: 845
adelanto_entregado_bob: 800.00
gasto_total_bob: 735.00
saldo_a_rendir_bob: 65.00
```

**Relaciones**

- `viaje_liquidacion` 1:1 `viaje`

---

## 6. SQL Server - `finanzas_rrhh_db`

### 6.1. Que Guarda

Este gestor guarda la parte **financiera, crediticia, de costos y RRHH**:

- credito y reservas
- facturacion y cobranza
- costos estructurales
- mantenimiento
- gastos fijos
- empleados, contratos, nomina y asistencia

### 6.2. Tablas

#### `cuenta_credito_cliente`

**Que guarda**  
Guarda la situacion de credito actual del cliente.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_cuenta_credito` | Identificador de la cuenta |
| `id_cliente_comercial` | Cliente relacionado |
| `limite_credito_bob` | Limite de credito |
| `saldo_utilizado_bob` | Monto ya usado |
| `saldo_vencido_bob` | Monto vencido |
| `credito_disponible_bob` | Monto disponible |
| `fecha_corte` | Ultima actualizacion |

**Ejemplo**

```text
id_cuenta_credito: 188
id_cliente_comercial: 302
limite_credito_bob: 50000.00
credito_disponible_bob: 32500.00
```

**Relaciones**

- referencia logica a `MySQL.cliente`
- `cuenta_credito_cliente` 1:N `reserva_credito`

#### `reserva_credito`

**Que guarda**  
Guarda la reserva de credito para una orden a credito.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_reserva_credito` | Identificador de la reserva |
| `id_cuenta_credito` | Cuenta origen |
| `id_cliente_comercial` | Cliente |
| `monto_reservado_bob` | Monto retenido |
| `estado` | RESERVADA, CONSUMIDA, LIBERADA, RECHAZADA |
| `fecha_creacion` | Fecha de creacion |
| `fecha_expira` | Fecha de expiracion |

**Ejemplo**

```text
id_reserva_credito: 8021
monto_reservado_bob: 4200.00
estado: RESERVADA
```

**Relaciones**

- `reserva_credito` N:1 `cuenta_credito_cliente`
- `reserva_credito` 1:0..1 `MySQL.orden_servicio`

#### `factura`

**Que guarda**  
Guarda la cabecera fiscal de la venta.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_factura` | Identificador de la factura |
| `nro_factura` | Numero fiscal |
| `id_cliente_comercial` | Cliente facturado |
| `fecha_emision` | Fecha de emision |
| `fecha_vencimiento` | Fecha limite de pago |
| `total_bob` | Total |
| `estado_cobro` | PENDIENTE, PARCIAL, COBRADO, VENCIDO |

**Ejemplo**

```text
id_factura: 11250
nro_factura: FCT-2025-000001245
total_bob: 920.00
estado_cobro: PENDIENTE
```

**Relaciones**

- referencia logica a `MySQL.cliente`
- `factura` 1:N `factura_detalle`
- `factura` 1:N `pago`

#### `factura_detalle`

**Que guarda**  
Guarda el detalle facturado por envio y por orden de servicio.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_factura_detalle` | Identificador de la linea |
| `id_factura` | Factura padre |
| `id_envio_ops` | Envio cobrado |
| `id_orden_servicio` | Orden comercial de referencia |
| `cantidad` | Cantidad |
| `precio_unitario_bob` | Precio aplicado |
| `total_linea_bob` | Total de la linea |

**Ejemplo**

```text
id_factura_detalle: 50091
id_factura: 11250
id_envio_ops: 22011
total_linea_bob: 460.00
```

**Relaciones**

- `factura_detalle` N:1 `factura`
- referencia logica a `PostgreSQL.envio`
- referencia logica a `MySQL.orden_servicio`

#### `pago`

**Que guarda**  
Guarda los pagos recibidos por factura.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_pago` | Identificador del pago |
| `id_factura` | Factura pagada |
| `monto_bob` | Importe pagado |
| `fecha_pago` | Fecha del pago |
| `metodo_pago` | TRANSFERENCIA, QR, EFECTIVO, CHEQUE |

**Ejemplo**

```text
id_pago: 88220
id_factura: 11250
monto_bob: 460.00
metodo_pago: QR
```

**Relaciones**

- `pago` N:1 `factura`

#### `mantenimiento_vehiculo`

**Que guarda**  
Guarda el mantenimiento realizado a los vehiculos.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_mantenimiento` | Identificador del mantenimiento |
| `id_vehiculo_ops` | Vehiculo afectado |
| `tipo_mantenimiento` | PREVENTIVO, CORRECTIVO, INSPECCION |
| `descripcion` | Descripcion del trabajo |
| `fecha_ingreso` | Entrada a taller |
| `fecha_salida` | Salida de taller |
| `costo_repuestos_bob` | Costo de repuestos |
| `costo_mano_obra_bob` | Costo de mano de obra |
| `costo_total_bob` | Costo total |
| `proveedor` | Taller o proveedor |
| `nro_factura_proveedor` | Comprobante del proveedor |

**Ejemplo**

```text
id_mantenimiento: 971
id_vehiculo_ops: 145
tipo_mantenimiento: CORRECTIVO
costo_total_bob: 2570.00
proveedor: Taller Andino
```

**Relaciones**

- referencia logica a `PostgreSQL.vehiculo`

#### `gasto_fijo_mensual`

**Que guarda**  
Guarda gastos fijos mensuales de sucursal o de la empresa.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_gasto_fijo` | Identificador del gasto |
| `periodo` | Periodo mensual |
| `categoria` | ALQUILER, SERVICIOS_BASICOS, ADMINISTRATIVO, SEGURO, IMPUESTO, OTROS |
| `descripcion` | Descripcion del gasto |
| `id_sucursal_ref` | Sucursal afectada, si aplica |
| `monto_bob` | Monto del gasto |
| `fecha_registro` | Fecha de registro |
| `responsable_ci` | Responsable del registro |

**Ejemplo**

```text
id_gasto_fijo: 2205
periodo: 2025-07-01
categoria: SERVICIOS_BASICOS
id_sucursal_ref: 5
monto_bob: 4250.00
```

**Relaciones**

- referencia logica a `PostgreSQL.sucursal`
- puede ser gasto por sucursal o gasto global corporativo

#### `empleado`

**Que guarda**  
Guarda el maestro del personal.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_empleado` | Identificador del empleado |
| `ci` | Documento de identidad |
| `nombres_apellidos` | Nombre completo |
| `cargo` | Cargo principal |
| `area` | OPERACIONES, COMERCIAL, FINANZAS, RRHH, MANTENIMIENTO, etc. |
| `id_sucursal_ref` | Sucursal base |
| `fecha_ingreso` | Fecha de ingreso |
| `estado_laboral` | ACTIVO, SUSPENDIDO, BAJA |

**Ejemplo**

```text
id_empleado: 420
ci: 6745221
nombres_apellidos: Juan Perez Quispe
cargo: Supervisor Logistico
id_sucursal_ref: 1
estado_laboral: ACTIVO
```

**Relaciones**

- referencia logica a `PostgreSQL.sucursal`
- `empleado` 1:N `contrato_laboral`
- `empleado` 1:N `nomina`
- `empleado` 1:N `asistencia_empleado`
- referenciado logicamente desde `PostgreSQL.conductor_operativo` y `evento_envio`

#### `contrato_laboral`

**Que guarda**  
Guarda la condicion contractual del empleado.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_contrato_laboral` | Identificador del contrato laboral |
| `id_empleado` | Empleado contratado |
| `tipo_contrato` | INDEFINIDO, PLAZO_FIJO, EVENTUAL, CONSULTORIA |
| `salario_base_bob` | Salario base acordado |
| `fecha_inicio` | Fecha de inicio |
| `fecha_fin` | Fecha de fin |
| `estado` | VIGENTE, FINALIZADO, SUSPENDIDO |

**Ejemplo**

```text
id_contrato_laboral: 771
id_empleado: 420
tipo_contrato: INDEFINIDO
salario_base_bob: 5200.00
estado: VIGENTE
```

**Relaciones**

- `contrato_laboral` N:1 `empleado`

#### `nomina`

**Que guarda**  
Guarda el pago mensual del empleado.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_nomina` | Identificador de la nomina |
| `id_empleado` | Empleado pagado |
| `periodo` | Periodo mensual |
| `salario_base_bob` | Salario base |
| `horas_extra_monto_bob` | Pago monetario por horas extra |
| `descuentos_bob` | Descuentos aplicados |
| `liquido_pagable_bob` | Neto a pagar |
| `fecha_pago` | Fecha efectiva de pago |

**Ejemplo**

```text
id_nomina: 19421
id_empleado: 420
periodo: 2025-07-01
liquido_pagable_bob: 5480.00
```

**Relaciones**

- `nomina` N:1 `empleado`

#### `asistencia_empleado`

**Que guarda**  
Guarda el control diario de asistencia y jornada.

**Atributos**

| Atributo | Descripcion |
|---|---|
| `id_asistencia` | Identificador del registro |
| `id_empleado` | Empleado asociado |
| `fecha` | Dia controlado |
| `hora_entrada` | Hora de entrada |
| `hora_salida` | Hora de salida |
| `horas_trabajadas` | Horas efectivas |
| `horas_extra` | Horas extra |
| `tipo_jornada` | NORMAL, EXTRA, GUARDIA, DIA_LIBRE |
| `estado_asistencia` | PRESENTE, AUSENTE, TARDANZA, LICENCIA |
| `observacion` | Detalle del caso |

**Ejemplo**

```text
id_asistencia: 65002
id_empleado: 420
fecha: 2025-07-10
horas_trabajadas: 8.50
horas_extra: 1.00
estado_asistencia: PRESENTE
```

**Relaciones**

- `asistencia_empleado` N:1 `empleado`

---

## 7. MongoDB - `telemetria_gps_db`

### 7.1. Que Guarda

Este gestor guarda datos de alta frecuencia y eventos tecnicos de seguimiento.

### 7.2. Colecciones

#### `gps_track`

**Que guarda**  
Guarda los puntos de telemetria del viaje y del vehiculo.

**Atributos principales**

- `id_vehiculo_ops`
- `id_viaje_ops`
- `id_conductor_ops`
- `ts`
- `lat`
- `lon`
- `vel_kmh`
- `temp_motor_c`
- `combustible_pct`
- `evento`

**Ejemplo**

```json
{
  "id_vehiculo_ops": 145,
  "id_viaje_ops": 845,
  "id_conductor_ops": 88,
  "ts": "2025-07-10T08:15:00Z",
  "lat": -16.51,
  "lon": -68.12,
  "vel_kmh": 67.4,
  "temp_motor_c": 84.2,
  "combustible_pct": 35.8,
  "evento": "TRACK"
}
```

**Relaciones**

- referencia logica a `PostgreSQL.vehiculo`
- referencia logica a `PostgreSQL.viaje`
- referencia logica a `PostgreSQL.conductor_operativo`

#### `gps_alerta`

**Que guarda**  
Guarda alertas operativas o mecanicas derivadas de la telemetria.

**Atributos principales**

- `id_vehiculo_ops`
- `id_viaje_ops`
- `ts_alerta`
- `tipo_alerta`
- `nivel`
- `descripcion`
- `atendida`

**Ejemplo**

```json
{
  "id_vehiculo_ops": 145,
  "id_viaje_ops": 845,
  "ts_alerta": "2025-07-10T09:05:00Z",
  "tipo_alerta": "COMBUSTIBLE_BAJO",
  "nivel": "ALTO",
  "descripcion": "Nivel de combustible bajo",
  "atendida": false
}
```

**Relaciones**

- referencia logica a `PostgreSQL.vehiculo`
- referencia logica a `PostgreSQL.viaje`

---

## 8. Flujo Operativo Resumido

1. Se registra una `entidad`.
2. Esa entidad puede convertirse en `cliente`.
3. El cliente puede firmar un `contrato_cliente`.
4. Se define un `tarifario` y su `tarifario_detalle`.
5. Se crea una `orden_servicio` con precio autorizado.
6. Si el cliente es a credito, se valida `reserva_credito`.
7. Operaciones genera el `envio`.
8. El envio genera trazabilidad en `evento_envio`.
9. El envio puede pasar por uno o varios viajes usando `envio_viaje_tramo`.
10. El `vehiculo` puede registrar `abastecimiento_combustible`.
11. El `viaje` puede registrar `viaje_gasto_operativo` y `viaje_liquidacion`.
12. Finanzas genera `factura`, `factura_detalle` y `pago`.
13. RRHH registra `empleado`, `contrato_laboral`, `nomina` y `asistencia_empleado`.
14. Costos estructurales se registran en `mantenimiento_vehiculo` y `gasto_fijo_mensual`.

---

## 9. Costos Y Egresos Que Quedan Modelados

El modelo final permite registrar:

- combustible por vehiculo en `abastecimiento_combustible`
- peajes, viaticos y otros gastos de viaje en `viaje_gasto_operativo`
- liquidacion total del viaje en `viaje_liquidacion`
- mantenimiento de vehiculos en `mantenimiento_vehiculo`
- alquiler por sucursal alquilada en `gasto_fijo_mensual`
- servicios basicos por sucursal en `gasto_fijo_mensual`
- gastos administrativos, seguros, impuestos y otros en `gasto_fijo_mensual`
- costo laboral en `nomina`

Con esto el OLTP queda preparado para soportar analitica posterior de ingresos, costos operativos, costos laborales y costos estructurales.
