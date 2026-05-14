select
  cast(id_asistencia as number(38,0)) as id_asistencia,
  cast(id_empleado as number(38,0)) as id_empleado,
  cast(fecha as date) as fecha,
  cast(hora_entrada as time) as hora_entrada,
  cast(hora_salida as time) as hora_salida,
  cast(horas_trabajadas as number(18,2)) as horas_trabajadas,
  cast(horas_extra as number(18,2)) as horas_extra,
  {{ clean_upper_text('tipo_jornada') }} as tipo_jornada,
  {{ clean_upper_text('estado_asistencia') }} as estado_asistencia
from {{ source('fin', 'asistencia_empleado') }}
