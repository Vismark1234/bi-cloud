select
  cast(id_vehiculo as number(38,0)) as id_vehiculo,
  cast(id_flota as number(38,0)) as id_flota,
  {{ clean_text('placa') }} as placa,
  cast(capacidad_kg as number(18,2)) as capacidad_kg,
  cast(fecha_compra as date) as fecha_compra,
  cast(monto_compra_bob as number(18,4)) as monto_compra_bob,
  {{ clean_upper_text('estado') }} as estado_vehiculo
from {{ source('ops', 'vehiculo') }}
