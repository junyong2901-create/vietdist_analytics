create view dwh."mart_sales_vs_target" as 
with 
actual_sales as (
	select 
		order_year as year,
		order_month as month,
		sum(quantity ) as actual_quantity,
		sum(net_amount ) as actual_sales
	from dwh.fact_sales
	where delivery_status <> 'Cancelled'
	group by order_year, order_month
), 

target_sales as (
	select 
		year,
		month,
		sum(target_quantity) as target_quantity,
		sum(target_revenue) as target_revenue
	from dwh.fact_targets
	group by year, month
	order by month
)

select
	a.year as year,
	a.month as month,
	t.target_quantity as target_quantity,
	t.target_revenue as target_revenue,
	a.actual_quantity as actual_quantity,
	a.actual_sales as actual_sales
from actual_sales as a
inner join target_sales as t
on a.month = t.month
order by month