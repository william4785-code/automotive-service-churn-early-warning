generate_synthetic_vehicle_months <- function(
  n_vehicles = 2500L,
  n_months = 18L,
  start_month = as.Date("2025-01-01"),
  seed = 20260723L
) {
  if (n_months < 8L) {
    stop("n_months must be at least 8.", call. = FALSE)
  }

  set.seed(seed)
  months <- add_months(start_month, 0:(n_months - 1L))
  vehicle_id <- sprintf("SYN-%06d", seq_len(n_vehicles))

  profile <- data.frame(
    vehicle_id = vehicle_id,
    site_id = sample(sprintf("SITE_%02d", 1:5), n_vehicles, replace = TRUE),
    initial_age = runif(n_vehicles, 0.5, 14),
    annual_mileage = pmax(2500, rnorm(n_vehicles, 12000, 4500)),
    usage_frequency = sample(
      c("low", "medium", "high"),
      n_vehicles,
      replace = TRUE,
      prob = c(0.25, 0.55, 0.20)
    ),
    uio_310 = sample(c(FALSE, TRUE), n_vehicles, replace = TRUE),
    uio_412 = sample(
      c(FALSE, TRUE),
      n_vehicles,
      replace = TRUE,
      prob = c(0.18, 0.82)
    ),
    return_relationship = sample(
      c("home_site", "same_network_other_site", "outside_network"),
      n_vehicles,
      replace = TRUE,
      prob = c(0.90, 0.09, 0.01)
    ),
    stringsAsFactors = FALSE
  )

  exit_probability <- plogis(
    -3.15 +
      0.35 * (profile$usage_frequency == "low") +
      0.25 * (profile$initial_age > 9)
  )
  will_exit <- rbinom(n_vehicles, 1, exit_probability) == 1
  exit_index <- rep(Inf, n_vehicles)
  eligible_exit_months <- seq.int(10L, n_months - 1L)
  exit_index[will_exit] <- sample(
    eligible_exit_months,
    sum(will_exit),
    replace = TRUE
  )

  panel <- merge(
    profile,
    data.frame(
      month_index = seq_len(n_months),
      base_month = months
    ),
    by = NULL
  )
  panel$exit_index <- exit_index[match(panel$vehicle_id, profile$vehicle_id)]
  panel <- panel[panel$month_index < panel$exit_index, , drop = FALSE]

  months_to_exit <- panel$exit_index - panel$month_index
  near_exit <- is.finite(months_to_exit) & months_to_exit >= 1 &
    months_to_exit <= 3

  visits_lambda <- pmax(
    0.05,
    0.55 +
      0.30 * (panel$usage_frequency == "high") -
      0.18 * near_exit
  )
  panel$visits_last_3m <- rpois(nrow(panel), visits_lambda)
  panel$general_repairs_last_3m <- rpois(
    nrow(panel),
    0.10 + 0.08 * (panel$visits_last_3m > 0)
  )
  panel$body_repairs_last_3m <- rpois(
    nrow(panel),
    0.025 + 0.42 * near_exit
  )
  panel$inspections_last_3m <- rpois(
    nrow(panel),
    0.06 + 0.06 * (panel$initial_age < 3)
  )
  panel$sales_amount_last_3m <- round(
    rgamma(
      nrow(panel),
      shape = 1.4,
      scale = 1800
    ) * (panel$visits_last_3m > 0),
    0
  )

  has_recent_visit <- panel$visits_last_3m > 0
  panel$days_since_actual_visit_3m <- NA_real_
  panel$days_since_actual_visit_3m[has_recent_visit] <- sample(
    2:90,
    sum(has_recent_visit),
    replace = TRUE
  )
  panel$days_since_last_service <- ifelse(
    has_recent_visit,
    panel$days_since_actual_visit_3m,
    pmin(
      720,
      round(
        80 +
          panel$month_index * 11 +
          rexp(nrow(panel), rate = 1 / 70)
      )
    )
  )
  panel$vehicle_age_years <- panel$initial_age +
    (panel$month_index - 1) / 12
  panel$last_service_mileage <- pmax(
    0,
    round(
      panel$annual_mileage *
        panel$vehicle_age_years +
        rnorm(nrow(panel), 0, 1800)
    )
  )

  output <- panel[
    ,
    required_vehicle_month_columns(),
    drop = FALSE
  ]
  output$base_month <- as.Date(output$base_month)
  output <- output[order(output$base_month, output$vehicle_id), ]
  rownames(output) <- NULL
  output
}
