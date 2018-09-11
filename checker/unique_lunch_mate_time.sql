select
	distinct
	first_dt,
	--companion,
	count(*) over(order by first_dt) total_id
	
from
	(select companion, min(dt) first_dt from food_mate group by companion) a
	
where
	companion not in ('Brother','Sister','Father','Mother') and
	companion is not null
	
order by first_dt