library(testthat)
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "scoring_utils.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "normalization.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "dimension_scoring.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "calculate_scores.R"))

test_that("end-to-end scoring pipeline works with sample data", {
  data_path <- file.path(
    rprojroot::find_root("DESCRIPTION"), "data", "sample_reps.csv"
  )
  data <- read.csv(data_path, stringsAsFactors = FALSE)

  result <- calculate_scores(data)

  # Validate output structure
  expect_equal(nrow(result), 80)
  expect_true(all(c("score", "activity_score", "conversion_score",
    "revenue_score") %in% names(result)))

  # Validate score ranges
  expect_true(all(result$score >= 0 & result$score <= 100))
  expect_true(all(result$activity_score >= 0 & result$activity_score <= 100))
  expect_true(all(result$conversion_score >= 0 &
    result$conversion_score <= 100))
  expect_true(all(result$revenue_score >= 0 & result$revenue_score <= 100))

  # Validate scores vary (not all identical)
  expect_true(length(unique(result$score)) > 10)

  # Validate no NA or Inf values
  expect_false(any(is.na(result$score)))
  expect_false(any(is.infinite(result$score)))
})

test_that("integration test validates known rep score correctness", {
  data_path <- file.path(
    rprojroot::find_root("DESCRIPTION"), "data", "sample_reps.csv"
  )
  data <- read.csv(data_path, stringsAsFactors = FALSE)
  result <- calculate_scores(data)

  # REP003 Q1-2025 (from scored_reps.csv review):
  # - High tenure (72 months -> tenure_factor = 1.0, capped)
  # - Low territory (54 accounts -> territory_factor = 0.54)
  # - High activity (129 calls, 72 followups, 36 meetings)
  # Expected: High activity_score (normalized activity / low territory = high rank)
  rep003_q1 <- result[result$rep_id == "REP003" & result$period == "Q1-2025", ]

  expect_true(
    rep003_q1$activity_score > 90,
    info = paste("REP003 Q1 activity_score =", rep003_q1$activity_score,
                 "— expected > 90 due to high tenure, low territory, high activity")
  )

  # REP012 Q1-2025 (from scored_reps.csv review):
  # - Very low tenure (4 months)
  # - Low activity (22 calls, 28 followups, 16 meetings)
  # - Very low revenue ($6,406 / $75k quota = 8.5%)
  # Expected: Low overall score
  rep012_q1 <- result[result$rep_id == "REP012" & result$period == "Q1-2025", ]

  expect_true(
    rep012_q1$score < 20,
    info = paste("REP012 Q1 score =", rep012_q1$score,
                 "— expected < 20 due to low tenure, low activity, low revenue")
  )
})

test_that("scoring handles all-identical input data gracefully", {
  df <- tibble::tibble(
    rep_id = paste0("REP", sprintf("%03d", 1:10)),
    rep_name = paste0("Rep ", LETTERS[1:10]),
    tenure_months = rep(12, 10),
    calls_made = rep(100, 10),
    followups_done = rep(50, 10),
    meetings_scheduled = rep(20, 10),
    deals_closed = rep(5, 10),
    revenue_generated = rep(50000, 10),
    quota = rep(100000, 10),
    territory_size = rep(100, 10),
    period = rep("Q1-2025", 10)
  )

  result <- calculate_scores(df)

  # All reps should have identical scores (percentile_rank handles ties)
  expect_equal(length(unique(result$activity_score)), 1,
               info = "All identical inputs should produce identical activity scores")
  expect_equal(length(unique(result$conversion_score)), 1)
  expect_equal(length(unique(result$revenue_score)), 1)
  expect_equal(length(unique(result$score)), 1)

  # Scores should be at midpoint (50) since all tied
  expect_equal(result$activity_score[1], 50)
  expect_equal(result$conversion_score[1], 50)
  expect_equal(result$revenue_score[1], 50)
  expect_equal(result$score[1], 50)
})

test_that("scoring pipeline preserves all input columns", {
  data_path <- file.path(
    rprojroot::find_root("DESCRIPTION"), "data", "sample_reps.csv"
  )
  data <- read.csv(data_path, stringsAsFactors = FALSE)

  original_cols <- names(data)
  result <- calculate_scores(data)

  expect_true(all(original_cols %in% names(result)))
})

# Suggestions Engine Integration Tests
test_that("generate_suggestions works with real scored data", {
  source(file.path(rprojroot::find_root("DESCRIPTION"),
                   "R", "generate_suggestions.R"))

  scored_data <- read.csv(
    file.path(rprojroot::find_root("DESCRIPTION"), "data", "scored_reps.csv"),
    stringsAsFactors = FALSE
  )

  suggestions <- generate_suggestions(scored_data)

  expect_true(is.data.frame(suggestions))
  expect_true(all(c("rep_id", "rep_name", "suggestion_category",
                     "suggestion_text") %in% names(suggestions)))

  # Scored data has diverse scores, expect at least some suggestions
  expect_true(nrow(suggestions) > 0)
  expect_true(nrow(suggestions) <= nrow(scored_data))

  # Validate category values
  valid_categories <- c("comprehensive_coaching", "mentorship",
                        "conversion_training", "increase_outreach",
                        "deal_sizing")
  expect_true(all(suggestions$suggestion_category %in% valid_categories))

  # Validate text is non-empty
  expect_true(all(nchar(suggestions$suggestion_text) > 0))
})

test_that("suggestions engine handles single-period data", {
  source(file.path(rprojroot::find_root("DESCRIPTION"),
                   "R", "generate_suggestions.R"))

  scored_data <- read.csv(
    file.path(rprojroot::find_root("DESCRIPTION"), "data", "scored_reps.csv"),
    stringsAsFactors = FALSE
  )
  single_period <- scored_data[scored_data$period == "Q1-2025", ]

  suggestions <- generate_suggestions(single_period)

  expect_true(is.data.frame(suggestions))
  expect_true(nrow(suggestions) <= nrow(single_period))
})

test_that("scoring with custom weights produces different results", {
  data_path <- file.path(
    rprojroot::find_root("DESCRIPTION"), "data", "sample_reps.csv"
  )
  data <- read.csv(data_path, stringsAsFactors = FALSE)

  result_default <- calculate_scores(data)
  result_custom <- calculate_scores(
    data, c(activity = 0.8, conversion = 0.1, revenue = 0.1)
  )

  # Scores should be different with different weights
  expect_false(all(result_default$score == result_custom$score))
})
