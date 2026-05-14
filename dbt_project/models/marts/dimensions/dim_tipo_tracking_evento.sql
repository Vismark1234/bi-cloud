select distinct
  id_tipo_tracking_evento,
  origen_evento,
  tipo_tracking_evento,
  categoria_tracking,
  nivel_alerta
from {{ ref('int_tracking_eventos') }}
