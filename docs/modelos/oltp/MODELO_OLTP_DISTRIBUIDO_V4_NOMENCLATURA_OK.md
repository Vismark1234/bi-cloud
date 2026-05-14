# Modelo OLTP Distribuido v4 (Corregido, Monomoneda BOB) - Transporte y Logistica Bolivia

## Objetivo
Mantener la esencia del diseno distribuido, simplificando el modelo a moneda unica BOB y cierre de entrega por estado/evento (sin auditoria de delivery).

---

## 1) Matriz de observaciones y solucion tecnica

| Observacion critica | Riesgo | Solucion aplicada en v4 |
|---|---|---|
| Precio duplicado entre Operaciones y Finanzas | Descuadres contables | **Fuente unica de precio**: `orden_servicio` (MySQL) calcula/autoriza precio. PostgreSQL solo referencia `id_orden_servicio`. |
| Limite de credito sin control online | Sobreendeudamiento | SQL Server agrega `cuenta_credito_cliente` + `reserva_credito`. Envio solo se crea con `reserva_credito` aprobada. |
| Envio solo admite 1 viaje | Transbordos imposibles | Tabla puente `envio_viaje_tramo` (N:M) con secuencia por tramo. |
| Tarifario por ciudad textual libre | Cruce inestable contra rutas y KPI por ruta | `tarifario_detalle` incorpora `id_sucursal_origen_ref` + `id_sucursal_destino_ref` (FK logicas). |
| Viaje largo con un solo conductor | Operacion incompleta en rutas con relevo | Tabla puente `viaje_conductor_asignado` para PRINCIPAL/RELEVO por viaje. |
| Reserva de credito cross-DB sin contrato de compensacion | Ordenes validas con reserva luego LIBERADA/RECHAZADA | Cardinalidad explicita `reserva_credito` 1:0..1 `orden_servicio` + consistencia por Saga/Event-Driven. |
| Orden sin trazabilidad tarifaria/temporal | Dificultad de auditoria del precio aplicado | `orden_servicio` incorpora `id_tarifa_detalle` y `fecha_creacion`. |
| Tramos con secuencia repetible | Orden de ruta ambiguo por envio | `envio_viaje_tramo` incorpora UQ (`id_envio`,`secuencia_tramo`). |
| Liquidacion duplicable por viaje | Cierre economico inconsistente | `viaje_liquidacion` incorpora UQ en `id_viaje` (1:0..1 real). |
| Entrega sobredocumentada para operacion de recojo | Complejidad innecesaria | Se elimina `entrega_auditoria`; cierre por estado final en `evento_envio`. |
| Moneda variable innecesaria para el negocio actual | Complejidad y costos de mantenimiento | Se elimina multimoneda y se estandariza todo en BOB. |

---

## 2) Distribucion final de motores

## Transaccionales (3)
- **MySQL (`gestion_comercial_db`)**: maestro de entidades/clientes, contratos, tarifarios y orden de servicio.
- **PostgreSQL (`ops_logistica_db`)**: sucursales, flota, rutas, viajes, envios, transbordos y eventos.
- **SQL Server (`finanzas_rrhh_db`)**: credito/cartera, facturacion, pagos, RRHH y costos.

## Complementarios
- **MongoDB (`telemetria_gps_db`)**: GPS y alertas de alta frecuencia.
- **Excel/CSV**: contingencia operativa y cargas manuales controladas.

---

## 3) MySQL - Comercial + Maestro Unico (`gestion_comercial_db`)

## 3.1 Que guarda y por que
- Maestro unico de personas/empresas (evita clonacion).
- Reglas comerciales y precio autorizado antes de operar.
- Montos comerciales en BOB.

## 3.2 Tablas

### `entidad` (maestro unico)
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_entidad | `BIGINT AUTO_INCREMENT` | PK | Identificador unico de persona, empresa o institucion. |
| tipo_entidad | `VARCHAR(15)` |  | PERSONA, EMPRESA, INSTITUCION, GUBERNAMENTAL. |
| nombre_o_razon_social | `VARCHAR(160)` |  | Nombre de la persona, empresa o institucion. |
| tipo_documento | `VARCHAR(10)` |  | CI, NIT, PASAPORTE. |
| numero_documento | `VARCHAR(30)` | UQ | Documento principal. |
| telefono | `VARCHAR(20)` |  | Contacto principal. |
| correo | `VARCHAR(120)` |  | Contacto digital. |
| ciudad | `VARCHAR(60)` |  | Ciudad base. |
| estado | `VARCHAR(20)` |  | ACTIVO, INACTIVO. |

### `cliente`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_cliente | `BIGINT AUTO_INCREMENT` | PK | Cliente comercial. |
| id_entidad | `BIGINT` | FK -> entidad.id_entidad | Vinculo al maestro unico. |
| segmento | `VARCHAR(30)` |  | INDUSTRIA, DISTRIBUIDOR, IMPORTADOR, MAYORISTA, INSTITUCION, GUBERNAMENTAL, CORPORATIVO. |
| fecha_alta | `DATE` |  | Alta comercial. |

### `contrato_cliente`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_contrato | `BIGINT AUTO_INCREMENT` | PK | Contrato B2B. |
| id_cliente | `BIGINT` | FK -> cliente.id_cliente | Cliente contratante. |
| nro_contrato | `VARCHAR(30)` | UQ | Numero formal. |
| fecha_inicio | `DATE` |  | Vigencia desde. |
| fecha_fin | `DATE` |  | Vigencia hasta. |
| forma_pago | `VARCHAR(30)` |  | CONTADO, CREDITO_30, CREDITO_60. |
| estado | `VARCHAR(20)` |  | VIGENTE, SUSPENDIDO, CERRADO. |

### `tarifario`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_tarifario | `BIGINT AUTO_INCREMENT` | PK | Cabecera de tarifas. |
| nombre | `VARCHAR(100)` |  | Nombre comercial. |
| tipo_tarifario | `VARCHAR(20)` |  | VENTANILLA, CONTRATO. |
| vigente_desde | `DATE` |  | Inicio. |
| vigente_hasta | `DATE` |  | Fin. |
| activo | `TINYINT(1)` |  | Activo/inactivo. |

### `tarifario_detalle`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_tarifa_detalle | `BIGINT AUTO_INCREMENT` | PK | Regla de precio por ruta/tramo. |
| id_tarifario | `BIGINT` | FK -> tarifario.id_tarifario | Tarifario padre. |
| id_sucursal_origen_ref | `BIGINT` | FK logica -> PostgreSQL.sucursal.id_sucursal | Origen normalizado para cruce con ruta. |
| id_sucursal_destino_ref | `BIGINT` | FK logica -> PostgreSQL.sucursal.id_sucursal | Destino normalizado para cruce con ruta. |
| origen_ciudad | `VARCHAR(60)` |  | Snapshot textual de origen. |
| destino_ciudad | `VARCHAR(60)` |  | Snapshot textual de destino. |
| tipo_carga | `VARCHAR(20)` |  | GENERAL, FRAGIL, REFRIGERADO, etc. |
| peso_desde_kg | `DECIMAL(10,2)` |  | Tramo desde. |
| peso_hasta_kg | `DECIMAL(10,2)` |  | Tramo hasta. |
| precio_unitario_bob | `DECIMAL(14,4)` |  | Precio en BOB. |

### `orden_servicio` (fuente unica de precio)
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_orden_servicio | `BIGINT AUTO_INCREMENT` | PK | Orden previa al envio. |
| id_cliente | `BIGINT` | FK -> cliente.id_cliente | Cliente solicitante. |
| id_contrato | `BIGINT` | FK -> contrato_cliente.id_contrato, NULL | Contrato aplicado. |
| id_tarifa_detalle | `BIGINT` | FK -> tarifario_detalle.id_tarifa_detalle, NULL | Regla aplicada; NULL solo para precio manual autorizado. |
| total_bob | `DECIMAL(14,4)` |  | Total en BOB. |
| id_reserva_credito | `BIGINT` | FK logica + UQ -> SQLServer.reserva_credito.id_reserva_credito | Reserva aprobada para la orden. |
| estado | `VARCHAR(20)` |  | PENDIENTE, APROBADA, RECHAZADA, VENCIDA. |
| fecha_creacion | `DATETIME` |  | Timestamp de creacion de la orden. |
| vigencia_hasta | `DATETIME` |  | Limite de uso del precio. |

## 3.3 Cardinalidad (MySQL)
- `entidad` 1:N `cliente`
- `cliente` 1:N `contrato_cliente`
- `tarifario` 1:N `tarifario_detalle`
- `sucursal` (PostgreSQL) 1:N `tarifario_detalle` (via `id_sucursal_origen_ref`)
- `sucursal` (PostgreSQL) 1:N `tarifario_detalle` (via `id_sucursal_destino_ref`)
- `tarifario_detalle` 1:N `orden_servicio`
- `cliente` 1:N `orden_servicio`
- `contrato_cliente` 1:N `orden_servicio`

---

## 4) PostgreSQL - Operaciones y Custodia (`ops_logistica_db`)

## 4.1 Que guarda y por que
- Ejecucion fisica de la logistica.
- Soporte de transbordos y relevos de conductor.
- Cierre de envios por estado final de evento (entrega/recojo en ventanilla).

## 4.2 Tablas

### `sucursal`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_sucursal | `bigserial` | PK | Agencia/sucursal operativa. |
| codigo | `varchar(10)` | UQ | Codigo sucursal. |
| ciudad | `varchar(60)` |  | Ciudad. |
| activa | `boolean` |  | Estado operativo. |
| tipo_tenencia_inmueble | `varchar(20)` |  | PROPIA, ALQUILADA. |
| monto_alquiler_mensual_bob | `numeric(14,4)` |  | Monto referencial mensual del alquiler; usar `0` para sucursal PROPIA. |

### `flota`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_flota | `bigserial` | PK | Flota de vehiculos. |
| nombre | `varchar(80)` |  | Nombre. |
| tipo_servicio | `varchar(20)` |  | PESADA, EXPRESS, REFRIGERADA. |
| id_sucursal_base | `bigint` | FK -> sucursal.id_sucursal | Base. |

### `vehiculo`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_vehiculo | `bigserial` | PK | Vehiculo. |
| id_flota | `bigint` | FK -> flota.id_flota | Flota. |
| placa | `varchar(15)` | UQ | Placa oficial. |
| capacidad_kg | `numeric(10,2)` |  | Capacidad maxima. |
| fecha_compra | `date` |  | Fecha de compra del vehiculo. |
| monto_compra_bob | `numeric(14,4)` |  | Monto de compra del vehiculo en BOB. |
| estado | `varchar(20)` |  | ACTIVO, MANTENIMIENTO, VENDIDO. |

### `conductor_operativo`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_conductor | `bigserial` | PK | Conductor operativo. |
| id_empleado_rrhh | `bigint` | FK logica -> SQLServer.empleado.id_empleado | Vinculo RRHH. |
| id_sucursal_base | `bigint` | FK -> sucursal.id_sucursal | Sucursal base operativa del conductor. |
| ci | `varchar(20)` |  | Snapshot de CI. |
| licencia_nro | `varchar(30)` | UQ | Licencia. |
| estado | `varchar(20)` |  | ACTIVO, SUSPENDIDO. |

### `ruta`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_ruta | `bigserial` | PK | Ruta definida. |
| codigo_ruta | `varchar(20)` | UQ | Codigo de ruta. |
| id_origen_sucursal | `bigint` | FK -> sucursal.id_sucursal | Origen. |
| id_destino_sucursal | `bigint` | FK -> sucursal.id_sucursal | Destino. |
| distancia_km | `numeric(8,2)` |  | Distancia. |

### `viaje`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_viaje | `bigserial` | PK | Viaje operativo. |
| id_ruta | `bigint` | FK -> ruta.id_ruta | Ruta base. |
| id_vehiculo | `bigint` | FK -> vehiculo.id_vehiculo | Vehiculo. |
| id_conductor | `bigint` | FK -> conductor_operativo.id_conductor | Conductor principal/responsable. |
| fecha_salida_real | `timestamptz` |  | Salida real. |
| fecha_llegada_real | `timestamptz` |  | Llegada real. |
| estado_viaje | `varchar(20)` |  | PROGRAMADO, EN_RUTA, FINALIZADO. |

### `viaje_conductor_asignado`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_viaje | `bigint` | PK/FK -> viaje.id_viaje | Viaje asignado. |
| id_conductor | `bigint` | PK/FK -> conductor_operativo.id_conductor | Conductor asignado al viaje. |
| rol | `varchar(20)` | UQ parcial por viaje (`rol='PRINCIPAL'`) | PRINCIPAL, RELEVO. |
| orden_relevo | `smallint` |  | Secuencia de participacion (1..N). |
| fecha_asignacion | `timestamptz` |  | Momento de asignacion. |

### `viaje_carga_resumen`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_viaje | `bigint` | PK/FK -> viaje.id_viaje | Viaje. |
| capacidad_kg | `numeric(10,2)` |  | Copia de capacidad vehiculo. |
| peso_asignado_kg | `numeric(10,2)` |  | Peso acumulado asignado. |
| capacidad_disponible_kg | `numeric(10,2)` |  | Capacidad restante. |
| sobrecapacidad_flag | `boolean` |  | Marca de control. |

### `envio`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_envio | `bigserial` | PK | Identificador envio. |
| codigo_guia | `varchar(30)` | UQ | Guia. |
| id_orden_servicio | `bigint` | FK logica -> MySQL.orden_servicio.id_orden_servicio | Precio autorizado y credito validado. |
| id_remitente_entidad | `bigint` | FK logica -> MySQL.entidad.id_entidad | Quien deja el paquete en oficina. |
| id_destinatario_entidad | `bigint` | FK logica -> MySQL.entidad.id_entidad | Destinatario declarado. |
| id_sucursal_origen | `bigint` | FK -> sucursal.id_sucursal | Origen. |
| id_sucursal_destino | `bigint` | FK -> sucursal.id_sucursal | Destino. |
| id_ruta_referencia | `bigint` | FK -> ruta.id_ruta, NULL | Ruta principal analitica del envio para BI (no reemplaza tramos). |
| fecha_registro | `timestamptz` |  | Inicio de custodia. |
| fecha_compromiso_listo_recojo | `timestamptz` |  | SLA para disponibilidad en oficina destino. |
| tipo_carga | `varchar(20)` |  | Tipo de carga. |
| peso_kg | `numeric(10,2)` |  | Peso real. |
| volumen_m3 | `numeric(10,3)` |  | Volumen real. |
| valor_declarado_bob | `numeric(14,4)` |  | Valor declarado en BOB. |

### `evento_envio` (verdad unica de trazabilidad y estado)
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_evento | `bigserial` | PK | Evento cronologico. |
| id_envio | `bigint` | FK -> envio.id_envio | Envio afectado. |
| codigo_evento | `varchar(30)` |  | RECIBIDO, CLASIFICADO, EN_TRANSITO, EN_SUCURSAL, LISTO_RECOJO, ENTREGADO, DEVUELTO. |
| fecha_hora_evento | `timestamptz` |  | Timestamp exacto. |
| id_sucursal | `bigint` | FK -> sucursal.id_sucursal | Lugar del evento. |
| id_empleado_rrhh | `bigint` | FK logica -> SQLServer.empleado.id_empleado | Quien registra. |
| observacion | `varchar(255)` |  | Nota operativa. El estado actual del envio se obtiene del ultimo `codigo_evento` registrado. |

### `envio_viaje_tramo` (habilita transbordos)
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_envio_viaje_tramo | `bigserial` | PK | Registro de tramo. |
| id_envio | `bigint` | FK -> envio.id_envio | Envio. |
| id_viaje | `bigint` | FK -> viaje.id_viaje | Viaje del tramo. |
| secuencia_tramo | `smallint` | UQ compuesta (`id_envio`,`secuencia_tramo`) | Orden 1..N del transbordo. |
| id_sucursal_carga | `bigint` | FK -> sucursal.id_sucursal | Donde sube al viaje. |
| id_sucursal_descarga | `bigint` | FK -> sucursal.id_sucursal | Donde baja. |
| fecha_hora_carga | `timestamptz` |  | Carga fisica. |
| fecha_hora_descarga | `timestamptz` |  | Descarga fisica. |
| peso_asignado_kg | `numeric(10,2)` |  | Peso asignado a ese viaje. |

### `abastecimiento_combustible`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_abastecimiento | `bigserial` | PK | Registro unico de abastecimiento. |
| id_vehiculo | `bigint` | FK -> vehiculo.id_vehiculo | Vehiculo abastecido. |
| fecha_hora_abastecimiento | `timestamptz` |  | Fecha/hora del abastecimiento. |
| litros | `numeric(12,3)` |  | Litros cargados. |
| monto_pagado_bob | `numeric(14,4)` |  | Monto pagado en BOB. |
| tipo_combustible | `varchar(20)` |  | DIESEL, GASOLINA, GNV u otro catalogo definido. |

### `viaje_gasto_operativo`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_gasto | `bigserial` | PK | Gasto registrado. |
| id_viaje | `bigint` | FK -> viaje.id_viaje | Viaje asociado. |
| tipo_gasto | `varchar(20)` |  | PEAJE, VIATICO, OTRO. |
| monto_bob | `numeric(14,4)` |  | Monto del gasto en BOB. |
| fecha_hora_gasto | `timestamptz` |  | Momento del gasto. |
| comprobante_ref | `varchar(80)` |  | Nro recibo/factura. |

### `viaje_liquidacion`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_liquidacion | `bigserial` | PK | Cierre economico de viaje. |
| id_viaje | `bigint` | FK + UQ -> viaje.id_viaje | Viaje cerrado (maximo una liquidacion por viaje). |
| adelanto_entregado_bob | `numeric(14,4)` |  | Dinero entregado al chofer en BOB. |
| gasto_total_bob | `numeric(14,4)` |  | Total gastado en BOB. |
| saldo_a_rendir_bob | `numeric(14,4)` |  | Saldo pendiente/devolucion en BOB. |
| fecha_liquidacion | `timestamptz` |  | Cierre de viaje. |

## 4.3 Cardinalidad (PostgreSQL)
- `sucursal` 1:N `flota`
- `sucursal` 1:N `conductor_operativo`
- `sucursal` 1:N `ruta` (como origen)
- `sucursal` 1:N `ruta` (como destino)
- `sucursal` 1:N `envio` (como origen)
- `sucursal` 1:N `envio` (como destino)
- `flota` 1:N `vehiculo`
- `vehiculo` 1:N `abastecimiento_combustible`
- `ruta` 1:N `viaje`
- `ruta` 1:N `envio` (via `id_ruta_referencia`, nullable)
- `vehiculo` 1:N `viaje`
- `conductor_operativo` 1:N `viaje` (conductor principal)
- `viaje` 1:N `viaje_conductor_asignado`
- `conductor_operativo` 1:N `viaje_conductor_asignado`
- `envio` 1:N `evento_envio`
- `sucursal` 1:N `evento_envio`
- `envio` N:M `viaje` via `envio_viaje_tramo`
- `sucursal` 1:N `envio_viaje_tramo` (como carga)
- `sucursal` 1:N `envio_viaje_tramo` (como descarga)
- `viaje` 1:1 `viaje_carga_resumen`
- `viaje` 1:N `viaje_gasto_operativo`
- `viaje` 1:0..1 `viaje_liquidacion`

---

## 5) SQL Server - Finanzas, Credito y RRHH (`finanzas_rrhh_db`)

## 5.1 Que guarda y por que
- Control contable, cartera y credito en tiempo casi real.
- RRHH para costos de personal y control administrativo.
- Montos financieros y laborales en BOB.

## 5.2 Tablas de credito/cartera

### `cuenta_credito_cliente`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_cuenta_credito | `BIGINT IDENTITY(1,1)` | PK | Cuenta de credito del cliente. |
| id_cliente_comercial | `BIGINT` | FK logica -> MySQL.cliente.id_cliente | Cliente. |
| limite_credito_bob | `DECIMAL(14,4)` |  | Limite vigente en BOB. |
| saldo_utilizado_bob | `DECIMAL(14,4)` |  | Saldo usado en BOB. |
| saldo_vencido_bob | `DECIMAL(14,4)` |  | Cartera vencida en BOB. |
| credito_disponible_bob | `DECIMAL(14,4)` |  | Disponible actual en BOB. |
| fecha_corte | `DATETIME2` |  | Ultima actualizacion. |

### `reserva_credito`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_reserva_credito | `BIGINT IDENTITY(1,1)` | PK | Reserva para una orden. |
| id_cuenta_credito | `BIGINT` | FK -> cuenta_credito_cliente.id_cuenta_credito | Cuenta origen de la reserva. |
| id_cliente_comercial | `BIGINT` | FK logica -> MySQL.cliente.id_cliente | Cliente. |
| monto_reservado_bob | `DECIMAL(14,4)` |  | Monto retenido en BOB. |
| estado | `VARCHAR(20)` |  | RESERVADA, CONSUMIDA, LIBERADA, RECHAZADA. |
| fecha_creacion | `DATETIME2` |  | Creacion. |
| fecha_expira | `DATETIME2` |  | Expiracion. |

## 5.3 Tablas financieras y costos estructurales

### `factura`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_factura | `BIGINT IDENTITY(1,1)` | PK | Cabecera de factura. |
| nro_factura | `VARCHAR(30)` | UQ | Numero fiscal. |
| id_cliente_comercial | `BIGINT` | FK logica -> MySQL.cliente.id_cliente | Cliente. |
| fecha_emision | `DATETIME2` |  | Fecha/hora de emision. |
| fecha_vencimiento | `DATE` |  | Fecha limite de pago para mora/vencimiento. |
| total_bob | `DECIMAL(14,4)` |  | Total en BOB. |
| estado_cobro | `VARCHAR(20)` |  | PENDIENTE, PARCIAL, COBRADO, VENCIDO. |

### `factura_detalle`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_factura_detalle | `BIGINT IDENTITY(1,1)` | PK | Detalle de factura. |
| id_factura | `BIGINT` | FK -> factura.id_factura | Factura padre. |
| id_envio_ops | `BIGINT` | FK logica -> PostgreSQL.envio.id_envio | Envio cobrado. |
| id_orden_servicio | `BIGINT` | FK logica -> MySQL.orden_servicio.id_orden_servicio | Trazabilidad del precio autorizado. |
| cantidad | `DECIMAL(10,2)` |  | Cantidad. |
| precio_unitario_bob | `DECIMAL(14,4)` |  | Precio en BOB. |
| total_linea_bob | `DECIMAL(14,4)` |  | Total linea en BOB. |

### `pago`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_pago | `BIGINT IDENTITY(1,1)` | PK | Cobranza. |
| id_factura | `BIGINT` | FK -> factura.id_factura | Factura pagada. |
| monto_bob | `DECIMAL(14,4)` |  | Monto cobrado en BOB. |
| fecha_pago | `DATETIME2` |  | Fecha/hora. |
| metodo_pago | `VARCHAR(30)` |  | TRANSFERENCIA, QR, EFECTIVO, CHEQUE. |

### `mantenimiento_vehiculo`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_mantenimiento | `BIGINT IDENTITY(1,1)` | PK | Registro unico de mantenimiento. |
| id_vehiculo_ops | `BIGINT` | FK logica -> PostgreSQL.vehiculo.id_vehiculo | Vehiculo afectado. |
| tipo_mantenimiento | `VARCHAR(30)` |  | PREVENTIVO, CORRECTIVO, INSPECCION. |
| descripcion | `VARCHAR(255)` |  | Detalle del trabajo realizado. |
| fecha_ingreso | `DATETIME2` |  | Ingreso a taller. |
| fecha_salida | `DATETIME2` |  | Salida de taller. |
| costo_repuestos_bob | `DECIMAL(14,4)` |  | Costo de piezas en BOB. |
| costo_mano_obra_bob | `DECIMAL(14,4)` |  | Costo de mano de obra en BOB. |
| costo_total_bob | `DECIMAL(14,4)` |  | Total en BOB. |
| proveedor | `VARCHAR(120)` |  | Taller/proveedor. |
| nro_factura_proveedor | `VARCHAR(40)` |  | Comprobante de respaldo. |

### `gasto_fijo_mensual`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_gasto_fijo | `BIGINT IDENTITY(1,1)` | PK | Registro unico de gasto fijo. |
| periodo | `DATE` |  | Periodo mensual normalizado al primer dia del mes. |
| categoria | `VARCHAR(40)` |  | ALQUILER, SERVICIOS_BASICOS, ADMINISTRATIVO, SEGURO, IMPUESTO, OTROS. |
| descripcion | `VARCHAR(255)` |  | Detalle del gasto. |
| id_sucursal_ref | `BIGINT` | FK logica -> PostgreSQL.sucursal.id_sucursal, NULL | Sucursal afectada o gasto global empresa. |
| monto_bob | `DECIMAL(14,4)` |  | Monto en BOB. |
| fecha_registro | `DATETIME2` |  | Fecha/hora de registro en sistema. |
| responsable_ci | `VARCHAR(20)` |  | Identificador del responsable de carga. |

## 5.4 Tablas RRHH (expandido)

### `empleado`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_empleado | `BIGINT IDENTITY(1,1)` | PK | Identificador de empleado. |
| ci | `VARCHAR(20)` | UQ | Documento de identidad. |
| nombres_apellidos | `VARCHAR(160)` |  | Nombre completo. |
| cargo | `VARCHAR(80)` |  | Cargo principal. |
| area | `VARCHAR(40)` |  | OPERACIONES, COMERCIAL, FINANZAS, RRHH, MANTENIMIENTO, etc. |
| id_sucursal_ref | `BIGINT` | FK logica -> PostgreSQL.sucursal.id_sucursal | Sucursal base de trabajo. |
| fecha_ingreso | `DATE` |  | Fecha de ingreso laboral. |
| estado_laboral | `VARCHAR(20)` |  | ACTIVO, SUSPENDIDO, BAJA. |

### `contrato_laboral`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_contrato_laboral | `BIGINT IDENTITY(1,1)` | PK | Contrato laboral. |
| id_empleado | `BIGINT` | FK -> empleado.id_empleado | Empleado contratado. |
| tipo_contrato | `VARCHAR(30)` |  | INDEFINIDO, PLAZO_FIJO, EVENTUAL, CONSULTORIA. |
| salario_base_bob | `DECIMAL(14,4)` |  | Salario base acordado en BOB. |
| fecha_inicio | `DATE` |  | Inicio de vigencia. |
| fecha_fin | `DATE` |  | Fin de vigencia, NULL si indefinido. |
| estado | `VARCHAR(20)` |  | VIGENTE, FINALIZADO, SUSPENDIDO. |

### `nomina`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_nomina | `BIGINT IDENTITY(1,1)` | PK | Registro de pago de nomina. |
| id_empleado | `BIGINT` | FK -> empleado.id_empleado | Empleado pagado (UQ compuesta con `periodo`). |
| periodo | `DATE` | UQ compuesta (`id_empleado`,`periodo`) | Periodo mensual normalizado al primer dia del mes. |
| salario_base_bob | `DECIMAL(14,4)` |  | Base salarial en BOB. |
| horas_extra_monto_bob | `DECIMAL(14,4)` |  | Total monetario de horas extra en BOB. |
| descuentos_bob | `DECIMAL(14,4)` |  | Descuentos en BOB. |
| liquido_pagable_bob | `DECIMAL(14,4)` |  | Neto a pagar en BOB. |
| fecha_pago | `DATETIME2` |  | Fecha efectiva de pago. |

### `asistencia_empleado`
| Campo | Tipo | Clave | Descripcion |
|---|---|---|---|
| id_asistencia | `BIGINT IDENTITY(1,1)` | PK | Registro diario de asistencia. |
| id_empleado | `BIGINT` | FK -> empleado.id_empleado | Empleado asociado. |
| fecha | `DATE` | UQ compuesta (`id_empleado`,`fecha`) | Dia de control. |
| hora_entrada | `TIME` |  | Marcacion de entrada. |
| hora_salida | `TIME` |  | Marcacion de salida. |
| horas_trabajadas | `DECIMAL(5,2)` |  | Horas trabajadas del dia. |
| horas_extra | `DECIMAL(5,2)` |  | Horas fuera de jornada base. |
| tipo_jornada | `VARCHAR(20)` |  | NORMAL, EXTRA, GUARDIA, DIA_LIBRE. |
| estado_asistencia | `VARCHAR(20)` |  | PRESENTE, AUSENTE, TARDANZA, LICENCIA. |
| observacion | `VARCHAR(200)` |  | Justificacion u observaciones. |

## 5.5 Cardinalidad (SQL Server)
- `cuenta_credito_cliente` 1:N `reserva_credito`
- `reserva_credito` 1:0..1 `orden_servicio` (FK logica via `orden_servicio.id_reserva_credito`)
- `factura` 1:N `factura_detalle`
- `factura` 1:N `pago`
- `orden_servicio` 1:1..N `factura_detalle` (segun politica de facturacion)
- `sucursal` (PostgreSQL) 1:N `empleado` (FK logica)
- `empleado` 1:N `contrato_laboral`
- `empleado` 1:N `nomina`
- `empleado` 1:N `asistencia_empleado`
- `vehiculo` (PostgreSQL) 1:N `mantenimiento_vehiculo` (FK logica)
- `sucursal` (PostgreSQL) 1:N `gasto_fijo_mensual` (FK logica; NULL permitido para gasto global)

---

## 6) MongoDB - Telemetria (`telemetria_gps_db`)

### `gps_track`
```json
{
  "_id": "ObjectId",
  "id_vehiculo_ops": "Long",
  "id_viaje_ops": "Long",
  "id_conductor_ops": "Long",
  "ts": "Date",
  "lat": "Double",
  "lon": "Double",
  "vel_kmh": "Double",
  "temp_motor_c": "Double",
  "combustible_pct": "Double",
  "evento": "String"
}
```

### `gps_alerta`
```json
{
  "_id": "ObjectId",
  "id_vehiculo_ops": "Long (opcional)",
  "id_viaje_ops": "Long",
  "ts_alerta": "Date",
  "tipo_alerta": "String",
  "nivel": "String",
  "descripcion": "String",
  "atendida": "Boolean"
}
```

Cardinalidad logica:
- `viaje` (PostgreSQL) 1:N `gps_track`
- `vehiculo` (PostgreSQL) 1:N `gps_alerta` (opcional, para alertas fuera de viaje)
- `viaje` (PostgreSQL) 1:N `gps_alerta`

---

## 7) Excel/CSV - Contingencia controlada

### `recojos_contingencia.xlsx`
- Campos: `codigo_guia`, `receptor_ci`, `fecha_hora_recojo`, `validador_ci`, `motivo`.
- Uso: solo contingencia; luego se reconcilia contra `evento_envio` con estado final de recojo/entrega en ventanilla.

### `incidencias_operativas.xlsx`
- Campos: `fecha_hora`, `codigo_guia`, `tipo_incidencia`, `descripcion`, `responsable_ci`.
- Uso: captura manual cuando no hay conectividad.

### `clientes_eventuales.csv`
- Campos: `tipo_documento`, `numero_documento`, `nombre_o_razon_social`, `telefono`, `ciudad`.
- Uso: alta rapida, luego homologacion obligatoria a `MySQL.entidad`.

---

## 8) Reglas operativas clave (cross-DB)
1. **No se crea `envio` sin `orden_servicio` APROBADA**.
2. **No se aprueba `orden_servicio` sin `reserva_credito` valida** para clientes a credito.
3. **Consistencia `reserva_credito` <-> `orden_servicio` se gobierna por Saga/Event-Driven**.
4. **Tarifario operativo cruza por sucursal (`id_sucursal_origen_ref`, `id_sucursal_destino_ref`)**.
5. **Estado actual se deriva del ultimo `evento_envio`** (no duplicar estado en `envio`).
6. **Asignacion a viaje pasa por `envio_viaje_tramo`** y valida capacidad de `viaje_carga_resumen`.
7. **Viajes de larga distancia pueden asignar multiples conductores** via `viaje_conductor_asignado`.
8. **Cada `viaje` debe tener exactamente un conductor `PRINCIPAL`**.
9. **`viaje.id_conductor` es la referencia autoritativa**; el `PRINCIPAL` debe coincidir.
10. **Facturacion solo usa `orden_servicio` como referencia de precio**.
11. **Facturas deben registrar `fecha_emision` y `fecha_vencimiento`**.
12. **Todos los montos monetarios se registran en BOB** (moneda unica operativa).
13. **No duplicar gastos entre `abastecimiento_combustible`, `viaje_gasto_operativo` y `gasto_fijo_mensual`**.
14. **`asistencia_empleado` mantiene unicidad por (`id_empleado`,`fecha`)**.
15. **Cierre mensual financiero fija periodo de corte usando `factura.fecha_emision`, nomina, mantenimiento y gastos fijos**.
16. **`nomina` mantiene unicidad por (`id_empleado`,`periodo`)**.
17. **`credito_disponible_bob` se actualiza en la misma transaccion de reservas/liberaciones/consumos**.
18. **`envio_viaje_tramo` mantiene unicidad por (`id_envio`,`secuencia_tramo`)**.
19. **`viaje_liquidacion` mantiene unicidad por `id_viaje`**.
20. **`orden_servicio` registra `fecha_creacion` e `id_tarifa_detalle` (o excepcion manual autorizada)**.
21. **No existe `entrega_auditoria`: el cierre es por estado final en `evento_envio` (`ENTREGADO` o equivalente)**.
22. **Si `sucursal.tipo_tenencia_inmueble = 'PROPIA'`, entonces `sucursal.monto_alquiler_mensual_bob = 0`**.
23. **Si `sucursal.tipo_tenencia_inmueble = 'ALQUILADA'`, el gasto real mensual de alquiler se registra en `gasto_fijo_mensual` con categoria `ALQUILER`**.
24. **El combustible se registra en `abastecimiento_combustible`; no debe repetirse como `COMBUSTIBLE` en `viaje_gasto_operativo`**.

---

## 9) Resultado
Este v4 conserva la esencia del modelo distribuido y simplifica la operacion financiera:
- evita descuadres de precio,
- soporta transbordos reales,
- controla credito,
- estandariza moneda unica BOB,
- evita duplicacion de personas,
- incorpora abastecimiento de combustible por vehiculo,
- incorpora costos de mantenimiento y gastos fijos,
- incorpora control de asistencia y costo laboral real,
- elimina complejidad de delivery y cierre por auditoria.

Formula objetivo de ganancia neta mensual:
```text
GANANCIA NETA =
  SUM(factura.total_bob)
  - SUM(abastecimiento_combustible.monto_pagado_bob)
  - SUM(viaje_gasto_operativo.monto_bob)
  - SUM(mantenimiento_vehiculo.costo_total_bob)
  - SUM(nomina.liquido_pagable_bob)
  - SUM(gasto_fijo_mensual.monto_bob)
```

Nota sobre adelantos:
- Si `adelanto_entregado_bob` se descuenta dentro de `nomina.liquido_pagable_bob`, no sumar adelanto aparte.
- Si el adelanto se registra fuera de nomina, restar adicionalmente `SUM(viaje_liquidacion.adelanto_entregado_bob)`.
