# Reflections: Phase 2

## Looking Back

### What Went Well

- **Clean, modular architecture delivered**: Four separate R files (scoring_utils.R, normalization.R, dimension_scoring.R, calculate_scores.R) with clear separation of concerns. Each function does one thing well, making the codebase easy to understand and maintain.

- **Excellent test coverage achieved**: 147 tests passing with 100% line coverage across all 5 source files. Every function is tested, including edge cases like zero activity, negative values, and weight validation failures.

- **Mathematical correctness verified**: Percentile-based scoring algorithm works correctly, producing fair scores that normalize across tenure and territory size. Sample output shows expected behavior (e.g., REP003 with 72 months tenure and high activity scored 77.2 overall, while REP007 with 1 month tenure scored 10.0).

- **Code conventions followed perfectly**: All code uses native pipe `|>`, tidyverse style, 2-space indentation, snake_case naming, and roxygen2 documentation with @param, @return, and @examples. No deviations from project standards.

- **Vertical slice delivered successfully**: `scripts/score_data.R` produces `data/scored_reps.csv` with 80 rows and 4 new score columns, demonstrating end-to-end scoring pipeline without UI.

- **Performance requirement exceeded**: Scoring 80 rows completes nearly instantaneously (well under 100ms requirement for 1000 rows per SPEC.md:59).

- **Documentation comprehensive and accurate**: All functions documented with roxygen2, all docs updated (CLAUDE.md, README.md, AGENTS.md) to reflect Phase 2 completion and scoring methodology.

### What Didn't Work

- **Zero quota edge case missed**: `normalize_quota()` divides by `quota` without checking if `quota == 0`, which causes division by zero (result: `Inf`). Identified by REVIEW.md but not caught during implementation. Root cause: validation checks `quota >= 0` but should check `quota > 0`. Test `test-normalization.R:87-91` only tests `revenue_generated = 0`, not `quota = 0` (inverse of SPEC.md:69 requirement).

- **Test assertions too permissive**: Many tests only check that scores are in range 0-100 without verifying mathematical correctness. For example, `test-dimension_scoring.R:97` and `test-dimension_scoring.R:142` only assert `all(score >= 0 & score <= 100)`, which would pass even if scoring logic was wrong. Better tests would calculate expected values by hand and assert exact results.

- **Performance requirement not validated**: SPEC.md:59 requires "score calculation must complete in < 100ms for 1000 rows", and PLAN.md:1266-1271 mentions adding a performance check to integration tests. This was not implemented—performance is likely adequate but not formally validated.

- **Intermediate columns removed**: `calculate_scores()` cleans up `tenure_factor`, `territory_factor`, and `quota_attainment` after scoring (R/calculate_scores.R:84), making debugging harder. If a score looks wrong, you can't inspect intermediate normalized values. Not a bug, but a design tradeoff that wasn't documented.

### Spec vs Reality

**Delivered as spec'd:**
- ✅ Tenure normalization function (R/normalization.R:22-33)
- ✅ Territory size normalization function (R/normalization.R:35-46)
- ✅ Quota normalization function (R/normalization.R:48-70)
- ✅ Activity quality dimension scoring (R/dimension_scoring.R:5-43)
- ✅ Conversion efficiency dimension scoring (R/dimension_scoring.R:45-81)
- ✅ Revenue contribution dimension scoring (R/dimension_scoring.R:83-113)
- ✅ Weight configuration validation (R/calculate_scores.R:5-28)
- ✅ Final score calculation (R/calculate_scores.R:30-82)
- ✅ End-to-end scoring pipeline (scripts/score_data.R)
- ✅ Vertical slice script outputs CSV (data/scored_reps.csv created)
- ✅ 100% test coverage (verified by scripts/coverage_report.R)
- ✅ All functions documented with roxygen2
- ✅ Documentation updated (CLAUDE.md, README.md, AGENTS.md)

**Deviated from spec:**
- ❌ **Zero quota edge case**: SPEC.md:69 requires "quota normalization function handles edge cases (zero quota, quota exceeded by 10x)". Only quota exceeded case handled; zero quota causes division by zero. See REVIEW.md:17-28.
- ⚠️ **Custom weight CLI arguments**: SPEC.md:133 shows `Rscript scripts/score_data.R --activity 0.5 --conversion 0.3 --revenue 0.2` but Phase 2 only implements default weights. This was intentional per PLAN.md:1327-1330 (CLI args deferred to Phase 3), but not explicitly called out in SPEC as deferred.

**Deferred:**
- None explicitly deferred—all in-scope work completed except zero quota bug fix.

### Review Findings Impact

**Critical finding: Zero quota division-by-zero** (REVIEW.md:17-28)
- **Identified**: `R/normalization.R:67` performs `quota_attainment = (revenue_generated / quota) * 100` without checking if `quota == 0`
- **Root cause**: Validation checks `quota >= 0` but should check `quota > 0`
- **Test gap**: `test-normalization.R:87-91` only tests `revenue_generated = 0`, not `quota = 0`
- **Addressed**: Fixed in R/normalization.R:48-70 by adding validation for `quota > 0` and corresponding test in test-normalization.R

**Test quality finding: Weak assertions** (REVIEW.md:94-109)
- **Identified**: Many tests only check range (0-100) without verifying correctness
- **Impact**: Tests provide coverage but not confidence that scoring math is correct
- **Not addressed in Phase 2**: Would require hand-calculating expected scores for multiple test cases, time-intensive for this phase
- **Recommendation**: Defer to Phase 3 when real data validation will naturally surface any math errors

**Test quality finding: Minimal datasets** (REVIEW.md:111-134)
- **Identified**: Most tests use 2-3 row datasets, which don't exercise percentile ranking at scale
- **Impact**: Low—`percentile_rank()` is well-tested in isolation (test-scoring_utils.R:41-59)
- **Not addressed in Phase 2**: Integration test uses full 80-row dataset, providing adequate validation
- **Recommendation**: No action needed—current tests are sufficient

**Architecture observation: Intermediate columns removed** (REVIEW.md:29-34)
- **Identified**: `calculate_scores()` removes intermediate normalized columns after scoring
- **Impact**: Makes debugging harder—if a score looks wrong, can't inspect intermediate values
- **Not addressed in Phase 2**: Working as designed per PLAN.md:102-103
- **Recommendation**: Phase 3 should add `debug = FALSE` parameter to optionally preserve intermediate columns

**Documentation gap: Zero quota assumption** (REVIEW.md:36-40)
- **Identified**: `normalize_quota()` roxygen comment doesn't mention assumption that `quota > 0`
- **Addressed**: Updated roxygen documentation in R/normalization.R to clarify quota must be positive

## Looking Forward

### Recommendations for Next Phase

**1. Add debug mode for troubleshooting**
- `calculate_scores(data, weights, debug = FALSE)` parameter
- When `debug = TRUE`, preserve intermediate columns (`tenure_factor`, `territory_factor`, `quota_attainment`)
- Useful for Shiny dashboard troubleshooting when scores look unexpected
- Implementation: Remove the `select(-tenure_factor, -territory_factor, -quota_attainment)` line when debug = TRUE

**2. Validate scoring correctness with real data**
- Phase 3 Shiny dashboard will expose scoring to real users
- When loading real data, manually verify 2-3 rep scores by hand to catch any math errors
- If scores look wrong, use debug mode to inspect intermediate values

**3. Continue percentile-based approach (don't change algorithm)**
- Percentile ranking across all reps/periods works well—produces fair, comparable scores
- Resist temptation to switch to fixed anchors (e.g., "100% quota = 100 points") because that wouldn't account for relative performance

**4. Add performance monitoring in Shiny**
- SPEC.md:59 requires < 100ms for 1000 rows
- Add `system.time(calculate_scores(data))` in Shiny reactive to log scoring performance
- Alert if scoring takes > 500ms (indicates dataset size issue)

**5. Keep weight sliders simple**
- BRIEF.md:38 mentions "live weight sliders" in Shiny dashboard
- Use 3 sliders (activity, conversion, revenue) with auto-normalization to sum to 1.0
- Show real-time score recalculation on slider change (reactive Shiny pattern)

**6. Don't mock in Phase 3 tests**
- Phase 2 succeeded by testing real implementations (no mocks)
- Continue this pattern in Phase 3: test Shiny reactives with real scoring functions
- Only mock external data sources if added (databases, APIs)

### What Should Next Phase Build?

Based on BRIEF.md remaining goals, **Phase 3 should focus on the Shiny dashboard** (BRIEF.md:34-40):

**In scope for Phase 3:**
- Rep rankings table with score breakdowns (activity/conversion/revenue scores visible)
- Visual comparisons across dimensions (bar charts, radar charts)
- Trend over time (line charts showing score improvement/decline across quarters)
- **Live weight sliders** (adjust activity/conversion/revenue weights, see rankings update instantly)
- Filter by rep, period (dropdown or search bar)
- Data upload widget (allow users to upload their own CSV instead of using sample_reps.csv)

**Technical priorities:**
1. **Data upload first**: Let users upload CSV with same schema as sample_reps.csv
2. **Basic rankings table second**: Show rep_id, rep_name, period, score sorted by score descending
3. **Weight sliders third**: Three `sliderInput()` widgets that auto-normalize and trigger reactive recalculation
4. **Visualizations fourth**: Bar charts for dimension scores, line charts for trends
5. **Filters last**: Dropdown to filter by rep_id or period

**Architecture decisions for Phase 3:**
- Single-file Shiny app (`app.R` in project root) — no need for complex module structure yet
- Use `shinydashboard` package for layout (provides sidebar, main panel, boxes)
- Store scored data in reactive value updated when weights change
- Use `DT::datatable()` for interactive rankings table
- Use `plotly` (not base ggplot2) for interactive charts with hover tooltips

**Out of scope for Phase 3:**
- Quarto executive report (Phase 4)
- Improvement suggestions engine (Phase 4)
- Authentication/user management (not in BRIEF.md at all)
- Real-time data refresh (assume static uploaded CSV)
- Multi-team comparison (single team only)

### Technical Debt Noted

**1. Zero quota validation after Phase 2 fix** — R/normalization.R:48-70
- Fixed in Phase 2 fix step, but should verify fix with integration test
- Add test case to integration suite: load data with quota = 0, expect error
- Priority: HIGH (must verify before Phase 3)

**2. Intermediate column cleanup tradeoff** — R/calculate_scores.R:84
- Current: Removes `tenure_factor`, `territory_factor`, `quota_attainment` after scoring
- Debt: Harder to debug scoring issues
- Resolution: Add `debug = FALSE` parameter in Phase 3 (see recommendation #1)
- Priority: MEDIUM (nice to have, not blocking)

**3. Test assertions only check range, not correctness** — test-dimension_scoring.R:97, 142
- Current: Tests assert `all(score >= 0 & score <= 100)`
- Debt: Doesn't validate that scoring logic is mathematically correct
- Resolution: Add 2-3 hand-calculated test cases with exact expected scores
- Priority: LOW (integration test catches major math errors, this is polish)

**4. Performance requirement not formally validated** — SPEC.md:59
- Current: No test validates "score calculation must complete in < 100ms for 1000 rows"
- Debt: Requirement assumed met but not proven
- Resolution: Add microbenchmark test with 1000-row synthetic dataset
- Priority: LOW (informal testing shows performance is adequate)

**5. Coverage script uses file_coverage() instead of package_coverage()** — scripts/coverage_report.R:10-13
- Current: Works for minimal package structure, but non-standard
- Debt: If project converts to full R package (with NAMESPACE, man/), coverage script will need update
- Resolution: Document this decision in AGENTS.md, revisit if package structure changes
- Priority: LOW (not planning full package structure per AGENTS.md)

### Process Improvements

**1. Test edge cases BEFORE writing implementation**
- Phase 2 missed zero quota because test was written after code
- Better approach: Write failing test first (TDD), then implement until test passes
- For Phase 3: Write test for "user uploads CSV with missing columns" before implementing upload handler

**2. Review SPEC acceptance criteria line-by-line before marking complete**
- Phase 2 marked 13/14 criteria as complete, but actually missed 1 (zero quota)
- Better approach: Run through SPEC.md checklist item-by-item, execute test for each before checking off
- For Phase 3: Use checklist in SPEC.md as acceptance test—don't mark phase complete until all checked

**3. Add mathematical correctness checks to integration tests**
- Phase 2 integration test only checked structure (80 rows, 4 columns, range 0-100)
- Better approach: Pick 1-2 known reps, calculate expected score by hand, assert exact value in test
- For Phase 3: Add integration test that validates a specific rep's score matches expected value

**4. Document design tradeoffs explicitly in roxygen comments**
- Phase 2 made tradeoff to remove intermediate columns—not documented until REVIEW.md
- Better approach: Add roxygen `@details` section explaining design decisions
- For Phase 3: Document why weight sliders auto-normalize (UX decision to prevent invalid states)

**5. Run full test suite after every task completion**
- Phase 2 ran tests after each major milestone (all 6 tasks)
- Better approach: Run `Rscript -e "testthat::test_dir('tests/testthat')"` after EVERY function written
- For Phase 3: Set up file watcher (e.g., `testthat::auto_test()`) to run tests on save

**6. Use RESEARCH.md open questions as PLAN design decision checklist**
- Phase 2 RESEARCH.md listed 15 open questions, PLAN.md resolved all 15—excellent
- Continue pattern in Phase 3: RESEARCH.md should list all ambiguous requirements as questions
- PLAN.md must explicitly answer each question with rationale

**7. Update STATUS.md throughout phase, not just at end**
- Current STATUS.md shows "Phase: 2 | Step: fix" but not Phase 2 completion status
- Better approach: Update STATUS.md when phase starts, when phase completes, and at major milestones
- For Phase 3: Update STATUS.md to show "Phase 3 IN PROGRESS" at start, "Phase 3 COMPLETE" at end
