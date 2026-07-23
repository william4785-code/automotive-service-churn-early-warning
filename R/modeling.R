align_factor_levels <- function(new_data, factor_levels) {
  output <- new_data

  for (column in names(factor_levels)) {
    output[[column]] <- factor(
      as.character(output[[column]]),
      levels = factor_levels[[column]]
    )
  }

  output
}

fit_churn_logistic <- function(
  training_data,
  feature_names,
  target = "churn_3m"
) {
  assert_columns(
    training_data,
    c(target, feature_names),
    "training data"
  )

  complete <- complete.cases(training_data[c(target, feature_names)])
  train <- droplevels(training_data[complete, , drop = FALSE])

  if (nrow(train) == 0L || length(unique(train[[target]])) < 2L) {
    stop(
      "Training data must contain complete rows and both target classes.",
      call. = FALSE
    )
  }

  factor_features <- feature_names[
    vapply(train[feature_names], is.factor, logical(1))
  ]
  factor_levels <- lapply(train[factor_features], levels)
  formula <- reformulate(feature_names, response = target)
  model <- glm(formula, data = train, family = binomial())

  structure(
    list(
      model = model,
      target = target,
      feature_names = feature_names,
      factor_levels = factor_levels,
      training_rows = nrow(train),
      training_events = sum(as.logical(train[[target]])),
      converged = isTRUE(model$converged)
    ),
    class = "churn_model_bundle"
  )
}

predict_churn_probability <- function(model_bundle, new_data) {
  assert_columns(
    new_data,
    model_bundle$feature_names,
    "scoring data"
  )
  aligned <- align_factor_levels(new_data, model_bundle$factor_levels)
  complete <- complete.cases(aligned[model_bundle$feature_names])
  probability <- rep(NA_real_, nrow(aligned))

  if (any(complete)) {
    probability[complete] <- predict(
      model_bundle$model,
      newdata = aligned[complete, , drop = FALSE],
      type = "response"
    )
  }

  probability
}

fit_model_roles <- function(
  training_data,
  model_specs = MODEL_SPECS,
  target = "churn_3m"
) {
  lapply(
    model_specs,
    function(spec) {
      fit_churn_logistic(
        training_data = training_data,
        feature_names = spec$feature_names,
        target = target
      )
    }
  )
}

freeze_model_bundle <- function(
  model_bundle,
  path,
  model_role,
  model_version = "pure_early_warning_v1.1"
) {
  if (file.exists(path)) {
    stop("Refusing to overwrite frozen model bundle: ", path, call. = FALSE)
  }

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  frozen <- list(
    model_version = model_version,
    model_role = model_role,
    immutable = TRUE,
    frozen_at = Sys.time(),
    feature_names = model_bundle$feature_names,
    factor_levels = model_bundle$factor_levels,
    training_rows = model_bundle$training_rows,
    training_events = model_bundle$training_events,
    model = model_bundle$model
  )
  saveRDS(frozen, path, compress = FALSE)
  invisible(path)
}
