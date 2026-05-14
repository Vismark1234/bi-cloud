select
  cast(id_reserva_credito as number(38,0)) as id_reserva_credito,
  cast(id_cuenta_credito as number(38,0)) as id_cuenta_credito,
  cast(id_cliente_comercial as number(38,0)) as id_cliente,
  cast(monto_reservado_bob as number(18,4)) as monto_reservado_bob,
  upper(trim(estado)) as estado_reserva,
  cast(fecha_creacion as timestamp_ntz) as fecha_creacion,
  cast(fecha_expira as timestamp_ntz) as fecha_expira
from {{ source('fin', 'reserva_credito') }}
