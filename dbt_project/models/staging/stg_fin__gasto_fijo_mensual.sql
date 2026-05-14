select
  cast(id_gasto_fijo as number(38,0)) as id_gasto_fijo,
  cast(periodo as date) as periodo_mes,
  {{ clean_upper_text('categoria') }} as categoria_gasto_fijo,
  nullif({{ clean_text('descripcion') }}, 'NO_DEFINIDO') as descripcion,
  cast(id_sucursal_ref as number(38,0)) as id_sucursal,
  cast(monto_bob as number(18,4)) as monto_bob,
  cast(fecha_registro as timestamp_ntz) as fecha_registro,
  {{ clean_text('responsable_ci') }} as responsable_ci
from {{ source('fin', 'gasto_fijo_mensual') }}
