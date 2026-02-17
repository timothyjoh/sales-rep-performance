# Implementation Plan: Phase 1

## Overview
Establish R project foundation with minimal package structure, generate reproducible sample sales rep data for 20 reps across 4 quarters, configure testthat with code coverage, and create comprehensive documentation enabling any developer to immediately work with the project.

## Current State (from Research)
- **Brand new, empty repository** — only documentation scaffolding exists (BRIEF.md, SPEC.md, README.md placeholder)
- **No R code exists** — all directories (R/, tests/, data/) and files must be created from scratch
- **CLAUDE.md contains incorrect content** — references "SwimLanes" (a Trello kanban app) with npm commands; must be completely replaced
- **R is not installed on the system** — developer must install R 4.0+ before proceeding
- **No existing code patterns to follow** — this is a greenfield R project

## Desired End State
After Phase 1 completion:
- Minimal R package structure with DESCRIPTION file (enables testthat and covr integration)
- `R/generate_sample_data.R` containing tested data generation function
- `data/sample_reps.csv` with 80 rows (20 reps × 4 quarters) of realistic sample data
- Full test suite (≥3 tests) with 100% code coverage
- AGENTS.md, CLAUDE.md, and README.md documentation enabling immediate onboarding
- All tests passing, no errors/warnings

**Verification:**
1. Run `Rscript -e "testthat::test_dir('tests')"` → All tests pass
2. Run `Rscript -e "source('R/generate_sample_data.R'); df <- generate_sample_data(); nrow(df)"` → Returns 80
3. Open `data/sample_reps.csv` in Excel/spreadsheet app → Data looks realistic
4. Run `Rscript -e "covr::file_coverage('R/generate_sample_data.R', 'tests/testthat/test-generate_sample_data.R')"` → 100% coverage

## What We're NOT Doing
- **No scoring logic** — Phase 2 only
- **No normalization or statistical algorithms** — Phase 2 only
- **No UI components** — No Shiny dashboard (Phase 3), no Quarto reports (Phase 4)
- **No data validation beyond basic type checks** — Complex validation is out of scope
- **No external data sources** — All data is generated programmatically
- **No database integration** — CSV file output only
- **Not creating a full-featured R package** — Using minimal package structure (DESCRIPTION + R/ + tests/) to enable testthat/covr, but no NAMESPACE, no exports, no vignettes
- **Not installing R for the user** — Documentation assumes R 4.0+ already installed

## Implementation Approach

### Structural Decision: Minimal Package Structure
**Rationale:** Based on research ([R Packages testing guide](https://r-pkgs.org/testing-basics.html)), testthat requires a minimal package structure to function properly:
- DESCRIPTION file (for dependency declaration)
- R/ directory (for source code)
- tests/testthat/ directory (for tests)
- tests/testthat.R (test runner script)

This is simpler than a full R package (no NAMESPACE, no exports, no vignettes) but provides the infrastructure needed for testthat and covr integration. The `package_coverage()` function works with this minimal structure.

### Coverage Strategy
Using `covr::package_coverage()` which works with the minimal package structure described above. This is simpler than `file_coverage()` and provides better integration with the package structure.

### Data Generation Design
`generate_sample_data()` function signature:
```r
generate_sample_data <- function(n_reps = 20, n_quarters = 4, seed = 42)
```
- **Parameters:** Configurable for testing flexibility, with sensible defaults matching SPEC requirements
- **Seed default (42):** Ensures reproducibility while being a recognizable default
- **Output:** Returns a tibble (tidyverse data frame) with 11 required columns

### Testing Philosophy
- **Anti-mock bias:** No mocking needed — data generation is self-contained
- **Fast, deterministic tests:** Seeded RNG ensures tests are reproducible
- **Comprehensive coverage:** Test data shape, types, ranges, and reproducibility

---

## Task 1: Create Minimal R Package Structure

### Overview
Initialize the R project with minimal package structure (DESCRIPTION + .Rproj + directories) and configure .gitignore for R-specific patterns.

### Changes Required

**File**: `DESCRIPTION`
**Changes**: Create new file with minimal package metadata:
```r
Package: salesrepperformance
Title: Sales Rep Performance Scoring System
Version: 0.1.0
Authors@R: person("Developer", "Team", email = "dev@example.com", role = c("aut", "cre"))
Description: Sales rep productivity scoring system with fair, bias-free performance metrics.
License: MIT + file LICENSE
Encoding: UTF-8
LazyData: true
Imports:
    dplyr,
    tibble
Suggests:
    testthat (>= 3.0.0),
    covr
Config/testthat/edition: 3
```
- **Imports:** tidyverse packages needed for `generate_sample_data()` (dplyr for piping, tibble for data frames)
- **Suggests:** testthat 3e and covr for testing/coverage (not required to run the code, only for testing)
- **Config/testthat/edition: 3:** Enables testthat 3rd edition features

**File**: `sales-rep-performance.Rproj`
**Changes**: Create R project configuration file:
```
Version: 1.0

RestoreWorkspace: Default
SaveWorkspace: Default
AlwaysSaveHistory: Default

EnableCodeIndexing: Yes
UseSpacesForTab: Yes
NumSpacesForTab: 2
Encoding: UTF-8

RnwWeave: Sweave
LaTeX: pdfLaTeX

BuildType: Package
PackageUseDevtools: Yes
PackageInstallArgs: --no-multiarch --with-keep.source
```
- **Standard R project settings** with 2-space indentation (tidyverse style)
- **BuildType: Package:** Enables package development features in RStudio

**File**: `.gitignore`
**Changes**: Add R-specific patterns (append to existing file):
```gitignore
# R specific
.Rproj.user/
.Rhistory
.RData
.Ruserdata
*.Rproj.user/

# R package build artifacts
*.tar.gz
*.zip
/man/
/Meta/

# covr output
coverage.html
```
- **Keep existing Node.js patterns** — they don't interfere with R project (may be from pipeline tooling)
- **Add R session artifacts** (.Rhistory, .RData) that should not be committed

**Directories to create:**
- `R/` — Source code directory
- `tests/` — Test directory (parent)
- `tests/testthat/` — testthat tests directory
- `data/` — CSV output directory

### Success Criteria
- [ ] `DESCRIPTION` file exists with valid package metadata
- [ ] `.Rproj` file exists and can be opened in RStudio
- [ ] `.gitignore` includes R-specific patterns
- [ ] Directories `R/`, `tests/`, `tests/testthat/`, `data/` exist
- [ ] Running `Rscript -e "library(desc); desc::desc()"` successfully parses DESCRIPTION

---

## Task 2: Implement Data Generation Function

### Overview
Create `generate_sample_data()` function that produces realistic sales rep activity data with proper data types, realistic value ranges, and mix of rep profiles (new/experienced, high/low performers).

### Changes Required

**File**: `R/generate_sample_data.R`
**Changes**: Create new file with data generation function:
```r
#' Generate Sample Sales Rep Data
#'
#' Creates realistic sales rep activity data for testing and demos.
#' Generates data for multiple reps across multiple quarters with varying
#' performance profiles (new/experienced reps, high/low activity levels).
#'
#' @param n_reps Number of sales reps to generate (default: 20)
#' @param n_quarters Number of quarters to generate data for (default: 4)
#' @param seed Random seed for reproducibility (default: 42)
#'
#' @return A tibble with columns: rep_id, rep_name, tenure_months, calls_made,
#'   followups_done, meetings_scheduled, deals_closed, revenue_generated,
#'   quota, territory_size, period
#'
#' @examples
#' # Generate default dataset (20 reps, 4 quarters)
#' data <- generate_sample_data()
#'
#' # Generate smaller dataset for testing
#' data <- generate_sample_data(n_reps = 5, n_quarters = 2, seed = 123)
#'
#' @export
generate_sample_data <- function(n_reps = 20, n_quarters = 4, seed = 42) {
  set.seed(seed)

  # Generate rep profiles (tenure determines experience level)
  rep_profiles <- tibble::tibble(
    rep_id = sprintf("REP%03d", 1:n_reps),
    rep_name = sprintf("Rep %s", LETTERS[1:n_reps %% 26 + 1]),
    tenure_months = sample(c(
      sample(1:12, n_reps * 0.3, replace = TRUE),      # 30% new reps (0-1 year)
      sample(13:36, n_reps * 0.4, replace = TRUE),     # 40% mid-level (1-3 years)
      sample(37:120, n_reps * 0.3, replace = TRUE)     # 30% experienced (3-10 years)
    ), n_reps),
    quota = sample(c(50000, 75000, 100000, 150000), n_reps, replace = TRUE),
    territory_size = round(runif(n_reps, min = 50, max = 500))
  )

  # Generate quarterly data for each rep
  quarters <- sprintf("Q%d-2025", 1:n_quarters)

  data <- purrr::map_dfr(quarters, function(quarter) {
    rep_profiles |>
      dplyr::mutate(
        period = quarter,
        # Activity levels influenced by tenure (experienced reps slightly more efficient)
        calls_made = pmax(0, round(rnorm(n_reps,
          mean = 80 + tenure_months * 0.5,
          sd = 20))),
        followups_done = pmax(0, round(rnorm(n_reps,
          mean = 40 + tenure_months * 0.3,
          sd = 15))),
        meetings_scheduled = pmax(0, round(rnorm(n_reps,
          mean = 15 + tenure_months * 0.2,
          sd = 8))),
        deals_closed = pmax(0, round(rnorm(n_reps,
          mean = 5 + tenure_months * 0.1,
          sd = 3))),
        # Revenue tied to deals closed and quota level
        revenue_generated = pmax(0, round(
          deals_closed * (quota / 10) * runif(n_reps, 0.8, 1.2)
        ))
      )
  })

  # Reorder columns to match spec
  data |>
    dplyr::select(
      rep_id, rep_name, tenure_months, calls_made, followups_done,
      meetings_scheduled, deals_closed, revenue_generated, quota,
      territory_size, period
    )
}
```

**Key Design Decisions:**
- **Tenure-based performance**: Experienced reps have slightly higher activity means (realistic without being deterministic)
- **Realistic variance**: Using `rnorm()` with standard deviations creates natural performance distribution
- **No negative values**: Using `pmax(0, ...)` ensures all counts/revenue ≥ 0
- **Rep profiles mixed across dataset**: 30% new, 40% mid-level, 30% experienced matches realistic org structure
- **Revenue tied to deals**: Revenue calculation based on `deals_closed * (quota/10) * random_factor` creates correlation without making it deterministic
- **Column order matches SPEC**: Explicit `select()` ensures output matches documented data model

### Success Criteria
- [ ] File `R/generate_sample_data.R` exists
- [ ] Function signature matches: `generate_sample_data(n_reps = 20, n_quarters = 4, seed = 42)`
- [ ] Running `Rscript -e "source('R/generate_sample_data.R'); df <- generate_sample_data(); str(df)"` shows 11 columns
- [ ] Running with default params returns 80 rows (20 reps × 4 quarters)
- [ ] No warnings or errors during execution

---

## Task 3: Write Comprehensive Test Suite

### Overview
Create test suite with ≥3 tests covering data shape, column types, value ranges, and reproducibility. Achieve 100% code coverage.

### Changes Required

**File**: `tests/testthat.R`
**Changes**: Create test runner script:
```r
# This file is part of the standard testthat setup
# It runs all tests in tests/testthat/ when R CMD check is executed
library(testthat)
library(salesrepperformance)

test_check("salesrepperformance")
```
- **Standard testthat entry point** — required for package testing workflow

**File**: `tests/testthat/test-generate_sample_data.R`
**Changes**: Create comprehensive test file:
```r
library(testthat)
source("../../R/generate_sample_data.R")

test_that("generate_sample_data produces correct number of rows", {
  # Test default parameters
  df_default <- generate_sample_data()
  expect_equal(nrow(df_default), 80)  # 20 reps × 4 quarters

  # Test custom parameters
  df_custom <- generate_sample_data(n_reps = 5, n_quarters = 2)
  expect_equal(nrow(df_custom), 10)  # 5 reps × 2 quarters

  # Test edge case: single rep, single quarter
  df_minimal <- generate_sample_data(n_reps = 1, n_quarters = 1)
  expect_equal(nrow(df_minimal), 1)
})

test_that("generate_sample_data contains all required columns with correct types", {
  df <- generate_sample_data()

  # Check column names
  expected_cols <- c(
    "rep_id", "rep_name", "tenure_months", "calls_made", "followups_done",
    "meetings_scheduled", "deals_closed", "revenue_generated", "quota",
    "territory_size", "period"
  )
  expect_equal(names(df), expected_cols)

  # Check column types
  expect_type(df$rep_id, "character")
  expect_type(df$rep_name, "character")
  expect_type(df$tenure_months, "double")
  expect_type(df$calls_made, "double")
  expect_type(df$followups_done, "double")
  expect_type(df$meetings_scheduled, "double")
  expect_type(df$deals_closed, "double")
  expect_type(df$revenue_generated, "double")
  expect_type(df$quota, "double")
  expect_type(df$territory_size, "double")
  expect_type(df$period, "character")
})

test_that("generate_sample_data produces realistic value ranges", {
  df <- generate_sample_data()

  # Non-negative constraints
  expect_true(all(df$tenure_months >= 0))
  expect_true(all(df$calls_made >= 0))
  expect_true(all(df$followups_done >= 0))
  expect_true(all(df$meetings_scheduled >= 0))
  expect_true(all(df$deals_closed >= 0))
  expect_true(all(df$revenue_generated >= 0))
  expect_true(all(df$quota > 0))
  expect_true(all(df$territory_size > 0))

  # Realistic upper bounds (sanity checks)
  expect_true(all(df$tenure_months <= 120))  # Max 10 years tenure
  expect_true(all(df$calls_made <= 500))     # Reasonable quarterly max
  expect_true(all(df$deals_closed <= 50))    # Reasonable quarterly max

  # Period format check
  expect_true(all(grepl("^Q[1-4]-2025$", df$period)))
})

test_that("generate_sample_data is reproducible with same seed", {
  df1 <- generate_sample_data(seed = 123)
  df2 <- generate_sample_data(seed = 123)

  # Identical output with same seed
  expect_identical(df1, df2)

  # Different output with different seed
  df3 <- generate_sample_data(seed = 456)
  expect_false(identical(df1, df3))
})

test_that("generate_sample_data includes mix of rep profiles", {
  df <- generate_sample_data(n_reps = 30)  # Larger sample for profile distribution

  # Check tenure distribution (should have new, mid, and experienced reps)
  new_reps <- sum(df$tenure_months <= 12) / nrow(df)
  mid_reps <- sum(df$tenure_months > 12 & df$tenure_months <= 36) / nrow(df)
  exp_reps <- sum(df$tenure_months > 36) / nrow(df)

  # Each category should have some representation (at least 10%)
  expect_true(new_reps > 0.1)
  expect_true(mid_reps > 0.1)
  expect_true(exp_reps > 0.1)
})
```

**Test Coverage Breakdown:**
1. **Test 1 (Row count):** Validates function handles different parameter values correctly
2. **Test 2 (Columns):** Ensures data model compliance (all 11 columns present with correct types)
3. **Test 3 (Value ranges):** Validates data realism (no negative values, reasonable upper bounds, period format)
4. **Test 4 (Reproducibility):** Critical for demos and debugging — same seed = same data
5. **Test 5 (Rep profiles):** Ensures mix of experience levels exists (business requirement)

**Why no mocks:** Data generation is self-contained with no external dependencies (no APIs, no file I/O in function itself, no database calls). All randomness is controlled via seeded RNG. Real implementation testing is faster and more reliable than mocking.

### Success Criteria
- [ ] File `tests/testthat.R` exists
- [ ] File `tests/testthat/test-generate_sample_data.R` exists with ≥5 test cases
- [ ] Running `Rscript -e "testthat::test_dir('tests')"` executes all tests
- [ ] All tests pass with 0 failures
- [ ] No warnings or errors during test execution

---

## Task 4: Generate and Save Sample CSV Data

### Overview
Create executable R script that generates sample data and saves to CSV, producing the tangible deliverable artifact for Phase 1.

### Changes Required

**File**: `scripts/generate_data.R`
**Changes**: Create data generation script:
```r
#!/usr/bin/env Rscript

# Generate Sample Sales Rep Data
# Outputs: data/sample_reps.csv

# Source the data generation function
source("R/generate_sample_data.R")

# Generate default dataset (20 reps, 4 quarters)
cat("Generating sample sales rep data...\n")
sample_data <- generate_sample_data(n_reps = 20, n_quarters = 4, seed = 42)

# Ensure data directory exists
if (!dir.exists("data")) {
  dir.create("data", recursive = TRUE)
}

# Write to CSV
output_path <- "data/sample_reps.csv"
write.csv(sample_data, output_path, row.names = FALSE)

cat(sprintf("✓ Generated %d rows of sample data\n", nrow(sample_data)))
cat(sprintf("✓ Saved to: %s\n", output_path))
cat("\nSummary:\n")
print(summary(sample_data))
```

**Design Decisions:**
- **Executable script** with shebang (`#!/usr/bin/env Rscript`) for command-line usage
- **Hardcoded seed (42):** Ensures `data/sample_reps.csv` is always identical (critical for reproducibility)
- **Directory creation:** Script creates `data/` if it doesn't exist (idempotent)
- **Summary output:** Prints data summary for immediate verification
- **No function parameters:** Script uses defaults from SPEC (20 reps, 4 quarters)

### Success Criteria
- [ ] File `scripts/generate_data.R` exists and is executable
- [ ] Running `Rscript scripts/generate_data.R` creates `data/sample_reps.csv`
- [ ] CSV file contains 80 rows + header row
- [ ] CSV file has 11 columns matching data model
- [ ] Opening CSV in Excel/Google Sheets shows realistic data
- [ ] Running script twice produces identical CSV (reproducibility check)

---

## Task 5: Configure Code Coverage Reporting

### Overview
Verify covr integration works with minimal package structure and document coverage command in AGENTS.md.

### Changes Required

**File**: `scripts/coverage_report.R`
**Changes**: Create coverage reporting script:
```r
#!/usr/bin/env Rscript

# Generate Code Coverage Report
# Requires: covr package installed

library(covr)

cat("Running code coverage analysis...\n\n")

# Calculate coverage for the package
cov <- package_coverage()

# Print coverage summary to console
print(cov)

# Generate HTML report
output_file <- "coverage.html"
report(cov, file = output_file)

cat(sprintf("\n✓ Coverage report saved to: %s\n", output_file))
cat("✓ Open in browser to view detailed coverage\n")

# Get overall coverage percentage
coverage_pct <- percent_coverage(cov)
cat(sprintf("\nOverall coverage: %.1f%%\n", coverage_pct))

# Exit with error if coverage < 100%
if (coverage_pct < 100) {
  cat("\n✗ Coverage is below 100%\n")
  quit(status = 1)
} else {
  cat("\n✓ Coverage target met (100%)\n")
}
```

**Why this approach:**
- **package_coverage():** Works with minimal package structure (DESCRIPTION + R/ + tests/)
- **HTML report:** Provides visual line-by-line coverage inspection
- **Coverage threshold:** Enforces 100% coverage requirement from SPEC
- **Exit status:** Non-zero exit if coverage fails (enables CI/CD integration later)

### Success Criteria
- [ ] File `scripts/coverage_report.R` exists
- [ ] Running `Rscript scripts/coverage_report.R` generates `coverage.html`
- [ ] Coverage report shows 100% coverage for `R/generate_sample_data.R`
- [ ] Opening `coverage.html` in browser displays line-by-line coverage
- [ ] Script exits with status 0 (success)

---

## Task 6: Create AGENTS.md Developer Guide

### Overview
Write comprehensive developer onboarding documentation covering installation, project structure, running code, running tests, coverage reporting, data model, and coding conventions.

### Changes Required

**File**: `AGENTS.md`
**Changes**: Create complete developer guide:
```markdown
# Sales Rep Performance — Developer Guide

This document contains all project conventions, setup instructions, and commands needed to work on this project. **Read this FIRST before making any changes.**

## Project Overview
A sales rep productivity scoring system built in R. Generates fair, bias-free performance scores that normalize across experience levels (new vs senior reps). Currently in Phase 1: foundational data generation.

## Tech Stack
- **R 4.0+** — Core language
- **tidyverse** — Data wrangling (dplyr, tibble, purrr)
- **testthat** — Unit testing framework (3rd edition)
- **covr** — Code coverage reporting
- Future: Shiny (dashboard), Quarto (reports), ggplot2 (visualizations)

## Prerequisites
1. **R 4.0 or higher** installed
   - Check: `R --version`
   - Install: https://cloud.r-project.org/
2. **RStudio** (optional but recommended)
   - Install: https://posit.co/download/rstudio-desktop/

## Installation

### 1. Clone the repository
```bash
git clone <repo-url>
cd sales-rep-performance
```

### 2. Install R package dependencies
Open R or RStudio and run:
```r
# Install required packages
install.packages(c("dplyr", "tibble", "purrr", "testthat", "covr"))
```

Or from the project root directory:
```bash
Rscript -e "install.packages(c('dplyr', 'tibble', 'purrr', 'testthat', 'covr'))"
```

### 3. Verify installation
```bash
Rscript -e "library(dplyr); library(testthat); library(covr); cat('✓ All dependencies installed\n')"
```

## Project Structure

```
sales-rep-performance/
├── DESCRIPTION              # Package metadata and dependencies
├── sales-rep-performance.Rproj  # RStudio project file
├── R/                       # Source code
│   └── generate_sample_data.R   # Data generation function
├── tests/                   # Test suite
│   ├── testthat.R          # Test runner (standard testthat entry point)
│   └── testthat/
│       └── test-generate_sample_data.R  # Tests for data generation
├── scripts/                 # Executable scripts
│   ├── generate_data.R     # Generate sample CSV data
│   └── coverage_report.R   # Generate code coverage report
├── data/                    # Generated data files
│   └── sample_reps.csv     # Sample sales rep data (20 reps × 4 quarters)
├── docs/                    # Documentation and phase planning
│   └── phases/
│       └── phase-1/
│           ├── SPEC.md     # Phase 1 specification
│           ├── RESEARCH.md # Phase 1 codebase research
│           └── PLAN.md     # Phase 1 implementation plan
├── AGENTS.md               # This file — developer guide
├── CLAUDE.md               # Agent instructions (references this file)
├── BRIEF.md                # Project requirements and business context
└── README.md               # Getting started guide for end users
```

## Running the Project

### Generate sample data
```bash
Rscript scripts/generate_data.R
```
**Output:** `data/sample_reps.csv` (80 rows: 20 reps × 4 quarters)

**Verification:**
- Open `data/sample_reps.csv` in Excel/Google Sheets
- Should see 11 columns: rep_id, rep_name, tenure_months, calls_made, followups_done, meetings_scheduled, deals_closed, revenue_generated, quota, territory_size, period
- All numeric values should be ≥ 0
- Period values should be Q1-2025, Q2-2025, Q3-2025, Q4-2025

## Running Tests

### Run all tests
```bash
Rscript -e "testthat::test_dir('tests')"
```

### Run tests in RStudio
In RStudio, press `Ctrl+Shift+T` (Windows/Linux) or `Cmd+Shift+T` (Mac)

**Expected output:**
```
✔ | F W S  OK | Context
✔ |         5 | test-generate_sample_data

══ Results ════════════════════════════════════════════
Duration: X.X s

[ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]
```

## Running Code Coverage

### Generate coverage report
```bash
Rscript scripts/coverage_report.R
```

**Output:**
- Console summary with overall coverage percentage
- `coverage.html` file with detailed line-by-line coverage

**Open in browser:**
```bash
open coverage.html  # macOS
xdg-open coverage.html  # Linux
start coverage.html  # Windows
```

**Coverage target:** 100% for all Phase 1 code (currently just `R/generate_sample_data.R`)

## Data Model

### Sales Rep Activity Data
**File:** `data/sample_reps.csv`
**Rows:** 80 (20 reps × 4 quarters)
**Columns:** 11

| Column               | Type      | Description                           | Constraints      |
|----------------------|-----------|---------------------------------------|------------------|
| `rep_id`             | character | Unique rep identifier (e.g., "REP001") | Non-empty string |
| `rep_name`           | character | Rep full name (e.g., "Rep A")         | Non-empty string |
| `tenure_months`      | numeric   | Months employed                       | ≥ 0, ≤ 120       |
| `calls_made`         | numeric   | Number of calls made in period        | ≥ 0              |
| `followups_done`     | numeric   | Number of follow-ups completed        | ≥ 0              |
| `meetings_scheduled` | numeric   | Number of meetings scheduled          | ≥ 0              |
| `deals_closed`       | numeric   | Number of deals closed                | ≥ 0              |
| `revenue_generated`  | numeric   | Dollar revenue generated              | ≥ 0              |
| `quota`              | numeric   | Rep sales quota (target revenue)      | > 0              |
| `territory_size`     | numeric   | Number of accounts/leads in territory | > 0              |
| `period`             | character | Time period (e.g., "Q1-2025")         | Format: Q[1-4]-YYYY |

### Rep Profile Mix
Sample data includes realistic mix of experience levels:
- **30% new reps** — tenure 1-12 months (still learning, lower activity/results)
- **40% mid-level reps** — tenure 13-36 months (competent, moderate activity/results)
- **30% experienced reps** — tenure 37-120 months (efficient, higher activity/results)

## Coding Conventions

### Style Guide
Follow the [tidyverse style guide](https://style.tidyverse.org/):
- **Indentation:** 2 spaces (no tabs)
- **Line length:** ≤ 80 characters where practical
- **Naming:**
  - Functions: `snake_case()` (e.g., `generate_sample_data()`)
  - Variables: `snake_case` (e.g., `rep_profiles`)
  - Constants: `SCREAMING_SNAKE_CASE` (rare in R)
- **Assignment:** Use `<-` for assignment, not `=`
- **Piping:** Use native pipe `|>` (R 4.1+) or magrittr pipe `%>%`

### Testing Conventions
- **Test file naming:** `test-<source_file_name>.R` (e.g., `test-generate_sample_data.R`)
- **Test organization:** Use `test_that("description", { ... })` blocks
- **Assertions:** Use testthat expectations (`expect_equal()`, `expect_true()`, etc.)
- **Anti-mock bias:** Prefer testing real implementations over mocking when possible
- **Coverage:** Aim for 100% line coverage

### Documentation Conventions
- **Function docs:** Use roxygen2 format with `#'` comments
- **Required sections:** `@param`, `@return`, `@examples`
- **In-code comments:** Explain *why*, not *what* (code should be self-documenting)

### Git Conventions
- **Commit messages:** Imperative mood (e.g., "Add data generation function" not "Added...")
- **Branch naming:** `feature/<description>`, `fix/<description>`, `docs/<description>`
- **No commits to main:** All changes via pull requests (when team > 1 person)

## Common Commands Cheatsheet

```bash
# Installation
Rscript -e "install.packages(c('dplyr', 'tibble', 'purrr', 'testthat', 'covr'))"

# Generate sample data
Rscript scripts/generate_data.R

# Run tests
Rscript -e "testthat::test_dir('tests')"

# Generate coverage report
Rscript scripts/coverage_report.R

# Check package metadata
Rscript -e "library(desc); desc::desc()"

# Interactive R session
R
> source("R/generate_sample_data.R")
> df <- generate_sample_data()
> str(df)
> View(df)
```

## Troubleshooting

### "Error: package 'dplyr' is not installed"
**Fix:** Run `install.packages("dplyr")` (or other missing package)

### "Error: Cannot open file 'R/generate_sample_data.R'"
**Fix:** Ensure you're running commands from the project root directory (where DESCRIPTION file is located)

### Tests fail with "could not find function 'generate_sample_data'"
**Fix:** Ensure `tests/testthat/test-generate_sample_data.R` includes `source("../../R/generate_sample_data.R")` at the top

### Coverage report shows < 100%
**Fix:** Add tests for uncovered code paths (see `coverage.html` for specific lines)

## Phase Status
**Current Phase:** Phase 1 — Project Foundation & Sample Data Generation
**Status:** Complete (all acceptance criteria met)

**Phase 1 Deliverables:**
- ✓ R project structure with minimal package setup
- ✓ Sample data generation function (`generate_sample_data()`)
- ✓ Test suite with 100% coverage (5 test cases)
- ✓ Sample CSV data file (`data/sample_reps.csv`)
- ✓ Complete documentation (AGENTS.md, CLAUDE.md, README.md)

**Next Phase:** Phase 2 — Scoring Engine with Normalization
```

### Success Criteria
- [ ] File `AGENTS.md` exists with all required sections
- [ ] Installation section provides exact commands for dependency installation
- [ ] Commands section documents exact test/coverage commands from SPEC
- [ ] Data model section lists all 11 columns with descriptions
- [ ] Coding conventions section references tidyverse style guide
- [ ] Troubleshooting section covers common setup issues
- [ ] Reading time < 10 minutes for experienced R developer

---

## Task 7: Update CLAUDE.md Agent Instructions

### Overview
Replace outdated CLAUDE.md content (currently references "SwimLanes" and npm) with emphatic instruction to read AGENTS.md first, plus brief project description.

### Changes Required

**File**: `CLAUDE.md`
**Changes**: Replace entire file content:
```markdown
# Sales Rep Performance — Agent Instructions

**CRITICAL: Read AGENTS.md IMMEDIATELY FIRST for all project conventions, setup instructions, and commands.**

## Project Description
Sales rep productivity scoring system built in R. Generates fair, bias-free performance scores that normalize across experience levels (new reps vs experienced reps). Delivers interactive Shiny dashboard and static Quarto reports.

## Quick Command Reference
All commands are documented in detail in AGENTS.md. Quick reference:

### Run Tests
```bash
Rscript -e "testthat::test_dir('tests')"
```

### Generate Coverage Report
```bash
Rscript scripts/coverage_report.R
```

### Generate Sample Data
```bash
Rscript scripts/generate_data.R
```

## Development Workflow
1. **Always read AGENTS.md before starting work** — it contains complete project conventions
2. **Run tests after every change** — test-driven development expected
3. **Verify coverage remains 100%** — no untested code allowed
4. **Follow tidyverse style guide** — 2-space indentation, snake_case naming
5. **Document all functions with roxygen2 comments** — @param, @return, @examples required

## Phase Approach
This project follows an iterative phase-based development approach:
- **Phase 1** (current): Data model + sample data + project scaffolding
- **Phase 2**: Scoring engine with normalization + configurable weights
- **Phase 3**: Shiny dashboard with rankings and live weight adjustment
- **Phase 4**: Quarto reports + improvement suggestions engine

Refer to `BRIEF.md` for complete project requirements and `docs/phases/phase-N/SPEC.md` for phase-specific specifications.
```

**Key Changes:**
- **Emphatic opening:** "CRITICAL: Read AGENTS.md IMMEDIATELY FIRST" (addresses SPEC requirement)
- **Accurate project description:** Sales rep performance system, not SwimLanes kanban board
- **R commands, not npm:** References `Rscript`, not `npm test`
- **Quick reference section:** Provides commands from AGENTS.md without duplicating full docs
- **Development workflow:** Sets expectations for test-driven development and coverage

### Success Criteria
- [ ] File `CLAUDE.md` updated with new content
- [ ] No references to "SwimLanes" or "npm" remain
- [ ] Opening line emphasizes reading AGENTS.md first
- [ ] Commands are R/Rscript-based, not Node.js-based
- [ ] Brief project description accurately describes sales rep scoring system

---

## Task 8: Update README.md Getting Started Guide

### Overview
Transform minimal README.md placeholder into comprehensive getting started guide with project description, tech stack, installation steps, and Phase 1 deliverable overview.

### Changes Required

**File**: `README.md`
**Changes**: Replace entire file content:
```markdown
# Sales Rep Performance Scoring System

A fair, bias-free sales rep productivity scoring system built in R. Normalizes performance metrics across experience levels so new and senior reps can be fairly compared. Delivers interactive Shiny dashboards and static Quarto reports for managers and leadership.

## What It Does

### Core Features
- **Activity Tracking:** Tracks calls made, follow-ups, meetings scheduled, and deals closed per rep
- **Normalized Scoring:** Fair comparison across experience levels (adjusts for tenure, territory size)
- **Configurable Weights:** Adjustable scoring dimensions (activity quality, conversion efficiency, revenue contribution)
- **Interactive Dashboard:** Shiny app with rep rankings, score breakdowns, and live weight adjustment
- **Executive Reports:** Polished Quarto HTML/PDF reports for leadership (no R server needed)
- **Improvement Suggestions:** Identifies specific skill gaps and provides actionable coaching recommendations

### Business Value
- Removes bias from performance reviews
- Enables data-driven coaching decisions
- Fairly compares new reps vs experienced reps
- Identifies high-effort/low-result reps needing skill development vs low-effort reps needing motivation

## Tech Stack
- **R 4.0+** — Core language
- **tidyverse** — Data wrangling (dplyr, tibble, purrr)
- **ggplot2** — Data visualizations
- **Shiny** — Interactive dashboard (Phase 3)
- **Quarto** — Static reports (Phase 4)
- **testthat** — Unit testing with 100% coverage requirement
- **covr** — Code coverage reporting

## Getting Started

### Prerequisites
- **R 4.0 or higher** — [Download](https://cloud.r-project.org/)
- **RStudio** (optional but recommended) — [Download](https://posit.co/download/rstudio-desktop/)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd sales-rep-performance
   ```

2. **Install R dependencies**
   ```bash
   Rscript -e "install.packages(c('dplyr', 'tibble', 'purrr', 'testthat', 'covr'))"
   ```

3. **Verify installation**
   ```bash
   Rscript -e "library(dplyr); library(testthat); cat('✓ All dependencies installed\n')"
   ```

### Quick Start

**Generate sample data:**
```bash
Rscript scripts/generate_data.R
```
Output: `data/sample_reps.csv` (20 reps × 4 quarters = 80 rows)

**Run tests:**
```bash
Rscript -e "testthat::test_dir('tests')"
```

**Generate coverage report:**
```bash
Rscript scripts/coverage_report.R
open coverage.html  # View in browser
```

### Exploring the Data

Open `data/sample_reps.csv` in Excel, Google Sheets, or any spreadsheet app to see sample sales rep activity data:

| Column               | Description                          |
|----------------------|--------------------------------------|
| `rep_id`             | Unique rep identifier (e.g., REP001) |
| `rep_name`           | Rep full name                        |
| `tenure_months`      | Months employed                      |
| `calls_made`         | Number of calls in quarter           |
| `followups_done`     | Number of follow-ups completed       |
| `meetings_scheduled` | Number of meetings scheduled         |
| `deals_closed`       | Number of deals closed               |
| `revenue_generated`  | Dollar revenue generated             |
| `quota`              | Rep sales quota                      |
| `territory_size`     | Number of accounts in territory      |
| `period`             | Time period (Q1-2025, Q2-2025, etc.) |

Sample data includes mix of rep profiles: 30% new reps (low tenure), 40% mid-level, 30% experienced.

## Project Status

### Phase 1: Project Foundation & Sample Data Generation ✓ COMPLETE
**Delivered:**
- ✓ R project structure with minimal package setup (DESCRIPTION, .Rproj)
- ✓ Sample data generation function (`generate_sample_data()`)
- ✓ Comprehensive test suite with 100% code coverage (5 test cases)
- ✓ Sample CSV data file with 20 reps across 4 quarters
- ✓ Complete developer documentation (AGENTS.md)

### Phase 2: Scoring Engine (NEXT)
**Upcoming:**
- Normalization logic for fair cross-tenure comparison
- Configurable scoring weights (activity, conversion, revenue)
- Score calculation functions with comprehensive tests

### Phase 3: Shiny Dashboard
**Planned:**
- Interactive rep rankings with score breakdowns
- Visual comparisons across scoring dimensions
- Live weight sliders for instant ranking updates
- Filters by rep, team, time period

### Phase 4: Quarto Reports & Improvement Suggestions
**Planned:**
- Polished HTML/PDF executive reports
- Automated improvement suggestion engine
- Actionable coaching recommendations per rep

## Documentation

- **[AGENTS.md](AGENTS.md)** — Complete developer guide (setup, commands, conventions)
- **[BRIEF.md](BRIEF.md)** — Project requirements and business context
- **[CLAUDE.md](CLAUDE.md)** — Agent instructions for AI assistants
- **[docs/phases/](docs/phases/)** — Phase-specific specifications and plans

## Developer Quick Reference

```bash
# Generate sample data
Rscript scripts/generate_data.R

# Run tests
Rscript -e "testthat::test_dir('tests')"

# Generate coverage report
Rscript scripts/coverage_report.R

# Interactive R session
R
> source("R/generate_sample_data.R")
> df <- generate_sample_data()
> View(df)
```

For complete developer documentation, see **[AGENTS.md](AGENTS.md)**.

## License
MIT License (see LICENSE file)

## Contributing
This is a phase-based development project. Each phase must complete with 100% test coverage before moving to the next phase. See AGENTS.md for coding conventions and workflow.
```

**Key Sections:**
- **What It Does:** Business-focused feature description (from BRIEF.md)
- **Tech Stack:** Complete technology list
- **Getting Started:** Step-by-step installation for new developers
- **Quick Start:** Commands to immediately see results
- **Exploring the Data:** Visual table of data model (helps non-technical users)
- **Project Status:** Phase breakdown showing progress and upcoming work
- **Developer Quick Reference:** Fast command lookup (points to AGENTS.md for details)

### Success Criteria
- [ ] File `README.md` updated with comprehensive content
- [ ] Getting Started section provides step-by-step installation
- [ ] Phase 1 status marked as complete
- [ ] Data model table clearly explains all 11 columns
- [ ] Links to AGENTS.md, BRIEF.md, and phase docs work
- [ ] Reading time < 5 minutes for new developer to understand project scope

---

## Testing Strategy

### Unit Tests
**Coverage Target:** 100% for all R code in `R/` directory

**Key Test Scenarios:**
1. **Data shape validation** — Correct number of rows/columns for various parameters
2. **Column type checking** — All 11 columns have correct R types (character, numeric)
3. **Value range validation** — Non-negative constraints, realistic upper bounds
4. **Reproducibility** — Same seed produces identical output, different seeds differ
5. **Rep profile distribution** — Mix of new/mid/experienced reps exists in generated data

**Test Organization:**
- One test file per source file: `tests/testthat/test-generate_sample_data.R`
- Multiple test cases per file using `test_that()` blocks
- Each test case covers a specific requirement from SPEC.md

**Mocking Strategy:**
- **No mocks needed** — `generate_sample_data()` has no external dependencies
- **No file I/O mocks** — CSV generation happens in separate script, not in tested function
- **No API mocks** — No external services called
- **Seeded RNG** — Randomness is deterministic via `set.seed()`, no need to mock random functions

**Why no mocks?** Testing the real implementation is faster, more maintainable, and provides higher confidence than mocking. Mocks should only be used when:
- External dependencies are slow (network calls, database queries)
- External dependencies are flaky (third-party APIs)
- External dependencies have side effects (sending emails, charging credit cards)

None of these apply to Phase 1 code.

### Integration Tests
Not applicable for Phase 1 — no integration points yet (no database, no API, no UI). Phase 2+ will require integration testing when components interact.

### E2E Tests
Not applicable for Phase 1 — no user-facing features yet. Phase 3 (Shiny dashboard) will require E2E testing of UI workflows.

### Manual Verification
After implementation, manually verify:
1. **CSV inspection:** Open `data/sample_reps.csv` in Excel → data looks realistic
2. **Coverage report:** Open `coverage.html` → all lines green (100% coverage)
3. **Test output:** Run tests → 0 failures, all expectations met
4. **Documentation accuracy:** Follow AGENTS.md installation steps → works on clean machine

---

## Risk Assessment

### Risk: R not installed on developer machine
**Impact:** Cannot run any R code, blocking all development
**Probability:** Medium (many developers don't have R pre-installed)
**Mitigation:**
- AGENTS.md provides clear R installation links
- Prerequisites section in README.md emphasizes R 4.0+ requirement
- Installation verification step (`R --version`) catches this early

### Risk: Package dependency conflicts
**Impact:** Tests fail due to incompatible package versions
**Probability:** Low (using stable CRAN packages with wide version compatibility)
**Mitigation:**
- DESCRIPTION file pins testthat to version >= 3.0.0 (ensures testthat 3rd edition)
- Future: Use `renv` for lockfile-based reproducible environments (Phase 2+)

### Risk: Generated data not realistic enough
**Impact:** Phase 2 scoring engine gets misleading test results
**Probability:** Low (data generation includes variance and tenure-based performance)
**Mitigation:**
- Manual CSV inspection during Task 4 (success criteria includes "data looks realistic")
- Test case validates rep profile distribution (new/mid/experienced mix)
- Future: Add more sophisticated data generation in Phase 2 if needed

### Risk: Coverage tool doesn't work with minimal package structure
**Impact:** Cannot verify 100% coverage requirement
**Probability:** Very Low (covr's `package_coverage()` works with minimal DESCRIPTION + R/ + tests/ structure per research)
**Mitigation:**
- Task 5 explicitly tests coverage reporting works
- Fallback: Use `file_coverage()` if `package_coverage()` fails (documented in research)

### Risk: Documentation too long/complex for quick onboarding
**Impact:** Developers skip reading AGENTS.md, miss critical conventions
**Probability:** Medium (comprehensive docs can be overwhelming)
**Mitigation:**
- CLAUDE.md emphasizes "Read AGENTS.md FIRST" in opening line
- AGENTS.md structured with "Common Commands Cheatsheet" for quick lookup
- README.md provides "Quick Start" section for immediate results (< 5 commands)

### Risk: Tests pass locally but CSV generation script fails
**Impact:** Deliverable artifact (`data/sample_reps.csv`) not created
**Probability:** Low (script uses same function as tests)
**Mitigation:**
- Task 4 success criteria includes "Running script twice produces identical CSV"
- Script includes error handling (directory creation, summary output)

### Risk: tidyverse packages not available on CRAN
**Impact:** Dependency installation fails
**Probability:** Very Low (tidyverse is most popular R meta-package, stable for years)
**Mitigation:**
- Using individual packages (dplyr, tibble, purrr) instead of meta-package `tidyverse`
- Provides more granular control and smaller dependency footprint

---

## Open Questions Resolution

Based on research conducted ([R Packages testing guide](https://r-pkgs.org/testing-basics.html), [covr documentation](https://covr.r-lib.org/)), all open questions from RESEARCH.md have been resolved:

1. **R Project Structure** → **RESOLVED:** Use minimal package structure (DESCRIPTION + R/ + tests/) per research. This enables testthat and covr without full package overhead (no NAMESPACE, no exports, no vignettes).

2. **Directory Naming** → **RESOLVED:** Use `tests/testthat/` (standard package structure) per testthat best practices. The command `testthat::test_dir('tests')` discovers tests in `tests/testthat/`.

3. **Function Scope** → **RESOLVED:** `generate_sample_data(n_reps = 20, n_quarters = 4, seed = 42)` — parameters enable testing flexibility while defaults match SPEC requirements.

4. **Git Ignore Patterns** → **RESOLVED:** Keep existing Node.js patterns (they don't interfere, may be used by pipeline tooling), add R-specific patterns (`.Rproj.user/`, `.Rhistory`, `.RData`, `coverage.html`).

5. **Dependency Installation** → **RESOLVED:** Document `install.packages()` commands in AGENTS.md. No `renv` in Phase 1 (adds complexity without benefit for single-developer project). Consider `renv` in Phase 2+ if team grows.

6. **Test Organization** → **RESOLVED:** Use `tests/testthat/` (standard structure). Requires `tests/testthat.R` runner script per testthat 3e conventions.

7. **Coverage Reporting** → **RESOLVED:** Use `covr::package_coverage()` which works with minimal package structure (DESCRIPTION + R/ + tests/). No special configuration needed.

8. **Data Generation Seed** → **RESOLVED:** Seed value `42` (recognizable default, ensures reproducibility). Documented in function signature and script.

---

## Sources

Research for this plan was informed by:

### R Package Development & Testing
- [R Packages: Testing basics](https://r-pkgs.org/testing-basics.html) — testthat setup and package structure requirements
- [R Packages: Designing your test suite](https://r-pkgs.org/testing-design.html) — test organization and coverage best practices
- [Testing with {testthat}](https://www.jumpingrivers.com/blog/r-testthat/) — testthat usage patterns
- [Posit Community: Testing R projects vs R packages](https://forum.posit.co/t/testing-or-r-projects-vs-r-packages/107747) — minimal package structure discussion

### Code Coverage
- [Test Coverage for Packages • covr](https://covr.r-lib.org/) — covr overview and usage
- [Package 'covr' reference manual](https://cran.r-project.org/web/packages/covr/covr.pdf) — `package_coverage()` vs `file_coverage()` differences

### Best Practices
- [tidyverse style guide](https://style.tidyverse.org/) — R coding conventions (referenced in AGENTS.md)
- [A simple R package development best-practices-example](https://gist.github.com/stevenpollack/141b14437c6c4b071fff) — minimal package structure examples
