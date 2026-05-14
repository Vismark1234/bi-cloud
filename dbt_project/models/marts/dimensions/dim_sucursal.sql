select
  id_sucursal,
  id_sucursal as id_sucursal_origen,
  coalesce(codigo_sucursal, 'NO_DEFINIDO') as codigo_sucursal,
  coalesce(ciudad, 'NO_DEFINIDO') as ciudad,
  coalesce(activa_flag, 0) as activa_flag,
  coalesce(tipo_tenencia_inmueble, 'NO_DEFINIDO') as tipo_tenencia_inmueble,
  coalesce(monto_alquiler_mensual_bob, 0) as monto_alquiler_mensual_bob
from {{ ref('stg_ops__sucursal') }}
