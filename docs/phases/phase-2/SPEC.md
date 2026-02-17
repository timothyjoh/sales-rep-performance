# Phase 2: Scoring Engine with Normalization

## Objective
Build the core scoring engine that calculates fair, bias-free productivity scores (0-100) for each sales rep. Implement normalization functions that adjust for tenure, territory size, and quota attainment, plus a configurable weight system so different scoring dimensions can be balanced. Deliver a working, testable pipeline from raw rep data to scored output.

## Scope

### In Scope
- **Normalization functions** that adjust raw metrics for fairness:
  - Tenure-based normalization (new reps vs veterans)
  - Territory size adjustment (account for different opportunity volumes)
  - Quota normalization (standardize revenue relative to target)
- **Dimension scoring** across three areas:
  - Activity quality (calls, follow-ups, meetings)
  - Conversion efficiency (meetings-to-deals ratio, activity-to-revenue efficiency)
  - Revenue contribution (quota attainment, revenue per deal)
- **Configurable weight system** allowing adjustment of dimension importance
- **Final score calculation** that combines normalized dimensions with weights to produce 0-100 score
- **End-to-end scoring pipeline** function that takes raw data and returns scored results
- **Comprehensive tests** covering edge cases (zero activity, quota exceeded, veteran low-performers, new high-performers)
- **Vertical slice validation script** that loads sample data, calculates scores, outputs CSV

### Out of Scope
- No Shiny dashboard or UI components (Phase 3)
- No Quarto report generation (Phase 4)
- No improvement suggestions logic (Phase 4)
- No time-series trending or multi-period comparisons
- No visualization functions (Phase 3 will handle charts)
- No data validation/cleaning beyond basic sanity checks
- No external data sources or API integrations

## Requirements

### Functional Requirements

**Normalization:**
- Tenure adjustment: New reps (0-12 months) get scaled expectations vs experienced reps (37+ months)
- Territory normalization: Adjust metrics by territory_size (larger territories should have proportionally higher activity)
- Quota normalization: Convert revenue_generated to quota attainment percentage

**Dimension Scoring:**
- Activity quality: Composite of calls_made, followups_done, meetings_scheduled (normalized by tenure & territory)
- Conversion efficiency: Meetings-to-deals ratio, revenue per activity unit
- Revenue contribution: Quota attainment percentage, revenue per deal closed

**Weight System:**
- Accept weight configuration as named numeric vector: `c(activity = 0.3, conversion = 0.4, revenue = 0.3)`
- Validate weights sum to 1.0 (tolerance of 0.001 for floating point precision)
- Provide default weights that balance all three dimensions equally

**Score Calculation:**
- Final score is weighted sum of three dimension scores
- Output range strictly 0-100
- Handle edge cases gracefully (all-zero activity should score 0, not error)
- Return detailed breakdown: overall score + individual dimension scores for transparency

### Non-Functional Requirements
- All normalization functions must be pure (no side effects, deterministic)
- Score calculation must complete in < 100ms for 1000 rows (performance requirement for future dashboard)
- Functions must handle grouped data (multiple periods per rep) correctly
- Code follows tidyverse style guide
- 100% test coverage maintained
- Clear error messages for invalid inputs (negative values, missing required columns)

## Acceptance Criteria

- [ ] Tenure normalization function works with tests covering new/mid/experienced reps
- [ ] Territory size normalization function works with tests covering small/large territories
- [ ] Quota normalization function handles edge cases (zero quota, quota exceeded by 10x)
- [ ] Activity quality dimension scoring implemented and tested
- [ ] Conversion efficiency dimension scoring implemented and tested
- [ ] Revenue contribution dimension scoring implemented and tested
- [ ] Weight configuration validates sum-to-1 requirement with clear error message
- [ ] Final score calculation combines dimensions correctly (verified by hand-calculated test cases)
- [ ] End-to-end scoring pipeline works with sample_reps.csv data
- [ ] Vertical slice script (`scripts/score_data.R`) generates output CSV with scores
- [ ] All tests pass (minimum 15 test cases covering edge cases)
- [ ] 100% code coverage verified via `scripts/coverage_report.R`
- [ ] All functions documented with roxygen2 (@param, @return, @examples)
- [ ] No warnings or errors when running scoring pipeline

## Testing Strategy

### Framework
- **testthat** (continuing from Phase 1)
- **covr** for coverage reporting
- Test files: `tests/testthat/test-normalization.R`, `tests/testthat/test-scoring.R`

### Key Test Scenarios

**Normalization tests:**
- Tenure adjustment: New rep (6 months) vs veteran (60 months) with same raw metrics → veteran penalized
- Territory size: Rep with 50 accounts vs rep with 200 accounts → larger territory gets higher normalized activity
- Quota normalization: Rep who hit 150% quota vs rep who hit 50% quota → scores reflect attainment

**Dimension scoring tests:**
- Activity quality: High activity but short tenure → appropriate score
- Conversion efficiency: 10 meetings, 0 deals → low efficiency score
- Revenue contribution: Zero revenue → zero contribution score

**Weight configuration tests:**
- Weights sum to 0.99 → error with clear message
- Weights sum to 1.0 → accepted
- Negative weights → error

**Edge cases:**
- All-zero activity row → score = 0 (no error)
- Quota exceeded by 10x → capped or handled gracefully (document decision)
- Negative tenure_months → error with message "tenure_months cannot be negative"
- Missing required column → error listing which columns are missing

**Integration tests:**
- Load `data/sample_reps.csv`, run full scoring pipeline, verify output has correct columns
- Run scoring with custom weights, verify scores change appropriately

### Coverage Expectations
- 100% line coverage for all new scoring functions
- No decrease in overall project coverage from Phase 1

### E2E Tests
Not applicable — Phase 2 has no UI. Vertical slice script serves as integration validation.

## Documentation Updates

### CLAUDE.md
**Add:**
- Quick reference for scoring commands:
  ```bash
  # Score sample data with default weights
  Rscript scripts/score_data.R

  # Score data with custom weights
  Rscript scripts/score_data.R --activity 0.5 --conversion 0.3 --revenue 0.2
  ```
- Brief explanation of scoring methodology (one paragraph)
- Reference to scoring function documentation for details

### README.md
**Add:**
- Update Phase Status: Phase 2 COMPLETE
- Add "Scoring" section explaining:
  - What the scoring engine does
  - How to run scoring on sample data
  - Overview of three scoring dimensions
  - Link to full methodology documentation (if created)
- Update Tech Stack section if any new packages added

### AGENTS.md
**Add:**
- Scoring methodology overview (2-3 paragraphs explaining normalization + dimensions + weights)
- Scored data model: New columns added to output (score, activity_score, conversion_score, revenue_score)
- Document expected score ranges and interpretation
- Add scoring commands to Common Commands Cheatsheet section

### New Documentation (Optional)
Consider creating `docs/methodology.md` if scoring logic becomes complex and needs detailed explanation separate from code comments.

## Dependencies

### Code Dependencies
- Existing Phase 1 code: `generate_sample_data()` and `data/sample_reps.csv`
- No new R packages required — tidyverse functions sufficient
- Possible addition: `checkmate` package for input validation (optional, only if validation becomes complex)

### Process Dependencies
- Phase 1 must be complete (it is — marked COMPLETE in REFLECTIONS.md)
- Sample data must exist at `data/sample_reps.csv` (it does)

## Adjustments from Previous Phase

Based on REFLECTIONS.md lessons learned:

**1. Validate test infrastructure early**
- Before writing scoring functions, write one trivial normalization test to confirm testthat setup still works after Phase 1 fixes
- Run tests in clean environment (or document assumptions about working directory)

**2. Declare dependencies immediately**
- If any new package is used (e.g., `scales` for percentage formatting), add to DESCRIPTION immediately
- Run `grep "library\\|require" R/*.R` periodically to audit undeclared dependencies

**3. Write assertions that match intent**
- If normalization divides by territory_size, test verifies result is proportional to territory_size, not just "is numeric"
- If weights must sum to 1.0, test that weights = c(0.3, 0.4, 0.29) is rejected

**4. Add error handling for user-facing functions**
- Scoring functions will be called by Shiny dashboard (Phase 3), so use `stopifnot()` or `rlang::abort()` with clear messages
- Test error messages explicitly: `expect_error(score_reps(bad_data), "tenure_months cannot be negative")`

**5. Keep documentation in sync during implementation**
- Update phase status to "IN PROGRESS" in all docs when Phase 2 work starts
- Update to "COMPLETE" when acceptance criteria are met, before writing REFLECTIONS.md

**6. Use integration tests for multi-step workflows**
- Write test that calls `load data → normalize → score → validate output structure` in one test case
- This catches integration bugs that unit tests miss (e.g., column name mismatches between functions)

**7. Validate PLAN assumptions before full implementation**
- If PLAN proposes "normalize activity by dividing by territory_size," test with sample data first to ensure result is sensible
- Document any mathematical assumptions (e.g., "assumes territory_size > 0") in function roxygen comments

## Vertical Slice Validation

**User-visible deliverable:** A new CSV file (`data/scored_reps.csv`) created by running:
```bash
Rscript scripts/score_data.R
```

This file contains all original columns from `sample_reps.csv` plus new scoring columns:
- `score` — Overall productivity score (0-100)
- `activity_score` — Activity quality dimension score (0-100)
- `conversion_score` — Conversion efficiency dimension score (0-100)
- `revenue_score` — Revenue contribution dimension score (0-100)

**Validation criteria:**
- File exists and contains 80 rows (same as input)
- All scores are numeric and within 0-100 range
- Scores vary across reps (not all identical)
- High-performing reps (high revenue, high conversion) have higher scores than low-performing reps
- Can be opened in Excel/Google Sheets and inspected by non-technical user

This demonstrates end-to-end scoring without requiring UI, making Phase 2 testable and valuable on its own.
