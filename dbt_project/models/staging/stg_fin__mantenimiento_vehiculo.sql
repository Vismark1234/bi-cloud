select
  cast(id_mantenimiento as number(38,0)) as id_mantenimiento,
  cast(id_vehiculo_ops as number(38,0)) as id_vehiculo,
  {{ clean_upper_text('tipo_mantenimiento') }} as tipo_mantenimiento,
  nullif({{ clean_text('descripcion') }}, 'NO_DEFINIDO') as descripcion,
  cast(fecha_ingreso as timestamp_ntz) as fecha_ingreso,
  cast(fecha_salida as timestamp_ntz) as fecha_salida,
  cast(costo_repuestos_bob as number(18,4)) as costo_repuestos_bob,
  cast(costo_mano_obra_bob as number(18,4)) as costo_mano_obra_bob,
  cast(costo_total_bob as number(18,4)) as costo_total_bob,
  nullif({{ clean_text('proveedor') }}, 'NO_DEFINIDO') as proveedor,
  nullif({{ clean_text('nro_factura_proveedor') }}, 'NO_DEFINIDO') as nro_factura_proveedor
from {{ source('fin', 'mantenimiento_vehiculo') }}
