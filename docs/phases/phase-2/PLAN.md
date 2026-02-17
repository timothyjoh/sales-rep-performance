# Implementation Plan: Phase 2

## Overview
Build a fair, bias-free scoring engine that produces 0-100 productivity scores for sales reps. Implements normalization functions (tenure, territory, quota), three dimension scores (activity quality, conversion efficiency, revenue contribution), and a configurable weight system.

## Current State (from Research)
- Phase 1 complete with 100% test coverage
- Sample data: 80 rows (20 reps × 4 quarters) at `data/sample_reps.csv`
- Test infrastructure: testthat 3rd edition, uses `source()` with `rprojroot::find_root()`
- Code patterns: native pipe `|>`, tidyverse style, roxygen2 docs
- Edge cases present: zero activity quarters, quota exceeded by 190%, tenure 1-77 months
- Tenure distribution in data: 30% new (1-12mo), 40% mid (13-36mo), 30% exp (37-120mo)
- Territory size range: 50-500 accounts (10x variance)
- Quota levels: discrete values ($50k, $75k, $100k, $150k)

## Desired End State
After Phase 2, the codebase produces scored output via:
```bash
Rscript scripts/score_data.R
```

This generates `data/scored_reps.csv` with 4 new columns:
- `score` — Overall productivity score (0-100)
- `activity_score` — Activity quality dimension (0-100)
- `conversion_score` — Conversion efficiency dimension (0-100)
- `revenue_score` — Revenue contribution dimension (0-100)

All scoring functions are pure, deterministic, fully tested (100% coverage), and documented with roxygen2.

## What We're NOT Doing
- No Shiny dashboard or UI components (Phase 3)
- No Quarto report generation (Phase 4)
- No improvement suggestions logic (Phase 4)
- No time-series trending or multi-period comparisons
- No visualization functions (charts are Phase 3)
- No data validation/cleaning beyond basic sanity checks
- No external data sources or API integrations
- No command-line argument parsing for custom weights (default weights only)
- No advanced statistical modeling (ML, clustering, etc.)

## Implementation Approach

### Design Decisions (Resolving RESEARCH.md Open Questions)

**1. Normalization Strategy**
- **Tenure**: Continuous scaling using `tenure_months / 60` (5 years = fully experienced). New reps (< 12 months) get 0.2-1.0 scaling, experienced reps (60+ months) get 1.0 (no penalty).
- **Territory**: Activity per account normalization. Divide activity metrics by `territory_size / 100` (100 accounts = baseline). Large territories get credit for higher activity volumes.
- **Quota**: Percentage-based, uncapped. Formula: `(revenue_generated / quota) * 100`. Allow 200%+ for overachievers—no artificial ceiling.

**2. Dimension Scoring Formulas**
- **Activity quality**: Composite of three normalized metrics with equal weighting (33.3% each):
  - `calls_made_normalized = (calls_made / territory_factor) * tenure_factor`
  - `followups_done_normalized = (followups_done / territory_factor) * tenure_factor`
  - `meetings_scheduled_normalized = (meetings_scheduled / territory_factor) * tenure_factor`
  - Score: Scale combined metric to 0-100 using percentile ranking within dataset

- **Conversion efficiency**: Two sub-components weighted 50/50:
  - Meetings-to-deals ratio: `deals_closed / pmax(1, meetings_scheduled)` (avoid division by zero)
  - Revenue per activity unit: `revenue_generated / pmax(1, calls_made + followups_done + meetings_scheduled)`
  - Score: Percentile rank each component, average them, scale to 0-100

- **Revenue contribution**: Two sub-components weighted 50/50:
  - Quota attainment: `(revenue_generated / quota) * 100` (uncapped)
  - Revenue per deal: `revenue_generated / pmax(1, deals_closed)` (avoid division by zero)
  - Score: Percentile rank each component, average them, scale to 0-100

**3. Weight System**
- Input format: Named numeric vector: `c(activity = 0.3, conversion = 0.4, revenue = 0.3)`
- Validation: Weights must sum to 1.0 (tolerance = 0.001 for floating point)
- Names must exactly match: "activity", "conversion", "revenue"
- Default weights: Equal balance `c(activity = 0.333, conversion = 0.334, revenue = 0.333)`
- Error messages: Clear, specific (e.g., "Weights sum to 0.99, must sum to 1.0 (tolerance ±0.001)")

**4. Score Scaling to 0-100**
- Use **percentile ranking** within the dataset for each dimension
- Rationale: Anchors scores relative to peer performance, not absolute values
- Implementation: `rank(x, ties.method = "average") / length(x) * 100`
- Edge case: All-zero rows get rank 1 (tied lowest), which maps to lowest percentile

**5. Edge Case Handling**
- **Zero activity**: All activity metrics = 0 → activity_score = 0 (percentile rank handles this)
- **Zero meetings**: Use `pmax(1, meetings_scheduled)` in ratio calculations → conversion ratio = 0
- **Zero deals**: Use `pmax(1, deals_closed)` in revenue-per-deal → assigns minimum score
- **Missing columns**: Error message lists all missing columns: "Required columns missing: tenure_months, quota"
- **Negative values**: Validate at function entry, error: "Column {col} cannot contain negative values"

**6. Function Architecture**
- **Three separate normalization functions**: `normalize_tenure()`, `normalize_territory()`, `normalize_quota()`
- **Three dimension scoring functions**: `score_activity()`, `score_conversion()`, `score_revenue()`
- **One weight validation function**: `validate_weights()`
- **One final scoring pipeline**: `calculate_scores()` — orchestrates all steps
- **Granular functions enable**: Easier testing, clearer documentation, reusability

**7. Grouped Data Handling**
- Scoring functions accept **ungrouped tibbles** and work row-by-row
- Percentile ranking uses **entire dataset** (all reps, all periods) for fair comparison
- Rationale: Scores should be comparable across time periods, so normalization pool is global

**8. Function Return Structure**
- Normalization functions: Return input tibble + new normalized columns
- Dimension scoring functions: Return input tibble + dimension score column
- Final pipeline: Return input tibble + 4 score columns (score, activity_score, conversion_score, revenue_score)
- Rationale: Preserve all input columns for traceability and debugging

### Architecture Diagram
```
Input: sample_reps.csv (11 columns)
  ↓
normalize_tenure() → adds tenure_factor column
  ↓
normalize_territory() → adds territory_factor column
  ↓
normalize_quota() → adds quota_attainment column
  ↓
score_activity() → adds activity_score column (0-100)
  ↓
score_conversion() → adds conversion_score column (0-100)
  ↓
score_revenue() → adds revenue_score column (0-100)
  ↓
validate_weights() → checks weight configuration
  ↓
calculate_scores() → adds final score column (weighted sum)
  ↓
Output: scored_reps.csv (15 columns = 11 original + 4 scores)
```

---

## Task 1: Setup Scoring Infrastructure

### Overview
Create file structure and helper functions for scoring engine. Establish validation utilities that will be reused across normalization and scoring functions.

### Changes Required

**File**: `R/scoring_utils.R` (new file)
```r
#' Validate Required Columns in DataFrame
#'
#' Checks that all required columns exist in the input data frame.
#' Throws an error listing missing columns if any are not found.
#'
#' @param data A data frame or tibble to validate
#' @param required_cols Character vector of required column names
#'
#' @return NULL (invisibly). Function only used for side effect (error if validation fails).
#'
#' @examples
#' df <- tibble::tibble(rep_id = "REP001", score = 85)
#' validate_columns(df, c("rep_id", "score"))  # Passes
#' \dontrun{
#' validate_columns(df, c("rep_id", "missing_col"))  # Errors
#' }
validate_columns <- function(data, required_cols) {
  missing <- setdiff(required_cols, names(data))
  if (length(missing) > 0) {
    stop("Required columns missing: ", paste(missing, collapse = ", "))
  }
  invisible(NULL)
}

#' Validate No Negative Values in Column
#'
#' Checks that a numeric column contains no negative values.
#' Throws an error if negative values are found.
#'
#' @param data A data frame or tibble
#' @param col_name String name of column to validate
#'
#' @return NULL (invisibly). Function only used for side effect (error if validation fails).
#'
#' @examples
#' df <- tibble::tibble(tenure_months = c(1, 12, 36))
#' validate_non_negative(df, "tenure_months")  # Passes
validate_non_negative <- function(data, col_name) {
  if (any(data[[col_name]] < 0, na.rm = TRUE)) {
    stop("Column '", col_name, "' cannot contain negative values")
  }
  invisible(NULL)
}

#' Calculate Percentile Rank
#'
#' Converts a numeric vector to percentile ranks (0-100 scale).
#' Handles ties using average method. All-zero vectors return zeros.
#'
#' @param x Numeric vector to rank
#'
#' @return Numeric vector of percentile ranks (0-100)
#'
#' @examples
#' percentile_rank(c(10, 20, 30))  # Returns c(0, 50, 100)
#' percentile_rank(c(5, 5, 5))     # Returns c(50, 50, 50)
percentile_rank <- function(x) {
  if (all(x == 0)) {
    return(rep(0, length(x)))
  }
  (rank(x, ties.method = "average") - 1) / (length(x) - 1) * 100
}
```

**File**: `tests/testthat/test-scoring_utils.R` (new file)
```r
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

  # All same values
  expect_equal(percentile_rank(c(5, 5, 5)), c(50, 50, 50))

  # All zeros edge case
  expect_equal(percentile_rank(c(0, 0, 0)), c(0, 0, 0))

  # Single value
  expect_equal(percentile_rank(100), 0)
})
```

### Success Criteria
- [ ] `R/scoring_utils.R` created with 3 helper functions
- [ ] All functions documented with roxygen2 (@param, @return, @examples)
- [ ] `tests/testthat/test-scoring_utils.R` created with 3 test blocks
- [ ] Tests pass: `Rscript -e "testthat::test_dir('tests/testthat')"`
- [ ] Coverage 100% for scoring_utils.R

---

## Task 2: Implement Normalization Functions

### Overview
Create three normalization functions that adjust raw metrics for fair comparison: tenure adjustment, territory size adjustment, and quota attainment calculation.

### Changes Required

**File**: `R/normalization.R` (new file)
```r
#' Normalize Metrics by Tenure
#'
#' Calculates a tenure adjustment factor where new reps get scaled expectations.
#' Uses continuous scaling: tenure_factor = min(1.0, tenure_months / 60).
#' Experienced reps (60+ months) get factor of 1.0 (no adjustment).
#'
#' @param data A data frame or tibble with tenure_months column
#'
#' @return Input data with new column 'tenure_factor' (range: 0-1)
#'
#' @examples
#' df <- tibble::tibble(rep_id = "REP001", tenure_months = 12)
#' normalize_tenure(df)  # Adds tenure_factor = 0.2
normalize_tenure <- function(data) {
  validate_columns(data, "tenure_months")
  validate_non_negative(data, "tenure_months")

  data |>
    dplyr::mutate(
      tenure_factor = pmin(1.0, tenure_months / 60)
    )
}

#' Normalize Metrics by Territory Size
#'
#' Calculates a territory adjustment factor for activity metrics.
#' Baseline is 100 accounts. Factor = territory_size / 100.
#' Larger territories get higher factor (credit for managing more accounts).
#'
#' @param data A data frame or tibble with territory_size column
#'
#' @return Input data with new column 'territory_factor' (range: 0.5-5.0 for 50-500 territories)
#'
#' @examples
#' df <- tibble::tibble(rep_id = "REP001", territory_size = 200)
#' normalize_territory(df)  # Adds territory_factor = 2.0
normalize_territory <- function(data) {
  validate_columns(data, "territory_size")
  validate_non_negative(data, "territory_size")

  data |>
    dplyr::mutate(
      territory_factor = territory_size / 100
    )
}

#' Normalize Revenue by Quota
#'
#' Calculates quota attainment percentage (uncapped).
#' Allows overachievers to score > 100%.
#'
#' @param data A data frame or tibble with revenue_generated and quota columns
#'
#' @return Input data with new column 'quota_attainment' (percentage, uncapped)
#'
#' @examples
#' df <- tibble::tibble(revenue_generated = 150000, quota = 100000)
#' normalize_quota(df)  # Adds quota_attainment = 150
normalize_quota <- function(data) {
  validate_columns(data, c("revenue_generated", "quota"))
  validate_non_negative(data, "revenue_generated")
  validate_non_negative(data, "quota")

  data |>
    dplyr::mutate(
      quota_attainment = (revenue_generated / quota) * 100
    )
}
```

**File**: `tests/testthat/test-normalization.R` (new file)
```r
library(testthat)
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "scoring_utils.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "normalization.R"))

test_that("normalize_tenure calculates tenure factor correctly", {
  df <- tibble::tibble(
    rep_id = c("REP001", "REP002", "REP003", "REP004"),
    tenure_months = c(6, 30, 60, 120)
  )

  result <- normalize_tenure(df)

  # Check column added
  expect_true("tenure_factor" %in% names(result))

  # Validate calculations
  expect_equal(result$tenure_factor[1], 0.1)  # 6/60 = 0.1
  expect_equal(result$tenure_factor[2], 0.5)  # 30/60 = 0.5
  expect_equal(result$tenure_factor[3], 1.0)  # 60/60 = 1.0 (capped)
  expect_equal(result$tenure_factor[4], 1.0)  # 120/60 = 2.0 → capped at 1.0
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
  expect_equal(result$territory_factor[1], 0.5)   # 50/100 = 0.5
  expect_equal(result$territory_factor[2], 1.0)   # 100/100 = 1.0
  expect_equal(result$territory_factor[3], 4.0)   # 400/100 = 4.0
})

test_that("normalize_territory errors on negative territory_size", {
  df <- tibble::tibble(territory_size = c(100, -50))
  expect_error(
    normalize_territory(df),
    "Column 'territory_size' cannot contain negative values"
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

test_that("normalize_quota errors on negative values", {
  df1 <- tibble::tibble(revenue_generated = -1000, quota = 100000)
  expect_error(normalize_quota(df1), "cannot contain negative values")

  df2 <- tibble::tibble(revenue_generated = 100000, quota = -50000)
  expect_error(normalize_quota(df2), "cannot contain negative values")
})
```

### Success Criteria
- [ ] `R/normalization.R` created with 3 normalization functions
- [ ] All functions documented with roxygen2
- [ ] `tests/testthat/test-normalization.R` created with 9 test blocks
- [ ] Tests pass including edge cases (zero values, negative values, capped tenure)
- [ ] Coverage 100% for normalization.R

---

## Task 3: Implement Dimension Scoring Functions

### Overview
Create three dimension scoring functions: activity quality, conversion efficiency, and revenue contribution. Each function calculates a 0-100 score using percentile ranking.

### Changes Required

**File**: `R/dimension_scoring.R` (new file)
```r
#' Score Activity Quality Dimension
#'
#' Calculates activity quality score (0-100) based on normalized activity metrics.
#' Combines calls, followups, and meetings with equal weighting.
#' Uses percentile ranking across all rows in dataset.
#'
#' @param data A data frame with calls_made, followups_done, meetings_scheduled,
#'   tenure_factor, and territory_factor columns
#'
#' @return Input data with new column 'activity_score' (0-100)
#'
#' @examples
#' df <- tibble::tibble(
#'   calls_made = 100, followups_done = 50, meetings_scheduled = 20,
#'   tenure_factor = 0.5, territory_factor = 2.0
#' )
#' score_activity(df)
score_activity <- function(data) {
  required <- c("calls_made", "followups_done", "meetings_scheduled",
                "tenure_factor", "territory_factor")
  validate_columns(data, required)

  data |>
    dplyr::mutate(
      # Normalize each activity metric
      calls_normalized = (calls_made / territory_factor) * tenure_factor,
      followups_normalized = (followups_done / territory_factor) * tenure_factor,
      meetings_normalized = (meetings_scheduled / territory_factor) * tenure_factor,
      # Composite activity metric (equal weighting)
      activity_composite = (calls_normalized + followups_normalized + meetings_normalized) / 3,
      # Convert to percentile rank
      activity_score = percentile_rank(activity_composite)
    ) |>
    dplyr::select(-calls_normalized, -followups_normalized, -meetings_normalized, -activity_composite)
}

#' Score Conversion Efficiency Dimension
#'
#' Calculates conversion efficiency score (0-100) based on:
#' - Meetings-to-deals ratio (50% weight)
#' - Revenue per activity unit (50% weight)
#' Uses percentile ranking for each component.
#'
#' @param data A data frame with deals_closed, meetings_scheduled, revenue_generated,
#'   calls_made, followups_done columns
#'
#' @return Input data with new column 'conversion_score' (0-100)
#'
#' @examples
#' df <- tibble::tibble(
#'   deals_closed = 10, meetings_scheduled = 20,
#'   revenue_generated = 100000, calls_made = 100, followups_done = 50
#' )
#' score_conversion(df)
score_conversion <- function(data) {
  required <- c("deals_closed", "meetings_scheduled", "revenue_generated",
                "calls_made", "followups_done")
  validate_columns(data, required)

  data |>
    dplyr::mutate(
      # Component 1: Meetings-to-deals ratio
      meetings_to_deals = deals_closed / pmax(1, meetings_scheduled),
      meetings_to_deals_score = percentile_rank(meetings_to_deals),
      # Component 2: Revenue per activity
      total_activities = calls_made + followups_done + meetings_scheduled,
      revenue_per_activity = revenue_generated / pmax(1, total_activities),
      revenue_per_activity_score = percentile_rank(revenue_per_activity),
      # Average the two components (50/50 weighting)
      conversion_score = (meetings_to_deals_score + revenue_per_activity_score) / 2
    ) |>
    dplyr::select(-meetings_to_deals, -meetings_to_deals_score,
                  -total_activities, -revenue_per_activity, -revenue_per_activity_score)
}

#' Score Revenue Contribution Dimension
#'
#' Calculates revenue contribution score (0-100) based on:
#' - Quota attainment percentage (50% weight)
#' - Revenue per deal closed (50% weight)
#' Uses percentile ranking for each component.
#'
#' @param data A data frame with quota_attainment, revenue_generated, deals_closed columns
#'
#' @return Input data with new column 'revenue_score' (0-100)
#'
#' @examples
#' df <- tibble::tibble(
#'   quota_attainment = 150, revenue_generated = 150000, deals_closed = 10
#' )
#' score_revenue(df)
score_revenue <- function(data) {
  required <- c("quota_attainment", "revenue_generated", "deals_closed")
  validate_columns(data, required)

  data |>
    dplyr::mutate(
      # Component 1: Quota attainment (already calculated in normalization)
      quota_attainment_score = percentile_rank(quota_attainment),
      # Component 2: Revenue per deal
      revenue_per_deal = revenue_generated / pmax(1, deals_closed),
      revenue_per_deal_score = percentile_rank(revenue_per_deal),
      # Average the two components (50/50 weighting)
      revenue_score = (quota_attainment_score + revenue_per_deal_score) / 2
    ) |>
    dplyr::select(-quota_attainment_score, -revenue_per_deal, -revenue_per_deal_score)
}
```

**File**: `tests/testthat/test-dimension_scoring.R` (new file)
```r
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
  expect_equal(result$activity_score, c(0, 50, 100))  # Perfect ranking
  expect_true(all(result$activity_score >= 0 & result$activity_score <= 100))
})

test_that("score_activity handles tenure and territory adjustments", {
  df <- tibble::tibble(
    calls_made = c(100, 100),
    followups_done = c(50, 50),
    meetings_scheduled = c(20, 20),
    tenure_factor = c(0.5, 1.0),  # Rep 1 is new, Rep 2 is experienced
    territory_factor = c(1.0, 1.0)
  )

  result <- score_activity(df)

  # New rep should have lower activity score despite same raw metrics
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

  expect_equal(result$activity_score[1], 0)   # Zero activity → lowest rank
  expect_equal(result$activity_score[2], 100) # Non-zero → highest rank
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

  # Should not error, should produce valid scores
  expect_false(any(is.na(result$conversion_score)))
  expect_false(any(is.infinite(result$conversion_score)))
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

  # Should not error or produce NA/Inf
  expect_false(any(is.na(result$revenue_score)))
  expect_false(any(is.infinite(result$revenue_score)))
})

test_that("dimension scoring errors on missing columns", {
  df <- tibble::tibble(rep_id = "REP001")

  expect_error(score_activity(df), "Required columns missing")
  expect_error(score_conversion(df), "Required columns missing")
  expect_error(score_revenue(df), "Required columns missing")
})
```

### Success Criteria
- [ ] `R/dimension_scoring.R` created with 3 dimension scoring functions
- [ ] All functions documented with roxygen2
- [ ] `tests/testthat/test-dimension_scoring.R` created with 9 test blocks
- [ ] Tests pass including edge cases (zero activity, zero meetings, zero deals)
- [ ] Coverage 100% for dimension_scoring.R
- [ ] No NA or Inf values produced by edge cases

---

## Task 4: Implement Weight System and Final Score Calculation

### Overview
Create weight validation function and final scoring pipeline that combines dimension scores using configurable weights.

### Changes Required

**File**: `R/calculate_scores.R` (new file)
```r
#' Validate Weight Configuration
#'
#' Checks that weights are a named numeric vector with correct names,
#' all positive values, and sum to 1.0 (within tolerance).
#'
#' @param weights Named numeric vector with names: activity, conversion, revenue
#'
#' @return NULL (invisibly). Function only used for validation side effect.
#'
#' @examples
#' validate_weights(c(activity = 0.3, conversion = 0.4, revenue = 0.3))  # Passes
#' \dontrun{
#' validate_weights(c(activity = 0.3, conversion = 0.4, revenue = 0.29))  # Errors
#' }
validate_weights <- function(weights) {
  # Check that weights is a named vector
  if (!is.numeric(weights) || is.null(names(weights))) {
    stop("Weights must be a named numeric vector")
  }

  # Check that names are exactly: activity, conversion, revenue
  expected_names <- c("activity", "conversion", "revenue")
  if (!all(expected_names %in% names(weights)) || length(weights) != 3) {
    stop("Weights must have exactly three names: activity, conversion, revenue")
  }

  # Check that all weights are non-negative
  if (any(weights < 0)) {
    stop("All weights must be non-negative")
  }

  # Check that weights sum to 1.0 (tolerance = 0.001)
  weight_sum <- sum(weights)
  if (abs(weight_sum - 1.0) > 0.001) {
    stop("Weights sum to ", round(weight_sum, 3),
         ", must sum to 1.0 (tolerance ±0.001)")
  }

  invisible(NULL)
}

#' Calculate Final Productivity Scores
#'
#' Orchestrates full scoring pipeline: normalization → dimension scoring → weighted sum.
#' Returns input data with four new score columns.
#'
#' @param data A data frame with all required columns from sample_reps.csv
#' @param weights Named numeric vector with dimension weights (default: equal weighting)
#'
#' @return Input data with new columns: activity_score, conversion_score, revenue_score, score
#'
#' @examples
#' df <- read.csv("data/sample_reps.csv")
#' scored <- calculate_scores(df)  # Uses default weights
#' scored_custom <- calculate_scores(df, c(activity = 0.5, conversion = 0.3, revenue = 0.2))
calculate_scores <- function(data,
                               weights = c(activity = 0.333, conversion = 0.334, revenue = 0.333)) {
  # Validate inputs
  required <- c("rep_id", "tenure_months", "territory_size", "quota",
                "calls_made", "followups_done", "meetings_scheduled",
                "deals_closed", "revenue_generated")
  validate_columns(data, required)
  validate_weights(weights)

  # Normalization pipeline
  data_normalized <- data |>
    normalize_tenure() |>
    normalize_territory() |>
    normalize_quota()

  # Dimension scoring pipeline
  data_scored <- data_normalized |>
    score_activity() |>
    score_conversion() |>
    score_revenue()

  # Calculate final weighted score
  data_scored |>
    dplyr::mutate(
      score = activity_score * weights["activity"] +
              conversion_score * weights["conversion"] +
              revenue_score * weights["revenue"]
    )
}
```

**File**: `tests/testthat/test-calculate_scores.R` (new file)
```r
library(testthat)
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "scoring_utils.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "normalization.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "dimension_scoring.R"))
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "calculate_scores.R"))

test_that("validate_weights accepts valid weights", {
  expect_silent(validate_weights(c(activity = 0.333, conversion = 0.334, revenue = 0.333)))
  expect_silent(validate_weights(c(activity = 0.5, conversion = 0.3, revenue = 0.2)))
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
})

test_that("calculate_scores produces all required columns", {
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

  # Check all score columns present
  expect_true("activity_score" %in% names(result))
  expect_true("conversion_score" %in% names(result))
  expect_true("revenue_score" %in% names(result))
  expect_true("score" %in% names(result))

  # Check all scores in 0-100 range
  expect_true(all(result$activity_score >= 0 & result$activity_score <= 100))
  expect_true(all(result$conversion_score >= 0 & result$conversion_score <= 100))
  expect_true(all(result$revenue_score >= 0 & result$revenue_score <= 100))
  expect_true(all(result$score >= 0 & result$score <= 100))
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
  result_activity_heavy <- calculate_scores(df, c(activity = 0.8, conversion = 0.1, revenue = 0.1))
  expect_true(result_activity_heavy$score[2] > result_activity_heavy$score[1])

  # Weight heavily toward revenue
  result_revenue_heavy <- calculate_scores(df, c(activity = 0.1, conversion = 0.1, revenue = 0.8))
  expect_true(result_revenue_heavy$score[1] > result_revenue_heavy$score[2])
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

  # Should not produce NA or Inf
  expect_false(any(is.na(result$score)))
  expect_false(any(is.infinite(result$score)))
})

test_that("calculate_scores errors on missing columns", {
  df <- tibble::tibble(rep_id = "REP001")
  expect_error(calculate_scores(df), "Required columns missing")
})
```

### Success Criteria
- [ ] `R/calculate_scores.R` created with 2 functions (validate_weights, calculate_scores)
- [ ] All functions documented with roxygen2
- [ ] `tests/testthat/test-calculate_scores.R` created with 7 test blocks
- [ ] Tests pass including weight validation and custom weight scenarios
- [ ] Coverage 100% for calculate_scores.R
- [ ] Integration test validates full pipeline works end-to-end

---

## Task 5: Create Vertical Slice Validation Script

### Overview
Build executable script that loads sample data, calculates scores with default weights, and outputs scored CSV file. This demonstrates Phase 2 deliverable without UI.

### Changes Required

**File**: `scripts/score_data.R` (new file)
```r
#!/usr/bin/env Rscript

# Load required functions
source(file.path(dirname(dirname(rstudioapi::getSourceEditorContext()$path)), "R", "scoring_utils.R"))
source(file.path(dirname(dirname(rstudioapi::getSourceEditorContext()$path)), "R", "normalization.R"))
source(file.path(dirname(dirname(rstudioapi::getSourceEditorContext()$path)), "R", "dimension_scoring.R"))
source(file.path(dirname(dirname(rstudioapi::getSourceEditorContext()$path)), "R", "calculate_scores.R"))

# Alternative sourcing for command-line execution (more robust)
if (!exists("calculate_scores")) {
  script_dir <- getwd()
  source(file.path(script_dir, "R", "scoring_utils.R"))
  source(file.path(script_dir, "R", "normalization.R"))
  source(file.path(script_dir, "R", "dimension_scoring.R"))
  source(file.path(script_dir, "R", "calculate_scores.R"))
}

cat("Loading sample data from data/sample_reps.csv...\n")

# Load sample data
data <- read.csv("data/sample_reps.csv", stringsAsFactors = FALSE)

cat("Calculating productivity scores...\n")

# Calculate scores with default weights
scored_data <- calculate_scores(data)

cat("Writing scored data to data/scored_reps.csv...\n")

# Write output
write.csv(scored_data, "data/scored_reps.csv", row.names = FALSE)

cat("\nScoring complete!\n")
cat("Output: data/scored_reps.csv (", nrow(scored_data), " rows)\n\n")
cat("Score summary:\n")
print(summary(scored_data[, c("activity_score", "conversion_score", "revenue_score", "score")]))
```

**Simpler version without rstudioapi dependency**:
```r
#!/usr/bin/env Rscript

# Source scoring functions
source("R/scoring_utils.R")
source("R/normalization.R")
source("R/dimension_scoring.R")
source("R/calculate_scores.R")

cat("Loading sample data from data/sample_reps.csv...\n")

# Load sample data
data <- read.csv("data/sample_reps.csv", stringsAsFactors = FALSE)

cat("Calculating productivity scores...\n")

# Calculate scores with default weights
scored_data <- calculate_scores(data)

cat("Writing scored data to data/scored_reps.csv...\n")

# Write output
write.csv(scored_data, "data/scored_reps.csv", row.names = FALSE)

cat("\nScoring complete!\n")
cat("Output: data/scored_reps.csv (", nrow(scored_data), " rows)\n\n")
cat("Score summary:\n")
print(summary(scored_data[, c("activity_score", "conversion_score", "revenue_score", "score")]))
```

**File**: `tests/testthat/test-integration.R` (new file)
```r
library(testthat)

test_that("end-to-end scoring pipeline works with sample data", {
  # Source all functions
  source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "scoring_utils.R"))
  source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "normalization.R"))
  source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "dimension_scoring.R"))
  source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "calculate_scores.R"))

  # Load sample data
  data_path <- file.path(rprojroot::find_root("DESCRIPTION"), "data", "sample_reps.csv")
  data <- read.csv(data_path, stringsAsFactors = FALSE)

  # Run full scoring pipeline
  result <- calculate_scores(data)

  # Validate output structure
  expect_equal(nrow(result), 80)  # Same as input
  expect_true(all(c("score", "activity_score", "conversion_score", "revenue_score") %in% names(result)))

  # Validate score ranges
  expect_true(all(result$score >= 0 & result$score <= 100))
  expect_true(all(result$activity_score >= 0 & result$activity_score <= 100))
  expect_true(all(result$conversion_score >= 0 & result$conversion_score <= 100))
  expect_true(all(result$revenue_score >= 0 & result$revenue_score <= 100))

  # Validate scores vary (not all identical)
  expect_true(length(unique(result$score)) > 10)

  # Validate no NA or Inf values
  expect_false(any(is.na(result$score)))
  expect_false(any(is.infinite(result$score)))
})

test_that("scoring pipeline preserves all input columns", {
  source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "scoring_utils.R"))
  source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "normalization.R"))
  source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "dimension_scoring.R"))
  source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "calculate_scores.R"))

  data_path <- file.path(rprojroot::find_root("DESCRIPTION"), "data", "sample_reps.csv")
  data <- read.csv(data_path, stringsAsFactors = FALSE)

  original_cols <- names(data)
  result <- calculate_scores(data)

  # All original columns should be present
  expect_true(all(original_cols %in% names(result)))
})
```

### Success Criteria
- [ ] `scripts/score_data.R` created as executable script
- [ ] Script runs successfully: `Rscript scripts/score_data.R`
- [ ] Output file `data/scored_reps.csv` created with 80 rows
- [ ] Output contains 4 new columns: score, activity_score, conversion_score, revenue_score
- [ ] All scores are numeric and within 0-100 range
- [ ] Scores vary across reps (not all identical)
- [ ] Script prints summary statistics to console
- [ ] Integration test validates full pipeline with sample data
- [ ] No errors or warnings during execution

---

## Task 6: Update Documentation

### Overview
Update project documentation to reflect Phase 2 completion: add scoring commands, explain methodology, update data model, and mark phase as complete.

### Changes Required

**File**: `CLAUDE.md`
Add after line 14 (Quick Command Reference section):
```markdown
### Score Sample Data
```bash
Rscript scripts/score_data.R
```

### Scoring Methodology
The scoring engine calculates fair, bias-free productivity scores (0-100) using three normalized dimensions:
- **Activity Quality (33.3%)**: Calls, followups, and meetings, adjusted for tenure and territory size
- **Conversion Efficiency (33.4%)**: Meetings-to-deals ratio and revenue per activity unit
- **Revenue Contribution (33.3%)**: Quota attainment and revenue per deal closed

Each dimension is percentile-ranked across all reps and periods, then combined using configurable weights. Default weights balance all three dimensions equally.
```

**File**: `README.md`
Update Phase Status section (around line 50):
```markdown
## Phase Status
- **Phase 1**: ✅ COMPLETE — Data model + sample data
- **Phase 2**: ✅ COMPLETE — Scoring engine with normalization
- **Phase 3**: 🔄 NOT STARTED — Shiny dashboard
- **Phase 4**: 🔄 NOT STARTED — Quarto executive reports
```

Add new Scoring section after Data Model section (around line 90):
```markdown
## Scoring

### Running the Scoring Engine
Generate productivity scores for sample data:
```bash
Rscript scripts/score_data.R
```

This creates `data/scored_reps.csv` with four new score columns (0-100 scale):
- `score` — Overall productivity score
- `activity_score` — Activity quality dimension
- `conversion_score` — Conversion efficiency dimension
- `revenue_score` — Revenue contribution dimension

### Scoring Methodology
The engine implements fair, bias-free scoring through three steps:

1. **Normalization**: Adjusts raw metrics for fairness
   - Tenure adjustment: New reps (< 12 months) get scaled expectations
   - Territory normalization: Adjusts for territory size (50-500 accounts)
   - Quota normalization: Converts revenue to quota attainment percentage

2. **Dimension Scoring**: Calculates three performance dimensions (0-100)
   - Activity quality: Composite of calls, followups, meetings (adjusted for tenure/territory)
   - Conversion efficiency: Meetings-to-deals ratio + revenue per activity
   - Revenue contribution: Quota attainment + revenue per deal

3. **Weighted Combination**: Combines dimensions with configurable weights (default: equal)

All scores use percentile ranking across the entire dataset, ensuring fair comparison across time periods and experience levels.
```

**File**: `AGENTS.md`
Add Scoring section after Data Model section (around line 150):
```markdown
## Scoring Methodology

### Overview
The scoring engine produces fair, bias-free productivity scores (0-100) by normalizing raw metrics and combining three performance dimensions with configurable weights.

### Normalization
- **Tenure adjustment**: `tenure_factor = min(1.0, tenure_months / 60)` — new reps get scaled expectations, experienced reps (60+ months) have no adjustment
- **Territory adjustment**: `territory_factor = territory_size / 100` — adjusts for territory size (100 accounts = baseline)
- **Quota adjustment**: `quota_attainment = (revenue_generated / quota) * 100` — converts revenue to percentage, uncapped for overachievers

### Dimension Scoring (0-100 scale)
1. **Activity Quality** (33.3% weight): Composite of normalized calls, followups, and meetings. Uses percentile ranking across all reps/periods.
2. **Conversion Efficiency** (33.4% weight): Average of meetings-to-deals ratio and revenue-per-activity, both percentile-ranked.
3. **Revenue Contribution** (33.3% weight): Average of quota attainment and revenue-per-deal, both percentile-ranked.

### Scored Data Model
After scoring, data includes 4 new columns:

| Column           | Type    | Range | Description                          |
|------------------|---------|-------|--------------------------------------|
| activity_score   | numeric | 0-100 | Activity quality dimension score     |
| conversion_score | numeric | 0-100 | Conversion efficiency dimension score|
| revenue_score    | numeric | 0-100 | Revenue contribution dimension score |
| score            | numeric | 0-100 | Overall weighted productivity score  |

### Expected Score Ranges
- **0-25**: Low performer (bottom quartile)
- **26-50**: Below average (second quartile)
- **51-75**: Above average (third quartile)
- **76-100**: High performer (top quartile)

Scores are percentile-based, so distribution is roughly uniform across the 0-100 range.
```

Update Common Commands Cheatsheet section (around line 180):
```markdown
### Common Commands Cheatsheet
```bash
# Generate sample data
Rscript scripts/generate_data.R

# Calculate productivity scores
Rscript scripts/score_data.R

# Run all tests
Rscript -e "testthat::test_dir('tests/testthat')"

# Generate coverage report
Rscript scripts/coverage_report.R
```
```

**File**: `STATUS.md`
Update Phase 2 status:
```markdown
## Phase 2: Scoring Engine ✅ COMPLETE
- Normalization functions (tenure, territory, quota)
- Dimension scoring (activity, conversion, revenue)
- Weight validation and final score calculation
- Vertical slice script: `scripts/score_data.R`
- Comprehensive tests (100% coverage)
- Documentation updated
```

### Success Criteria
- [ ] `CLAUDE.md` updated with scoring commands and methodology
- [ ] `README.md` updated with Phase 2 complete status and Scoring section
- [ ] `AGENTS.md` updated with scoring methodology and scored data model
- [ ] `STATUS.md` updated to show Phase 2 complete
- [ ] All documentation accurately reflects implemented functionality
- [ ] No broken internal references or missing sections

---

## Testing Strategy

### Unit Tests
**Coverage Target**: 100% line coverage for all new R files

**Test Files** (6 total):
1. `test-scoring_utils.R` — 3 helper functions (column validation, non-negative validation, percentile ranking)
2. `test-normalization.R` — 3 normalization functions (tenure, territory, quota)
3. `test-dimension_scoring.R` — 3 dimension scoring functions (activity, conversion, revenue)
4. `test-calculate_scores.R` — Weight validation and final score calculation
5. `test-integration.R` — End-to-end pipeline with sample data

**Key Edge Cases**:
- Zero activity (all metrics = 0) → should score 0, not error
- Zero meetings → meetings-to-deals ratio uses `pmax(1, meetings)` to avoid division by zero
- Zero deals → revenue-per-deal uses `pmax(1, deals)` to avoid division by zero
- Negative input values → error with clear message: "Column 'X' cannot contain negative values"
- Missing required columns → error listing all missing columns
- Weights sum to 0.99 or 1.01 → error with message showing actual sum
- Negative weights → error: "All weights must be non-negative"
- Quota exceeded by 10x → handled gracefully (no cap, percentile ranking handles it)
- Tenure > 60 months → capped at tenure_factor = 1.0
- Territory extremes (50 vs 500) → territory_factor scales proportionally

**Mocking Strategy**:
- **NO MOCKING** — all tests use real implementations with seeded randomness where needed
- Rationale: Functions are pure, deterministic, and fast — no need for mocks

### Integration Tests
**`test-integration.R`** validates:
1. Full pipeline works end-to-end with `data/sample_reps.csv`
2. Output has correct structure (80 rows, 15 columns = 11 original + 4 scores)
3. All scores are numeric, in range 0-100, no NA/Inf values
4. Scores vary (not all identical) — validates percentile ranking works
5. All input columns preserved in output

### Manual Validation
**Vertical Slice Script**: `scripts/score_data.R`
- Run: `Rscript scripts/score_data.R`
- Inspect: `data/scored_reps.csv` in Excel/Google Sheets
- Verify: Scores vary, high performers have higher scores, no errors printed

### Performance Validation
SPEC.md:59 requires "score calculation must complete in < 100ms for 1000 rows".

**Validation approach**:
- Sample data has 80 rows, so full pipeline should complete in < 10ms
- Add performance check to integration test:
```r
system.time(calculate_scores(data))  # Should be < 0.1 seconds
```
- If performance is slow, profile with `profvis` package

## Risk Assessment

### Technical Risks

**Risk**: Percentile ranking with small dataset (80 rows) may produce coarse scores
- **Mitigation**: This is expected behavior — Phase 2 works with sample data, Phase 3/4 will use larger real datasets with finer granularity
- **Validation**: Integration test checks that scores vary (> 10 unique values)

**Risk**: Division by zero in ratio calculations (meetings = 0, deals = 0)
- **Mitigation**: Use `pmax(1, denominator)` in all ratio calculations
- **Validation**: Explicit edge case tests for zero meetings and zero deals

**Risk**: Floating point precision issues in weight validation (sum to 0.999999 or 1.000001)
- **Mitigation**: Use tolerance of 0.001 in weight sum check: `abs(sum - 1.0) > 0.001`
- **Validation**: Test with weights that sum to 0.999, 1.0, and 1.001

**Risk**: Test file sourcing breaks if working directory is wrong
- **Mitigation**: All test files use `rprojroot::find_root("DESCRIPTION")` to locate project root
- **Validation**: Run tests from different working directories (project root, tests/, R/)

**Risk**: Coverage report fails on new files
- **Mitigation**: Update `scripts/coverage_report.R` to include new source files
- **Validation**: Run coverage report after each task completion

### Process Risks

**Risk**: Implementing all 5 scoring functions at once may introduce bugs
- **Mitigation**: Incremental approach — complete Task 1-2-3-4-5 in order, validating tests after each
- **Validation**: Each task has explicit "Success Criteria" checklist

**Risk**: Mathematical formulas may not produce sensible scores on real data
- **Mitigation**: Validate with sample data inspection (REP011 high performer should score > REP012 low performer)
- **Validation**: Manual inspection of `data/scored_reps.csv` in vertical slice validation

**Risk**: Documentation updates may lag behind implementation
- **Mitigation**: Task 6 is dedicated to documentation updates with explicit file sections to modify
- **Validation**: Read-through of all docs after Task 6 completion

### Open Questions Resolved

All 15 open questions from RESEARCH.md have been resolved in "Design Decisions" section above. Key decisions:
1. Tenure: Continuous scaling (tenure_months / 60, capped at 1.0)
2. Territory: Activity per account (divide by territory_factor)
3. Quota: Uncapped percentage (allow 200%+ for overachievers)
4. Activity composite: Equal weighting (33.3% each for calls/followups/meetings)
5. Conversion: Two components, 50/50 weighting
6. Revenue: Two components, 50/50 weighting
7. Score scaling: Percentile ranking within dataset
8. Weights: Named vector `c(activity = 0.3, conversion = 0.4, revenue = 0.3)`
9. Default weights: Equal balance (0.333/0.334/0.333)
10. Zero activity: Percentile rank handles it (assigns lowest rank = 0)
11. Missing columns: Error lists all missing columns in comma-separated format
12. Function granularity: Separate functions for each normalization/dimension
13. Grouped data: Functions accept ungrouped data, percentile ranking uses global pool
14. Return structure: Return input tibble + new score columns (preserves all columns)
15. CLI args: Phase 2 uses default weights only (custom weights in Phase 3)

---

## Summary

Phase 2 delivers a complete, testable scoring engine in **6 tasks**:

1. **Setup Infrastructure** — Helper functions for validation and percentile ranking
2. **Normalization Functions** — Tenure, territory, and quota adjustments
3. **Dimension Scoring** — Activity quality, conversion efficiency, revenue contribution
4. **Weight System** — Validation and final weighted score calculation
5. **Vertical Slice Script** — User-visible deliverable (`scored_reps.csv`)
6. **Documentation Updates** — CLAUDE.md, README.md, AGENTS.md, STATUS.md

**Total New Code**: 4 R files (scoring_utils.R, normalization.R, dimension_scoring.R, calculate_scores.R) + 1 script (score_data.R)
**Total Tests**: 5 test files with ~30 test blocks, 100% coverage
**Deliverable**: `data/scored_reps.csv` (80 rows × 15 columns) demonstrating fair productivity scoring

All design decisions are documented, all edge cases are handled, and all acceptance criteria from SPEC.md are met.
