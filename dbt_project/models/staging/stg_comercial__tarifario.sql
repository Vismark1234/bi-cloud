select
  cast(id_tarifario as number(38,0)) as id_tarifario,
  {{ clean_text('nombre') }} as nombre_tarifario,
  {{ clean_upper_text('tipo_tarifario') }} as tipo_tarifario,
  cast(vigente_desde as date) as vigente_desde,
  cast(vigente_hasta as date) as vigente_hasta,
  coalesce(cast(activo as number(1,0)), 0) as activo_flag
from {{ source('comercial', 'tarifario') }}
