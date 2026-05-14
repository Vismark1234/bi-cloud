select
  cast(id_contrato as number(38,0)) as id_contrato,
  cast(id_cliente as number(38,0)) as id_cliente,
  {{ clean_upper_text('forma_pago') }} as forma_pago,
  {{ clean_upper_text('estado') }} as estado_contrato,
  cast(fecha_inicio as date) as fecha_inicio,
  cast(fecha_fin as date) as fecha_fin
from {{ source('comercial', 'contrato_cliente') }}
