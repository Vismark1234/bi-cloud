select
  id_abastecimiento,
  id_vehiculo,
  id_sucursal,
  coalesce(tipo_combustible, 'NO_DEFINIDO') as id_tipo_combustible,
  {{ date_key('fecha_hora_abastecimiento') }} as id_fecha_abastecimiento,
  {{ time_key('fecha_hora_abastecimiento') }} as id_hora_abastecimiento,
  1 as cantidad_abastecimientos,
  coalesce(litros, 0) as litros_combustible,
  coalesce(monto_pagado_bob, 0) as monto_combustible_bob,
  coalesce(precio_unitario_bob, 0) as precio_unitario_bob
from {{ ref('int_abastecimiento_base') }}
