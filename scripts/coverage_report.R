#!/usr/bin/env Rscript

# Generate Code Coverage Report
# Requires: covr package installed

library(covr)

cat("Running code coverage analysis...\n\n")

cov <- file_coverage(
  source_files = list.files("R", full.names = TRUE, pattern = "\\.R$"),
  test_files = list.files("tests/testthat", full.names = TRUE, pattern = "^test.*\\.R$")
)

print(cov)

coverage_pct <- percent_coverage(cov)
cat(sprintf("\nOverall coverage: %.1f%%\n", coverage_pct))

if (coverage_pct < 100) {
  cat("\nCoverage is below 100%\n")
  quit(status = 1)
} else {
  cat("\nCoverage target met (100%)\n")
}
