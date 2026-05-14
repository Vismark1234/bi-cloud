select
  id_mantenimiento,
  id_vehiculo,
  id_sucursal,
  coalesce(tipo_mantenimiento, 'NO_DEFINIDO') as id_tipo_mantenimiento,
  {{ date_key('fecha_ingreso') }} as id_fecha_ingreso,
  {{ date_key('fecha_salida') }} as id_fecha_salida,
  1 as cantidad_mantenimientos,
  coalesce(costo_repuestos_bob, 0) as costo_repuestos_bob,
  coalesce(costo_mano_obra_bob, 0) as costo_mano_obra_bob,
  coalesce(costo_total_bob, 0) as costo_total_bob,
  {{ boolean_flag('fecha_salida is not null') }} as mantenimiento_cerrado_flag,
  coalesce(datediff('hour', fecha_ingreso, fecha_salida), 0) as duracion_mantenimiento_horas
from {{ ref('int_mantenimiento_base') }}
