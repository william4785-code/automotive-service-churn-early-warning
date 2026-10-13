# Model Card: `pure_early_warning_v1.1`

## Model Details

- **Model family:** binomial logistic regression
- **Status:** frozen research candidate; first prospective checkpoint completed
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

### Retrospective Evidence

Paired stratified bootstrap used 500 resamples across three validation months.
Champion-minus-Baseline mean differences were:

- PR AUC: +0.00170, 95% CI [-0.0000789, 0.00665], 95.2% win proportion;
- Top-5% lift: +1.10, 95% CI [-0.226, 2.51], 95.2% win proportion;
- Top-5% capture: +0.0553, 95% CI [-0.0113, 0.126], 95.0% win proportion.

All confidence intervals included zero. Win proportions are the share of
bootstrap resamples in which the Champion exceeded the Baseline; they are not
accuracy, statistical significance, or a probability of superiority.

### First Mature Prospective Checkpoint

The frozen June 2026 cohort contained 42,895 eligible records and 44 matured
events. The Champion recorded ROC AUC 0.561, PR AUC 0.00131, Top-5% lift 1.82,
and Top-5% capture 9.09% (4 hits). The Baseline recorded ROC AUC 0.494, PR AUC
0.00100, Top-5% lift 0.909, and capture 4.55% (2 hits).

This result passed the first directional research checkpoint: Champion lift
exceeded one and captured twice as many events as the Baseline. It did not pass
a production promotion gate. Only 44 events matured, discrimination was
modest, and no prospective bootstrap confidence interval was constructed.

The mean predicted probability was approximately 0.594 times the observed
prevalence. Scores may be used only for ranking research until probability
calibration is completed.

### Second Observation Cohort

A September 2026 observation cohort was created after a data-quality gate
detected and blocked an ingestion gap. Following backfill and revalidation,
43,548 of 43,565 eligible raw records were scored; 17 were excluded for missing
vehicle age. The Champion Top-5% cohort contained 2,178 scores.

Reliability checks passed with Champion PSI 0.00616, P99 ratio 1.03, maximum
segment concentration 1.19, and maximum within-segment selection rate 5.97%.
Outcome performance remains pending until December 2026. Reliability PASS does
not mean predictive-performance PASS.

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
- Only one of the required three prospective months has mature outcomes.
- The first mature cohort contained 44 events, so one additional hit materially
  changes lift and capture estimates.
- Absolute risk is underpredicted and probabilities are not calibrated.
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

Until at least three prospective months mature and the promotion criteria are
met, outputs should be labeled:

> Research candidate; not production-ready, not intervention-validated, and not
> a calibrated churn probability.

## Data Boundary

T0 customer and vehicle data never enters Git, including private repositories.
Tracked materials may include reviewed source code, generalized documentation,
approved cohort-level aggregates, and synthetic examples written from scratch.
Raw records, masked samples, model objects, caches, logs, score lists, and any
artifact capable of reconstructing a person, vehicle, or service event are
prohibited.
