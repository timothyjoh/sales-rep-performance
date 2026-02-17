# Sales Rep Performance — Developer Guide

This document contains all project conventions, setup instructions, and commands needed to work on this project. **Read this FIRST before making any changes.**

## Project Overview
A sales rep productivity scoring system built in R. Generates fair, bias-free performance scores that normalize across experience levels (new vs senior reps). Currently in Phase 1: foundational data generation.

## Tech Stack
- **R 4.0+** — Core language
- **tidyverse** — Data wrangling (dplyr, tibble, purrr)
- **testthat** — Unit testing framework (3rd edition)
- **covr** — Code coverage reporting
- **Shiny + shinydashboard** — Interactive dashboard
- **DT** — Interactive data tables
- **plotly** — Interactive charts with hover tooltips
- **Quarto** — Static executive reports (HTML/PDF)

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
Rscript -e "install.packages(c('dplyr', 'tibble', 'purrr', 'shiny', 'shinydashboard', 'DT', 'plotly', 'ggplot2', 'knitr', 'rmarkdown', 'tidyr', 'testthat', 'covr', 'rprojroot'), repos='https://cloud.r-project.org/')"
```

### 3. Verify installation
```bash
Rscript -e "library(dplyr); library(testthat); library(covr); cat('All dependencies installed\n')"
```

## Running the Project

### Generate sample data
```bash
Rscript scripts/generate_data.R
```
**Output:** `data/sample_reps.csv` (80 rows: 20 reps x 4 quarters)

### Launch interactive dashboard
```bash
Rscript -e "shiny::runApp('app.R')"
```
**Output:** Dashboard opens in browser at `http://127.0.0.1:XXXX`

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

## Scoring Methodology

### Overview
The scoring engine produces fair, bias-free productivity scores (0-100) by normalizing raw metrics and combining three performance dimensions with configurable weights.

### Normalization
- **Tenure adjustment**: `tenure_factor = min(1.0, tenure_months / 60)` — new reps get scaled expectations, experienced reps (60+ months) have no adjustment
- **Territory adjustment**: `territory_factor = territory_size / 100` — adjusts for territory size (100 accounts = baseline)
- **Quota adjustment**: `quota_attainment = (revenue_generated / quota) * 100` — converts revenue to percentage, uncapped for overachievers

### Dimension Scoring (0-100 scale)
1. **Activity Quality** (33.3% weight): Composite of normalized calls, followups, and meetings. Uses percentile ranking across all reps/periods.
2. **Conversion Efficiency** (33.4% weight): Average of meetings-to-deals ratio and revenue-per-activity, both percentile-ranked.
3. **Revenue Contribution** (33.3% weight): Average of quota attainment and revenue-per-deal, both percentile-ranked.

### Scored Data Model
After scoring, data includes 4 new columns:

| Column           | Type    | Range | Description                          |
|------------------|---------|-------|--------------------------------------|
| activity_score   | numeric | 0-100 | Activity quality dimension score     |
| conversion_score | numeric | 0-100 | Conversion efficiency dimension score|
| revenue_score    | numeric | 0-100 | Revenue contribution dimension score |
| score            | numeric | 0-100 | Overall weighted productivity score  |

### Expected Score Ranges
- **0-25**: Low performer (bottom quartile)
- **26-50**: Below average (second quartile)
- **51-75**: Above average (third quartile)
- **76-100**: High performer (top quartile)

Scores are percentile-based, so distribution is roughly uniform across the 0-100 range.

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
Rscript -e "install.packages(c('dplyr', 'tibble', 'purrr', 'shiny', 'shinydashboard', 'DT', 'plotly', 'ggplot2', 'knitr', 'rmarkdown', 'tidyr', 'testthat', 'covr', 'rprojroot'), repos='https://cloud.r-project.org/')"

# Generate sample data
Rscript scripts/generate_data.R

# Calculate productivity scores
Rscript scripts/score_data.R

# Run tests
Rscript -e "testthat::test_dir('tests/testthat')"

# Generate coverage report
Rscript scripts/coverage_report.R

# Generate executive report (requires Quarto CLI)
Rscript scripts/generate_report.R
```

## Troubleshooting

### "Error: package 'dplyr' is not installed"
Run `Rscript -e "install.packages('dplyr', repos='https://cloud.r-project.org/')"` (or other missing package)

### "Error: Cannot open file 'R/generate_sample_data.R'"
Ensure you're running commands from the project root directory (where DESCRIPTION file is located)

### Tests fail with "could not find function"
Ensure test files include `source(file.path(rprojroot::find_root("DESCRIPTION"), "R", "generate_sample_data.R"))` at the top

## Project Structure

```
sales-rep-performance/
├── DESCRIPTION                     # Package metadata and dependencies
├── sales-rep-performance.Rproj     # RStudio project file
├── app.R                              # Shiny dashboard (single-file app)
├── R/                              # Source code
│   ├── generate_sample_data.R      # Data generation function
│   ├── scoring_utils.R             # Validation helpers and percentile ranking
│   ├── normalization.R             # Tenure, territory, quota normalization
│   ├── dimension_scoring.R         # Activity, conversion, revenue scoring
│   ├── calculate_scores.R          # Weight validation and scoring pipeline
│   ├── shiny_helpers.R             # Dashboard helper functions (validation, weights)
│   └── generate_suggestions.R     # Rule-based coaching recommendations engine
├── reports/                       # Quarto report templates and generated reports
│   └── template.qmd              # Parameterized executive report template
├── tests/                          # Test suite
│   ├── testthat.R                  # Test runner (standard testthat entry point)
│   └── testthat/
│       ├── test-generate_sample_data.R  # Tests for data generation
│       ├── test-scoring_utils.R         # Tests for validation helpers
│       ├── test-normalization.R         # Tests for normalization functions
│       ├── test-dimension_scoring.R     # Tests for dimension scoring
│       ├── test-calculate_scores.R      # Tests for weight validation and pipeline
│       ├── test-integration.R           # End-to-end integration tests
│       ├── test-shiny_helpers.R        # Tests for dashboard helper functions
│       ├── test-app.R                  # shinytest2 E2E dashboard tests
│       ├── test-app-manual.R          # Manual test checklist for UX validation
│       ├── test-generate_suggestions.R  # Tests for suggestions engine
│       └── test-report-generation.R     # E2E report generation tests
├── scripts/                        # Executable scripts
│   ├── generate_data.R             # Generate sample CSV data
│   ├── score_data.R                # Calculate productivity scores
│   ├── coverage_report.R           # Generate code coverage report
│   └── generate_report.R          # Generate executive Quarto report
├── data/                           # Generated data files
│   ├── sample_reps.csv             # Sample sales rep data (20 reps x 4 quarters)
│   └── scored_reps.csv             # Scored output (80 rows x 15 columns)
├── docs/                           # Documentation and phase planning
├── AGENTS.md                       # This file — developer guide
├── CLAUDE.md                       # Agent instructions (references this file)
├── BRIEF.md                        # Project requirements and business context
└── README.md                       # Getting started guide
```

## Executive Report Generation

### Prerequisites

#### Quarto CLI Installation
Quarto CLI must be installed on your system (not an R package):

**Mac:**
```bash
brew install quarto
```

**Linux/Windows:**
Visit https://quarto.org/docs/get-started/

**Verify installation:**
```bash
quarto --version
# Expected: 1.3.0 or higher
```

#### Optional: LaTeX for PDF Output
PDF rendering requires LaTeX (optional, HTML is default format):
```bash
# Install TinyTeX via Quarto
quarto install tinytex

# Or verify existing LaTeX installation
pdflatex --version
```

### Generate Executive Report

**Command:**
```bash
Rscript scripts/generate_report.R
```

**Output:** `reports/executive_report_<YYYY-MM-DD>.html`

**What the report includes:**
- Executive summary with key metrics (total reps, average score, score range)
- Top 10 performers table with dimension scores
- Score distribution histogram and dimension breakdown charts
- Trend analysis showing top 5 improving/declining reps over time
- Improvement suggestions table with coaching recommendations

### Customize Report Parameters

**Use custom input file:**
```bash
Rscript scripts/generate_report.R --input data/custom_scored.csv
```

**Generate PDF format (requires LaTeX):**
```bash
Rscript scripts/generate_report.R --output pdf
```

**Specify output directory:**
```bash
Rscript scripts/generate_report.R --output-dir custom_reports/
```

### Improvement Suggestions Engine

The report includes rule-based coaching recommendations based on dimension score patterns:

**Rule 1: High Activity (>75) + Low Conversion (<50)**
- **Suggestion:** Focus on meeting quality and follow-up techniques to improve conversion rate
- **Rationale:** High activity indicates strong outreach, but poor conversion suggests skill gap in closing

**Rule 2: Low Activity (<40) + High Conversion (>70)**
- **Suggestion:** Increase outreach volume to capitalize on strong conversion skills
- **Rationale:** Strong closing ability, but insufficient pipeline volume limits results

**Rule 3: High Conversion (>75) + Low Revenue (<50)**
- **Suggestion:** Focus on deal sizing and upselling to increase revenue per closed deal
- **Rationale:** Good at closing deals, but small deal sizes limit revenue contribution

**Rule 4: Low Overall Score (<40)**
- **Suggestion:** Schedule comprehensive coaching session to identify skill gaps and barriers
- **Rationale:** Struggling across multiple dimensions requires holistic intervention
- **Priority:** This rule takes precedence over dimension-specific patterns (most critical need)

**Rule 5: High Overall Score (>85)**
- **Suggestion:** Consider for mentorship role or leadership development
- **Rationale:** Top performers can help develop others and take on leadership opportunities

**Edge Cases Handled:**
- Reps with mid-range scores (40-75 all dimensions): No suggestion (performing within expectations)
- Reps with NA dimension scores: Skipped (insufficient data for recommendation)
- Multiple matching rules: Returns most critical suggestion per rep (priority ordering)

### Viewing Generated Reports

**Mac:**
```bash
open reports/executive_report_<YYYY-MM-DD>.html
```

**Linux:**
```bash
xdg-open reports/executive_report_<YYYY-MM-DD>.html
```

**Windows:**
```cmd
start reports/executive_report_<YYYY-MM-DD>.html
```

### Troubleshooting

**Error: "Quarto CLI not found"**
Install Quarto: `brew install quarto` (Mac) or visit https://quarto.org/docs/get-started/

**Error: "Template not found"**
Ensure you're running command from project root directory (where DESCRIPTION file is located)

**Error: "Input file not found"**
Generate scored data first: `Rscript scripts/score_data.R`

**PDF rendering fails**
Install LaTeX: `quarto install tinytex` or verify pdflatex installed

## Dashboard Usage

### Launching the App
```bash
Rscript -e "shiny::runApp('app.R')"
```
Your default browser will open automatically. If not, navigate to the URL shown in the console.

### Uploading Custom Data
1. Navigate to "Upload Data" tab
2. Click "Choose CSV File"
3. Select a CSV with required columns: rep_id, rep_name, tenure_months, calls_made, followups_done, meetings_scheduled, deals_closed, revenue_generated, quota, territory_size, period
4. SUCCESS message confirms upload; ERROR message lists missing columns

### Adjusting Scoring Weights
- Use three sidebar sliders: Activity Quality, Conversion Efficiency, Revenue Contribution
- Weights are auto-normalized to sum to 1.0 for scoring
- Scores recalculate instantly (< 500ms for typical datasets)

### Viewing Rankings and Scores
- Rankings tab shows reps sorted by overall score (highest first)
- Dimension breakdown chart shows top 10 entries with activity/conversion/revenue bars
- Click column headers to sort by any dimension

### Analyzing Trends Over Time
- Trends tab shows score progression across quarters
- Select 1-5 reps from checkbox list
- Adjust weight sliders to see trend lines update

### Filtering Data
- Filter by Rep or Period using sidebar dropdowns
- Click "Clear Filters" to reset
- Charts and export respect active filters

### Exporting Scored Data
- Click "Export Scored Data (CSV)" on Rankings tab
- File downloads with timestamp (e.g., scored_reps_2026-02-17.csv)
- Export includes only currently displayed data (respects filters)

### Debug Mode
- Check "Debug Mode" in sidebar to show intermediate columns (tenure_factor, territory_factor, quota_attainment)
- Useful for troubleshooting unexpected scores

### Troubleshooting
- **App won't launch**: Check dependencies installed (shiny, shinydashboard, DT, plotly)
- **Scores look wrong**: Enable debug mode, inspect intermediate columns
- **Upload fails**: Verify CSV has all 11 required columns (case-sensitive)
- **Slow scoring**: Check console for timing logs; datasets > 1000 rows may exceed 500ms

## Phase Status
**Current Phase:** Phase 4 — COMPLETE
**Project Status:** ALL PHASES COMPLETE
