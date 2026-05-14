with ordenes as (
  select
    os.id_orden_servicio,
    os.fecha_creacion,
    rc.id_reserva_credito,
    rc.id_cuenta_credito,
    rc.id_cliente,
    rc.monto_reservado_bob
  from {{ ref('stg_comercial__orden_servicio') }} os
  inner join {{ ref('stg_fin__reserva_credito') }} rc
    on os.id_reserva_credito = rc.id_reserva_credito
),
snap_match as (
  select
    o.id_orden_servicio,
    o.id_reserva_credito,
    o.id_cuenta_credito,
    o.id_cliente,
    o.monto_reservado_bob,
    s.limite_credito_bob,
    s.saldo_utilizado_bob,
    s.saldo_vencido_bob,
    s.credito_disponible_bob,
    row_number() over (
      partition by o.id_orden_servicio
      order by s.dbt_valid_from desc nulls last
    ) as rn
  from ordenes o
  left join {{ ref('snap_fin__cuenta_credito_cliente') }} s
    on o.id_cuenta_credito = s.id_cuenta_credito
   and o.fecha_creacion >= s.dbt_valid_from
   and o.fecha_creacion < coalesce(s.dbt_valid_to, '2999-12-31'::timestamp_ntz)
)
select
  id_orden_servicio,
  id_reserva_credito,
  id_cuenta_credito,
  id_cliente,
  monto_reservado_bob,
  limite_credito_bob,
  saldo_utilizado_bob,
  saldo_vencido_bob,
  credito_disponible_bob
from snap_match
qualify rn = 1
