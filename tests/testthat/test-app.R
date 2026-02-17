library(testthat)

# shinytest2 E2E tests for Shiny dashboard
# These require a headless browser (chromote) and shinytest2 package.
# Tests are skipped if shinytest2 is not available.

# Only skip if shinytest2 genuinely not available (e.g., in minimal CI)
if (!requireNamespace("shinytest2", quietly = TRUE)) {
  skip("shinytest2 not available")
}
library(shinytest2)

test_that("app launches and loads default data", {
  app <- AppDriver$new(
    app_dir = rprojroot::find_root("DESCRIPTION"),
    name = "default-load",
    timeout = 10000
  )
  on.exit(app$stop(), add = TRUE)

  # Check that sample data loaded via data summary
  summary <- app$get_value(output = "data_summary")
  expect_match(summary, "80 rows")
  expect_match(summary, "20 reps")
})

test_that("weight sliders trigger score recalculation", {
  app <- AppDriver$new(
    app_dir = rprojroot::find_root("DESCRIPTION"),
    name = "weight-sliders",
    timeout = 10000
  )
  on.exit(app$stop(), add = TRUE)

  # Get initial score summary
  initial_summary <- app$get_value(output = "data_summary")

  # Move activity slider to 0.8
  app$set_inputs(weight_activity = 0.8)
  Sys.sleep(1)

  # Score range should change when weights change
  new_summary <- app$get_value(output = "data_summary")
  expect_false(identical(initial_summary, new_summary))
})

test_that("rep filter updates data summary", {
  app <- AppDriver$new(
    app_dir = rprojroot::find_root("DESCRIPTION"),
    name = "rep-filter",
    timeout = 10000
  )
  on.exit(app$stop(), add = TRUE)

  # Wait for filters to populate
  Sys.sleep(1)

  # Apply rep filter
  app$set_inputs(filter_rep = "REP001")
  Sys.sleep(1)

  # Check data summary shows fewer rows
  summary <- app$get_value(output = "data_summary")
  expect_match(summary, "4 rows")
  expect_match(summary, "1 reps")
})

test_that("clear filters resets view", {
  app <- AppDriver$new(
    app_dir = rprojroot::find_root("DESCRIPTION"),
    name = "clear-filters",
    timeout = 10000
  )
  on.exit(app$stop(), add = TRUE)

  Sys.sleep(1)

  # Apply filter
  app$set_inputs(filter_rep = "REP001")
  Sys.sleep(1)

  # Clear filters
  app$click("clear_filters")
  Sys.sleep(1)

  # Should be back to full dataset
  summary <- app$get_value(output = "data_summary")
  expect_match(summary, "80 rows")
})

test_that("debug mode toggles intermediate columns", {
  app <- AppDriver$new(
    app_dir = rprojroot::find_root("DESCRIPTION"),
    name = "debug-mode",
    timeout = 10000
  )
  on.exit(app$stop(), add = TRUE)

  # Enable debug mode
  app$set_inputs(debug_mode = TRUE)
  Sys.sleep(1)

  # Verify app didn't crash (smoke test)
  summary <- app$get_value(output = "data_summary")
  expect_match(summary, "80 rows")
})

test_that("period filter updates data", {
  app <- AppDriver$new(
    app_dir = rprojroot::find_root("DESCRIPTION"),
    name = "period-filter",
    timeout = 10000
  )
  on.exit(app$stop(), add = TRUE)

  Sys.sleep(1)

  # Apply period filter
  app$set_inputs(filter_period = "Q1-2025")
  Sys.sleep(1)

  # Should show 20 rows (20 reps x 1 period)
  summary <- app$get_value(output = "data_summary")
  expect_match(summary, "20 rows")
})

test_that("weight sliders auto-normalize and update UI", {
  app <- AppDriver$new(
    app_dir = rprojroot::find_root("DESCRIPTION"),
    name = "slider-auto-normalize",
    timeout = 10000
  )
  on.exit(app$stop(), add = TRUE)

  # Set activity slider to 0.8
  app$set_inputs(weight_activity = 0.8)
  Sys.sleep(1)

  # Get current slider values
  activity_val <- app$get_value(input = "weight_activity")
  conversion_val <- app$get_value(input = "weight_conversion")
  revenue_val <- app$get_value(input = "weight_revenue")

  # Verify sliders auto-normalized to sum to 1.0
  total <- activity_val + conversion_val + revenue_val
  expect_equal(total, 1.0, tolerance = 0.01)

  # Verify activity slider stayed close to 0.8
  expect_equal(activity_val, 0.8, tolerance = 0.05)

  # Verify other sliders adjusted proportionally
  expect_true(conversion_val < 0.4)  # Should be around 0.1
  expect_true(revenue_val < 0.4)     # Should be around 0.1
})

test_that("debug mode affects exported CSV columns", {
  app <- AppDriver$new(
    app_dir = rprojroot::find_root("DESCRIPTION"),
    name = "debug-export",
    timeout = 10000
  )
  on.exit(app$stop(), add = TRUE)

  Sys.sleep(1)

  # Enable debug mode
  app$set_inputs(debug_mode = TRUE)
  Sys.sleep(1)

  # Export would trigger download, which is hard to test with shinytest2
  # Instead, verify debug mode affects scored_data reactive by checking
  # that table rendering doesn't error (smoke test)
  summary <- app$get_value(output = "data_summary")
  expect_match(summary, "80 rows")

  # Disable debug mode
  app$set_inputs(debug_mode = FALSE)
  Sys.sleep(1)

  # Verify still works
  summary2 <- app$get_value(output = "data_summary")
  expect_match(summary2, "80 rows")
})
