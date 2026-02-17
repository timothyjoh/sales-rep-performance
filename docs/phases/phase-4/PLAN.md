# Implementation Plan: Phase 4

## Overview
Build a static Quarto executive report with polished HTML output showcasing top performers, score distributions, and trend analysis. Implement a rule-based improvement suggestions engine that identifies specific coaching opportunities based on dimension score patterns. Deliver shareable reports for leadership and actionable recommendations for managers.

## Current State (from Research)

### What Already Exists
- **Scoring engine complete** (Phase 2): `calculate_scores()` generates dimension scores (activity, conversion, revenue) and overall scores (0-100 scale)
- **Scored data available**: `data/scored_reps.csv` contains 80 rows (20 reps × 4 quarters) with all necessary columns for reporting
- **Shiny dashboard complete** (Phase 3): Exports scored CSV with custom weights if needed
- **Test infrastructure mature**: 100% coverage maintained across 6 R source files, 190 passing tests, TDD workflow established
- **Documentation patterns established**: roxygen2 comments, command-line script structure, validation helper patterns

### Patterns to Follow
- **Validation helper pattern**: Return `list(valid = TRUE/FALSE, message = "...")` — see `R/shiny_helpers.R:14-33`
- **Pipeline function pattern**: Accept data frame → validate → transform → return enhanced data frame — see `R/calculate_scores.R:60-97`
- **Script structure pattern**: Shebang line, source dependencies, cat() progress messages, summary output — see `scripts/score_data.R`
- **Test-first approach**: Write failing tests before implementing each feature (Phase 3 lesson learned)
- **Documentation during implementation**: Update docs when features are tested and working, not at phase end (Phase 3 lesson learned)

### Key Takeaways from Phase 3 REFLECTIONS.md
- Front-load dependency configuration (add knitr, rmarkdown to DESCRIPTION.Imports immediately)
- Write tests before implementing features (TDD prevents logic bugs)
- Manual validation required for user-facing deliverables (render report, review formatting)
- Update STATUS.md at major milestones (track progress visibility)
- Document design decisions in code comments (explain *why*, not just *what*)

## Desired End State

After Phase 4 completion, the codebase will include:

1. **`R/generate_suggestions.R`** — Standalone function implementing 5 rule-based coaching patterns with 100% test coverage
2. **`reports/template.qmd`** — Quarto report template with 5 sections: executive summary, top performers, score distributions, trends, suggestions
3. **`scripts/generate_report.R`** — Command-line script that loads scored data, generates suggestions, renders HTML report with timestamp
4. **`tests/testthat/test-generate_suggestions.R`** — Minimum 10 test cases covering all rules and edge cases
5. **Generated report** — `reports/executive_report_YYYY-MM-DD.html` with professional formatting suitable for VP-level review
6. **Updated documentation** — CLAUDE.md, AGENTS.md, README.md with report generation commands and suggestion engine explanation

### How to Verify Success

**Primary validation**: Run `Rscript scripts/generate_report.R`, open `reports/executive_report_<timestamp>.html` in browser, verify:
- Executive summary shows total reps, average score, date range
- Top 10 performers table displays with dimension scores
- Score distribution histogram renders
- Dimension breakdown grouped bar chart renders
- Trend analysis shows top 5 improvers/decliners (if ≥2 periods)
- Suggestions table shows at least 1 coaching recommendation

**Secondary validation**: Non-technical executive can answer "Who are my top performers?", "Are any reps declining?", "What coaching should I prioritize?" by reading the report alone.

## What We're NOT Doing

- **Advanced statistical analysis** (correlation, regression, predictive modeling) — not in BRIEF.md
- **Custom report branding** or white-labeling — keep professional but generic
- **Automated report scheduling** or email delivery — static generation only
- **Multi-team comparisons** or org-wide benchmarking — single dataset focus
- **Real-time data refresh** in reports — reports are static snapshots
- **Interactive Quarto widgets** — keep reports simple HTML (charts are static images)
- **Machine learning-based suggestions** — rule-based logic only
- **Dashboard integration of suggestions** — deferred unless report completes early (SPEC.md:73-74, REFLECTIONS.md:319-322 prioritize report as primary deliverable)
- **PDF rendering** — optional, requires LaTeX installation, focus on HTML first (SPEC.md:96)

## Implementation Approach

### Strategy
Use **test-driven vertical slices**: implement suggestions engine first (pure R function, easy to test), then Quarto report (harder to test, benefits from real suggestions data), then report generation script (orchestrates both).

### Rationale
1. **Suggestions engine first** — Zero UI dependencies, can achieve 100% test coverage before touching Quarto
2. **Quarto template second** — Requires manual validation, but can test with real suggestions data
3. **Report script last** — Orchestrates both components, validates end-to-end workflow

### Technical Decisions

**Decision 1: Call Quarto CLI directly via system2(), not quarto R package**
- Rationale: Avoids adding another R package dependency, quarto R package not currently in DESCRIPTION
- Trade-off: Less robust error handling, but simpler setup
- Implementation: Check `Sys.which("quarto")` before rendering, provide clear error message if missing

**Decision 2: Suggestion priority — Low overall score (<40) takes precedence when multiple rules match**
- Rationale: Comprehensive coaching for struggling reps is most critical intervention
- Trade-off: May miss nuanced suggestions (e.g., high activity/low conversion) if overall score low
- Implementation: Check low overall score rule first, then evaluate dimension-specific rules

**Decision 3: Trend charts — Include section with "Insufficient data" message if <2 periods**
- Rationale: Maintains consistent report structure regardless of data, clearer than omitting section
- Trade-off: Adds empty section to single-period reports
- Implementation: Conditional chunk in Quarto template with `eval=FALSE` if periods < 2

**Decision 4: Dependencies in DESCRIPTION.Imports, not Suggests**
- Rationale: Phase 3 REFLECTIONS.md:59-63 identified plotly misconfiguration as deployment blocker
- Trade-off: None — knitr and rmarkdown are hard requirements for report rendering
- Implementation: Add to Imports section in Task 1 before writing code

---

## Task 1: Configure Dependencies and Project Structure

### Overview
Set up Phase 4 dependencies, create directory structure, and document Quarto CLI prerequisite. This prevents deployment issues identified in Phase 3 and ensures all tools available before implementation.

### Changes Required

**File**: `DESCRIPTION`
**Changes**:
```r
# Add to Imports section (after line 17):
Imports:
    dplyr,
    tibble,
    purrr,
    shiny,
    shinydashboard,
    DT,
    plotly,
    ggplot2,
    knitr,        # NEW: Required for Quarto rendering
    rmarkdown     # NEW: Required for Quarto rendering
```

**File**: `AGENTS.md` (add new section after "Dashboard Usage")
**Changes**: Add "Executive Report Generation" section:
```markdown
## Executive Report Generation

### Prerequisites

#### Quarto CLI Installation
Quarto CLI must be installed on your system (not an R package):

**Mac:**
```bash
brew install quarto
```

**Linux/Windows:**
Visit https://quarto.org/docs/get-started/

**Verify installation:**
```bash
quarto --version
# Expected: 1.3.0 or higher
```

#### Optional: LaTeX for PDF Output
PDF rendering requires LaTeX (optional, HTML is default format):
```bash
# Install TinyTeX via Quarto
quarto install tinytex

# Or verify existing LaTeX installation
pdflatex --version
```
```

**Directory**: Create `reports/` directory
**Command**: `mkdir -p reports`

**File**: `STATUS.md`
**Changes**: Update to reflect Phase 4 start:
```markdown
Phase: 4
Step: dependencies_configured
Status: IN PROGRESS
```

### Success Criteria
- [ ] `DESCRIPTION` file includes knitr and rmarkdown in Imports section
- [ ] `quarto --version` command documented in AGENTS.md with installation instructions
- [ ] `reports/` directory exists
- [ ] STATUS.md updated to Phase 4 "dependencies_configured"
- [ ] `Rscript -e "library(knitr); library(rmarkdown)"` executes without errors (validates dependencies installed)

---

## Task 2: Implement Suggestions Engine (TDD - Write Tests First)

### Overview
Create test file with 10+ test cases covering all 5 suggestion rules plus edge cases. Write FAILING tests first (TDD approach), then implement `generate_suggestions()` function to make tests pass.

### Changes Required

**File**: `tests/testthat/test-generate_suggestions.R` (CREATE NEW)
**Changes**: Write comprehensive test suite BEFORE implementation:

```r
# Source dependencies
library(testthat)
root <- rprojroot::find_root("DESCRIPTION")
source(file.path(root, "R", "generate_suggestions.R"))

# Create test data fixtures
test_that("generate_suggestions works with sample data fixtures", {
  # Fixture: High activity (80) + Low conversion (40)
  high_act_low_conv <- data.frame(
    rep_id = "REP001",
    rep_name = "Rep A",
    score = 60,
    activity_score = 80,
    conversion_score = 40,
    revenue_score = 60
  )

  result <- generate_suggestions(high_act_low_conv)

  expect_equal(nrow(result), 1)
  expect_equal(result$rep_id, "REP001")
  expect_equal(result$suggestion_category, "conversion_training")
  expect_match(result$suggestion_text, "conversion")
})

# Test Rule 1: High Activity / Low Conversion
test_that("suggests conversion training for high activity low conversion", {
  data <- data.frame(
    rep_id = "REP001", rep_name = "Rep A",
    score = 60, activity_score = 76, conversion_score = 49, revenue_score = 60
  )
  result <- generate_suggestions(data)
  expect_equal(result$suggestion_category, "conversion_training")
  expect_match(result$suggestion_text, "meeting quality|conversion rate")
})

# Test Rule 2: Low Activity / High Conversion
test_that("suggests increase outreach for low activity high conversion", {
  data <- data.frame(
    rep_id = "REP002", rep_name = "Rep B",
    score = 60, activity_score = 39, conversion_score = 71, revenue_score = 60
  )
  result <- generate_suggestions(data)
  expect_equal(result$suggestion_category, "increase_outreach")
  expect_match(result$suggestion_text, "outreach|volume")
})

# Test Rule 3: High Conversion / Low Revenue
test_that("suggests deal sizing for high conversion low revenue", {
  data <- data.frame(
    rep_id = "REP003", rep_name = "Rep C",
    score = 60, activity_score = 60, conversion_score = 76, revenue_score = 49
  )
  result <- generate_suggestions(data)
  expect_equal(result$suggestion_category, "deal_sizing")
  expect_match(result$suggestion_text, "deal siz|upsell")
})

# Test Rule 4: Low Overall Score
test_that("suggests comprehensive coaching for low overall score", {
  data <- data.frame(
    rep_id = "REP004", rep_name = "Rep D",
    score = 35, activity_score = 35, conversion_score = 35, revenue_score = 35
  )
  result <- generate_suggestions(data)
  expect_equal(result$suggestion_category, "comprehensive_coaching")
  expect_match(result$suggestion_text, "comprehensive|skill gaps")
})

# Test Rule 5: High Overall Score
test_that("suggests mentorship for high overall score", {
  data <- data.frame(
    rep_id = "REP005", rep_name = "Rep E",
    score = 90, activity_score = 88, conversion_score = 90, revenue_score = 92
  )
  result <- generate_suggestions(data)
  expect_equal(result$suggestion_category, "mentorship")
  expect_match(result$suggestion_text, "mentorship|leadership")
})

# Edge Case: Multiple rules match → prioritize low overall score
test_that("prioritizes low overall score over dimension-specific rules", {
  data <- data.frame(
    rep_id = "REP006", rep_name = "Rep F",
    score = 38, activity_score = 80, conversion_score = 30, revenue_score = 35
  )
  result <- generate_suggestions(data)
  expect_equal(result$suggestion_category, "comprehensive_coaching")
})

# Edge Case: Mid-range scores → no suggestion
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
  expect_equal(ncol(result), 4)  # rep_id, rep_name, suggestion_category, suggestion_text
})

# Edge Case: Missing dimension scores (NA values)
test_that("handles NA dimension scores gracefully", {
  data <- data.frame(
    rep_id = "REP008", rep_name = "Rep H",
    score = 50, activity_score = NA, conversion_score = 60, revenue_score = 70
  )
  result <- generate_suggestions(data)
  expect_true(nrow(result) >= 0)  # Should not crash
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
  expect_true(all(c("rep_id", "rep_name", "suggestion_category", "suggestion_text") %in% names(result)))
  expect_type(result$rep_id, "character")
  expect_type(result$suggestion_category, "character")
  expect_type(result$suggestion_text, "character")
})
```

### Success Criteria
- [ ] Test file created with minimum 10 test cases
- [ ] Tests FAIL initially (function doesn't exist yet — this confirms TDD approach)
- [ ] All 5 suggestion rules covered in tests (high act/low conv, low act/high conv, high conv/low rev, low overall, high overall)
- [ ] Edge cases tested (empty input, NA values, mid-range scores, multiple reps)
- [ ] Output schema validation test included

**Note**: Do NOT implement `R/generate_suggestions.R` yet — tests must fail first to validate TDD approach.

---

## Task 3: Implement Suggestions Engine Function

### Overview
Implement `generate_suggestions()` function in `R/generate_suggestions.R` to make all tests pass. Use rule-based logic with priority ordering: low overall score → dimension-specific patterns.

### Changes Required

**File**: `R/generate_suggestions.R` (CREATE NEW)
**Changes**: Implement complete suggestions engine:

```r
#' Generate Improvement Suggestions Based on Score Patterns
#'
#' Analyzes rep performance scores and returns rule-based coaching recommendations.
#' Identifies specific skill gaps and development opportunities using dimension scores.
#'
#' @param scored_data Data frame with columns: rep_id, rep_name, score,
#'   activity_score, conversion_score, revenue_score
#'
#' @return Data frame with columns: rep_id, rep_name, suggestion_category,
#'   suggestion_text. Returns empty data frame if no suggestions match.
#'   When multiple rules match, returns the most critical suggestion per rep.
#'
#' @details
#' Implements 5 rule-based patterns with priority ordering:
#' 1. Low overall score (<40) → comprehensive_coaching (HIGHEST PRIORITY)
#' 2. High overall score (>85) → mentorship
#' 3. High activity (>75) + Low conversion (<50) → conversion_training
#' 4. Low activity (<40) + High conversion (>70) → increase_outreach
#' 5. High conversion (>75) + Low revenue (<50) → deal_sizing
#'
#' Priority rationale: Struggling reps need comprehensive support before
#' dimension-specific coaching. High performers identified for leadership roles.
#' Mid-range scores receive targeted coaching on specific weaknesses.
#'
#' @examples
#' scored_data <- read.csv("data/scored_reps.csv")
#' suggestions <- generate_suggestions(scored_data)
#' View(suggestions[suggestions$suggestion_category == "conversion_training", ])
#'
#' @export
generate_suggestions <- function(scored_data) {
  # Validate input
  required_cols <- c("rep_id", "rep_name", "score", "activity_score",
                     "conversion_score", "revenue_score")

  if (!is.data.frame(scored_data) || nrow(scored_data) == 0) {
    return(data.frame(
      rep_id = character(0),
      rep_name = character(0),
      suggestion_category = character(0),
      suggestion_text = character(0),
      stringsAsFactors = FALSE
    ))
  }

  missing <- setdiff(required_cols, names(scored_data))
  if (length(missing) > 0) {
    stop(paste0("Missing required columns: ", paste(missing, collapse = ", ")))
  }

  # Process each rep individually
  suggestions_list <- lapply(seq_len(nrow(scored_data)), function(i) {
    rep <- scored_data[i, ]

    # Skip reps with NA dimension scores (insufficient data)
    if (any(is.na(c(rep$activity_score, rep$conversion_score, rep$revenue_score)))) {
      return(NULL)
    }

    # Priority 1: Low overall score → comprehensive coaching
    if (rep$score < 40) {
      return(data.frame(
        rep_id = rep$rep_id,
        rep_name = rep$rep_name,
        suggestion_category = "comprehensive_coaching",
        suggestion_text = "Schedule comprehensive coaching session to identify skill gaps and barriers",
        stringsAsFactors = FALSE
      ))
    }

    # Priority 2: High overall score → mentorship
    if (rep$score > 85) {
      return(data.frame(
        rep_id = rep$rep_id,
        rep_name = rep$rep_name,
        suggestion_category = "mentorship",
        suggestion_text = "Consider for mentorship role or leadership development",
        stringsAsFactors = FALSE
      ))
    }

    # Priority 3: High activity + Low conversion → conversion training
    if (rep$activity_score > 75 && rep$conversion_score < 50) {
      return(data.frame(
        rep_id = rep$rep_id,
        rep_name = rep$rep_name,
        suggestion_category = "conversion_training",
        suggestion_text = "Focus on meeting quality and follow-up techniques to improve conversion rate",
        stringsAsFactors = FALSE
      ))
    }

    # Priority 4: Low activity + High conversion → increase outreach
    if (rep$activity_score < 40 && rep$conversion_score > 70) {
      return(data.frame(
        rep_id = rep$rep_id,
        rep_name = rep$rep_name,
        suggestion_category = "increase_outreach",
        suggestion_text = "Increase outreach volume to capitalize on strong conversion skills",
        stringsAsFactors = FALSE
      ))
    }

    # Priority 5: High conversion + Low revenue → deal sizing
    if (rep$conversion_score > 75 && rep$revenue_score < 50) {
      return(data.frame(
        rep_id = rep$rep_id,
        rep_name = rep$rep_name,
        suggestion_category = "deal_sizing",
        suggestion_text = "Focus on deal sizing and upselling to increase revenue per closed deal",
        stringsAsFactors = FALSE
      ))
    }

    # No matching pattern → return NULL (no suggestion for mid-range performers)
    return(NULL)
  })

  # Combine all suggestions and remove NULLs
  suggestions_list <- Filter(Negate(is.null), suggestions_list)

  if (length(suggestions_list) == 0) {
    return(data.frame(
      rep_id = character(0),
      rep_name = character(0),
      suggestion_category = character(0),
      suggestion_text = character(0),
      stringsAsFactors = FALSE
    ))
  }

  do.call(rbind, suggestions_list)
}
```

### Success Criteria
- [ ] All tests pass: `Rscript -e "testthat::test_file('tests/testthat/test-generate_suggestions.R')"`
- [ ] Coverage reaches 100%: `Rscript scripts/coverage_report.R` shows `R/generate_suggestions.R: 100.00%`
- [ ] Function documented with roxygen2 (@param, @return, @details, @examples)
- [ ] Priority ordering explained in comments (low overall score takes precedence)
- [ ] Edge cases handled gracefully (empty input, NA values)
- [ ] Function can process real scored data: `generate_suggestions(read.csv("data/scored_reps.csv"))` returns suggestions without errors

---

## Task 4: Integration Test for Suggestions Engine

### Overview
Add end-to-end integration test that loads real scored data from `data/scored_reps.csv` and validates suggestions output structure and content. Ensures suggestions engine works with production data, not just synthetic test fixtures.

### Changes Required

**File**: `tests/testthat/test-integration.R` (APPEND to existing file)
**Changes**: Add suggestion engine integration test at end of file:

```r
# Suggestions Engine Integration Tests
test_that("generate_suggestions works with real scored data", {
  # Source suggestions function
  source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "generate_suggestions.R"))

  # Load real scored data
  scored_data <- read.csv(
    file.path(rprojroot::find_root("DESCRIPTION"), "data", "scored_reps.csv"),
    stringsAsFactors = FALSE
  )

  # Generate suggestions
  suggestions <- generate_suggestions(scored_data)

  # Validate output structure
  expect_true(is.data.frame(suggestions))
  expect_true(all(c("rep_id", "rep_name", "suggestion_category", "suggestion_text") %in% names(suggestions)))

  # Validate at least some suggestions returned (scored_reps.csv has diverse scores)
  expect_true(nrow(suggestions) > 0)
  expect_true(nrow(suggestions) <= nrow(scored_data))  # At most one suggestion per rep

  # Validate known patterns in real data
  # REP001 (Rep A) has score=49, activity=39, conversion=52, revenue=56 → likely no suggestion or low activity pattern
  # We don't hard-code expected suggestions here since data may change, just validate structure

  # Validate category values are from expected set
  valid_categories <- c("comprehensive_coaching", "mentorship", "conversion_training",
                        "increase_outreach", "deal_sizing")
  expect_true(all(suggestions$suggestion_category %in% valid_categories))

  # Validate text is non-empty
  expect_true(all(nchar(suggestions$suggestion_text) > 0))

  cat("\nSuggestions generated for", nrow(suggestions), "out of", nrow(scored_data), "reps\n")
})

test_that("suggestions engine handles single-period data", {
  # Source suggestions function
  source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "generate_suggestions.R"))

  # Load real scored data and filter to single period
  scored_data <- read.csv(
    file.path(rprojroot::find_root("DESCRIPTION"), "data", "scored_reps.csv"),
    stringsAsFactors = FALSE
  )
  single_period <- scored_data[scored_data$period == "Q1_2025", ]

  # Generate suggestions (should work regardless of number of periods)
  suggestions <- generate_suggestions(single_period)

  expect_true(is.data.frame(suggestions))
  expect_true(nrow(suggestions) <= nrow(single_period))
})
```

### Success Criteria
- [ ] Integration test passes: `Rscript -e "testthat::test_file('tests/testthat/test-integration.R')"`
- [ ] Test validates real scored_reps.csv data structure
- [ ] Test confirms at least some suggestions returned (diverse score patterns exist)
- [ ] Test validates category values from expected set
- [ ] Test validates single-period data handling
- [ ] Console output shows suggestions count for visibility

---

## Task 5: Create Quarto Report Template

### Overview
Create `reports/template.qmd` with 5 sections: executive summary, top performers, score distributions, trend analysis, and improvement suggestions. Use parameterized input to accept CSV path. Focus on professional formatting suitable for VP-level review.

### Changes Required

**File**: `reports/template.qmd` (CREATE NEW)
**Changes**: Full Quarto template with all sections:

````markdown
---
title: "Sales Rep Performance — Executive Report"
format:
  html:
    theme: cosmo
    toc: true
    toc-depth: 2
    code-fold: true
    embed-resources: true
date: "`r format(Sys.Date(), '%B %d, %Y')`"
params:
  input_csv: "data/scored_reps.csv"
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE)

# Load required libraries
library(dplyr)
library(ggplot2)
library(knitr)

# Source suggestion engine
source("../R/generate_suggestions.R")

# Load scored data
scored_data <- read.csv(params$input_csv, stringsAsFactors = FALSE)

# Generate suggestions
suggestions <- generate_suggestions(scored_data)

# Calculate summary metrics
total_reps <- length(unique(scored_data$rep_id))
total_periods <- length(unique(scored_data$period))
avg_score <- mean(scored_data$score, na.rm = TRUE)
score_range <- range(scored_data$score, na.rm = TRUE)

# Identify top performers (top 10 by average score across all periods)
top_performers <- scored_data |>
  group_by(rep_id, rep_name) |>
  summarise(
    avg_score = mean(score, na.rm = TRUE),
    avg_activity = mean(activity_score, na.rm = TRUE),
    avg_conversion = mean(conversion_score, na.rm = TRUE),
    avg_revenue = mean(revenue_score, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(avg_score)) |>
  head(10)
```

# Executive Summary

**Analysis Period:** `r paste(unique(scored_data$period), collapse = ", ")`
**Total Representatives Analyzed:** `r total_reps`
**Average Performance Score:** `r round(avg_score, 1)`
**Score Range:** `r round(score_range[1], 1)` – `r round(score_range[2], 1)`

This report provides a comprehensive analysis of sales representative performance across activity quality, conversion efficiency, and revenue contribution. Scores are normalized (0-100 scale) and adjusted for tenure and territory size to ensure fair comparisons.

---

# Top Performers

The following table shows the top 10 sales representatives by average performance score:

```{r top-performers-table}
top_performers_display <- top_performers |>
  mutate(
    avg_score = round(avg_score, 1),
    avg_activity = round(avg_activity, 1),
    avg_conversion = round(avg_conversion, 1),
    avg_revenue = round(avg_revenue, 1)
  )

kable(
  top_performers_display,
  col.names = c("Rep ID", "Rep Name", "Overall Score", "Activity", "Conversion", "Revenue"),
  align = c("l", "l", "r", "r", "r", "r"),
  caption = "Top 10 Sales Representatives (Average Across All Periods)"
)
```

---

# Score Distributions

## Overall Performance Distribution

```{r score-distribution-histogram}
ggplot(scored_data, aes(x = score)) +
  geom_histogram(bins = 20, fill = "#4A90E2", color = "white", alpha = 0.8) +
  labs(
    title = "Distribution of Overall Performance Scores",
    x = "Overall Score (0-100)",
    y = "Number of Rep-Period Observations"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 11)
  )
```

## Dimension Score Breakdown

```{r dimension-breakdown}
# Calculate average dimension scores per rep
dimension_summary <- scored_data |>
  group_by(rep_id, rep_name) |>
  summarise(
    Activity = mean(activity_score, na.rm = TRUE),
    Conversion = mean(conversion_score, na.rm = TRUE),
    Revenue = mean(revenue_score, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(Activity + Conversion + Revenue)) |>
  head(10)

# Reshape for grouped bar chart
dimension_long <- dimension_summary |>
  tidyr::pivot_longer(
    cols = c(Activity, Conversion, Revenue),
    names_to = "Dimension",
    values_to = "Score"
  )

ggplot(dimension_long, aes(x = reorder(rep_name, -Score), y = Score, fill = Dimension)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
  scale_fill_manual(values = c(
    "Activity" = "#FF6B6B",
    "Conversion" = "#4ECDC4",
    "Revenue" = "#45B7D1"
  )) +
  labs(
    title = "Dimension Scores by Top 10 Representatives",
    x = "Representative",
    y = "Average Score (0-100)",
    fill = "Dimension"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 11),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )
```

---

# Trend Analysis

```{r trend-analysis, eval=(total_periods >= 2)}
# Identify top 5 improvers and decliners (requires at least 2 periods)
if (total_periods >= 2) {
  # Calculate score change from first to last period per rep
  trend_data <- scored_data |>
    group_by(rep_id, rep_name) |>
    arrange(period) |>
    summarise(
      first_score = first(score),
      last_score = last(score),
      score_change = last_score - first_score,
      .groups = "drop"
    )

  top_improvers <- trend_data |>
    arrange(desc(score_change)) |>
    head(5)

  top_decliners <- trend_data |>
    arrange(score_change) |>
    head(5)

  # Plot improvers
  improver_data <- scored_data |>
    filter(rep_id %in% top_improvers$rep_id)

  print(
    ggplot(improver_data, aes(x = period, y = score, color = rep_name, group = rep_name)) +
      geom_line(linewidth = 1) +
      geom_point(size = 2) +
      labs(
        title = "Top 5 Improving Representatives",
        x = "Period",
        y = "Performance Score",
        color = "Representative"
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom"
      )
  )

  # Plot decliners
  decliner_data <- scored_data |>
    filter(rep_id %in% top_decliners$rep_id)

  print(
    ggplot(decliner_data, aes(x = period, y = score, color = rep_name, group = rep_name)) +
      geom_line(linewidth = 1) +
      geom_point(size = 2) +
      labs(
        title = "Top 5 Declining Representatives",
        x = "Period",
        y = "Performance Score",
        color = "Representative"
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom"
      )
  )
} else {
  cat("**Insufficient data for trend analysis.** Minimum 2 periods required.\n")
}
```

```{r trend-fallback, eval=(total_periods < 2)}
cat("**Insufficient data for trend analysis.** This report contains data for only", total_periods, "period. Trend charts require at least 2 periods to show performance changes over time.\n")
```

---

# Improvement Suggestions

```{r suggestions-table}
if (nrow(suggestions) > 0) {
  suggestions_display <- suggestions |>
    select(rep_name, suggestion_category, suggestion_text) |>
    arrange(suggestion_category, rep_name)

  kable(
    suggestions_display,
    col.names = c("Representative", "Category", "Recommendation"),
    align = c("l", "l", "l"),
    caption = "Coaching Recommendations by Representative"
  )

  cat("\n\n**Total Representatives with Recommendations:**", nrow(suggestions), "\n")
} else {
  cat("**No specific recommendations at this time.** All representatives are performing within expected ranges. Continue monitoring performance trends.\n")
}
```

---

## Report Metadata

**Generated:** `r format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z')`
**Data Source:** `r params$input_csv`
**Total Observations:** `r nrow(scored_data)` rep-period records

---

*This report was generated using the Sales Rep Performance Scoring System. Scores are normalized and adjusted for tenure and territory size to ensure fair, bias-free comparisons.*
````

### Success Criteria
- [ ] Template file created at `reports/template.qmd`
- [ ] Includes all 5 required sections (executive summary, top performers, distributions, trends, suggestions)
- [ ] Uses parameterized input: `params$input_csv`
- [ ] Sources `R/generate_suggestions.R` to generate suggestions
- [ ] Conditional trend charts: `eval=(total_periods >= 2)` for multi-period data
- [ ] Professional theme (cosmo) and embedded resources for standalone HTML
- [ ] Template includes report metadata footer

**Note**: Do NOT render template yet — will validate in next task with report generation script.

---

## Task 6: Create Report Generation Script

### Overview
Implement `scripts/generate_report.R` that accepts command-line arguments (--input, --output, --output-dir), validates Quarto CLI installation, generates suggestions, renders Quarto template, and outputs timestamped HTML/PDF report.

### Changes Required

**File**: `scripts/generate_report.R` (CREATE NEW)
**Changes**: Complete report generation script:

```r
#!/usr/bin/env Rscript

# Generate Executive Report
# Loads scored data, generates suggestions, renders Quarto report

# Parse command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Default arguments
input_csv <- "data/scored_reps.csv"
output_format <- "html"
output_dir <- "reports"

# Parse arguments (simple approach without optparse for minimal dependencies)
if (length(args) > 0) {
  for (i in seq_along(args)) {
    if (args[i] == "--input" && i < length(args)) {
      input_csv <- args[i + 1]
    } else if (args[i] == "--output" && i < length(args)) {
      output_format <- args[i + 1]
    } else if (args[i] == "--output-dir" && i < length(args)) {
      output_dir <- args[i + 1]
    }
  }
}

cat("==================================================\n")
cat("Sales Rep Performance — Executive Report Generator\n")
cat("==================================================\n\n")

# Validate Quarto CLI installation
quarto_path <- Sys.which("quarto")
if (quarto_path == "") {
  stop(paste0(
    "ERROR: Quarto CLI not found.\n\n",
    "Please install Quarto to generate reports:\n",
    "  Mac: brew install quarto\n",
    "  Linux/Windows: https://quarto.org/docs/get-started/\n\n",
    "After installation, verify with: quarto --version\n"
  ))
}

cat("Quarto CLI found:", quarto_path, "\n")

# Validate input file exists
if (!file.exists(input_csv)) {
  stop(paste0("ERROR: Input file not found: ", input_csv))
}

cat("Input file:", input_csv, "\n")
cat("Output format:", output_format, "\n")
cat("Output directory:", output_dir, "\n\n")

# Validate output format
if (!output_format %in% c("html", "pdf")) {
  stop("ERROR: Output format must be 'html' or 'pdf'")
}

# Create output directory if needed
if (!dir.exists(output_dir)) {
  cat("Creating output directory:", output_dir, "\n")
  dir.create(output_dir, recursive = TRUE)
}

# Generate timestamped output filename
timestamp <- format(Sys.Date(), "%Y-%m-%d")
output_file <- file.path(
  output_dir,
  paste0("executive_report_", timestamp, ".", output_format)
)

cat("Generating report...\n\n")

# Render Quarto template
template_path <- "reports/template.qmd"

if (!file.exists(template_path)) {
  stop(paste0("ERROR: Template not found: ", template_path))
}

# Build quarto render command
quarto_cmd <- paste0(
  "quarto render ", template_path,
  " --to ", output_format,
  " --output ", basename(output_file),
  " --output-dir ", output_dir,
  " --execute-params '{\"input_csv\": \"", input_csv, "\"}'"
)

cat("Executing:", quarto_cmd, "\n\n")

# Execute render command
render_result <- system(quarto_cmd, intern = FALSE)

if (render_result != 0) {
  stop("ERROR: Quarto rendering failed. Check error messages above.")
}

cat("\n==================================================\n")
cat("Report generation complete!\n")
cat("==================================================\n\n")
cat("Output file:", output_file, "\n")

# Validate output file was created
if (!file.exists(output_file)) {
  stop("ERROR: Output file was not created. Rendering may have failed.")
}

file_size <- file.info(output_file)$size
cat("File size:", format(file_size, big.mark = ","), "bytes\n\n")

cat("Open report with:\n")
cat("  open", output_file, "(Mac)\n")
cat("  xdg-open", output_file, "(Linux)\n")
cat("  start", output_file, "(Windows)\n\n")
```

**File**: `scripts/generate_report.R` (make executable)
**Command**: `chmod +x scripts/generate_report.R`

### Success Criteria
- [ ] Script created at `scripts/generate_report.R` with executable permissions
- [ ] Script checks for Quarto CLI installation before rendering
- [ ] Script accepts --input, --output, --output-dir arguments
- [ ] Script generates timestamped output filename (e.g., `executive_report_2026-02-17.html`)
- [ ] Script creates output directory if missing
- [ ] Script validates template and input file exist before rendering
- [ ] Script provides user-friendly error messages (Quarto missing, file not found, etc.)
- [ ] Script prints success message with output file path

---

## Task 7: End-to-End Report Generation Test

### Overview
Validate full report generation workflow: run `scripts/generate_report.R`, verify HTML report created, manually review report in browser for professional formatting and content accuracy. This is the critical user-facing deliverable validation.

### Changes Required

**File**: `tests/testthat/test-report-generation.R` (CREATE NEW)
**Changes**: Automated report generation tests:

```r
library(testthat)

test_that("report generation script produces HTML output", {
  # Skip if Quarto not installed (CI environment may not have Quarto)
  skip_if(Sys.which("quarto") == "", "Quarto CLI not installed")

  # Clean up any existing test reports
  test_output_dir <- "reports_test"
  if (dir.exists(test_output_dir)) {
    unlink(test_output_dir, recursive = TRUE)
  }

  # Run report generation script with test output directory
  result <- system2(
    "Rscript",
    args = c(
      "scripts/generate_report.R",
      "--input", "data/scored_reps.csv",
      "--output", "html",
      "--output-dir", test_output_dir
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  # Validate script executed successfully
  expect_equal(attr(result, "status"), NULL)  # NULL status = success (exit code 0)

  # Validate output file exists
  output_files <- list.files(test_output_dir, pattern = "executive_report_.*\\.html$")
  expect_true(length(output_files) > 0)

  # Validate file size > 0 (not empty)
  output_path <- file.path(test_output_dir, output_files[1])
  file_size <- file.info(output_path)$size
  expect_true(file_size > 1000)  # HTML report should be > 1KB

  # Clean up test output
  unlink(test_output_dir, recursive = TRUE)
})

test_that("report generation fails gracefully with missing input", {
  skip_if(Sys.which("quarto") == "", "Quarto CLI not installed")

  # Attempt to generate report with non-existent input
  result <- system2(
    "Rscript",
    args = c(
      "scripts/generate_report.R",
      "--input", "data/nonexistent.csv"
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  # Validate script exits with error
  expect_true(!is.null(attr(result, "status")))  # Non-null status = error
})

test_that("report generation fails gracefully without Quarto CLI", {
  # This test can't actually remove Quarto, but documents expected behavior
  skip("Manual test: Uninstall Quarto and verify error message")
})
```

**Manual Validation Checklist** (document in test comments or separate file):
```markdown
# Manual Report Validation Checklist

After running `Rscript scripts/generate_report.R`, open `reports/executive_report_<timestamp>.html` in browser and verify:

## Executive Summary Section
- [ ] Shows total reps analyzed (20)
- [ ] Shows date range (Q1-Q4 2025)
- [ ] Shows average score (numeric, reasonable range 40-70)
- [ ] Shows score range (min-max, reasonable spread)

## Top Performers Section
- [ ] Table displays 10 rows
- [ ] Columns: Rep ID, Rep Name, Overall Score, Activity, Conversion, Revenue
- [ ] Scores are sorted descending by Overall Score
- [ ] All scores are 0-100 range
- [ ] Formatting is clean and readable

## Score Distributions Section
- [ ] Histogram renders with reasonable distribution (not all zeros)
- [ ] X-axis labeled "Overall Score (0-100)"
- [ ] Y-axis labeled "Number of Rep-Period Observations"
- [ ] Title: "Distribution of Overall Performance Scores"
- [ ] Grouped bar chart renders for top 10 reps
- [ ] Three bars per rep (Activity, Conversion, Revenue)
- [ ] Colors distinct and professional (red, teal, blue)
- [ ] Legend shows dimension names

## Trend Analysis Section
- [ ] Line chart shows "Top 5 Improving Representatives"
- [ ] Line chart shows "Top 5 Declining Representatives"
- [ ] Each rep has distinct color in legend
- [ ] Lines connect period data points (Q1→Q2→Q3→Q4)
- [ ] If single period: Shows "Insufficient data" message instead

## Improvement Suggestions Section
- [ ] Table displays coaching recommendations
- [ ] Columns: Representative, Category, Recommendation
- [ ] At least 1 suggestion present (sample data has diverse scores)
- [ ] Recommendation text is actionable and clear
- [ ] Categories from expected set (conversion_training, increase_outreach, etc.)

## Report Metadata Footer
- [ ] Shows generation timestamp
- [ ] Shows data source path (data/scored_reps.csv)
- [ ] Shows total observations (80 rep-period records)

## Professional Appearance
- [ ] No raw R code visible (code-fold: true works)
- [ ] No error messages or warnings in output
- [ ] Color scheme is professional (cosmo theme)
- [ ] Typography is readable (appropriate font sizes)
- [ ] Suitable for sharing with VP-level executive
```

### Success Criteria
- [ ] Run `Rscript scripts/generate_report.R` executes without errors
- [ ] HTML report file created in `reports/` directory with timestamp
- [ ] Report file size > 100KB (contains charts and formatting)
- [ ] Automated test validates file creation and non-zero size
- [ ] Manual checklist completed: all sections render correctly, professional formatting verified
- [ ] Report opens in browser and displays charts (not broken images)
- [ ] No code chunks visible in output (code-fold: true effective)

**Critical**: This task requires manual review — automated tests cannot validate UX quality. Open report in browser and systematically verify all sections per checklist above.

---

## Task 8: Documentation Updates

### Overview
Update CLAUDE.md, AGENTS.md, and README.md with report generation commands, suggestion engine explanation, and Phase 4 completion status. Document commands only after testing and verifying they work.

### Changes Required

**File**: `CLAUDE.md` (add to "Quick Command Reference" section)
**Changes**: Add report generation commands:
```markdown
### Generate Executive Report
```bash
Rscript scripts/generate_report.R
```

### Generate PDF Report (requires LaTeX)
```bash
Rscript scripts/generate_report.R --output pdf
```

### Generate Report from Custom Data
```bash
Rscript scripts/generate_report.R --input data/custom_scored.csv
```
```

**File**: `AGENTS.md` (add new section after "Dashboard Usage")
**Changes**: Add complete "Report Generation Workflow" section:
```markdown
## Report Generation Workflow

### Prerequisites
Ensure Quarto CLI installed (see "Executive Report Generation" → "Prerequisites" section above).

### Generate Executive Report

**Command:**
```bash
Rscript scripts/generate_report.R
```

**Output:** `reports/executive_report_<YYYY-MM-DD>.html`

**What the report includes:**
- Executive summary with key metrics (total reps, average score, score range)
- Top 10 performers table with dimension scores
- Score distribution histogram and dimension breakdown charts
- Trend analysis showing top 5 improving/declining reps over time
- Improvement suggestions table with coaching recommendations

### Customize Report Parameters

**Use custom input file:**
```bash
Rscript scripts/generate_report.R --input data/custom_scored.csv
```

**Generate PDF format (requires LaTeX):**
```bash
Rscript scripts/generate_report.R --output pdf
```

**Specify output directory:**
```bash
Rscript scripts/generate_report.R --output-dir custom_reports/
```

### Improvement Suggestions Engine

The report includes rule-based coaching recommendations based on dimension score patterns:

**Rule 1: High Activity (>75) + Low Conversion (<50)**
- **Suggestion:** Focus on meeting quality and follow-up techniques to improve conversion rate
- **Rationale:** High activity indicates strong outreach, but poor conversion suggests skill gap in closing

**Rule 2: Low Activity (<40) + High Conversion (>70)**
- **Suggestion:** Increase outreach volume to capitalize on strong conversion skills
- **Rationale:** Strong closing ability, but insufficient pipeline volume limits results

**Rule 3: High Conversion (>75) + Low Revenue (<50)**
- **Suggestion:** Focus on deal sizing and upselling to increase revenue per closed deal
- **Rationale:** Good at closing deals, but small deal sizes limit revenue contribution

**Rule 4: Low Overall Score (<40)**
- **Suggestion:** Schedule comprehensive coaching session to identify skill gaps and barriers
- **Rationale:** Struggling across multiple dimensions requires holistic intervention
- **Priority:** This rule takes precedence over dimension-specific patterns (most critical need)

**Rule 5: High Overall Score (>85)**
- **Suggestion:** Consider for mentorship role or leadership development
- **Rationale:** Top performers can help develop others and take on leadership opportunities

**Edge Cases Handled:**
- Reps with mid-range scores (40-75 all dimensions): No suggestion (performing within expectations)
- Reps with NA dimension scores: Skipped (insufficient data for recommendation)
- Multiple matching rules: Returns most critical suggestion per rep (priority ordering)

### Viewing Generated Reports

**Mac:**
```bash
open reports/executive_report_<YYYY-MM-DD>.html
```

**Linux:**
```bash
xdg-open reports/executive_report_<YYYY-MM-DD>.html
```

**Windows:**
```cmd
start reports/executive_report_<YYYY-MM-DD>.html
```

### Troubleshooting

**Error: "Quarto CLI not found"**
Install Quarto: `brew install quarto` (Mac) or visit https://quarto.org/docs/get-started/

**Error: "Template not found"**
Ensure you're running command from project root directory (where DESCRIPTION file is located)

**Error: "Input file not found"**
Generate scored data first: `Rscript scripts/score_data.R`

**PDF rendering fails**
Install LaTeX: `quarto install tinytex` or verify pdflatex installed
```

**File**: `README.md` (update Phase Status and add new sections)
**Changes**:
1. Update Phase Status section:
```markdown
## Phase Status
- **Phase 1** (COMPLETE): Data model + sample data generation
- **Phase 2** (COMPLETE): Scoring engine with normalization
- **Phase 3** (COMPLETE): Shiny dashboard with live weights and visualizations
- **Phase 4** (COMPLETE): Quarto executive reports + improvement suggestions engine

**PROJECT COMPLETE** — All BRIEF.md requirements delivered.
```

2. Add "Executive Reporting" section after "Interactive Dashboard":
```markdown
## Executive Reporting

Generate polished HTML/PDF reports for leadership with top performers, trends, and coaching recommendations.

**Generate report:**
```bash
Rscript scripts/generate_report.R
```

**Report sections:**
- **Executive Summary** — Total reps, average score, score range, analysis period
- **Top Performers** — Top 10 reps with overall and dimension scores
- **Score Distributions** — Histogram of overall scores, grouped bar chart of dimensions
- **Trend Analysis** — Top 5 improving/declining reps over quarters
- **Improvement Suggestions** — Rule-based coaching recommendations

**Output:** `reports/executive_report_<YYYY-MM-DD>.html` — Shareable static report (no R server needed)
```

3. Add "Improvement Suggestions" section:
```markdown
## Improvement Suggestions

Rule-based coaching recommendations identify specific development opportunities:

- **High activity + Low conversion** → Focus on meeting quality and follow-up techniques
- **Low activity + High conversion** → Increase outreach volume to capitalize on strong conversion skills
- **High conversion + Low revenue** → Focus on deal sizing and upselling
- **Low overall score (<40)** → Schedule comprehensive coaching session
- **High overall score (>85)** → Consider for mentorship or leadership development

Suggestions are integrated into executive reports and help managers prioritize coaching efforts.
```

### Success Criteria
- [ ] CLAUDE.md includes report generation commands in "Quick Command Reference"
- [ ] AGENTS.md includes complete "Report Generation Workflow" section with all 5 suggestion rules explained
- [ ] AGENTS.md includes troubleshooting section for common errors
- [ ] README.md Phase Status updated to "Phase 4 COMPLETE" and "PROJECT COMPLETE"
- [ ] README.md includes "Executive Reporting" and "Improvement Suggestions" sections
- [ ] All documented commands tested and verified working before documentation commit

---

## Task 9: Update STATUS.md to Phase 4 Complete

### Overview
Mark Phase 4 complete in STATUS.md, indicating project completion. This ensures project tracking is up-to-date and Phase 4 REFLECTIONS.md can reference completion state.

### Changes Required

**File**: `STATUS.md`
**Changes**: Update to completion state:
```markdown
Phase: 4
Step: complete
Status: PROJECT COMPLETE

Last Updated: 2026-02-17

Phase 4 delivered:
- Quarto executive report template with 5 sections (summary, top performers, distributions, trends, suggestions)
- Rule-based improvement suggestions engine with 100% test coverage
- Report generation script with CLI arguments and error handling
- HTML report output with professional formatting suitable for VP-level review
- Complete documentation in CLAUDE.md, AGENTS.md, README.md

All BRIEF.md requirements complete.
```

### Success Criteria
- [ ] STATUS.md shows "Phase: 4"
- [ ] STATUS.md shows "Step: complete"
- [ ] STATUS.md shows "Status: PROJECT COMPLETE"
- [ ] STATUS.md includes Phase 4 deliverables summary
- [ ] STATUS.md timestamp matches completion date

---

## Task 10: Performance Validation and Final Testing

### Overview
Run full test suite, validate 100% coverage maintained, verify report generation performance meets <30 second target for 1000-row dataset. This ensures all quality gates pass before phase completion.

### Changes Required

**Test Execution Sequence:**

1. **Run unit tests:**
```bash
Rscript -e "testthat::test_dir('tests/testthat')"
```
Expected: All tests pass (200+ tests), 0 failures

2. **Validate coverage:**
```bash
Rscript scripts/coverage_report.R
```
Expected output includes:
```
R/generate_suggestions.R: 100.00%
Overall coverage: 100.0%
```

3. **Performance test — Create 1000-row test dataset:**
```bash
# Manual R script to create large test dataset
Rscript -e "
  set.seed(123)
  large_data <- do.call(rbind, replicate(13, read.csv('data/scored_reps.csv'), simplify = FALSE))
  large_data <- large_data[1:1000, ]
  write.csv(large_data, 'data/scored_reps_1000.csv', row.names = FALSE)
  cat('Created 1000-row test dataset\n')
"
```

4. **Measure report generation time:**
```bash
time Rscript scripts/generate_report.R --input data/scored_reps_1000.csv --output-dir reports_test
```
Expected: Completes in < 30 seconds (SPEC.md:78 requirement)

5. **Clean up test artifacts:**
```bash
rm data/scored_reps_1000.csv
rm -rf reports_test
```

### Success Criteria
- [ ] All unit tests pass (0 failures, 0 errors)
- [ ] Coverage report shows 100% for `R/generate_suggestions.R`
- [ ] Overall project coverage remains 100%
- [ ] Report generation completes in < 30 seconds for 1000-row dataset
- [ ] No new warnings or errors introduced
- [ ] Test count increased (minimum 10 new tests for suggestions engine)

---

## Testing Strategy

### Unit Tests
**What to test:**
- All 5 suggestion rules return correct category and text (Task 2)
- Priority ordering: low overall score takes precedence over dimension-specific rules (Task 2)
- Edge cases: empty input, NA values, mid-range scores, single rep, multiple reps (Task 2)
- Output schema validation: 4 columns with correct types (Task 2)
- Input validation: missing required columns throws error (Task 2)

**Mocking strategy:**
- Prefer real implementations over mocking (AGENTS.md:150 anti-mock bias)
- Use simple test fixtures (data frames) instead of mocking `read.csv()`
- No mocking needed for suggestions engine (pure function with no external dependencies)

### Integration Tests
**What to test:**
- `generate_suggestions()` works with real `data/scored_reps.csv` (Task 4)
- Suggestions returned have valid categories from expected set (Task 4)
- Single-period data handling (Task 4)
- Report generation produces non-empty HTML file (Task 7)
- Report generation fails gracefully with missing input file (Task 7)

### Manual Validation (Critical for UX)
**What to validate:**
- Report opens in browser without errors (Task 7)
- All charts render (not broken images) (Task 7)
- Professional formatting suitable for executives (Task 7)
- Suggestion text is clear and actionable (Task 7)
- No code chunks visible in output (Task 7)
- Complete checklist in Task 7 before marking phase complete

### Performance Tests
**What to measure:**
- Report generation time for 1000-row dataset must be < 30 seconds (SPEC.md:78)
- Measure in Task 10 with `time` command
- Compare to Phase 3 scoring performance (0.044s for 1000 rows) — report rendering will be slower due to chart generation

## Risk Assessment

**Risk: Quarto CLI not available in CI environment**
- **Likelihood:** Medium — External dependency not controlled by R package manager
- **Impact:** High — Report generation tests skip, reducing coverage
- **Mitigation:** Document Quarto installation in AGENTS.md, use `skip_if(Sys.which("quarto") == "")` in tests, mark report generation tests as integration tests that may skip in CI

**Risk: Report rendering fails with cryptic Quarto error**
- **Likelihood:** Medium — Quarto errors can be opaque (missing packages, syntax errors in template)
- **Impact:** Medium — Delays troubleshooting, frustrating user experience
- **Mitigation:** Check Quarto CLI presence before rendering (Task 6), provide clear error messages, validate template syntax early via manual rendering (Task 7)

**Risk: Suggestion rules too rigid, miss nuanced patterns**
- **Likelihood:** Low — SPEC.md:49-57 explicitly defines 5 rule-based patterns
- **Impact:** Low — Out of scope to handle all patterns (SPEC.md:28 excludes ML-based suggestions)
- **Mitigation:** Document rule thresholds in code comments (Task 3), explain why mid-range performers get no suggestions (expected behavior)

**Risk: Report charts break with edge case data (single rep, single period, all same scores)**
- **Likelihood:** Medium — ggplot2 can fail with degenerate data
- **Impact:** Medium — Report generation fails for valid input
- **Mitigation:** Add conditional rendering for trend charts (Task 5 uses `eval=(total_periods >= 2)`), test with single-period data (Task 4), handle empty suggestions gracefully (Task 5 shows "No recommendations" message)

**Risk: Phase 3 dependency issues resurface (plotly, ggplot2 misconfiguration)**
- **Likelihood:** Low — Already fixed in DESCRIPTION (Task 1 verification)
- **Impact:** High — Report rendering fails due to missing packages
- **Mitigation:** Verify DESCRIPTION.Imports includes knitr, rmarkdown immediately (Task 1), run `library()` checks before implementation

**Risk: Manual validation checklist incomplete, report ships with formatting issues**
- **Likelihood:** Medium — Automated tests can't validate UX quality
- **Impact:** High — Unprofessional report delivered to executives
- **Mitigation:** Comprehensive manual checklist in Task 7 (22 validation points), require browser review before marking phase complete

**Risk: Dashboard integration scope creep**
- **Likelihood:** Medium — Temptation to add suggestions to Shiny dashboard during Phase 4
- **Impact:** Medium — Delays primary deliverable (report), increases complexity
- **Mitigation:** Explicit "What We're NOT Doing" section (deferred unless report completes early), SPEC.md:73-74 and REFLECTIONS.md:319-322 prioritize report over dashboard enhancement
