# Sales Rep Performance — Agent Instructions

**CRITICAL: Read AGENTS.md IMMEDIATELY FIRST for all project conventions, setup instructions, and commands.**

## Project Description
Sales rep productivity scoring system built in R. Generates fair, bias-free performance scores that normalize across experience levels (new reps vs experienced reps). Delivers interactive Shiny dashboard and static Quarto reports.

## Quick Command Reference
All commands are documented in detail in AGENTS.md. Quick reference:

### Run Tests
```bash
Rscript -e "testthat::test_dir('tests/testthat')"
```

### Generate Coverage Report
```bash
Rscript scripts/coverage_report.R
```

### Generate Sample Data
```bash
Rscript scripts/generate_data.R
```

### Score Sample Data
```bash
Rscript scripts/score_data.R
```

## Scoring Methodology
The scoring engine calculates fair, bias-free productivity scores (0-100) using three normalized dimensions:
- **Activity Quality (33.3%)**: Calls, followups, and meetings, adjusted for tenure and territory size
- **Conversion Efficiency (33.4%)**: Meetings-to-deals ratio and revenue per activity unit
- **Revenue Contribution (33.3%)**: Quota attainment and revenue per deal closed

Each dimension is percentile-ranked across all reps and periods, then combined using configurable weights. Default weights balance all three dimensions equally. See `R/calculate_scores.R` for implementation details.

## Development Workflow
1. **Always read AGENTS.md before starting work** — it contains complete project conventions
2. **Run tests after every change** — test-driven development expected
3. **Verify coverage remains 100%** — no untested code allowed
4. **Follow tidyverse style guide** — 2-space indentation, snake_case naming
5. **Document all functions with roxygen2 comments** — @param, @return, @examples required

## Phase Approach
This project follows an iterative phase-based development approach:
- **Phase 1** (COMPLETE): Data model + sample data + project scaffolding
- **Phase 2** (COMPLETE): Scoring engine with normalization + configurable weights
- **Phase 3**: Shiny dashboard with rankings, visualizations, and live weight sliders
- **Phase 4**: Quarto executive report + improvement suggestions engine

Refer to `BRIEF.md` for complete project requirements and `docs/phases/phase-N/SPEC.md` for phase-specific specifications.
