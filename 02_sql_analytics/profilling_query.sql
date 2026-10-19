-- Q1. Tổng số dòng và số cột của từng bảng
SELECT t.table_name,
       (xpath('/row/total_rows/text()',
              query_to_xml(format('SELECT count(*) AS total_rows FROM raw.%I', t.table_name),
                           false, true, '')))[1]::text::bigint AS total_rows,
       (SELECT count(*) FROM information_schema.columns c
         WHERE c.table_schema = 'raw' AND c.table_name = t.table_name) AS n_columns
FROM information_schema.tables t
WHERE t.table_schema = 'raw' AND t.table_type = 'BASE TABLE' AND t.table_name <> 'ingestion_log'
ORDER BY t.table_name;

-- Q2. % NULL và % chuỗi rỗng của MỌI cột
with null_table as (
	SELECT q.*,
	       round(100.0 * q.null_rows  / nullif(q.total_rows, 0), 2) AS pct_null,
	       round(100.0 * q.blank_rows / nullif(q.total_rows, 0), 2) AS pct_blank
	FROM (
	    SELECT s.table_name, s.column_name, s.ordinal_position,
	           (xpath('/row/total_rows/text()', s.x))[1]::text::bigint AS total_rows,
	           (xpath('/row/null_rows/text()',  s.x))[1]::text::bigint AS null_rows,
	           (xpath('/row/blank_rows/text()', s.x))[1]::text::bigint AS blank_rows
	    FROM (
	        SELECT c.table_name, c.column_name, c.ordinal_position,
	               query_to_xml(
	                   format('SELECT count(*) AS total_rows, '
	                          'count(*) FILTER (WHERE %I IS NULL) AS null_rows, '
	                          'count(*) FILTER (WHERE btrim(%I::text) = '''') AS blank_rows '
	                          'FROM raw.%I', c.column_name, c.column_name, c.table_name),
	                   false, true, '') AS x
	        FROM information_schema.columns c
	        JOIN information_schema.tables t
	          ON t.table_schema = c.table_schema AND t.table_name = c.table_name
	        WHERE c.table_schema = 'raw' AND t.table_type = 'BASE TABLE'
	          AND c.table_name <> 'ingestion_log'
	          AND c.column_name NOT IN ('_source_file', '_source_platform', '_ingested_at', '_batch_id')
	    ) s
	) q
	ORDER BY q.table_name, q.ordinal_position)

select *
from null_table
where table_name =  'raw_promotions'

-- Q3. Dòng trùng hoàn toàn (giống nhau ở mọi cột, không tính 4 cột metadata)
SELECT s.table_name,
       (xpath('/row/dup_groups/text()', s.x))[1]::text::bigint AS duplicate_groups,
       (xpath('/row/extra_rows/text()', s.x))[1]::text::bigint AS extra_rows
FROM (
    SELECT g.table_name,
           query_to_xml(
               format('SELECT count(*) AS dup_groups, coalesce(sum(n - 1), 0) AS extra_rows '
                      'FROM (SELECT count(*) AS n FROM raw.%I GROUP BY %s HAVING count(*) > 1) d',
                      g.table_name, g.cols),
               false, true, '') AS x
    FROM (
        SELECT c.table_name,
               string_agg(quote_ident(c.column_name), ', ' ORDER BY c.ordinal_position) AS cols
        FROM information_schema.columns c
        JOIN information_schema.tables t
          ON t.table_schema = c.table_schema AND t.table_name = c.table_name
        WHERE c.table_schema = 'raw' AND t.table_type = 'BASE TABLE'
          AND c.table_name <> 'ingestion_log'
          AND c.column_name NOT IN ('_source_file', '_source_platform', '_ingested_at', '_batch_id')
        GROUP BY c.table_name
    ) g
) s
ORDER BY s.table_name;

-- Q4. Cột text có khoảng trắng thừa ở đầu/cuối (chỉ hiện cột có vấn đề)
SELECT q.table_name, q.column_name, q.padded_rows
FROM (
    SELECT c.table_name, c.column_name,
           (xpath('/row/padded_rows/text()',
                  query_to_xml(
                      format('SELECT count(*) FILTER (WHERE %I <> btrim(%I)) AS padded_rows FROM raw.%I',
                             c.column_name, c.column_name, c.table_name),
                      false, true, '')))[1]::text::bigint AS padded_rows
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema AND t.table_name = c.table_name
    WHERE c.table_schema = 'raw' AND t.table_type = 'BASE TABLE'
      AND c.table_name <> 'ingestion_log'
      AND c.data_type IN ('text', 'character varying')
      AND c.column_name NOT IN ('_source_file', '_source_platform', '_batch_id')
) q
WHERE q.padded_rows > 0
ORDER BY q.table_name, q.column_name;

-- Q5. Kiểu dữ liệu hiện tại của từng cột (ngày/số đang bị lưu dạng text là dấu hiệu cần ép kiểu ở Silver)
with data_type as (
	SELECT c.table_name, c.column_name, c.data_type
	FROM information_schema.columns c
	JOIN information_schema.tables t
	  ON t.table_schema = c.table_schema AND t.table_name = c.table_name
	WHERE c.table_schema = 'raw' AND t.table_type = 'BASE TABLE'
	  AND c.table_name <> 'ingestion_log'
	  AND c.column_name NOT IN ('_source_file', '_source_platform', '_ingested_at', '_batch_id')
	ORDER BY c.table_name, c.ordinal_position)
	
select *
from data_type
where table_name = 'raw_promotions'

-- Q7. Số khóa bị trùng và số dòng thừa
 SELECT count(*) AS duplicate_keys, coalesce(sum(n - 1), 0) AS extra_rows
 FROM (SELECT count(*) AS n from raw.raw_promotions GROUP BY promotion_id   HAVING count(*) > 1) d;
-- 7b. 50 khóa trùng nhiều nhất, để xem tận mắt
-- SELECT <cột_key>, count(*) AS n FROM raw.<bảng>
-- GROUP BY <cột_key> HAVING count(*) > 1 ORDER BY n DESC LIMIT 50;