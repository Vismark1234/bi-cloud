select
  c.id_conductor,
  c.id_conductor as id_conductor_origen,
  coalesce(c.ci_conductor, e.ci, 'NO_DEFINIDO') as ci_conductor,
  coalesce(c.licencia_nro, 'NO_DEFINIDO') as licencia_nro,
  coalesce(c.estado_conductor, 'NO_DEFINIDO') as estado_conductor,
  coalesce(s.codigo_sucursal, 'NO_DEFINIDO') as codigo_sucursal_base,
  coalesce(s.ciudad, 'NO_DEFINIDO') as ciudad_sucursal_base
from {{ ref('stg_ops__conductor_operativo') }} c
left join {{ ref('stg_fin__empleado') }} e
  on c.id_empleado_rrhh = e.id_empleado
left join {{ ref('stg_ops__sucursal') }} s
  on c.id_sucursal_base = s.id_sucursal
