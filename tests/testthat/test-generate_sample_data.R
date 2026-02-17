library(testthat)
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "generate_sample_data.R"))

test_that("generate_sample_data produces correct number of rows", {
  df_default <- generate_sample_data()
  expect_equal(nrow(df_default), 80)

  df_custom <- generate_sample_data(n_reps = 5, n_quarters = 2)
  expect_equal(nrow(df_custom), 10)

  df_minimal <- generate_sample_data(n_reps = 1, n_quarters = 1)
  expect_equal(nrow(df_minimal), 1)
})

test_that("generate_sample_data contains all required columns with correct types", {
  df <- generate_sample_data()

  expected_cols <- c(
    "rep_id", "rep_name", "tenure_months", "calls_made", "followups_done",
    "meetings_scheduled", "deals_closed", "revenue_generated", "quota",
    "territory_size", "period"
  )
  expect_equal(names(df), expected_cols)

  expect_type(df$rep_id, "character")
  expect_type(df$rep_name, "character")
  expect_type(df$period, "character")
  expect_true(is.integer(df$tenure_months))
  expect_true(is.integer(df$calls_made))
  expect_true(is.integer(df$followups_done))
  expect_true(is.integer(df$meetings_scheduled))
  expect_true(is.integer(df$deals_closed))
  expect_true(is.numeric(df$revenue_generated))  # Can be double
  expect_true(is.numeric(df$quota))  # Can be double
  expect_true(is.numeric(df$territory_size))  # Can be double
})

test_that("generate_sample_data produces realistic value ranges", {
  df <- generate_sample_data()

  expect_true(all(df$tenure_months >= 0))
  expect_true(all(df$calls_made >= 0))
  expect_true(all(df$followups_done >= 0))
  expect_true(all(df$meetings_scheduled >= 0))
  expect_true(all(df$deals_closed >= 0))
  expect_true(all(df$revenue_generated >= 0))
  expect_true(all(df$quota > 0))
  expect_true(all(df$territory_size > 0))

  expect_true(all(df$tenure_months <= 120))
  expect_true(all(df$calls_made <= 500))
  expect_true(all(df$deals_closed <= 50))

  expect_true(all(grepl("^Q[1-4]-2025$", df$period)))
})

test_that("generate_sample_data is reproducible with same seed", {
  df1 <- generate_sample_data(seed = 123)
  df2 <- generate_sample_data(seed = 123)

  expect_identical(df1, df2)

  df3 <- generate_sample_data(seed = 456)
  expect_false(identical(df1, df3))
})

test_that("generate_sample_data includes mix of rep profiles", {
  df <- generate_sample_data(n_reps = 30)

  new_reps <- sum(df$tenure_months <= 12) / nrow(df)
  mid_reps <- sum(df$tenure_months > 12 & df$tenure_months <= 36) / nrow(df)
  exp_reps <- sum(df$tenure_months > 36) / nrow(df)

  # Target distribution: 30% new, 40% mid, 30% experienced
  # Allow ±10% tolerance for randomness
  expect_true(new_reps >= 0.20 && new_reps <= 0.40,
              info = sprintf("New reps: %.1f%% (expected ~30%%)", new_reps * 100))
  expect_true(mid_reps >= 0.30 && mid_reps <= 0.50,
              info = sprintf("Mid reps: %.1f%% (expected ~40%%)", mid_reps * 100))
  expect_true(exp_reps >= 0.20 && exp_reps <= 0.40,
              info = sprintf("Exp reps: %.1f%% (expected ~30%%)", exp_reps * 100))
})
