select
	dt,
	case when lead(dt) over() is not null then lead(dt) over() else current_date end dt2,
	date_part('day', 
		age(case when lead(dt) over() is not null 
			then lead(dt) over() else current_date end, dt)) diff
	
from
	raw_taplog
	
where
	cat2 = 'H'
	
order by dt desc