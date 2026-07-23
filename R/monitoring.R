calculate_psi <- function(reference_score, current_score, bins = 10L) {
  reference_score <- reference_score[is.finite(reference_score)]
  current_score <- current_score[is.finite(current_score)]

  if (length(reference_score) == 0L || length(current_score) == 0L) {
    return(NA_real_)
  }

  breaks <- unique(
    as.numeric(
      quantile(
        reference_score,
        probs = seq(0, 1, length.out = bins + 1L),
        na.rm = TRUE,
        names = FALSE
      )
    )
  )
  if (length(breaks) < 3L) {
    return(0)
  }
  breaks[1] <- -Inf
  breaks[length(breaks)] <- Inf

  reference_bin <- cut(reference_score, breaks, include.lowest = TRUE)
  current_bin <- cut(current_score, breaks, include.lowest = TRUE)
  reference_share <- prop.table(table(reference_bin))
  current_share <- prop.table(table(current_bin))
  levels_all <- union(names(reference_share), names(current_share))
  expected <- pmax(as.numeric(reference_share[levels_all]), 1e-6)
  actual <- pmax(as.numeric(current_share[levels_all]), 1e-6)
  expected[is.na(expected)] <- 1e-6
  actual[is.na(actual)] <- 1e-6
  sum((actual - expected) * log(actual / expected))
}

segment_concentration_audit <- function(
  scored_data,
  segment_column = "site_id"
) {
  assert_columns(
    scored_data,
    c(segment_column, "top_risk_flag"),
    "scored data"
  )
  segment <- as.character(scored_data[[segment_column]])
  selected <- as.logical(scored_data$top_risk_flag)
  population_n <- as.data.frame(table(segment), stringsAsFactors = FALSE)
  names(population_n) <- c("segment", "population_n")
  selected_n <- as.data.frame(
    table(segment[selected %in% TRUE]),
    stringsAsFactors = FALSE
  )
  names(selected_n) <- c("segment", "selected_n")
  audit <- merge(population_n, selected_n, by = "segment", all.x = TRUE)
  audit$selected_n[is.na(audit$selected_n)] <- 0L
  audit$population_share <- audit$population_n / sum(audit$population_n)
  total_selected <- sum(audit$selected_n)
  audit$selected_share <- if (total_selected > 0L) {
    audit$selected_n / total_selected
  } else {
    0
  }
  audit$concentration_ratio <- ifelse(
    audit$population_share > 0,
    audit$selected_share / audit$population_share,
    NA_real_
  )
  audit$selection_rate <- audit$selected_n / audit$population_n
  audit
}

run_reliability_gate <- function(
  reference_score,
  scored_data,
  segment_column = "site_id"
) {
  current_score <- scored_data$risk_probability
  psi <- calculate_psi(reference_score, current_score)
  reference_p99 <- unname(quantile(reference_score, 0.99, na.rm = TRUE))
  current_p99 <- unname(quantile(current_score, 0.99, na.rm = TRUE))
  p99_ratio <- if (reference_p99 > 0) {
    current_p99 / reference_p99
  } else {
    NA_real_
  }
  segment_audit <- segment_concentration_audit(
    scored_data,
    segment_column
  )
  max_concentration <- max(
    segment_audit$concentration_ratio,
    na.rm = TRUE
  )
  max_selection_rate <- max(segment_audit$selection_rate, na.rm = TRUE)

  status <- if (
    is.na(psi) ||
      is.na(p99_ratio) ||
      psi >= 0.25 ||
      p99_ratio > 3 ||
      max_concentration > 3 ||
      max_selection_rate > 0.20
  ) {
    "HOLD"
  } else if (psi >= 0.10 || p99_ratio > 2) {
    "WARN"
  } else {
    "PASS"
  }

  list(
    summary = data.frame(
      status = status,
      score_psi = psi,
      reference_p99 = reference_p99,
      current_p99 = current_p99,
      p99_ratio = p99_ratio,
      maximum_segment_concentration = max_concentration,
      maximum_segment_selection_rate = max_selection_rate
    ),
    segment_audit = segment_audit
  )
}
