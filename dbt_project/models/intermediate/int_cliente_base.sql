select
  c.id_cliente,
  e.id_entidad,
  e.nombre_razon_social,
  e.numero_documento,
  c.segmento,
  e.ciudad,
  e.estado_entidad as estado_cliente,
  c.fecha_alta
from {{ ref('stg_comercial__cliente') }} c
inner join {{ ref('stg_comercial__entidad') }} e
  on c.id_entidad = e.id_entidad
