select
  'NO_DEFINIDO' as id_categoria_gasto_fijo,
  'NO_DEFINIDO' as categoria_gasto_fijo,
  'NO_DEFINIDO' as grupo_gasto_fijo,
  0 as es_gasto_estructural_flag,
  0 as requiere_sucursal_flag

union all

select distinct
  categoria_gasto_fijo as id_categoria_gasto_fijo,
  categoria_gasto_fijo,
  case
    when categoria_gasto_fijo in ('ALQUILER', 'SERVICIOS_BASICOS', 'SEGURO', 'IMPUESTO') then 'ESTRUCTURAL'
    when categoria_gasto_fijo = 'ADMINISTRATIVO' then 'ADMINISTRATIVO'
    else 'OTROS'
  end as grupo_gasto_fijo,
  case when categoria_gasto_fijo in ('ALQUILER', 'SERVICIOS_BASICOS', 'SEGURO', 'IMPUESTO') then 1 else 0 end as es_gasto_estructural_flag,
  case when categoria_gasto_fijo = 'ALQUILER' then 1 else 0 end as requiere_sucursal_flag
from {{ ref('stg_fin__gasto_fijo_mensual') }}
where categoria_gasto_fijo is not null
  and categoria_gasto_fijo <> 'NO_DEFINIDO'
