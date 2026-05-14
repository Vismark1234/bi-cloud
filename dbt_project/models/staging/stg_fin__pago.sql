select
  cast(id_pago as number(38,0)) as id_pago,
  cast(id_factura as number(38,0)) as id_factura,
  cast(monto_bob as number(18,4)) as monto_bob,
  cast(fecha_pago as timestamp_ntz) as fecha_pago,
  {{ clean_upper_text('metodo_pago') }} as metodo_pago
from {{ source('fin', 'pago') }}
