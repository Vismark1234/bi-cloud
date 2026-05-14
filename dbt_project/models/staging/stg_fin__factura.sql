select
  cast(id_factura as number(38,0)) as id_factura,
  {{ clean_text('nro_factura') }} as nro_factura,
  cast(id_cliente_comercial as number(38,0)) as id_cliente,
  cast(fecha_emision as timestamp_ntz) as fecha_emision,
  cast(fecha_vencimiento as date) as fecha_vencimiento,
  coalesce(cast(total_bob as number(18,4)), 0) as total_bob,
  {{ clean_upper_text('estado_cobro') }} as estado_cobro
from {{ source('fin', 'factura') }}
