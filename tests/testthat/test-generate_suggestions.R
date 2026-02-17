library(testthat)
root <- rprojroot::find_root("DESCRIPTION")
source(file.path(root, "R", "generate_suggestions.R"))

# Test Rule 1: High Activity / Low Conversion
test_that("suggests conversion training for high activity low conversion", {
  data <- data.frame(
    rep_id = "REP001", rep_name = "Rep A",
    score = 60, activity_score = 76, conversion_score = 49, revenue_score = 60
  )
  result <- generate_suggestions(data)
  expect_equal(nrow(result), 1)
  expect_equal(result$suggestion_category, "conversion_training")
  expect_match(result$suggestion_text, "conversion rate")
})

# Test Rule 2: Low Activity / High Conversion
test_that("suggests increase outreach for low activity high conversion", {
  data <- data.frame(
    rep_id = "REP002", rep_name = "Rep B",
    score = 60, activity_score = 39, conversion_score = 71, revenue_score = 60
  )
  result <- generate_suggestions(data)
  expect_equal(nrow(result), 1)
  expect_equal(result$suggestion_category, "increase_outreach")
  expect_match(result$suggestion_text, "outreach volume")
})

# Test Rule 3: High Conversion / Low Revenue
test_that("suggests deal sizing for high conversion low revenue", {
  data <- data.frame(
    rep_id = "REP003", rep_name = "Rep C",
    score = 60, activity_score = 60, conversion_score = 76, revenue_score = 49
  )
  result <- generate_suggestions(data)
  expect_equal(nrow(result), 1)
  expect_equal(result$suggestion_category, "deal_sizing")
  expect_match(result$suggestion_text, "deal sizing")
})

# Test Rule 4: Low Overall Score
test_that("suggests comprehensive coaching for low overall score", {
  data <- data.frame(
    rep_id = "REP004", rep_name = "Rep D",
    score = 35, activity_score = 35, conversion_score = 35, revenue_score = 35
  )
  result <- generate_suggestions(data)
  expect_equal(nrow(result), 1)
  expect_equal(result$suggestion_category, "comprehensive_coaching")
  expect_match(result$suggestion_text, "skill gaps")
})

# Test Rule 5: High Overall Score
test_that("suggests mentorship for high overall score", {
  data <- data.frame(
    rep_id = "REP005", rep_name = "Rep E",
    score = 90, activity_score = 88, conversion_score = 90, revenue_score = 92
  )
  result <- generate_suggestions(data)
  expect_equal(nrow(result), 1)
  expect_equal(result$suggestion_category, "mentorship")
  expect_match(result$suggestion_text, "mentorship")
})

# Edge Case: Multiple rules match -> prioritize low overall score
test_that("prioritizes low overall score over dimension-specific rules", {
  data <- data.frame(
    rep_id = "REP006", rep_name = "Rep F",
    score = 38, activity_score = 80, conversion_score = 30, revenue_score = 35
  )
  result <- generate_suggestions(data)
  expect_equal(result$suggestion_category, "comprehensive_coaching")
})

# Edge Case: Mid-range scores -> no suggestion
test_that("returns empty data frame for mid-range scores", {
  data <- data.frame(
    rep_id = "REP007", rep_name = "Rep G",
    score = 55, activity_score = 52, conversion_score = 58, revenue_score = 55
  )
  result <- generate_suggestions(data)
  expect_equal(nrow(result), 0)
})

# Edge Case: Empty input
test_that("handles empty data frame gracefully", {
  empty_df <- data.frame(
    rep_id = character(0), rep_name = character(0),
    score = numeric(0), activity_score = numeric(0),
    conversion_score = numeric(0), revenue_score = numeric(0)
  )
  result <- generate_suggestions(empty_df)
  expect_equal(nrow(result), 0)
  expect_equal(ncol(result), 4)
  expect_true(all(c("rep_id", "rep_name", "suggestion_category",
                     "suggestion_text") %in% names(result)))
})

# Edge Case: Missing dimension scores (NA values)
test_that("handles NA dimension scores gracefully", {
  data <- data.frame(
    rep_id = "REP008", rep_name = "Rep H",
    score = 50, activity_score = NA, conversion_score = 60, revenue_score = 70
  )
  result <- generate_suggestions(data)
  expect_equal(nrow(result), 0)  # NA reps skipped, no crash
})

# Validation: Multiple reps input
test_that("processes multiple reps and returns suggestions for each", {
  data <- data.frame(
    rep_id = c("REP001", "REP002", "REP003"),
    rep_name = c("Rep A", "Rep B", "Rep C"),
    score = c(90, 38, 60),
    activity_score = c(88, 30, 80),
    conversion_score = c(90, 40, 40),
    revenue_score = c(92, 40, 60)
  )
  result <- generate_suggestions(data)
  expect_equal(nrow(result), 3)
  expect_true(all(c("REP001", "REP002", "REP003") %in% result$rep_id))
})

# Validation: Output schema
test_that("output has required columns with correct types", {
  data <- data.frame(
    rep_id = "REP001", rep_name = "Rep A",
    score = 90, activity_score = 88, conversion_score = 90, revenue_score = 92
  )
  result <- generate_suggestions(data)

  expect_equal(ncol(result), 4)
  expect_true(all(c("rep_id", "rep_name", "suggestion_category",
                     "suggestion_text") %in% names(result)))
  expect_type(result$rep_id, "character")
  expect_type(result$suggestion_category, "character")
  expect_type(result$suggestion_text, "character")
})

# Validation: Missing required columns throws error
test_that("errors on missing required columns", {
  bad_data <- data.frame(rep_id = "REP001", rep_name = "Rep A")
  expect_error(generate_suggestions(bad_data), "Missing required columns")
})

# Boundary: Score exactly at threshold
test_that("boundary scores correctly trigger or skip rules", {
  # Score exactly 40 -> should NOT trigger comprehensive_coaching (< 40 required)
  data_at_40 <- data.frame(
    rep_id = "REP009", rep_name = "Rep I",
    score = 40, activity_score = 40, conversion_score = 40, revenue_score = 40
  )
  result <- generate_suggestions(data_at_40)
  expect_true(nrow(result) == 0 ||
                result$suggestion_category != "comprehensive_coaching")

  # Score exactly 85 -> should NOT trigger mentorship (> 85 required)
  data_at_85 <- data.frame(
    rep_id = "REP010", rep_name = "Rep J",
    score = 85, activity_score = 85, conversion_score = 85, revenue_score = 85
  )
  result <- generate_suggestions(data_at_85)
  expect_true(nrow(result) == 0 ||
                result$suggestion_category != "mentorship")
})
