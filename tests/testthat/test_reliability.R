testthat::test_that("stable scores and balanced segments pass", {
  reference <- seq(0.001, 0.2, length.out = 1000)
  scored <- data.frame(
    site_id = rep(sprintf("SITE_%02d", 1:5), times = 200),
    risk_probability = reference,
    top_risk_flag = rank(-reference, ties.method = "first") <= 50
  )
  gate <- run_reliability_gate(reference, scored)
  testthat::expect_equal(gate$summary$status, "PASS")
})

testthat::test_that("extreme segment concentration is held", {
  reference <- seq(0.001, 0.2, length.out = 1000)
  scored <- data.frame(
    site_id = rep(sprintf("SITE_%02d", 1:5), each = 200),
    risk_probability = reference,
    top_risk_flag = FALSE
  )
  scored$top_risk_flag[1:50] <- TRUE
  gate <- run_reliability_gate(reference, scored)
  testthat::expect_equal(gate$summary$status, "HOLD")
  testthat::expect_gt(
    gate$summary$maximum_segment_concentration,
    3
  )
})
