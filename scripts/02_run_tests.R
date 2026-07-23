if (!requireNamespace("testthat", quietly = TRUE)) {
  stop(
    'Package "testthat" is required. Run install.packages("testthat").',
    call. = FALSE
  )
}

testthat::test_dir("tests/testthat", reporter = "summary")
