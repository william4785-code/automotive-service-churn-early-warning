module_files <- c(
  "R/config.R",
  "R/data_access.R",
  "R/synthetic_data.R",
  "R/labels.R",
  "R/feature_engineering.R",
  "R/modeling.R",
  "R/validation.R",
  "R/scoring.R",
  "R/monitoring.R"
)
invisible(lapply(module_files, source, encoding = "UTF-8"))

config <- churn_config()
dir.create(config$output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(config$model_dir, recursive = TRUE, showWarnings = FALSE)

vehicle_months <- generate_synthetic_vehicle_months(seed = config$seed)
labeled <- build_three_month_labels(vehicle_months)
model_data <- prepare_model_population(
  labeled,
  maximum_days_since_last_service =
    config$maximum_days_since_last_service
)

available_validation_months <- sort(unique(model_data$base_month))
validation_months <- tail(available_validation_months, 3L)
backtest <- rolling_backtest(
  data = model_data,
  validation_months = validation_months,
  top_fraction = config$top_fraction
)

final_models <- fit_model_roles(model_data)
prospective <- prepare_prospective_population(
  vehicle_months,
  maximum_days_since_last_service =
    config$maximum_days_since_last_service
)
scored <- score_prospective_cohort(
  prospective,
  final_models$champion,
  top_fraction = config$top_fraction
)
reference_score <- predict_churn_probability(
  final_models$champion,
  model_data
)
reliability <- run_reliability_gate(
  reference_score = reference_score,
  scored_data = scored,
  segment_column = "site_id"
)

write.csv(
  backtest,
  file.path(config$output_dir, "synthetic_backtest_results.csv"),
  row.names = FALSE
)
write.csv(
  reliability$summary,
  file.path(config$output_dir, "synthetic_reliability_summary.csv"),
  row.names = FALSE
)

message("\nSynthetic rolling backtest:")
print(
  backtest[
    ,
    c(
      "validation_month",
      "model_role",
      "events",
      "pr_auc",
      "top_lift",
      "top_capture_rate"
    )
  ],
  row.names = FALSE
)
message("\nSynthetic prospective reliability gate:")
print(reliability$summary, row.names = FALSE)
message(
  "\nDemo outputs were written to ",
  normalizePath(config$output_dir, winslash = "/", mustWork = FALSE)
)
