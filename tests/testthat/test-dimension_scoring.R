library(testthat)
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "scoring_utils.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "dimension_scoring.R"))

test_that("score_activity calculates activity score correctly", {
  df <- tibble::tibble(
    rep_id = c("REP001", "REP002", "REP003"),
    calls_made = c(50, 100, 150),
    followups_done = c(25, 50, 75),
    meetings_scheduled = c(10, 20, 30),
    tenure_factor = c(1.0, 1.0, 1.0),
    territory_factor = c(1.0, 1.0, 1.0)
  )

  result <- score_activity(df)

  expect_true("activity_score" %in% names(result))
  expect_equal(result$activity_score, c(0, 50, 100))
  expect_true(all(result$activity_score >= 0 & result$activity_score <= 100))
})

test_that("score_activity handles tenure and territory adjustments", {
  df <- tibble::tibble(
    calls_made = c(100, 100),
    followups_done = c(50, 50),
    meetings_scheduled = c(20, 20),
    tenure_factor = c(0.5, 1.0),
    territory_factor = c(1.0, 1.0)
  )

  result <- score_activity(df)

  # New rep (lower tenure_factor) should have lower activity score
  expect_true(result$activity_score[1] < result$activity_score[2])
})

test_that("score_activity adjusts for territory size", {
  df <- tibble::tibble(
    calls_made = c(100, 100),
    followups_done = c(50, 50),
    meetings_scheduled = c(20, 20),
    tenure_factor = c(1.0, 1.0),
    territory_factor = c(2.0, 1.0)
  )

  result <- score_activity(df)

  # Larger territory (higher factor) gets lower normalized activity
  expect_true(result$activity_score[1] < result$activity_score[2])
})

test_that("score_activity handles zero activity gracefully", {
  df <- tibble::tibble(
    calls_made = c(0, 100),
    followups_done = c(0, 50),
    meetings_scheduled = c(0, 20),
    tenure_factor = c(1.0, 1.0),
    territory_factor = c(1.0, 1.0)
  )

  result <- score_activity(df)

  expect_equal(result$activity_score[1], 0)
  expect_equal(result$activity_score[2], 100)
})

test_that("score_activity removes intermediate columns", {
  df <- tibble::tibble(
    calls_made = c(100),
    followups_done = c(50),
    meetings_scheduled = c(20),
    tenure_factor = c(1.0),
    territory_factor = c(1.0)
  )

  result <- score_activity(df)

  expect_false("calls_normalized" %in% names(result))
  expect_false("followups_normalized" %in% names(result))
  expect_false("meetings_normalized" %in% names(result))
  expect_false("activity_composite" %in% names(result))
})

test_that("score_conversion calculates conversion score correctly", {
  df <- tibble::tibble(
    rep_id = c("REP001", "REP002", "REP003"),
    deals_closed = c(5, 10, 15),
    meetings_scheduled = c(10, 20, 30),
    revenue_generated = c(50000, 100000, 150000),
    calls_made = c(100, 100, 100),
    followups_done = c(50, 50, 50)
  )

  result <- score_conversion(df)

  expect_true("conversion_score" %in% names(result))
  expect_true(all(result$conversion_score >= 0 & result$conversion_score <= 100))
})

test_that("score_conversion handles zero meetings gracefully", {
  df <- tibble::tibble(
    deals_closed = c(0, 10),
    meetings_scheduled = c(0, 20),
    revenue_generated = c(0, 100000),
    calls_made = c(50, 100),
    followups_done = c(25, 50)
  )

  result <- score_conversion(df)

  expect_false(any(is.na(result$conversion_score)))
  expect_false(any(is.infinite(result$conversion_score)))
})

test_that("score_conversion removes intermediate columns", {
  df <- tibble::tibble(
    deals_closed = c(10),
    meetings_scheduled = c(20),
    revenue_generated = c(100000),
    calls_made = c(100),
    followups_done = c(50)
  )

  result <- score_conversion(df)

  expect_false("meetings_to_deals" %in% names(result))
  expect_false("total_activities" %in% names(result))
  expect_false("revenue_per_activity" %in% names(result))
})

test_that("score_revenue calculates revenue score correctly", {
  df <- tibble::tibble(
    rep_id = c("REP001", "REP002", "REP003"),
    quota_attainment = c(50, 100, 150),
    revenue_generated = c(50000, 100000, 150000),
    deals_closed = c(5, 10, 15)
  )

  result <- score_revenue(df)

  expect_true("revenue_score" %in% names(result))
  expect_true(all(result$revenue_score >= 0 & result$revenue_score <= 100))
})

test_that("score_revenue handles zero deals gracefully", {
  df <- tibble::tibble(
    quota_attainment = c(0, 100),
    revenue_generated = c(0, 100000),
    deals_closed = c(0, 10)
  )

  result <- score_revenue(df)

  expect_false(any(is.na(result$revenue_score)))
  expect_false(any(is.infinite(result$revenue_score)))
})

test_that("score_revenue removes intermediate columns", {
  df <- tibble::tibble(
    quota_attainment = c(100),
    revenue_generated = c(100000),
    deals_closed = c(10)
  )

  result <- score_revenue(df)

  expect_false("quota_attainment_score" %in% names(result))
  expect_false("revenue_per_deal" %in% names(result))
  expect_false("revenue_per_deal_score" %in% names(result))
})

test_that("dimension scoring errors on missing columns", {
  df <- tibble::tibble(rep_id = "REP001")

  expect_error(score_activity(df), "Required columns missing")
  expect_error(score_conversion(df), "Required columns missing")
  expect_error(score_revenue(df), "Required columns missing")
})
