library(testthat)
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "shiny_helpers.R"))

test_that("validate_upload_schema accepts valid data", {
  df <- data.frame(
    rep_id = "REP001",
    rep_name = "Rep A",
    tenure_months = 24,
    calls_made = 50,
    followups_done = 30,
    meetings_scheduled = 10,
    deals_closed = 3,
    revenue_generated = 15000,
    quota = 10000,
    territory_size = 100,
    period = "Q1-2025"
  )

  result <- validate_upload_schema(df)
  expect_true(result$valid)
  expect_equal(result$message, "")
})

test_that("validate_upload_schema rejects data with missing columns", {
  df <- data.frame(
    rep_id = "REP001",
    rep_name = "Rep A"
  )

  result <- validate_upload_schema(df)
  expect_false(result$valid)
  expect_match(result$message, "Missing required columns:")
  expect_match(result$message, "tenure_months")
})

test_that("validate_upload_schema rejects empty data", {
  df <- data.frame()

  result <- validate_upload_schema(df)
  expect_false(result$valid)
  expect_match(result$message, "empty")
})

test_that("validate_upload_schema rejects non-dataframe input", {
  result <- validate_upload_schema("not a dataframe")
  expect_false(result$valid)
  expect_match(result$message, "empty|not a valid")
})

test_that("normalize_three_weights maintains proportions", {
  result <- normalize_three_weights(0.5, 0.3, 0.2)
  expect_equal(result[["activity"]], 0.5)
  expect_equal(result[["conversion"]], 0.3)
  expect_equal(result[["revenue"]], 0.2)
  expect_equal(sum(result), 1.0)
})

test_that("normalize_three_weights handles equal values", {
  result <- normalize_three_weights(1.0, 1.0, 1.0)
  expect_equal(result[["activity"]], 1 / 3, tolerance = 0.001)
  expect_equal(result[["conversion"]], 1 / 3, tolerance = 0.001)
  expect_equal(result[["revenue"]], 1 / 3, tolerance = 0.001)
  expect_equal(sum(result), 1.0)
})

test_that("normalize_three_weights handles all-zero input", {
  result <- normalize_three_weights(0, 0, 0)
  expect_equal(sum(result), 1.0)
  expect_true(all(result > 0))
})

test_that("normalize_three_weights handles one-zero case", {
  result <- normalize_three_weights(0.6, 0.4, 0)
  expect_equal(result[["activity"]], 0.6)
  expect_equal(result[["conversion"]], 0.4)
  expect_equal(result[["revenue"]], 0.0)
  expect_equal(sum(result), 1.0)
})

test_that("normalize_three_weights rescales non-unit sums", {
  result <- normalize_three_weights(2, 2, 1)
  expect_equal(result[["activity"]], 0.4)
  expect_equal(result[["conversion"]], 0.4)
  expect_equal(result[["revenue"]], 0.2)
  expect_equal(sum(result), 1.0)
})

test_that("format_row_summary produces correct output", {
  df <- data.frame(
    rep_id = rep(c("REP001", "REP002"), each = 4),
    period = rep(c("Q1", "Q2", "Q3", "Q4"), 2)
  )

  result <- format_row_summary(df)
  expect_match(result, "Loaded 8 rows")
  expect_match(result, "2 reps")
  expect_match(result, "4 periods")
})
