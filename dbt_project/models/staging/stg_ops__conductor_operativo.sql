select
  cast(id_conductor as number(38,0)) as id_conductor,
  cast(id_empleado_rrhh as number(38,0)) as id_empleado_rrhh,
  cast(id_sucursal_base as number(38,0)) as id_sucursal_base,
  {{ clean_text('ci') }} as ci_conductor,
  {{ clean_text('licencia_nro') }} as licencia_nro,
  {{ clean_upper_text('estado') }} as estado_conductor
from {{ source('ops', 'conductor_operativo') }}
