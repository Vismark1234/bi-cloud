select
  id_empleado,
  periodo_mes,
  count(*) as repeticiones
from {{ ref('fact_rrhh_mensual') }}
group by 1, 2
having count(*) > 1
