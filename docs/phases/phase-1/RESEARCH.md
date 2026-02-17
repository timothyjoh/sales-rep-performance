# Research: Phase 1

## Phase Context
Phase 1 establishes the R project foundation by creating the project structure, installing dependencies (tidyverse, testthat, ggplot2, Shiny, Quarto), configuring test framework with code coverage reporting, generating reproducible sample sales rep data with 11 specific columns (rep_id, rep_name, tenure_months, calls_made, followups_done, meetings_scheduled, deals_closed, revenue_generated, quota, territory_size, period) for at least 20 reps across 4 quarters, and creating comprehensive documentation (AGENTS.md, CLAUDE.md updates, README.md updates) so any developer can immediately work with the project.

## Previous Phase Learnings
First phase — no prior reflections exist (`docs/phases/phase-0/REFLECTIONS.md` does not exist).

## Current Codebase State

### Repository Overview
This is a **brand new, empty R project**. The repository was initialized on 2026-02-17 with only documentation scaffolding.

**Git History:**
- Commit `7d14821` (Initial commit): Created empty `README.md`
- Commit `59701fa` (Add CC pipeline and project brief): Added:
  - `.gitignore` — `.gitignore:1-10`
  - `BRIEF.md` — Project requirements — `BRIEF.md:1-79`
  - `CLAUDE.md` — Agent instructions (currently minimal, references "SwimLanes" from a previous project) — `CLAUDE.md:1-8`
  - `.pipeline/` — CI/CD pipeline configuration (not part of deliverable codebase)
  - `docs/phases/phase-1/SPEC.md` — Phase 1 specification — `docs/phases/phase-1/SPEC.md:1-111`

**Current File Structure:**
```
.
├── .git/
├── .gitignore
├── .pipeline/          # CI/CD scaffolding (not part of R project)
├── BRIEF.md            # Project requirements document
├── CLAUDE.md           # Agent instructions (needs complete rewrite per SPEC)
├── README.md           # Currently empty (needs Phase 1 content)
├── STATUS.md           # Auto-generated pipeline status
└── docs/
    └── phases/
        └── phase-1/
            └── SPEC.md # Phase 1 specification
```

**No R code exists yet.** Phase 1 must create everything from scratch.

### Relevant Components
**None exist yet.** All components must be created in Phase 1:

Expected R project structure per `docs/phases/phase-1/SPEC.md:41`:
- `R/` directory — Will contain `generate_sample_data()` function
- `tests/` directory — Will contain testthat tests
- `data/` directory — Will contain `sample_reps.csv` output
- `.Rproj` file — R project configuration
- `DESCRIPTION` file (or equivalent) — R package dependencies

### Existing Patterns to Follow
**No code patterns exist** — this is a greenfield R project.

However, there are **documentation patterns** established:
1. **CLAUDE.md structure** — Currently references old project ("SwimLanes"), must be replaced per `docs/phases/phase-1/SPEC.md:77-82`:
   - Must emphasize "READ AGENTS.md IMMEDIATELY FIRST"
   - Brief project description: "Sales rep productivity scoring system in R"
   - Reference test commands from AGENTS.md

2. **BRIEF.md structure** — Comprehensive project specification — `BRIEF.md:1-79`:
   - Defines tech stack (R, Shiny, Quarto, tidyverse, ggplot2, testthat) — `BRIEF.md:6-12`
   - Defines data model with 11 required columns — `BRIEF.md:59-63`
   - Defines quality bar including unit tests and reproducible sample dataset — `BRIEF.md:65-69`

3. **Phase approach** — Iterative phases defined in `BRIEF.md:72-77`:
   - Phase 1: Data model + sample data + scaffolding
   - Phase 2: Scoring engine
   - Phase 3: Shiny dashboard
   - Phase 4: Quarto reports + improvement suggestions

### Dependencies & Integration Points
**R Environment:**
- R version 4.0+ required — `docs/phases/phase-1/SPEC.md:94`
- **R is not currently installed** on the system (confirmed via `which R` — not found)

**Required R Packages (per SPEC):**
- tidyverse — Data wrangling — `BRIEF.md:10` and `docs/phases/phase-1/SPEC.md:10`
- testthat — Unit testing framework — `BRIEF.md:12` and `docs/phases/phase-1/SPEC.md:10,55`
- ggplot2 — Visualizations — `BRIEF.md:11` and `docs/phases/phase-1/SPEC.md:10`
- Shiny — Interactive dashboard (Phase 3 use) — `BRIEF.md:8` and `docs/phases/phase-1/SPEC.md:10`
- Quarto — Static reports (Phase 4 use) — `BRIEF.md:9` and `docs/phases/phase-1/SPEC.md:10`
- covr — Code coverage reporting — `docs/phases/phase-1/SPEC.md:56,72`

**Integration Points:**
- No external APIs or databases — Phase 1 is self-contained
- CSV file output `data/sample_reps.csv` will serve as input for Phase 2

### Test Infrastructure
**None exists yet.** Must be created in Phase 1.

**Required Test Setup (per SPEC):**
- **Framework:** testthat — `docs/phases/phase-1/SPEC.md:55`
- **Coverage tool:** covr package — `docs/phases/phase-1/SPEC.md:56`
- **Minimum tests required:** 3 unit tests passing — `docs/phases/phase-1/SPEC.md:46`
- **Coverage expectation:** 100% coverage for Phase 1 code — `docs/phases/phase-1/SPEC.md:62`

**Key Test Scenarios (per SPEC:57-61):**
1. Sample data generation produces correct number of rows
2. Sample data contains all required columns with correct types
3. Generated data has realistic value ranges (tenure_months >= 0, revenue_generated >= 0, etc.)
4. Reproducibility: same seed produces identical data

**Test Commands (must be documented in AGENTS.md):**
- Run tests: `testthat::test_dir("tests")` — `docs/phases/phase-1/SPEC.md:71`
- Run coverage: `covr::package_coverage()` — `docs/phases/phase-1/SPEC.md:72`

### Data Model Definition
**Required columns for sample data** (`BRIEF.md:59-63` and `docs/phases/phase-1/SPEC.md:29`):

| Column                | Description                          | Expected Type |
|-----------------------|--------------------------------------|---------------|
| `rep_id`              | Unique rep identifier                | Character/Int |
| `rep_name`            | Rep full name                        | Character     |
| `tenure_months`       | Months employed                      | Numeric (≥0)  |
| `calls_made`          | Number of calls                      | Integer (≥0)  |
| `followups_done`      | Number of follow-ups                 | Integer (≥0)  |
| `meetings_scheduled`  | Number of meetings scheduled         | Integer (≥0)  |
| `deals_closed`        | Number of deals closed               | Integer (≥0)  |
| `revenue_generated`   | Dollar revenue generated             | Numeric (≥0)  |
| `quota`               | Rep sales quota                      | Numeric (≥0)  |
| `territory_size`      | Size of territory                    | Numeric       |
| `period`              | Time period (monthly/quarterly)      | Character     |

**Sample Data Requirements** (`docs/phases/phase-1/SPEC.md:30-33`):
- Minimum 20 reps — `docs/phases/phase-1/SPEC.md:30`
- Across 4 quarters — `docs/phases/phase-1/SPEC.md:30`
- Reproducible (seeded RNG) — `docs/phases/phase-1/SPEC.md:31`
- Mix of profiles: new reps (low tenure), experienced reps (high tenure), varying activity levels — `docs/phases/phase-1/SPEC.md:32`
- Output as CSV: `data/sample_reps.csv` — `docs/phases/phase-1/SPEC.md:33,45`

### Coding Conventions
**Per SPEC:**
- All R code must follow **tidyverse style guide** — `docs/phases/phase-1/SPEC.md:36`

**To be documented in AGENTS.md** (`docs/phases/phase-1/SPEC.md:75`):
- tidyverse style requirements
- Naming patterns (to be established during Phase 1)

### Documentation Requirements
Three files must be created/updated in Phase 1:

**1. AGENTS.md (CREATE)** — `docs/phases/phase-1/SPEC.md:67-76`
Must include:
- Installation: How to install R dependencies (exact commands)
- Running the project: How to generate sample data
- Running tests: Exact command (`testthat::test_dir("tests")`)
- Running coverage: Exact command (`covr::package_coverage()`)
- Project structure: Overview of directories and key files
- Data model: Column descriptions and expected ranges
- Coding conventions: tidyverse style, naming patterns

**2. CLAUDE.md (UPDATE)** — `docs/phases/phase-1/SPEC.md:78-82`
Replace existing content with:
- Emphatic instruction: "READ AGENTS.md IMMEDIATELY FIRST for all project conventions"
- Brief project description: "Sales rep productivity scoring system in R"
- Reference to test commands from AGENTS.md

**Current CLAUDE.md** (`CLAUDE.md:1-8`) incorrectly references "SwimLanes" (a Trello-like kanban board app) and "npm test" — this must be completely replaced.

**3. README.md (UPDATE)** — `docs/phases/phase-1/SPEC.md:84-92`
Must include:
- Project description from BRIEF.md
- Tech stack overview
- Getting started section:
  - Prerequisites (R version)
  - Dependency installation
  - Generate sample data
  - Run tests
- Overview of what Phase 1 delivers

**Current README.md** (`README.md:1`) contains only "# sales-rep-performance" — needs complete Phase 1 content.

### Acceptance Criteria Checklist
From `docs/phases/phase-1/SPEC.md:40-52`:

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

### Vertical Slice Validation
**User-visible deliverable** (`docs/phases/phase-1/SPEC.md:110-111`):
A CSV file (`data/sample_reps.csv`) containing realistic sales rep activity data that can be opened and inspected. This serves as the foundation data layer for all future features.

## Code References
**Existing Files:**
- `.gitignore:1-10` — Contains Node.js/JavaScript patterns (node_modules, dist, .astro, etc.) — needs R-specific patterns added
- `BRIEF.md:1-79` — Project requirements and business context
- `BRIEF.md:59-63` — Data model definition
- `BRIEF.md:72-77` — Phase breakdown
- `CLAUDE.md:1-8` — Current agent instructions (outdated, references "SwimLanes")
- `README.md:1` — Minimal placeholder
- `docs/phases/phase-1/SPEC.md:1-111` — Complete Phase 1 specification

**Files to Create:**
- `R/generate_sample_data.R` (or similar naming) — Function to generate sample data
- `tests/testthat/test-*.R` — Test files (at least 3 tests)
- `data/sample_reps.csv` — Generated sample data output
- `.Rproj` — R project configuration file
- `DESCRIPTION` — R package dependencies manifest
- `AGENTS.md` — Comprehensive developer guide
- Updated `CLAUDE.md` — Agent instructions pointing to AGENTS.md
- Updated `README.md` — Getting started guide

**No Directories Exist Yet:**
- `R/` — Must be created
- `tests/` — Must be created
- `data/` — Must be created

## Open Questions
1. **R Project Structure:** Should this be structured as an R package (with DESCRIPTION, NAMESPACE) or a simpler R project with just an .Rproj file? The SPEC mentions "DESCRIPTION or equivalent" (`docs/phases/phase-1/SPEC.md:42`), suggesting flexibility.

2. **Directory Naming:** Standard R package structure uses `tests/testthat/`, but simpler projects might use just `tests/`. The SPEC references `testthat::test_dir("tests")` which suggests the simpler structure may be acceptable.

3. **Function Scope:** Should `generate_sample_data()` accept parameters (number of reps, quarters, seed) or use hardcoded defaults? The SPEC doesn't specify the function signature.

4. **Git Ignore Patterns:** The current `.gitignore` contains JavaScript/Node.js patterns. Should these be removed (they're from a previous project template) or left in place? Should R-specific patterns be added (e.g., `.Rproj.user/`, `.Rhistory`, `.RData`)?

5. **Dependency Installation:** How should dependencies be installed? Via `install.packages()` commands in documentation, via `renv` for reproducibility, or another approach? The SPEC requires documenting "exact commands" in AGENTS.md.

6. **Test Organization:** Should tests be in `tests/testthat/` (standard package structure) or `tests/` (simpler structure)? The command `testthat::test_dir("tests")` works with either.

7. **Coverage Reporting:** The command `covr::package_coverage()` assumes package structure. If using simpler project structure, will this work or does it need a different command?

8. **Data Generation Seed:** What seed value should be used for reproducibility? The SPEC doesn't specify a particular seed value.
