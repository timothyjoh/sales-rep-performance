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
```bash
Rscript -e "install.packages(c('dplyr', 'tibble', 'purrr', 'testthat', 'covr', 'rprojroot'), repos='https://cloud.r-project.org/')"
```

### 3. Verify installation
```bash
Rscript -e "library(dplyr); library(testthat); library(covr); cat('All dependencies installed\n')"
```

## Project Structure

```
sales-rep-performance/
├── DESCRIPTION                     # Package metadata and dependencies
├── sales-rep-performance.Rproj     # RStudio project file
├── R/                              # Source code
│   └── generate_sample_data.R      # Data generation function
├── tests/                          # Test suite
│   ├── testthat.R                  # Test runner (standard testthat entry point)
│   └── testthat/
│       └── test-generate_sample_data.R  # Tests for data generation
├── scripts/                        # Executable scripts
│   ├── generate_data.R             # Generate sample CSV data
│   └── coverage_report.R           # Generate code coverage report
├── data/                           # Generated data files
│   └── sample_reps.csv             # Sample sales rep data (20 reps x 4 quarters)
├── docs/                           # Documentation and phase planning
├── AGENTS.md                       # This file — developer guide
├── CLAUDE.md                       # Agent instructions (references this file)
├── BRIEF.md                        # Project requirements and business context
└── README.md                       # Getting started guide
```

## Running the Project

### Generate sample data
```bash
Rscript scripts/generate_data.R
```
**Output:** `data/sample_reps.csv` (80 rows: 20 reps x 4 quarters)

## Running Tests

### Run all tests
```bash
Rscript -e "testthat::test_dir('tests/testthat')"
```

### Run tests in RStudio
Press `Cmd+Shift+T` (Mac) or `Ctrl+Shift+T` (Windows/Linux)

## Running Code Coverage

### Generate coverage report
```bash
Rscript scripts/coverage_report.R
```

**Output:** Console summary with per-file coverage percentages

**Coverage target:** 100% for all R code

## Data Model

### Sales Rep Activity Data
**File:** `data/sample_reps.csv`
**Rows:** 80 (20 reps x 4 quarters)

| Column               | Type      | Description                           | Constraints      |
|----------------------|-----------|---------------------------------------|------------------|
| `rep_id`             | character | Unique rep identifier (e.g., REP001)  | Non-empty string |
| `rep_name`           | character | Rep full name (e.g., Rep A)           | Non-empty string |
| `tenure_months`      | numeric   | Months employed                       | >= 0, <= 120     |
| `calls_made`         | integer   | Number of calls made in period        | >= 0             |
| `followups_done`     | integer   | Number of follow-ups completed        | >= 0             |
| `meetings_scheduled` | integer   | Number of meetings scheduled          | >= 0             |
| `deals_closed`       | integer   | Number of deals closed                | >= 0             |
| `revenue_generated`  | numeric   | Dollar revenue generated              | >= 0             |
| `quota`              | numeric   | Rep sales quota (target revenue)      | > 0              |
| `territory_size`     | numeric   | Number of accounts in territory       | > 0              |
| `period`             | character | Time period (e.g., Q1-2025)           | Format: Q[1-4]-YYYY |

### Rep Profile Mix
- **30% new reps** — tenure 1-12 months
- **40% mid-level reps** — tenure 13-36 months
- **30% experienced reps** — tenure 37-120 months

## Coding Conventions

### Style Guide
Follow the [tidyverse style guide](https://style.tidyverse.org/):
- **Indentation:** 2 spaces (no tabs)
- **Line length:** <= 80 characters where practical
- **Naming:** Functions and variables use `snake_case`
- **Assignment:** Use `<-` for assignment, not `=`
- **Piping:** Use native pipe `|>` (R 4.1+)

### Testing Conventions
- **Test file naming:** `test-<source_file_name>.R`
- **Test organization:** Use `test_that("description", { ... })` blocks
- **Assertions:** Use testthat expectations (`expect_equal()`, `expect_true()`, etc.)
- **Anti-mock bias:** Prefer testing real implementations over mocking
- **Coverage:** Aim for 100% line coverage

### Documentation Conventions
- **Function docs:** Use roxygen2 format with `#'` comments
- **Required sections:** `@param`, `@return`, `@examples`

## Common Commands Cheatsheet

```bash
# Install dependencies
Rscript -e "install.packages(c('dplyr', 'tibble', 'purrr', 'testthat', 'covr', 'rprojroot'), repos='https://cloud.r-project.org/')"

# Generate sample data
Rscript scripts/generate_data.R

# Run tests
Rscript -e "testthat::test_dir('tests/testthat')"

# Generate coverage report
Rscript scripts/coverage_report.R
```

## Troubleshooting

### "Error: package 'dplyr' is not installed"
Run `Rscript -e "install.packages('dplyr', repos='https://cloud.r-project.org/')"` (or other missing package)

### "Error: Cannot open file 'R/generate_sample_data.R'"
Ensure you're running commands from the project root directory (where DESCRIPTION file is located)

### Tests fail with "could not find function"
Ensure test files include `source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "generate_sample_data.R"))` at the top

## Phase Status
**Current Phase:** Phase 1 — COMPLETE
**Next Phase:** Phase 2 — Scoring Engine with Normalization
