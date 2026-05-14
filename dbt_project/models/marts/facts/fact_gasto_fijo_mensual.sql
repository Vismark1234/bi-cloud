select
  id_gasto_fijo,
  id_sucursal,
  coalesce(categoria_gasto_fijo, 'NO_DEFINIDO') as id_categoria_gasto_fijo,
  {{ date_key('periodo_mes') }} as id_fecha_periodo,
  {{ date_key('fecha_registro') }} as id_fecha_registro,
  coalesce(gasto_corporativo_flag, 0) as gasto_corporativo_flag,
  1 as cantidad_gastos,
  coalesce(monto_bob, 0) as monto_gasto_bob
from {{ ref('int_gasto_fijo_base') }}
