to_binary <- function(x) {
  if (is.factor(x)) {
    return(as.character(x) %in% c("TRUE", "1", "yes", "positive"))
  }
  as.logical(x)
}

binary_roc_auc <- function(actual, probability) {
  keep <- !is.na(actual) & !is.na(probability)
  y <- to_binary(actual[keep])
  score <- probability[keep]
  positives <- sum(y)
  negatives <- sum(!y)

  if (positives == 0L || negatives == 0L) {
    return(NA_real_)
  }

  ranks <- rank(score, ties.method = "average")
  (sum(ranks[y]) - positives * (positives + 1) / 2) /
    (positives * negatives)
}

average_precision <- function(actual, probability) {
  keep <- !is.na(actual) & !is.na(probability)
  y <- to_binary(actual[keep])
  score <- probability[keep]
  positives <- sum(y)

  if (positives == 0L) {
    return(NA_real_)
  }

  grouped <- aggregate(
    list(positive = as.integer(y), total = rep(1L, length(y))),
    by = list(score = score),
    FUN = sum
  )
  grouped <- grouped[order(grouped$score, decreasing = TRUE), ]
  cumulative_positive <- cumsum(grouped$positive)
  cumulative_total <- cumsum(grouped$total)
  recall <- cumulative_positive / positives
  precision <- cumulative_positive / cumulative_total
  previous_recall <- c(0, head(recall, -1L))
  sum((recall - previous_recall) * precision)
}

evaluate_ranked_predictions <- function(
  actual,
  probability,
  top_fraction = 0.05
) {
  keep <- !is.na(actual) & !is.na(probability)
  y <- to_binary(actual[keep])
  score <- probability[keep]

  if (length(y) == 0L) {
    stop("No complete predictions are available for evaluation.", call. = FALSE)
  }

  top_n <- max(1L, ceiling(length(y) * top_fraction))
  selected <- order(score, decreasing = TRUE, na.last = NA)[seq_len(top_n)]
  event_rate <- mean(y)
  top_event_rate <- mean(y[selected])

  data.frame(
    rows = length(y),
    events = sum(y),
    event_rate = event_rate,
    roc_auc = binary_roc_auc(y, score),
    pr_auc = average_precision(y, score),
    top_fraction = top_fraction,
    top_n = top_n,
    top_event_rate = top_event_rate,
    top_lift = if (event_rate > 0) top_event_rate / event_rate else NA_real_,
    top_capture_rate = if (sum(y) > 0) sum(y[selected]) / sum(y) else NA_real_
  )
}

purged_time_split <- function(
  data,
  validation_month,
  feature_names,
  target = "churn_3m"
) {
  validation_month <- month_start(validation_month)
  assert_columns(
    data,
    c("base_month", "label_end_month", target, feature_names),
    "model data"
  )

  train <- data[
    data$label_end_month < validation_month,
    ,
    drop = FALSE
  ]
  validation <- data[
    data$base_month == validation_month,
    ,
    drop = FALSE
  ]

  train <- train[
    complete.cases(train[c(target, feature_names)]),
    ,
    drop = FALSE
  ]
  validation <- validation[
    complete.cases(validation[c(target, feature_names)]),
    ,
    drop = FALSE
  ]

  if (nrow(train) == 0L || nrow(validation) == 0L) {
    stop("The purged split produced an empty partition.", call. = FALSE)
  }
  if (max(train$label_end_month) >= validation_month) {
    stop("Purge boundary violation detected.", call. = FALSE)
  }

  list(
    train = droplevels(train),
    validation = validation,
    validation_month = validation_month,
    train_base_start = min(train$base_month),
    train_base_end = max(train$base_month),
    train_label_end = max(train$label_end_month)
  )
}

rolling_backtest <- function(
  data,
  validation_months,
  model_specs = MODEL_SPECS,
  target = "churn_3m",
  top_fraction = 0.05
) {
  rows <- list()
  index <- 1L

  for (validation_index in seq_along(validation_months)) {
    validation_month <- validation_months[[validation_index]]
    for (role in names(model_specs)) {
      spec <- model_specs[[role]]
      split <- purged_time_split(
        data = data,
        validation_month = validation_month,
        feature_names = spec$feature_names,
        target = target
      )
      model <- fit_churn_logistic(
        training_data = split$train,
        feature_names = spec$feature_names,
        target = target
      )
      probability <- predict_churn_probability(model, split$validation)
      metrics <- evaluate_ranked_predictions(
        actual = split$validation[[target]],
        probability = probability,
        top_fraction = top_fraction
      )
      metrics$validation_month <- month_start(validation_month)
      metrics$model_role <- role
      metrics$model_name <- spec$display_name
      metrics$train_rows <- nrow(split$train)
      metrics$train_events <- sum(to_binary(split$train[[target]]))
      metrics$train_label_end <- split$train_label_end
      rows[[index]] <- metrics
      index <- index + 1L
    }
  }

  output <- do.call(rbind, rows)
  rownames(output) <- NULL
  output
}

paired_bootstrap_comparison <- function(
  actual,
  champion_probability,
  baseline_probability,
  repetitions = 500L,
  top_fraction = 0.05,
  seed = 20260723L
) {
  keep <- complete.cases(actual, champion_probability, baseline_probability)
  y <- actual[keep]
  champion <- champion_probability[keep]
  baseline <- baseline_probability[keep]
  set.seed(seed)

  difference <- replicate(repetitions, {
    sample_index <- sample.int(length(y), length(y), replace = TRUE)
    champion_metrics <- evaluate_ranked_predictions(
      y[sample_index],
      champion[sample_index],
      top_fraction
    )
    baseline_metrics <- evaluate_ranked_predictions(
      y[sample_index],
      baseline[sample_index],
      top_fraction
    )
    c(
      pr_auc = champion_metrics$pr_auc - baseline_metrics$pr_auc,
      top_lift = champion_metrics$top_lift - baseline_metrics$top_lift,
      top_capture_rate =
        champion_metrics$top_capture_rate -
        baseline_metrics$top_capture_rate
    )
  })

  data.frame(
    metric = rownames(difference),
    mean_difference = rowMeans(difference, na.rm = TRUE),
    lower_95 = apply(difference, 1, quantile, 0.025, na.rm = TRUE),
    upper_95 = apply(difference, 1, quantile, 0.975, na.rm = TRUE),
    win_rate = rowMeans(difference > 0, na.rm = TRUE),
    row.names = NULL
  )
}
