month_start <- function(x) {
  as.Date(format(as.Date(x), "%Y-%m-01"))
}

add_months <- function(x, n) {
  x <- month_start(x)
  year <- as.integer(format(x, "%Y"))
  month <- as.integer(format(x, "%m")) + as.integer(n)
  adjusted_year <- year + (month - 1L) %/% 12L
  adjusted_month <- (month - 1L) %% 12L + 1L
  as.Date(sprintf("%04d-%02d-01", adjusted_year, adjusted_month))
}

project_root <- function() {
  configured <- Sys.getenv("CHURN_PROJECT_DIR", unset = ".")
  normalizePath(configured, winslash = "/", mustWork = FALSE)
}

churn_config <- function() {
  root <- project_root()

  list(
    project_root = root,
    data_path = Sys.getenv(
      "CHURN_DATA_PATH",
      unset = file.path(root, "data", "synthetic_vehicle_months.csv")
    ),
    output_dir = Sys.getenv(
      "CHURN_OUTPUT_DIR",
      unset = file.path(root, "outputs")
    ),
    model_dir = Sys.getenv(
      "CHURN_MODEL_DIR",
      unset = file.path(root, "models")
    ),
    seed = as.integer(Sys.getenv("CHURN_SEED", unset = "20260723")),
    model_version = "pure_early_warning_v1.1",
    target = "churn_3m",
    horizon_months = 3L,
    behavior_window_months = 3L,
    maximum_days_since_last_service = 600,
    top_fraction = 0.05
  )
}

STATIC_FEATURES <- c(
  "vehicle_age_years",
  "days_since_last_service",
  "return_relationship",
  "last_service_mileage",
  "usage_frequency",
  "uio_310",
  "uio_412"
)

BEHAVIOR_FEATURES <- c(
  "visits_last_3m",
  "general_repairs_last_3m",
  "body_repairs_last_3m",
  "inspections_last_3m",
  "sales_amount_last_3m_log",
  "days_since_actual_visit_3m"
)

MODEL_SPECS <- list(
  champion = list(
    display_name = "Static + full service behavior logistic",
    feature_names = c(STATIC_FEATURES, BEHAVIOR_FEATURES)
  ),
  challenger = list(
    display_name = "Static + body repair logistic",
    feature_names = c(STATIC_FEATURES, "body_repairs_last_3m")
  ),
  baseline = list(
    display_name = "Static logistic",
    feature_names = STATIC_FEATURES
  )
)
