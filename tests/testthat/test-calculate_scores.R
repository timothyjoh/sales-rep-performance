library(testthat)
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "scoring_utils.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "normalization.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "dimension_scoring.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "calculate_scores.R"))

test_that("validate_weights accepts valid weights", {
  expect_silent(validate_weights(c(
    activity = 0.333, conversion = 0.334, revenue = 0.333
  )))
  expect_silent(validate_weights(c(
    activity = 0.5, conversion = 0.3, revenue = 0.2
  )))
  expect_silent(validate_weights(c(
    activity = 1.0, conversion = 0.0, revenue = 0.0
  )))
})

test_that("validate_weights rejects weights that don't sum to 1.0", {
  expect_error(
    validate_weights(c(activity = 0.3, conversion = 0.4, revenue = 0.29)),
    "Weights sum to 0.99, must sum to 1.0"
  )

  expect_error(
    validate_weights(c(activity = 0.3, conversion = 0.4, revenue = 0.31)),
    "Weights sum to 1.01, must sum to 1.0"
  )
})

test_that("validate_weights rejects negative weights", {
  expect_error(
    validate_weights(c(activity = -0.1, conversion = 0.6, revenue = 0.5)),
    "All weights must be non-negative"
  )
})

test_that("validate_weights rejects missing or wrong names", {
  expect_error(
    validate_weights(c(0.333, 0.334, 0.333)),
    "Weights must be a named numeric vector"
  )

  expect_error(
    validate_weights(c(activity = 0.333, wrong_name = 0.334, revenue = 0.333)),
    "Weights must have exactly three names: activity, conversion, revenue"
  )

  expect_error(
    validate_weights("not_numeric"),
    "Weights must be a named numeric vector"
  )
})

test_that("calculate_scores produces all required columns", {
  df <- tibble::tibble(
    rep_id = c("REP001", "REP002", "REP003"),
    rep_name = c("Rep A", "Rep B", "Rep C"),
    tenure_months = c(12, 36, 60),
    calls_made = c(80, 120, 150),
    followups_done = c(40, 60, 75),
    meetings_scheduled = c(15, 25, 30),
    deals_closed = c(5, 10, 15),
    revenue_generated = c(50000, 100000, 150000),
    quota = c(100000, 100000, 100000),
    territory_size = c(100, 150, 200),
    period = c("Q1-2025", "Q1-2025", "Q1-2025")
  )

  result <- calculate_scores(df)

  # Check all score columns present
  expect_true("activity_score" %in% names(result))
  expect_true("conversion_score" %in% names(result))
  expect_true("revenue_score" %in% names(result))
  expect_true("score" %in% names(result))

  # Check all scores in 0-100 range
  expect_true(all(result$activity_score >= 0 & result$activity_score <= 100))
  expect_true(all(result$conversion_score >= 0 &
    result$conversion_score <= 100))
  expect_true(all(result$revenue_score >= 0 & result$revenue_score <= 100))
  expect_true(all(result$score >= 0 & result$score <= 100))
})

test_that("calculate_scores removes intermediate normalization columns", {
  df <- tibble::tibble(
    rep_id = c("REP001", "REP002"),
    rep_name = c("Rep A", "Rep B"),
    tenure_months = c(12, 36),
    calls_made = c(100, 150),
    followups_done = c(50, 75),
    meetings_scheduled = c(20, 30),
    deals_closed = c(5, 10),
    revenue_generated = c(50000, 100000),
    quota = c(100000, 100000),
    territory_size = c(100, 200),
    period = c("Q1-2025", "Q1-2025")
  )

  result <- calculate_scores(df)

  # Intermediate columns should be removed
  expect_false("tenure_factor" %in% names(result))
  expect_false("territory_factor" %in% names(result))
  expect_false("quota_attainment" %in% names(result))
})

test_that("calculate_scores respects custom weights", {
  df <- tibble::tibble(
    rep_id = c("REP001", "REP002"),
    rep_name = c("Rep A", "Rep B"),
    tenure_months = c(12, 12),
    calls_made = c(0, 100),
    followups_done = c(0, 50),
    meetings_scheduled = c(0, 20),
    deals_closed = c(10, 5),
    revenue_generated = c(100000, 50000),
    quota = c(100000, 100000),
    territory_size = c(100, 100),
    period = c("Q1-2025", "Q1-2025")
  )

  # REP001: Zero activity, high revenue
  # REP002: High activity, low revenue

  # Weight heavily toward activity
  result_activity <- calculate_scores(
    df, c(activity = 0.8, conversion = 0.1, revenue = 0.1)
  )
  expect_true(result_activity$score[2] > result_activity$score[1])

  # Weight heavily toward revenue
  result_revenue <- calculate_scores(
    df, c(activity = 0.1, conversion = 0.1, revenue = 0.8)
  )
  expect_true(result_revenue$score[1] > result_revenue$score[2])
})

test_that("calculate_scores handles edge cases without errors", {
  df <- tibble::tibble(
    rep_id = c("REP001", "REP002"),
    rep_name = c("Rep A", "Rep B"),
    tenure_months = c(1, 120),
    calls_made = c(0, 200),
    followups_done = c(0, 100),
    meetings_scheduled = c(0, 50),
    deals_closed = c(0, 20),
    revenue_generated = c(0, 300000),
    quota = c(100000, 100000),
    territory_size = c(50, 500),
    period = c("Q1-2025", "Q1-2025")
  )

  result <- calculate_scores(df)

  expect_false(any(is.na(result$score)))
  expect_false(any(is.infinite(result$score)))
  expect_true(all(result$score >= 0 & result$score <= 100))
})

test_that("calculate_scores errors on missing columns", {
  df <- tibble::tibble(rep_id = "REP001")
  expect_error(calculate_scores(df), "Required columns missing")
})

test_that("calculate_scores preserves original columns", {
  df <- tibble::tibble(
    rep_id = c("REP001", "REP002"),
    rep_name = c("Rep A", "Rep B"),
    tenure_months = c(12, 36),
    calls_made = c(100, 150),
    followups_done = c(50, 75),
    meetings_scheduled = c(20, 30),
    deals_closed = c(5, 10),
    revenue_generated = c(50000, 100000),
    quota = c(100000, 100000),
    territory_size = c(100, 200),
    period = c("Q1-2025", "Q1-2025")
  )

  original_cols <- names(df)
  result <- calculate_scores(df)

  expect_true(all(original_cols %in% names(result)))
})
