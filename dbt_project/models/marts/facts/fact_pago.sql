select
  id_pago,
  id_factura,
  id_cliente,
  coalesce(id_metodo_pago, 'NO_DEFINIDO') as id_metodo_pago,
  {{ date_key('fecha_pago') }} as id_fecha_pago,
  1 as cantidad_pagos,
  {{ boolean_flag("cast(fecha_pago as date) > fecha_vencimiento") }} as pago_tardio_flag,
  coalesce(monto_bob, 0) as monto_bob,
  coalesce(datediff('day', cast(fecha_emision as date), cast(fecha_pago as date)), 0) as dias_cobro_desde_emision,
  greatest(coalesce(datediff('day', fecha_vencimiento, cast(fecha_pago as date)), 0), 0) as dias_mora_pago
from {{ ref('int_pago_base') }}
