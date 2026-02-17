# Phase 3: Interactive Shiny Dashboard

## Objective
Build an interactive Shiny dashboard that lets managers explore rep performance scores, adjust scoring weights in real-time with live sliders, visualize dimension breakdowns and trends over time, and upload their own sales data. Deliver a working web application that makes the scoring engine from Phase 2 accessible and actionable for non-technical users.

## Scope

### In Scope
- **Data upload widget** — Upload CSV files with same schema as sample_reps.csv
- **Rep rankings table** — Interactive table showing rep_id, rep_name, period, overall score, and dimension scores (activity/conversion/revenue), sortable and filterable
- **Live weight sliders** — Three sliders (activity, conversion, revenue) that auto-normalize to sum to 1.0 and trigger instant score recalculation
- **Dimension breakdown visualization** — Bar charts showing how each rep scores across the three dimensions
- **Trend over time visualization** — Line charts showing score progression across quarters for selected reps
- **Filter controls** — Dropdown or search to filter by rep_id or period
- **Score export** — Download button to export scored data as CSV
- **Debug mode toggle** — Checkbox to preserve intermediate normalization columns in output (addresses Phase 2 technical debt)

### Out of Scope
- Quarto executive report generation (Phase 4)
- Improvement suggestions engine (Phase 4)
- Authentication or user management (not in BRIEF.md)
- Real-time data refresh or database integration (static uploaded CSV only)
- Multi-team comparison (single team/dataset only)
- Custom theme configuration or white-labeling
- Mobile-responsive layout optimization (desktop-first acceptable)

## Requirements

### Functional Requirements

**Data Upload:**
- Accept CSV files with exact columns: `rep_id`, `rep_name`, `tenure_months`, `calls_made`, `followups_done`, `meetings_scheduled`, `deals_closed`, `revenue_generated`, `quota`, `territory_size`, `period`
- Validate uploaded data schema and show clear error message if columns missing or types wrong
- Default to sample_reps.csv if no file uploaded
- Display row count and basic summary stats after upload

**Rankings Table:**
- Show all reps with scores sorted by overall score descending by default
- Allow sorting by any column (rep_name, period, dimension scores)
- Display scores rounded to 1 decimal place
- Use color coding (green/yellow/red) for score ranges (75-100 / 50-74 / 0-49)
- Make table scrollable if data exceeds viewport height

**Weight Sliders:**
- Three sliders: Activity Quality, Conversion Efficiency, Revenue Contribution
- Range 0.0 to 1.0 each, default 0.333 each
- Auto-normalize on any slider change (e.g., if user sets activity=0.5, other two auto-adjust to sum to 1.0)
- Display current weight values next to each slider (e.g., "Activity: 0.50")
- Trigger score recalculation reactively whenever weights change
- Recalculation must feel instant (< 500ms for typical dataset of 100 rows)

**Dimension Breakdown Visualization:**
- Grouped bar chart showing activity_score, conversion_score, revenue_score for top 10 reps
- Interactive (hover to see exact values)
- Color-coded by dimension (consistent colors across all charts)
- Update reactively when weights change or filters applied

**Trend Visualization:**
- Line chart showing overall score over time (across periods) for selected rep(s)
- Allow selecting 1-5 reps via checkboxes or multi-select dropdown
- X-axis: period (quarters), Y-axis: score (0-100)
- Update reactively when weights change or rep selection changes

**Filters:**
- Dropdown to filter by single rep_id (show only that rep's data)
- Dropdown to filter by single period (show only that quarter's data)
- "Clear filters" button to reset to full dataset view

**Export:**
- Download button labeled "Export Scored Data (CSV)"
- Exports currently displayed scored data (respects active filters)
- Filename includes timestamp (e.g., `scored_reps_2026-02-17.csv`)

**Debug Mode:**
- Checkbox labeled "Debug Mode: Show Intermediate Normalization Columns"
- When checked, scored data includes `tenure_factor`, `territory_factor`, `quota_attainment` columns
- Addresses Phase 2 technical debt item #2 (REFLECTIONS.md:159-163)

### Non-Functional Requirements
- **Performance**: Score recalculation on weight change must complete in < 500ms for datasets up to 1000 rows
- **Responsiveness**: UI must remain interactive during scoring (use Shiny progress indicators if scoring > 100ms)
- **Error handling**: Invalid uploaded CSV shows user-friendly error message, not raw R error
- **Layout**: Use shinydashboard package for clean sidebar/main panel structure
- **Code organization**: Single-file app (`app.R` in project root) — no complex module structure needed yet
- **Styling**: Professional appearance using shinydashboard themes, no custom CSS required

## Acceptance Criteria

- [ ] Shiny app launches successfully via `Rscript app.R` or `shiny::runApp()`
- [ ] Data upload widget accepts CSV and validates schema (show error for invalid format)
- [ ] Default sample_reps.csv data loads automatically on app launch
- [ ] Rankings table displays all reps with scores, sortable by any column
- [ ] Weight sliders adjust dynamically and auto-normalize to sum = 1.0
- [ ] Scores recalculate instantly (< 500ms) when sliders move
- [ ] Dimension breakdown bar chart shows top 10 reps with three scores each
- [ ] Trend line chart shows score progression over periods for selected reps
- [ ] Filter by rep_id updates table and charts reactively
- [ ] Filter by period updates table and charts reactively
- [ ] Clear filters button resets to full dataset view
- [ ] Export button downloads CSV with correct data and timestamp filename
- [ ] Debug mode checkbox toggles intermediate columns in output data
- [ ] App handles edge cases gracefully (zero activity rows, missing periods, single rep)
- [ ] All tests pass (Shiny reactivity tested with shinytest2 or manual test cases)
- [ ] Code runs without errors or warnings
- [ ] Documentation updated (CLAUDE.md, README.md, AGENTS.md)

## Testing Strategy

### Framework
- **shinytest2** — Automated Shiny app testing with headless browser
- **testthat** — Continue unit testing for helper functions
- **Manual testing** — Critical for UX validation (slider behavior, chart interactivity)

### Key Test Scenarios

**Data Upload Tests:**
- Upload valid CSV → data loads, table updates, scores calculated
- Upload CSV with missing columns → error message displayed, app doesn't crash
- Upload CSV with wrong column types (e.g., tenure_months as character) → error message displayed
- Upload empty CSV → error message displayed

**Weight Slider Tests:**
- Move activity slider to 0.5 → other two sliders auto-adjust to 0.25 each
- Move all sliders to 0.33 → weights sum to 0.99 (acceptable tolerance) → scores recalculate
- Verify scores change when weights change (e.g., increasing revenue weight → high-revenue reps rank higher)

**Reactivity Tests:**
- Change rep_id filter → table shows only that rep, charts update
- Change period filter → table shows only that quarter, charts update
- Clear filters → full dataset restored
- Select different reps in trend chart → lines update to show selected reps only

**Edge Case Tests:**
- Load dataset with single rep → app doesn't crash, charts render
- Load dataset with single period → trend chart shows single point (no error)
- Load dataset where one rep has all-zero activity → score = 0, no error
- Apply filter that returns zero rows → table shows "No data matches filters" message

**Export Tests:**
- Export with no filters → CSV contains all rows
- Export with rep filter active → CSV contains only filtered rep
- Export with debug mode on → CSV includes intermediate columns
- Export with debug mode off → CSV excludes intermediate columns

**Performance Tests:**
- Load 500-row dataset, move slider → score recalculation completes in < 500ms
- Load 1000-row dataset, move slider → score recalculation completes in < 1 second (log timing to console)
- If scoring exceeds 500ms, display progress indicator during calculation

### Coverage Expectations
- **Unit test coverage**: 100% for any helper functions outside app.R (e.g., data validation helpers)
- **Integration coverage**: shinytest2 tests cover major user workflows (upload → adjust weights → filter → export)
- **Manual testing**: Required for UX polish (slider smoothness, chart aesthetics, error message clarity)

### E2E Tests
**Required** — This phase delivers UI, so end-to-end testing is mandatory:
1. **Happy path workflow**:
   - Launch app → sample data loads → adjust weight sliders → scores update → export CSV → verify file contents
2. **Upload custom data workflow**:
   - Launch app → upload valid CSV → verify scores calculated → filter by rep → export filtered data
3. **Error handling workflow**:
   - Launch app → upload invalid CSV → verify error message shown → upload valid CSV → verify recovery

Use **shinytest2** for automated E2E tests, or document manual test cases if automation proves complex.

## Documentation Updates

### CLAUDE.md
**Add:**
- Quick command to launch Shiny app:
  ```bash
  # Launch interactive dashboard
  Rscript app.R
  # Or alternatively:
  Rscript -e "shiny::runApp('app.R')"
  ```
- Brief description of dashboard features (weight sliders, trend charts, data upload)
- Note about debug mode for troubleshooting scores

### README.md
**Add:**
- Update Phase Status: Phase 3 COMPLETE
- Add "Interactive Dashboard" section:
  - How to launch the Shiny app
  - Overview of features (rankings table, weight sliders, trend charts, upload)
  - Screenshot or GIF showing dashboard in action (optional but recommended)
  - Link to AGENTS.md for detailed usage instructions
- Update "Getting Started" to include Shiny app launch as primary usage method

### AGENTS.md
**Add:**
- Dashboard usage guide:
  - How to launch the app
  - How to upload custom data (CSV schema requirements)
  - How to adjust scoring weights with sliders
  - How to use filters and export data
  - Troubleshooting: what to do if app crashes or scores look wrong
- Debug mode instructions: when to use it and what intermediate columns mean
- Performance expectations: typical recalculation times for different dataset sizes

### New Documentation (Optional)
Consider adding `docs/dashboard-guide.md` with screenshots and detailed user instructions if AGENTS.md becomes too long.

## Dependencies

### Code Dependencies
- **Existing Phase 2 code**: All scoring functions in R/ directory (calculate_scores.R, normalization.R, dimension_scoring.R, scoring_utils.R)
- **New R packages**:
  - `shiny` — Core dashboard framework (already in DESCRIPTION from Phase 1)
  - `shinydashboard` — Layout and UI components
  - `DT` — Interactive data tables
  - `plotly` — Interactive charts (preferred over base ggplot2 for hover tooltips)
  - `shinytest2` — Automated Shiny testing (test dependency only)

### Process Dependencies
- Phase 2 must be complete (it is — REFLECTIONS.md confirms all acceptance criteria met)
- Scoring functions must handle grouped data correctly (verified in Phase 2 tests)
- `data/sample_reps.csv` must exist (it does)

## Adjustments from Previous Phase

Based on Phase 2 REFLECTIONS.md lessons learned:

**1. Implement debug mode early (addresses technical debt #2)**
- Add `debug` parameter to `calculate_scores()` function first, before building UI
- Write unit test verifying intermediate columns preserved when `debug = TRUE`
- Then expose as UI checkbox in dashboard
- Rationale: Solves documented technical debt and enables troubleshooting when scores look unexpected

**2. Add performance monitoring to reactive scoring (addresses recommendation #4)**
- Wrap `calculate_scores()` in `system.time()` inside Shiny reactive
- Log timing to console: `message("Scoring took ", elapsed, " seconds")`
- Alert user if scoring exceeds 500ms (show warning banner: "Large dataset detected — scoring may be slow")
- Rationale: Validates SPEC.md:59 performance requirement missed in Phase 2

**3. Validate scoring correctness with real data (addresses recommendation #2)**
- During implementation, manually verify 2-3 rep scores by hand before UI development
- Pick 1 new rep (low tenure) and 1 veteran rep (high tenure), calculate expected score manually
- Add integration test asserting these exact scores (e.g., `expect_equal(scored_data$score[rep_id == "REP007"], 10.0, tolerance = 0.1)`)
- Rationale: Catches math errors Phase 2 unit tests might have missed

**4. Test edge cases BEFORE implementing features (addresses process improvement #1)**
- For data upload: write test "upload CSV with missing columns" before implementing validation logic
- For sliders: write test "move slider triggers score recalculation" before implementing reactive logic
- Follow TDD pattern: failing test → implement feature → passing test
- Rationale: Prevents bugs like zero quota division-by-zero that Phase 2 missed

**5. Run tests after every feature completion (addresses process improvement #5)**
- After implementing data upload widget → run full test suite
- After implementing weight sliders → run full test suite
- After implementing each chart → run full test suite
- Consider using `testthat::auto_test()` file watcher during development
- Rationale: Catches regressions immediately instead of at end of phase

**6. Update STATUS.md at phase start and major milestones (addresses process improvement #7)**
- When Phase 3 starts: Update STATUS.md to "Phase: 3 | Step: spec_written | Status: IN PROGRESS"
- After data upload complete: Update to "Step: data_upload_complete"
- After weight sliders complete: Update to "Step: weight_sliders_complete"
- After charts complete: Update to "Step: visualizations_complete"
- When Phase 3 complete: Update to "Phase: 3 | Step: complete | Status: DONE"
- Rationale: Makes progress visible to anyone reading the project

**7. Document design tradeoffs in code comments (addresses process improvement #4)**
- When implementing weight auto-normalization: add comment explaining UX decision (prevent invalid states vs allow user to manually balance)
- When choosing plotly over ggplot2: add comment explaining interactivity rationale
- When using single-file app.R: add comment explaining "no modules yet, defer until complexity requires it"
- Rationale: Future maintainers understand why decisions were made

## Vertical Slice Validation

**User-visible deliverable:** A working Shiny web application accessible at `http://127.0.0.1:XXXX` after running:
```bash
Rscript app.R
```

**Validation criteria:**
1. **Non-technical user can load data**: Upload CSV or use default sample data → see table of reps with scores
2. **Non-technical user can adjust priorities**: Move weight sliders → see rankings re-order in real time
3. **Non-technical user can explore details**: Click on a rep → see dimension breakdown bar chart
4. **Non-technical user can spot trends**: Select multiple reps → see line chart showing performance over quarters
5. **Non-technical user can export results**: Click "Export" → download CSV file with scores

**Success criteria:** A manager with zero R knowledge can answer "Who are my top 10 reps this quarter?" and "Is Rep X improving over time?" using only the dashboard UI, without touching code or terminal.

This delivers the core interactive experience promised in BRIEF.md:34-40, making the scoring engine from Phase 2 accessible and actionable.
