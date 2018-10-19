select
	ts,
	count(distinct id) participant_cnt
from
	finhack_lb_hist
where
	cat = 'atm'
group by 1
order by ts desc