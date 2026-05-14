select
  r.id_ruta,
  r.codigo_ruta,
  r.id_sucursal_origen,
  r.id_sucursal_destino,
  so.ciudad as ciudad_origen,
  sd.ciudad as ciudad_destino,
  r.distancia_km
from {{ ref('stg_ops__ruta') }} r
left join {{ ref('stg_ops__sucursal') }} so
  on r.id_sucursal_origen = so.id_sucursal
left join {{ ref('stg_ops__sucursal') }} sd
  on r.id_sucursal_destino = sd.id_sucursal
