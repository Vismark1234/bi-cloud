with viajes as (
  select
    v.id_viaje,
    v.id_ruta,
    v.id_vehiculo,
    v.id_conductor,
    v.fecha_salida_real,
    coalesce(v.fecha_llegada_real, current_timestamp()::timestamp_ntz) as fecha_fin
  from {{ ref('stg_ops__viaje') }} v
),
tracks as (
  select
    gt.id_viaje,
    gt.id_vehiculo,
    gt.id_conductor,
    gt.ts_track,
    gt.velocidad_kmh,
    gt.temp_motor_c,
    lag(gt.ts_track) over (
      partition by gt.id_viaje
      order by gt.ts_track
    ) as prev_ts_track
  from {{ ref('stg_tel__gps_track') }} gt
  where gt.id_viaje is not null
),
tracks_agg as (
  select
    id_viaje,
    count(*) as cantidad_tracks,
    avg(velocidad_kmh) as velocidad_promedio_kmh,
    max(temp_motor_c) as temp_max_motor_c,
    count_if(datediff('minute', prev_ts_track, ts_track) > {{ var('telemetry_gap_minutes') }}) as interrupciones_senal_count
  from tracks
  group by 1
),
alerts_agg as (
  select
    id_viaje,
    count(*) as alertas_totales_count,
    count_if(nivel_alerta in ('ALTA', 'CRITICA')) as alertas_criticas_count,
    count_if(tipo_alerta like '%TEMP%' or tipo_alerta like '%MOTOR%') as alertas_mecanicas_count
  from {{ ref('stg_tel__gps_alerta') }}
  where id_viaje is not null
  group by 1
),
expected as (
  select
    id_viaje,
    greatest(
      1,
      floor(greatest(datediff('minute', fecha_salida_real, fecha_fin), 0) / {{ var('telemetry_expected_interval_minutes') }}) + 1
    ) as expected_tracks
  from viajes
),
maintenance as (
  select
    v.id_viaje,
    count_if(m.tipo_mantenimiento = 'CORRECTIVO') as mantenimientos_correctivos_30d,
    sum(m.costo_total_bob) as costo_mantenimiento_30d_bob
  from viajes v
  left join {{ ref('stg_fin__mantenimiento_vehiculo') }} m
    on v.id_vehiculo = m.id_vehiculo
   and m.fecha_ingreso >= v.fecha_fin
   and m.fecha_ingreso < dateadd(day, {{ var('maintenance_window_days') }}, v.fecha_fin)
  group by 1
)
select
  v.id_viaje,
  coalesce(
    least(
      100,
      {{ safe_divide('ta.cantidad_tracks * 100.0', 'ex.expected_tracks', 0) }}
    ),
    0
  ) as cobertura_telemetria_pct,
  coalesce(ta.interrupciones_senal_count, 0) as interrupciones_senal_count,
  coalesce(al.alertas_totales_count, 0) as alertas_totales_count,
  coalesce(al.alertas_criticas_count, 0) as alertas_criticas_count,
  coalesce(al.alertas_mecanicas_count, 0) as alertas_mecanicas_count,
  coalesce(ta.temp_max_motor_c, 0) as temp_max_motor_c,
  coalesce(ta.velocidad_promedio_kmh, 0) as velocidad_promedio_kmh,
  case when coalesce(mt.mantenimientos_correctivos_30d, 0) > 0 then 1 else 0 end as mantenimiento_correctivo_flag_30d,
  coalesce(mt.costo_mantenimiento_30d_bob, 0) as costo_mantenimiento_30d_bob
from viajes v
left join tracks_agg ta
  on v.id_viaje = ta.id_viaje
left join alerts_agg al
  on v.id_viaje = al.id_viaje
left join expected ex
  on v.id_viaje = ex.id_viaje
left join maintenance mt
  on v.id_viaje = mt.id_viaje
