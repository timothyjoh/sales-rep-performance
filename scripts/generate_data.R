#!/usr/bin/env Rscript

# Generate Sample Sales Rep Data
# Outputs: data/sample_reps.csv

source("R/generate_sample_data.R")

cat("Generating sample sales rep data...\n")
sample_data <- generate_sample_data(n_reps = 20, n_quarters = 4, seed = 42)

if (!dir.exists("data")) {
  dir.create("data", recursive = TRUE)
}

output_path <- "data/sample_reps.csv"
write.csv(sample_data, output_path, row.names = FALSE)

cat(sprintf("Generated %d rows of sample data\n", nrow(sample_data)))
cat(sprintf("Saved to: %s\n", output_path))
cat("\nSummary:\n")
print(summary(sample_data))
