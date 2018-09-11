select
	companion,
	count(*) cnt
	--count(distinct companion) lunch_mate
	
from
	food_mate
	
where
	companion not in ('Brother','Sister','Father','Mother') and
	companion is not null
	
group by 1
order by cnt desc