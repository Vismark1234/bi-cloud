select
  v.id_vehiculo,
  v.placa,
  f.tipo_servicio,
  v.capacidad_kg,
  v.fecha_compra,
  v.monto_compra_bob,
  v.estado_vehiculo,
  f.id_sucursal_base
from {{ ref('stg_ops__vehiculo') }} v
left join {{ ref('stg_ops__flota') }} f
  on v.id_flota = f.id_flota
