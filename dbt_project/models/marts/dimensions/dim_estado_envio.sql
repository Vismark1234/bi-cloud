select
  'NO_DEFINIDO' as id_estado_envio,
  'NO_DEFINIDO' as codigo_estado_envio,
  'NO DEFINIDO' as nombre_estado_envio,
  'SIN_CIERRE' as categoria_estado_envio,
  0 as es_entrega_flag,
  0 as es_devolucion_flag,
  0 as es_cierre_flag

union all

select distinct
  estado_final_codigo as id_estado_envio,
  estado_final_codigo as codigo_estado_envio,
  replace(estado_final_codigo, '_', ' ') as nombre_estado_envio,
  case
    when estado_final_codigo = 'ENTREGADO' then 'ENTREGA'
    when estado_final_codigo = 'DEVUELTO' then 'DEVOLUCION'
    when estado_final_codigo = 'LISTO_RECOJO' then 'RECOJO'
    else 'OPERACION'
  end as categoria_estado_envio,
  case when estado_final_codigo = 'ENTREGADO' then 1 else 0 end as es_entrega_flag,
  case when estado_final_codigo = 'DEVUELTO' then 1 else 0 end as es_devolucion_flag,
  case when estado_final_codigo in ('ENTREGADO', 'DEVUELTO') then 1 else 0 end as es_cierre_flag
from {{ ref('int_envio_cierre') }}
where estado_final_codigo is not null
  and estado_final_codigo <> 'NO_DEFINIDO'
