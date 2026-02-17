library(testthat)
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "scoring_utils.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "normalization.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "dimension_scoring.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "calculate_scores.R"))

test_that("scoring completes in under 500ms for 1000 rows", {

  # Generate 1000-row dataset (50 reps x 20 periods)
  set.seed(42)
  data <- data.frame(
    rep_id = rep(sprintf("REP%03d", 1:50), each = 20),
    rep_name = rep(sprintf("Rep %d", 1:50), each = 20),
    tenure_months = sample(6:120, 1000, replace = TRUE),
    calls_made = sample(10:200, 1000, replace = TRUE),
    followups_done = sample(5:100, 1000, replace = TRUE),
    meetings_scheduled = sample(1:30, 1000, replace = TRUE),
    deals_closed = sample(0:10, 1000, replace = TRUE),
    revenue_generated = sample(1000:100000, 1000, replace = TRUE),
    quota = sample(50000:200000, 1000, replace = TRUE),
    territory_size = sample(50:500, 1000, replace = TRUE),
    period = rep(sprintf("Q%d-2025", 1:20), 50)
  )

  # Time scoring execution
  start_time <- Sys.time()
  result <- calculate_scores(data)
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  # Log timing for monitoring
  message("Scoring 1000 rows took ", round(elapsed, 3), " seconds")

  # Verify performance requirement
  expect_lt(elapsed, 0.5,
            label = paste0("Scoring took ", round(elapsed, 3),
                          "s, should be < 0.5s"))

  # Verify correctness (no NA/Inf, valid ranges)
  expect_true(nrow(result) == 1000)
  expect_true(all(!is.na(result$score)))
  expect_true(all(!is.infinite(result$score)))
  expect_true(all(result$score >= 0 & result$score <= 100))
})

test_that("scoring handles 80-row sample data quickly", {
  # Baseline performance test with actual sample data
  data_path <- file.path(rprojroot::find_root("DESCRIPTION"), "data", "sample_reps.csv")
  data <- read.csv(data_path, stringsAsFactors = FALSE)

  start_time <- Sys.time()
  result <- calculate_scores(data)
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  message("Scoring 80 rows took ", round(elapsed, 3), " seconds")

  # Should be well under 100ms for small datasets
  expect_lt(elapsed, 0.1,
            label = paste0("Scoring took ", round(elapsed, 3),
                          "s, should be < 0.1s for 80 rows"))
})
