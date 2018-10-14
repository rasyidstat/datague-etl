with main as (
select
	id, team_name, cat, score, min(ts) ts
from
	finhack_lb_hist
where cat = 'atm'
group by 1,2,3,4
order by score desc
)
select
	*, dense_rank() over(order by score desc)
from
	main