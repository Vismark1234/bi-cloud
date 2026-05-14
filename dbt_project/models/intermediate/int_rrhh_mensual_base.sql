with asistencia as (
  select
    id_empleado,
    date_trunc('month', fecha)::date as periodo_mes,
    count(*) as dias_controlados,
    count_if(estado_asistencia = 'AUSENTE') as dias_ausencia,
    sum(coalesce(horas_trabajadas, 0)) as horas_trabajadas,
    sum(coalesce(horas_extra, 0)) as horas_extra
  from {{ ref('stg_fin__asistencia_empleado') }}
  group by 1, 2
),
nomina as (
  select
    id_empleado,
    periodo_mes,
    salario_base_bob,
    horas_extra_monto_bob,
    descuentos_bob,
    liquido_pagable_bob
  from {{ ref('stg_fin__nomina') }}
),
base as (
  select
    coalesce(n.id_empleado, a.id_empleado) as id_empleado,
    coalesce(n.periodo_mes, a.periodo_mes) as periodo_mes,
    n.salario_base_bob,
    n.horas_extra_monto_bob,
    n.descuentos_bob,
    n.liquido_pagable_bob,
    a.dias_controlados,
    a.dias_ausencia,
    a.horas_trabajadas,
    a.horas_extra
  from nomina n
  full outer join asistencia a
    on n.id_empleado = a.id_empleado
   and n.periodo_mes = a.periodo_mes
)
select
  b.id_empleado,
  e.id_sucursal,
  b.periodo_mes,
  coalesce(b.salario_base_bob, 0) as salario_base_bob,
  coalesce(b.horas_extra_monto_bob, 0) as horas_extra_monto_bob,
  coalesce(b.descuentos_bob, 0) as descuentos_bob,
  coalesce(b.liquido_pagable_bob, 0) as liquido_pagable_bob,
  coalesce(b.horas_trabajadas, 0) as horas_trabajadas,
  coalesce(b.horas_extra, 0) as horas_extra,
  coalesce(b.dias_ausencia, 0) as dias_ausencia,
  coalesce(
    {{ safe_divide('b.dias_ausencia * 100.0', 'b.dias_controlados', 0) }},
    0
  ) as tasa_ausentismo_pct,
  coalesce(
    {{ safe_divide('b.horas_trabajadas', var('monthly_fte_hours'), 0) }},
    0
  ) as fte_equivalente
from base b
left join {{ ref('stg_fin__empleado') }} e
  on b.id_empleado = e.id_empleado
