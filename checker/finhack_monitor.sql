with main as (
select
	*, row_number() over(partition by cat order by score desc) rank
from
	finhack_lb_hist
where
	ts = (select max(ts) from finhack_lb_hist)
)

select
	cat,
	count(distinct team_name) participant_cnt,
	max(score) score_max,
	min(case when rank <= 5 then score end) score_min
from
	main
group by 
	cat