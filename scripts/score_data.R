#!/usr/bin/env Rscript

# Score Sales Rep Data
# Loads sample data, calculates productivity scores, outputs scored CSV

# Source scoring functions
source("R/scoring_utils.R")
source("R/normalization.R")
source("R/dimension_scoring.R")
source("R/calculate_scores.R")

cat("Loading sample data from data/sample_reps.csv...\n")

# Load sample data
data <- read.csv("data/sample_reps.csv", stringsAsFactors = FALSE)

cat("Calculating productivity scores...\n")

# Calculate scores with default weights
scored_data <- calculate_scores(data)

# Select final output columns (original + 4 score columns)
output_cols <- c(
  "rep_id", "rep_name", "tenure_months", "calls_made", "followups_done",
  "meetings_scheduled", "deals_closed", "revenue_generated", "quota",
  "territory_size", "period", "activity_score", "conversion_score",
  "revenue_score", "score"
)
scored_data <- scored_data[, output_cols]

cat("Writing scored data to data/scored_reps.csv...\n")

# Write output
write.csv(scored_data, "data/scored_reps.csv", row.names = FALSE)

cat("\nScoring complete!\n")
cat("Output: data/scored_reps.csv (", nrow(scored_data), " rows)\n\n")
cat("Score summary:\n")
print(summary(scored_data[, c("activity_score", "conversion_score",
  "revenue_score", "score")]))
