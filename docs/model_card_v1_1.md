# Model Card: `pure_early_warning_v1.1`

## Model Details

- **Model family:** binomial logistic regression
- **Status:** frozen research candidate
- **Primary role:** rank currently active vehicles by three-month service-network
  churn risk
- **Decision capacity:** top 5% of eligible scores
- **Parent model:** `pure_early_warning_v1`

The v1.1 revision removed location as a predictive feature after the first
prospective shadow run exposed unstable concentration in a small segment.
Location remains available for post-score reliability monitoring.

## Intended Use

- Prioritize a limited review cohort for retention research.
- Compare Champion, Challenger, and Baseline rankings.
- Monitor whether prospective score distributions remain comparable with the
  frozen training reference.
- Support a future treatment-control experiment after prospective labels mature.

## Out-of-Scope Uses

- Automatic denial, pricing, eligibility, or other consequential decisions.
- Claiming that a feature causes churn.
- Contacting every high-score customer without operational review.
- Treating the score as proof that outreach will recover a customer.
- Replacing prospective validation with retrospective fit statistics.

## Population

A row represents one vehicle at one scoring month. A row is eligible when:

- the vehicle is currently active in the service network;
- fewer than 600 days have elapsed since its last service;
- its latest service relationship is the home location or another location in
  the same anonymized network.

## Target

`churn_3m = TRUE` when the vehicle is absent in the third month after the
scoring month.

The label intentionally differs from:

- any temporary absence during the three-month horizon;
- a next-month transfer between locations;
- evidence that a customer has already completed a move elsewhere.

## Feature Sets

### Champion

Seven static attributes plus:

- visits in the last three months;
- general repairs in the last three months;
- body repairs in the last three months;
- inspection visits in the last three months;
- signed-log service sales amount;
- days since the latest actual visit in the three-month behavior window.

### Challenger

The same static attributes plus body-repair count.

### Baseline

Static attributes only.

Location is excluded from all three models.

## Missing-Value Rules

- If no visit occurs in the three-month behavior window,
  `days_since_actual_visit_3m` is set to 100.
- This value is a predictive missingness code and must not be interpreted as a
  causal 100-day effect.
- Rows missing other required model fields are excluded and should be recorded
  in a private scoring audit.

## Validation

Rolling time validation uses a purge boundary:

```text
training label end month < validation scoring month
```

This prevents training rows whose future outcome overlaps the validation
period. Because the target is extremely rare, evaluation emphasizes:

- PR AUC;
- top-5% lift;
- top-5% capture rate;
- paired bootstrap win rate.

## Reliability Gate

| Check | WARN | HOLD |
|---|---:|---:|
| Score PSI | >= 0.10 | >= 0.25 |
| P99 score ratio | > 2.0 | > 3.0 |
| Maximum segment concentration | — | > 3.0 |
| Maximum within-segment selection rate | — | > 20% |

Any HOLD condition prevents operational promotion.

## Known Limitations

- Historical positive events were sparse.
- The original rolling evaluation covered three validation months.
- Bootstrap win rates were favorable, but most 95% confidence intervals still
  crossed zero.
- Behavioral features are associations, not causal mechanisms.
- The model has not yet proved that intervention changes return behavior.
- The final version traded some retrospective top-5% capture for improved
  prospective stability and portability.

## Required Prospective Acceptance

When labels mature, the frozen list must be evaluated without changing its
scores, membership, target, or model:

- actual event count and event rate;
- PR AUC;
- top-5% lift and capture rate;
- Champion versus Challenger and Baseline;
- segment-level hit rate and capture;
- calibration and ranking stability.

Until that evaluation is complete, outputs should be labeled:

> Prospective observation cohort; not a proven retention intervention list.
