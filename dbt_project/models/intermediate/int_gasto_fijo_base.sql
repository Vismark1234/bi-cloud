select
  g.id_gasto_fijo,
  g.periodo_mes,
  g.categoria_gasto_fijo,
  g.descripcion,
  g.id_sucursal,
  s.codigo_sucursal,
  s.ciudad,
  s.tipo_tenencia_inmueble,
  s.monto_alquiler_mensual_bob,
  g.monto_bob,
  g.fecha_registro,
  g.responsable_ci,
  case when g.id_sucursal is null then 1 else 0 end as gasto_corporativo_flag
from {{ ref('stg_fin__gasto_fijo_mensual') }} g
left join {{ ref('stg_ops__sucursal') }} s
  on g.id_sucursal = s.id_sucursal
