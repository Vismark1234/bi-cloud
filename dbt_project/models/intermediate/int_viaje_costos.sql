with viajes as (
  select
    id_viaje,
    id_vehiculo,
    fecha_salida_real,
    coalesce(fecha_llegada_real, dateadd(hour, 24, fecha_salida_real)) as fecha_fin_ref
  from {{ ref('stg_ops__viaje') }}
),
gastos as (
  select
    id_viaje,
    sum(monto_bob) as gasto_operativo_detalle_bob,
    sum(case when tipo_gasto = 'PEAJE' then monto_bob else 0 end) as gasto_peaje_bob,
    sum(case when tipo_gasto = 'VIATICO' then monto_bob else 0 end) as gasto_viatico_bob,
    sum(case when tipo_gasto = 'OTRO' then monto_bob else 0 end) as gasto_otro_bob
  from {{ ref('stg_ops__viaje_gasto_operativo') }}
  group by 1
),
combustible as (
  with combustible_candidatos as (
    select
      a.id_abastecimiento,
      v.id_viaje,
      a.litros,
      a.monto_pagado_bob,
      row_number() over (
        partition by a.id_abastecimiento
        order by
          case
            when a.fecha_hora_abastecimiento between v.fecha_salida_real and v.fecha_fin_ref then 0
            else 1
          end,
          least(
            abs(datediff('minute', a.fecha_hora_abastecimiento, v.fecha_salida_real)),
            abs(datediff('minute', a.fecha_hora_abastecimiento, v.fecha_fin_ref))
          ),
          v.fecha_salida_real desc,
          v.id_viaje desc
      ) as rn
    from viajes v
    join {{ ref('stg_ops__abastecimiento_combustible') }} a
      on v.id_vehiculo = a.id_vehiculo
     and a.fecha_hora_abastecimiento >= dateadd(hour, -1, v.fecha_salida_real)
     and a.fecha_hora_abastecimiento <= dateadd(hour, 1, v.fecha_fin_ref)
  )
  select
    id_viaje,
    count(id_abastecimiento) as cantidad_abastecimientos,
    sum(litros) as litros_combustible_total,
    sum(monto_pagado_bob) as costo_combustible_total_bob
  from combustible_candidatos
  where rn = 1
  group by 1
),
liquidaciones as (
  select
    id_viaje,
    gasto_total_bob,
    adelanto_entregado_bob,
    saldo_a_rendir_bob,
    fecha_liquidacion
  from {{ ref('stg_ops__viaje_liquidacion') }}
),
keys as (
  select id_viaje from gastos
  union
  select id_viaje from combustible
  union
  select id_viaje from liquidaciones
)
select
  k.id_viaje,
  g.gasto_operativo_detalle_bob,
  g.gasto_peaje_bob,
  g.gasto_viatico_bob,
  g.gasto_otro_bob,
  l.gasto_total_bob as gasto_liquidado_bob,
  l.adelanto_entregado_bob,
  l.saldo_a_rendir_bob,
  l.fecha_liquidacion,
  coalesce(c.cantidad_abastecimientos, 0) as cantidad_abastecimientos,
  coalesce(c.litros_combustible_total, 0) as litros_combustible_total,
  coalesce(c.costo_combustible_total_bob, 0) as costo_combustible_total_bob,
  coalesce(
    {{ safe_divide('c.costo_combustible_total_bob', 'c.litros_combustible_total', 0) }},
    0
  ) as precio_combustible_promedio_bob_litro,
  coalesce(nullif(g.gasto_operativo_detalle_bob, 0), l.gasto_total_bob, 0) as costo_operativo_no_combustible_bob,
  coalesce(nullif(g.gasto_operativo_detalle_bob, 0), l.gasto_total_bob, 0) + coalesce(c.costo_combustible_total_bob, 0) as costo_operativo_total_bob
from keys k
left join gastos g
  on k.id_viaje = g.id_viaje
left join combustible c
  on k.id_viaje = c.id_viaje
left join liquidaciones l
  on k.id_viaje = l.id_viaje
