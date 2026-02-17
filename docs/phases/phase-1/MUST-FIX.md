# Must-Fix Items: Phase 1

## Summary
5 critical issues and 3 minor issues found in review. All issues have been fixed.

---

## Tasks

### Task 1: Fix test runner to work without installed package
**Status:** ✅ Fixed
**What was done:** Replaced `tests/testthat.R` content to remove `library(salesrepperformance)` line. File now contains only the standard testthat setup: `library(testthat)` and `test_check("salesrepperformance")`.

---

### Task 2: Add rprojroot to package dependencies
**Status:** ✅ Fixed
**What was done:** Added `rprojroot` to `Suggests:` in DESCRIPTION. Updated install commands in AGENTS.md (both section 2 and Common Commands Cheatsheet) and README.md to include `rprojroot`.

---

### Task 3: Remove misleading @export tag
**Status:** ✅ Fixed
**What was done:** Removed the `#' @export` line from `R/generate_sample_data.R`. All other roxygen2 documentation kept intact.

---

### Task 4: Update phase status in documentation
**Status:** ✅ Fixed
**What was done:** Updated CLAUDE.md Phase 1 from "(current)" to "(COMPLETE)". README.md Phase 1 was already marked "COMPLETE"; updated Phase 2 heading from "(NEXT)" to "— NEXT" for consistency. Updated AGENTS.md to show "Phase 1 — COMPLETE" and added "Next Phase: Phase 2 — Scoring Engine with Normalization".

---

### Task 5: Clean up .gitignore from previous project
**Status:** ✅ Fixed
**What was done:** Removed lines 1-9 containing Node.js/JavaScript patterns (node_modules, dist, .astro, swimlanes.db, coverage/, test-results/, playwright-report/). File now starts with R-specific patterns only.

---

### Task 6: Strengthen integer type tests
**Status:** ✅ Fixed
**What was done:** Updated `tests/testthat/test-generate_sample_data.R` to use `is.integer()` for `tenure_months`, `calls_made`, `followups_done`, `meetings_scheduled`, and `deals_closed`. Kept `is.numeric()` for `revenue_generated`, `quota`, and `territory_size` which can be doubles.

---

### Task 7: Strengthen profile distribution test
**Status:** ✅ Fixed
**What was done:** Replaced permissive `> 0.1` checks with tighter bounds: new_reps 20-40%, mid_reps 30-50%, exp_reps 20-40%. Added informative `info` messages with actual percentages for debugging if tests fail.

---

## Post-Fix Verification Checklist

- [x] **Tests pass:** All 32 assertions pass
- [x] **Coverage remains 100%:** Overall coverage: 100.0%
- [x] **Documentation consistency:** CLAUDE.md, README.md, and AGENTS.md all updated
