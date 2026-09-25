# Warehouse Data Dictionary & Catalog

## Dataset: `core_aura`

### Table: `fact_order_items`
* **Type:** Fact Table
* **Grain:** 1 row per order item
* **Partition Key:** `date_key`
* **Cluster Keys:** `order_id`, `product_id`

| Column Name | Data Type | Key Type | Description |
| :--- | :--- | :--- | :--- |
| `order_item_skey` | STRING | Primary Key | Composite MD5 hash (`order_id` + `order_item_id`) |
| `date_key` | INT64 | Foreign Key | References `dim_dates.date_key` (Format: YYYYMMDD) |
| `product_skey` | STRING | Foreign Key | References `dim_products.product_skey` |
| `customer_skey` | STRING | Foreign Key | References `dim_customers.customer_skey` (SCD2 Version) |
| `item_gross_amount`| NUMERIC | Measure | Calculated gross sales: `quantity * price_at_purchase` |

---

## Dataset: `marts_aura`

### View: `mart_daily_revenue`
* **Consumer:** Finance & Executive Reporting
* **Grain:** 1 row per `order_date` × `category_name`

| Column Name | Data Type | Description | Formula |
| :--- | :--- | :--- | :--- |
| `order_date` | DATE | Date of transaction | `dim_dates.full_date` |
| `category_name` | STRING | Product category | `dim_products.category_name` |
| `gross_revenue` | NUMERIC | Total gross sales | `SUM(item_gross_amount)` |
| `daily_category_refunds` | NUMERIC | Total refund amount | `SUM(stg_refunds.refund_amount)` |
| `net_revenue` | NUMERIC | Net revenue after refunds | `gross_revenue - daily_category_refunds` |
