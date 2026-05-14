with rutas as (
  select * from {{ ref('int_ruta_base') }}
),
viajes as (
  select
    v.id_viaje,
    v.id_ruta,
    v.id_vehiculo,
    v.id_conductor,
    r.id_sucursal_origen,
    r.id_sucursal_destino
  from {{ ref('stg_ops__viaje') }} v
  left join rutas r
    on v.id_ruta = r.id_ruta
),
maint_after_alert as (
  select
    ga.id_alerta,
    case when count_if(m.tipo_mantenimiento = 'CORRECTIVO') > 0 then 1 else 0 end as mantenimiento_correctivo_30d_flag
  from {{ ref('stg_tel__gps_alerta') }} ga
  left join viajes v
    on ga.id_viaje = v.id_viaje
  left join {{ ref('stg_fin__mantenimiento_vehiculo') }} m
    on coalesce(ga.id_vehiculo, v.id_vehiculo) = m.id_vehiculo
   and m.fecha_ingreso >= ga.ts_alerta
   and m.fecha_ingreso < dateadd(day, {{ var('maintenance_window_days') }}, ga.ts_alerta)
  group by 1
),
eventos_envio as (
  select
    'EVENTO_ENVIO' as origen_evento,
    cast(ev.id_evento as varchar) as id_tracking_evento,
    ev.id_envio,
    cast(null as number(38,0)) as id_viaje,
    en.id_ruta_referencia as id_ruta,
    ev.id_sucursal,
    cast(null as number(38,0)) as id_vehiculo,
    cast(null as number(38,0)) as id_conductor,
    concat('EVENTO_ENVIO::', ev.codigo_evento) as id_tipo_tracking_evento,
    ev.codigo_evento as tipo_tracking_evento,
    'OPERACION' as categoria_tracking,
    cast(null as varchar) as nivel_alerta,
    ev.fecha_hora_evento as ts_evento,
    1 as cantidad_eventos,
    case when ev.codigo_evento = 'DEVUELTO' then 1 else 0 end as evento_critico_flag,
    0 as alerta_critica_flag,
    datediff(
      'minute',
      lag(ev.fecha_hora_evento) over (partition by ev.id_envio order by ev.fecha_hora_evento, ev.id_evento),
      ev.fecha_hora_evento
    ) as gap_desde_evento_prev_min,
    cast(null as number(18,4)) as temperatura_motor_c,
    cast(null as number(18,4)) as velocidad_kmh,
    0 as mantenimiento_correctivo_30d_flag
  from {{ ref('stg_ops__evento_envio') }} ev
  left join {{ ref('stg_ops__envio') }} en
    on ev.id_envio = en.id_envio
),
alertas_gps as (
  select
    'GPS_ALERTA' as origen_evento,
    ga.id_alerta as id_tracking_evento,
    cast(null as number(38,0)) as id_envio,
    ga.id_viaje,
    v.id_ruta,
    v.id_sucursal_origen as id_sucursal,
    coalesce(ga.id_vehiculo, v.id_vehiculo) as id_vehiculo,
    v.id_conductor,
    concat('GPS_ALERTA::', ga.tipo_alerta, '::', coalesce(ga.nivel_alerta, 'NO_DEFINIDO')) as id_tipo_tracking_evento,
    ga.tipo_alerta as tipo_tracking_evento,
    'ALERTA_GPS' as categoria_tracking,
    ga.nivel_alerta,
    ga.ts_alerta as ts_evento,
    1 as cantidad_eventos,
    case when ga.nivel_alerta in ('ALTA', 'CRITICA') then 1 else 0 end as evento_critico_flag,
    case when ga.nivel_alerta in ('ALTA', 'CRITICA') then 1 else 0 end as alerta_critica_flag,
    datediff(
      'minute',
      lag(ga.ts_alerta) over (partition by ga.id_viaje order by ga.ts_alerta, ga.id_alerta),
      ga.ts_alerta
    ) as gap_desde_evento_prev_min,
    cast(null as number(18,4)) as temperatura_motor_c,
    cast(null as number(18,4)) as velocidad_kmh,
    coalesce(ma.mantenimiento_correctivo_30d_flag, 0) as mantenimiento_correctivo_30d_flag
  from {{ ref('stg_tel__gps_alerta') }} ga
  left join viajes v
    on ga.id_viaje = v.id_viaje
  left join maint_after_alert ma
    on ga.id_alerta = ma.id_alerta
),
tracks_ordenados as (
  select
    gt.*,
    v.id_ruta,
    v.id_sucursal_origen,
    coalesce(gt.id_vehiculo, v.id_vehiculo) as id_vehiculo_final,
    coalesce(gt.id_conductor, v.id_conductor) as id_conductor_final,
    lag(gt.ts_track) over (partition by gt.id_viaje order by gt.ts_track, gt.id_track) as prev_ts_track
  from {{ ref('stg_tel__gps_track') }} gt
  left join viajes v
    on gt.id_viaje = v.id_viaje
  where gt.id_viaje is not null
),
temp_critica as (
  select
    'GPS_TRACK' as origen_evento,
    concat('TEMP_', id_track) as id_tracking_evento,
    cast(null as number(38,0)) as id_envio,
    id_viaje,
    id_ruta,
    id_sucursal_origen as id_sucursal,
    id_vehiculo_final as id_vehiculo,
    id_conductor_final as id_conductor,
    'GPS_TRACK::TEMP_MOTOR_CRITICA' as id_tipo_tracking_evento,
    'TEMP_MOTOR_CRITICA' as tipo_tracking_evento,
    'TELEMETRIA' as categoria_tracking,
    'CRITICA' as nivel_alerta,
    ts_track as ts_evento,
    1 as cantidad_eventos,
    1 as evento_critico_flag,
    1 as alerta_critica_flag,
    datediff('minute', prev_ts_track, ts_track) as gap_desde_evento_prev_min,
    temp_motor_c as temperatura_motor_c,
    velocidad_kmh,
    0 as mantenimiento_correctivo_30d_flag
  from tracks_ordenados
  where temp_motor_c >= {{ var('critical_temp_motor_c') }}
),
gaps_senal as (
  select
    'GPS_TRACK' as origen_evento,
    concat('GAP_', id_track) as id_tracking_evento,
    cast(null as number(38,0)) as id_envio,
    id_viaje,
    id_ruta,
    id_sucursal_origen as id_sucursal,
    id_vehiculo_final as id_vehiculo,
    id_conductor_final as id_conductor,
    'GPS_TRACK::CORTE_SENAL' as id_tipo_tracking_evento,
    'CORTE_SENAL' as tipo_tracking_evento,
    'TELEMETRIA' as categoria_tracking,
    'ALTA' as nivel_alerta,
    ts_track as ts_evento,
    1 as cantidad_eventos,
    1 as evento_critico_flag,
    1 as alerta_critica_flag,
    datediff('minute', prev_ts_track, ts_track) as gap_desde_evento_prev_min,
    temp_motor_c as temperatura_motor_c,
    velocidad_kmh,
    0 as mantenimiento_correctivo_30d_flag
  from tracks_ordenados
  where datediff('minute', prev_ts_track, ts_track) > {{ var('telemetry_gap_minutes') }}
)
select * from eventos_envio
union all
select * from alertas_gps
union all
select * from temp_critica
union all
select * from gaps_senal
