# Synthetic Data Dictionary

This dictionary describes the public synthetic schema. Names are generic and do
not reproduce any private database schema.

| Field | Type | Description |
|---|---|---|
| `vehicle_id` | character | Synthetic vehicle identifier |
| `base_month` | Date | First day of the scoring month |
| `site_id` | character | Anonymous monitoring segment; excluded from v1.1 models |
| `vehicle_age_years` | numeric | Vehicle age at the scoring month |
| `days_since_last_service` | numeric | Days since the latest known service |
| `return_relationship` | category | Home site, same-network site, or outside network |
| `last_service_mileage` | numeric | Latest recorded synthetic mileage |
| `usage_frequency` | category | Low, medium, or high usage band |
| `uio_310` | logical | Synthetic ownership-status indicator |
| `uio_412` | logical | Synthetic ownership-status indicator |
| `visits_last_3m` | integer | Service visits during the three-month behavior window |
| `general_repairs_last_3m` | integer | General-repair visits during the behavior window |
| `body_repairs_last_3m` | integer | Body-repair visits during the behavior window |
| `inspections_last_3m` | integer | Inspection visits during the behavior window |
| `sales_amount_last_3m` | numeric | Synthetic service sales during the behavior window |
| `days_since_actual_visit_3m` | numeric | Days since a visit inside the behavior window |
| `present_m1` | logical | Present one month after the base month |
| `present_m2` | logical | Present two months after the base month |
| `present_m3` | logical | Present three months after the base month |
| `label_end_month` | Date | Month when the three-month target is fully observed |
| `ever_absent_3m` | logical | Absent in at least one horizon month |
| `churn_3m` | logical | Absent in the third horizon month |
| `sales_amount_last_3m_log` | numeric | Signed `log1p` transformation of service sales |
| `risk_probability` | numeric | Model score between zero and one |
| `risk_rank` | integer | Descending score rank |
| `risk_percentile` | numeric | Rank divided by the eligible cohort size |
| `top_risk_flag` | logical | Member of the fixed top-5% review cohort |

## Privacy Boundary

The public schema does not require names, phone numbers, addresses, government
identifiers, real vehicle identifiers, real license plates, employee names, or
free-text customer feedback.
