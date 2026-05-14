select
  origen_evento,
  id_tracking_evento,
  count(*) as repeticiones
from {{ ref('fact_tracking_evento') }}
group by 1, 2
having count(*) > 1
