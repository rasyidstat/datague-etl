with main as (
select
	*, row_number() over(partition by cat) rank
from
	finhack_lb_hist
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