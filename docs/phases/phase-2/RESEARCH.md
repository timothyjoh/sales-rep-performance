# Research: Phase 2

## Phase Context
Phase 2 builds the core scoring engine that calculates fair, bias-free productivity scores (0-100) for each sales rep. It implements normalization functions that adjust for tenure, territory size, and quota attainment, plus a configurable weight system to balance three scoring dimensions: activity quality, conversion efficiency, and revenue contribution. The deliverable is a working, testable pipeline from raw rep data to scored output, demonstrated via a vertical slice validation script that outputs a CSV with scores.

## Previous Phase Learnings

### Key Takeaways from Phase 1 Reflections
From `docs/phases/phase-1/REFLECTIONS.md`:

**Test Infrastructure Validation (REFLECTIONS.md:71-72)**
- Before writing scoring functions, validate test infrastructure works end-to-end with a trivial test
- Phase 1 had issues with `library(salesrepperformance)` in tests/testthat.R despite using minimal package structure — this was fixed
- Tests now use `source()` with `rprojroot::find_root()` to load R code directly — `tests/testthat/test-generate_sample_data.R:2`

**Dependency Management (REFLECTIONS.md:73-76)**
- Declare all dependencies immediately when using a package function
- Phase 1 missed rprojroot in DESCRIPTION initially, causing "works on my machine" problems
- All dependencies now properly declared in DESCRIPTION:18 Suggests section

**Precise Test Assertions (REFLECTIONS.md:77-79)**
- Match test precision to requirement precision
- If code uses `as.integer()`, test must use `is.integer()`, not permissive `is.numeric()`
- Phase 1 strengthened assertions: tenure_months, calls_made, followups_done, meetings_scheduled, deals_closed all validated with `is.integer()` — `tests/testthat/test-generate_sample_data.R:28-32`

**Error Handling for User-Facing Functions (REFLECTIONS.md:80-82)**
- Phase 2 scoring functions will be called by Shiny dashboard (Phase 3), so need clear error messages
- Use `stopifnot()` or `rlang::abort()` with descriptive messages for invalid inputs
- Test error messages explicitly: `expect_error(score_reps(bad_data), "tenure_months cannot be negative")`

**Documentation Sync During Implementation (REFLECTIONS.md:83-85)**
- Update phase status to "IN PROGRESS" when Phase 2 work starts
- Update to "COMPLETE" when acceptance criteria met, before writing REFLECTIONS.md
- Don't wait until end to update docs

**Integration Tests for Multi-Step Workflows (REFLECTIONS.md:86-88)**
- Write tests that call full pipelines: load data → normalize → score → validate output structure
- This catches integration bugs that unit tests miss (e.g., column name mismatches between functions)

**Validate PLAN Assumptions Early (REFLECTIONS.md:89-91)**
- Test mathematical assumptions with sample data before full implementation
- Document assumptions in roxygen comments (e.g., "assumes territory_size > 0")

## Current Codebase State

### Project Structure Overview
This is a **minimal R package** structure (not a full package with NAMESPACE/man/ directories). Current structure:

```
sales-rep-performance/
├── DESCRIPTION                     # Package metadata — declares dependencies
├── sales-rep-performance.Rproj     # RStudio project (BuildType: Package)
├── R/                              # Source code
│   └── generate_sample_data.R      # Data generation function (Phase 1)
├── tests/                          # Test suite
│   ├── testthat.R                  # Test runner entry point
│   └── testthat/
│       └── test-generate_sample_data.R  # Tests for data generation
├── scripts/                        # Executable scripts
│   ├── generate_data.R             # Generate sample CSV data
│   └── coverage_report.R           # Generate code coverage report
├── data/                           # Generated data files
│   └── sample_reps.csv             # Sample sales rep data (80 rows)
└── docs/                           # Documentation and phase planning
    └── phases/
        ├── phase-1/                # Phase 1 planning/review docs
        └── phase-2/                # Phase 2 (current phase)
            └── SPEC.md
```

### Relevant Components

#### Data Generation Function
**File:** `R/generate_sample_data.R` (84 lines)
**Function:** `generate_sample_data(n_reps = 20, n_quarters = 4, seed = 42)`

**Roxygen Documentation Pattern:** — `R/generate_sample_data.R:1-21`
- `#'` comment blocks above functions
- Required tags: `@param`, `@return`, `@examples`
- Multi-line descriptions with paragraph breaks
- Examples show both default and custom usage

**Implementation Details:**
- Uses `set.seed()` for reproducibility — `R/generate_sample_data.R:23`
- Creates rep profiles with tenure-based distribution (30% new/40% mid/30% exp) — `R/generate_sample_data.R:26-28`
- Generates quarterly data using `purrr::map_dfr()` — `R/generate_sample_data.R:46`
- Tenure affects performance: higher tenure → higher baseline activity — `R/generate_sample_data.R:52-53, 57-58`
- Activity metrics use `rnorm()` with tenure-scaled means and fixed standard deviations
- Integer columns coerced with `as.integer(round(...))` wrapped in `pmax(0L, ...)` to prevent negatives — `R/generate_sample_data.R:50-69`
- Revenue tied to deals_closed with quota-based scaling and random factor — `R/generate_sample_data.R:70-72`
- Column reordering ensures spec-compliant output — `R/generate_sample_data.R:77-82`

**Key Pattern for Phase 2:** All tidyverse pipes use native pipe `|>` (not magrittr `%>%`)

#### Sample Data Output
**File:** `data/sample_reps.csv` (81 lines: 1 header + 80 data rows)
**Structure:** 20 reps × 4 quarters (Q1-2025 through Q4-2025)

**Data Model (11 columns):**
| Column               | Type      | Range/Format              | Notes                              |
|----------------------|-----------|---------------------------|------------------------------------|
| rep_id               | character | REP001-REP020             | Sprintf format: REP%03d            |
| rep_name             | character | "Rep A" - "Rep T"         | Cycles through alphabet            |
| tenure_months        | integer   | 1-120                     | Determines experience level        |
| calls_made           | integer   | 0-200+                    | Higher for experienced reps        |
| followups_done       | integer   | 0-100+                    | Correlated with tenure             |
| meetings_scheduled   | integer   | 0-50+                     | Correlated with tenure             |
| deals_closed         | integer   | 0-20+                     | Correlated with tenure             |
| revenue_generated    | numeric   | 0-200000+                 | Tied to deals_closed × quota/10    |
| quota                | numeric   | 50000/75000/100000/150000 | Four discrete quota levels         |
| territory_size       | numeric   | 50-500                    | Uniform random distribution        |
| period               | character | Q1-2025, Q2-2025, etc.    | Format: Q[1-4]-YYYY                |

**Sample Data Observations:**
- Some reps have zero activity in specific quarters (e.g., REP002 Q3-2025: 0 meetings, 0 deals, $0 revenue) — useful edge case for Phase 2
- Quota values are discrete (50k/75k/100k/150k), not continuous — simplifies quota normalization
- Territory_size varies widely (50-500 accounts) — significant normalization factor
- Tenure ranges from 1 month (REP007, REP009) to 77 months (REP019) — good spread for tenure normalization

#### Test Infrastructure
**Test Runner:** `tests/testthat.R` (5 lines)
- Uses standard testthat entry point: `library(testthat)` then `test_check("salesrepperformance")`
- NOTE: This is standard package test structure, but actual test files use `source()` to load code directly

**Test File:** `tests/testthat/test-generate_sample_data.R` (83 lines)
**Test Framework:** testthat 3rd edition — `DESCRIPTION:17`
**Test Count:** 5 test_that blocks with 32 total assertions

**Test Loading Pattern:** — `tests/testthat/test-generate_sample_data.R:1-2`
```r
library(testthat)
source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "generate_sample_data.R"))
```
This pattern will be used for Phase 2 test files — avoids package installation, works with minimal structure

**Test Organization Pattern:**
- One `test_that("description", { ... })` block per test scenario
- Multiple `expect_*()` assertions within each block (average 6-7 per test)
- Descriptive test names with clear intent

**Test Assertion Patterns:**
- **Row count validation:** `expect_equal(nrow(df), expected)` — `test-generate_sample_data.R:6, 9, 12`
- **Column existence:** `expect_equal(names(df), expected_cols)` — `test-generate_sample_data.R:23`
- **Type checking:** `expect_type()` for character, `expect_true(is.integer())` for integers, `expect_true(is.numeric())` for numeric — `test-generate_sample_data.R:25-35`
- **Range validation:** `expect_true(all(df$column >= min))` — `test-generate_sample_data.R:41-53`
- **Pattern matching:** `expect_true(all(grepl("regex", df$column)))` — `test-generate_sample_data.R:54`
- **Reproducibility:** `expect_identical(df1, df2)` for same seed, `expect_false(identical(...))` for different seeds — `test-generate_sample_data.R:61, 64`
- **Distribution checks with tolerance:** Range checks with informative messages — `test-generate_sample_data.R:76-81`

**Coverage Pattern:**
- 100% line coverage achieved for Phase 1 — verified by `scripts/coverage_report.R`
- Coverage script uses `covr::file_coverage()` (not `package_coverage()` — intentional for minimal structure)
- Coverage threshold enforced: script exits with status 1 if coverage < 100% — `scripts/coverage_report.R:20-22`

#### Scripts
**Script Pattern:** Both scripts have shebang `#!/usr/bin/env Rscript` and use `source("R/...")` to load code

**`scripts/generate_data.R`** (22 lines):
- Sources data generation function — `scripts/generate_data.R:6`
- Creates `data/` directory if missing — `scripts/generate_data.R:11-13`
- Writes CSV with `write.csv(..., row.names = FALSE)` — `scripts/generate_data.R:16`
- Prints summary with `cat()` and `summary()` — `scripts/generate_data.R:8, 18-21`

**`scripts/coverage_report.R`** (26 lines):
- Uses `covr::file_coverage()` with explicit source_files and test_files lists — `scripts/coverage_report.R:10-13`
- Prints coverage with `print(cov)` and `percent_coverage(cov)` — `scripts/coverage_report.R:15, 17-18`
- Exits with status 1 if coverage < 100% — `scripts/coverage_report.R:20-22`

### Existing Patterns to Follow

#### Code Style Conventions (from AGENTS.md and observed code)
- **Indentation:** 2 spaces (no tabs) — confirmed in `.Rproj:9-10`
- **Assignment:** Use `<-` for assignment, not `=` — observed throughout `R/generate_sample_data.R`
- **Piping:** Use native pipe `|>` (R 4.1+) — observed in `R/generate_sample_data.R:47, 77`
- **Naming:** Functions and variables use `snake_case` — all existing code follows this
- **Line length:** ~80 characters where practical — observed in existing code

#### Tidyverse Patterns
- **tibble construction:** `tibble::tibble(col1 = ..., col2 = ...)` with explicit namespace — `R/generate_sample_data.R:31`
- **dplyr verbs:** `dplyr::mutate()`, `dplyr::select()` with explicit namespace — `R/generate_sample_data.R:48, 78`
- **purrr iteration:** `purrr::map_dfr()` for row-binding mapped results — `R/generate_sample_data.R:46`
- **Column selection:** Use `dplyr::select()` at end to ensure column order matches spec

#### Function Documentation Pattern (roxygen2)
From `R/generate_sample_data.R:1-21`:
1. Start with one-line summary
2. Blank comment line
3. Detailed multi-paragraph description
4. Blank comment line
5. `@param` for each parameter with description
6. Blank comment line
7. `@return` describing output structure with column names
8. Blank comment line
9. `@examples` with 2-3 usage examples showing default and custom usage

**Note:** No `@export` tag used (Phase 1 removed it per REFLECTIONS.md:64-66) — functions are sourced, not exported via NAMESPACE

#### Error Prevention Patterns
- **Non-negative enforcement:** Wrap numeric generation in `pmax(0, ...)` or `pmax(0L, ...)` for integers — `R/generate_sample_data.R:50, 55, 60, 65, 70`
- **Integer coercion:** `as.integer(round(...))` to ensure integer type — `R/generate_sample_data.R:50, 55, 60, 65`
- **Reproducibility:** `set.seed(seed)` at function start — `R/generate_sample_data.R:23`

### Dependencies & Integration Points

#### Declared Dependencies
**File:** `DESCRIPTION` (18 lines)

**Imports (required dependencies):**
- `dplyr` — Data manipulation (mutate, select, filter, etc.)
- `tibble` — Modern data frames
- `purrr` — Functional programming (map functions)

**Suggests (development dependencies):**
- `testthat (>= 3.0.0)` — Testing framework, 3rd edition
- `covr` — Code coverage reporting
- `rprojroot` — Find project root directory (used in tests)

**Config:**
- `Config/testthat/edition: 3` — Enables testthat 3rd edition features

#### Phase 2 Dependency Considerations
From SPEC.md:159-163:
- **No new packages required** — tidyverse functions sufficient for normalization and scoring
- **Possible addition:** `checkmate` package for input validation (optional, only if validation becomes complex)

Current tidyverse imports should handle:
- Normalization: `dplyr::mutate()` for column transformations
- Grouping: `dplyr::group_by()` if needed for grouped normalization
- Weight validation: Base R functions sufficient
- Score calculation: `dplyr::mutate()` with arithmetic operations

#### Integration with Phase 1 Deliverables
**Input:** `data/sample_reps.csv` — generated by `scripts/generate_data.R`
- 80 rows (20 reps × 4 quarters)
- 11 columns matching data model
- Already includes tenure_months, territory_size, quota needed for normalization

**Expected Output (Phase 2):** `data/scored_reps.csv` — generated by new `scripts/score_data.R`
- Same 80 rows as input
- All original 11 columns preserved
- Plus 4 new columns: score, activity_score, conversion_score, revenue_score (per SPEC.md:208-212)

### Test Infrastructure Details

#### Test File Naming Convention
- Pattern: `test-<source_file_name>.R` — `AGENTS.md:129`
- Example: `test-generate_sample_data.R` tests `generate_sample_data.R`
- Expected Phase 2 files: `test-normalization.R`, `test-scoring.R` (per SPEC.md:87)

#### Test Organization Within Files
From `tests/testthat/test-generate_sample_data.R`:
- Multiple `test_that()` blocks per file (5 in Phase 1 test file)
- Each block tests one aspect (row count, column types, value ranges, reproducibility, distribution)
- Blocks contain 2-12 assertions each
- Use `info` parameter in `expect_*()` for helpful failure messages — `test-generate_sample_data.R:77-81`

#### Test Execution
**Command:** `Rscript -e "testthat::test_dir('tests/testthat')"`
**Output Format:** `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 32 ]` — concise summary line
**Current Status:** All 32 assertions pass (verified 2026-02-17)

#### Coverage Reporting
**Command:** `Rscript scripts/coverage_report.R`
**Output:** Per-file coverage percentages, overall percentage
**Current Coverage:** 100.0% for `R/generate_sample_data.R`
**Enforcement:** Script exits with status 1 if coverage < 100% — enables CI integration

### Data Model Deep Dive

#### Tenure Distribution (for normalization design)
From AGENTS.md:113-116:
- **30% new reps** — tenure 1-12 months (approximately 6 of 20 reps)
- **40% mid-level reps** — tenure 13-36 months (approximately 8 of 20 reps)
- **30% experienced reps** — tenure 37-120 months (approximately 6 of 20 reps)

Implementation distributes evenly via sampling — `R/generate_sample_data.R:34-38`

**Normalization Implication:** Tenure adjustment should have breakpoints or continuous scaling across this range

#### Activity Metrics Correlation with Tenure
From `R/generate_sample_data.R:50-69`:
- `calls_made`: mean = 80 + tenure_months * 0.5 (range: 80-140 for 0-120 months tenure)
- `followups_done`: mean = 40 + tenure_months * 0.3 (range: 40-76 for 0-120 months tenure)
- `meetings_scheduled`: mean = 15 + tenure_months * 0.2 (range: 15-39 for 0-120 months tenure)
- `deals_closed`: mean = 5 + tenure_months * 0.1 (range: 5-17 for 0-120 months tenure)

**Normalization Implication:** Experienced reps naturally have ~2x higher activity than new reps in sample data — tenure normalization must account for this to enable fair comparison

#### Quota Structure
From `R/generate_sample_data.R:39`:
- Four discrete levels: $50k, $75k, $100k, $150k
- Randomly assigned (uniform distribution across 4 levels)
- Used in revenue calculation: `revenue = deals_closed * (quota / 10) * random_factor(0.8, 1.2)`

**Normalization Implication:** Quota normalization likely converts revenue_generated to percentage of quota (revenue_generated / quota * 100)

#### Territory Size Range
From `R/generate_sample_data.R:40`:
- Range: 50-500 accounts
- Uniform random distribution via `runif(n_reps, min = 50, max = 500)`
- 10x difference between smallest and largest territories

**Normalization Implication:** Territory size adjustment likely involves dividing activity metrics by territory_size or similar proportional scaling

#### Edge Cases Present in Sample Data
From manual inspection of `data/sample_reps.csv`:
- **Zero activity quarters:** REP002 Q3-2025 has 0 meetings_scheduled, 0 deals_closed, $0 revenue
- **High performers:** REP011 Q1-2025 has 19 deals_closed, $142,501 revenue (exceeds $75k quota by 190%)
- **Low performers:** REP012 Q1-2025 has 1 deal_closed, $6,406 revenue (8.5% of $75k quota)
- **Tenure extremes:** REP007/REP009 have 1 month tenure, REP019 has 77 months tenure

**Testing Implication:** Phase 2 must handle these edge cases without errors or NaN/Inf values

## Code References

### Phase 1 Core Implementation
- `R/generate_sample_data.R:1-84` — Complete data generation function
- `R/generate_sample_data.R:22-83` — Function body with tenure-based performance model
- `R/generate_sample_data.R:46-74` — Quarterly data generation loop using purrr::map_dfr

### Documentation Patterns
- `R/generate_sample_data.R:1-21` — Roxygen2 documentation template (use for Phase 2 functions)
- `AGENTS.md:119-138` — Coding conventions section (style guide reference)
- `README.md:69-81` — Data model table (update with scored columns in Phase 2)

### Test Patterns
- `tests/testthat/test-generate_sample_data.R:1-2` — Test file header with source loading pattern
- `tests/testthat/test-generate_sample_data.R:4-13` — Row count validation pattern
- `tests/testthat/test-generate_sample_data.R:15-36` — Column existence and type checking pattern
- `tests/testthat/test-generate_sample_data.R:38-55` — Range validation pattern
- `tests/testthat/test-generate_sample_data.R:57-65` — Reproducibility testing pattern
- `tests/testthat/test-generate_sample_data.R:67-82` — Distribution validation with tolerance ranges

### Script Patterns
- `scripts/generate_data.R:1-22` — Executable script template (use for scripts/score_data.R)
- `scripts/coverage_report.R:10-13` — Coverage analysis setup using file_coverage()

### Dependency Management
- `DESCRIPTION:1-18` — Package metadata and dependency declarations
- `DESCRIPTION:9-12` — Imports section (tidyverse packages)
- `DESCRIPTION:13-16` — Suggests section (testing/coverage packages)

## Open Questions

### Normalization Function Design
1. **Tenure normalization approach:** Should tenure adjustment be linear (divide by tenure factor), categorical (bucket into new/mid/exp), or use a scaling curve? SPEC.md:37 mentions "scaled expectations" but doesn't specify formula.

2. **Territory normalization direction:** Should activity metrics be divided by territory_size (activity per account) or should territory_size act as a scaling factor? SPEC.md:38 says "adjust metrics by territory_size" but direction unclear.

3. **Quota exceeded handling:** SPEC.md:108 mentions "quota exceeded by 10x → capped or handled gracefully (document decision)". Should quota attainment percentage be capped at 100%, or allow 200%/300% for overachievers?

### Dimension Scoring Formulas
4. **Activity quality composite:** SPEC.md:42 says "composite of calls_made, followups_done, meetings_scheduled (normalized by tenure & territory)". What's the weighting within this composite? Equal thirds? Should meetings_scheduled count more than calls?

5. **Conversion efficiency calculation:** SPEC.md:43 mentions "meetings-to-deals ratio, revenue per activity unit". How are these two metrics combined into one conversion_score? Weighted average? Separate sub-scores?

6. **Revenue contribution components:** SPEC.md:44 says "quota attainment percentage, revenue per deal closed". How are these combined? Which matters more?

7. **Score scaling to 0-100:** Should each dimension score be independently scaled to 0-100 based on its own range, or should there be fixed anchors (e.g., 100% quota = 100 points)?

### Weight System Implementation
8. **Weight input format:** SPEC.md:47 shows `c(activity = 0.3, conversion = 0.4, revenue = 0.3)`. Should weight system accept list, named vector, or separate parameters? How to validate names match expected dimensions?

9. **Default weights:** SPEC.md:49 says "default weights that balance all three dimensions equally". Does "equally" mean 0.33/0.33/0.34 (sums to 1.0), or is there a business reason to weight differently?

### Edge Case Handling
10. **Zero activity handling:** SPEC.md:54 says "all-zero activity should score 0, not error". Should zero activity across ALL dimensions score 0, or should dimensions with zero activity score 0 individually while others score normally?

11. **Missing required columns:** SPEC.md:110 says "error listing which columns are missing". Should this be a comma-separated list, or one error per missing column? What's the exact error message format?

### Function Architecture
12. **Normalization function granularity:** Should there be one normalize_metrics() function that does all three normalizations, or separate normalize_tenure(), normalize_territory(), normalize_quota() functions?

13. **Grouped data handling:** SPEC.md:60 says "functions must handle grouped data (multiple periods per rep) correctly". Should scoring functions accept grouped tibbles and preserve grouping, or expect ungrouped data and work row-by-row?

14. **Function return structure:** Should dimension scoring functions return just the score column, or return a tibble with the score plus intermediate calculations for debugging (e.g., normalized_calls, normalized_meetings)?

### Vertical Slice Script
15. **Custom weight CLI arguments:** SPEC.md:133 shows `Rscript scripts/score_data.R --activity 0.5 --conversion 0.3 --revenue 0.2`. Should script parse command-line args, or should Phase 2 just implement default weights and Phase 3 adds CLI args?

These questions should be addressed during PLAN.md creation, with decisions documented in the plan rationale.
