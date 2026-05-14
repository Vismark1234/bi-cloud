select
  cast(id_tarifa_detalle as number(38,0)) as id_tarifa_detalle,
  cast(id_tarifario as number(38,0)) as id_tarifario,
  cast(id_sucursal_origen_ref as number(38,0)) as id_sucursal_origen_ref,
  cast(id_sucursal_destino_ref as number(38,0)) as id_sucursal_destino_ref,
  {{ clean_text('origen_ciudad') }} as origen_ciudad,
  {{ clean_text('destino_ciudad') }} as destino_ciudad,
  {{ clean_upper_text('tipo_carga') }} as tipo_carga,
  cast(peso_desde_kg as number(18,2)) as peso_desde_kg,
  cast(peso_hasta_kg as number(18,2)) as peso_hasta_kg,
  cast(precio_unitario_bob as number(18,4)) as precio_unitario_bob
from {{ source('comercial', 'tarifario_detalle') }}
