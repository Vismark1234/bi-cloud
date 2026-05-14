select
  p.id_pago,
  p.id_factura,
  f.id_cliente,
  p.metodo_pago as id_metodo_pago,
  p.fecha_pago,
  f.fecha_emision,
  f.fecha_vencimiento,
  p.monto_bob
from {{ ref('stg_fin__pago') }} p
left join {{ ref('stg_fin__factura') }} f
  on p.id_factura = f.id_factura
