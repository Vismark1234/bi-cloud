select
  'NO_DEFINIDO' as id_tipo_combustible,
  'NO_DEFINIDO' as tipo_combustible,
  'NO_DEFINIDA' as categoria_energia,
  0 as es_fosil_flag

union all

select distinct
  tipo_combustible as id_tipo_combustible,
  tipo_combustible,
  case
    when tipo_combustible in ('DIESEL', 'GASOLINA') then 'FOSIL'
    when tipo_combustible = 'GNV' then 'GAS'
    else 'OTRA'
  end as categoria_energia,
  case when tipo_combustible in ('DIESEL', 'GASOLINA', 'GNV') then 1 else 0 end as es_fosil_flag
from {{ ref('stg_ops__abastecimiento_combustible') }}
where tipo_combustible is not null
  and tipo_combustible <> 'NO_DEFINIDO'
