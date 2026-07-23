testthat::test_that("purged training labels mature before validation", {
  data <- data.frame(
    base_month = add_months(as.Date("2025-01-01"), 0:7),
    label_end_month = add_months(as.Date("2025-01-01"), 3:10),
    churn_3m = rep(c(FALSE, TRUE), 4),
    feature = seq_len(8)
  )

  split <- purged_time_split(
    data = data,
    validation_month = as.Date("2025-08-01"),
    feature_names = "feature"
  )

  testthat::expect_true(
    max(split$train$label_end_month) < as.Date("2025-08-01")
  )
  testthat::expect_equal(
    unique(split$validation$base_month),
    as.Date("2025-08-01")
  )
})

testthat::test_that("top-risk evaluation respects review capacity", {
  metrics <- evaluate_ranked_predictions(
    actual = c(TRUE, FALSE, FALSE, TRUE, rep(FALSE, 16)),
    probability = seq(1, 0.05, length.out = 20),
    top_fraction = 0.05
  )
  testthat::expect_equal(metrics$top_n, 1)
})
