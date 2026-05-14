select
  cast(id_nomina as number(38,0)) as id_nomina,
  cast(id_empleado as number(38,0)) as id_empleado,
  cast(periodo as date) as periodo_mes,
  cast(salario_base_bob as number(18,4)) as salario_base_bob,
  cast(horas_extra_monto_bob as number(18,4)) as horas_extra_monto_bob,
  cast(descuentos_bob as number(18,4)) as descuentos_bob,
  cast(liquido_pagable_bob as number(18,4)) as liquido_pagable_bob,
  cast(fecha_pago as timestamp_ntz) as fecha_pago
from {{ source('fin', 'nomina') }}
