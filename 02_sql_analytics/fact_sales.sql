create view dwh."fact_sales" as 
select *
from staging.stg_sales_transaction