# Reflections: Phase 1

## Looking Back

### What Went Well

- **Clean greenfield start with solid foundation**: Created a minimal R package structure that balances simplicity with functionality. No legacy code to work around, no technical debt inherited.

- **Comprehensive documentation upfront**: AGENTS.md provides exact commands and clear project structure. New developers can be productive within minutes. The emphatic "READ THIS FIRST" approach in CLAUDE.md successfully establishes documentation hierarchy.

- **Test-driven approach delivered genuine coverage**: Achieved 100% line coverage with meaningful tests, not just happy-path assertions. Tests use real implementations with seeded randomness—no mock abuse, fast execution, deterministic results.

- **Realistic sample data generation**: The tenure-based performance model creates believable variance without hardcoding patterns. 30%/40%/30% rep profile distribution matches real org structures. Revenue tied to deals_closed with random factor creates correlation without determinism.

- **Iterative review-fix cycle worked**: REVIEW.md identified 5 critical issues and 3 minor issues. All were fixed systematically in MUST-FIX.md, with verification checkmarks confirming resolution. This caught problems early before they propagated to Phase 2.

### What Didn't Work

- **Test runner misconfiguration**: Initial `tests/testthat.R` tried to load `library(salesrepperformance)` despite using "minimal package structure" approach. This fundamental contradiction meant tests would fail in clean environments. Root cause: PLAN.md specified this approach (PLAN.md:273-277) without validating it against the minimal structure constraint.

- **Missing dependency declaration (rprojroot)**: Tests relied on `rprojroot::find_root()` but package wasn't declared in DESCRIPTION. This is a classic "works on my machine" problem—installation instructions didn't match actual dependencies. Caught by review but should have been prevented by dependency auditing during implementation.

- **Imprecise test assertions**: Initial type checks used `is.numeric()` for integer columns when implementation used `as.integer()`. Tests passed but didn't validate the intended type. This is test laziness—passing tests that don't actually prove correctness.

- **Weak profile distribution validation**: Test checked `>10%` representation when code targets 30%/40%/30%. A test that accepts 70%/10%/10% distribution doesn't validate the requirement. Classic case of "test exists but doesn't test what it claims."

- **.gitignore pollution from previous project**: Kept Node.js patterns (node_modules, dist, .astro, swimlanes.db) that have zero relevance to R project. PLAN.md explicitly chose to keep these (PLAN.md:142) which was a poor decision—cosmetically unprofessional and confusing for developers.

### Spec vs Reality

**Delivered as spec'd:**
- ✅ R project structure with R/, tests/, data/ directories
- ✅ DESCRIPTION file with dependencies (dplyr, tibble, purrr, testthat, covr, rprojroot)
- ✅ Data generation function `generate_sample_data()` with configurable parameters (n_reps, n_quarters, seed)
- ✅ Sample CSV with 80 rows (20 reps × 4 quarters) at data/sample_reps.csv
- ✅ 5 test cases (exceeds "at least 3" requirement) with 32 assertions
- ✅ 100% code coverage verified via scripts/coverage_report.R
- ✅ AGENTS.md with installation, commands, data model, conventions
- ✅ CLAUDE.md updated to reference AGENTS.md first
- ✅ README.md with getting started guide, tech stack, phase status

**Deviated from spec:**
- **Coverage tool**: Used `covr::file_coverage()` instead of `covr::package_coverage()` specified in PLAN.md:466. Functionally equivalent but inconsistent with plan. Reason: Implementation discovered `file_coverage()` was simpler for minimal package structure.
- **Test directory naming**: Used `tests/testthat/` (standard package structure) despite PLAN.md ambiguity about simpler `tests/` structure. This was the right call—standard structure is more maintainable.

**Deferred:**
- **Advanced edge case testing**: REVIEW.md noted missing tests for n_reps=0, n_quarters=0, negative inputs. These boundary conditions weren't in SPEC acceptance criteria but were identified as "minor" gaps. Deferred to future phases if needed.
- **Integration test for CSV generation script**: scripts/generate_data.R is tested manually but lacks automated end-to-end test. REVIEW.md noted this as "moderate" severity but not blocking. Deferred due to Phase 1 focus on function-level testing.
- **Error handling for invalid inputs**: No tests for non-numeric parameters or invalid seeds. R will error naturally, but graceful error messages weren't implemented. Out of scope for Phase 1.

### Review Findings Impact

- **Test runner fix (MUST-FIX Task 1)**: Removed `library(salesrepperformance)` from tests/testthat.R. Critical fix—tests now work in clean environments without package installation.

- **rprojroot dependency (MUST-FIX Task 2)**: Added rprojroot to DESCRIPTION Suggests. Updated all installation commands in AGENTS.md and README.md. This closed the "works on my machine" gap.

- **Integer type assertions strengthened (MUST-FIX Task 6)**: Changed `is.numeric()` to `is.integer()` for tenure_months, calls_made, followups_done, meetings_scheduled, deals_closed. Tests now validate intended types, not just permissive supersets.

- **Profile distribution test tightened (MUST-FIX Task 7)**: Replaced `>10%` checks with 20-40% (new), 30-50% (mid), 20-40% (exp) bounds. Added info messages with actual percentages for debugging. Test now validates requirement instead of accepting any skewed distribution.

- **.gitignore cleaned up (MUST-FIX Task 5)**: Removed all Node.js/JavaScript patterns. File now contains only R-specific patterns. Cosmetic but eliminates confusion.

- **Phase status corrected (MUST-FIX Task 4)**: CLAUDE.md, README.md, AGENTS.md all updated to show Phase 1 as COMPLETE. Documentation now accurately reflects project state.

- **@export tag removed (MUST-FIX Task 3)**: Removed misleading roxygen2 `@export` from R/generate_sample_data.R. Function is not actually exported (no NAMESPACE file). Documentation now matches reality.

## Looking Forward

### Recommendations for Next Phase

- **Validate test infrastructure early**: Before writing scoring functions in Phase 2, run a trivial test in a clean Docker container to prove testthat setup works end-to-end. Don't trust PLAN assumptions—validate them.

- **Declare all dependencies immediately**: When using a package function (even once), add it to DESCRIPTION immediately. Don't wait for review to catch missing dependencies. Use `desc::desc_get_deps()` to audit.

- **Write assertions that match intent**: If code uses `as.integer()`, test uses `is.integer()`. If distribution target is 30%/40%/30%, test validates ranges like 20-40%/30-50%/20-40%, not permissive `>10%`. Match test precision to requirement precision.

- **Consider error handling for user-facing functions**: Phase 2 scoring functions will be called by Shiny dashboard (Phase 3). Add `stopifnot()` or `rlang::abort()` with clear error messages for invalid inputs. Don't rely on R's default cryptic errors.

- **Keep documentation in sync during implementation**: Don't update CLAUDE.md/README.md/AGENTS.md only at the end. Update phase status as soon as work starts, so docs always reflect reality. Use git commits to track doc updates alongside code.

- **Use integration tests for multi-step workflows**: Phase 2 will combine data loading + normalization + scoring. Write tests that exercise the full pipeline, not just isolated functions. Catch integration bugs early.

### What Should Next Phase Build?

Based on BRIEF.md remaining goals, **Phase 2 should deliver the scoring engine**:

**Scope:**
- Normalization functions that adjust for tenure, territory_size, and opportunity volume
- Configurable weight system (activity quality, conversion efficiency, revenue contribution)
- Score calculation function that outputs 0-100 productivity scores per rep per period
- Comprehensive tests covering edge cases (zero activity, quota exceeded, veteran reps with low activity, new reps with high conversion)

**Out of scope for Phase 2:**
- No UI components (Shiny dashboard is Phase 3)
- No report generation (Quarto reports are Phase 4)
- No improvement suggestions logic (Phase 4)

**Priorities:**
1. **Normalization logic first**: Build tenure adjustment, territory size adjustment, quota normalization as separate testable functions before combining them.
2. **Weight configuration**: Implement as named vector or list (`weights = c(activity = 0.3, conversion = 0.4, revenue = 0.3)`) with validation that weights sum to 1.0.
3. **Score calculation**: Combine normalized metrics with weights to produce final score. Return tibble with `rep_id`, `period`, `score`, plus breakdown columns for debugging.
4. **Edge case handling**: Test what happens with all-zero activity, quota 10x exceeded, negative territory_size (should error gracefully).

**Vertical slice validation**: A runnable script that loads data/sample_reps.csv, calculates scores with default weights, and outputs a CSV with rep_id, period, score columns. This demonstrates end-to-end scoring without UI.

### Technical Debt Noted

- **No integration test for CSV generation script**: scripts/generate_data.R writes CSV but has no automated test. If someone modifies write.csv parameters (e.g., adds quote escaping), breakage won't be caught. **Risk: Low** (Phase 2 will read CSV, which indirectly validates format).

- **No boundary testing for edge inputs**: Tests validate happy path (n_reps=20, n_reps=1) but not error cases (n_reps=0, negative values, non-numeric inputs). R will error but messages may be cryptic. **Risk: Low** (Phase 1 functions are internal, not user-facing). Consider adding boundary tests if Phase 2 scoring functions expose similar parameters.

- **Data generation uses simple normal distributions**: Tenure-based performance uses `rnorm(mean = baseline + tenure * factor, sd = ...)` which is realistic but simplistic. Real sales data has outliers, seasonality, quota resets. **Risk: Low** (Phase 1 goal is "realistic sample data," not "production-grade data modeling"). Consider more sophisticated generation in Phase 3/4 if dashboards reveal unrealistic patterns.

- **Coverage report doesn't enforce threshold in CI**: scripts/coverage_report.R exits with status 1 if coverage < 100%, which is CI-ready. But there's no CI configuration yet (no .github/workflows/ or similar). **Risk: Low** (single developer, manual testing sufficient for now). Add CI in Phase 3 when Shiny integration tests require automated validation.

### Process Improvements

- **Review pass should happen BEFORE fixes**: The current flow was Implement → Review → Fix → Reflection. A better flow would be Implement → Review → Reflection → Fix, where Reflection analyzes review findings before prescribing fixes. This allows Reflection to comment on *whether fixes were appropriate*, not just *what was fixed*. For Phase 2, write REFLECTIONS.md before starting MUST-FIX tasks.

- **PLAN.md open questions need explicit resolution section**: PLAN.md ended with resolved questions in prose, but RESEARCH.md had 8 open questions that were answered implicitly during implementation. Add explicit "Open Questions Resolution" section to REFLECTIONS.md that maps RESEARCH.md questions to PLAN.md decisions. This creates audit trail.

- **Test PLAN assumptions before full implementation**: PLAN.md specified `library(salesrepperformance)` in tests/testthat.R without validating it worked with minimal package structure. Phase 2 should validate key architectural decisions (e.g., "can normalization work with grouped data?") with spike solutions before writing full implementation.

- **Document "why" for non-obvious decisions**: PLAN.md said "keep Node.js patterns in .gitignore" (PLAN.md:142) but didn't explain rationale. This made it harder to evaluate whether decision was intentional or oversight. Phase 2 plans should include brief "why" for decisions that future developers might question.
