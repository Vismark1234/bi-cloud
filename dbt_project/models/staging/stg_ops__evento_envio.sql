select
  cast(id_evento as number(38,0)) as id_evento,
  cast(id_envio as number(38,0)) as id_envio,
  {{ clean_upper_text('codigo_evento') }} as codigo_evento,
  cast(fecha_hora_evento as timestamp_ntz) as fecha_hora_evento,
  cast(id_sucursal as number(38,0)) as id_sucursal,
  cast(id_empleado_rrhh as number(38,0)) as id_empleado_rrhh,
  nullif({{ clean_text('observacion') }}, 'NO_DEFINIDO') as observacion
from {{ source('ops', 'evento_envio') }}
