To complete **Task 2**, you will establish source contracts for a fictitious multi-seller e-commerce platform named **"Aura Commerce"**.

Treating incoming data as untrusted third-party feeds requires clear contracts specifying **data types, nullability, valid ranges, update behaviors, and timestamp semantics** before writing any SQL transforms.

---

## 1. Domain Overview: Aura Commerce

* **Domain:** E-commerce Marketplace
* **Business Model:** Third-party sellers list products; customers purchase items in multi-item orders; payments are processed through payment gateways; sellers fulfill orders via logistics partners.
* **Ingestion Mechanism:** Daily batch landing of CSV/JSON files into Google Cloud Storage (GCS) or raw BigQuery tables.

---

## 2. Source Contracts Specification

Below are the detailed contracts for the **8 source entities**.

### Entity 1: `raw_customers`

* **Source System:** User Management Microservice
* **Purpose:** Stores registered customer accounts and profile data.
* **Primary / Natural Key:** `customer_id`
* **Update Behavior:** Snapshot / Upsert (Overwrites current profile state or delivers full daily snapshots).

| Column | Data Type | Nullable | Valid Values / Constraints | Classification | Description |
| --- | --- | --- | --- | --- | --- |
| `customer_id` | `STRING` | **No** | UUID / Alpha-numeric string | Identifier | Unique user ID |
| `email` | `STRING` | **No** | Valid email pattern containing `@` | Attribute | Customer email address |
| `first_name` | `STRING` | Yes | Non-empty string | Attribute | Customer first name |
| `last_name` | `STRING` | Yes | Non-empty string | Attribute | Customer last name |
| `created_at` | `TIMESTAMP` | **No** | Past or present timestamp | Event / Timestamp | Account creation timestamp |
| `updated_at` | `TIMESTAMP` | **No** | `updated_at >= created_at` | Event / Timestamp | Last profile update timestamp |

* **Timestamp Semantics:** `created_at` is fixed UTC event time; `updated_at` represents system modification time.
* **Expected Data Quality Issues:** Missing names, duplicate emails due to social login bugs, soft-deleted accounts without proper flags.

---

### Entity 2: `raw_sellers`

* **Source System:** Merchant Onboarding Portal
* **Purpose:** Stores merchant profiles operating on the marketplace platform.
* **Primary / Natural Key:** `seller_id`
* **Update Behavior:** Snapshot / Upsert.

| Column | Data Type | Nullable | Valid Values / Constraints | Classification | Description |
| --- | --- | --- | --- | --- | --- |
| `seller_id` | `STRING` | **No** | `SEL_` prefix + numeric ID | Identifier | Merchant identifier |
| `seller_name` | `STRING` | **No** | Non-empty string | Attribute | Business/Store name |
| `country` | `STRING` | **No** | ISO 2-letter country code (`US`, `IN`, `CA`, etc.) | Attribute | Registration country |
| `status` | `STRING` | **No** | `'ACTIVE'`, `'SUSPENDED'`, `'PENDING'` | Attribute | Operational status |
| `created_at` | `TIMESTAMP` | **No** | Past or present timestamp | Event / Timestamp | Merchant onboarding date |

* **Timestamp Semantics:** `created_at` is UTC registration time.
* **Expected Data Quality Issues:** Inconsistent casing in country codes (`us`, `US`, `USA`), legacy sellers missing registration status.

---

### Entity 3: `raw_products`

* **Source System:** Product Catalog Management System (PIM)
* **Purpose:** Product listings and metadata created by sellers.
* **Primary / Natural Key:** `product_id`
* **Update Behavior:** Upsert / CDC.

| Column | Data Type | Nullable | Valid Values / Constraints | Classification | Description |
| --- | --- | --- | --- | --- | --- |
| `product_id` | `STRING` | **No** | UUID | Identifier | Product item ID |
| `seller_id` | `STRING` | **No** | Valid foreign key to `raw_sellers` | Identifier | Seller offering the product |
| `category_name` | `STRING` | Yes | Known taxology list (e.g., `Electronics`, `Apparel`) | Attribute | Category grouping |
| `unit_price` | `NUMERIC` | **No** | `unit_price > 0` | Measure | Base price per unit |
| `updated_at` | `TIMESTAMP` | **No** | Past or present timestamp | Event / Timestamp | System modification time |

* **Timestamp Semantics:** `updated_at` represents the catalog record versioning timestamp.
* **Expected Data Quality Issues:** Zero or negative unit prices, orphan `seller_id` values not found in `sellers`, unmapped category strings (`N/A`, `Unknown`).

---

### Entity 4: `raw_orders`

* **Source System:** Order Management System (OMS)
* **Purpose:** Header records for customer transaction requests.
* **Primary / Natural Key:** `order_id`
* **Update Behavior:** Append-only or State-Transition Updates.

| Column | Data Type | Nullable | Valid Values / Constraints | Classification | Description |
| --- | --- | --- | --- | --- | --- |
| `order_id` | `STRING` | **No** | `ORD_` + alphanumeric | Identifier | Unique order header ID |
| `customer_id` | `STRING` | **No** | Valid foreign key to `raw_customers` | Identifier | Purchasing customer |
| `order_status` | `STRING` | **No** | `'PENDING'`, `'PAID'`, `'CANCELLED'`, `'COMPLETED'` | Attribute | State lifecycle status |
| `order_placed_at` | `TIMESTAMP` | **No** | Past or present timestamp | Event / Timestamp | Customer checkout time |
| `total_amount` | `NUMERIC` | **No** | `total_amount >= 0` | Measure | Sum total charge |

* **Timestamp Semantics:** `order_placed_at` is immutable business event time (UTC).
* **Expected Data Quality Issues:** Mismatch between `total_amount` and individual line item totals; status stuck in `'PENDING'` infinitely.

---

### Entity 5: `raw_order_items`

* **Source System:** Order Management System (OMS)
* **Purpose:** Granular line items within an order (Order-Product relationship).
* **Primary / Natural Key:** Composite key (`order_id`, `order_item_id`)
* **Update Behavior:** Append-only (Created at checkout time).

| Column | Data Type | Nullable | Valid Values / Constraints | Classification | Description |
| --- | --- | --- | --- | --- | --- |
| `order_id` | `STRING` | **No** | Valid foreign key to `raw_orders` | Identifier | Parent order header |
| `order_item_id` | `INT64` | **No** | Sequence integer (`1, 2, 3...`) | Identifier | Line item position in order |
| `product_id` | `STRING` | **No** | Valid foreign key to `raw_products` | Identifier | Purchased product ID |
| `quantity` | `INT64` | **No** | `quantity > 0` | Measure | Purchased count |
| `price_at_purchase` | `NUMERIC` | **No** | `price_at_purchase >= 0` | Measure | Item unit price at checkout |

* **Timestamp Semantics:** Shares timestamp with parent `order_placed_at`.
* **Expected Data Quality Issues:** Duplicate `(order_id, order_item_id)` combinations on system retries; quantity recorded as 0.

---

### Entity 6: `raw_payments`

* **Source System:** Payment Gateway Service (Stripe / Adyen integration)
* **Purpose:** Financial ledger of transaction processing attempts.
* **Primary / Natural Key:** `payment_id`
* **Update Behavior:** Append-only.

| Column | Data Type | Nullable | Valid Values / Constraints | Classification | Description |
| --- | --- | --- | --- | --- | --- |
| `payment_id` | `STRING` | **No** | `PAY_` + alphanumeric | Identifier | Transaction ledger ID |
| `order_id` | `STRING` | **No** | Valid foreign key to `raw_orders` | Identifier | Associated order |
| `payment_method` | `STRING` | **No** | `'CREDIT_CARD'`, `'PAYPAL'`, `'BANK_TRANSFER'` | Attribute | Payment rail used |
| `payment_status` | `STRING` | **No** | `'SUCCESS'`, `'FAILED'`, `'PENDING'` | Attribute | Gateway outcome |
| `amount` | `NUMERIC` | **No** | `amount > 0` | Measure | Transaction currency value |
| `processed_at` | `TIMESTAMP` | **No** | `processed_at >= order_placed_at` | Event / Timestamp | Gateway response timestamp |

* **Timestamp Semantics:** `processed_at` is external event execution time in UTC.
* **Expected Data Quality Issues:** Multiple `'SUCCESS'` records for a single `order_id` (double-charging bug); late-arriving settlement logs.

---

### Entity 7: `raw_refunds`

* **Source System:** Customer Support & Financial Clearing System
* **Purpose:** Tracks reversal of funds back to customers.
* **Primary / Natural Key:** `refund_id`
* **Update Behavior:** Append-only.

| Column | Data Type | Nullable | Valid Values / Constraints | Classification | Description |
| --- | --- | --- | --- | --- | --- |
| `refund_id` | `STRING` | **No** | `REF_` + alphanumeric | Identifier | Refund record ID |
| `order_id` | `STRING` | **No** | Valid foreign key to `raw_orders` | Identifier | Target order for refund |
| `refund_amount` | `NUMERIC` | **No** | `refund_amount > 0` | Measure | Returned monetary amount |
| `reason` | `STRING` | Yes | `'DEFECTIVE'`, `'LATE_DELIVERY'`, `'BUYER_REMORSE'` | Attribute | Return categorization |
| `refunded_at` | `TIMESTAMP` | **No** | `refunded_at >= order_placed_at` | Event / Timestamp | Ledger settlement timestamp |

* **Timestamp Semantics:** `refunded_at` represents financial execution timestamp.
* **Expected Data Quality Issues:** `refund_amount` exceeds original `total_amount` of the order; refund timestamp occurring *before* order placement date.

---

### Entity 8: `raw_shipments`

* **Source System:** Logistics & Fulfillment Partner API
* **Purpose:** Package dispatch and delivery tracking updates.
* **Primary / Natural Key:** `shipment_id`
* **Update Behavior:** Upsert / State-Tracking.

| Column | Data Type | Nullable | Valid Values / Constraints | Classification | Description |
| --- | --- | --- | --- | --- | --- |
| `shipment_id` | `STRING` | **No** | `SHP_` + alphanumeric | Identifier | Logistics container ID |
| `order_id` | `STRING` | **No** | Valid foreign key to `raw_orders` | Identifier | Order being fulfilled |
| `carrier` | `STRING` | **No** | `'FEDEX'`, `'UPS'`, `'DHL'`, `'USPS'` | Attribute | Delivery service partner |
| `shipped_at` | `TIMESTAMP` | Yes | `shipped_at >= order_placed_at` | Event / Timestamp | Carrier dispatch time |
| `delivered_at` | `TIMESTAMP` | Yes | `delivered_at >= shipped_at` | Event / Timestamp | Recipient drop-off time |

* **Timestamp Semantics:** Timestamps reflect actual physical event occurrences in UTC.
* **Expected Data Quality Issues:** `delivered_at` is populated while `shipped_at` is `NULL`; delivery dates occurring months in the future due to time zone offset bugs.

---

## 3. Contract Violation Strategy

When incoming source batch data fails to meet these rules during downstream processing:

```
[ Raw Ingestion Layer ]  --->  [ Data Quality / Validation Check ]
                                      |
                     +----------------+----------------+
                     |                                 |
              (Passes Rules)                    (Fails Rules)
                     v                                 v
            [ Staging Layer ]                [ Quarantine Table ]
       (Clean, standardized views)       (Log error code & retain record)

```

1. **Hard Failures (Critical Identifiers / Keys):**
* *Trigger:* `NULL` primary keys, duplicate primary keys in append-only files, or unparseable timestamps.
* *Action:* Quarantine bad rows into a `quarantine_raw_*` logging table with an error code flag (`NULL_PRIMARY_KEY`, `INVALID_TIMESTAMP`). Do **not** allow them to propagate to `Staging`.


2. **Soft Failures (Formatting / Unknown Categories):**
* *Trigger:* Out-of-spec category strings, irregular casing, or non-critical null attributes (`reason` in refunds).
* *Action:* Allow rows into `Staging`, but set unmapped strings to standard defaults like `'UNKNOWN'` or `NULL`.


3. **Domain & Range Failures (Invalid Business Measures):**
* *Trigger:* Negative prices, refund amount > order amount, delivery before shipment.
* *Action:* Allow the record into staging for auditing purposes, but raise alert flags via audit queries in Task 8.
