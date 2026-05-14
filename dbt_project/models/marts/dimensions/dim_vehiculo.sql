select
  v.id_vehiculo,
  v.id_vehiculo as id_vehiculo_origen,
  coalesce(v.placa, 'NO_DEFINIDO') as placa,
  coalesce(v.tipo_servicio, 'NO_DEFINIDO') as tipo_servicio,
  coalesce(v.capacidad_kg, 0) as capacidad_kg,
  v.fecha_compra,
  coalesce(v.monto_compra_bob, 0) as monto_compra_bob,
  coalesce(v.estado_vehiculo, 'NO_DEFINIDO') as estado_vehiculo,
  coalesce(s.codigo_sucursal, 'NO_DEFINIDO') as codigo_sucursal_base,
  coalesce(s.ciudad, 'NO_DEFINIDO') as ciudad_sucursal_base
from {{ ref('int_vehiculo_base') }} v
left join {{ ref('stg_ops__sucursal') }} s
  on v.id_sucursal_base = s.id_sucursal
