score_prospective_cohort <- function(
  prospective_data,
  model_bundle,
  top_fraction = 0.05
) {
  probability <- predict_churn_probability(model_bundle, prospective_data)
  rank_position <- rank(
    -probability,
    ties.method = "first",
    na.last = "keep"
  )
  eligible_n <- sum(!is.na(probability))
  selected_n <- max(1L, ceiling(eligible_n * top_fraction))

  output <- prospective_data
  output$risk_probability <- probability
  output$risk_rank <- as.integer(rank_position)
  output$risk_percentile <- ifelse(
    is.na(rank_position),
    NA_real_,
    rank_position / eligible_n
  )
  output$top_risk_flag <- !is.na(rank_position) &
    rank_position <= selected_n
  output
}

create_scoring_registry_row <- function(
  scored_data,
  scoring_month,
  model_version,
  model_role
) {
  data.frame(
    model_version = model_version,
    model_role = model_role,
    scoring_month = month_start(scoring_month),
    eligible_rows = sum(!is.na(scored_data$risk_probability)),
    selected_rows = sum(scored_data$top_risk_flag, na.rm = TRUE),
    score_mean = mean(scored_data$risk_probability, na.rm = TRUE),
    score_p95 = unname(
      quantile(scored_data$risk_probability, 0.95, na.rm = TRUE)
    ),
    score_p99 = unname(
      quantile(scored_data$risk_probability, 0.99, na.rm = TRUE)
    ),
    scored_at = Sys.time()
  )
}
