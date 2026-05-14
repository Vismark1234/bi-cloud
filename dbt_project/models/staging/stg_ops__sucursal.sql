select
  cast(id_sucursal as number(38,0)) as id_sucursal,
  {{ clean_text('codigo') }} as codigo_sucursal,
  {{ clean_text('ciudad') }} as ciudad,
  coalesce(cast(activa as number(1,0)), 0) as activa_flag,
  {{ clean_upper_text('tipo_tenencia_inmueble') }} as tipo_tenencia_inmueble,
  coalesce(cast(monto_alquiler_mensual_bob as number(18,4)), 0) as monto_alquiler_mensual_bob
from {{ source('ops', 'sucursal') }}
