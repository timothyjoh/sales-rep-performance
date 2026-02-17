library(testthat)
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "scoring_utils.R"))

test_that("validate_columns detects missing columns", {
  df <- tibble::tibble(rep_id = "REP001", score = 85)

  # Should pass with all columns present
  expect_silent(validate_columns(df, c("rep_id", "score")))

  # Should error with one missing column
  expect_error(
    validate_columns(df, c("rep_id", "missing_col")),
    "Required columns missing: missing_col"
  )

  # Should error with multiple missing columns
  expect_error(
    validate_columns(df, c("rep_id", "col1", "col2")),
    "Required columns missing: col1, col2"
  )
})

test_that("validate_non_negative detects negative values", {
  df <- tibble::tibble(tenure_months = c(1, 12, 36))

  # Should pass with all positive values
  expect_silent(validate_non_negative(df, "tenure_months"))

  # Should pass with zero values
  df_zero <- tibble::tibble(tenure_months = c(0, 12, 36))
  expect_silent(validate_non_negative(df_zero, "tenure_months"))

  # Should error with negative value
  df_bad <- tibble::tibble(tenure_months = c(1, -5, 36))
  expect_error(
    validate_non_negative(df_bad, "tenure_months"),
    "Column 'tenure_months' cannot contain negative values"
  )
})

test_that("percentile_rank scales correctly", {
  # Basic ascending values
  expect_equal(percentile_rank(c(10, 20, 30)), c(0, 50, 100))

  # Ties should get average rank
  expect_equal(percentile_rank(c(10, 20, 20, 30)), c(0, 50, 50, 100))

  # All same values (non-zero)
  expect_equal(percentile_rank(c(5, 5, 5)), c(50, 50, 50))

  # All zeros edge case
  expect_equal(percentile_rank(c(0, 0, 0)), c(0, 0, 0))

  # Single value
  expect_equal(percentile_rank(100), 0)

  # Descending values
  expect_equal(percentile_rank(c(30, 20, 10)), c(100, 50, 0))
})

test_that("percentile_rank handles large dataset with ties and outliers", {
  # 20 values: 10 tied at low value, 9 tied at mid value, 1 outlier
  x <- c(rep(10, 10), rep(50, 9), 1000)

  result <- percentile_rank(x)

  # Outlier should get rank 100
  expect_equal(result[20], 100)

  # Low-tied group should have same rank (clustered near bottom)
  expect_true(all(result[1:10] == result[1]),
              info = "All tied values should have identical rank")

  # Mid-tied group should be between low group and outlier
  expect_true(all(result[11:19] > result[1]) && all(result[11:19] < result[20]),
              info = "Mid-tier tied values should rank between low and high")

  # All ranks should be in 0-100 range
  expect_true(all(result >= 0 & result <= 100))
})
