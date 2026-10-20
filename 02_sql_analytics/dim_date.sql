create table dwh."dim_date" as 
with 
date_base as(
	select 
		d::date as full_date,
		extract(year from d)::int as year,
		extract(month from d):: int as month_number,
		9 as fy_start_month
	from generate_series(DATE '2022-01-01', current_timestamp, interval '1 day') as g(d)
),

date_fiscal as (
	select 
		*,
		case when month_number >= fy_start_month then year else year -1 end as fiscal_year,
		((month_number - fy_start_month + 12) % 12) + 1 as fiscal_month
	from date_base
)

select 
	to_char(full_date, 'YYYYMMDD')::int as date_key,
	full_date,
	extract(isodow from full_date)::int as day_of_week,
	(array['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']) [extract (isodow from full_date)::int] as day_name,
	extract(DAY from full_date)::int as day_of_month,
	extract(DOY from full_date)::int as day_of_year,
	extract(week from full_date)::int as week_of_year,
	date_trunc('week', full_date):: date as week_start_date,
	month_number,
	(array['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']) [month_number] as month_name,
	to_char(full_date, 'YYYY-MM') as year_month,
	extract(quarter from full_date)::int as quarter,
	year,
	fiscal_year,
	((fiscal_month - 1)/3 +1) as fiscal_quarter,
	fiscal_month,
	(extract(isodow from full_date) >= 6) as is_weekend,
	full_date >= (date_trunc('month', full_date) + interval '1 month - 1 day')::date as is_month_end
from date_fiscal