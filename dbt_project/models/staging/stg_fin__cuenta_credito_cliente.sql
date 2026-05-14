select
  cast(id_cuenta_credito as number(38,0)) as id_cuenta_credito,
  cast(id_cliente_comercial as number(38,0)) as id_cliente,
  cast(limite_credito_bob as number(18,4)) as limite_credito_bob,
  cast(saldo_utilizado_bob as number(18,4)) as saldo_utilizado_bob,
  cast(saldo_vencido_bob as number(18,4)) as saldo_vencido_bob,
  cast(credito_disponible_bob as number(18,4)) as credito_disponible_bob,
  cast(fecha_corte as timestamp_ntz) as fecha_corte
from {{ source('fin', 'cuenta_credito_cliente') }}
