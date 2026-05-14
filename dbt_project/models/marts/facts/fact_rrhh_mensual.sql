select
  id_empleado,
  id_sucursal,
  periodo_mes,
  {{ date_key('periodo_mes') }} as id_fecha_periodo,
  1 as cantidad_empleados,
  coalesce(salario_base_bob, 0) as salario_base_bob,
  coalesce(horas_extra_monto_bob, 0) as horas_extra_monto_bob,
  coalesce(descuentos_bob, 0) as descuentos_bob,
  coalesce(liquido_pagable_bob, 0) as liquido_pagable_bob,
  coalesce(horas_trabajadas, 0) as horas_trabajadas,
  coalesce(horas_extra, 0) as horas_extra,
  coalesce(dias_ausencia, 0) as dias_ausencia,
  coalesce(tasa_ausentismo_pct, 0) as tasa_ausentismo_pct,
  coalesce(fte_equivalente, 0) as fte_equivalente
from {{ ref('int_rrhh_mensual_base') }}
