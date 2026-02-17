# Manual Test Checklist for Shiny Dashboard
#
# IMPORTANT: These tests are the primary E2E validation until shinytest2
# tests are fixed to run in CI environments. shinytest2 tests currently
# skip due to "On CRAN" detection.
#
# Run these after unit tests pass (100% coverage verified).

# TEST 1: Slider smoothness and responsiveness
# - Launch app: Rscript -e "shiny::runApp('app.R')"
# - Move weight sliders continuously (drag, don't click)
# - Expected: Sliders move smoothly without lag
# - Expected: Table updates within 500ms of slider release

# TEST 2: Chart interactivity
# - Navigate to Rankings tab
# - Hover over bars in dimension chart
# - Expected: Tooltip shows rep name, dimension, exact score
# - Expected: Tooltip follows cursor without lag
# - Navigate to Trends tab
# - Hover over line chart data points
# - Expected: Tooltip shows rep name, period, score

# TEST 3: Error message clarity
# - Navigate to Upload Data tab
# - Upload CSV with missing columns (create test file)
# - Expected: Error message lists specific missing columns
# - Expected: No raw R error displayed

# TEST 4: Large dataset performance
# - Generate 1000-row dataset (modify generate_data.R)
# - Upload via dashboard
# - Move weight slider
# - Expected: Console logs "Scoring took X seconds"
# - Expected: If > 0.5s, warning notification appears
# - Expected: UI remains responsive during scoring

# TEST 5: Export file integrity
# - Apply rep filter (select "REP001")
# - Enable debug mode
# - Click "Export Scored Data (CSV)"
# - Open CSV in Excel
# - Expected: Only REP001 rows present (4 rows)
# - Expected: Intermediate columns present (tenure_factor, etc.)
# - Disable debug mode
# - Export again
# - Expected: Intermediate columns absent
