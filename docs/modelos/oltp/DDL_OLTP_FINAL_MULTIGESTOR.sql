/*
===============================================================================
DDL OLTP FINAL MULTIGESTOR
===============================================================================

Archivo unico con el DDL del modelo OLTP final para:
1. MySQL        -> gestion_comercial_db
2. PostgreSQL   -> ops_logistica_db
3. SQL Server   -> finanzas_rrhh_db
4. MongoDB      -> telemetria_gps_db (incluido como bloque comentado para mongosh)

IMPORTANTE
- No ejecutar el archivo completo en un solo motor.
- Ejecutar unicamente la seccion correspondiente a cada gestor.
- Las relaciones entre motores distintos son FK logicas; no se declaran como FK fisicas.
- Las llaves de integracion para futuro DWH usan BIGINT de forma consistente.
- Moneda unica del modelo: BOB.
- El estado del envio se obtiene del ultimo registro en evento_envio.
- Este DDL refleja el modelo final y puede requerir ajustes en simuladores o ETL legacy.

CONVENCIONES COMUNES
- IDs: BIGINT
- Montos monetarios: DECIMAL/NUMERIC(14,4)
- Fechas de periodo mensual: primer dia del mes
- Se prioriza integridad de datos y claridad para futura integracion analitica
===============================================================================
*/

/* ============================================================================
   1) MYSQL - gestion_comercial_db
   Ejecutar solo esta seccion en MySQL 8+
============================================================================ */

CREATE DATABASE IF NOT EXISTS gestion_comercial_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE gestion_comercial_db;

CREATE TABLE IF NOT EXISTS entidad (
    id_entidad BIGINT NOT NULL AUTO_INCREMENT,
    tipo_entidad VARCHAR(20) NOT NULL,
    nombre_o_razon_social VARCHAR(160) NOT NULL,
    tipo_documento VARCHAR(20) NOT NULL,
    numero_documento VARCHAR(40) NULL,
    telefono VARCHAR(30) NULL,
    correo VARCHAR(120) NULL,
    ciudad VARCHAR(80) NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
    PRIMARY KEY (id_entidad),
    CONSTRAINT uq_entidad_documento UNIQUE (tipo_documento, numero_documento),
    CONSTRAINT ck_entidad_tipo_entidad CHECK (tipo_entidad IN ('PERSONA', 'EMPRESA', 'INSTITUCION', 'GUBERNAMENTAL')),
    CONSTRAINT ck_entidad_tipo_documento CHECK (tipo_documento IN ('CI', 'NIT', 'PASAPORTE', 'OTRO')),
    CONSTRAINT ck_entidad_estado CHECK (estado IN ('ACTIVO', 'INACTIVO'))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cliente (
    id_cliente BIGINT NOT NULL AUTO_INCREMENT,
    id_entidad BIGINT NOT NULL,
    segmento VARCHAR(30) NOT NULL,
    fecha_alta DATE NOT NULL,
    PRIMARY KEY (id_cliente),
    CONSTRAINT uq_cliente_entidad UNIQUE (id_entidad),
    CONSTRAINT fk_cliente_entidad FOREIGN KEY (id_entidad) REFERENCES entidad (id_entidad),
    CONSTRAINT ck_cliente_segmento CHECK (
        segmento IN (
            'PERSONA NATURAL',
            'PYME',
            'CORPORATIVO',
            'INDUSTRIA',
            'DISTRIBUIDOR',
            'IMPORTADOR',
            'MAYORISTA',
            'INSTITUCION',
            'GUBERNAMENTAL'
        )
    )
) ENGINE=InnoDB;

CREATE INDEX idx_cliente_fecha_alta ON cliente (fecha_alta);

CREATE TABLE IF NOT EXISTS contrato_cliente (
    id_contrato BIGINT NOT NULL AUTO_INCREMENT,
    id_cliente BIGINT NOT NULL,
    nro_contrato VARCHAR(40) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    forma_pago VARCHAR(20) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_contrato),
    CONSTRAINT uq_contrato_cliente_nro UNIQUE (nro_contrato),
    CONSTRAINT fk_contrato_cliente_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
    CONSTRAINT ck_contrato_cliente_forma_pago CHECK (forma_pago IN ('CONTADO', 'CREDITO_15', 'CREDITO_30', 'CREDITO_45', 'CREDITO_60')),
    CONSTRAINT ck_contrato_cliente_estado CHECK (estado IN ('VIGENTE', 'SUSPENDIDO', 'CERRADO', 'FINALIZADO')),
    CONSTRAINT ck_contrato_cliente_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
) ENGINE=InnoDB;

CREATE INDEX idx_contrato_cliente_cliente_estado ON contrato_cliente (id_cliente, estado);
CREATE INDEX idx_contrato_cliente_fechas ON contrato_cliente (fecha_inicio, fecha_fin);

CREATE TABLE IF NOT EXISTS tarifario (
    id_tarifario BIGINT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    tipo_tarifario VARCHAR(20) NOT NULL,
    vigente_desde DATE NOT NULL,
    vigente_hasta DATE NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id_tarifario),
    CONSTRAINT uq_tarifario_nombre_desde UNIQUE (nombre, vigente_desde),
    CONSTRAINT ck_tarifario_tipo CHECK (tipo_tarifario IN ('VENTANILLA', 'CONTRATO', 'PROMOCIONAL')),
    CONSTRAINT ck_tarifario_fechas CHECK (vigente_hasta IS NULL OR vigente_hasta >= vigente_desde)
) ENGINE=InnoDB;

CREATE INDEX idx_tarifario_vigencia ON tarifario (vigente_desde, vigente_hasta, activo);

CREATE TABLE IF NOT EXISTS tarifario_detalle (
    id_tarifa_detalle BIGINT NOT NULL AUTO_INCREMENT,
    id_tarifario BIGINT NOT NULL,
    id_sucursal_origen_ref BIGINT NOT NULL,
    id_sucursal_destino_ref BIGINT NOT NULL,
    origen_ciudad VARCHAR(80) NOT NULL,
    destino_ciudad VARCHAR(80) NOT NULL,
    tipo_carga VARCHAR(20) NOT NULL,
    peso_desde_kg DECIMAL(10,2) NOT NULL,
    peso_hasta_kg DECIMAL(10,2) NOT NULL,
    precio_unitario_bob DECIMAL(14,4) NOT NULL,
    PRIMARY KEY (id_tarifa_detalle),
    CONSTRAINT fk_tarifario_detalle_tarifario FOREIGN KEY (id_tarifario) REFERENCES tarifario (id_tarifario),
    CONSTRAINT uq_tarifario_detalle_regla UNIQUE (
        id_tarifario,
        id_sucursal_origen_ref,
        id_sucursal_destino_ref,
        tipo_carga,
        peso_desde_kg,
        peso_hasta_kg
    ),
    CONSTRAINT ck_tarifario_detalle_ciudades CHECK (origen_ciudad <> destino_ciudad),
    CONSTRAINT ck_tarifario_detalle_sucursales CHECK (id_sucursal_origen_ref <> id_sucursal_destino_ref),
    CONSTRAINT ck_tarifario_detalle_tipo_carga CHECK (tipo_carga IN ('GENERAL', 'FRAGIL', 'REFRIGERADO', 'PERECEDERO', 'PELIGROSO')),
    CONSTRAINT ck_tarifario_detalle_pesos CHECK (peso_desde_kg >= 0 AND peso_hasta_kg > peso_desde_kg),
    CONSTRAINT ck_tarifario_detalle_precio CHECK (precio_unitario_bob > 0)
) ENGINE=InnoDB;

CREATE INDEX idx_tarifario_detalle_corredor ON tarifario_detalle (id_sucursal_origen_ref, id_sucursal_destino_ref, tipo_carga);

CREATE TABLE IF NOT EXISTS orden_servicio (
    id_orden_servicio BIGINT NOT NULL AUTO_INCREMENT,
    id_cliente BIGINT NOT NULL,
    id_contrato BIGINT NULL,
    id_tarifa_detalle BIGINT NULL,
    total_bob DECIMAL(14,4) NOT NULL,
    id_reserva_credito BIGINT NULL,
    estado VARCHAR(20) NOT NULL,
    fecha_creacion DATETIME NOT NULL,
    vigencia_hasta DATETIME NOT NULL,
    PRIMARY KEY (id_orden_servicio),
    CONSTRAINT uq_orden_servicio_reserva UNIQUE (id_reserva_credito),
    CONSTRAINT fk_orden_servicio_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
    CONSTRAINT fk_orden_servicio_contrato FOREIGN KEY (id_contrato) REFERENCES contrato_cliente (id_contrato),
    CONSTRAINT fk_orden_servicio_tarifa FOREIGN KEY (id_tarifa_detalle) REFERENCES tarifario_detalle (id_tarifa_detalle),
    CONSTRAINT ck_orden_servicio_total CHECK (total_bob > 0),
    CONSTRAINT ck_orden_servicio_estado CHECK (estado IN ('PENDIENTE', 'APROBADA', 'RECHAZADA', 'VENCIDA', 'CANCELADA')),
    CONSTRAINT ck_orden_servicio_vigencia CHECK (vigencia_hasta >= fecha_creacion)
) ENGINE=InnoDB;

CREATE INDEX idx_orden_servicio_cliente_fecha ON orden_servicio (id_cliente, fecha_creacion);
CREATE INDEX idx_orden_servicio_estado_fecha ON orden_servicio (estado, fecha_creacion);
CREATE INDEX idx_orden_servicio_contrato ON orden_servicio (id_contrato);


/* ============================================================================
   2) POSTGRESQL - ops_logistica_db
   Ejecutar solo esta seccion en psql
============================================================================ */

SELECT 'CREATE DATABASE ops_logistica_db WITH ENCODING ''UTF8'' TEMPLATE template0'
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_database
    WHERE datname = 'ops_logistica_db'
)\gexec

\connect ops_logistica_db

SET search_path TO public;

CREATE TABLE IF NOT EXISTS sucursal (
    id_sucursal BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    ciudad VARCHAR(80) NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    tipo_tenencia_inmueble VARCHAR(20) NOT NULL,
    monto_alquiler_mensual_bob NUMERIC(14,4) NOT NULL DEFAULT 0,
    CONSTRAINT ck_sucursal_tenencia CHECK (tipo_tenencia_inmueble IN ('PROPIA', 'ALQUILADA')),
    CONSTRAINT ck_sucursal_alquiler CHECK (
        (tipo_tenencia_inmueble = 'PROPIA' AND monto_alquiler_mensual_bob = 0)
        OR
        (tipo_tenencia_inmueble = 'ALQUILADA' AND monto_alquiler_mensual_bob > 0)
    )
);

CREATE INDEX IF NOT EXISTS idx_sucursal_ciudad ON sucursal (ciudad);

CREATE TABLE IF NOT EXISTS flota (
    id_flota BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE,
    tipo_servicio VARCHAR(30) NOT NULL,
    id_sucursal_base BIGINT NOT NULL REFERENCES sucursal (id_sucursal),
    CONSTRAINT ck_flota_tipo_servicio CHECK (tipo_servicio IN ('EXPRESS', 'PESADA', 'REFRIGERADA', 'MIXTA'))
);

CREATE INDEX IF NOT EXISTS idx_flota_sucursal_base ON flota (id_sucursal_base);

CREATE TABLE IF NOT EXISTS vehiculo (
    id_vehiculo BIGSERIAL PRIMARY KEY,
    id_flota BIGINT NOT NULL REFERENCES flota (id_flota),
    placa VARCHAR(20) NOT NULL UNIQUE,
    capacidad_kg NUMERIC(10,2) NOT NULL,
    fecha_compra DATE NOT NULL,
    monto_compra_bob NUMERIC(14,4) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    CONSTRAINT ck_vehiculo_capacidad CHECK (capacidad_kg > 0),
    CONSTRAINT ck_vehiculo_monto_compra CHECK (monto_compra_bob > 0),
    CONSTRAINT ck_vehiculo_estado CHECK (estado IN ('ACTIVO', 'MANTENIMIENTO', 'VENDIDO'))
);

CREATE INDEX IF NOT EXISTS idx_vehiculo_flota_estado ON vehiculo (id_flota, estado);

CREATE TABLE IF NOT EXISTS conductor_operativo (
    id_conductor BIGSERIAL PRIMARY KEY,
    id_empleado_rrhh BIGINT NOT NULL UNIQUE,
    id_sucursal_base BIGINT NOT NULL REFERENCES sucursal (id_sucursal),
    ci VARCHAR(20) NOT NULL UNIQUE,
    licencia_nro VARCHAR(40) NOT NULL UNIQUE,
    estado VARCHAR(20) NOT NULL,
    CONSTRAINT ck_conductor_estado CHECK (estado IN ('ACTIVO', 'SUSPENDIDO', 'BAJA'))
);

CREATE INDEX IF NOT EXISTS idx_conductor_sucursal_base ON conductor_operativo (id_sucursal_base);

CREATE TABLE IF NOT EXISTS ruta (
    id_ruta BIGSERIAL PRIMARY KEY,
    codigo_ruta VARCHAR(30) NOT NULL UNIQUE,
    id_origen_sucursal BIGINT NOT NULL REFERENCES sucursal (id_sucursal),
    id_destino_sucursal BIGINT NOT NULL REFERENCES sucursal (id_sucursal),
    distancia_km NUMERIC(10,2) NOT NULL,
    CONSTRAINT ck_ruta_origen_destino CHECK (id_origen_sucursal <> id_destino_sucursal),
    CONSTRAINT ck_ruta_distancia CHECK (distancia_km > 0)
);

CREATE INDEX IF NOT EXISTS idx_ruta_origen_destino ON ruta (id_origen_sucursal, id_destino_sucursal);

CREATE TABLE IF NOT EXISTS viaje (
    id_viaje BIGSERIAL PRIMARY KEY,
    id_ruta BIGINT NOT NULL REFERENCES ruta (id_ruta),
    id_vehiculo BIGINT NOT NULL REFERENCES vehiculo (id_vehiculo),
    id_conductor BIGINT NOT NULL REFERENCES conductor_operativo (id_conductor),
    fecha_salida_real TIMESTAMPTZ NOT NULL,
    fecha_llegada_real TIMESTAMPTZ NULL,
    estado_viaje VARCHAR(20) NOT NULL,
    CONSTRAINT ck_viaje_estado CHECK (estado_viaje IN ('PROGRAMADO', 'EN_RUTA', 'FINALIZADO', 'CANCELADO')),
    CONSTRAINT ck_viaje_fechas CHECK (fecha_llegada_real IS NULL OR fecha_llegada_real >= fecha_salida_real)
);

CREATE INDEX IF NOT EXISTS idx_viaje_ruta_fecha ON viaje (id_ruta, fecha_salida_real);
CREATE INDEX IF NOT EXISTS idx_viaje_vehiculo_fecha ON viaje (id_vehiculo, fecha_salida_real);

CREATE TABLE IF NOT EXISTS viaje_conductor_asignado (
    id_viaje BIGINT NOT NULL REFERENCES viaje (id_viaje),
    id_conductor BIGINT NOT NULL REFERENCES conductor_operativo (id_conductor),
    rol VARCHAR(20) NOT NULL,
    orden_relevo SMALLINT NOT NULL,
    fecha_asignacion TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id_viaje, id_conductor),
    CONSTRAINT ck_viaje_conductor_rol CHECK (rol IN ('PRINCIPAL', 'RELEVO')),
    CONSTRAINT ck_viaje_conductor_orden CHECK (orden_relevo >= 1)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_viaje_conductor_principal
    ON viaje_conductor_asignado (id_viaje)
    WHERE rol = 'PRINCIPAL';

CREATE TABLE IF NOT EXISTS viaje_carga_resumen (
    id_viaje BIGINT PRIMARY KEY REFERENCES viaje (id_viaje),
    capacidad_kg NUMERIC(10,2) NOT NULL,
    peso_asignado_kg NUMERIC(10,2) NOT NULL,
    capacidad_disponible_kg NUMERIC(10,2) NOT NULL,
    sobrecapacidad_flag BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT ck_viaje_carga_capacidad CHECK (capacidad_kg > 0),
    CONSTRAINT ck_viaje_carga_asignado CHECK (peso_asignado_kg >= 0),
    CONSTRAINT ck_viaje_carga_disponible CHECK (capacidad_disponible_kg >= 0 AND capacidad_disponible_kg <= capacidad_kg)
);

CREATE TABLE IF NOT EXISTS envio (
    id_envio BIGSERIAL PRIMARY KEY,
    codigo_guia VARCHAR(40) NOT NULL UNIQUE,
    id_orden_servicio BIGINT NOT NULL,
    id_remitente_entidad BIGINT NOT NULL,
    id_destinatario_entidad BIGINT NOT NULL,
    id_sucursal_origen BIGINT NOT NULL REFERENCES sucursal (id_sucursal),
    id_sucursal_destino BIGINT NOT NULL REFERENCES sucursal (id_sucursal),
    id_ruta_referencia BIGINT NULL REFERENCES ruta (id_ruta),
    fecha_registro TIMESTAMPTZ NOT NULL,
    fecha_compromiso_listo_recojo TIMESTAMPTZ NOT NULL,
    tipo_carga VARCHAR(20) NOT NULL,
    peso_kg NUMERIC(10,2) NOT NULL,
    volumen_m3 NUMERIC(10,3) NOT NULL,
    valor_declarado_bob NUMERIC(14,4) NOT NULL DEFAULT 0,
    CONSTRAINT ck_envio_sucursales CHECK (id_sucursal_origen <> id_sucursal_destino),
    CONSTRAINT ck_envio_fechas CHECK (fecha_compromiso_listo_recojo >= fecha_registro),
    CONSTRAINT ck_envio_tipo_carga CHECK (tipo_carga IN ('GENERAL', 'FRAGIL', 'REFRIGERADO', 'PERECEDERO', 'PELIGROSO')),
    CONSTRAINT ck_envio_peso CHECK (peso_kg > 0),
    CONSTRAINT ck_envio_volumen CHECK (volumen_m3 >= 0),
    CONSTRAINT ck_envio_valor_declarado CHECK (valor_declarado_bob >= 0)
);

CREATE INDEX IF NOT EXISTS idx_envio_orden_servicio ON envio (id_orden_servicio);
CREATE INDEX IF NOT EXISTS idx_envio_sucursales ON envio (id_sucursal_origen, id_sucursal_destino);
CREATE INDEX IF NOT EXISTS idx_envio_fecha_registro ON envio (fecha_registro);

CREATE TABLE IF NOT EXISTS evento_envio (
    id_evento BIGSERIAL PRIMARY KEY,
    id_envio BIGINT NOT NULL REFERENCES envio (id_envio),
    codigo_evento VARCHAR(30) NOT NULL,
    fecha_hora_evento TIMESTAMPTZ NOT NULL,
    id_sucursal BIGINT NOT NULL REFERENCES sucursal (id_sucursal),
    id_empleado_rrhh BIGINT NOT NULL,
    observacion VARCHAR(255) NULL,
    CONSTRAINT ck_evento_envio_codigo CHECK (
        codigo_evento IN ('RECIBIDO', 'CLASIFICADO', 'EN_TRANSITO', 'EN_SUCURSAL', 'LISTO_RECOJO', 'ENTREGADO', 'DEVUELTO')
    )
);

CREATE INDEX IF NOT EXISTS idx_evento_envio_envio_fecha ON evento_envio (id_envio, fecha_hora_evento DESC, id_evento DESC);
CREATE INDEX IF NOT EXISTS idx_evento_envio_sucursal_fecha ON evento_envio (id_sucursal, fecha_hora_evento);

CREATE TABLE IF NOT EXISTS envio_viaje_tramo (
    id_envio_viaje_tramo BIGSERIAL PRIMARY KEY,
    id_envio BIGINT NOT NULL REFERENCES envio (id_envio),
    id_viaje BIGINT NOT NULL REFERENCES viaje (id_viaje),
    secuencia_tramo SMALLINT NOT NULL,
    id_sucursal_carga BIGINT NOT NULL REFERENCES sucursal (id_sucursal),
    id_sucursal_descarga BIGINT NOT NULL REFERENCES sucursal (id_sucursal),
    fecha_hora_carga TIMESTAMPTZ NOT NULL,
    fecha_hora_descarga TIMESTAMPTZ NULL,
    peso_asignado_kg NUMERIC(10,2) NOT NULL,
    CONSTRAINT uq_envio_viaje_tramo_secuencia UNIQUE (id_envio, secuencia_tramo),
    CONSTRAINT ck_envio_viaje_tramo_secuencia CHECK (secuencia_tramo >= 1),
    CONSTRAINT ck_envio_viaje_tramo_sucursales CHECK (id_sucursal_carga <> id_sucursal_descarga),
    CONSTRAINT ck_envio_viaje_tramo_fechas CHECK (fecha_hora_descarga IS NULL OR fecha_hora_descarga >= fecha_hora_carga),
    CONSTRAINT ck_envio_viaje_tramo_peso CHECK (peso_asignado_kg > 0)
);

CREATE INDEX IF NOT EXISTS idx_envio_viaje_tramo_viaje ON envio_viaje_tramo (id_viaje);

CREATE TABLE IF NOT EXISTS abastecimiento_combustible (
    id_abastecimiento BIGSERIAL PRIMARY KEY,
    id_vehiculo BIGINT NOT NULL REFERENCES vehiculo (id_vehiculo),
    fecha_hora_abastecimiento TIMESTAMPTZ NOT NULL,
    litros NUMERIC(12,3) NOT NULL,
    monto_pagado_bob NUMERIC(14,4) NOT NULL,
    tipo_combustible VARCHAR(20) NOT NULL,
    CONSTRAINT ck_abastecimiento_litros CHECK (litros > 0),
    CONSTRAINT ck_abastecimiento_monto CHECK (monto_pagado_bob > 0),
    CONSTRAINT ck_abastecimiento_tipo CHECK (tipo_combustible IN ('DIESEL', 'GASOLINA', 'GNV', 'OTRO'))
);

CREATE INDEX IF NOT EXISTS idx_abastecimiento_vehiculo_fecha ON abastecimiento_combustible (id_vehiculo, fecha_hora_abastecimiento);

CREATE TABLE IF NOT EXISTS viaje_gasto_operativo (
    id_gasto BIGSERIAL PRIMARY KEY,
    id_viaje BIGINT NOT NULL REFERENCES viaje (id_viaje),
    tipo_gasto VARCHAR(20) NOT NULL,
    monto_bob NUMERIC(14,4) NOT NULL,
    fecha_hora_gasto TIMESTAMPTZ NOT NULL,
    comprobante_ref VARCHAR(80) NULL,
    CONSTRAINT ck_viaje_gasto_tipo CHECK (tipo_gasto IN ('PEAJE', 'VIATICO', 'OTRO')),
    CONSTRAINT ck_viaje_gasto_monto CHECK (monto_bob > 0)
);

CREATE INDEX IF NOT EXISTS idx_viaje_gasto_viaje_fecha ON viaje_gasto_operativo (id_viaje, fecha_hora_gasto);

CREATE TABLE IF NOT EXISTS viaje_liquidacion (
    id_liquidacion BIGSERIAL PRIMARY KEY,
    id_viaje BIGINT NOT NULL UNIQUE REFERENCES viaje (id_viaje),
    adelanto_entregado_bob NUMERIC(14,4) NOT NULL,
    gasto_total_bob NUMERIC(14,4) NOT NULL,
    saldo_a_rendir_bob NUMERIC(14,4) NOT NULL,
    fecha_liquidacion TIMESTAMPTZ NOT NULL,
    CONSTRAINT ck_viaje_liquidacion_montos CHECK (
        adelanto_entregado_bob >= 0
        AND gasto_total_bob >= 0
        AND saldo_a_rendir_bob = ROUND(adelanto_entregado_bob - gasto_total_bob, 4)
    )
);

CREATE INDEX IF NOT EXISTS idx_viaje_liquidacion_fecha ON viaje_liquidacion (fecha_liquidacion);


/* ============================================================================
   3) SQL SERVER - finanzas_rrhh_db
   Ejecutar solo esta seccion en SQL Server / SSMS / sqlcmd
============================================================================ */

IF DB_ID(N'finanzas_rrhh_db') IS NULL
BEGIN
    CREATE DATABASE [finanzas_rrhh_db];
END;
GO

USE [finanzas_rrhh_db];
GO

CREATE TABLE dbo.cuenta_credito_cliente (
    id_cuenta_credito BIGINT IDENTITY(1,1) NOT NULL,
    id_cliente_comercial BIGINT NOT NULL,
    limite_credito_bob DECIMAL(14,4) NOT NULL,
    saldo_utilizado_bob DECIMAL(14,4) NOT NULL DEFAULT 0,
    saldo_vencido_bob DECIMAL(14,4) NOT NULL DEFAULT 0,
    credito_disponible_bob DECIMAL(14,4) NOT NULL,
    fecha_corte DATETIME2(0) NOT NULL,
    CONSTRAINT PK_cuenta_credito_cliente PRIMARY KEY (id_cuenta_credito),
    CONSTRAINT UQ_cuenta_credito_cliente_cliente UNIQUE (id_cliente_comercial),
    CONSTRAINT CK_cuenta_credito_limites CHECK (
        limite_credito_bob >= 0
        AND saldo_utilizado_bob >= 0
        AND saldo_vencido_bob >= 0
        AND saldo_utilizado_bob <= limite_credito_bob
        AND saldo_vencido_bob <= saldo_utilizado_bob
        AND credito_disponible_bob = ROUND(limite_credito_bob - saldo_utilizado_bob, 4)
    )
);
GO

CREATE TABLE dbo.reserva_credito (
    id_reserva_credito BIGINT IDENTITY(1,1) NOT NULL,
    id_cuenta_credito BIGINT NOT NULL,
    id_cliente_comercial BIGINT NOT NULL,
    monto_reservado_bob DECIMAL(14,4) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    fecha_creacion DATETIME2(0) NOT NULL,
    fecha_expira DATETIME2(0) NOT NULL,
    CONSTRAINT PK_reserva_credito PRIMARY KEY (id_reserva_credito),
    CONSTRAINT FK_reserva_credito_cuenta FOREIGN KEY (id_cuenta_credito) REFERENCES dbo.cuenta_credito_cliente (id_cuenta_credito),
    CONSTRAINT CK_reserva_credito_estado CHECK (estado IN ('RESERVADA', 'CONSUMIDA', 'LIBERADA', 'RECHAZADA')),
    CONSTRAINT CK_reserva_credito_monto CHECK (monto_reservado_bob > 0),
    CONSTRAINT CK_reserva_credito_fechas CHECK (fecha_expira >= fecha_creacion)
);
GO

CREATE INDEX IX_reserva_credito_cliente_estado_fecha
    ON dbo.reserva_credito (id_cliente_comercial, estado, fecha_creacion, fecha_expira);
GO

CREATE TABLE dbo.factura (
    id_factura BIGINT IDENTITY(1,1) NOT NULL,
    nro_factura VARCHAR(30) NOT NULL,
    id_cliente_comercial BIGINT NOT NULL,
    fecha_emision DATETIME2(0) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    total_bob DECIMAL(14,4) NOT NULL,
    estado_cobro VARCHAR(20) NOT NULL,
    CONSTRAINT PK_factura PRIMARY KEY (id_factura),
    CONSTRAINT UQ_factura_nro UNIQUE (nro_factura),
    CONSTRAINT CK_factura_total CHECK (total_bob > 0),
    CONSTRAINT CK_factura_estado CHECK (estado_cobro IN ('PENDIENTE', 'PARCIAL', 'COBRADO', 'VENCIDO')),
    CONSTRAINT CK_factura_fechas CHECK (fecha_vencimiento >= CAST(fecha_emision AS DATE))
);
GO

CREATE INDEX IX_factura_cliente_fecha ON dbo.factura (id_cliente_comercial, fecha_emision);
GO

CREATE TABLE dbo.factura_detalle (
    id_factura_detalle BIGINT IDENTITY(1,1) NOT NULL,
    id_factura BIGINT NOT NULL,
    id_envio_ops BIGINT NOT NULL,
    id_orden_servicio BIGINT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario_bob DECIMAL(14,4) NOT NULL,
    total_linea_bob DECIMAL(14,4) NOT NULL,
    CONSTRAINT PK_factura_detalle PRIMARY KEY (id_factura_detalle),
    CONSTRAINT FK_factura_detalle_factura FOREIGN KEY (id_factura) REFERENCES dbo.factura (id_factura),
    CONSTRAINT UQ_factura_detalle_envio UNIQUE (id_factura, id_envio_ops),
    CONSTRAINT CK_factura_detalle_valores CHECK (
        cantidad > 0
        AND precio_unitario_bob > 0
        AND total_linea_bob = ROUND(cantidad * precio_unitario_bob, 4)
    )
);
GO

CREATE INDEX IX_factura_detalle_orden ON dbo.factura_detalle (id_orden_servicio);
GO

CREATE TABLE dbo.pago (
    id_pago BIGINT IDENTITY(1,1) NOT NULL,
    id_factura BIGINT NOT NULL,
    monto_bob DECIMAL(14,4) NOT NULL,
    fecha_pago DATETIME2(0) NOT NULL,
    metodo_pago VARCHAR(30) NOT NULL,
    CONSTRAINT PK_pago PRIMARY KEY (id_pago),
    CONSTRAINT FK_pago_factura FOREIGN KEY (id_factura) REFERENCES dbo.factura (id_factura),
    CONSTRAINT CK_pago_monto CHECK (monto_bob > 0),
    CONSTRAINT CK_pago_metodo CHECK (metodo_pago IN ('TRANSFERENCIA', 'QR', 'EFECTIVO', 'CHEQUE'))
);
GO

CREATE INDEX IX_pago_factura_fecha ON dbo.pago (id_factura, fecha_pago);
GO

CREATE TABLE dbo.empleado (
    id_empleado BIGINT IDENTITY(1,1) NOT NULL,
    ci VARCHAR(20) NOT NULL,
    nombres_apellidos VARCHAR(160) NOT NULL,
    cargo VARCHAR(80) NOT NULL,
    area VARCHAR(40) NOT NULL,
    id_sucursal_ref BIGINT NOT NULL,
    fecha_ingreso DATE NOT NULL,
    estado_laboral VARCHAR(20) NOT NULL,
    CONSTRAINT PK_empleado PRIMARY KEY (id_empleado),
    CONSTRAINT UQ_empleado_ci UNIQUE (ci),
    CONSTRAINT CK_empleado_estado CHECK (estado_laboral IN ('ACTIVO', 'SUSPENDIDO', 'BAJA'))
);
GO

CREATE INDEX IX_empleado_sucursal_area ON dbo.empleado (id_sucursal_ref, area);
GO

CREATE TABLE dbo.contrato_laboral (
    id_contrato_laboral BIGINT IDENTITY(1,1) NOT NULL,
    id_empleado BIGINT NOT NULL,
    tipo_contrato VARCHAR(30) NOT NULL,
    salario_base_bob DECIMAL(14,4) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    estado VARCHAR(20) NOT NULL,
    CONSTRAINT PK_contrato_laboral PRIMARY KEY (id_contrato_laboral),
    CONSTRAINT FK_contrato_laboral_empleado FOREIGN KEY (id_empleado) REFERENCES dbo.empleado (id_empleado),
    CONSTRAINT CK_contrato_laboral_tipo CHECK (tipo_contrato IN ('INDEFINIDO', 'PLAZO_FIJO', 'EVENTUAL', 'CONSULTORIA')),
    CONSTRAINT CK_contrato_laboral_estado CHECK (estado IN ('VIGENTE', 'FINALIZADO', 'SUSPENDIDO')),
    CONSTRAINT CK_contrato_laboral_salario CHECK (salario_base_bob > 0),
    CONSTRAINT CK_contrato_laboral_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);
GO

CREATE UNIQUE INDEX UX_contrato_laboral_vigente_por_empleado
    ON dbo.contrato_laboral (id_empleado)
    WHERE estado = 'VIGENTE';
GO

CREATE TABLE dbo.nomina (
    id_nomina BIGINT IDENTITY(1,1) NOT NULL,
    id_empleado BIGINT NOT NULL,
    periodo DATE NOT NULL,
    salario_base_bob DECIMAL(14,4) NOT NULL,
    horas_extra_monto_bob DECIMAL(14,4) NOT NULL DEFAULT 0,
    descuentos_bob DECIMAL(14,4) NOT NULL DEFAULT 0,
    liquido_pagable_bob DECIMAL(14,4) NOT NULL,
    fecha_pago DATETIME2(0) NOT NULL,
    CONSTRAINT PK_nomina PRIMARY KEY (id_nomina),
    CONSTRAINT FK_nomina_empleado FOREIGN KEY (id_empleado) REFERENCES dbo.empleado (id_empleado),
    CONSTRAINT UQ_nomina_empleado_periodo UNIQUE (id_empleado, periodo),
    CONSTRAINT CK_nomina_periodo CHECK (DAY(periodo) = 1),
    CONSTRAINT CK_nomina_valores CHECK (
        salario_base_bob >= 0
        AND horas_extra_monto_bob >= 0
        AND descuentos_bob >= 0
        AND liquido_pagable_bob = ROUND(salario_base_bob + horas_extra_monto_bob - descuentos_bob, 4)
    ),
    CONSTRAINT CK_nomina_fecha_pago CHECK (fecha_pago >= CAST(periodo AS DATETIME2(0)))
);
GO

CREATE INDEX IX_nomina_periodo ON dbo.nomina (periodo);
GO

CREATE TABLE dbo.asistencia_empleado (
    id_asistencia BIGINT IDENTITY(1,1) NOT NULL,
    id_empleado BIGINT NOT NULL,
    fecha DATE NOT NULL,
    hora_entrada TIME NOT NULL,
    hora_salida TIME NOT NULL,
    horas_trabajadas DECIMAL(5,2) NOT NULL,
    horas_extra DECIMAL(5,2) NOT NULL DEFAULT 0,
    tipo_jornada VARCHAR(20) NOT NULL,
    estado_asistencia VARCHAR(20) NOT NULL,
    observacion VARCHAR(200) NULL,
    CONSTRAINT PK_asistencia_empleado PRIMARY KEY (id_asistencia),
    CONSTRAINT FK_asistencia_empleado_empleado FOREIGN KEY (id_empleado) REFERENCES dbo.empleado (id_empleado),
    CONSTRAINT UQ_asistencia_empleado_fecha UNIQUE (id_empleado, fecha),
    CONSTRAINT CK_asistencia_horas CHECK (
        horas_trabajadas >= 0
        AND horas_extra >= 0
        AND horas_extra <= horas_trabajadas
    ),
    CONSTRAINT CK_asistencia_tipo_jornada CHECK (tipo_jornada IN ('NORMAL', 'EXTRA', 'GUARDIA', 'DIA_LIBRE')),
    CONSTRAINT CK_asistencia_estado CHECK (estado_asistencia IN ('PRESENTE', 'AUSENTE', 'TARDANZA', 'LICENCIA'))
);
GO

CREATE INDEX IX_asistencia_fecha ON dbo.asistencia_empleado (fecha);
GO

CREATE TABLE dbo.mantenimiento_vehiculo (
    id_mantenimiento BIGINT IDENTITY(1,1) NOT NULL,
    id_vehiculo_ops BIGINT NOT NULL,
    tipo_mantenimiento VARCHAR(30) NOT NULL,
    descripcion VARCHAR(255) NULL,
    fecha_ingreso DATETIME2(0) NOT NULL,
    fecha_salida DATETIME2(0) NULL,
    costo_repuestos_bob DECIMAL(14,4) NOT NULL DEFAULT 0,
    costo_mano_obra_bob DECIMAL(14,4) NOT NULL DEFAULT 0,
    costo_total_bob DECIMAL(14,4) NOT NULL,
    proveedor VARCHAR(120) NULL,
    nro_factura_proveedor VARCHAR(40) NULL,
    CONSTRAINT PK_mantenimiento_vehiculo PRIMARY KEY (id_mantenimiento),
    CONSTRAINT CK_mantenimiento_tipo CHECK (tipo_mantenimiento IN ('PREVENTIVO', 'CORRECTIVO', 'INSPECCION')),
    CONSTRAINT CK_mantenimiento_fechas CHECK (fecha_salida IS NULL OR fecha_salida >= fecha_ingreso),
    CONSTRAINT CK_mantenimiento_costos CHECK (
        costo_repuestos_bob >= 0
        AND costo_mano_obra_bob >= 0
        AND costo_total_bob = ROUND(costo_repuestos_bob + costo_mano_obra_bob, 4)
    )
);
GO

CREATE INDEX IX_mantenimiento_vehiculo_fecha ON dbo.mantenimiento_vehiculo (id_vehiculo_ops, fecha_ingreso);
GO

CREATE TABLE dbo.gasto_fijo_mensual (
    id_gasto_fijo BIGINT IDENTITY(1,1) NOT NULL,
    periodo DATE NOT NULL,
    categoria VARCHAR(40) NOT NULL,
    descripcion VARCHAR(255) NULL,
    id_sucursal_ref BIGINT NULL,
    monto_bob DECIMAL(14,4) NOT NULL,
    fecha_registro DATETIME2(0) NOT NULL,
    responsable_ci VARCHAR(20) NOT NULL,
    CONSTRAINT PK_gasto_fijo_mensual PRIMARY KEY (id_gasto_fijo),
    CONSTRAINT FK_gasto_fijo_responsable FOREIGN KEY (responsable_ci) REFERENCES dbo.empleado (ci),
    CONSTRAINT CK_gasto_fijo_periodo CHECK (DAY(periodo) = 1),
    CONSTRAINT CK_gasto_fijo_categoria CHECK (
        categoria IN ('ALQUILER', 'SERVICIOS_BASICOS', 'ADMINISTRATIVO', 'SEGURO', 'IMPUESTO', 'OTROS')
    ),
    CONSTRAINT CK_gasto_fijo_monto CHECK (monto_bob > 0),
    CONSTRAINT CK_gasto_fijo_fecha_registro CHECK (fecha_registro >= CAST(periodo AS DATETIME2(0))),
    CONSTRAINT CK_gasto_fijo_alquiler_sucursal CHECK (categoria <> 'ALQUILER' OR id_sucursal_ref IS NOT NULL)
);
GO

CREATE INDEX IX_gasto_fijo_periodo_categoria_sucursal
    ON dbo.gasto_fijo_mensual (periodo, categoria, id_sucursal_ref);
GO

CREATE UNIQUE INDEX UX_gasto_fijo_alquiler_periodo_sucursal
    ON dbo.gasto_fijo_mensual (periodo, id_sucursal_ref, categoria)
    WHERE categoria = 'ALQUILER' AND id_sucursal_ref IS NOT NULL;
GO

CREATE UNIQUE INDEX UX_gasto_fijo_servicios_periodo_sucursal
    ON dbo.gasto_fijo_mensual (periodo, id_sucursal_ref, categoria)
    WHERE categoria = 'SERVICIOS_BASICOS' AND id_sucursal_ref IS NOT NULL;
GO


/* ============================================================================
   4) MONGODB - telemetria_gps_db
   Esta seccion queda comentada porque se ejecuta en mongosh, no en SQL
============================================================================ */

/*
use telemetria_gps_db;

db.createCollection("gps_track", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [
        "id_vehiculo_ops",
        "id_viaje_ops",
        "id_conductor_ops",
        "ts",
        "lat",
        "lon",
        "vel_kmh",
        "temp_motor_c",
        "combustible_pct",
        "evento"
      ],
      properties: {
        id_vehiculo_ops: { bsonType: "long" },
        id_viaje_ops: { bsonType: "long" },
        id_conductor_ops: { bsonType: "long" },
        ts: { bsonType: "date" },
        lat: { bsonType: "double" },
        lon: { bsonType: "double" },
        vel_kmh: { bsonType: "double", minimum: 0 },
        temp_motor_c: { bsonType: "double" },
        combustible_pct: { bsonType: "double", minimum: 0, maximum: 100 },
        evento: { bsonType: "string" }
      }
    }
  }
});

db.createCollection("gps_alerta", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [
        "id_viaje_ops",
        "ts_alerta",
        "tipo_alerta",
        "nivel",
        "descripcion",
        "atendida"
      ],
      properties: {
        id_vehiculo_ops: { bsonType: ["long", "null"] },
        id_viaje_ops: { bsonType: "long" },
        ts_alerta: { bsonType: "date" },
        tipo_alerta: { bsonType: "string" },
        nivel: { bsonType: "string", enum: ["MEDIO", "ALTO", "CRITICO"] },
        descripcion: { bsonType: "string" },
        atendida: { bsonType: "bool" }
      }
    }
  }
});

db.gps_track.createIndex({ id_viaje_ops: 1, ts: 1 });
db.gps_track.createIndex({ id_vehiculo_ops: 1, ts: 1 });
db.gps_alerta.createIndex({ id_viaje_ops: 1, ts_alerta: 1 });
db.gps_alerta.createIndex({ id_vehiculo_ops: 1, ts_alerta: 1 });
*/
