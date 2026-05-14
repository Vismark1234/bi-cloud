select
  'NO_DEFINIDO' as id_metodo_pago,
  'NO_DEFINIDO' as metodo_pago

union all

select distinct
  metodo_pago as id_metodo_pago,
  metodo_pago
from {{ ref('stg_fin__pago') }}
where metodo_pago is not null
  and metodo_pago <> 'NO_DEFINIDO'
