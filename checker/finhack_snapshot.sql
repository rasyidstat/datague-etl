-- MAIN
with main as (
select
	id,
	cat,
	score,
	min(ts) ts
from
	finhack_lb_hist
group by 1,2,3
),

main_rank as (
select
	*,
	row_number() over(partition by id, cat order by ts) r,
	row_number() over(partition by id, cat order by ts desc) r2 
from
	main
),

main_summary as (
select
	id,
	cat,
	max(case when r2 = 1 then score end) score,
	max(case when r2 = 1 then ts end) ts,
	count(*) submission_cnt,
	max(case when r = 1 then score end) score_1,
	max(case when r = 1 then ts end) ts_1,
	max(case when r = 2 then score end) score_2,
	max(case when r = 2 then ts end) ts_2,
	max(case when r = 3 then score end) score_3,
	max(case when r = 3 then ts end) ts_3
from
	main_rank
group by 1,2
),

-- REFERENCE
ref_team_name_main as (
select
	id,
	team_name,
	cat
from
	finhack_lb_hist
where
	ts = (select max(ts) from finhack_lb_hist)
),

ref_team_name_alias as (
select
	distinct
	a.id,
	a.team_name,
	a.cat
from
	finhack_lb_hist a
inner join ref_team_name_main b on
	a.id = b.id
	and a.cat = b.cat
	and a.team_name != b.team_name
),

ref_team_name as (
select
	a.id,
	a.team_name,
	a.cat,
	array_to_string(array_agg(distinct b.team_name), ', ') team_name_alias,
	count(distinct b.team_name) + 1 team_name_cnt
from
	ref_team_name_main a
left join ref_team_name_alias b on
	a.id = b.id
	and a.cat = b.cat
group by 1,2,3
)

select
	a.id,
	team_name,
	a.cat, 
	row_number() over(partition by a.cat order by score desc) as rank,
	score,
	ts,
	submission_cnt,
	count(*) over(partition by team_name) competition_cnt,
	score_1,
	score_2,
	score_3,
	ts_1,
	ts_2,
	ts_3,
	team_name_alias,
	team_name_cnt
from
	main_summary a
left join ref_team_name b on
	a.id = b.id
	and a.cat = b.cat
order by cat, score desc





