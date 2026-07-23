required_vehicle_month_columns <- function() {
  c(
    "vehicle_id",
    "base_month",
    "site_id",
    "vehicle_age_years",
    "days_since_last_service",
    "return_relationship",
    "last_service_mileage",
    "usage_frequency",
    "uio_310",
    "uio_412",
    "visits_last_3m",
    "general_repairs_last_3m",
    "body_repairs_last_3m",
    "inspections_last_3m",
    "sales_amount_last_3m",
    "days_since_actual_visit_3m"
  )
}

assert_columns <- function(data, required, object_name = "data") {
  missing <- setdiff(required, names(data))

  if (length(missing) > 0L) {
    stop(
      sprintf(
        "%s is missing required columns: %s",
        object_name,
        paste(missing, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  invisible(data)
}

read_vehicle_month_csv <- function(path) {
  if (!file.exists(path)) {
    stop("Vehicle-month input file does not exist: ", path, call. = FALSE)
  }

  data <- read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  assert_columns(data, required_vehicle_month_columns(), "vehicle-month data")
  data$base_month <- as.Date(data$base_month)
  data
}

write_synthetic_vehicle_month_csv <- function(data, path) {
  assert_columns(data, required_vehicle_month_columns(), "synthetic data")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write.csv(data, path, row.names = FALSE, na = "")
  invisible(path)
}

connect_production_source <- function(...) {
  stop(
    paste(
      "Production connectivity is intentionally excluded from this public",
      "edition. Implement a private adapter outside the repository."
    ),
    call. = FALSE
  )
}
