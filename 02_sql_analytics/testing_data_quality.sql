-- Kiểm tra primary key có unique không?
select
	count(*) as total_rows,
	count(customer_id) as non_null_pk_count,
	count(distinct customer_id) as distinct_pk_count
from staging.stg_customers;

-- Kiểm tra primary key có unique không?
select
	count(*) as total_rows,
	count(order_id) as non_null_pk_count,
	count(distinct order_id) as distinct_pk_count
from staging.stg_distributor_orders;

select 
	order_id, 
	product_id ,
	count(*)
from staging.stg_sales_transaction
group by 1,2
having count(*) > 1;

select 
	count(*) as total_rows,
	count(territory_id  ) as non_null_pk_count,
	count(distinct territory_id) as distinct_pk_count
from staging.stg_territory_mapping;

select *
from staging.stg_territory_mapping;