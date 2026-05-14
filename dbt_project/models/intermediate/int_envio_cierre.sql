with eventos as (
  select
    ev.id_evento,
    ev.id_envio,
    ev.codigo_evento,
    ev.fecha_hora_evento,
    ev.id_sucursal,
    case when ev.codigo_evento in ('ENTREGADO', 'DEVUELTO') then 1 else 0 end as es_final_flag,
    row_number() over (
      partition by ev.id_envio
      order by ev.fecha_hora_evento desc, ev.id_evento desc
    ) as rn_ultimo
  from {{ ref('stg_ops__evento_envio') }} ev
),
listo_recojo as (
  select
    id_envio,
    min(fecha_hora_evento) as fecha_listo_recojo
  from eventos
  where codigo_evento = 'LISTO_RECOJO'
  group by 1
),
ultimo_evento as (
  select
    id_envio,
    fecha_hora_evento as fecha_ultimo_evento,
    codigo_evento as estado_final_codigo,
    id_sucursal as id_sucursal_ultimo_evento
  from eventos
  qualify rn_ultimo = 1
),
cierres as (
  select
    id_envio,
    fecha_hora_evento as fecha_cierre_envio,
    id_sucursal as id_sucursal_cierre
  from eventos
  where es_final_flag = 1
  qualify row_number() over (
    partition by id_envio
    order by fecha_hora_evento desc, id_evento desc
  ) = 1
)
select
  u.id_envio,
  l.fecha_listo_recojo,
  c.fecha_cierre_envio,
  l.fecha_listo_recojo as fecha_cumplimiento_sla,
  u.estado_final_codigo,
  coalesce(c.id_sucursal_cierre, u.id_sucursal_ultimo_evento) as id_sucursal_cierre
from ultimo_evento u
left join listo_recojo l
  on u.id_envio = l.id_envio
left join cierres c
  on u.id_envio = c.id_envio
