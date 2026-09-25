My apologies for jumping ahead! Let's officially kick off **Task 9**.

---

# Task 9 — Implement Data Governance, Lineage & Documentation

### Objective

Establish warehouse transparency, data dictionary documentation, and column-level governance so business users and engineers can easily discover, trust, and audit datasets.

---

## Work Assignment Overview

1. **Catalog Data Assets:** Document table and column descriptions for all layers (`staging_aura`, `core_aura`, `marts_aura`).
2. **Column-Level Data Lineage:** Map source-to-target dependencies from raw operational tables down to gold business marts.
3. **Data Classification & PII Security:** Identify sensitive columns (PII) and apply governance tagging/masking strategies.
4. **Data Dictionary:** Create a centralized, version-controlled markdown data dictionary for project handoff.

---

## Step 1: Create Branch & Governance Directory

Run these commands in Cloud Shell:

```bash
# 1. Feature branch
git checkout main
git pull origin main
git checkout -b task-9-governance-documentation

# 2. Create directory for governance documentation and scripts
mkdir -p docs
mkdir -p sql/07_governance

```

---

## Step 2: Implement Column-Level Data Lineage & Classification Matrix

Create `docs/data_lineage_and_governance.md` to map lineage and classify PII data across layers:

### Data Lineage & Governance Specification

```
[Raw Layer]                   [Staging Layer]             [Core Layer]                   [Marts Layer]
raw_customers      ──────►   stg_customers     ──────►   dim_customers (SCD2)   ───┐
raw_orders         ──────►   stg_orders        ──┐                                  ├──► mart_customer_ltv
raw_order_items    ──────►   stg_order_items   ──┼────►   fact_order_items       ───┼──► mart_daily_revenue
raw_products       ──────►   stg_products      ──┤                                  └──► mart_product_performance
raw_payments       ──────►   stg_payments      ──┴────►   stg_payments           ──────► mart_payment_performance

```

### Data Classification & PII Mapping

| Layer | Table Name | Column Name | Classification | Governance Action / Masking |
| --- | --- | --- | --- | --- |
| `staging_aura` | `stg_customers` | `email` | **PII (High Sensitive)** | Restrict via Column Security / Hashing |
| `staging_aura` | `stg_customers` | `first_name`, `last_name` | **PII (Medium Sensitive)** | Mask in non-prod / restricted views |
| `core_aura` | `dim_customers` | `email` | **PII (High Sensitive)** | Restrict access via Policy Tags |
| `marts_aura` | `mart_daily_revenue` | All columns | **Confidential / Commercial** | Restricted to Finance & Executive roles |

---

## Step 3: Apply BigQuery Schema Descriptions & Column Labels

Create `sql/07_governance/apply_schema_labels.sql` to programmatically add documentation tags directly to BigQuery tables:

```sql
-- Apply Table Descriptions to Gold Marts
ALTER VIEW `sql-only-warehouse-v1.marts_aura.mart_daily_revenue`
SET OPTIONS(
  description="Gold mart serving daily gross/net revenue aggregated by product category. Reconciles with core_aura.fact_order_items."
);

ALTER VIEW `sql-only-warehouse-v1.marts_aura.mart_customer_ltv`
SET OPTIONS(
  description="Gold mart tracking customer lifetime value, order frequency, and repeat buyer status. Contains sensitive PII attributes."
);

ALTER TABLE `sql-only-warehouse-v1.core_aura.fact_order_items`
SET OPTIONS(
  description="Core transactional fact table with item-level grain (1 row per order item). Partitioned by date_key."
);

```

---

## Step 4: Generate Centralized Data Dictionary

Create `docs/DATA_DICTIONARY.md` for team-wide handoff:

```markdown
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

```

---

## Step 5: Deploy Governance & Commit

Run in Cloud Shell:

```bash
# 1. Execute schema description script
bq query --use_legacy_sql=false < sql/07_governance/apply_schema_labels.sql

# 2. Stage and commit files
git add docs/ sql/07_governance/
git commit -m "docs: add data lineage, PII classification, and data dictionary for Task 9"

# 3. Merge to main
git checkout main
git merge task-9-governance-documentation
git push origin main
git branch -d task-9-governance-documentation

```

---

### Task 9 Complete Checklist

* [x] Column-level data lineage documented.
* [x] PII data identified and security classification applied.
* [x] Schema descriptions updated directly inside BigQuery metadata.
* [x] Comprehensive Markdown Data Dictionary built for project handoff.