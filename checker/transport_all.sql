with gojek as (
select
	service_type,
	extract(year from dt) y,
	min(dt) dt_min,
	max(dt) dt_max,
	count(*) cnt,
	sum(price) price,
	sum(discount) discount,
	sum(distance) distance,
	avg(price) price_avg,
	avg(distance) distance_avg
from
	transport_gojek
where
	extract(year from dt) >= 2017
group by 1,2
order by service_type, y
),

grab as (
select
	service_type,
	extract(year from dt) y,
	min(dt) dt_min,
	max(dt) dt_max,
	count(*) cnt,
	sum(price) price,
	sum(discount) discount,
	sum(distance) distance,
	avg(price) price_avg,
	avg(distance) distance_avg
from
	transport_grab
where
	extract(year from dt) >= 2017
	and service_type != 'GrabFood'
group by 1,2
order by service_type, y
),

final as (
select * from gojek union 
select * from grab
order by service_type, y
)

select
	service_type,
	y,
	dt_min,
	dt_max,
	cnt,
	price,
	discount,
	round(distance::decimal, 2) distance,
	round(price_avg) price_avg,
	round(distance_avg::decimal, 2) distance_avg
from
	final