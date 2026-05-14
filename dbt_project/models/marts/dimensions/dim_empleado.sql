select
  e.id_empleado,
  e.id_empleado as id_empleado_origen,
  coalesce(e.ci, 'NO_DEFINIDO') as ci,
  coalesce(e.nombre_completo, 'NO_DEFINIDO') as nombre_completo,
  coalesce(e.cargo, 'NO_DEFINIDO') as cargo,
  coalesce(e.area, 'NO_DEFINIDO') as area,
  e.fecha_ingreso,
  coalesce(e.estado_laboral, 'NO_DEFINIDO') as estado_laboral,
  coalesce(s.codigo_sucursal, 'NO_DEFINIDO') as codigo_sucursal_trabajo,
  coalesce(s.ciudad, 'NO_DEFINIDO') as ciudad_sucursal_trabajo
from {{ ref('stg_fin__empleado') }} e
left join {{ ref('stg_ops__sucursal') }} s
  on e.id_sucursal = s.id_sucursal
