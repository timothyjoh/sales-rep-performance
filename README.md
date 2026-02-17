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
   Rscript -e "install.packages(c('dplyr', 'tibble', 'purrr', 'shiny', 'shinydashboard', 'DT', 'plotly', 'ggplot2', 'knitr', 'rmarkdown', 'tidyr', 'testthat', 'covr', 'rprojroot'), repos='https://cloud.r-project.org/')"
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

## Scoring

### Running the Scoring Engine
Generate productivity scores for sample data:
```bash
Rscript scripts/score_data.R
```

This creates `data/scored_reps.csv` with four new score columns (0-100 scale):
- `score` — Overall productivity score
- `activity_score` — Activity quality dimension
- `conversion_score` — Conversion efficiency dimension
- `revenue_score` — Revenue contribution dimension

### Scoring Methodology
The engine implements fair, bias-free scoring through three steps:

1. **Normalization**: Adjusts raw metrics for fairness
   - Tenure adjustment: New reps (< 12 months) get scaled expectations
   - Territory normalization: Adjusts for territory size (50-500 accounts)
   - Quota normalization: Converts revenue to quota attainment percentage

2. **Dimension Scoring**: Calculates three performance dimensions (0-100)
   - Activity quality: Composite of calls, followups, meetings (adjusted for tenure/territory)
   - Conversion efficiency: Meetings-to-deals ratio + revenue per activity
   - Revenue contribution: Quota attainment + revenue per deal

3. **Weighted Combination**: Combines dimensions with configurable weights (default: equal)

All scores use percentile ranking across the entire dataset, ensuring fair comparison across time periods and experience levels.

## Interactive Dashboard

Launch the Shiny dashboard to explore rep performance interactively:

```bash
Rscript -e "shiny::runApp('app.R')"
```

**Features:**
- Rankings table with sortable dimension scores
- Live weight sliders for activity/conversion/revenue priorities
- Dimension breakdown chart for top 10 reps
- Trend chart tracking score progression over quarters
- Rep and period filters
- CSV export with timestamp
- Debug mode to show intermediate normalization columns

See AGENTS.md for detailed usage instructions.

## Executive Reporting

Generate polished HTML reports for leadership with top performers, trends, and coaching recommendations.

**Generate report:**
```bash
Rscript scripts/generate_report.R
```

**Report sections:**
- **Executive Summary** — Total reps, average score, score range, analysis period
- **Top Performers** — Top 10 reps with overall and dimension scores
- **Score Distributions** — Histogram of overall scores, grouped bar chart of dimensions
- **Trend Analysis** — Top 5 improving/declining reps over quarters
- **Improvement Suggestions** — Rule-based coaching recommendations

**Output:** `reports/executive_report_<YYYY-MM-DD>.html` — Shareable static report (no R server needed)

## Improvement Suggestions

Rule-based coaching recommendations identify specific development opportunities:

- **High activity + Low conversion** — Focus on meeting quality and follow-up techniques
- **Low activity + High conversion** — Increase outreach volume to capitalize on strong conversion skills
- **High conversion + Low revenue** — Focus on deal sizing and upselling
- **Low overall score (<40)** — Schedule comprehensive coaching session
- **High overall score (>85)** — Consider for mentorship or leadership development

Suggestions are integrated into executive reports and help managers prioritize coaching efforts.

## Project Status

### Phase 1: Project Foundation & Sample Data Generation — COMPLETE
- R project structure with minimal package setup
- Sample data generation function (`generate_sample_data()`)
- Test suite with 100% code coverage
- Sample CSV data file with 20 reps across 4 quarters
- Complete developer documentation

### Phase 2: Scoring Engine — COMPLETE
- Normalization functions (tenure, territory size, quota attainment)
- Three dimension scores: activity quality, conversion efficiency, revenue contribution
- Configurable weight system with validation
- End-to-end scoring pipeline with 100% test coverage

### Phase 3: Shiny Dashboard — COMPLETE
- Interactive rep rankings with score breakdowns
- Live weight sliders for instant ranking updates
- Dimension breakdown charts and trend visualizations
- CSV upload, filtering, and export
- Debug mode for troubleshooting

### Phase 4: Quarto Reports & Improvement Suggestions — COMPLETE
- Polished HTML executive reports with professional formatting
- Rule-based improvement suggestions engine with 5 coaching patterns
- Report generation script with CLI arguments
- 100% test coverage maintained

**PROJECT COMPLETE** — All BRIEF.md requirements delivered.

## Documentation

- **[AGENTS.md](AGENTS.md)** — Complete developer guide (setup, commands, conventions)
- **[BRIEF.md](BRIEF.md)** — Project requirements and business context
- **[CLAUDE.md](CLAUDE.md)** — Agent instructions for AI assistants

## Developer Quick Reference

```bash
# Generate sample data
Rscript scripts/generate_data.R

# Calculate productivity scores
Rscript scripts/score_data.R

# Run tests
Rscript -e "testthat::test_dir('tests/testthat')"

# Generate coverage report
Rscript scripts/coverage_report.R
```

For complete developer documentation, see **[AGENTS.md](AGENTS.md)**.
