with calendario as (
  select
    dateadd(day, seq4(), to_date('{{ var("calendar_start") }}')) as fecha
  from table(generator(rowcount => 10000))
)
select
  {{ date_key('fecha') }} as id_fecha,
  fecha,
  year(fecha) as anio,
  quarter(fecha) as trimestre,
  month(fecha) as mes,
  upper(to_char(fecha, 'MON')) as nombre_mes,
  weekiso(fecha) as semana_iso,
  day(fecha) as dia_mes,
  dayofweekiso(fecha) as dia_semana,
  case when dayofweekiso(fecha) in (6, 7) then 1 else 0 end as fin_semana_flag
from calendario
where fecha <= to_date('{{ var("calendar_end") }}')
