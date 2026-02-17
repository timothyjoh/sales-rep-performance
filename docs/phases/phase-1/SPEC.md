# Phase 1: Project Foundation & Sample Data Generation

## Objective
Establish the R project structure, install dependencies, configure testing with coverage, generate reproducible sample sales rep data, and create comprehensive documentation so any agent or developer can immediately understand how to work with the project.

## Scope

### In Scope
- R project scaffolding (directory structure, .Rproj file)
- Dependency installation (tidyverse, testthat, ggplot2, Shiny, Quarto)
- Test framework configuration with code coverage reporting
- Sample data generation function that creates realistic rep activity data
- Data model definition matching BRIEF.md requirements
- Initial tests proving the setup works
- Complete AGENTS.md with project conventions
- Updated CLAUDE.md with agent instructions
- Updated README.md with getting started guide

### Out of Scope
- Scoring engine or normalization logic (Phase 2)
- Shiny dashboard implementation (Phase 3)
- Quarto reports (Phase 4)
- Improvement suggestions engine (Phase 4)
- Any UI components or interactive visualizations

## Requirements

### Functional Requirements
- Generate sample dataset with columns: `rep_id`, `rep_name`, `tenure_months`, `calls_made`, `followups_done`, `meetings_scheduled`, `deals_closed`, `revenue_generated`, `quota`, `territory_size`, `period`
- Sample data should include at least 20 reps across 4 quarters
- Data generation must be reproducible (seeded random number generation)
- Include mix of rep profiles: new reps (low tenure), experienced reps (high tenure), varying activity levels
- Save sample data as CSV for easy inspection and reuse

### Non-Functional Requirements
- All R code follows tidyverse style guide
- Test framework must support code coverage reporting
- Documentation clear enough that a new developer can run tests within 2 minutes of cloning

## Acceptance Criteria
- [ ] R project structure created with standard directories (R/, tests/, data/)
- [ ] All dependencies installed and documented in DESCRIPTION or equivalent
- [ ] testthat configured with code coverage reporting working
- [ ] Sample data generation function `generate_sample_data()` works and is tested
- [ ] CSV output file `data/sample_reps.csv` created with valid data
- [ ] At least 3 unit tests written and passing
- [ ] Code coverage report can be generated (command documented)
- [ ] AGENTS.md exists with complete project conventions
- [ ] CLAUDE.md updated to reference AGENTS.md first
- [ ] README.md updated with project description and getting started steps
- [ ] All tests pass
- [ ] Code runs without errors or warnings

## Testing Strategy
- **Framework**: testthat (standard R testing framework)
- **Coverage tool**: covr package for code coverage reporting
- **Key test scenarios**:
  - Sample data generation produces correct number of rows
  - Sample data contains all required columns with correct types
  - Generated data has realistic value ranges (e.g., tenure_months >= 0, revenue_generated >= 0)
  - Reproducibility: same seed produces identical data
- **Coverage expectations**: 100% coverage for Phase 1 code (data generation function)
- **E2E tests**: Not applicable for Phase 1 (no user-facing features yet)

## Documentation Updates

### AGENTS.md (CREATE)
Must include:
- **Installation**: How to install R dependencies (exact commands)
- **Running the project**: How to generate sample data
- **Running tests**: Exact command (e.g., `testthat::test_dir("tests")`)
- **Running coverage**: Exact command (e.g., `covr::package_coverage()`)
- **Project structure**: Overview of directories and key files
- **Data model**: Column descriptions and expected ranges
- **Coding conventions**: tidyverse style, naming patterns

### CLAUDE.md (UPDATE)
Replace existing content with:
- Emphatic instruction: "READ AGENTS.md IMMEDIATELY FIRST for all project conventions"
- Brief project description: "Sales rep productivity scoring system in R"
- Reference to test commands from AGENTS.md

### README.md (UPDATE)
- Project description from BRIEF.md
- Tech stack overview
- Getting started section:
  - Prerequisites (R version)
  - Dependency installation
  - Generate sample data
  - Run tests
- Overview of what Phase 1 delivers

## Dependencies
- R (version 4.0+)
- No prior phases exist — this is the foundation

## Adjustments from Previous Phase
First phase — no prior adjustments.

## Phase 1 Special Requirements ✓
This spec fulfills all Phase 1 requirements:
1. ✓ Project scaffolding and dependency installation
2. ✓ Test framework configured with coverage reporting
3. ✓ Initial tests that prove setup works
4. ✓ AGENTS.md creation detailed above
5. ✓ CLAUDE.md creation detailed above
6. ✓ README.md creation detailed above

## Vertical Slice Validation
**User-visible feature**: A CSV file (`data/sample_reps.csv`) containing realistic sales rep activity data that can be opened and inspected. This is the foundation data layer required for all future features, delivered as a tangible, verifiable artifact rather than abstract infrastructure.
