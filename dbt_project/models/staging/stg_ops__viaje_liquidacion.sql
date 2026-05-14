select
  cast(id_liquidacion as number(38,0)) as id_liquidacion,
  cast(id_viaje as number(38,0)) as id_viaje,
  cast(adelanto_entregado_bob as number(18,4)) as adelanto_entregado_bob,
  cast(gasto_total_bob as number(18,4)) as gasto_total_bob,
  cast(saldo_a_rendir_bob as number(18,4)) as saldo_a_rendir_bob,
  cast(fecha_liquidacion as timestamp_ntz) as fecha_liquidacion
from {{ source('ops', 'viaje_liquidacion') }}
