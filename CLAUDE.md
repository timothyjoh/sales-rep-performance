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

## Development Workflow
1. **Always read AGENTS.md before starting work** — it contains complete project conventions
2. **Run tests after every change** — test-driven development expected
3. **Verify coverage remains 100%** — no untested code allowed
4. **Follow tidyverse style guide** — 2-space indentation, snake_case naming
5. **Document all functions with roxygen2 comments** — @param, @return, @examples required

## Phase Approach
This project follows an iterative phase-based development approach:
- **Phase 1** (COMPLETE): Data model + sample data + project scaffolding
- **Phase 2**: Scoring engine with normalization + configurable weights
- **Phase 3**: Shiny dashboard with rankings, visualizations, and live weight sliders
- **Phase 4**: Quarto executive report + improvement suggestions engine

Refer to `BRIEF.md` for complete project requirements and `docs/phases/phase-N/SPEC.md` for phase-specific specifications.
