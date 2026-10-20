create view dwh."mart_distributor_performance" as 
with distributors_pfm as (
	select 
		distributor_id,
		sum(qty_ordered) as total_qty_ordered,
		sum(qty_delivered) as total_qty_delivered,
		ROUND(sum(qty_delivered)/sum(qty_ordered) *100.00,2) as fill_rate_pct,
		sum(gross_amount) as total_gross_amount,
		sum(delivered_amount) as total_delivered_amount
	from staging.stg_distributor_orders
	group by distributor_id
	order by distributor_id
)
select 
	d.*,
	p.total_qty_ordered,
	p.total_qty_delivered,
	p.fill_rate_pct,
	p.total_gross_amount,
	p.total_delivered_amount
from staging.stg_distributors as d 
inner join distributors_pfm as p 
on d.distributor_id = p.distributor_id
order by d.distributor_id