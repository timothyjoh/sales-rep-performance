# Research: Phase 3

## Phase Context
Phase 3 builds an interactive Shiny dashboard that makes the Phase 2 scoring engine accessible to non-technical users (managers, leadership). It delivers a web application with CSV data upload, interactive rankings table, live weight sliders that trigger instant score recalculation, dimension breakdown charts, trend visualizations over time, filtering controls, and CSV export capabilities. The dashboard must handle typical datasets (100-1000 rows) with sub-500ms recalculation performance.

## Previous Phase Learnings

### Key Takeaways from Phase 2 Reflections
From `docs/phases/phase-2/REFLECTIONS.md`:

**Add debug mode for troubleshooting (REFLECTIONS.md:89-93)**
- Phase 2 removes intermediate normalization columns (`tenure_factor`, `territory_factor`, `quota_attainment`) after scoring — `R/calculate_scores.R:84`
- Makes debugging harder when scores look unexpected
- Phase 3 must add `debug = FALSE` parameter to `calculate_scores()` to optionally preserve these columns
- Expose as UI checkbox in dashboard for troubleshooting

**Validate scoring correctness with real data (REFLECTIONS.md:95-98)**
- When loading real data via dashboard upload, scores may look wrong due to math errors
- Manually verify 2-3 rep scores by hand during implementation
- Use debug mode to inspect intermediate values if needed

**Continue percentile-based approach (REFLECTIONS.md:100-102)**
- Percentile ranking works well — produces fair, comparable scores
- Do NOT switch to fixed anchors (e.g., "100% quota = 100 points")
- Fixed anchors wouldn't account for relative performance

**Add performance monitoring in Shiny (REFLECTIONS.md:104-107)**
- SPEC.md:80 requires < 500ms for datasets up to 1000 rows
- Wrap `calculate_scores()` in `system.time()` inside Shiny reactive
- Log timing to console, alert if > 500ms

**Keep weight sliders simple (REFLECTIONS.md:109-112)**
- Three sliders (activity, conversion, revenue) with auto-normalization to sum to 1.0
- Show real-time score recalculation on slider change (reactive Shiny pattern)
- Don't over-engineer — simple slider UX is sufficient

**Don't mock in Phase 3 tests (REFLECTIONS.md:114-117)**
- Phase 2 succeeded by testing real implementations (no mocks)
- Continue pattern: test Shiny reactives with real scoring functions
- Only mock external data sources if added (databases, APIs)

**Test edge cases BEFORE writing implementation (REFLECTIONS.md:186-188)**
- Phase 2 missed zero quota because test written after code
- TDD approach: write failing test first → implement → passing test
- For Phase 3: write test "upload CSV with missing columns" before implementing upload handler

**Review SPEC acceptance criteria line-by-line (REFLECTIONS.md:190-193)**
- Don't mark phase complete until all SPEC.md checklist items verified
- Run through checklist item-by-item, execute test for each

**Add mathematical correctness checks to integration tests (REFLECTIONS.md:195-198)**
- Pick 1-2 known reps, calculate expected score by hand, assert exact value
- Phase 3 integration test should validate specific rep's score matches expected

**Document design tradeoffs explicitly (REFLECTIONS.md:200-203)**
- Use roxygen `@details` section explaining design decisions
- For Phase 3: document why weight sliders auto-normalize (UX decision to prevent invalid states)

**Run full test suite after every task completion (REFLECTIONS.md:205-208)**
- Run `Rscript -e "testthat::test_dir('tests/testthat')"` after EVERY function written
- Consider setting up file watcher (e.g., `testthat::auto_test()`)

**Update STATUS.md throughout phase (REFLECTIONS.md:216-218)**
- Update when phase starts, at major milestones, and when complete
- Show "Phase 3 IN PROGRESS" at start, "Phase 3 COMPLETE" at end

## Current Codebase State

### Project Structure Overview
This is a **minimal R package** structure (not full package with NAMESPACE/man/):

```
sales-rep-performance/
├── DESCRIPTION                     # Package metadata with dependencies
├── sales-rep-performance.Rproj     # RStudio project file (BuildType: Package)
├── R/                              # Source code (5 files, all Phase 2 scoring engine)
│   ├── generate_sample_data.R      # Data generation function (Phase 1)
│   ├── scoring_utils.R             # Validation helpers + percentile ranking
│   ├── normalization.R             # Tenure/territory/quota normalization
│   ├── dimension_scoring.R         # Activity/conversion/revenue scoring
│   └── calculate_scores.R          # Weight validation + scoring pipeline
├── tests/                          # Test suite (testthat 3rd edition)
│   ├── testthat.R                  # Test runner entry point
│   └── testthat/
│       ├── test-generate_sample_data.R  # Data generation tests (82 lines)
│       ├── test-scoring_utils.R         # Validation + percentile tests (80 lines)
│       ├── test-normalization.R         # Normalization tests (112 lines)
│       ├── test-dimension_scoring.R     # Dimension scoring tests (178 lines)
│       ├── test-calculate_scores.R      # Weight + pipeline tests (186 lines)
│       └── test-integration.R           # End-to-end scoring tests (125 lines)
├── scripts/                        # Executable scripts
│   ├── generate_data.R             # Generate sample CSV (uses R/generate_sample_data.R)
│   ├── score_data.R                # Score sample data and output CSV
│   └── coverage_report.R           # Generate code coverage report (100% target)
├── data/                           # Generated data files
│   ├── sample_reps.csv             # Sample sales rep data (80 rows: 20 reps x 4 quarters)
│   └── scored_reps.csv             # Scored output (80 rows x 15 columns)
└── docs/                           # Documentation and phase planning
    ├── phases/phase-1/             # Phase 1 complete
    ├── phases/phase-2/             # Phase 2 complete
    └── phases/phase-3/             # Phase 3 (current phase)
        └── SPEC.md
```

**Key observation:** No Shiny code exists yet — Phase 3 starts from scratch for UI.

### Relevant Components for Phase 3

#### 1. Scoring Engine (Phase 2 deliverables — ready to integrate)

**Main Entry Point:** `R/calculate_scores.R:56-85`
```r
calculate_scores <- function(
    data,
    weights = c(activity = 0.333, conversion = 0.334, revenue = 0.333))
```
- **Input:** Data frame with 11 required columns (rep_id, rep_name, tenure_months, calls_made, followups_done, meetings_scheduled, deals_closed, revenue_generated, quota, territory_size, period)
- **Output:** Input data + 4 new score columns (activity_score, conversion_score, revenue_score, score)
- **Validation:** Calls `validate_columns()` and `validate_weights()` — throws errors if invalid
- **Pipeline:** normalization → dimension scoring → weighted sum
- **Key limitation:** Removes intermediate columns at line 84 (tenure_factor, territory_factor, quota_attainment) — Phase 3 must add debug parameter

**Weight Validation:** `R/calculate_scores.R:15-36`
```r
validate_weights(weights)
```
- Checks: named vector, correct names (activity/conversion/revenue), all >= 0, sum to 1.0 (±0.001 tolerance)
- **Important:** Shiny sliders must respect these validation rules

**Supporting Functions:**
- `R/scoring_utils.R:17-23` — `validate_columns(data, required_cols)` — throws error listing missing columns
- `R/scoring_utils.R:38-43` — `validate_non_negative(data, col_name)` — throws error if negatives found
- `R/scoring_utils.R:57-66` — `percentile_rank(x)` — converts vector to 0-100 percentile ranks, handles ties and all-zero vectors

**Normalization Functions:** `R/normalization.R`
- `normalize_tenure()` — Line 14-22: calculates `tenure_factor = pmin(1.0, tenure_months / 60)`
- `normalize_territory()` — Line 38-45: calculates `territory_factor = territory_size / 100`
- `normalize_quota()` — Line 61-73: calculates `quota_attainment = (revenue_generated / quota) * 100`, validates quota > 0

**Dimension Scoring Functions:** `R/dimension_scoring.R`
- `score_activity()` — Line 18-36: normalizes calls/followups/meetings by tenure and territory, percentile ranks composite
- `score_conversion()` — Line 57-75: calculates meetings-to-deals ratio and revenue-per-activity, percentile ranks each
- `score_revenue()` — Line 95-108: percentile ranks quota attainment and revenue-per-deal

**All functions use native pipe `|>` and tidyverse (dplyr) conventions** — Phase 3 must continue this pattern.

#### 2. Sample Data Structure

**Input Data Schema:** `data/sample_reps.csv` (80 rows)
- **Columns (11):** rep_id (chr), rep_name (chr), tenure_months (int), calls_made (int), followups_done (int), meetings_scheduled (int), deals_closed (int), revenue_generated (num), quota (num), territory_size (num), period (chr)
- **Periods:** Q1-2025, Q2-2025, Q3-2025, Q4-2025
- **Reps:** REP001 through REP020
- **Tenure distribution:** 30% new (1-12 months), 40% mid (13-36), 30% experienced (37-120)

**Scored Data Schema:** `data/scored_reps.csv` (80 rows x 15 columns)
- **Original 11 columns** + **4 score columns:** activity_score, conversion_score, revenue_score, score
- **Score ranges:** All 0-100 scale (percentile-based)
- **Example row (REP003 Q1-2025):** activity_score = 100.0, conversion_score = 60.1, revenue_score = 71.5, score = 77.2

**Key for Phase 3:** Dashboard must accept same CSV schema as `sample_reps.csv`, validate column presence, and display all 15 columns after scoring.

#### 3. Test Infrastructure Patterns

**Test File Structure:** All tests use:
```r
library(testthat)
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "source_file.R"))
```

**Test Organization:** — `tests/testthat/test-integration.R:1-126`
- Use `test_that("description", { ... })` blocks
- Multiple assertions per test (expect_equal, expect_true, expect_error)
- Integration tests load real data from `data/sample_reps.csv` — Line 8-11
- Validate structure (row counts, column names) + behavior (score ranges, no NA/Inf) + correctness (known rep scores)

**Coverage Target:** 100% line coverage enforced — `scripts/coverage_report.R:20-25`

**Anti-mock Philosophy:** No mocking in Phase 2 tests — test real implementations with real data — this pattern continues in Phase 3.

#### 4. Vertical Slice Script Pattern

**File:** `scripts/score_data.R` (41 lines)
**Pattern:**
1. Source all R functions explicitly — Lines 7-10
2. Load data with `read.csv(stringsAsFactors = FALSE)` — Line 15
3. Call scoring function — Line 20
4. Select output columns explicitly — Lines 23-29
5. Write CSV with `write.csv(row.names = FALSE)` — Line 34
6. Print summary statistics — Lines 38-40

**Key for Phase 3:** Shiny app will follow similar pattern (source functions, load data, score, display) but with reactive wrappers.

### Existing Patterns to Follow

#### Code Style Conventions (from all R files)
- **Piping:** Native pipe `|>` (not magrittr `%>%`) — used in all R/ files
- **Indentation:** 2 spaces — consistent across all files
- **Line length:** Mostly under 80 characters (some roxygen lines longer)
- **Naming:** snake_case for functions and variables — no deviations found
- **Assignment:** `<-` for assignment, never `=` — consistent across all files
- **Roxygen docs:** Required for all functions with `@param`, `@return`, `@examples` — see `R/calculate_scores.R:38-55`

#### Function Documentation Pattern (roxygen2)
Every function has:
```r
#' Function Title
#'
#' Multi-paragraph description explaining what it does.
#' Can span multiple lines.
#'
#' @param data A data frame with required columns
#' @param weights Named numeric vector (default values shown)
#'
#' @return Description of return value
#'
#' @examples
#' # Example showing default usage
#' result <- function_name(data)
#'
#' # Example showing custom parameters
#' result <- function_name(data, weights = c(...))
```

#### Test Assertion Patterns
**Positive tests:** — `tests/testthat/test-calculate_scores.R:7-17`
```r
expect_silent(function_call())
expect_equal(result$column, expected_value)
expect_true(condition)
```

**Error tests:** — `tests/testthat/test-calculate_scores.R:19-29`
```r
expect_error(function_call(bad_input), "Expected error message substring")
```

**Range validation:** — `tests/testthat/test-integration.R:21-25`
```r
expect_true(all(result$score >= 0 & result$score <= 100))
```

#### Error Message Patterns
All validation functions throw descriptive errors:
- `R/scoring_utils.R:20` — "Required columns missing: [list]"
- `R/scoring_utils.R:40` — "Column 'col_name' cannot contain negative values"
- `R/normalization.R:67` — "Column 'quota' cannot contain zero values (must be > 0)"
- `R/calculate_scores.R:17` — "Weights must be a named numeric vector"
- `R/calculate_scores.R:30-32` — "Weights sum to X.XXX, must sum to 1.0 (tolerance ±0.001)"

**Key for Phase 3:** Dashboard error handling must match this descriptive style.

### Dependencies & Integration Points

#### Current R Package Dependencies
**File:** `DESCRIPTION:9-16`
```
Imports:
    dplyr,
    tibble,
    purrr
Suggests:
    testthat (>= 3.0.0),
    covr,
    rprojroot
```

**Phase 3 will ADD (per SPEC.md:208-213):**
- `shiny` — Core dashboard framework (already in DESCRIPTION from Phase 1)
- `shinydashboard` — Layout and UI components (NEW)
- `DT` — Interactive data tables (NEW)
- `plotly` — Interactive charts with hover tooltips (NEW, preferred over ggplot2)
- `shinytest2` — Automated Shiny testing (NEW, test dependency only)

**Note:** DESCRIPTION line 9 shows `shiny` should already be present (SPEC.md:209 says "already in DESCRIPTION from Phase 1"), but actual DESCRIPTION file doesn't list it. Must add during Phase 3 dependency setup.

#### Shiny Reactivity Integration
**Scoring function is NOT reactive-aware** — `R/calculate_scores.R:56-85` is a pure function.

**Phase 3 must wrap scoring in Shiny reactive:**
```r
scored_data <- reactive({
  req(input$data_upload)  # Require data uploaded
  start_time <- Sys.time()
  result <- calculate_scores(raw_data(), weights = c(
    activity = input$weight_activity,
    conversion = input$weight_conversion,
    revenue = input$weight_revenue
  ))
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
  message("Scoring took ", elapsed, " seconds")
  result
})
```

#### Test Infrastructure Compatibility
**Existing test runner:** `tests/testthat.R:1-4`
```r
library(testthat)
test_check("salesrepperformance")
```

**Phase 3 Shiny tests must:**
- Use `shinytest2` package for E2E testing
- Continue pattern of real implementations (no mocking)
- Maintain 100% coverage for helper functions (validation, data loading)
- Document manual test cases for UX validation (slider smoothness, chart aesthetics)

### Code References

#### Scoring Engine Entry Points
- `R/calculate_scores.R:56-85` — Main scoring pipeline function, takes data + weights, returns scored data
- `R/calculate_scores.R:15-36` — Weight validation (checks names, range, sum to 1.0)
- `R/scoring_utils.R:17-23` — Column validation (throws error if columns missing)
- `R/scoring_utils.R:57-66` — Percentile ranking function (handles ties, all-zero vectors)

#### Normalization Functions
- `R/normalization.R:14-22` — Tenure normalization (factor = min(1.0, months / 60))
- `R/normalization.R:38-45` — Territory normalization (factor = size / 100)
- `R/normalization.R:61-73` — Quota normalization (attainment = revenue / quota * 100, validates quota > 0)

#### Dimension Scoring Functions
- `R/dimension_scoring.R:18-36` — Activity quality scoring (calls + followups + meetings, normalized by tenure/territory)
- `R/dimension_scoring.R:57-75` — Conversion efficiency scoring (meetings-to-deals + revenue-per-activity)
- `R/dimension_scoring.R:95-108` — Revenue contribution scoring (quota attainment + revenue-per-deal)

#### Data Generation and Scripts
- `R/generate_sample_data.R:22-84` — Generates sample data (20 reps x 4 quarters default)
- `scripts/generate_data.R:1-15` — Script wrapper for data generation
- `scripts/score_data.R:1-41` — Vertical slice script showing full pipeline (load → score → write CSV)
- `scripts/coverage_report.R:1-26` — Coverage report script (enforces 100% target)

#### Test Files (Integration Test Key Reference)
- `tests/testthat/test-integration.R:7-33` — End-to-end scoring pipeline test (validates structure, ranges, no NA/Inf)
- `tests/testthat/test-integration.R:35-67` — Known rep score correctness test (validates REP003 activity > 90, REP012 overall < 20)
- `tests/testthat/test-integration.R:69-98` — All-identical input test (validates percentile_rank ties handling)
- `tests/testthat/test-integration.R:112-125` — Custom weights test (validates different weights produce different scores)

#### Sample Data Files
- `data/sample_reps.csv:1-81` — Sample input data (11 columns x 80 rows)
- `data/scored_reps.csv:1-81` — Scored output data (15 columns x 80 rows, includes 4 score columns)

## Open Questions

### UI/UX Design Questions
1. **Weight slider auto-normalization UX:** When user adjusts one slider, should:
   - (a) Auto-adjust other two sliders proportionally to maintain sum = 1.0? (Recommended per REFLECTIONS.md:109-112)
   - (b) Lock one slider and adjust the other?
   - (c) Show validation error and require manual adjustment?
   - **Recommendation:** (a) — prevents invalid states, provides instant feedback

2. **Trend chart rep selection control:** SPEC.md:60 says "allow selecting 1-5 reps" — use:
   - (a) Multi-select dropdown (selectizeInput with multiple = TRUE)?
   - (b) Checkbox group (checkboxGroupInput)?
   - (c) Interactive table row selection (DT::datatable selectRows)?
   - **Recommendation:** (c) — most intuitive, click table row → see trend line appear

3. **Dimension breakdown chart scope:** SPEC.md:52 says "top 10 reps" — should "top" mean:
   - (a) Top 10 by overall score?
   - (b) Top 10 by currently selected dimension?
   - (c) User-configurable (dropdown to choose sort dimension)?
   - **Recommendation:** (a) — simplest, aligns with "rankings" mental model

### Technical Architecture Questions
4. **Single-file vs modular Shiny app:** SPEC.md:84 says "single-file app (app.R)" — confirm:
   - (a) Single app.R with all UI + server logic inline?
   - (b) app.R + helper R files in R/ directory for data loading/validation?
   - **Recommendation:** (a) — defer modularization until complexity requires it (per REFLECTIONS.md:139)

5. **Debug mode implementation approach:** Add `debug` parameter to:
   - (a) `calculate_scores()` function signature only?
   - (b) All normalization + dimension scoring functions?
   - **Recommendation:** (a) — change only `calculate_scores()` to conditionally preserve intermediate columns before final select() call

6. **Data upload default behavior:** SPEC.md:34 says "default to sample_reps.csv if no file uploaded" — implementation:
   - (a) Load sample data on app startup (reactive initialized with sample_reps.csv)?
   - (b) Show empty state until user uploads OR clicks "Load Sample Data" button?
   - **Recommendation:** (a) — provides immediate value, user sees working dashboard instantly

### Test Strategy Questions
7. **shinytest2 vs manual testing balance:** SPEC.md:152 says "manual testing required for UX validation" — what's the split?
   - (a) shinytest2 for all workflows, manual testing only for aesthetics?
   - (b) shinytest2 for happy path + error cases, manual for slider smoothness and chart interactivity?
   - **Recommendation:** (b) — automate critical paths, manually verify UX polish

8. **Coverage expectations for app.R:** SPEC.md:151 says "100% for helper functions outside app.R" — does app.R need coverage?
   - (a) No coverage required for app.R (Shiny app code hard to unit test)?
   - (b) Extract testable logic to helper functions, aim for 100% on helpers only?
   - **Recommendation:** (b) — extract data validation, file upload parsing, weight normalization to R/shiny_helpers.R with 100% coverage

### Performance and Scalability Questions
9. **Performance monitoring threshold:** SPEC.md:80 requires "< 500ms for 1000 rows" — what action when exceeded?
   - (a) Show warning banner in UI ("Large dataset — scoring may be slow")?
   - (b) Log to console only (developer visibility)?
   - (c) Both?
   - **Recommendation:** (c) — log for debugging, warn user for transparency

10. **Progress indicator threshold:** SPEC.md:82 says "use progress indicators if scoring > 100ms" — implement:
    - (a) Always show progress indicator (even if fast)?
    - (b) Conditional: only if dataset > 200 rows?
    - (c) Conditional: only if scoring takes > 100ms (requires timing first)?
    - **Recommendation:** (b) — predictive approach, avoids UI flicker for small datasets

### Edge Cases and Error Handling Questions
11. **Upload validation error display:** SPEC.md:82 says "show user-friendly error message" — where?
    - (a) Modal dialog (showModal)?
    - (b) Inline error text above upload widget (validate() in reactive)?
    - (c) Alert banner at top of dashboard (showNotification)?
    - **Recommendation:** (b) — least intrusive, keeps context visible

12. **Zero rows after filter behavior:** SPEC.md:137 requires "show 'No data matches filters' message" — location?
    - (a) Replace table with message text?
    - (b) Show empty table + message above table?
    - (c) Show message in table body (DT customization)?
    - **Recommendation:** (a) — clearest, prevents confusion with empty table

13. **Weight slider rounding precision:** Sliders output decimal values — should weights:
    - (a) Round to 2 decimals (0.33, 0.34)?
    - (b) Round to 3 decimals (0.333, 0.334)?
    - (c) Use exact slider values (0.3333333...)?
    - **Recommendation:** (b) — matches default weights in calculate_scores(), stays within ±0.001 tolerance

### Deployment and Documentation Questions
14. **App launch command:** SPEC.md:89 shows both `Rscript app.R` and `shiny::runApp()` — which is primary?
    - (a) `Rscript app.R` (requires shebang in app.R)?
    - (b) `Rscript -e "shiny::runApp('app.R')"` (explicit)?
    - **Recommendation:** (b) — more explicit, avoids shebang platform issues

15. **Dashboard usage documentation location:** SPEC.md:191-202 proposes updating AGENTS.md vs creating docs/dashboard-guide.md — which?
    - (a) Add dashboard section to AGENTS.md (keep all developer docs in one place)?
    - (b) Create separate docs/dashboard-guide.md (keep AGENTS.md focused on code)?
    - **Recommendation:** (a) — AGENTS.md is established as "complete developer guide", keep pattern consistent
