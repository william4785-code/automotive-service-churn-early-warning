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
repository_root <- normalizePath(
  file.path("..", ".."),
  winslash = "/",
  mustWork = TRUE
)
invisible(
  lapply(
    file.path(repository_root, module_files),
    source,
    encoding = "UTF-8"
  )
)
