select
  id_factura,
  id_factura as id_factura_origen,
  coalesce(nro_factura, 'NO_DEFINIDO') as nro_factura,
  fecha_emision,
  fecha_vencimiento,
  coalesce(total_bob, 0) as total_bob,
  coalesce(estado_cobro, 'NO_DEFINIDO') as estado_cobro
from {{ ref('stg_fin__factura') }}
