select
  'NO_DEFINIDO' as id_tipo_mantenimiento,
  'NO_DEFINIDO' as tipo_mantenimiento,
  'NO_DEFINIDO' as categoria_mantenimiento,
  0 as es_programado_flag,
  0 as es_correctivo_flag

union all

select distinct
  tipo_mantenimiento as id_tipo_mantenimiento,
  tipo_mantenimiento,
  case
    when tipo_mantenimiento = 'PREVENTIVO' then 'PROGRAMADO'
    when tipo_mantenimiento = 'INSPECCION' then 'CONTROL'
    when tipo_mantenimiento = 'CORRECTIVO' then 'INCIDENTE'
    else 'OTRO'
  end as categoria_mantenimiento,
  case when tipo_mantenimiento in ('PREVENTIVO', 'INSPECCION') then 1 else 0 end as es_programado_flag,
  case when tipo_mantenimiento = 'CORRECTIVO' then 1 else 0 end as es_correctivo_flag
from {{ ref('stg_fin__mantenimiento_vehiculo') }}
where tipo_mantenimiento is not null
  and tipo_mantenimiento <> 'NO_DEFINIDO'
