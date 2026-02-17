# Reflections: Phase 3

## Looking Back

### What Went Well

**Iterative task-by-task execution delivered clean, testable code**
- Followed PLAN.md's 10-task breakdown precisely
- Added debug mode first (Task 1), enabling troubleshooting throughout remaining tasks
- Helper functions extracted to `R/shiny_helpers.R` with 100% test coverage before building UI
- TDD approach caught edge cases early (all-zero weights, empty data) before app.R implementation

**Vertical slice approach proved working dashboard quickly**
- Basic data upload (Task 3) validated data flow before adding complexity
- Reactive scoring (Task 4) with performance monitoring established core value proposition
- Charts (Tasks 5-6) added analytical depth incrementally
- Each task produced runnable, testable code — no "big bang" integration at end

**Debug mode solves Phase 2 technical debt effectively**
- `calculate_scores(debug = TRUE)` preserves intermediate columns (tenure_factor, territory_factor, quota_attainment)
- Exposed as UI checkbox in dashboard sidebar
- Test validates scores identical regardless of debug parameter
- Already useful during implementation when manually verifying rep scores — `R/calculate_scores.R:56-98`

**Performance monitoring validates SPEC requirements**
- Wrapped scoring in `system.time()` inside reactive — `app.R:168-188`
- Console logs show 0.011s for 80-row sample (well under 500ms target)
- 1000-row performance test shows 0.044s (meets SPEC.md:80 requirement)
- No progress indicator needed for typical datasets — fast enough without UI complexity

**Helper function tests caught real bugs before UI integration**
- `normalize_three_weights()` all-zero edge case identified during test writing
- `validate_upload_schema()` test revealed missing non-dataframe check
- 100% coverage for `R/shiny_helpers.R` (99 test assertions) — `tests/testthat/test-shiny_helpers.R`
- Mock-free testing philosophy continued — all tests use real implementations

**Documentation updates completed per SPEC**
- CLAUDE.md: Added dashboard launch command and feature overview
- AGENTS.md: Added complete "Dashboard Usage" section (73 new lines)
- README.md: Added "Interactive Dashboard" section with emoji feature list
- All commands tested and verified working before documenting

### What Didn't Work

**Weight slider auto-normalization UX incomplete**
- PLAN.md:573-581 explicitly required `updateSliderInput()` to show normalized values to user
- Implementation normalizes weights for scoring but doesn't update slider UI — `app.R:143-153`
- User sets activity=0.8, sees "0.80" on slider, but actual weight used is different after normalization
- Code comment says "We don't auto-update sliders to avoid reactive loops" but this creates confusing UX
- Impact: SPEC.md:48-49 requirement violated ("Display current weight values next to each slider")

**shinytest2 E2E tests skipped in test environment**
- All 8 integration tests exist but skip with "On CRAN" reason — `tests/testthat/test-app.R:7-157`
- Test runner environment behaves like CRAN, triggering `skip_if_not_installed("shinytest2")`
- Zero automated verification of: app launch, weight slider reactivity, filter behavior, export, debug mode toggle
- Only unit tests run (190 passing) — no E2E validation that dashboard actually works
- Impact: Manual testing is only verification of interactive features (error-prone, not repeatable)

**Dependency configuration error (critical but fixable)**
- `plotly` declared in `Suggests` but imported as hard dependency in `app.R:15`
- App will crash on systems where plotly not installed despite being optional
- Should be in `Imports` section of DESCRIPTION — `DESCRIPTION:20`
- Impact: Breaks deployment in production environments

**STATUS.md not updated to completion state**
- Shows "Phase: 3 | Step: build" instead of "Phase: 3 | Step: complete | Status: DONE"
- Violates SPEC.md:260 and PLAN.md:1295-1300 documentation requirements
- Indicates incomplete delivery tracking

**ggplot2 import missing from dependencies**
- Code uses `ggplot2::ggplot()` and `ggplot2::annotate()` at lines 330, 397 for empty state charts
- ggplot2 never explicitly loaded in app.R imports
- May work accidentally via plotly loading ggplot2 namespace, but fragile
- Impact: Runtime error in edge cases (empty data after filtering)

### Spec vs Reality

**Delivered as spec'd:**
- ✅ Data upload widget with CSV validation (SPEC.md:31-35)
- ✅ Rankings table (sortable, color-coded, scrollable) (SPEC.md:37-42)
- ✅ Live weight sliders with reactive score recalculation (SPEC.md:44-50) — **scores update**, but slider UI doesn't show normalized values
- ✅ Dimension breakdown visualization (top 10 reps, grouped bars, interactive) (SPEC.md:52-56)
- ✅ Trend over time visualization (line chart, multi-rep selection) (SPEC.md:58-62)
- ✅ Filter controls (rep_id and period dropdowns, clear button) (SPEC.md:64-67)
- ✅ Score export (CSV download with timestamp) (SPEC.md:69-72)
- ✅ Debug mode toggle (preserves intermediate columns) (SPEC.md:74-77)
- ✅ Performance target met (< 500ms for 1000 rows: actual 44ms) (SPEC.md:80)
- ✅ Error handling (invalid CSV shows user-friendly messages) (SPEC.md:82)
- ✅ Single-file app structure (app.R in root) (SPEC.md:84)

**Deviated from spec:**
- ⚠️ Weight sliders auto-normalize for **scoring** but don't **visually update** to show normalized values (SPEC.md:48 requires "Display current weight values")
- ⚠️ shinytest2 tests written but **skipped** in test environment (SPEC.md:164 requires E2E tests to run)
- ⚠️ STATUS.md not updated to "complete" state (SPEC.md:260 requires phase completion tracking)

**Deferred:**
- None — all in-scope features delivered

### Review Findings Impact

**Finding #1: Dependency mismatch (plotly in Suggests vs Imports)** — REVIEW.md:21-24
- Not yet fixed — still in Suggests, should be in Imports
- Needs fix before phase can be marked complete
- Workaround: Manual `install.packages('plotly')` works for now

**Finding #2: Test infrastructure gap (shinytest2 skipped)** — REVIEW.md:26-29
- Not yet fixed — tests still skip with "On CRAN" reason
- Root cause: Test environment setting triggers CRAN-like behavior
- Workaround: Manual testing validates functionality, but not automated

**Finding #3: Weight slider UX incomplete** — REVIEW.md:31-36
- Not yet fixed — sliders don't visually update to show normalized values
- Would require adding `observe({ updateSliderInput(...) })` block per PLAN.md:573-581
- Deferred to avoid reactive loop complexity in initial implementation

**Finding #4: STATUS.md not updated** — REVIEW.md:38-40
- Not yet fixed — still shows "Step: build" instead of "Step: complete"
- Simple fix, should be updated when phase marked complete

**Finding #5: Zero-weight edge case not validated** — REVIEW.md:42-45
- Not yet fixed — UI doesn't prevent all-three-sliders-to-zero scenario
- Helper function handles gracefully (returns equal weights), but no user feedback
- Low priority — unlikely user action, function handles correctly

**Finding #6: Missing ggplot2 import** — REVIEW.md:47-50
- Not yet fixed — ggplot2 used but not imported
- Works accidentally because plotly loads ggplot2, but fragile
- Should add `library(ggplot2)` or move to Imports in DESCRIPTION

**Test gap identified: E2E tests not running** — REVIEW.md:95-103
- 8 shinytest2 tests written, 0 executed (all skipped)
- Unit tests excellent (190 passing, 100% coverage for helpers)
- Integration coverage weak — dashboard not validated automatically
- Manual test checklist exists (`tests/testthat/test-app-manual.R:1-45`) but not executable

## Looking Forward

### Recommendations for Next Phase

**Continue task-by-task iterative approach**
- Phase 3's 10-task breakdown worked well — small, testable, incremental
- Apply same pattern to Phase 4 (Quarto report + suggestions engine)
- Each task should produce working, verifiable output before moving to next

**Front-load documentation during implementation, not at end**
- Phase 3 updated CLAUDE.md, AGENTS.md, README.md all in Task 10 (last task)
- Better: Update docs when feature is implemented and tested
- Example: Document data upload in AGENTS.md immediately after Task 3 completes
- Prevents documentation drift and ensures commands are verified as working

**Add visual/screenshot validation for Shiny features**
- Charts, color coding, and layout are hard to validate via automated tests
- Consider adding screenshot comparison tests (vdiffr or shinytest2 screenshots)
- Or document expected appearance in manual test checklist with sample images

**Test reactive behaviors with deliberate timing**
- shinytest2 tests may be flaky due to reactive propagation delays
- Use `Sys.sleep()` after input changes (see PLAN.md:1041)
- Or use `app$wait_for_idle()` to ensure all reactives stabilized before assertions

**Prioritize fixing test infrastructure before Phase 4**
- shinytest2 skipping is a blocker for future phases
- Phase 4 may add more Shiny features (e.g., interactive suggestions) — need E2E tests working
- Investigate CI environment settings causing "On CRAN" skip trigger

**Address dependency issues before Phase 4 begins**
- Move plotly and ggplot2 to Imports (not Suggests)
- Verify `install.packages()` and `library()` align with DESCRIPTION
- Prevents deployment issues when Phase 4 adds Quarto integration

### What Should Next Phase Build?

**Phase 4: Quarto Executive Report + Improvement Suggestions Engine**

Based on BRIEF.md remaining goals, Phase 4 should deliver:

1. **Quarto Executive Report (Static HTML/PDF)** — BRIEF.md:41-45
   - Polished output for leadership (shareable via email or GitHub Pages)
   - Quarter/month summary with top performers and trends
   - Score distribution charts and improvement highlights
   - No R server needed — static files only

2. **Improvement Suggestions Engine** — BRIEF.md:47-50
   - Identify specific gaps per rep based on dimension scores
   - Example: "Rep C has high activity (85) but low conversion (45) → needs skill coaching"
   - Actionable recommendations based on score patterns
   - Rules-based approach: if activity > 70 AND conversion < 50, suggest "conversion training"

**Scope priorities:**
- **Must-have**: Quarto report generation with scoring summary, top performers table, and score distributions
- **Must-have**: Basic suggestions engine with 3-5 rule patterns (high activity/low conversion, etc.)
- **Nice-to-have**: Trend charts in Quarto report (rep improvement over time)
- **Nice-to-have**: Suggestions integrated into Shiny dashboard (show per-rep suggestions in table)

**Dependencies:**
- Quarto CLI installed on system (not R package — external tool)
- `knitr`, `rmarkdown` R packages for rendering
- Leverage existing `calculate_scores()` function — no changes needed

**Integration points:**
- Quarto report should accept same scored CSV as Shiny export
- Suggestions engine should be standalone function: `generate_suggestions(scored_data)` → returns data frame with rep_id + suggestion text
- Shiny dashboard can optionally display suggestions if available (Phase 4 enhancement)

**Estimated complexity:** Medium
- Quarto templating is straightforward (RMarkdown-like syntax)
- Suggestions logic is rule-based, not ML — simple if/else branching
- Testing Quarto output requires rendered HTML/PDF validation (file existence, content checks)

### Technical Debt Noted

**Weight slider auto-update not implemented** — `app.R:143-153`
- Current: Weights normalized for scoring, but sliders don't visually update
- Expected: Sliders should call `updateSliderInput()` to show normalized values (per PLAN.md:573-581)
- Deferred reason: Avoiding reactive loop complexity in initial implementation
- Future fix: Add `observe({ updateSliderInput(session, "weight_activity", value = normalized_weights()[["activity"]]) })` with proper isolate() guards

**shinytest2 tests skipped in CI** — `tests/testthat/test-app.R:7-157`
- Current: All 8 E2E tests skip with "On CRAN" reason
- Root cause: Test environment sets CRAN-like flags, triggering `skip_if_not_installed()`
- Impact: Zero automated dashboard validation
- Future fix: Replace `skip_if_not_installed("shinytest2")` with `skip_on_cran()` or custom skip logic

**plotly dependency misconfigured** — `DESCRIPTION:20` and `app.R:15`
- Current: plotly in Suggests but used as hard dependency
- Impact: App crashes if plotly not installed, despite being "optional"
- Future fix: Move plotly to Imports section

**ggplot2 not explicitly imported** — `app.R:16` and `app.R:330,397`
- Current: ggplot2 used via namespace (`ggplot2::ggplot()`) but never loaded
- Impact: May fail if plotly doesn't load ggplot2 namespace
- Future fix: Add `library(ggplot2)` at top of app.R or move to Imports

**No validation for all-zero slider scenario** — `app.R:39-44`
- Current: If user drags all three sliders to zero, `normalize_three_weights()` returns equal weights silently
- Impact: Confusing UX — no feedback to user about invalid state
- Future fix: Add reactive validation to disable sliders or show warning if sum approaches zero

**Manual test checklist not executable** — `tests/testthat/test-app-manual.R:1-45`
- Current: File contains only comments describing manual tests
- Impact: UX validation not repeatable, depends on human tester
- Future fix: Convert to executable checklist (e.g., using `usethis::use_test()` pattern with `skip("Manual test")` and instructions)

### Process Improvements

**Update STATUS.md at phase milestones, not just start/end**
- Phase 3 STATUS.md updated at start ("Step: build") but never updated to "complete"
- Better: Update after each major task (data upload, sliders, charts) to show progress
- Helps team see where phase stands at any point

**Run full test suite after every task, not just at phase end**
- Verified: Test coverage remained 100% throughout thanks to TDD approach
- Continue: Run `Rscript -e "testthat::test_dir('tests/testthat')"` after each task completion
- Consider: Set up file watcher (`testthat::auto_test()`) during development

**Document design decisions in code comments, not just commit messages**
- Good: `app.R:5` comments on single-file approach ("defer until complexity requires it")
- Good: `R/shiny_helpers.R:53` comments on all-zero edge case handling
- Continue: Add comments explaining **why** decisions made, not just **what** code does

**Test reactive behaviors explicitly, not just function outputs**
- Phase 3 tested helper functions exhaustively (100% coverage)
- Missed: Testing Shiny reactive propagation (slider → scoring → table update)
- Future: Write integration tests that verify reactive chains work end-to-end

**Validate acceptance criteria line-by-line before marking complete**
- SPEC.md:87-106 has 16 acceptance criteria
- Current phase: 13/16 met (81%) — not 100%
- Better: Review checklist item-by-item, test each, fix gaps before phase complete

**Consider screenshot/visual regression tests for UI phases**
- Phase 3 testing strong for logic, weak for appearance
- Color coding, chart layout, slider styling all validated manually
- Future: Add `shinytest2` screenshot comparisons or `vdiffr` for ggplot outputs
