#!/usr/bin/env Rscript

# Generate Executive Report
# Loads scored data, generates suggestions, renders Quarto report
#
# Usage:
#   Rscript scripts/generate_report.R
#   Rscript scripts/generate_report.R --input data/scored_reps.csv
#   Rscript scripts/generate_report.R --output pdf
#   Rscript scripts/generate_report.R --output-dir custom_reports/

# Parse command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Default arguments
input_csv <- "data/scored_reps.csv"
output_format <- "html"
output_dir <- "reports"

# Parse arguments (simple approach without optparse for minimal dependencies)
if (length(args) > 0) {
  for (i in seq_along(args)) {
    if (args[i] == "--input" && i < length(args)) {
      input_csv <- args[i + 1]
    } else if (args[i] == "--output" && i < length(args)) {
      output_format <- args[i + 1]
    } else if (args[i] == "--output-dir" && i < length(args)) {
      output_dir <- args[i + 1]
    }
  }
}

cat("==================================================\n")
cat("Sales Rep Performance - Executive Report Generator\n")
cat("==================================================\n\n")

# Validate Quarto CLI installation
quarto_path <- Sys.which("quarto")
if (quarto_path == "") {
  stop(paste0(
    "ERROR: Quarto CLI not found.\n\n",
    "Please install Quarto to generate reports:\n",
    "  Mac: brew install quarto\n",
    "  Linux/Windows: https://quarto.org/docs/get-started/\n\n",
    "After installation, verify with: quarto --version\n"
  ))
}

cat("Quarto CLI found:", quarto_path, "\n")

# Validate input file exists
if (!file.exists(input_csv)) {
  stop(paste0("ERROR: Input file not found: ", input_csv))
}

cat("Input file:", input_csv, "\n")
cat("Output format:", output_format, "\n")
cat("Output directory:", output_dir, "\n\n")

# Validate output format
if (!output_format %in% c("html", "pdf")) {
  stop("ERROR: Output format must be 'html' or 'pdf'")
}

# Resolve output directory to absolute path
if (!startsWith(output_dir, "/")) {
  output_dir <- file.path(
    tryCatch(rprojroot::find_root("DESCRIPTION"), error = function(e) getwd()),
    output_dir
  )
}

# Create output directory if needed
if (!dir.exists(output_dir)) {
  cat("Creating output directory:", output_dir, "\n")
  dir.create(output_dir, recursive = TRUE)
}

# Generate timestamped output filename
timestamp <- format(Sys.Date(), "%Y-%m-%d")
output_file <- file.path(
  output_dir,
  paste0("executive_report_", timestamp, ".", output_format)
)

cat("Generating report...\n\n")

# Render Quarto template
# Find project root to resolve template path regardless of working directory
project_root <- tryCatch(
  rprojroot::find_root("DESCRIPTION"),
  error = function(e) getwd()
)
template_path <- file.path(project_root, "reports", "template.qmd")

if (!file.exists(template_path)) {
  stop(paste0("ERROR: Template not found: ", template_path))
}

# Build quarto render command
# Use --execute-param for each parameter (more portable than JSON string)
# Use --execute-dir to ensure R code runs from project root for consistent paths
# Render the template in place first, then rename output file
# This avoids Quarto path resolution issues with --output and --output-dir
quarto_args <- c(
  "render", template_path,
  "--to", output_format,
  "-P", paste0("input_csv:", input_csv)
)
# Default output will be reports/template.html (same name as .qmd)

cat("Executing: quarto", paste(quarto_args, collapse = " "), "\n\n")

# Execute render command
render_result <- system2("quarto", args = quarto_args)

if (render_result != 0) {
  stop("ERROR: Quarto rendering failed. Check error messages above.")
}

# Quarto renders to reports/template.html by default (same base name as .qmd)
# Rename to the timestamped output filename
default_output <- file.path(
  dirname(template_path),
  paste0(tools::file_path_sans_ext(basename(template_path)), ".", output_format)
)

if (!file.exists(default_output)) {
  stop("ERROR: Output file was not created. Rendering may have failed.")
}

# Move to timestamped filename in target output directory
# Use file.copy + file.remove instead of file.rename for cross-directory moves
if (normalizePath(dirname(default_output), mustWork = FALSE) ==
    normalizePath(dirname(output_file), mustWork = FALSE)) {
  file.rename(default_output, output_file)
} else {
  file.copy(default_output, output_file, overwrite = TRUE)
  file.remove(default_output)
}

cat("\n==================================================\n")
cat("Report generation complete!\n")
cat("==================================================\n\n")
cat("Output file:", output_file, "\n")

# Validate output file was created
if (!file.exists(output_file)) {
  stop("ERROR: Output file was not created. Rendering may have failed.")
}

file_size <- file.info(output_file)$size
cat("File size:", format(file_size, big.mark = ","), "bytes\n\n")

cat("Open report with:\n")
cat("  open", output_file, "(Mac)\n")
cat("  xdg-open", output_file, "(Linux)\n")
cat("  start", output_file, "(Windows)\n\n")
