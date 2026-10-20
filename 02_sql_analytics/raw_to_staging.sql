-- Create stg_sales_transactions
create table staging."stg_sales_transaction" as 
select 
	order_id,
	to_timestamp(order_date, 'YYYY-MM-DD') as order_date, 
	order_month,
	order_quarter,
	order_year,
	customer_id,
	region,
	province,
	channel,
	employee_id,
	product_id,
	product_category,
	quantity,
	unit_price,
	discount_pct,
	discount_amount,
	gross_amount,
	net_amount,
	delivery_status,
	payment_method,
	payment_status
from raw.raw_sales_transactions
order by order_id;

-- Create stg_customers
create table staging."stg_customers" as 
select 
	customer_id,
	customer_name,
	customer_type,
	channel,
	province,
	region,
	address,
	concat('0', cast(phone as text)) as phone,
	coalesce(tax_code::text,'Unknown') as tax_code,
	to_timestamp(join_date, 'YYYY-MM_DD') as join_date,
	credit_limit,
	status
from raw.raw_customers;

-- Create stg_distributors
create table staging."stg_distributors" as 
select 
	distributor_id,
	distributor_name,
	tier,
	channel,
	province,
	region,
	contact_person,
	concat('0', cast(phone as text)) as phone,
	email,
	cast(tax_code as text) as tax_code,
	to_timestamp(join_date, 'YYYY-MM-DD') as join_date,
	credit_limit,
	status,
	assigned_supervisor_id
from raw.raw_distributor_master;

-- create stg_returns
create table staging."stg_returns" as 
select
	return_id,
	original_order_id,
	to_timestamp(return_date, 'YYYY-MM-DD') as return_date,
	return_month,
	customer_id,
	employee_id,
	product_id,
	region,
	province,
	return_quantity,
	unit_price,
	return_amount,
	return_reason,
	status
from raw.raw_returns
order by return_id;

-- Create stg_employees
create table staging."stg_employees" as 
select 
	employee_id,
	full_name,
	gender,
	to_timestamp(date_of_birth, 'YYYY-MM-DD') as date_of_birth,
	to_timestamp(join_date, 'YYYY-MM-DD') as join_date,
	position,
	region,
	team,
	email,
	concat('0', cast(phone as text)) as phone,
	status,
	version,
	to_timestamp(effective_date, 'YYYY-MM-DD') as effective_date
from raw.raw_employees
order by employee_id;

-- Create stg_sales_target_plan
create table staging."stg_sales_targets" as 
select 
	plan_version,
	to_timestamp(version_date, 'YYYY-MM-DD') as version_date,
	to_timestamp(effective_from, 'YYYY-MM-DD') as effective_from,
	to_timestamp(effective_to, 'YYYY-MM-DD') as effective_to,
	employee_id,
	employee_name,
	region,
	team,
	year,
	month,
	target_revenue,
	target_quantity,
	target_new_customers
from raw.raw_sales_targets;

-- Create stg_distributo_orders
create table staging."stg_distributor_orders" as 
select 
	order_id,
	to_timestamp(order_date, 'YYYY-MM-DD') as order_date,
	order_month,
	order_quarter,
	distributor_id,
	region,
	channel,
	product_id,
	product_category,
	qty_ordered,
	qty_delivered,
	fill_rate_pct,
	unit_price_list,
	distributor_price,
	gross_amount,
	delivered_amount,
	to_timestamp(expected_delivery_date, 'YYYY-MM-DD') as expected_delivery_date,
	to_timestamp(actual_delivery_date, 'YYYY-MM-DD') as actual_delivery_date,
	ontime_delivery,
	delivery_status,
	payment_terms
from raw.raw_distributor_orders
order by order_id;

-- Create stg_products
create table staging."stg_products" as 
select 
	product_id,
	product_name,
	category,
	sub_category,
	unit,
	unit_price,
	cost_price,
	weight_gram,
	status,
	to_timestamp(launch_date, 'YYYY-MM-DD') as launch_date
from raw.raw_products
order by product_id;

-- Create stg_territory_mapping
create table staging."stg_territory_mapping" as 
select 
	territory_id,
	employee_id,
	customer_id,
	region,
	team,
	to_timestamp(effective_date, 'YYYY-MM-DD') as effective_date,
	to_timestamp(expiry_date, 'YYYY-MM-DD') as expiry_date,
	version
from raw.raw_territory_mapping
order by territory_id;

-- Create stg_promotions
create table staging."stg_promotions" as 
select 
	promotion_id,
	promotion_name,
	promotion_type,
	target_channel,
	target_region,
	to_timestamp(start_date, 'YYYY-MM-DD') as start_date,
	to_timestamp(end_date, 'YYYY-MM-DD') as end_date,
	applicable_products,
	discount_pct,
	min_order_quantity,
	budget_vnd,
	actual_cost_vnd,
	status,
	created_by
from raw.raw_promotions
order by promotion_id;

-- Create stg_sales_targets_versioned
create table staging."stg_sales_targets_versioned" as 
select 
	plan_version,
	to_timestamp(version_date, 'YYYY-MM-DD') as version_date,
	to_timestamp(effective_from, 'YYYY-MM-DD') as effective_from,
	to_timestamp(effective_to, 'YYYY-MM-DD') as effective_to,
	employee_id,
	employee_name,
	region,
	team,
	year,
	month,
	target_revenue,
	target_quantity,
	target_new_customers, 
	case 
		when month between 1 and 6 and plan_version ='v1' then TRUE
		when month between 7 and 12 and plan_version ='v2' then true 
		else false
	end as is_lastest_flag
from raw.sales_target_version;

select *
from staging.stg_sales_targets_versioned
where is_lastest_flag = true 
order by employee_id, month;

-- Create stg_employees_version
create table staging."stg_employees_version" as 
select 
	employee_id,
	full_name,
	gender,
	to_timestamp(date_of_birth, 'YYYY-MM-DD') as date_of_birth,
	to_timestamp(join_date, 'YYYY-MM-DD') as join_date,
	position,
	region,
	team,
	email,
	concat('0', cast(phone as text)) as phone,
	status,
	version,
	to_timestamp(effective_date, 'YYYY-MM-DD') as effective_date
from raw.employees_version
order by version, employee_id;