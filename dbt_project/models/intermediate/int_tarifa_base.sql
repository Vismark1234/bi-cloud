select
  td.id_tarifa_detalle,
  t.id_tarifario,
  t.tipo_tarifario,
  td.tipo_carga,
  td.id_sucursal_origen_ref,
  td.id_sucursal_destino_ref,
  td.origen_ciudad,
  td.destino_ciudad,
  td.peso_desde_kg,
  td.peso_hasta_kg,
  td.precio_unitario_bob,
  t.vigente_desde,
  t.vigente_hasta
from {{ ref('stg_comercial__tarifario_detalle') }} td
inner join {{ ref('stg_comercial__tarifario') }} t
  on td.id_tarifario = t.id_tarifario
