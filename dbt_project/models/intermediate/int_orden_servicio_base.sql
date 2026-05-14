with ruta_tarifa as (
  select
    t.id_tarifa_detalle,
    r.id_ruta
  from {{ ref('int_tarifa_base') }} t
  left join {{ ref('int_ruta_base') }} r
    on t.id_sucursal_origen_ref = r.id_sucursal_origen
   and t.id_sucursal_destino_ref = r.id_sucursal_destino
  qualify row_number() over (
    partition by t.id_tarifa_detalle
    order by r.id_ruta
  ) = 1
),
envios_resumen as (
  select
    e.id_orden_servicio,
    count(distinct e.id_envio) as cantidad_envios,
    min(e.fecha_registro) as fecha_primer_envio,
    max(e.fecha_registro) as fecha_ultimo_envio,
    min(e.fecha_compromiso_listo_recojo) as fecha_primer_compromiso_recojo,
    max(e.fecha_compromiso_listo_recojo) as fecha_ultimo_compromiso_recojo,
    max(ec.fecha_cierre_envio) as fecha_ultimo_cierre_envio,
    max(case when ec.fecha_cierre_envio is not null then 1 else 0 end) as tiene_envio_cerrado_flag,
    max(case when ec.estado_final_codigo = 'DEVUELTO' then 1 else 0 end) as tiene_devolucion_flag
  from {{ ref('stg_ops__envio') }} e
  left join {{ ref('int_envio_cierre') }} ec
    on e.id_envio = ec.id_envio
  group by 1
)
select
  os.id_orden_servicio,
  os.id_reserva_credito,
  cred.id_cuenta_credito,
  os.id_cliente,
  os.id_contrato,
  coalesce(os.id_tarifa_detalle, 0) as id_tarifa_detalle,
  tar.id_sucursal_origen_ref as id_sucursal_origen,
  tar.id_sucursal_destino_ref as id_sucursal_destino,
  rt.id_ruta,
  os.fecha_creacion,
  os.vigencia_hasta,
  env.fecha_primer_envio,
  env.fecha_ultimo_envio,
  env.fecha_primer_compromiso_recojo,
  env.fecha_ultimo_compromiso_recojo,
  env.fecha_ultimo_cierre_envio,
  os.estado_orden,
  coalesce(env.cantidad_envios, 0) as cantidad_envios,
  coalesce(env.tiene_envio_cerrado_flag, 0) as tiene_envio_cerrado_flag,
  coalesce(env.tiene_devolucion_flag, 0) as tiene_devolucion_flag,
  os.total_bob,
  cred.monto_reservado_bob,
  cred.limite_credito_bob,
  cred.saldo_utilizado_bob,
  cred.saldo_vencido_bob,
  cred.credito_disponible_bob,
  fact.monto_facturado_bob,
  fact.cantidad_lineas_facturadas
from {{ ref('stg_comercial__orden_servicio') }} os
left join {{ ref('int_tarifa_base') }} tar
  on os.id_tarifa_detalle = tar.id_tarifa_detalle
left join ruta_tarifa rt
  on os.id_tarifa_detalle = rt.id_tarifa_detalle
left join {{ ref('int_credito_asof_orden') }} cred
  on os.id_orden_servicio = cred.id_orden_servicio
left join envios_resumen env
  on os.id_orden_servicio = env.id_orden_servicio
left join {{ ref('int_facturacion_por_orden') }} fact
  on os.id_orden_servicio = fact.id_orden_servicio
