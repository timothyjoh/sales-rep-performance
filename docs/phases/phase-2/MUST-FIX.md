# Must-Fix Items: Phase 2

## Summary
1 critical bug found: Zero quota causes division by zero in `normalize_quota()`. This bug is not caught by current tests and will crash the scoring pipeline if data contains `quota = 0`.

Also fixing 3 minor test quality issues to improve confidence in correctness.

---

## Tasks

### Task 1: Fix Zero Quota Division-by-Zero Bug
**Status:** ✅ Fixed
**What was done:** Added `if (any(data$quota == 0, na.rm = TRUE)) stop(...)` check in `normalize_quota()` after existing validations. Added roxygen note documenting "Assumes quota > 0". Added test `"normalize_quota errors on zero quota"` in `test-normalization.R`. Verified zero quota now produces clear error message instead of Inf.

---

### Task 2: Add Mathematical Correctness Test for Known Rep
**Status:** ✅ Fixed
**What was done:** Added `"integration test validates known rep score correctness"` test in `test-integration.R`. Validates REP003 Q1-2025 activity_score > 90 (high tenure, low territory, high activity) and REP012 Q1-2025 score < 20 (low tenure, low activity, low revenue). Both assertions pass.

---

### Task 3: Add Percentile Ranking Test with Ties and Outliers
**Status:** ✅ Fixed
**What was done:** Added `"percentile_rank handles large dataset with ties and outliers"` test in `test-scoring_utils.R`. Uses 20-value dataset (10 tied low, 9 tied mid, 1 outlier). Validates outlier gets rank 100, tied groups have identical ranks, mid-tier ranks between low and high, all ranks in 0-100.

---

### Task 4: Add Boundary Test for All-Identical Data
**Status:** ✅ Fixed
**What was done:** Added `"scoring handles all-identical input data gracefully"` test in `test-integration.R`. Uses 10 reps with identical metrics. Validates all scores are identical and equal to 50 (midpoint for tied percentile ranks).

---

## Final Verification Checklist

After completing all tasks:

- [x] All tests pass: 147 tests, 0 failures
- [x] Coverage remains 100%: All 5 R files at 100%
- [x] Scoring script runs without errors: 80 rows scored successfully
- [x] Zero quota now produces error (not Inf): "Column 'quota' cannot contain zero values (must be > 0)"
- [x] Known rep scores validated (REP003 Q1 activity > 90, REP012 Q1 score < 20)
- [x] All-identical data test passes
- [x] Percentile ranking with ties/outliers test passes
