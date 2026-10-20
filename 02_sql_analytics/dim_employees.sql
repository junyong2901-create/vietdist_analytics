create view dwh."dim_employees" as
with 
updated_employees_in4 as(
	select distinct employee_id, count(*) as n_rows, count(distinct region) as n_regions, count(distinct team) as n_teams
	from staging.stg_employees_version
	group by employee_id 
	having count(distinct region) > 1 or count(distinct team) > 1
	order by employee_id
),

updated_employees_id_list as(
	select employee_id
	from updated_employees_in4
),

updated_employees_id_v2_filter as(
	select *
	from staging.stg_employees_version
	where employee_id in (select * from updated_employees_id_list)
	and version = 'v2'
),

prepared_employees as(
	select *
	from staging.stg_employees
	union 
	select *
	from updated_employees_id_v2_filter
	order by employee_id
),

employee_version as(
	select
		*,
		row_number() over (partition by employee_id order by effective_date desc) as rn
	from prepared_employees
),

final_employees as (
select
	employee_id,
	full_name,
	gender,
	date_of_birth,
	join_date,
	position,
	region,
	team,
	email,
	phone,
	status,
	version,
	effective_date,
	case when rn =1 then true else false end as is_current
from employee_version
order by employee_id, effective_date
)

select *
from final_employees
where is_current = True