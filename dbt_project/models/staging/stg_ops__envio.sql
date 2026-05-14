select
  cast(id_envio as number(38,0)) as id_envio,
  cast(id_orden_servicio as number(38,0)) as id_orden_servicio,
  cast(id_sucursal_origen as number(38,0)) as id_sucursal_origen,
  cast(id_sucursal_destino as number(38,0)) as id_sucursal_destino,
  cast(id_ruta_referencia as number(38,0)) as id_ruta_referencia,
  cast(fecha_registro as timestamp_ntz) as fecha_registro,
  cast(fecha_compromiso_listo_recojo as timestamp_ntz) as fecha_compromiso_listo_recojo,
  {{ clean_upper_text('tipo_carga') }} as tipo_carga,
  greatest(coalesce(cast(peso_kg as number(18,2)), 0), 0) as peso_kg,
  greatest(coalesce(cast(volumen_m3 as number(18,3)), 0), 0) as volumen_m3,
  greatest(coalesce(cast(valor_declarado_bob as number(18,4)), 0), 0) as valor_declarado_bob
from {{ source('ops', 'envio') }}
