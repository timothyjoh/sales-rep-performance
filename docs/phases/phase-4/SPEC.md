# Phase 4: Quarto Executive Report & Improvement Suggestions

## Objective
Build a static Quarto executive report that generates polished HTML/PDF summaries of sales rep performance with top performers, score distributions, and trends. Add an improvement suggestions engine that identifies specific coaching opportunities based on dimension score patterns. Deliver shareable reports for leadership and actionable recommendations for managers.

## Scope

### In Scope
- **Quarto report template** — Parameterized .qmd file that renders HTML/PDF reports
- **Executive summary section** — Top performers table, key metrics (avg score, score range, quarter comparison)
- **Score distribution visualizations** — Histogram of scores, dimension breakdowns, percentile analysis
- **Trend analysis** — Rep improvement/decline over quarters with charts
- **Improvement suggestions engine** — Rule-based function that identifies coaching opportunities
  - Example: High activity (>75) + low conversion (<50) → "needs conversion training"
  - Example: Low activity (<40) + high conversion (>70) → "needs motivation/outreach coaching"
  - Example: High conversion (>75) + low revenue (<50) → "needs deal size coaching"
- **Suggestions integrated into report** — Display per-rep recommendations in report body
- **Report generation script** — `scripts/generate_report.R` that loads scored data and renders Quarto
- **Optional: Suggestions in Shiny dashboard** — Add suggestions column to rankings table (enhancement)

### Out of Scope
- Advanced statistical analysis (correlation, regression, predictive modeling) — not in BRIEF.md
- Custom report branding or white-labeling
- Automated report scheduling or email delivery
- Multi-team comparisons or org-wide benchmarking
- Real-time data refresh in reports (reports are static snapshots)
- Interactive Quarto widgets (keep reports simple HTML/PDF)
- Machine learning-based suggestions (rule-based only)

## Requirements

### Functional Requirements

**Quarto Report:**
- Accept scored data CSV as input parameter (e.g., `data/scored_reps.csv` or exported dashboard CSV)
- Render HTML by default, with PDF option if LaTeX installed
- Include sections:
  1. **Executive Summary** — Total reps analyzed, date range, average score
  2. **Top Performers** — Table of top 10 reps with overall + dimension scores
  3. **Score Distributions** — Histogram of overall scores, grouped bar chart of dimension scores
  4. **Trend Analysis** — Line charts showing rep scores over quarters (top 5 improvers, top 5 decliners)
  5. **Improvement Suggestions** — Table of reps with specific coaching recommendations
- Professional styling using Quarto themes (no custom CSS required)
- Include timestamp and report metadata in footer

**Improvement Suggestions Engine:**
- Implement as standalone function: `generate_suggestions(scored_data) -> data.frame`
- Return data frame with columns: `rep_id`, `rep_name`, `suggestion_category`, `suggestion_text`
- Rule-based logic with at least 5 patterns:
  1. **High Activity / Low Conversion** — `activity_score > 75 & conversion_score < 50` → "Focus on meeting quality and follow-up techniques to improve conversion rate"
  2. **Low Activity / High Conversion** — `activity_score < 40 & conversion_score > 70` → "Increase outreach volume to capitalize on strong conversion skills"
  3. **High Conversion / Low Revenue** — `conversion_score > 75 & revenue_score < 50` → "Focus on deal sizing and upselling to increase revenue per closed deal"
  4. **Low Across All Dimensions** — `score < 40` → "Schedule comprehensive coaching session to identify skill gaps and barriers"
  5. **High Across All Dimensions** — `score > 85` → "Consider for mentorship role or leadership development"
- Handle edge cases: reps with single period (no trend data), new reps (< 6 months tenure), reps with missing dimension scores
- Prioritize suggestions: return most critical suggestion per rep (not all matching rules)

**Report Generation Script:**
- `scripts/generate_report.R` — Loads scored data, generates suggestions, renders Quarto report
- Accept command-line arguments:
  - `--input` — Path to scored CSV (default: `data/scored_reps.csv`)
  - `--output` — Output format (default: `html`, options: `html`, `pdf`)
  - `--output-dir` — Directory for rendered report (default: `reports/`)
- Example usage:
  ```bash
  Rscript scripts/generate_report.R --input data/scored_reps.csv --output html
  ```
- Output filename includes timestamp (e.g., `executive_report_2026-02-17.html`)

**Optional: Dashboard Integration:**
- Add suggestions column to Shiny rankings table showing suggestion_text
- Add filter dropdown for suggestion_category (e.g., show only reps needing "conversion training")
- Only implement if time permits — report is higher priority

### Non-Functional Requirements
- **Quarto dependency**: Require Quarto CLI installed on system (document in AGENTS.md prerequisites)
- **Performance**: Report generation must complete in < 30 seconds for 1000-row dataset
- **Reproducibility**: Same scored data produces identical report (deterministic suggestions)
- **Clarity**: Report language accessible to non-technical managers (no jargon)
- **Professional polish**: Report suitable for sharing with VP-level executives
- **Code organization**: Keep suggestion logic in `R/generate_suggestions.R`, keep report template in `reports/template.qmd`

## Acceptance Criteria

- [ ] Quarto report template (`reports/template.qmd`) renders HTML successfully
- [ ] Report includes executive summary with key metrics
- [ ] Report includes top performers table (top 10 reps)
- [ ] Report includes score distribution histogram
- [ ] Report includes dimension breakdown visualization (grouped bars)
- [ ] Report includes trend analysis with line charts (top improvers/decliners)
- [ ] Improvement suggestions function works with 100% test coverage
- [ ] Suggestions engine implements all 5 rule patterns correctly
- [ ] Suggestions integrated into report (table showing rep + suggestion)
- [ ] Report generation script (`scripts/generate_report.R`) works end-to-end
- [ ] Generated report outputs to `reports/` directory with timestamp filename
- [ ] Report renders in PDF format if LaTeX installed (optional, document requirement)
- [ ] All tests pass (minimum 10 test cases for suggestions engine)
- [ ] 100% code coverage for `R/generate_suggestions.R`
- [ ] All functions documented with roxygen2 (@param, @return, @examples)
- [ ] No warnings or errors when rendering report
- [ ] Documentation updated (CLAUDE.md, README.md, AGENTS.md)

## Testing Strategy

### Framework
- **testthat** — Unit tests for suggestions engine logic
- **Manual testing** — Critical for report aesthetics and readability
- **Snapshot testing** — Consider capturing report HTML output for regression testing

### Key Test Scenarios

**Suggestions Engine Tests:**
- High activity (80) + low conversion (40) → returns "conversion training" suggestion
- Low activity (30) + high conversion (75) → returns "increase outreach" suggestion
- High conversion (80) + low revenue (45) → returns "deal sizing" suggestion
- Low score (35) across all dimensions → returns "comprehensive coaching" suggestion
- High score (90) across all dimensions → returns "mentorship" suggestion
- Rep with edge case scores (activity=50, conversion=50, revenue=50) → returns sensible suggestion or none
- Multiple matching rules → prioritizes most critical suggestion (e.g., low overall score takes precedence)
- Empty data frame input → returns empty suggestions frame (no error)
- Rep with missing dimension scores (NA values) → handles gracefully (skip or return generic suggestion)

**Report Rendering Tests:**
- Load scored_reps.csv → render report → verify HTML file exists in `reports/` directory
- Report contains "Top Performers" section with data table
- Report contains histogram image (verify ggplot2 renders)
- Report contains suggestions table with at least 1 row
- Report timestamp matches current date
- Rendering with missing Quarto CLI → error message with installation instructions

**Integration Tests:**
- End-to-end: `generate_data.R` → `score_data.R` → `generate_report.R` → verify report contains expected sections
- Dashboard export CSV → `generate_report.R` → verify report renders with custom weights reflected

**Edge Case Tests:**
- Report with single rep → renders without errors (charts show single data point)
- Report with single period → no trend charts (or shows "insufficient data" message)
- Report with all reps having score > 85 → suggestions table shows all "mentorship" recommendations
- Report with scored data but zero suggestions (all reps mid-range) → shows "No specific recommendations" message

### Coverage Expectations
- **Unit test coverage**: 100% for `R/generate_suggestions.R`
- **Manual coverage**: Report sections reviewed for clarity, formatting, professional appearance
- **No decrease in overall project coverage** from Phase 3 (maintain 100%)

### E2E Tests
**Required** — Report generation is user-facing deliverable:
1. **Happy path workflow**:
   - Run `Rscript scripts/generate_data.R` → `Rscript scripts/score_data.R` → `Rscript scripts/generate_report.R` → open HTML report → verify all sections present
2. **Custom data workflow**:
   - Export scored CSV from Shiny dashboard → Run `Rscript scripts/generate_report.R --input exported_data.csv` → verify report reflects custom weights
3. **PDF rendering workflow** (optional if LaTeX available):
   - Run `Rscript scripts/generate_report.R --output pdf` → verify PDF file generated

Manual validation: Open generated HTML report in browser, review for clarity and professionalism.

## Documentation Updates

### CLAUDE.md
**Add:**
- Quick command to generate executive report:
  ```bash
  # Generate executive report from scored data
  Rscript scripts/generate_report.R

  # Generate PDF report (requires LaTeX)
  Rscript scripts/generate_report.R --output pdf
  ```
- Brief description of report contents (top performers, trends, suggestions)
- Note about Quarto CLI prerequisite

### README.md
**Add:**
- Update Phase Status: Phase 4 COMPLETE → **PROJECT COMPLETE**
- Add "Executive Reporting" section:
  - How to generate Quarto reports
  - Overview of report sections (summary, top performers, trends, suggestions)
  - Link to sample report (optional: commit sample HTML to `docs/samples/`)
- Add "Improvement Suggestions" section:
  - Explanation of rule-based coaching recommendations
  - Example suggestions for different score patterns
- Update "Getting Started" to include report generation as final workflow step

### AGENTS.md
**Add:**
- Quarto CLI installation instructions:
  ```bash
  # Install Quarto (Mac)
  brew install quarto

  # Install Quarto (Linux/Windows)
  # Visit https://quarto.org/docs/get-started/
  ```
- Report generation workflow:
  - How to generate reports from scored data
  - How to customize report parameters (input file, output format)
  - Where to find generated reports (`reports/` directory)
- Suggestions engine methodology:
  - Explanation of 5 rule patterns
  - How suggestions are prioritized
  - Edge cases handled (new reps, missing data)
- Add report commands to Common Commands Cheatsheet section

### New Documentation
- Consider committing sample report to `docs/samples/executive_report_sample.html` for reference
- Update REFLECTIONS.md:144-145 forward-look section (mark Phase 4 complete, note project completion)

## Dependencies

### Code Dependencies
- **Existing Phase 2/3 code**: All scoring functions (`R/calculate_scores.R`) and Shiny dashboard (`app.R`)
- **Scored data**: Requires `data/scored_reps.csv` or Shiny export with dimension scores
- **New R packages**:
  - `quarto` — R interface to Quarto CLI (optional, can call CLI directly via `system()`)
  - `knitr` — Required for Quarto rendering
  - `rmarkdown` — Required for Quarto rendering

### External Dependencies
- **Quarto CLI** — Must be installed on system (not R package)
  - Check: `quarto --version`
  - Install: https://quarto.org/docs/get-started/
- **LaTeX** (optional) — Required only for PDF output
  - Check: `pdflatex --version`
  - Install: TinyTeX via `quarto install tinytex` or full TeX distribution

### Process Dependencies
- Phase 3 must be complete (it is — dashboard functional, scored data exports available)
- `data/scored_reps.csv` must exist (generated by Phase 2 or exported from Phase 3 dashboard)

## Adjustments from Previous Phase

Based on Phase 3 REFLECTIONS.md lessons learned:

**1. Fix dependency configuration issues before starting (addresses findings #1, #6)**
- Move `plotly` from Suggests to Imports in DESCRIPTION (REFLECTIONS.md:100-104)
- Add `library(ggplot2)` to `app.R` or move to Imports (REFLECTIONS.md:125-128)
- Validate all new Phase 4 packages (knitr, rmarkdown, quarto) declared in DESCRIPTION immediately
- Rationale: Prevents deployment failures and fragile namespace dependencies

**2. Front-load documentation during implementation (addresses recommendation #1)**
- Update AGENTS.md with Quarto installation instructions BEFORE writing report template
- Document suggestion engine rules in roxygen comments AS rules are implemented
- Update CLAUDE.md with report command AFTER script tested and working
- Rationale: Ensures commands are verified and prevents documentation drift

**3. Write tests before implementing features (TDD approach) (addresses process improvement #1)**
- Write failing test: `generate_suggestions(high_activity_low_conversion_data)` → expect "conversion training" suggestion
- Implement suggestion rule to make test pass
- Repeat for all 5 rule patterns
- Rationale: Catches logic bugs early, ensures 100% coverage by design

**4. Validate report output manually before marking complete (addresses recommendation #3)**
- Render sample report and open in browser
- Review formatting, chart clarity, suggestion text readability
- Verify professional appearance suitable for executives
- Consider adding screenshot comparison tests or committing sample HTML for regression checks
- Rationale: Automated tests can't validate UX and professionalism

**5. Update STATUS.md at major milestones (addresses finding #4, process improvement #7)**
- When Phase 4 starts: Update STATUS.md to "Phase: 4 | Step: spec_written | Status: IN PROGRESS"
- After suggestions engine complete: Update to "Step: suggestions_complete"
- After report template complete: Update to "Step: report_template_complete"
- When Phase 4 complete: Update to "Phase: 4 | Step: complete | Status: PROJECT COMPLETE"
- Rationale: Makes progress visible and tracks project completion

**6. Run full test suite after every task completion (addresses recommendation #2)**
- After implementing each suggestion rule → run `testthat::test_dir('tests/testthat')`
- After adding each report section → verify coverage remains 100%
- Consider using `testthat::auto_test()` during development
- Rationale: Catches regressions immediately

**7. Document design decisions in code comments (addresses recommendation #3)**
- When prioritizing suggestions (e.g., low overall score takes precedence): add comment explaining priority logic
- When choosing rule thresholds (e.g., activity > 75): add comment explaining rationale (quartile-based, domain expert input)
- When using Quarto over RMarkdown: add comment explaining decision (modern ecosystem, better theming)
- Rationale: Future maintainers understand why decisions were made

**8. Integrate suggestions into dashboard only if time permits (deferred enhancement)**
- Report is higher priority (BRIEF.md:41-45 primary deliverable)
- Dashboard integration is Phase 4 "nice-to-have" (REFLECTIONS.md:193)
- Only implement if suggestions engine and report complete with time remaining
- Rationale: Avoid scope creep, focus on vertical slice completion

## Vertical Slice Validation

**User-visible deliverable:** A static HTML executive report accessible at `reports/executive_report_<timestamp>.html` after running:
```bash
Rscript scripts/generate_report.R
```

**Validation criteria:**
1. **Executive can understand performance**: Open report in browser → see top 10 performers table → identify high/low performers
2. **Executive can spot trends**: Scroll to trend section → see charts showing which reps improving/declining over quarters
3. **Manager can identify coaching needs**: Review suggestions table → see specific recommendations per rep (e.g., "Rep C needs conversion training")
4. **Report is shareable**: Email HTML file or host on GitHub Pages → recipients can view without R/Quarto installed
5. **Report is professional**: Formatting, charts, and language suitable for VP-level review (no raw data dumps or jargon)

**Success criteria:** A VP with zero technical knowledge can answer "Who are my top performers this quarter?", "Are any reps declining?", and "What coaching should I prioritize?" by reading the report, without needing access to Shiny dashboard or raw data.

This completes the project scope defined in BRIEF.md:41-50, delivering both the static report for executives and the actionable suggestions for managers.
