build_three_month_labels <- function(vehicle_months) {
  assert_columns(
    vehicle_months,
    c("vehicle_id", "base_month"),
    "vehicle-month data"
  )

  data <- vehicle_months
  data$base_month <- month_start(data$base_month)

  duplicate_key <- duplicated(data[c("vehicle_id", "base_month")])
  if (any(duplicate_key)) {
    stop(
      "vehicle-month data contains duplicate vehicle_id/base_month keys.",
      call. = FALSE
    )
  }

  last_observed_month <- max(data$base_month)
  eligible <- data$base_month <= add_months(last_observed_month, -3L)
  labeled <- data[eligible, , drop = FALSE]

  presence_key <- paste(data$vehicle_id, data$base_month, sep = "|")
  presence_at <- function(offset) {
    target_key <- paste(
      labeled$vehicle_id,
      add_months(labeled$base_month, offset),
      sep = "|"
    )
    target_key %in% presence_key
  }

  labeled$present_m1 <- presence_at(1L)
  labeled$present_m2 <- presence_at(2L)
  labeled$present_m3 <- presence_at(3L)
  labeled$label_end_month <- add_months(labeled$base_month, 3L)
  labeled$ever_absent_3m <- !labeled$present_m1 |
    !labeled$present_m2 |
    !labeled$present_m3
  labeled$churn_3m <- !labeled$present_m3
  rownames(labeled) <- NULL
  labeled
}
