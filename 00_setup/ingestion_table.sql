create table if not exists raw.ingestion_log(
	log_id	bigserial primary key,
	batch_id uuid not null,
	source_name text not null,
	source_platform text not null check(source_platform in ('google_drive', 'one_drive')),
	source_file text not null,
	status text not null default 'running' check (status in ('success', 'failed')),
	rows_loaded integer,
	duration_sec numeric(10,2),
	error_message text,
	logged_at timestamp not null default now()
);

create index if not exists idx_ingestion_log_batch_id on raw.ingestion_log (batch_id);
create index if not exists idx_ingestion_log_status on raw.ingestion_log (status);

select column_name, data_type
from information_schema.columns
where table_schema = 'raw' and table_name = 'ingestion_log'
order by ordinal_position;
