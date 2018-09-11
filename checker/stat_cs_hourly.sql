select
	extract(hour from ts) h,
	count(*) cnt
	
from
	raw_taplog
	
where
	cat2 = 'H'
	
group by 1
order by cnt desc