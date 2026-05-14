# Revision del modelo `MODELO_DWH_DBT_ESTRELLA_SIMPLE_FINAL`

## 1) Objetivo de la revision

Validar dos cosas:

1. si el modelo dimensional simple realmente nace del OLTP que ya tienes;
2. si con `dbt` sobre `Snowflake` se puede construir sin romper grano, sin duplicar metricas y sin inventar relaciones.

---

## 2) Veredicto ejecutivo

**Si, el modelo esta correctamente basado en tu OLTP y si se puede implementar con `dbt` en un flujo `ELT` sobre `Snowflake`.**

Pero el veredicto correcto es:

- **Alineado al OLTP:** `SI`
- **Implementable con `dbt`:** `SI`
- **Cumplimiento de requerimientos BI:** `ALTO`
- **Condiciones tecnicas que no se deben romper:** `SI, HAY 3`

Las 3 condiciones importantes son:

1. **`orden_servicio` debe generar como maximo un `envio`** para que `fact_servicio` siga siendo una sola fila por orden.
2. **El analisis por conductor se hace con el conductor principal del viaje**, no con relevos detallados.
3. **Las metricas de credito historico no deben salir de la tabla actual de cuenta**, sino de un mecanismo de snapshot en `dbt`, para no reescribir historia.

---

## 3) Validacion contra el OLTP

## 3.1 Relacion directa OLTP -> modelo dimensional

El modelo final **si sale del OLTP real** porque cada hecho y dimension puede trazarse a tablas fuente concretas:

- `fact_servicio`
  - `orden_servicio`
  - `envio`
  - `evento_envio`
  - `reserva_credito`
  - `cuenta_credito_cliente`
  - `factura_detalle`

- `fact_viaje`
  - `viaje`
  - `ruta`
  - `vehiculo`
  - `viaje_carga_resumen`
  - `envio_viaje_tramo`
  - `viaje_gasto_operativo`
  - `viaje_liquidacion`
  - `gps_track`
  - `gps_alerta`
  - `mantenimiento_vehiculo`

- `fact_tracking_evento`
  - `evento_envio`
  - `gps_alerta`
  - excepciones derivadas de `gps_track`

- `fact_facturacion`
  - `factura`
  - `factura_detalle`
  - `envio`
  - `orden_servicio`

- `fact_pago`
  - `pago`
  - `factura`

- `fact_rrhh_mensual`
  - `empleado`
  - `nomina`
  - `asistencia_empleado`

Las dimensiones tambien estan alineadas con tablas reales del OLTP:

- `dim_cliente` <- `cliente` + `entidad`
- `dim_tarifa` <- `tarifario` + `tarifario_detalle`
- `dim_sucursal` <- `sucursal`
- `dim_ruta` <- `ruta`
- `dim_vehiculo` <- `vehiculo` + `flota`
- `dim_conductor` <- `conductor_operativo`
- `dim_factura` <- `factura`
- `dim_empleado` <- `empleado`
- `dim_metodo_pago` <- catalogo derivado de `pago`
- `dim_tipo_tracking_evento` <- catalogo derivado de `evento_envio`, `gps_alerta` y eventos derivados

## 3.2 No rompe el OLTP

El modelo **no se sale del contexto del OLTP** porque:

- no inventa procesos nuevos;
- no cambia la fuente unica del precio, que sigue siendo `orden_servicio`;
- no elimina el hecho de que los envios pueden tener transbordos;
- no obliga a unir hechos entre si mediante claves artificiales;
- conserva trazabilidad por `id_orden_servicio`, `id_envio`, `id_factura`, `id_pago`, `id_viaje`.

## 3.3 Donde si hay condiciones de validez

### Condicion 1: `fact_servicio`

`fact_servicio` es correcto **solo si** en la practica una orden genera como maximo un envio.

Esto hoy:

- **esta alineado con tu simulador de datos**, porque el generador crea un envio por orden;
- **no esta forzado de forma explicita en la documentacion del OLTP**.

Conclusión:

- en `dbt` se debe dejar un test obligatorio;
- si ese test falla, se divide en:
  - `fact_orden_servicio`
  - `fact_envio`

### Condicion 2: conductor principal

El OLTP soporta relevos por `viaje_conductor_asignado`.

El modelo simple usa solo:

- `viaje.id_conductor`

Eso **no rompe** el modelo, pero significa:

- sirve para tablero gerencial y operativo simple;
- no sirve para auditoria detallada de relevos por tramo.

### Condicion 3: credito historico

La tabla `cuenta_credito_cliente` del OLTP representa el estado actual de la cuenta.

Si se la une directamente a todas las ordenes historicas, se produce un error:

- se reescribe el pasado con el saldo actual.

Conclusión:

- con `dbt` **si se puede hacer bien**;
- pero hay que usar `snapshot` tecnico para congelar la evolucion de la cuenta en el tiempo.

Eso no complica el modelo de negocio, solo protege la consistencia del ELT.

---

## 4) Validacion de implementacion con `dbt` sobre `Snowflake`

## 4.1 Si se puede implementar con ELT

**Si.**

Este modelo es adecuado para `dbt + Snowflake` porque:

- el OLTP ya viene separado por dominios y motores;
- `Snowflake` puede centralizar esas fuentes en esquemas `raw`;
- `dbt` puede resolver bien los joins cross-domain en capas:
  - `staging`
  - `intermediate`
  - `marts`
- la mayoria de calculos son agregaciones y ventanas, no logica procedural compleja.

## 4.2 Que hace bien `dbt` aqui

`dbt` encaja muy bien para:

- limpiar y homologar tipos;
- construir dimensiones conformadas;
- calcular fechas de cierre y SLA desde eventos;
- resumir costos y telemetria por viaje;
- resumir RRHH por empleado-mes;
- validar reglas de negocio con tests.

## 4.3 Lo que no debes hacer en `dbt`

Para no romper consistencia:

- no unir la cuenta de credito actual directamente contra toda la historia sin snapshot;
- no sumar a la vez `viaje_gasto_operativo` y `viaje_liquidacion.gasto_total_bob` como si fueran dos costos independientes;
- no unir `fact_facturacion` con `fact_pago` fila a fila, porque la relacion analitica es por `factura`;
- no usar `gps_track` crudo como hecho principal de BI, porque solo meteria volumen y ruido.

---

## 5) Cobertura contra requerimientos R1-R14

## 5.1 Resumen corto

- **Cumple de forma directa:** R1, R2, R3, R5, R7, R8, R9, R10, R11, R12, R13
- **Cumple con condicion tecnica:** R4, R6, R14

## 5.2 Matriz de cobertura

| Req | Estado | Hechos principales | Comentario |
|---|---|---|---|
| R1-COM | CUMPLE | `fact_servicio`, `fact_facturacion` | Ingresos, volumen, ticket y ruta por periodo. |
| R2-COM | CUMPLE_CON_CONDICION | `fact_servicio` | Depende de que una orden no tenga mas de un envio. |
| R3-COM | CUMPLE | `fact_servicio`, `dim_tarifa` | Tipo tarifario, tipo carga y rango de peso. |
| R4-COM | CUMPLE_CON_CONDICION | `fact_servicio` | Requiere snapshot tecnico de `cuenta_credito_cliente` para no reescribir historia. |
| R5-OPS | CUMPLE | `fact_servicio`, `fact_tracking_evento` | SLA y desviacion salen de `envio` + `evento_envio`. |
| R6-OPS | CUMPLE_CON_CONDICION | `fact_viaje` | Responde ocupacion y sobrecapacidad por viaje/ruta; el nivel exacto de relevo por tramo no se expone como hecho aparte. |
| R7-OPS | CUMPLE | `fact_viaje` | Costos por viaje, ruta, vehiculo y costo por km. |
| R8-OPS | CUMPLE | `fact_tracking_evento`, `fact_viaje` | Trazabilidad, alertas, tiempos entre eventos y riesgo operativo. |
| R9-FIN | CUMPLE | `fact_servicio`, `fact_facturacion` | Cobertura de facturacion y envios no facturados. |
| R10-FIN | CUMPLE | `fact_facturacion`, `fact_pago` | Antiguedad, saldo vencido y porcentaje vencido. |
| R11-FIN | CUMPLE | `fact_pago`, `fact_facturacion` | DSO, pagos tardios y metodo de pago. |
| R12-RRHH | CUMPLE | `fact_rrhh_mensual`, `fact_viaje`, `fact_facturacion` | Costo laboral, asistencia y cruce con resultados operativos/comerciales. |
| R13-TEL | CUMPLE | `fact_viaje`, `fact_tracking_evento` | Cobertura, interrupciones y perdida de telemetria. |
| R14-TEL | CUMPLE_CON_CONDICION | `fact_viaje`, `fact_tracking_evento` | Se cubre completamente si en `fact_tracking_evento` se agrega una metrica de mantenimiento correctivo posterior a alerta. |

## 5.3 Cobertura por KPI y graficos

El modelo simple **cubre la mayoria fuerte** de tus KPI y graficos porque:

- comercial depende sobre todo de `fact_servicio` y `fact_facturacion`;
- operaciones depende de `fact_servicio`, `fact_viaje` y `fact_tracking_evento`;
- finanzas/cobranza depende de `fact_facturacion` y `fact_pago`;
- RRHH depende de `fact_rrhh_mensual`;
- telemetria depende de `fact_viaje` y `fact_tracking_evento`.

Los unicos puntos que requieren aclaracion previa son:

- conversion orden -> envio si existe multiplo envio por orden;
- credito historico si no se usa snapshot;
- causalidad alerta -> mantenimiento si no se deja la metrica derivada en eventos.

---

## 6) Recomendacion final

La mejor decision **no es volver a un snowflake grande**.

La mejor decision es:

1. mantener este modelo simple de **12 dimensiones + 6 hechos**;
2. protegerlo en `dbt` con:
   - tests de grano,
   - agregaciones correctas,
   - snapshot tecnico para credito;
3. agregar en la implementacion `dbt` una metrica adicional de seguimiento a mantenimiento correctivo desde eventos de tracking.

---

## 7) Veredicto final

**Tu modelo simple si esta en base al OLTP, si se puede construir bien con `dbt` sobre `Snowflake`, y si cubre todos o casi todos tus requerimientos de BI sin necesidad de volver a un modelo gigante.**

El ajuste tecnico clave no es agregar mas hechos, sino:

- validar `orden -> envio`,
- manejar bien snapshot de credito,
- y derivar correctamente las metricas de telemetria y mantenimiento.
