select
  m.id_mantenimiento,
  m.id_vehiculo,
  v.id_sucursal_base as id_sucursal,
  m.tipo_mantenimiento,
  m.descripcion,
  m.fecha_ingreso,
  m.fecha_salida,
  m.costo_repuestos_bob,
  m.costo_mano_obra_bob,
  m.costo_total_bob,
  m.proveedor,
  m.nro_factura_proveedor
from {{ ref('stg_fin__mantenimiento_vehiculo') }} m
left join {{ ref('int_vehiculo_base') }} v
  on m.id_vehiculo = v.id_vehiculo
