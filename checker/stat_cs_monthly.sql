select
	extract(month from dt) m,
	count(*) cnt
	
from
	raw_taplog
	
where
	cat2 = 'H'
	
group by 1
order by m