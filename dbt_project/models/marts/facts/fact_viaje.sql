with envios_por_viaje as (
  select
    id_viaje,
    count(distinct id_envio) as cantidad_envios_asignados
  from {{ ref('stg_ops__envio_viaje_tramo') }}
  group by 1
)
select
  v.id_viaje,
  v.id_ruta,
  v.id_vehiculo,
  v.id_conductor,
  r.id_sucursal_origen,
  r.id_sucursal_destino,
  {{ date_key('v.fecha_salida_real') }} as id_fecha_salida,
  {{ date_key('v.fecha_llegada_real') }} as id_fecha_llegada,
  1 as cantidad_viajes,
  coalesce(r.distancia_km, 0) as distancia_km,
  coalesce(vcr.capacidad_kg, veh.capacidad_kg, 0) as capacidad_kg,
  coalesce(vcr.peso_asignado_kg, 0) as peso_total_asignado_kg,
  coalesce(
    {{ safe_divide('vcr.peso_asignado_kg * 100.0', 'coalesce(vcr.capacidad_kg, veh.capacidad_kg)', 0) }},
    0
  ) as ocupacion_pct,
  coalesce(evv.cantidad_envios_asignados, 0) as cantidad_envios_asignados,
  coalesce(c.costo_operativo_total_bob, 0) as costo_operativo_total_bob,
  coalesce(c.costo_operativo_no_combustible_bob, 0) as costo_operativo_no_combustible_bob,
  coalesce(c.gasto_peaje_bob, 0) as gasto_peaje_bob,
  coalesce(c.gasto_viatico_bob, 0) as gasto_viatico_bob,
  coalesce(c.gasto_otro_bob, 0) as gasto_otro_bob,
  coalesce(c.cantidad_abastecimientos, 0) as cantidad_abastecimientos,
  coalesce(c.litros_combustible_total, 0) as litros_combustible_total,
  coalesce(c.costo_combustible_total_bob, 0) as costo_combustible_total_bob,
  coalesce(c.precio_combustible_promedio_bob_litro, 0) as precio_combustible_promedio_bob_litro,
  coalesce(
    {{ safe_divide('c.costo_operativo_total_bob', 'r.distancia_km', 0) }},
    0
  ) as costo_operativo_km_bob,
  {{ boolean_flag("v.estado_viaje = 'FINALIZADO' or v.fecha_llegada_real is not null") }} as viaje_finalizado_flag,
  case
    when coalesce(vcr.sobrecapacidad_flag, 0) = 1 then 1
    when coalesce(vcr.peso_asignado_kg, 0) > coalesce(vcr.capacidad_kg, veh.capacidad_kg, 0) then 1
    else 0
  end as sobrecapacidad_flag,
  coalesce(t.mantenimiento_correctivo_flag_30d, 0) as mantenimiento_correctivo_flag_30d,
  coalesce(t.cobertura_telemetria_pct, 0) as cobertura_telemetria_pct,
  coalesce(t.interrupciones_senal_count, 0) as interrupciones_senal_count,
  coalesce(t.alertas_totales_count, 0) as alertas_totales_count,
  coalesce(t.alertas_criticas_count, 0) as alertas_criticas_count,
  coalesce(t.alertas_mecanicas_count, 0) as alertas_mecanicas_count,
  coalesce(t.temp_max_motor_c, 0) as temp_max_motor_c,
  coalesce(t.velocidad_promedio_kmh, 0) as velocidad_promedio_kmh,
  coalesce(t.costo_mantenimiento_30d_bob, 0) as costo_mantenimiento_30d_bob
from {{ ref('stg_ops__viaje') }} v
left join {{ ref('int_ruta_base') }} r
  on v.id_ruta = r.id_ruta
left join {{ ref('stg_ops__viaje_carga_resumen') }} vcr
  on v.id_viaje = vcr.id_viaje
left join {{ ref('int_vehiculo_base') }} veh
  on v.id_vehiculo = veh.id_vehiculo
left join envios_por_viaje evv
  on v.id_viaje = evv.id_viaje
left join {{ ref('int_viaje_costos') }} c
  on v.id_viaje = c.id_viaje
left join {{ ref('int_viaje_telemetria') }} t
  on v.id_viaje = t.id_viaje
