# Phase Review: Phase 3

## Overall Verdict
**NEEDS-FIX** — See MUST-FIX.md for actionable fix tasks.

## Code Quality Review

### Summary
The Phase 3 implementation delivers a functional Shiny dashboard with all core features specified in SPEC.md. Code quality is generally good with consistent style, clear documentation, and 100% test coverage for helper functions. However, there are several critical issues that prevent full acceptance:

1. **Dependency mismatch**: `plotly` is in `Suggests` but used as hard dependency in app.R
2. **Test coverage gaps**: shinytest2 tests are skipped in CI/test environment
3. **Incomplete documentation**: STATUS.md not updated to reflect completion
4. **Missing slider auto-normalization UX**: Weight sliders don't auto-update in UI when normalized
5. **Edge case handling**: Missing validation for zero-weight scenarios in weight normalization

The core functionality works correctly — the app launches, scores calculate properly, filters work, and export functions as expected. The issues found are primarily around polish, edge cases, and test reliability.

### Findings

#### 1. **Dependency Configuration Issue** — `DESCRIPTION:20` and `app.R:15`
- **Problem**: `plotly` is declared in `Suggests` (line 20) but imported as hard dependency in `app.R` (line 15: `library(plotly)`)
- **Impact**: App will crash on systems where plotly is not installed, despite being listed as optional
- **Severity**: Critical — breaks deployment in production environments

#### 2. **Test Infrastructure Gap** — `tests/testthat/test-app.R:7-123`
- **Problem**: All 6 shinytest2 E2E tests are skipped with "On CRAN" reason (test output shows SKIP x6)
- **Impact**: No automated verification that the dashboard actually works end-to-end
- **Severity**: Major — manual testing is the only verification, which is error-prone and not repeatable

#### 3. **Weight Slider UX Incomplete** — `app.R:143-153`
- **Problem**: Weights are normalized for scoring (line 147-152), but sliders don't visually update to reflect normalized values
- **Impact**: User sets activity=0.8, sees "0.80" on slider, but actual weight used is different after normalization
- **Severity**: Major — confusing UX, violates SPEC.md:48-49 requirement to "Display current weight values next to each slider"
- **Note**: Code comment at line 145 says "We don't auto-update sliders to avoid reactive loops" but PLAN.md:573-581 explicitly requires `updateSliderInput()` to show normalized values

#### 4. **STATUS.md Not Updated** — `STATUS.md:4-5`
- **Problem**: STATUS.md shows "Phase: 3 | Step: build" instead of "Phase: 3 | Step: complete | Status: DONE"
- **Impact**: Project status tracking incomplete, violates SPEC.md:260 and PLAN.md:1295-1300
- **Severity**: Minor — documentation only, but indicates incomplete delivery

#### 5. **Zero-Weight Edge Case Not Validated** — `R/shiny_helpers.R:50-69`
- **Problem**: `normalize_three_weights()` handles all-zero case (line 54-56) but doesn't validate input constraints
- **Impact**: If user drags all three sliders to zero simultaneously (unlikely but possible), function returns default weights silently without user feedback
- **Severity**: Minor — edge case unlikely in practice, but should be validated at UI layer

#### 6. **Missing ggplot2 Import** — `app.R:330,397`
- **Problem**: Code uses `ggplot2::ggplot()` and `ggplot2::annotate()` at lines 330, 397 but ggplot2 is never imported
- **Impact**: Will fail if plotly loads before ggplot2 namespace is available
- **Severity**: Major — runtime error in empty data edge cases

#### 7. **Color Coding Not Implemented** — `SPEC.md:41` vs `app.R:316-322`
- **Problem**: SPEC.md:41 requires "color coding (green/yellow/red) for score ranges (75-100 / 50-74 / 0-49)"
- **Implementation**: Code at line 316-322 uses backgroundColor styleInterval with red/yellow/green BUT thresholds are at 50 and 75, which creates ranges 0-49 (red), 50-74 (yellow), 75-100 (green) — this actually matches spec
- **Severity**: None — on closer inspection, this is implemented correctly, just reversed from typical red=bad interpretation. The low scores get red background, which is correct.

### Spec Compliance Checklist

Based on SPEC.md:87-106 acceptance criteria:

- [x] Shiny app launches successfully via `Rscript -e "shiny::runApp('app.R')"`
- [x] Data upload widget accepts CSV and validates schema
- [x] Default sample_reps.csv data loads automatically on app launch
- [x] Rankings table displays all reps with scores, sortable by any column
- [ ] Weight sliders adjust dynamically and auto-normalize to sum = 1.0 — **FAILS: sliders don't visually update**
- [x] Scores recalculate instantly (< 500ms) when sliders move
- [x] Dimension breakdown bar chart shows top 10 reps with three scores each
- [x] Trend line chart shows score progression over periods for selected reps
- [x] Filter by rep_id updates table and charts reactively
- [x] Filter by period updates table and charts reactively
- [x] Clear filters button resets to full dataset view
- [x] Export button downloads CSV with correct data and timestamp filename
- [x] Debug mode checkbox toggles intermediate columns in output data
- [x] App handles edge cases gracefully (zero activity rows, missing periods, single rep)
- [ ] All tests pass — **PARTIAL: unit tests pass (184/184), E2E tests skipped (0/6 run)**
- [x] Code runs without errors or warnings (aside from shinytest2 skips)
- [ ] Documentation updated — **PARTIAL: CLAUDE.md, AGENTS.md, README.md updated, but STATUS.md not updated**

**Score: 13/16 acceptance criteria met (81%)**

## Adversarial Test Review

### Summary
Test quality is **adequate but incomplete**. Unit test coverage is excellent (100% for helper functions, 184 passing assertions). However, integration testing is weak:

- shinytest2 E2E tests exist but are skipped in the test environment
- No tests verify the actual interactive behavior users will experience
- Manual test checklist exists but is not runnable (comments only)
- No testing of failure scenarios in the Shiny app itself (only helper functions)

The project has strong unit testing discipline but weak integration testing, which is concerning for a UI-heavy phase.

### Findings

#### 1. **Skipped Integration Tests** — `tests/testthat/test-app.R:7-123`
- **Problem**: All 6 shinytest2 tests are skipped with `skip_if_not_installed("shinytest2")` triggered by "On CRAN" environment
- **Impact**: Zero automated verification of:
  - App launch and data loading
  - Weight slider reactivity
  - Filter behavior
  - Debug mode toggle
- **Root Cause**: Test runner environment behaves like CRAN (likely CI setting), causing `skip_if_not_installed()` to skip despite package being installed
- **Missing Coverage**: Upload validation, export functionality, chart rendering, error scenarios

#### 2. **Manual Tests Not Automated** — `tests/testthat/test-app-manual.R:1-45`
- **Problem**: File contains only comments, no executable tests
- **Impact**: 5 critical UX scenarios documented but not verified:
  - Slider smoothness (TEST 1)
  - Chart interactivity (TEST 2)
  - Error message clarity (TEST 3)
  - Large dataset performance (TEST 4)
  - Export file integrity (TEST 5)
- **Assessment**: This is acceptable per SPEC.md:152-153 which says "manual testing required for UX validation", but having zero automated E2E tests is risky

#### 3. **Helper Function Tests Are Excellent** — `tests/testthat/test-shiny_helpers.R:1-99`
- **Strength**: 8 thorough test cases covering:
  - Valid data acceptance
  - Missing column rejection
  - Empty data rejection
  - Non-dataframe input handling
  - Weight normalization proportions
  - Equal weight handling
  - All-zero edge case
  - One-zero case
  - Non-unit sum rescaling
  - Row summary formatting
- **Coverage**: 100% line coverage for `R/shiny_helpers.R`
- **Quality**: Assertions are specific (e.g., `expect_equal(result[["activity"]], 0.5)` not just `expect_true(result$valid)`)

#### 4. **No Negative Testing for App** — `tests/testthat/test-app.R`
- **Missing**: Tests for failure scenarios:
  - Upload CSV with wrong column types (e.g., tenure_months as character)
  - Upload CSV with negative values
  - Upload CSV with zero quota values
  - Apply filters that result in zero rows (test exists but skipped)
  - Drag slider to invalid range (e.g., negative)
- **Impact**: Edge cases may crash app in production without warning

#### 5. **No Performance Validation** — No test file
- **Missing**: Test verifying SPEC.md:80 requirement "< 500ms for datasets up to 1000 rows"
- **Suggested**: `test_that("scoring performance meets 500ms requirement for 1000 rows", { ... })`
- **Impact**: Performance regression could go unnoticed until production

#### 6. **Mock-Free Philosophy Maintained** — All test files
- **Strength**: No mocking found in any test file
- **Verification**: Tests use real implementations with real data
- **Compliance**: Follows Phase 2 REFLECTIONS.md:114-117 recommendation

#### 7. **Integration Test Pattern Weak** — `tests/testthat/test-app.R:10-22`
- **Problem**: Test "app launches and loads default data" only checks data_summary text output
- **Better**: Should also verify:
  - Rankings table has 80 rows
  - Score columns exist and contain valid ranges (0-100)
  - Dimension chart renders without error
- **Current**: Smoke test only, not comprehensive validation

### Test Coverage Summary

| Category | Coverage | Quality |
|----------|----------|---------|
| Unit Tests (R/ functions) | 100% line coverage, 184 assertions | Excellent |
| Integration Tests (E2E workflows) | 0% (all skipped) | Inadequate |
| Manual Tests (UX validation) | Documented, not executed | Adequate per spec |
| Edge Case Tests | Partial (helpers only) | Weak |
| Performance Tests | Missing | None |

**Overall Test Quality: Weak for UI phase** — Unit tests are strong, but the dashboard itself is not validated automatically.

### Missing Test Cases

Based on SPEC.md:114-148 test scenarios, these are **not covered**:

1. **Data Upload Tests** (SPEC.md:116-120):
   - [ ] Upload CSV with wrong column types → No test (skipped)
   - [ ] Upload empty CSV → No test (skipped)
   - [x] Upload CSV with missing columns → Covered by helper unit test

2. **Weight Slider Tests** (SPEC.md:122-125):
   - [ ] Move activity slider to 0.5 → Test exists but skipped
   - [ ] Verify scores change when weights change → Test exists but skipped
   - [ ] Auto-adjustment of other sliders → Not tested at all

3. **Reactivity Tests** (SPEC.md:127-131):
   - [ ] Change rep_id filter → Test exists but skipped
   - [ ] Change period filter → Test exists but skipped
   - [ ] Clear filters → Test exists but skipped
   - [ ] Select different reps in trend chart → Not tested

4. **Edge Case Tests** (SPEC.md:133-137):
   - [ ] Load dataset with single rep → Not tested
   - [ ] Load dataset with single period → Not tested
   - [ ] Load dataset with all-zero activity → Not tested
   - [ ] Apply filter returning zero rows → Not tested

5. **Export Tests** (SPEC.md:139-143):
   - [ ] Export with no filters → Not tested
   - [ ] Export with rep filter active → Not tested
   - [ ] Export with debug mode on/off → Not tested

6. **Performance Tests** (SPEC.md:145-148):
   - [ ] Load 500-row dataset, measure recalculation time → Not tested
   - [ ] Load 1000-row dataset, verify < 1s → Not tested
   - [ ] Verify progress indicator for slow scoring → Not tested

**Coverage: 1/21 specified test scenarios actually executed (5%)**

Most scenarios have test code written but are skipped. This is a test infrastructure problem, not a missing test problem.
