with horas as (
  select
    seq4() as minuto_del_dia
  from table(generator(rowcount => 1440))
)
select
  ((floor(minuto_del_dia / 60) * 100) + mod(minuto_del_dia, 60))::number(10,0) as id_hora,
  floor(minuto_del_dia / 60)::number(10,0) as hora,
  mod(minuto_del_dia, 60)::number(10,0) as minuto,
  case
    when floor(minuto_del_dia / 60) between 0 and 5 then 'MADRUGADA'
    when floor(minuto_del_dia / 60) between 6 and 11 then 'MANANA'
    when floor(minuto_del_dia / 60) between 12 and 17 then 'TARDE'
    else 'NOCHE'
  end as franja_horaria
from horas
