# Anonymized Experiment Results

The figures below summarize the private research study at an aggregate level.
They are included to explain model-selection decisions. No row-level data,
segment names, fitted objects, or prospective risk records are included.

## Research Scale

| Measure | Result |
|---|---:|
| Frozen training vehicle-months | 419,469 |
| Frozen training events | 256 |
| First prospective eligible cohort | 42,895 |
| First prospective top-5% cohort | 2,145 |
| Behavior bootstrap repetitions | 500 |

The pure early-warning event rate was approximately 0.05% to 0.07% in each
rolling validation month, with only 21 to 29 events per month.

## Why the Target Was Redesigned

An initial next-month churn model achieved strong retrospective discrimination,
but days since last service dominated the result. The highest 1% began near 692
days since service, and 75.2% of that group disappeared in the following month.
This was interpreted as a likely data-list expiration mechanism rather than a
useful early-warning signal.

The final target therefore:

- restricts the population to fewer than 600 days since service;
- excludes evidence that a move outside the network has already completed;
- predicts continued absence in the third month.

## Behavior Increment

The three-month service-behavior feature group improved ranking performance over
the static model. Body-repair count was the most stable individual signal:

| Validation month | Odds ratio | P-value |
|---|---:|---:|
| Month 1 | 2.31 | 0.0000971 |
| Month 2 | 2.21 | 0.000105 |
| Month 3 | 2.20 | 0.0000559 |

This is an association and must not be interpreted as evidence that body repair
causes churn.

## Paired Bootstrap

Champion versus location-free static Baseline:

| Metric | Mean difference | Bootstrap win rate |
|---|---:|---:|
| PR AUC | +0.00170 | 95.2% |
| Top-5% lift | +1.10 | 95.2% |
| Top-5% capture rate | +5.53 percentage points | 95.0% |

Most 95% confidence intervals still crossed zero because positive events were
rare. The results support candidacy, not certainty.

## Reliability-Driven Revision

The original v1 prospective shadow list concentrated 55.3% of one small
segment inside the top-risk group, producing an 11.1× concentration ratio.
This occurred despite globally stable score PSI, demonstrating why score drift
alone is not a sufficient release gate.

The v1.1 revision removed location from model features:

| Final Champion check | Result |
|---|---:|
| Score PSI | 0.00326 |
| P99 score ratio | 1.02 |
| Maximum segment concentration | 1.06 |
| Maximum within-segment selection rate | 5.29% |
| Reliability status | PASS |

The revision accepted a modest retrospective reduction in top-5% capture in
exchange for a more portable and operationally credible prospective score
distribution.

## Claim Boundary

The model ranks churn risk. It does not establish:

- a causal explanation for churn;
- that a high-risk customer will definitely leave;
- that contacting a customer will increase return behavior;
- that the first prospective list is ready for intervention.

Those claims require mature prospective outcomes and a controlled operational
experiment.
