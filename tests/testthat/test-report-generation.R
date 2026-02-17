library(testthat)

test_that("report generation script produces HTML output", {
  skip_if(Sys.which("quarto") == "", "Quarto CLI not installed")

  root <- rprojroot::find_root("DESCRIPTION")
  test_output_dir <- file.path(root, "reports_test")

  # Clean up any existing test reports
  if (dir.exists(test_output_dir)) {
    unlink(test_output_dir, recursive = TRUE)
  }

  # Run report generation script with test output directory
  result <- system2(
    "Rscript",
    args = c(
      file.path(root, "scripts", "generate_report.R"),
      "--input", file.path(root, "data", "scored_reps.csv"),
      "--output", "html",
      "--output-dir", test_output_dir
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  # NULL status = success (exit code 0)
  expect_null(attr(result, "status"))

  # Validate output file exists
  output_files <- list.files(test_output_dir,
                             pattern = "executive_report_.*\\.html$")
  expect_true(length(output_files) > 0)

  # Validate file size > 0 (HTML report should be substantial)
  output_path <- file.path(test_output_dir, output_files[1])
  file_size <- file.info(output_path)$size
  expect_true(file_size > 1000)

  # Clean up test output
  unlink(test_output_dir, recursive = TRUE)
})

test_that("report generation fails gracefully with missing input", {
  skip_if(Sys.which("quarto") == "", "Quarto CLI not installed")

  root <- rprojroot::find_root("DESCRIPTION")

  result <- system2(
    "Rscript",
    args = c(
      file.path(root, "scripts", "generate_report.R"),
      "--input", "data/nonexistent.csv"
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  # Non-null status = error (expected)
  expect_true(!is.null(attr(result, "status")))
})
