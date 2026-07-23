testthat::test_that("third-month label uses the exact future horizon", {
  months <- add_months(as.Date("2026-01-01"), 0:3)
  panel <- data.frame(
    vehicle_id = c(rep("SYN-A", 3), rep("SYN-B", 4)),
    base_month = c(months[1:3], months),
    stringsAsFactors = FALSE
  )

  labeled <- build_three_month_labels(panel)
  january <- labeled[labeled$base_month == as.Date("2026-01-01"), ]

  testthat::expect_true(january$churn_3m[january$vehicle_id == "SYN-A"])
  testthat::expect_false(january$churn_3m[january$vehicle_id == "SYN-B"])
  testthat::expect_equal(
    unique(january$label_end_month),
    as.Date("2026-04-01")
  )
})

testthat::test_that("duplicate vehicle-month keys are rejected", {
  duplicated_panel <- data.frame(
    vehicle_id = c("SYN-A", "SYN-A"),
    base_month = as.Date(c("2026-01-01", "2026-01-01"))
  )
  testthat::expect_error(
    build_three_month_labels(duplicated_panel),
    "duplicate"
  )
})
