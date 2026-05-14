select
  id_cliente,
  id_cliente as id_cliente_origen,
  id_entidad as id_entidad_origen,
  coalesce(nombre_razon_social, 'NO_DEFINIDO') as nombre_razon_social,
  coalesce(numero_documento, 'NO_DEFINIDO') as numero_documento,
  coalesce(segmento, 'NO_DEFINIDO') as segmento,
  coalesce(ciudad, 'NO_DEFINIDO') as ciudad,
  coalesce(estado_cliente, 'NO_DEFINIDO') as estado_cliente,
  fecha_alta
from {{ ref('int_cliente_base') }}
