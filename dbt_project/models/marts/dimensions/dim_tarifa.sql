select
  0 as id_tarifa_detalle,
  0 as id_tarifario_origen,
  'MANUAL' as tipo_tarifario,
  'NO_APLICA' as tipo_carga,
  'NO_DEFINIDO' as origen_ciudad,
  'NO_DEFINIDO' as destino_ciudad,
  0::number(18,2) as peso_desde_kg,
  0::number(18,2) as peso_hasta_kg,
  0::number(18,4) as precio_unitario_bob,
  null::date as vigente_desde,
  null::date as vigente_hasta

union all

select
  id_tarifa_detalle,
  id_tarifario as id_tarifario_origen,
  coalesce(tipo_tarifario, 'NO_DEFINIDO') as tipo_tarifario,
  coalesce(tipo_carga, 'NO_DEFINIDO') as tipo_carga,
  coalesce(origen_ciudad, 'NO_DEFINIDO') as origen_ciudad,
  coalesce(destino_ciudad, 'NO_DEFINIDO') as destino_ciudad,
  coalesce(peso_desde_kg, 0) as peso_desde_kg,
  coalesce(peso_hasta_kg, 0) as peso_hasta_kg,
  coalesce(precio_unitario_bob, 0) as precio_unitario_bob,
  vigente_desde,
  vigente_hasta
from {{ ref('int_tarifa_base') }}
