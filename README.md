# Sales Rep Performance Scoring System

A fair, bias-free sales rep productivity scoring system built in R. Normalizes performance metrics across experience levels so new and senior reps can be fairly compared. Delivers interactive Shiny dashboards and static Quarto reports for managers and leadership.

## What It Does

- **Activity Tracking:** Tracks calls made, follow-ups, meetings scheduled, and deals closed per rep
- **Normalized Scoring:** Fair comparison across experience levels (adjusts for tenure, territory size)
- **Configurable Weights:** Adjustable scoring dimensions (activity quality, conversion efficiency, revenue contribution)
- **Interactive Dashboard:** Shiny app with rep rankings, score breakdowns, and live weight adjustment
- **Executive Reports:** Polished Quarto HTML/PDF reports for leadership (no R server needed)
- **Improvement Suggestions:** Identifies specific skill gaps and provides actionable coaching recommendations

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
   Rscript -e "install.packages(c('dplyr', 'tibble', 'purrr', 'testthat', 'covr', 'rprojroot'), repos='https://cloud.r-project.org/')"
   ```

3. **Verify installation**
   ```bash
   Rscript -e "library(dplyr); library(testthat); cat('All dependencies installed\n')"
   ```

### Quick Start

**Generate sample data:**
```bash
Rscript scripts/generate_data.R
```
Output: `data/sample_reps.csv` (20 reps x 4 quarters = 80 rows)

**Run tests:**
```bash
Rscript -e "testthat::test_dir('tests/testthat')"
```

**Generate coverage report:**
```bash
Rscript scripts/coverage_report.R
```

### Exploring the Data

Open `data/sample_reps.csv` in Excel, Google Sheets, or any spreadsheet app:

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

### Phase 1: Project Foundation & Sample Data Generation — COMPLETE
- R project structure with minimal package setup
- Sample data generation function (`generate_sample_data()`)
- Test suite with 100% code coverage
- Sample CSV data file with 20 reps across 4 quarters
- Complete developer documentation

### Phase 2: Scoring Engine — NEXT
- Normalization logic for fair cross-tenure comparison
- Configurable scoring weights (activity, conversion, revenue)
- Score calculation functions with comprehensive tests

### Phase 3: Shiny Dashboard
- Interactive rep rankings with score breakdowns
- Live weight sliders for instant ranking updates

### Phase 4: Quarto Reports & Improvement Suggestions
- Polished HTML/PDF executive reports
- Automated improvement suggestion engine

## Documentation

- **[AGENTS.md](AGENTS.md)** — Complete developer guide (setup, commands, conventions)
- **[BRIEF.md](BRIEF.md)** — Project requirements and business context
- **[CLAUDE.md](CLAUDE.md)** — Agent instructions for AI assistants

## Developer Quick Reference

```bash
# Generate sample data
Rscript scripts/generate_data.R

# Run tests
Rscript -e "testthat::test_dir('tests/testthat')"

# Generate coverage report
Rscript scripts/coverage_report.R
```

For complete developer documentation, see **[AGENTS.md](AGENTS.md)**.
