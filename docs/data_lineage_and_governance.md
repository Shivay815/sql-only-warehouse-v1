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

