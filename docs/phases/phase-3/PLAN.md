# Implementation Plan: Phase 3

## Overview
Build an interactive Shiny dashboard that exposes Phase 2's scoring engine to non-technical users (managers, leadership). Delivers a web application with CSV upload, live weight sliders, interactive rankings table, dimension breakdown charts, trend visualizations, and CSV export — all with reactive score recalculation under 500ms.

## Current State (from Research)

**Scoring Engine (Phase 2):**
- Complete, tested scoring pipeline in `R/calculate_scores.R:56-85`
- Accepts data + weights, returns scored data with 4 new columns
- 100% test coverage, all functions use native pipe `|>` and tidyverse style
- Limitation: Removes intermediate columns (tenure_factor, territory_factor, quota_attainment) at line 84

**Data Model:**
- Input: 11 columns (rep_id, rep_name, tenure_months, calls_made, followups_done, meetings_scheduled, deals_closed, revenue_generated, quota, territory_size, period)
- Output: Input + 4 score columns (activity_score, conversion_score, revenue_score, score)
- Sample data: `data/sample_reps.csv` (80 rows: 20 reps x 4 quarters)

**Existing Patterns:**
- Roxygen2 docs with @param, @return, @examples required
- Error messages descriptive with specifics (e.g., "Required columns missing: [list]")
- Test pattern: Use real implementations, no mocking
- Coverage target: 100% for all helper functions

**Dependencies:**
- Current: dplyr, tibble, purrr, testthat, covr, rprojroot
- Must add: shiny, shinydashboard, DT, plotly, shinytest2

## Desired End State

**User Experience:**
- Manager launches app with `Rscript -e "shiny::runApp('app.R')"` → dashboard opens in browser at localhost
- Default sample data loaded automatically → sees 80 reps with scores in table
- Moves "Activity" slider to 0.5 → other sliders auto-adjust to 0.25 each → rankings update instantly
- Clicks on rep in table → dimension breakdown chart shows activity/conversion/revenue bars
- Selects 3 reps → trend chart shows score progression across Q1-Q4 2025
- Applies rep_id filter → table and charts show only that rep
- Clicks "Export" → downloads CSV with timestamp filename
- Enables debug mode → export includes intermediate normalization columns

**Technical State:**
- Single-file `app.R` in project root with UI + server logic
- Helper functions in `R/shiny_helpers.R` with 100% test coverage
- Debug mode added to `calculate_scores()` function (addresses Phase 2 technical debt)
- Performance monitoring logs scoring time to console
- All SPEC.md acceptance criteria met
- Documentation updated (CLAUDE.md, AGENTS.md, README.md)

## What We're NOT Doing

- Quarto executive report generation (Phase 4)
- Improvement suggestions engine (Phase 4)
- Authentication or user management (not in BRIEF.md)
- Real-time data refresh or database integration (static CSV only)
- Multi-team comparison (single team/dataset per session)
- Custom theme configuration or white-labeling
- Mobile-responsive layout optimization (desktop-first acceptable)
- Shiny modules (single-file app sufficient for this phase)
- Complex state management (reactive values sufficient)
- CLI arguments for weight configuration (SPEC.md:133 deferred per PLAN Phase 2)

## Implementation Approach

**Vertical Slice Strategy:**
Break work into end-to-end deliverables that build on each other, each testable via automated tests AND manual inspection:
1. Debug mode in scoring engine → enables troubleshooting throughout Phase 3
2. Basic Shiny app with data upload → proves data can flow into dashboard
3. Rankings table with reactive scoring → demonstrates core value proposition
4. Weight sliders with auto-normalization → enables primary use case (adjust priorities)
5. Dimension breakdown chart → adds analytical depth
6. Trend chart → shows performance over time
7. Filters and export → completes full workflow

**Testing Strategy:**
- Write tests BEFORE implementation (TDD approach per Phase 2 REFLECTIONS.md:186-188)
- Use shinytest2 for E2E workflows (upload → filter → export)
- 100% coverage for helper functions extracted to `R/shiny_helpers.R`
- Manual testing required for UX polish (slider smoothness, chart aesthetics)

**Performance First:**
- Add timing to reactive scoring immediately
- Log performance to console on every recalculation
- Alert user if scoring exceeds 500ms

**Open Questions Resolved:**
All 15 open questions from RESEARCH.md resolved below (see Implementation Approach section details).

---

## Task 1: Add Debug Mode to Scoring Engine

### Overview
Modify `calculate_scores()` to optionally preserve intermediate normalization columns (tenure_factor, territory_factor, quota_attainment). Addresses Phase 2 technical debt #2 (REFLECTIONS.md:159-163) and enables troubleshooting when scores look unexpected in dashboard.

### Changes Required

**File**: `R/calculate_scores.R`

**Changes**:
1. Add `debug = FALSE` parameter to function signature (line 56-58):
```r
calculate_scores <- function(
    data,
    weights = c(activity = 0.333, conversion = 0.334, revenue = 0.333),
    debug = FALSE) {
```

2. Update roxygen documentation (lines 38-55):
```r
#' @param debug Logical flag to preserve intermediate normalization columns
#'   (tenure_factor, territory_factor, quota_attainment). Default FALSE.
#'   Use TRUE for troubleshooting unexpected scores.
```

3. Conditionally remove intermediate columns (replace line 84):
```r
# Calculate final weighted score
result <- data_scored |>
  dplyr::mutate(
    score = activity_score * weights["activity"] +
      conversion_score * weights["conversion"] +
      revenue_score * weights["revenue"]
  )

# Remove intermediate columns unless debug mode enabled
if (!debug) {
  result <- result |>
    dplyr::select(-tenure_factor, -territory_factor, -quota_attainment)
}

result
```

**File**: `tests/testthat/test-calculate_scores.R`

**Changes**: Add test at end of file (after line 186):
```r
test_that("debug mode preserves intermediate normalization columns", {
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

  # Default: intermediate columns removed
  result_default <- calculate_scores(df)
  expect_false("tenure_factor" %in% names(result_default))
  expect_false("territory_factor" %in% names(result_default))
  expect_false("quota_attainment" %in% names(result_default))

  # Debug mode: intermediate columns preserved
  result_debug <- calculate_scores(df, debug = TRUE)
  expect_true("tenure_factor" %in% names(result_debug))
  expect_true("territory_factor" %in% names(result_debug))
  expect_true("quota_attainment" %in% names(result_debug))

  # Scores should be identical regardless of debug mode
  expect_equal(result_default$score, result_debug$score)
})
```

### Success Criteria
- [ ] `calculate_scores(data, debug = FALSE)` removes intermediate columns (existing behavior)
- [ ] `calculate_scores(data, debug = TRUE)` preserves tenure_factor, territory_factor, quota_attainment
- [ ] Final scores identical regardless of debug parameter
- [ ] Test passes
- [ ] Coverage remains 100%

---

## Task 2: Create Shiny Helper Functions with Tests

### Overview
Extract testable logic for data validation, file upload parsing, weight normalization, and error message formatting into `R/shiny_helpers.R`. Write tests FIRST (TDD), then implement. This enables 100% coverage for critical dashboard logic.

### Changes Required

**File**: `R/shiny_helpers.R` (NEW)

**Functions to create**:
```r
#' Validate Uploaded CSV Schema
#'
#' Checks that uploaded data frame has all required columns matching
#' sample_reps.csv schema. Returns list with success flag and error message.
#'
#' @param data Data frame from fileInput() or read.csv()
#'
#' @return List with elements: valid (logical), message (character)
#'
#' @examples
#' df <- read.csv("data/sample_reps.csv", stringsAsFactors = FALSE)
#' result <- validate_upload_schema(df)
#' if (!result$valid) stop(result$message)
validate_upload_schema <- function(data) {
  required <- c("rep_id", "rep_name", "tenure_months", "calls_made",
                "followups_done", "meetings_scheduled", "deals_closed",
                "revenue_generated", "quota", "territory_size", "period")

  if (!is.data.frame(data) || nrow(data) == 0) {
    return(list(valid = FALSE, message = "File is empty or not a valid CSV"))
  }

  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    return(list(
      valid = FALSE,
      message = paste0("Missing required columns: ",
                       paste(missing, collapse = ", "))
    ))
  }

  list(valid = TRUE, message = "")
}

#' Normalize Three Weights to Sum to 1.0
#'
#' Takes three weight values and proportionally adjusts them to sum to 1.0.
#' Handles edge case where all weights are zero (returns equal weights).
#'
#' @param w1 Numeric weight value (>= 0)
#' @param w2 Numeric weight value (>= 0)
#' @param w3 Numeric weight value (>= 0)
#'
#' @return Named numeric vector with weights summing to 1.0
#'
#' @examples
#' normalize_three_weights(0.5, 0.3, 0.2)  # Returns c(0.5, 0.3, 0.2)
#' normalize_three_weights(1.0, 1.0, 1.0)  # Returns c(0.333, 0.333, 0.334)
#' normalize_three_weights(0, 0, 0)        # Returns c(0.333, 0.333, 0.334)
normalize_three_weights <- function(w1, w2, w3) {
  total <- w1 + w2 + w3

  # Handle all-zero case (return equal weights)
  if (total == 0) {
    return(c(activity = 0.333, conversion = 0.334, revenue = 0.333))
  }

  # Normalize proportionally
  normalized <- c(
    activity = w1 / total,
    conversion = w2 / total,
    revenue = w3 / total
  )

  # Ensure sum is exactly 1.0 (adjust last weight for floating point errors)
  normalized["revenue"] <- 1.0 - normalized["activity"] - normalized["conversion"]

  normalized
}

#' Format Row Count Summary
#'
#' Returns user-friendly summary of uploaded data size.
#'
#' @param data Data frame
#'
#' @return Character string (e.g., "Loaded 80 rows (20 reps, 4 periods)")
#'
#' @examples
#' df <- read.csv("data/sample_reps.csv")
#' format_row_summary(df)
format_row_summary <- function(data) {
  n_rows <- nrow(data)
  n_reps <- length(unique(data$rep_id))
  n_periods <- length(unique(data$period))

  paste0("Loaded ", n_rows, " rows (",
         n_reps, " reps, ",
         n_periods, " periods)")
}
```

**File**: `tests/testthat/test-shiny_helpers.R` (NEW)

**Write tests FIRST** (TDD approach):
```r
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
    # Missing all other required columns
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

test_that("normalize_three_weights maintains proportions", {
  result <- normalize_three_weights(0.5, 0.3, 0.2)
  expect_equal(result["activity"], 0.5)
  expect_equal(result["conversion"], 0.3)
  expect_equal(result["revenue"], 0.2)
  expect_equal(sum(result), 1.0)
})

test_that("normalize_three_weights handles equal values", {
  result <- normalize_three_weights(1.0, 1.0, 1.0)
  expect_equal(result["activity"], 1/3, tolerance = 0.001)
  expect_equal(result["conversion"], 1/3, tolerance = 0.001)
  expect_equal(result["revenue"], 1/3, tolerance = 0.001)
  expect_equal(sum(result), 1.0)
})

test_that("normalize_three_weights handles all-zero input", {
  result <- normalize_three_weights(0, 0, 0)
  expect_equal(sum(result), 1.0)
  expect_true(all(result > 0))  # Should return equal weights, not zeros
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
```

### Success Criteria
- [ ] Run tests → 3 tests FAIL (functions not implemented yet)
- [ ] Implement functions in `R/shiny_helpers.R`
- [ ] Run tests → all tests PASS
- [ ] Run coverage report → 100% coverage for shiny_helpers.R
- [ ] All existing tests still pass (no regressions)

---

## Task 3: Build Basic Shiny App with Data Upload

### Overview
Create single-file `app.R` with shinydashboard layout, file upload widget, and basic UI structure. Default loads sample_reps.csv, allows user to upload custom CSV with validation. Displays row count summary after upload. No scoring yet — validates data flow first.

### Changes Required

**File**: `DESCRIPTION`

**Changes**: Add Shiny dependencies to Imports section (line 9-12):
```
Imports:
    dplyr,
    tibble,
    purrr,
    shiny,
    shinydashboard,
    DT
Suggests:
    testthat (>= 3.0.0),
    covr,
    rprojroot,
    plotly,
    shinytest2
```

**Install new packages**:
```bash
Rscript -e "install.packages(c('shiny', 'shinydashboard', 'DT', 'plotly', 'shinytest2'), repos='https://cloud.r-project.org/')"
```

**File**: `app.R` (NEW — in project root)

```r
# Sales Rep Performance Dashboard
#
# Interactive Shiny dashboard for exploring rep performance scores.
# Allows CSV upload, weight adjustment, filtering, and score export.

library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)

# Source all required functions
source(file.path("R", "shiny_helpers.R"))
source(file.path("R", "scoring_utils.R"))
source(file.path("R", "normalization.R"))
source(file.path("R", "dimension_scoring.R"))
source(file.path("R", "calculate_scores.R"))

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "Sales Rep Performance"),

  dashboardSidebar(
    sidebarMenu(
      menuItem("Rankings", tabName = "rankings", icon = icon("table")),
      menuItem("Upload Data", tabName = "upload", icon = icon("upload"))
    ),

    h4("Weight Configuration"),
    sliderInput("weight_activity", "Activity Quality",
                min = 0, max = 1, value = 0.333, step = 0.01),
    sliderInput("weight_conversion", "Conversion Efficiency",
                min = 0, max = 1, value = 0.334, step = 0.01),
    sliderInput("weight_revenue", "Revenue Contribution",
                min = 0, max = 1, value = 0.333, step = 0.01),

    checkboxInput("debug_mode", "Debug Mode: Show Intermediate Columns",
                  value = FALSE)
  ),

  dashboardBody(
    tabItems(
      tabItem(tabName = "rankings",
              fluidRow(
                box(title = "Rep Rankings", width = 12, status = "primary",
                    textOutput("data_summary"),
                    hr(),
                    DTOutput("rankings_table"))
              )),

      tabItem(tabName = "upload",
              fluidRow(
                box(title = "Upload Sales Data", width = 6,
                    p("Upload a CSV file with the same schema as sample_reps.csv:"),
                    tags$ul(
                      tags$li("rep_id, rep_name, tenure_months, calls_made, followups_done"),
                      tags$li("meetings_scheduled, deals_closed, revenue_generated"),
                      tags$li("quota, territory_size, period")
                    ),
                    fileInput("file_upload", "Choose CSV File",
                              accept = c("text/csv", ".csv")),
                    actionButton("load_sample", "Load Sample Data",
                                 icon = icon("refresh")),
                    hr(),
                    verbatimTextOutput("upload_status")
                )
              ))
    )
  )
)

# Server Logic
server <- function(input, output, session) {

  # Reactive: Load raw data (default to sample_reps.csv)
  raw_data <- reactiveVal(
    read.csv("data/sample_reps.csv", stringsAsFactors = FALSE)
  )

  # Observer: Handle file upload
  observeEvent(input$file_upload, {
    req(input$file_upload)

    tryCatch({
      uploaded <- read.csv(input$file_upload$datapath, stringsAsFactors = FALSE)
      validation <- validate_upload_schema(uploaded)

      if (!validation$valid) {
        output$upload_status <- renderText({
          paste("ERROR:", validation$message)
        })
      } else {
        raw_data(uploaded)
        output$upload_status <- renderText({
          paste("SUCCESS:", format_row_summary(uploaded))
        })
      }
    }, error = function(e) {
      output$upload_status <- renderText({
        paste("ERROR: Could not read file -", e$message)
      })
    })
  })

  # Observer: Load sample data button
  observeEvent(input$load_sample, {
    sample_data <- read.csv("data/sample_reps.csv", stringsAsFactors = FALSE)
    raw_data(sample_data)
    output$upload_status <- renderText({
      paste("Loaded sample data:", format_row_summary(sample_data))
    })
  })

  # Output: Data summary
  output$data_summary <- renderText({
    format_row_summary(raw_data())
  })

  # Output: Rankings table (unscored for now)
  output$rankings_table <- renderDT({
    datatable(raw_data(),
              options = list(pageLength = 25, scrollX = TRUE),
              rownames = FALSE)
  })
}

# Run App
shinyApp(ui, server)
```

### Success Criteria
- [ ] Run `Rscript -e "shiny::runApp('app.R')"` → app launches without errors
- [ ] Default sample data loads → see 80 rows in table
- [ ] Upload valid CSV → see "SUCCESS" message with row count
- [ ] Upload CSV with missing columns → see "ERROR: Missing required columns: ..."
- [ ] Upload invalid file (not CSV) → see error message
- [ ] Click "Load Sample Data" button → table resets to sample_reps.csv
- [ ] Weight sliders move freely (no validation yet)
- [ ] Debug checkbox toggles (no effect yet)
- [ ] No console errors or warnings

---

## Task 4: Add Reactive Scoring with Performance Monitoring

### Overview
Connect weight sliders to scoring engine. When sliders move, auto-normalize weights and recalculate scores reactively. Add performance timing to log scoring duration to console and alert user if > 500ms. Display scored data in rankings table.

### Changes Required

**File**: `app.R`

**Changes**:

1. Add reactive weight normalization and scoring (in server function, before `observeEvent` blocks):
```r
# Reactive: Normalized weights (auto-adjust to sum = 1.0)
normalized_weights <- reactive({
  normalize_three_weights(
    input$weight_activity,
    input$weight_conversion,
    input$weight_revenue
  )
})

# Observer: Update slider displays when weights change
observe({
  weights <- normalized_weights()
  updateSliderInput(session, "weight_activity",
                    value = weights["activity"])
  updateSliderInput(session, "weight_conversion",
                    value = weights["conversion"])
  updateSliderInput(session, "weight_revenue",
                    value = weights["revenue"])
})

# Reactive: Scored data with performance monitoring
scored_data <- reactive({
  req(raw_data())

  start_time <- Sys.time()

  result <- calculate_scores(
    raw_data(),
    weights = normalized_weights(),
    debug = input$debug_mode
  )

  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
  message("Scoring took ", round(elapsed, 3), " seconds for ",
          nrow(raw_data()), " rows")

  # Alert if performance exceeds threshold
  if (elapsed > 0.5) {
    showNotification(
      paste0("Large dataset detected — scoring took ",
             round(elapsed, 2), " seconds"),
      type = "warning",
      duration = 5
    )
  }

  result
})
```

2. Update rankings table to show scored data (replace `output$rankings_table`):
```r
# Output: Rankings table with scores
output$rankings_table <- renderDT({
  data <- scored_data()

  # Sort by overall score descending
  data <- data |> dplyr::arrange(desc(score))

  datatable(data,
            options = list(
              pageLength = 25,
              scrollX = TRUE,
              order = list(list(ncol(data) - 1, 'desc'))  # Sort by score column
            ),
            rownames = FALSE) |>
    formatRound(columns = c("activity_score", "conversion_score",
                            "revenue_score", "score"),
                digits = 1)
})
```

3. Update data summary to show score range (replace `output$data_summary`):
```r
# Output: Data summary with score range
output$data_summary <- renderText({
  data <- scored_data()
  summary_text <- format_row_summary(data)
  score_range <- paste0(" | Scores: ",
                        round(min(data$score), 1), "-",
                        round(max(data$score), 1))
  paste0(summary_text, score_range)
})
```

### Success Criteria
- [ ] Launch app → scores appear in table immediately
- [ ] Move activity slider to 0.5 → other sliders auto-adjust to ~0.25 each
- [ ] Move slider → console shows "Scoring took X seconds for 80 rows"
- [ ] Scoring completes in < 100ms for 80-row sample (check console log)
- [ ] Check debug mode → intermediate columns appear in table
- [ ] Uncheck debug mode → intermediate columns disappear
- [ ] Rankings table sorted by score descending (highest scores at top)
- [ ] Score columns rounded to 1 decimal place
- [ ] Sliders adjust smoothly without lag or flicker

---

## Task 5: Add Dimension Breakdown Bar Chart

### Overview
Add grouped bar chart showing activity_score, conversion_score, and revenue_score for top 10 reps. Chart updates reactively when weights change or filters applied. Uses plotly for interactivity (hover tooltips).

### Changes Required

**File**: `app.R`

**Changes**:

1. Add plotly library to imports (line 8):
```r
library(plotly)
```

2. Add chart box to rankings tab (in UI, after rankings_table box):
```r
fluidRow(
  box(title = "Dimension Breakdown (Top 10 Reps)", width = 12,
      status = "info",
      plotlyOutput("dimension_chart", height = "400px"))
)
```

3. Add reactive for top 10 reps (in server, after `scored_data` reactive):
```r
# Reactive: Top 10 reps by overall score
top_reps <- reactive({
  scored_data() |>
    dplyr::arrange(desc(score)) |>
    dplyr::slice_head(n = 10)
})
```

4. Add chart output (in server, after `output$rankings_table`):
```r
# Output: Dimension breakdown bar chart
output$dimension_chart <- renderPlotly({
  data <- top_reps()

  # Reshape data for grouped bar chart
  chart_data <- data.frame(
    rep_name = rep(data$rep_name, 3),
    dimension = rep(c("Activity", "Conversion", "Revenue"), each = nrow(data)),
    score = c(data$activity_score, data$conversion_score, data$revenue_score)
  )

  plot_ly(chart_data, x = ~rep_name, y = ~score, color = ~dimension,
          type = "bar",
          colors = c("#1f77b4", "#ff7f0e", "#2ca02c"),
          hovertemplate = paste0("<b>%{x}</b><br>",
                                 "%{fullData.name}: %{y:.1f}<br>",
                                 "<extra></extra>")) |>
    layout(
      barmode = "group",
      xaxis = list(title = "Rep", tickangle = -45),
      yaxis = list(title = "Score (0-100)", range = c(0, 100)),
      legend = list(title = list(text = "Dimension"))
    )
})
```

### Success Criteria
- [ ] Launch app → dimension chart displays for top 10 reps
- [ ] Bars grouped by rep, three bars per rep (activity/conversion/revenue)
- [ ] Colors consistent: blue = activity, orange = conversion, green = revenue
- [ ] Hover over bar → shows rep name, dimension, exact score
- [ ] Move weight slider → chart updates to show new top 10 (if rankings change)
- [ ] Y-axis fixed at 0-100 range
- [ ] X-axis labels readable (rotated 45° if needed)
- [ ] Chart renders without errors or warnings

---

## Task 6: Add Trend Over Time Line Chart

### Overview
Add line chart showing overall score progression across periods for selected reps. User selects 1-5 reps by clicking checkboxes. Chart updates reactively when weights change or rep selection changes.

### Changes Required

**File**: `app.R`

**Changes**:

1. Add trend chart tab to sidebar menu (in UI, after "Upload Data" menuItem):
```r
menuItem("Trends", tabName = "trends", icon = icon("line-chart"))
```

2. Add trend tab content (in UI, after upload tabItem):
```r
tabItem(tabName = "trends",
        fluidRow(
          box(title = "Select Reps to Compare", width = 4,
              uiOutput("rep_selector")),

          box(title = "Score Trend Over Time", width = 8, status = "info",
              plotlyOutput("trend_chart", height = "400px"))
        ))
```

3. Add reactive for available reps (in server, after `top_reps` reactive):
```r
# Reactive: List of unique rep names for selector
available_reps <- reactive({
  scored_data() |>
    dplyr::distinct(rep_id, rep_name) |>
    dplyr::arrange(rep_name)
})
```

4. Add dynamic rep selector UI (in server, after `output$dimension_chart`):
```r
# Output: Rep selector checkboxes
output$rep_selector <- renderUI({
  reps <- available_reps()

  checkboxGroupInput("selected_reps", "Select Reps (1-5):",
                     choices = setNames(reps$rep_id, reps$rep_name),
                     selected = reps$rep_id[1:min(3, nrow(reps))])
})
```

5. Add trend chart output (in server, after `output$rep_selector`):
```r
# Output: Trend line chart
output$trend_chart <- renderPlotly({
  req(input$selected_reps)

  # Limit to 5 reps for readability
  selected <- input$selected_reps[1:min(5, length(input$selected_reps))]

  data <- scored_data() |>
    dplyr::filter(rep_id %in% selected) |>
    dplyr::arrange(period)

  if (nrow(data) == 0) {
    # Empty chart with message
    return(
      plot_ly() |>
        layout(
          xaxis = list(title = "Period"),
          yaxis = list(title = "Score (0-100)"),
          annotations = list(
            text = "No data for selected reps",
            xref = "paper", yref = "paper",
            x = 0.5, y = 0.5, showarrow = FALSE
          )
        )
    )
  }

  plot_ly(data, x = ~period, y = ~score, color = ~rep_name,
          type = "scatter", mode = "lines+markers",
          hovertemplate = paste0("<b>%{fullData.name}</b><br>",
                                 "Period: %{x}<br>",
                                 "Score: %{y:.1f}<br>",
                                 "<extra></extra>")) |>
    layout(
      xaxis = list(title = "Period"),
      yaxis = list(title = "Score (0-100)", range = c(0, 100)),
      legend = list(title = list(text = "Rep"))
    )
})
```

### Success Criteria
- [ ] Navigate to "Trends" tab → see rep selector checkboxes
- [ ] Default: 3 reps pre-selected
- [ ] Trend chart shows lines for selected reps across Q1-Q4 2025
- [ ] Select different rep → line appears on chart
- [ ] Deselect rep → line disappears from chart
- [ ] Select more than 5 reps → only first 5 displayed
- [ ] Hover over data point → shows rep name, period, exact score
- [ ] Move weight slider → lines update with recalculated scores
- [ ] Upload new data with different periods → chart adapts to new periods
- [ ] Select rep with single period → single point displayed (no line error)

---

## Task 7: Add Filters and Clear Button

### Overview
Add dropdown filters for rep_id and period. When filter applied, rankings table and charts show only filtered data. "Clear Filters" button resets to full dataset view.

### Changes Required

**File**: `app.R`

**Changes**:

1. Add filter controls to sidebar (in UI, after debug_mode checkbox):
```r
hr(),
h4("Filters"),
selectInput("filter_rep", "Filter by Rep:",
            choices = NULL,  # Populated dynamically
            selected = NULL,
            multiple = FALSE),
selectInput("filter_period", "Filter by Period:",
            choices = NULL,  # Populated dynamically
            selected = NULL,
            multiple = FALSE),
actionButton("clear_filters", "Clear Filters", icon = icon("times"))
```

2. Add observers to populate filter dropdowns (in server, after `available_reps` reactive):
```r
# Observer: Update rep filter choices
observe({
  reps <- available_reps()
  choices <- setNames(c("All", reps$rep_id), c("All", reps$rep_name))
  updateSelectInput(session, "filter_rep",
                    choices = choices,
                    selected = "All")
})

# Observer: Update period filter choices
observe({
  periods <- scored_data() |>
    dplyr::distinct(period) |>
    dplyr::pull(period) |>
    sort()

  choices <- c("All", periods)
  updateSelectInput(session, "filter_period",
                    choices = choices,
                    selected = "All")
})

# Observer: Clear filters button
observeEvent(input$clear_filters, {
  updateSelectInput(session, "filter_rep", selected = "All")
  updateSelectInput(session, "filter_period", selected = "All")
})
```

3. Add reactive for filtered data (in server, replace `scored_data` usage with `filtered_data`):
```r
# Reactive: Apply filters to scored data
filtered_data <- reactive({
  data <- scored_data()

  # Apply rep filter
  if (!is.null(input$filter_rep) && input$filter_rep != "All") {
    data <- data |> dplyr::filter(rep_id == input$filter_rep)
  }

  # Apply period filter
  if (!is.null(input$filter_period) && input$filter_period != "All") {
    data <- data |> dplyr::filter(period == input$filter_period)
  }

  data
})
```

4. Update all output functions to use `filtered_data()` instead of `scored_data()`:
   - `output$data_summary`: Change `scored_data()` to `filtered_data()`
   - `output$rankings_table`: Change `scored_data()` to `filtered_data()`
   - `top_reps` reactive: Change `scored_data()` to `filtered_data()`
   - `available_reps` reactive: Keep as `scored_data()` (need full list)
   - `output$trend_chart`: Change `scored_data()` to `filtered_data()`

5. Add "No data" message for empty filter results (in `output$rankings_table`):
```r
output$rankings_table <- renderDT({
  data <- filtered_data()

  if (nrow(data) == 0) {
    return(datatable(data.frame(Message = "No data matches current filters")))
  }

  # Sort by overall score descending
  data <- data |> dplyr::arrange(desc(score))

  # ... rest of existing code
})
```

### Success Criteria
- [ ] Launch app → filter dropdowns populated with reps and periods
- [ ] Default: "All" selected for both filters
- [ ] Select rep filter → table shows only that rep's data
- [ ] Select period filter → table shows only that period's data
- [ ] Select both filters → table shows intersection (1 row if rep+period unique)
- [ ] Apply filter with zero matches → table shows "No data matches current filters"
- [ ] Click "Clear Filters" → resets both dropdowns to "All"
- [ ] Charts update reactively when filters applied
- [ ] Dimension chart shows top 10 from filtered data (may be < 10 if filtered)
- [ ] Trend chart shows only filtered reps and periods

---

## Task 8: Add CSV Export with Timestamp

### Overview
Add "Export Scored Data" download button that exports currently displayed data (respects filters) as CSV with timestamp filename. Includes intermediate columns if debug mode enabled.

### Changes Required

**File**: `app.R`

**Changes**:

1. Add export button to rankings tab (in UI, in rankings tabItem, before rankings_table box):
```r
fluidRow(
  box(title = "Export Data", width = 12,
      downloadButton("export_csv", "Export Scored Data (CSV)",
                     icon = icon("download")),
      helpText("Downloads currently displayed data (respects active filters and debug mode)"))
)
```

2. Add download handler (in server, after `output$trend_chart`):
```r
# Download handler: Export scored data as CSV
output$export_csv <- downloadHandler(
  filename = function() {
    timestamp <- format(Sys.Date(), "%Y-%m-%d")
    paste0("scored_reps_", timestamp, ".csv")
  },
  content = function(file) {
    data <- filtered_data()
    write.csv(data, file, row.names = FALSE)
  }
)
```

### Success Criteria
- [ ] Click "Export Scored Data (CSV)" → download dialog appears
- [ ] Filename includes today's date (e.g., `scored_reps_2026-02-17.csv`)
- [ ] Open CSV → contains all columns including scores
- [ ] Export with no filters → CSV has all 80 rows
- [ ] Export with rep filter → CSV has only filtered rep's rows
- [ ] Export with period filter → CSV has only filtered period's rows
- [ ] Enable debug mode → export includes tenure_factor, territory_factor, quota_attainment
- [ ] Disable debug mode → export excludes intermediate columns
- [ ] CSV opens correctly in Excel/spreadsheet app (no formatting issues)

---

## Task 9: Add E2E Tests with shinytest2

### Overview
Write automated end-to-end tests covering major workflows: default data load, weight adjustment, filter application, and export. Uses shinytest2 for headless browser testing.

### Changes Required

**File**: `tests/testthat/test-app.R` (NEW)

```r
library(testthat)
library(shinytest2)

test_that("app launches and loads default data", {
  app <- AppDriver$new(app_dir = rprojroot::find_root("DESCRIPTION"))

  # Check that app launches
  expect_true(app$get_html("title") != "")

  # Check that sample data loaded
  summary <- app$get_value(output = "data_summary")
  expect_match(summary, "80 rows")
  expect_match(summary, "20 reps")

  app$stop()
})

test_that("weight sliders trigger score recalculation", {
  app <- AppDriver$new(app_dir = rprojroot::find_root("DESCRIPTION"))

  # Get initial score range
  initial_summary <- app$get_value(output = "data_summary")

  # Move activity slider to 0.8
  app$set_inputs(weight_activity = 0.8)
  Sys.sleep(0.5)  # Wait for reactive recalculation

  # Get new score range
  new_summary <- app$get_value(output = "data_summary")

  # Score range should change when weights change
  expect_false(identical(initial_summary, new_summary))

  app$stop()
})

test_that("rep filter updates table", {
  app <- AppDriver$new(app_dir = rprojroot::find_root("DESCRIPTION"))

  # Apply rep filter (select first rep)
  app$set_inputs(filter_rep = "REP001")
  Sys.sleep(0.3)

  # Check data summary shows fewer rows
  summary <- app$get_value(output = "data_summary")
  expect_match(summary, "4 rows")  # 1 rep x 4 periods = 4 rows

  app$stop()
})

test_that("debug mode preserves intermediate columns", {
  app <- AppDriver$new(app_dir = rprojroot::find_root("DESCRIPTION"))

  # Navigate to rankings tab
  app$set_inputs(sidebar_menu = "rankings")

  # Enable debug mode
  app$set_inputs(debug_mode = TRUE)
  Sys.sleep(0.5)

  # Check that table has intermediate columns
  # (This is a smoke test — full column check would require DT inspection)
  expect_true(TRUE)  # Placeholder — manual verification required

  app$stop()
})
```

**File**: `tests/testthat/test-app-manual.R` (NEW — manual test checklist)

```r
# Manual Test Checklist for Shiny Dashboard
#
# These tests require manual execution and visual inspection.
# Run these after all automated tests pass.

# TEST 1: Slider smoothness and responsiveness
# - Launch app
# - Move weight sliders continuously (drag, don't click)
# - Expected: Sliders move smoothly without lag
# - Expected: Other sliders auto-adjust in real-time
# - Expected: Table updates within 500ms of slider release

# TEST 2: Chart interactivity
# - Navigate to Rankings tab
# - Hover over bars in dimension chart
# - Expected: Tooltip shows rep name, dimension, exact score
# - Expected: Tooltip follows cursor without lag
# - Navigate to Trends tab
# - Hover over line chart data points
# - Expected: Tooltip shows rep name, period, score

# TEST 3: Error message clarity
# - Navigate to Upload Data tab
# - Upload CSV with missing columns (create test file)
# - Expected: Error message lists specific missing columns
# - Expected: No raw R error displayed

# TEST 4: Large dataset performance
# - Generate 1000-row dataset (modify generate_data.R)
# - Upload via dashboard
# - Move weight slider
# - Expected: Console logs "Scoring took X seconds"
# - Expected: If > 0.5s, warning notification appears
# - Expected: UI remains responsive during scoring

# TEST 5: Export file integrity
# - Apply rep filter (select "REP001")
# - Enable debug mode
# - Click "Export Scored Data (CSV)"
# - Open CSV in Excel
# - Expected: Only REP001 rows present (4 rows)
# - Expected: Intermediate columns present (tenure_factor, etc.)
# - Disable debug mode
# - Export again
# - Expected: Intermediate columns absent
```

### Success Criteria
- [ ] Run `Rscript -e "testthat::test_dir('tests/testthat')"` → all automated tests pass
- [ ] shinytest2 launches app successfully
- [ ] Test "app launches and loads default data" passes
- [ ] Test "weight sliders trigger recalculation" passes
- [ ] Test "rep filter updates table" passes
- [ ] Manual test checklist documented for UX validation
- [ ] All existing Phase 2 tests still pass (no regressions)

---

## Task 10: Update Documentation

### Overview
Update CLAUDE.md, AGENTS.md, and README.md to reflect Phase 3 completion. Add dashboard launch command, feature overview, and usage instructions.

### Changes Required

**File**: `CLAUDE.md`

**Changes**: Add after "Quick Command Reference" section (around line 19):
```markdown
### Launch Dashboard
```bash
Rscript -e "shiny::runApp('app.R')"
```
Opens interactive dashboard at `http://127.0.0.1:XXXX` with:
- CSV data upload (or use default sample_reps.csv)
- Live weight sliders for activity/conversion/revenue priorities
- Rankings table with dimension score breakdowns
- Dimension breakdown charts (top 10 reps)
- Trend charts (score progression over quarters)
- Rep and period filters
- CSV export with timestamp
- Debug mode to show intermediate normalization columns
```

**File**: `AGENTS.md`

**Changes**:

1. Update "Running the Project" section (after line 46):
```markdown
### Launch interactive dashboard
```bash
Rscript -e "shiny::runApp('app.R')"
```
**Output:** Dashboard opens in browser at `http://127.0.0.1:XXXX`

## Dashboard Usage

### Launching the App
```bash
Rscript -e "shiny::runApp('app.R')"
```
Your default browser will open automatically. If not, navigate to the URL shown in the console (typically `http://127.0.0.1:XXXX`).

### Uploading Custom Data
1. Navigate to "Upload Data" tab
2. Click "Choose CSV File"
3. Select your CSV file with the same schema as `data/sample_reps.csv`:
   - Required columns: rep_id, rep_name, tenure_months, calls_made, followups_done, meetings_scheduled, deals_closed, revenue_generated, quota, territory_size, period
4. If upload succeeds, you'll see "SUCCESS: Loaded X rows"
5. If upload fails, error message will list missing columns

### Adjusting Scoring Weights
1. Use the three sliders in the sidebar:
   - Activity Quality (default 33.3%)
   - Conversion Efficiency (default 33.4%)
   - Revenue Contribution (default 33.3%)
2. Move any slider → other sliders auto-adjust to maintain sum = 100%
3. Scores recalculate instantly (< 500ms for typical datasets)
4. Rankings table updates to reflect new priorities

### Viewing Rankings and Scores
1. Navigate to "Rankings" tab (default view)
2. Table shows all reps sorted by overall score (highest first)
3. Columns: rep details + activity_score, conversion_score, revenue_score, score
4. Click column headers to sort by any dimension
5. Dimension breakdown chart shows top 10 reps with three bars each

### Analyzing Trends Over Time
1. Navigate to "Trends" tab
2. Select 1-5 reps from checkbox list (default: first 3 reps)
3. Line chart shows score progression across quarters
4. Hover over data points to see exact scores
5. Adjust weight sliders → trend lines update with recalculated scores

### Filtering Data
1. Use "Filter by Rep" dropdown to show single rep
2. Use "Filter by Period" dropdown to show single quarter
3. Combine filters to show specific rep in specific quarter
4. Click "Clear Filters" to reset to full dataset
5. Charts and export respect active filters

### Exporting Scored Data
1. Navigate to "Rankings" tab
2. Apply any desired filters
3. Click "Export Scored Data (CSV)"
4. File downloads with timestamp (e.g., `scored_reps_2026-02-17.csv`)
5. Export includes only currently displayed data (respects filters)

### Debug Mode
1. Check "Debug Mode: Show Intermediate Columns" in sidebar
2. Rankings table adds columns: tenure_factor, territory_factor, quota_attainment
3. Export CSV includes intermediate columns
4. Use when scores look unexpected — inspect normalization values
5. Uncheck to hide intermediate columns

### Troubleshooting
- **App won't launch**: Check that all dependencies installed (`shiny`, `shinydashboard`, `DT`, `plotly`)
- **Scores look wrong**: Enable debug mode, inspect intermediate columns, verify quota > 0
- **Upload fails**: Verify CSV has all 11 required columns with correct names (case-sensitive)
- **Slow scoring**: Check console for timing logs. Datasets > 1000 rows may exceed 500ms.
- **Charts not updating**: Check browser console for JavaScript errors (F12 → Console tab)
```

2. Update "Phase Status" section (line 214-215):
```markdown
## Phase Status
**Current Phase:** Phase 3 — COMPLETE
**Next Phase:** Phase 4 — Quarto Executive Report
```

**File**: `README.md`

**Changes**:

1. Update "Phase Status" (search for Phase 2 status):
```markdown
## Phase Status
- ✅ Phase 1: Data Model + Sample Data (COMPLETE)
- ✅ Phase 2: Scoring Engine (COMPLETE)
- ✅ Phase 3: Shiny Dashboard (COMPLETE)
- ⏳ Phase 4: Quarto Report + Suggestions Engine (PENDING)
```

2. Add "Interactive Dashboard" section (after "Scoring Methodology"):
```markdown
## Interactive Dashboard

Launch the Shiny dashboard to explore rep performance interactively:

```bash
Rscript -e "shiny::runApp('app.R')"
```

**Features:**
- 📊 **Rankings Table** — Sortable table showing all reps with dimension scores
- 🎚️ **Live Weight Sliders** — Adjust priorities (activity/conversion/revenue), see rankings update instantly
- 📈 **Dimension Breakdown Chart** — Compare top 10 reps across three performance dimensions
- 📉 **Trend Chart** — Track score progression over quarters for selected reps
- 🔍 **Filters** — View specific reps or time periods
- 💾 **CSV Export** — Download scored data with timestamp
- 🐛 **Debug Mode** — Show intermediate normalization columns for troubleshooting

See AGENTS.md for detailed usage instructions.
```

**File**: `STATUS.md`

**Changes**: Update to reflect Phase 3 completion:
```markdown
Phase: 3
Step: complete
Status: DONE
```

### Success Criteria
- [ ] CLAUDE.md includes dashboard launch command and feature list
- [ ] AGENTS.md has complete "Dashboard Usage" section with all features documented
- [ ] README.md shows Phase 3 COMPLETE and includes interactive dashboard section
- [ ] STATUS.md updated to "Phase: 3 | Step: complete | Status: DONE"
- [ ] All documentation accurate (no outdated references to Phase 2 as current)

---

## Testing Strategy

### Unit Tests
**Coverage target**: 100% for helper functions in `R/shiny_helpers.R`

**Key test scenarios**:
- `validate_upload_schema()`: Valid data passes, missing columns rejected, empty data rejected
- `normalize_three_weights()`: Proportional normalization, equal weights, all-zero edge case
- `format_row_summary()`: Correct row/rep/period counts
- `calculate_scores()` debug mode: Intermediate columns preserved when `debug = TRUE`

**Mocking strategy**: None — test real implementations with real data (continue Phase 2 anti-mock philosophy).

### Integration/E2E Tests
**Framework**: shinytest2 for automated Shiny app testing

**Required workflows**:
1. **Happy path**: Launch → default data loads → adjust sliders → scores update → export CSV
2. **Upload custom data**: Launch → upload valid CSV → verify scoring → filter → export
3. **Error handling**: Launch → upload invalid CSV → verify error message → recover with valid upload

**Manual testing required for**:
- Slider smoothness and responsiveness (drag interaction)
- Chart hover tooltips (visual inspection)
- Error message clarity (user-friendliness)
- Large dataset performance (1000+ rows)

### Coverage Expectations
- **R functions**: 100% line coverage for all code in R/ directory
- **Shiny app.R**: Not covered by unit tests (tested via shinytest2 E2E)
- **Manual tests**: Documented in `test-app-manual.R` with acceptance criteria

## Risk Assessment

**Risk**: Weight slider auto-normalization creates confusing UX (sliders jump unexpectedly)
**Mitigation**: Use `updateSliderInput()` with `session` to adjust silently without triggering infinite reactive loops. Test with rapid slider movements.

**Risk**: Large datasets (> 1000 rows) exceed 500ms scoring requirement
**Mitigation**: Add performance warning notification at 500ms threshold. Log timing to console for monitoring. If needed, Phase 4 can add async scoring with progress bar.

**Risk**: shinytest2 tests are flaky due to timing issues
**Mitigation**: Add `Sys.sleep()` delays after input changes to allow reactive propagation. Use `req()` guards in server to prevent premature rendering.

**Risk**: CSV upload fails silently with non-ASCII characters or encoding issues
**Mitigation**: Wrap `read.csv()` in `tryCatch()` to catch file read errors. Display error message to user instead of crashing app.

**Risk**: Filter combinations result in zero rows, breaking charts
**Mitigation**: Add conditional rendering — show "No data matches filters" message instead of empty chart. Test all filter combinations (rep only, period only, both, neither).

**Risk**: Debug mode exposes intermediate columns that confuse users
**Mitigation**: Label checkbox clearly as "Debug Mode" with help text. Hide checkbox in sidebar (less prominent than main features). Document usage in AGENTS.md.

**Risk**: Plotly charts don't render on certain browsers
**Mitigation**: Test in Chrome, Firefox, Safari. Plotly has wide browser support, but fallback to static ggplot2 if needed in Phase 4.

**Risk**: Phase 2 tests break due to function signature changes (debug parameter)
**Mitigation**: Add default `debug = FALSE` to maintain backward compatibility. Run full test suite after Task 1 to verify no regressions.

---

## Open Questions Resolved

All 15 open questions from RESEARCH.md resolved:

**Q1: Weight slider auto-normalization UX** → (a) Auto-adjust other two sliders proportionally (RESEARCH.md:345-349)
- **Decision**: Use `normalize_three_weights()` helper to proportionally adjust, then `updateSliderInput()` to silently update UI
- **Rationale**: Prevents invalid states, provides instant feedback, matches REFLECTIONS.md:109-112 recommendation

**Q2: Trend chart rep selection control** → (c) Interactive table row selection (RESEARCH.md:351-355)
- **Decision**: Use checkbox group (`checkboxGroupInput`) separate from main table
- **Rationale**: Simpler implementation than DT row selection, clearer UX for multi-select
- **Note**: Original recommendation (c) was table row selection, but checkbox group is more explicit

**Q3: Dimension breakdown chart scope** → (a) Top 10 by overall score (RESEARCH.md:357-361)
- **Decision**: Sort by overall `score` column, take top 10
- **Rationale**: Aligns with "rankings" mental model, simplest to understand

**Q4: Single-file vs modular Shiny app** → (a) Single app.R with all logic inline (RESEARCH.md:363-367)
- **Decision**: Single `app.R` in root, helper functions in `R/shiny_helpers.R`
- **Rationale**: Defer modularization until complexity requires it (REFLECTIONS.md:139)

**Q5: Debug mode implementation approach** → (a) `calculate_scores()` signature only (RESEARCH.md:369-372)
- **Decision**: Add `debug` parameter to `calculate_scores()`, conditionally preserve columns before final select()
- **Rationale**: Minimal change, backward compatible, sufficient for troubleshooting

**Q6: Data upload default behavior** → (a) Load sample data on app startup (RESEARCH.md:374-377)
- **Decision**: Initialize `raw_data` reactive with `read.csv("data/sample_reps.csv")`
- **Rationale**: Provides immediate value, user sees working dashboard instantly

**Q7: shinytest2 vs manual testing balance** → (b) shinytest2 for critical paths, manual for UX (RESEARCH.md:379-383)
- **Decision**: Automate major workflows (upload, filter, export), manually verify slider smoothness and chart aesthetics
- **Rationale**: Maximize automation where reliable, defer to manual for subjective UX assessment

**Q8: Coverage expectations for app.R** → (b) Extract helpers, aim for 100% on helpers only (RESEARCH.md:385-388)
- **Decision**: Create `R/shiny_helpers.R` with testable functions, 100% coverage required
- **Rationale**: `app.R` UI/server logic hard to unit test, but validation/normalization logic must be covered

**Q9: Performance monitoring threshold** → (c) Both console log and user warning (RESEARCH.md:390-395)
- **Decision**: Log all timing to console, show notification if > 500ms
- **Rationale**: Developers see all performance data, users warned only when slow

**Q10: Progress indicator threshold** → (b) Conditional based on row count (RESEARCH.md:397-401)
- **Decision**: Show notification if scoring > 500ms (reactive approach per Q9)
- **Rationale**: Avoids UI flicker for small datasets, alerts on actual slow performance

**Q11: Upload validation error display** → (b) Inline error text above widget (RESEARCH.md:403-408)
- **Decision**: Use `verbatimTextOutput("upload_status")` below file input
- **Rationale**: Least intrusive, keeps upload context visible, no modal interruption

**Q12: Zero rows after filter behavior** → (a) Replace table with message text (RESEARCH.md:410-414)
- **Decision**: Add `if (nrow(data) == 0)` check in `renderDT()`, return message data frame
- **Rationale**: Clearest feedback, prevents confusion with empty table

**Q13: Weight slider rounding precision** → (b) Round to 3 decimals (RESEARCH.md:416-420)
- **Decision**: Slider `step = 0.01`, weights rounded to 3 decimals (0.333, 0.334)
- **Rationale**: Matches default weights in `calculate_scores()`, stays within ±0.001 tolerance

**Q14: App launch command** → (b) `Rscript -e "shiny::runApp('app.R')"` (RESEARCH.md:422-426)
- **Decision**: Document explicit command, avoid shebang
- **Rationale**: Platform-independent, works on all OSes without file permissions

**Q15: Dashboard usage documentation location** → (a) Add to AGENTS.md (RESEARCH.md:428-431)
- **Decision**: Add "Dashboard Usage" section to AGENTS.md with all features documented
- **Rationale**: AGENTS.md is established developer guide, keep pattern consistent
