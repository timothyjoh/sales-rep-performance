#' Validate Uploaded CSV Schema
#'
#' Checks that uploaded data frame has all required columns matching
#' sample_reps.csv schema. Returns list with success flag and error message.
#'
#' @param data Data frame from fileInput() or read.csv()
#'
#' @return List with elements: valid (logical), message (character)
#'
#' @examples
#' df <- read.csv("data/sample_reps.csv", stringsAsFactors = FALSE)
#' result <- validate_upload_schema(df)
#' if (!result$valid) stop(result$message)
validate_upload_schema <- function(data) {
  required <- c("rep_id", "rep_name", "tenure_months", "calls_made",
                "followups_done", "meetings_scheduled", "deals_closed",
                "revenue_generated", "quota", "territory_size", "period")

  if (!is.data.frame(data) || nrow(data) == 0) {
    return(list(valid = FALSE, message = "File is empty or not a valid CSV"))
  }

  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    return(list(
      valid = FALSE,
      message = paste0("Missing required columns: ",
                       paste(missing, collapse = ", "))
    ))
  }

  list(valid = TRUE, message = "")
}

#' Normalize Three Weights to Sum to 1.0
#'
#' Takes three weight values and proportionally adjusts them to sum to 1.0.
#' Handles edge case where all weights are zero (returns equal weights).
#'
#' @param w1 Numeric weight value (>= 0)
#' @param w2 Numeric weight value (>= 0)
#' @param w3 Numeric weight value (>= 0)
#'
#' @return Named numeric vector with weights summing to 1.0
#'
#' @examples
#' normalize_three_weights(0.5, 0.3, 0.2)
#' normalize_three_weights(1.0, 1.0, 1.0)
#' normalize_three_weights(0, 0, 0)
normalize_three_weights <- function(w1, w2, w3) {
  total <- w1 + w2 + w3

  # Handle all-zero case (return equal weights)
  if (total == 0) {
    return(c(activity = 0.333, conversion = 0.334, revenue = 0.333))
  }

  # Normalize proportionally
  normalized <- c(
    activity = w1 / total,
    conversion = w2 / total,
    revenue = w3 / total
  )

  # Ensure sum is exactly 1.0 (adjust last weight for floating point errors)
  normalized["revenue"] <- 1.0 - normalized["activity"] - normalized["conversion"]

  normalized
}

#' Format Row Count Summary
#'
#' Returns user-friendly summary of uploaded data size.
#'
#' @param data Data frame
#'
#' @return Character string (e.g., "Loaded 80 rows (20 reps, 4 periods)")
#'
#' @examples
#' df <- read.csv("data/sample_reps.csv")
#' format_row_summary(df)
format_row_summary <- function(data) {
  n_rows <- nrow(data)
  n_reps <- length(unique(data$rep_id))
  n_periods <- length(unique(data$period))

  paste0("Loaded ", n_rows, " rows (",
         n_reps, " reps, ",
         n_periods, " periods)")
}
