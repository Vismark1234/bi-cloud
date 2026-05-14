select
  a.id_abastecimiento,
  a.id_vehiculo,
  v.id_sucursal_base as id_sucursal,
  a.fecha_hora_abastecimiento,
  a.tipo_combustible,
  a.litros,
  a.monto_pagado_bob,
  coalesce(
    {{ safe_divide('a.monto_pagado_bob', 'a.litros', 0) }},
    0
  ) as precio_unitario_bob,
  v.tipo_servicio,
  v.estado_vehiculo
from {{ ref('stg_ops__abastecimiento_combustible') }} a
left join {{ ref('int_vehiculo_base') }} v
  on a.id_vehiculo = v.id_vehiculo
