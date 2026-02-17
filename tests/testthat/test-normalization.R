library(testthat)
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "scoring_utils.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "normalization.R"))

test_that("normalize_tenure calculates tenure factor correctly", {
  df <- tibble::tibble(
    rep_id = c("REP001", "REP002", "REP003", "REP004"),
    tenure_months = c(6, 30, 60, 120)
  )

  result <- normalize_tenure(df)

  expect_true("tenure_factor" %in% names(result))
  expect_equal(result$tenure_factor[1], 0.1)   # 6/60 = 0.1
  expect_equal(result$tenure_factor[2], 0.5)   # 30/60 = 0.5
  expect_equal(result$tenure_factor[3], 1.0)   # 60/60 = 1.0 (capped)
  expect_equal(result$tenure_factor[4], 1.0)   # 120/60 = 2.0 -> capped at 1.0
})

test_that("normalize_tenure handles zero tenure", {
  df <- tibble::tibble(tenure_months = 0)
  result <- normalize_tenure(df)
  expect_equal(result$tenure_factor, 0)
})

test_that("normalize_tenure errors on negative tenure", {
  df <- tibble::tibble(tenure_months = c(10, -5))
  expect_error(
    normalize_tenure(df),
    "Column 'tenure_months' cannot contain negative values"
  )
})

test_that("normalize_tenure errors on missing column", {
  df <- tibble::tibble(rep_id = "REP001")
  expect_error(
    normalize_tenure(df),
    "Required columns missing: tenure_months"
  )
})

test_that("normalize_territory calculates territory factor correctly", {
  df <- tibble::tibble(
    rep_id = c("REP001", "REP002", "REP003"),
    territory_size = c(50, 100, 400)
  )

  result <- normalize_territory(df)

  expect_true("territory_factor" %in% names(result))
  expect_equal(result$territory_factor[1], 0.5)  # 50/100 = 0.5
  expect_equal(result$territory_factor[2], 1.0)  # 100/100 = 1.0
  expect_equal(result$territory_factor[3], 4.0)  # 400/100 = 4.0
})

test_that("normalize_territory errors on negative territory_size", {
  df <- tibble::tibble(territory_size = c(100, -50))
  expect_error(
    normalize_territory(df),
    "Column 'territory_size' cannot contain negative values"
  )
})

test_that("normalize_territory errors on missing column", {
  df <- tibble::tibble(rep_id = "REP001")
  expect_error(
    normalize_territory(df),
    "Required columns missing: territory_size"
  )
})

test_that("normalize_quota calculates quota attainment correctly", {
  df <- tibble::tibble(
    rep_id = c("REP001", "REP002", "REP003"),
    revenue_generated = c(50000, 100000, 200000),
    quota = c(100000, 100000, 100000)
  )

  result <- normalize_quota(df)

  expect_true("quota_attainment" %in% names(result))
  expect_equal(result$quota_attainment[1], 50)   # 50k/100k = 50%
  expect_equal(result$quota_attainment[2], 100)  # 100k/100k = 100%
  expect_equal(result$quota_attainment[3], 200)  # 200k/100k = 200% (uncapped)
})

test_that("normalize_quota handles zero revenue gracefully", {
  df <- tibble::tibble(revenue_generated = 0, quota = 100000)
  result <- normalize_quota(df)
  expect_equal(result$quota_attainment, 0)
})

test_that("normalize_quota errors on zero quota", {
  df <- tibble::tibble(revenue_generated = 100000, quota = 0)
  expect_error(
    normalize_quota(df),
    "quota.*cannot contain zero|must be.*positive"
  )
})

test_that("normalize_quota errors on negative values", {
  df1 <- tibble::tibble(revenue_generated = -1000, quota = 100000)
  expect_error(normalize_quota(df1), "cannot contain negative values")

  df2 <- tibble::tibble(revenue_generated = 100000, quota = -50000)
  expect_error(normalize_quota(df2), "cannot contain negative values")
})

test_that("normalize_quota errors on missing columns", {
  df <- tibble::tibble(rep_id = "REP001")
  expect_error(normalize_quota(df), "Required columns missing")
})
