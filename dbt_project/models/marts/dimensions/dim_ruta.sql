select
  r.id_ruta,
  r.id_ruta as id_ruta_origen,
  coalesce(r.codigo_ruta, 'NO_DEFINIDO') as codigo_ruta,
  coalesce(so.codigo_sucursal, 'NO_DEFINIDO') as codigo_sucursal_origen,
  coalesce(r.ciudad_origen, 'NO_DEFINIDO') as ciudad_origen,
  coalesce(sd.codigo_sucursal, 'NO_DEFINIDO') as codigo_sucursal_destino,
  coalesce(r.ciudad_destino, 'NO_DEFINIDO') as ciudad_destino,
  coalesce(r.distancia_km, 0) as distancia_km
from {{ ref('int_ruta_base') }} r
left join {{ ref('stg_ops__sucursal') }} so
  on r.id_sucursal_origen = so.id_sucursal
left join {{ ref('stg_ops__sucursal') }} sd
  on r.id_sucursal_destino = sd.id_sucursal
