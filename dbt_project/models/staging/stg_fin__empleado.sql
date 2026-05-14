select
  cast(id_empleado as number(38,0)) as id_empleado,
  {{ clean_text('ci') }} as ci,
  {{ clean_text('nombres_apellidos') }} as nombre_completo,
  {{ clean_upper_text('cargo') }} as cargo,
  {{ clean_upper_text('area') }} as area,
  cast(id_sucursal_ref as number(38,0)) as id_sucursal,
  cast(fecha_ingreso as date) as fecha_ingreso,
  {{ clean_upper_text('estado_laboral') }} as estado_laboral
from {{ source('fin', 'empleado') }}
