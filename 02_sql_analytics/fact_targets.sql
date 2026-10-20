create view dwh."fact_targets" as 
select *
from staging.stg_sales_targets_versioned
where is_lastest_flag = true
order by employee_id, month