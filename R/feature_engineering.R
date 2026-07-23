prepare_model_population <- function(
  labeled_data,
  maximum_days_since_last_service = 600
) {
  required <- c(
    required_vehicle_month_columns(),
    "label_end_month",
    "churn_3m"
  )
  assert_columns(labeled_data, required, "labeled data")

  qualifying_relationships <- c(
    "home_site",
    "same_network_other_site"
  )
  keep <- !is.na(labeled_data$days_since_last_service) &
    labeled_data$days_since_last_service < maximum_days_since_last_service &
    labeled_data$return_relationship %in% qualifying_relationships

  output <- labeled_data[keep, , drop = FALSE]
  output$sales_amount_last_3m_log <- sign(output$sales_amount_last_3m) *
    log1p(abs(output$sales_amount_last_3m))
  output$days_since_actual_visit_3m <- ifelse(
    is.na(output$days_since_actual_visit_3m),
    100,
    output$days_since_actual_visit_3m
  )

  factor_columns <- c(
    "return_relationship",
    "usage_frequency",
    "uio_310",
    "uio_412"
  )
  output[factor_columns] <- lapply(output[factor_columns], factor)
  output$churn_3m <- as.logical(output$churn_3m)
  rownames(output) <- NULL
  output
}

prepare_prospective_population <- function(
  vehicle_months,
  scoring_month = max(vehicle_months$base_month),
  maximum_days_since_last_service = 600
) {
  scoring_month <- month_start(scoring_month)
  current <- vehicle_months[
    month_start(vehicle_months$base_month) == scoring_month,
    ,
    drop = FALSE
  ]

  if (nrow(current) == 0L) {
    stop("No prospective records exist for the scoring month.", call. = FALSE)
  }

  qualifying_relationships <- c(
    "home_site",
    "same_network_other_site"
  )
  keep <- !is.na(current$days_since_last_service) &
    current$days_since_last_service < maximum_days_since_last_service &
    current$return_relationship %in% qualifying_relationships
  output <- current[keep, , drop = FALSE]
  output$sales_amount_last_3m_log <- sign(output$sales_amount_last_3m) *
    log1p(abs(output$sales_amount_last_3m))
  output$days_since_actual_visit_3m <- ifelse(
    is.na(output$days_since_actual_visit_3m),
    100,
    output$days_since_actual_visit_3m
  )

  factor_columns <- c(
    "return_relationship",
    "usage_frequency",
    "uio_310",
    "uio_412"
  )
  output[factor_columns] <- lapply(output[factor_columns], factor)
  rownames(output) <- NULL
  output
}
