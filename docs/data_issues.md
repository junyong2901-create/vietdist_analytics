# Data Issues - Raw layer 

- Ngày profiling: `19/10/2026`
- Nguồn query: `sql/profiling_raw.sql`
- Phạm vi: các bảng `raw.*` trừ `raw.ingestion_log`


## 1. Tổng quan

| Bảng | Tổng dòng | Số cột | Dòng trùng hoàn toàn (dòng thừa) | Số batch | File bị load nhiều lần |
|---|---|---|---|---|---|
| raw.sales_transactions | 119101 | 25 | 0 | 1 | 0 |
| raw.customer_master | 2000 | 16 | 0 | 1 | 0 |
| raw.distributor_master | 138 | 18 | 0 | 1 | 0 |
| raw.return_transactions | 3665 | 18 | 0 | 1 | 0 |
| raw.sales_target_plan | 1332 | 17 | 0 | 2 | 1 |
| raw.employees | 114 | 19 | 0 | 1 | 0 |
| raw.distributor_orders | 35945 | 25 | 0 | 1 | 0 |
| raw.products | 100 | 14 | 0 | 1 | 0 |
| raw.territory_mapping | 1834 | 12 | 0 | 1 | 0 |
| raw.promotions | 40 | 18 | 0 | 1 | 0 |


## 2. Chi tiết từng bảng


### raw.sales_transactions

- Tổng số dòng: `119101`
- Cột key: `order_id`

**% NULL / rỗng của các cột key** 

| Cột key | % NULL | % chuỗi rỗng |
|---|---|---|
| order_id | 0 | 0 |

**Duplicate**

- Trùng hoàn toàn: `0`
- Trùng theo key: `35090 khóa trùng, 69101 dòng thừa`

**Vấn đề phát hiện và cách xử lý ở Silver**

| # | Vấn đề | Bằng chứng (số liệu hoặc query) | Mức độ | Cách xử lý dự định ở Silver |
|---|---|---|---|---|
| 1 | cột order_date sai định dạng | data_type = text | Cao | đưa về dạng timestamp |

---

### raw.customer_master

- Tổng số dòng: `2000`
- Cột key: `customer_id`

**% NULL / rỗng của các cột key** 

| Cột key | % NULL | % chuỗi rỗng |
|---|---|---|
| customer_id | 0 | 0 |

**Duplicate**

- Trùng hoàn toàn: `0`
- Trùng theo key: `0`

**Vấn đề phát hiện và cách xử lý ở Silver**

| # | Vấn đề | Bằng chứng (số liệu hoặc query) | Mức độ | Cách xử lý dự định ở Silver |
|---|---|---|---|---|
| 1 | Taxcode có 1035 dòng null | pct_null = 51.75 | Thấp | Chuyển giá trị null thành Unknown |
| 2 | Cột phone sai định dạng | bigint | Thấp | Chuyển về dạng text và thêm đầu '0'|
| 3 | Cột tax_code sai định dạng | double precision  | Thấp | Chuyển về dạng text |
| 4 | join_date sai định dạng | text | Cao | Chuyển về dạng timestamp |
---

### raw.distributor_master

- Tổng số dòng: `138`
- Cột key: `distributor_id`

**% NULL / rỗng của các cột key** 

| Cột key | % NULL | % chuỗi rỗng |
|---|---|---|
| distributor_id | 0 | 0 |

**Duplicate**

- Trùng hoàn toàn: `0`
- Trùng theo key: `0`

**Vấn đề phát hiện và cách xử lý ở Silver**

| # | Vấn đề | Bằng chứng (số liệu hoặc query) | Mức độ | Cách xử lý dự định ở Silver |
|---|---|---|---|---|
| 1 | Cột phone sai định dạng | bigint | Thấp | Chuyển về dạng text và thêm đầu '0'|
| 2 | Cột tax_code sai định dạng | double precision  | Thấp | Chuyển về dạng text |
| 3 | join_date sai định dạng | text | Cao | Chuyển về dạng timestamp |
---

---

### raw.return_transactions

- Tổng số dòng: `3665`
- Cột key: `return_id`

**% NULL / rỗng của các cột key** 

| Cột key | % NULL | % chuỗi rỗng |
|---|---|---|
| return_id | 0 | 0 |

**Duplicate**

- Trùng hoàn toàn: `0`
- Trùng theo key: `0`

**Vấn đề phát hiện và cách xử lý ở Silver**

| # | Vấn đề | Bằng chứng (số liệu hoặc query) | Mức độ | Cách xử lý dự định ở Silver |
|---|---|---|---|---|
| 3 | return_date sai định dạng | text | Cao | Chuyển về dạng timestamp |

---

### raw.employees

- Tổng số dòng: `114`
- Cột key: `employee_id`

**% NULL / rỗng của các cột key** 

| Cột key | % NULL | % chuỗi rỗng |
|---|---|---|
| employee_id | 0 | 0 |

**Duplicate**

- Trùng hoàn toàn: `0`
- Trùng theo key: `0`

**Vấn đề phát hiện và cách xử lý ở Silver**

| # | Vấn đề | Bằng chứng (số liệu hoặc query) | Mức độ | Cách xử lý dự định ở Silver |
|---|---|---|---|---|
| 1 | Cột phone sai định dạng | bigint | Thấp | Chuyển về dạng text và thêm đầu '0'|
| 2 | Cột date_of_birth sai định dạng | text | Cao | Chuyển về dạng timestamp |
| 3 | join_date sai định dạng | text | Cao | Chuyển về dạng timestamp |
| 4 | Cột resign_date 100% null |  | Thấp | drop cột |
| 5 | Cột transfer_note 100% null |  | Thấp | drop cột |
---

### raw.sales_target_plan

- Tổng số dòng: `1950`
- Cột key: `employee_id, month`

**% NULL / rỗng của các cột key** 

| Cột key | % NULL | % chuỗi rỗng |
|---|---|---|
| employee_id | 0 | 0 |
| month | 0 | 0 |

**Duplicate**

- Trùng hoàn toàn: `0`
- Trùng theo key: `111 dòng trùng, 1839 dòng thừa`

**Vấn đề phát hiện và cách xử lý ở Silver**

| # | Vấn đề | Bằng chứng (số liệu hoặc query) | Mức độ | Cách xử lý dự định ở Silver |
|---|---|---|---|---|
| 1 | version_date sai định dạng | text | Cao | Chuyển về dạng timestamp |
| 2 | effective_from sai định dạng | text | Cao | Chuyển về dạng timestamp |
| 3 | effective_to sai định dạng | text | Cao | Chuyển về dạng timestamp |

---

### raw.distributor_orders

- Tổng số dòng: `35945`
- Cột key: `order_id, product_id`

**% NULL / rỗng của các cột key** 

| Cột key | % NULL | % chuỗi rỗng |
|---|---|---|
| order_id | 0 | 0 |
| product_id | 0 | 0 |

**Duplicate**

- Trùng hoàn toàn: `0`
- Trùng theo key: `7028 dòng trùng, 27945 dòng thừa`

**Vấn đề phát hiện và cách xử lý ở Silver**

| # | Vấn đề | Bằng chứng (số liệu hoặc query) | Mức độ | Cách xử lý dự định ở Silver |
|---|---|---|---|---|
| 1 | order_date sai định dạng | text | Cao | Chuyển về dạng timestamp |
| 2 | expected_delivery_date sai định dạng | text | Cao | Chuyển về dạng timestamp |
| 3 | actual_delivery_date sai định dạng | text | Cao | Chuyển về dạng timestamp |

---

### raw.products

- Tổng số dòng: `100`
- Cột key: `product_id`

**% NULL / rỗng của các cột key** 

| Cột key | % NULL | % chuỗi rỗng |
|---|---|---|
| product_id | 0 | 0 |

**Duplicate**

- Trùng hoàn toàn: `0`
- Trùng theo key: `0`

**Vấn đề phát hiện và cách xử lý ở Silver**

| # | Vấn đề | Bằng chứng (số liệu hoặc query) | Mức độ | Cách xử lý dự định ở Silver |
|---|---|---|---|---|
| 1 | launch_date sai định dạng | text | Cao | Chuyển về dạng timestamp |

---

### raw.territory_mapping

- Tổng số dòng: `1843`
- Cột key: `territory_id`

**% NULL / rỗng của các cột key**

| Cột key | % NULL | % chuỗi rỗng |
|---|---|---|
| territory_id | 0 | 0 |

**Duplicate**

- Trùng hoàn toàn: `0`
- Trùng theo key: `0`

**Vấn đề phát hiện và cách xử lý ở Silver**

| # | Vấn đề | Bằng chứng (số liệu hoặc query) | Mức độ | Cách xử lý dự định ở Silver |
|---|---|---|---|---|
| 1 | effective_date sai định dạng | text | Cao | Chuyển về dạng timestamp |
| 2 | expiry_date sai định dạng | text | Cao | Chuyển về dạng timestamp |

---

### raw.promotions

- Tổng số dòng: `40`
- Cột key: `promotion_id`

**% NULL / rỗng của các cột key**

| Cột key | % NULL | % chuỗi rỗng |
|---|---|---|
| promotion_id | 0 | 0 |

**Duplicate**

- Trùng hoàn toàn: `0`
- Trùng theo key: `0`

**Vấn đề phát hiện và cách xử lý ở Silver**

| # | Vấn đề | Bằng chứng (số liệu hoặc query) | Mức độ | Cách xử lý dự định ở Silver |
|---|---|---|---|---|
| 1 | start_date sai định dạng | text | Cao | Chuyển về dạng timestamp |
| 2 | end_date sai định dạng | text | Cao | Chuyển về dạng timestamp |

---


## 3. Vấn đề chung nhiều bảng

| # | Vấn đề | Bảng bị ảnh hưởng | Cách xử lý dự định ở Silver |
|---|---|---|---|
| 1 | Ngày bị lưu ở dạng text | Tất cả | Chuyển đổi về dạng timestamp |
