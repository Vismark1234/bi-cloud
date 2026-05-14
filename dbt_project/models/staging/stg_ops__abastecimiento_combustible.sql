select
  cast(id_abastecimiento as number(38,0)) as id_abastecimiento,
  cast(id_vehiculo as number(38,0)) as id_vehiculo,
  cast(fecha_hora_abastecimiento as timestamp_ntz) as fecha_hora_abastecimiento,
  cast(litros as number(18,4)) as litros,
  cast(monto_pagado_bob as number(18,4)) as monto_pagado_bob,
  {{ clean_upper_text('tipo_combustible') }} as tipo_combustible
from {{ source('ops', 'abastecimiento_combustible') }}
